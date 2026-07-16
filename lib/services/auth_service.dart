import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/models/user_model.dart';
import 'package:koniwalamatrimonial/models/data_entry_stats.dart';
import 'package:koniwalamatrimonial/models/payroll_run.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PayrollRecalculateResult {
  const PayrollRecalculateResult({required this.success, this.message});

  final bool success;
  final String? message;
}

class AuthService {
  final Dio _dio = Dio();
  late final Future<void> _ready;
  String? _accessToken;

  AuthService() {
    _ready = _initDio();
  }

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  Future<void> _ensureReady() => _ready;

  Future<void> _initDio() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String appDocPath = appDocDir.path;
    final cookieJar = PersistCookieJar(
      storage: FileStorage(appDocPath + "/.cookies/"),
    );
    _dio.interceptors.add(CookieManager(cookieJar));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<UserModel?> login(String email, String password) async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.login}';

    try {
      await _ensureReady();
      final response = await _dio.post(
        url,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final userModel = UserModel.fromJson(response.data);
        _accessToken = userModel.accessToken;
        return userModel;
      } else {
        return null;
      }
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.me}';

    try {
      await _ensureReady();
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        return null;
      }
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  Future<bool> refreshSession() async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.refresh}';

    try {
      await _ensureReady();
      final response = await _dio.post(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Refresh session error: $e');
      return false;
    }
  }

  Future<DataEntryStats?> getDashboardStats() async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.dataEntryDashboard}';

    try {
      await _ensureReady();
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        return DataEntryStats.fromJson(response.data);
      } else {
        return null;
      }
    } catch (e) {
      print('Get dashboard stats error: $e');
      return null;
    }
  }

  Future<bool> runPayroll({required int month, required int year}) async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.payrollRun}';

    try {
      await _ensureReady();
      final response = await _dio.post(
        url,
        data: {'month': month, 'year': year},
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Run payroll error: $e');
      return false;
    }
  }

  Future<PayrollRun?> getPayrollPreview({
    required int month,
    required int year,
  }) async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.payrollPreview}';

    try {
      await _ensureReady();
      final response = await _dio.post(
        url,
        data: {'month': month, 'year': year},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PayrollRun.fromJson(response.data);
      } else {
        return null;
      }
    } catch (e) {
      print('Post payroll preview error: $e');
      return null;
    }
  }

  Future<PayrollRecalculateResult> recalculatePayroll({
    required String id,
    required int month,
    required int year,
    required String status,
  }) async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.payrollRecalculate}';

    try {
      await _ensureReady();
      final response = await _postPayrollRecalculate(
        url: url,
        data: {'id': id, 'month': month, 'year': year, 'status': status},
      );

      final statusCode = response.statusCode ?? 0;
      return PayrollRecalculateResult(
        success: statusCode >= 200 && statusCode < 300,
      );
    } on DioException catch (e) {
      final message = _extractErrorMessage(e.response?.data);
      if (_shouldRetryPayrollRecalculateWithoutRunFields(message)) {
        return _recalculatePayrollWithPeriodOnly(
          url: url,
          month: month,
          year: year,
        );
      }

      return PayrollRecalculateResult(success: false, message: message);
    } catch (_) {
      return const PayrollRecalculateResult(success: false);
    }
  }

  Future<Response<dynamic>> _postPayrollRecalculate({
    required String url,
    required Map<String, dynamic> data,
  }) {
    return _dio.post(url, data: data);
  }

  Future<PayrollRecalculateResult> _recalculatePayrollWithPeriodOnly({
    required String url,
    required int month,
    required int year,
  }) async {
    try {
      final response = await _postPayrollRecalculate(
        url: url,
        data: {'month': month, 'year': year},
      );
      final statusCode = response.statusCode ?? 0;
      return PayrollRecalculateResult(
        success: statusCode >= 200 && statusCode < 300,
      );
    } on DioException catch (e) {
      return PayrollRecalculateResult(
        success: false,
        message: _extractErrorMessage(e.response?.data),
      );
    } catch (_) {
      return const PayrollRecalculateResult(success: false);
    }
  }

  bool _shouldRetryPayrollRecalculateWithoutRunFields(String? message) {
    final normalizedMessage = message?.toLowerCase() ?? '';
    return normalizedMessage.contains('property id') ||
        normalizedMessage.contains('property status');
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
      if (message is List && message.isNotEmpty) {
        return message.join(', ');
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    return null;
  }

  Future<List<dynamic>?> getProfiles({
    required String oppositeGenderOf,
    required String profileType,
  }) async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.profiles}';
    final queryParameters = {
      'oppositeGenderOf': oppositeGenderOf,
      'profileType': profileType,
    };

    try {
      await _ensureReady();
      final response = await _dio.get(url, queryParameters: queryParameters);

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print('Get profiles error: $e');
      return null;
    }
  }

  Future<File?> downloadPayrollPayslip({
    required String payslipId,
    String? fileName,
  }) async {
    final url =
        '${ApiConstants.baseUrl}${ApiConstants.payrollPayslipDownload(payslipId)}';

    try {
      await _ensureReady();
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode != 200 || response.data == null) {
        return null;
      }

      final directory = await _resolvePayrollPayslipDirectory();
      final resolvedFileName = _safePayrollFileName(
        fileName?.trim().isNotEmpty == true
            ? fileName!.trim()
            : 'payroll-slip-$payslipId.pdf',
      );
      final file = File(
        '${directory.path}${Platform.pathSeparator}$resolvedFileName',
      );
      await file.writeAsBytes(response.data!, flush: true);
      return file;
    } catch (e) {
      print('Download payroll payslip error: $e');
      return null;
    }
  }

  Future<Directory> _resolvePayrollPayslipDirectory() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final externalDirectory = await getExternalStorageDirectory();
        if (externalDirectory != null) {
          final directory = Directory(
            '${externalDirectory.path}${Platform.pathSeparator}payroll_payslips',
          );
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          return directory;
        }
      }

      final downloadsDirectory = await getDownloadsDirectory();
      if (downloadsDirectory != null) {
        final directory = Directory(
          '${downloadsDirectory.path}${Platform.pathSeparator}payroll_payslips',
        );
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        return directory;
      }
    } catch (_) {}

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}payroll_payslips',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  String _safePayrollFileName(String value) {
    final sanitized = value.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
    return sanitized.toLowerCase().endsWith('.pdf')
        ? sanitized
        : '$sanitized.pdf';
  }
}
