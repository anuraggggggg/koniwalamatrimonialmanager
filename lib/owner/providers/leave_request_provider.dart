import 'package:flutter/material.dart';
import 'package:koniwalamatrimonial/models/leave_model.dart';
import 'package:koniwalamatrimonial/services/leave_service.dart';

class LeaveRequestProvider extends ChangeNotifier {
  LeaveRequestProvider(this._leaveService);

  final LeaveService _leaveService;

  String? _selectedCategory;
  bool _isSubmitting = false;
  String? _errorMessage;
  LeaveModel? _submittedLeave;

  final TextEditingController departureDateController = TextEditingController();
  final TextEditingController returnDateController = TextEditingController();
  final TextEditingController justificationController = TextEditingController();

  String? get selectedCategory => _selectedCategory;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  LeaveModel? get submittedLeave => _submittedLeave;

  void setSelectedCategory(String? value) {
    if (_selectedCategory == value) {
      return;
    }

    _selectedCategory = value;
    notifyListeners();
  }

  void setDepartureDate(DateTime date) {
    departureDateController.text = _formatDate(date);
    notifyListeners();
  }

  void setReturnDate(DateTime date) {
    returnDateController.text = _formatDate(date);
    notifyListeners();
  }

  void reset() {
    _selectedCategory = null;
    _errorMessage = null;
    _submittedLeave = null;
    departureDateController.clear();
    returnDateController.clear();
    justificationController.clear();
    notifyListeners();
  }

  Future<bool> submitLeave({
    required String token,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    if (token.trim().isEmpty) {
      _errorMessage = 'Authorization token is missing.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _submittedLeave = null;
    notifyListeners();

    try {
      _leaveService.setAccessToken(token);
      _submittedLeave = await _leaveService.createLeave(
        type: type,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
      );
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '').trim();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  void dispose() {
    departureDateController.dispose();
    returnDateController.dispose();
    justificationController.dispose();
    super.dispose();
  }
}
