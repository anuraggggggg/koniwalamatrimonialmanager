import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/models/manager_dashboard.dart';

ManagerDashboard _parseManagerDashboardResponse(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw Exception('Manager dashboard API returned invalid payload');
  }

  return ManagerDashboard.fromJson(decoded);
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

class ManagerDashboardProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _requestedAccessToken;
  String? _requestedPeriod;
  bool _hasRequestedDashboard = false;
  ManagerDashboard? _dashboard;

  bool get isLoading => _isLoading;
  String? get error => _error;
  ManagerDashboard? get dashboard => _dashboard;

  bool hasRequestFor({required String? accessToken, required String period}) {
    return _hasRequestedDashboard &&
        _requestedAccessToken == accessToken &&
        _requestedPeriod == period;
  }

  Future<void> fetchDashboard(
    String? accessToken, {
    String period = 'past_month',
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _hasRequestedDashboard &&
        accessToken == _requestedAccessToken &&
        period == _requestedPeriod) {
      return;
    }

    _hasRequestedDashboard = true;
    _requestedAccessToken = accessToken;
    _requestedPeriod = period;

    if (accessToken == null || accessToken.isEmpty) {
      _isLoading = false;
      _error = 'Login required to load manager dashboard.';
      _dashboard = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.managerDashboard}',
      ).replace(queryParameters: {'period': period});
      if (kDebugMode) {
        debugPrint('Calling manager dashboard API: $uri');
      }

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${accessToken.trim()}',
        },
      );

      if (kDebugMode) {
        debugPrint(
          'Manager dashboard API response status=${response.statusCode}',
        );
      }
      _debugPrintCompact('Manager dashboard API body: ', response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Manager dashboard API failed with ${response.statusCode}',
        );
      }

      // PERF: Dashboard payload parsing can be large enough to hitch the first
      // frame. Parse it off the UI isolate so navigation/loading stays smooth.
      _dashboard = await compute(_parseManagerDashboardResponse, response.body);
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (error) {
      debugPrint('Manager dashboard API error: $error');
      _isLoading = false;
      _error = 'Unable to load manager dashboard.';
      notifyListeners();
    }
  }

  Future<void> retry() {
    return fetchDashboard(
      _requestedAccessToken,
      period: _requestedPeriod ?? 'past_month',
      forceRefresh: true,
    );
  }
}
