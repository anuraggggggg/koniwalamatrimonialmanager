import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/owner/models/hr_employee_item.dart';

class HrEmployeesProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _requestedAccessToken;
  bool _hasRequestedEmployees = false;
  List<HrEmployeeItem> _employees = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<HrEmployeeItem> get employees => _employees;

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
      debugPrint('Calling staff list API: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${accessToken.trim()}',
        },
      );

      debugPrint(
        'Staff list API response status=${response.statusCode}, '
        'body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Staff list API failed with ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      final employeeRows = _extractEmployeeRows(decoded);

      _employees = employeeRows
          .whereType<Map<String, dynamic>>()
          .map(HrEmployeeItem.fromJson)
          .toList();
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

  void _replaceEmployee(HrEmployeeItem oldEmployee, HrEmployeeItem newEmployee) {
    _employees = _employees
        .map((employee) => employee.id == oldEmployee.id ? newEmployee : employee)
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

  List<dynamic> _extractEmployeeRows(dynamic payload) {
    if (payload is List) {
      return payload;
    }

    if (payload is Map<String, dynamic>) {
      for (final key in const ['data', 'employees', 'items', 'results']) {
        final value = payload[key];

        if (value is List) {
          return value;
        }

        final nestedRows = _extractEmployeeRows(value);
        if (nestedRows.isNotEmpty) {
          return nestedRows;
        }
      }
    }

    return const [];
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
