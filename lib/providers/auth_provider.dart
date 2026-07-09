import 'package:flutter/material.dart';
import 'package:koniwalamatrimonial/models/user_model.dart';
import 'package:koniwalamatrimonial/models/data_entry_stats.dart';
import 'package:koniwalamatrimonial/models/payroll_run.dart';
import 'package:koniwalamatrimonial/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  UserModel? _userModel;
  DataEntryStats? _dashboardStats;
  PayrollRun? _payrollPreview;
  bool _isLoading = false;
  bool _isInitialized = false;

  UserModel? get userModel => _userModel;
  DataEntryStats? get dashboardStats => _dashboardStats;
  PayrollRun? get payrollPreview => _payrollPreview;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  final AuthService _authService = AuthService();
  late final Future<void> _loadUserFuture;

  AuthProvider() {
    _loadUserFuture = _loadUser();
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _loadUserFuture;
    }
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      _userModel = UserModel.fromJson(jsonDecode(userJson));
      _authService.setAccessToken(_userModel?.accessToken);
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    await _ensureInitialized();
    final result = await _authService.login(email, password);
    
    _isLoading = false;
    if (result != null) {
      _userModel = result;
      _authService.setAccessToken(result.accessToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(result.toJson()));
      notifyListeners();
      return true;
    }
    
    notifyListeners();
    return false;
  }

  Future<void> fetchCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    await _ensureInitialized();
    final result = await _authService.getCurrentUser();
    
    if (result != null) {
      // Merge with existing tokens if current user result doesn't provide them
      _userModel = UserModel(
        user: result.user,
        accessToken: _userModel?.accessToken ?? result.accessToken,
        refreshToken: _userModel?.refreshToken ?? result.refreshToken,
      );
      
      _authService.setAccessToken(_userModel?.accessToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_userModel!.toJson()));
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> refreshSession() async {
    _isLoading = true;
    notifyListeners();

    await _ensureInitialized();
    final success = await _authService.refreshSession();
    
    if (success) {
      // After a successful refresh, we might want to fetch the updated user profile
      // which often includes a new access token if the backend provides it via cookies
      await fetchCurrentUser();
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    notifyListeners();

    await _ensureInitialized();
    final result = await _authService.getDashboardStats();
    if (result != null) {
      _dashboardStats = result;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPayrollPreview({
    required int month,
    required int year,
  }) async {
    _isLoading = true;
    notifyListeners();

    await _ensureInitialized();
    final result = await _authService.getPayrollPreview(
      month: month,
      year: year,
    );
    if (result != null) {
      _payrollPreview = result;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> downloadPayrollPayslip({
    required String payslipId,
    String? fileName,
  }) async {
    await _ensureInitialized();
    final file = await _authService.downloadPayrollPayslip(
      payslipId: payslipId,
      fileName: fileName,
    );
    return file != null;
  }

  Future<PayrollRecalculateResult> recalculatePayroll({
    required String id,
    required int month,
    required int year,
    required String status,
  }) async {
    _isLoading = true;
    notifyListeners();

    await _ensureInitialized();
    final result = await _authService.recalculatePayroll(
      id: id,
      month: month,
      year: year,
      status: status,
    );

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<bool> runPayroll({
    required int month,
    required int year,
  }) async {
    await _ensureInitialized();
    return await _authService.runPayroll(
      month: month,
      year: year,
    );
  }

  Future<List<dynamic>?> fetchProfiles({
    required String oppositeGenderOf,
    required String profileType,
  }) async {
    await _ensureInitialized();
    return await _authService.getProfiles(
      oppositeGenderOf: oppositeGenderOf,
      profileType: profileType,
    );
  }

  Future<void> logout() async {
    await _ensureInitialized();
    _userModel = null;
    _authService.setAccessToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    notifyListeners();
  }
}
