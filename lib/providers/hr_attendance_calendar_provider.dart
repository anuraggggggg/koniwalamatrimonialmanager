import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/models/hr_attendance_calendar.dart';

class HrAttendanceCalendarProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _requestedAccessToken;
  int? _requestedMonth;
  int? _requestedYear;
  bool _hasRequestedCalendar = false;
  HrAttendanceCalendar? _calendar;

  bool get isLoading => _isLoading;
  String? get error => _error;
  HrAttendanceCalendar? get calendar => _calendar;

  Future<void> fetchCalendar({
    required String? accessToken,
    required int month,
    required int year,
    bool forceRefresh = false,
  }) async {
    debugPrint(
      'HrAttendanceCalendarProvider.fetchCalendar called. '
      'hasToken=${accessToken != null && accessToken.isNotEmpty}, '
      'month=$month, year=$year, forceRefresh=$forceRefresh',
    );

    if (!forceRefresh &&
        _hasRequestedCalendar &&
        accessToken == _requestedAccessToken &&
        month == _requestedMonth &&
        year == _requestedYear) {
      debugPrint('HR attendance calendar API skipped: request already loaded.');
      return;
    }

    _hasRequestedCalendar = true;
    _requestedAccessToken = accessToken;
    _requestedMonth = month;
    _requestedYear = year;

    if (accessToken == null || accessToken.isEmpty) {
      debugPrint('HR attendance calendar API not called: access token missing.');
      _isLoading = false;
      _error = 'Login required to load attendance calendar.';
      _calendar = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.hrAttendanceCalendar}',
      ).replace(
        queryParameters: {
          'month': '$month',
          'year': '$year',
        },
      );
      debugPrint('Calling HR attendance calendar API: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${accessToken.trim()}',
        },
      );

      debugPrint(
        'HR attendance calendar API response '
        'status=${response.statusCode}, body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'HR attendance calendar API failed with ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('HR attendance calendar API returned invalid payload');
      }

      _calendar = HrAttendanceCalendar.fromJson(decoded);
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (error) {
      debugPrint('HR attendance calendar API error: $error');
      _isLoading = false;
      _error = 'Unable to load attendance calendar.';
      notifyListeners();
    }
  }

  Future<void> retry() {
    return fetchCalendar(
      accessToken: _requestedAccessToken,
      month: _requestedMonth ?? DateTime.now().month,
      year: _requestedYear ?? DateTime.now().year,
      forceRefresh: true,
    );
  }
}
