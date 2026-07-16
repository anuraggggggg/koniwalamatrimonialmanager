import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/owner/models/hr_employee_detail.dart';
import 'package:koniwalamatrimonial/owner/models/hr_employee_item.dart';

List<HrEmployeeItem> _parseHrEmployeeItemsResponse(String body) {
  final decoded = jsonDecode(body);
  final employeeRows = _extractHrEmployeeRows(decoded);

  return employeeRows
      .whereType<Map<String, dynamic>>()
      .map(HrEmployeeItem.fromJson)
      .toList();
}

List<dynamic> _extractHrEmployeeRows(dynamic payload) {
  if (payload is List) {
    return payload;
  }

  if (payload is Map<String, dynamic>) {
    for (final key in const ['data', 'employees', 'items', 'results']) {
      final value = payload[key];

      if (value is List) {
        return value;
      }

      final nestedRows = _extractHrEmployeeRows(value);
      if (nestedRows.isNotEmpty) {
        return nestedRows;
      }
    }
  }

  return const [];
}

void _debugPrintCompact(String label, String value) {
  if (!kDebugMode) {
    return;
  }

  const maxChars = 1200;
  final compactValue = value.length > maxChars
      ? '${value.substring(0, maxChars)}... [truncated ${value.length} chars]'
      : value;
  debugPrint('$label$compactValue');
}

class HrEmployeesProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _requestedAccessToken;
  bool _hasRequestedEmployees = false;
  List<HrEmployeeItem> _employees = const [];
  bool _isEmployeeAttendanceLoading = false;
  bool _isPayrollHistoryLoading = false;
  String? _employeeAttendanceError;
  String? _payrollHistoryError;
  final Map<String, HrEmployeeAttendanceResult> _employeeAttendanceByKey = {};
  final Map<String, List<HrPayrollHistoryItem>> _payrollHistoryByEmployee = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<HrEmployeeItem> get employees => _employees;
  bool get isEmployeeAttendanceLoading => _isEmployeeAttendanceLoading;
  bool get isPayrollHistoryLoading => _isPayrollHistoryLoading;
  String? get employeeAttendanceError => _employeeAttendanceError;
  String? get payrollHistoryError => _payrollHistoryError;

  bool hasRequestFor({required String? accessToken}) {
    return _hasRequestedEmployees && _requestedAccessToken == accessToken;
  }

  Future<void> fetchEmployees(
    String? accessToken, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _hasRequestedEmployees &&
        accessToken == _requestedAccessToken) {
      return;
    }

    _hasRequestedEmployees = true;
    _requestedAccessToken = accessToken;

    if (accessToken == null || accessToken.isEmpty) {
      _isLoading = false;
      _error = 'Login required to load employee data.';
      _employees = const [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = '${ApiConstants.baseUrl}${ApiConstants.hrEmployees}';
      if (kDebugMode) {
        debugPrint('Calling staff list API: $url');
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${accessToken.trim()}',
        },
      );

      if (kDebugMode) {
        debugPrint('Staff list API response status=${response.statusCode}');
      }
      _debugPrintCompact('Staff list API body: ', response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Staff list API failed with ${response.statusCode}');
      }

      // PERF: Staff lists can include enough nested data to hitch the UI while
      // opening HR/owner screens. Parse on a background isolate.
      _employees = await compute(_parseHrEmployeeItemsResponse, response.body);
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (error) {
      debugPrint('Staff list API error: $error');
      _isLoading = false;
      _error = 'Unable to load employee data.';
      notifyListeners();
    }
  }

  Future<void> retry() {
    return fetchEmployees(_requestedAccessToken, forceRefresh: true);
  }

  HrEmployeeAttendanceResult? employeeAttendance({
    required String employeeId,
    required int month,
    required int year,
  }) {
    return _employeeAttendanceByKey[_attendanceKey(employeeId, month, year)];
  }

  List<HrPayrollHistoryItem> payrollHistory(String employeeId) {
    return _payrollHistoryByEmployee[employeeId] ?? const [];
  }

  Future<void> fetchEmployeeAttendance({
    required String? accessToken,
    required String employeeId,
    required int month,
    required int year,
    bool forceRefresh = false,
  }) async {
    final key = _attendanceKey(employeeId, month, year);
    if (!forceRefresh && _employeeAttendanceByKey.containsKey(key)) {
      return;
    }

    if (accessToken == null || accessToken.isEmpty) {
      _employeeAttendanceError = 'Login required to load attendance.';
      notifyListeners();
      return;
    }

    if (employeeId.trim().isEmpty) {
      _employeeAttendanceError = 'Employee id is missing.';
      notifyListeners();
      return;
    }

    _isEmployeeAttendanceLoading = true;
    _employeeAttendanceError = null;
    notifyListeners();

    try {
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.hrEmployeeAttendance(employeeId: employeeId, month: month, year: year)}';
      if (kDebugMode) {
        debugPrint('Calling employee attendance API: $url');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${accessToken.trim()}',
        },
      );

      if (kDebugMode) {
        debugPrint(
          'Employee attendance API response status=${response.statusCode}',
        );
      }
      _debugPrintCompact('Employee attendance API body: ', response.body);

      if (response.statusCode == 304 &&
          _employeeAttendanceByKey.containsKey(key)) {
        _isEmployeeAttendanceLoading = false;
        _employeeAttendanceError = null;
        notifyListeners();
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Employee attendance API failed with ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      _employeeAttendanceByKey[key] = HrEmployeeAttendanceResult.fromResponse(
        decoded,
      );
      _isEmployeeAttendanceLoading = false;
      _employeeAttendanceError = null;
      notifyListeners();
    } catch (error) {
      debugPrint('Employee attendance API error: $error');
      _isEmployeeAttendanceLoading = false;
      _employeeAttendanceError = 'Unable to load attendance.';
      notifyListeners();
    }
  }

  Future<void> fetchPayrollHistory({
    required String? accessToken,
    required String employeeId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _payrollHistoryByEmployee.containsKey(employeeId)) {
      return;
    }

    if (accessToken == null || accessToken.isEmpty) {
      _payrollHistoryError = 'Login required to load payroll history.';
      notifyListeners();
      return;
    }

    if (employeeId.trim().isEmpty) {
      _payrollHistoryError = 'Employee id is missing.';
      notifyListeners();
      return;
    }

    _isPayrollHistoryLoading = true;
    _payrollHistoryError = null;
    notifyListeners();

    try {
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.payrollEmployeeHistory(employeeId)}';
      if (kDebugMode) {
        debugPrint('Calling payroll history API: $url');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${accessToken.trim()}',
        },
      );

      if (kDebugMode) {
        debugPrint(
          'Payroll history API response status=${response.statusCode}',
        );
      }
      _debugPrintCompact('Payroll history API body: ', response.body);

      if (response.statusCode == 304 &&
          _payrollHistoryByEmployee.containsKey(employeeId)) {
        _isPayrollHistoryLoading = false;
        _payrollHistoryError = null;
        notifyListeners();
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Payroll history API failed with ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      _payrollHistoryByEmployee[employeeId] = HrPayrollHistoryItem.fromResponse(
        decoded,
      );
      _isPayrollHistoryLoading = false;
      _payrollHistoryError = null;
      notifyListeners();
    } catch (error) {
      debugPrint('Payroll history API error: $error');
      _isPayrollHistoryLoading = false;
      _payrollHistoryError = 'Unable to load payroll history.';
      notifyListeners();
    }
  }

  Future<String?> updateEmployee({
    required HrEmployeeItem employee,
    required String? accessToken,
    required String name,
    required String email,
    required String department,
    required String reportingManagerName,
    required String incentive,
    required String baseSalary,
    File? image,
  }) async {
    if (accessToken == null || accessToken.isEmpty) {
      return 'Login required to update employee data.';
    }

    if (employee.id.isEmpty) {
      return 'Employee id is missing.';
    }

    final data = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'department': department.trim(),
      'reportingManagerName': reportingManagerName.trim(),
      'incentive': incentive.trim(),
      'baseSalary': _normalizeSalary(baseSalary),
    };

    try {
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.hrEmployee(employee.id)}';
      debugPrint('Calling staff update API: $url');
      final response = image == null
          ? await http.patch(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${accessToken.trim()}',
              },
              body: jsonEncode(data),
            )
          : await _patchEmployeeMultipart(
              url: url,
              accessToken: accessToken,
              data: data,
              image: image,
            );

      debugPrint(
        'Staff update API response status=${response.statusCode}, '
        'body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _extractErrorMessage(response.body) ??
            'Unable to update employee data.';
      }

      _replaceEmployee(
        employee,
        employee.copyWith(
          name: data['name']?.toString(),
          email: data['email']?.toString(),
          department: data['department']?.toString(),
          reportingManagerName: data['reportingManagerName']?.toString(),
          baseSalary: data['baseSalary']?.toString(),
          image: image?.path,
          incentiveProgressLabel: data['incentive']?.toString(),
        ),
      );
      return null;
    } catch (error) {
      debugPrint('Staff update API error: $error');
      return 'Unable to update employee data.';
    }
  }

  Future<http.Response> _patchEmployeeMultipart({
    required String url,
    required String accessToken,
    required Map<String, dynamic> data,
    required File image,
  }) async {
    final request = http.MultipartRequest('PATCH', Uri.parse(url));
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer ${accessToken.trim()}',
    });
    request.fields.addAll(
      data.map((key, value) => MapEntry(key, value.toString())),
    );
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }

  void _replaceEmployee(
    HrEmployeeItem oldEmployee,
    HrEmployeeItem newEmployee,
  ) {
    _employees = _employees
        .map(
          (employee) => employee.id == oldEmployee.id ? newEmployee : employee,
        )
        .toList();
    notifyListeners();
  }

  String _normalizeSalary(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return text;
    }

    final numeric = text.replaceAll(RegExp(r'[^0-9.]'), '');
    return numeric.isEmpty ? text : numeric;
  }

  HrEmployeeItem? findEmployee({
    required String? userId,
    required String? role,
  }) {
    if (_employees.isEmpty) {
      return null;
    }

    if (userId != null) {
      for (final employee in _employees) {
        if (employee.id == userId) {
          return employee;
        }
      }
    }

    if (role != null) {
      for (final employee in _employees) {
        if (employee.role.toUpperCase() == role.toUpperCase()) {
          return employee;
        }
      }
    }

    return _employees.first;
  }

  String _attendanceKey(String employeeId, int month, int year) {
    return '$employeeId:$year:$month';
  }

  String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        for (final key in const ['message', 'error', 'detail']) {
          final value = decoded[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
