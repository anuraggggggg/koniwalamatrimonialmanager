import 'package:flutter/material.dart';
import 'package:koniwalamatrimonial/models/holiday_model.dart';
import 'package:koniwalamatrimonial/services/holiday_service.dart';

class HolidayProvider extends ChangeNotifier {
  final HolidayService _holidayService;
  List<HolidayModel> _holidays = [];
  bool _isLoading = false;
  bool _isCreating = false;

  HolidayProvider(this._holidayService);

  List<HolidayModel> get holidays => _holidays;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;

  Future<void> fetchHolidays(int year, String token) async {
    _isLoading = true;
    notifyListeners();

    _holidayService.setAccessToken(token);
    _holidays = await _holidayService.getHolidays(year);

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> createHoliday({
    required String token,
    required String name,
    required DateTime date,
    required String type,
    required bool isHalfDay,
    String? description,
  }) async {
    if (token.trim().isEmpty) {
      return 'Authorization token is missing.';
    }

    if (name.trim().isEmpty) {
      return 'Holiday designation is required.';
    }

    _isCreating = true;
    notifyListeners();

    try {
      _holidayService.setAccessToken(token);
      final holiday = await _holidayService.createHoliday(
        name: name,
        date: date,
        type: type,
        isHalfDay: isHalfDay,
        description: description,
      );

      if (holiday != null && holiday.id.trim().isNotEmpty) {
        _holidays = [holiday, ..._holidays];
      } else {
        _holidays = await _holidayService.getHolidays(date.year);
      }
      return null;
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '').trim();
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }
}
