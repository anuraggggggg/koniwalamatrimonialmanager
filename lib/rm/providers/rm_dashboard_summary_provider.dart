import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/rm/models/rm_dashboard_summary.dart';

class RmDashboardSummaryProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _requestedAccessToken;
  bool _hasRequestedSummary = false;
  RmDashboardSummary? _summary;

  bool get isLoading => _isLoading;
  String? get error => _error;
  RmDashboardSummary? get summary => _summary;

  Future<void> fetchSummary(
    String? accessToken, {
    bool forceRefresh = false,
  }) async {
    debugPrint(
      'RmDashboardSummaryProvider.fetchSummary called. '
      'hasToken=${accessToken != null && accessToken.isNotEmpty}, '
      'forceRefresh=$forceRefresh',
    );

    if (!forceRefresh &&
        _hasRequestedSummary &&
        accessToken == _requestedAccessToken) {
      debugPrint('RM dashboard summary API skipped: request already loaded.');
      return;
    }

    _hasRequestedSummary = true;
    _requestedAccessToken = accessToken;

    if (accessToken == null || accessToken.isEmpty) {
      debugPrint('RM dashboard summary API not called: access token missing.');
      _isLoading = false;
      _error = 'Login required to load RM dashboard summary.';
      _summary = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = '${ApiConstants.baseUrl}${ApiConstants.rmDashboardSummary}';
      debugPrint('Calling RM dashboard summary API: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${accessToken.trim()}',
        },
      );

      debugPrint(
        'RM dashboard summary API response '
        'status=${response.statusCode}, body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'RM dashboard summary API failed with ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('RM dashboard summary API returned invalid payload');
      }

      _summary = RmDashboardSummary.fromJson(decoded);
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (error) {
      debugPrint('RM dashboard summary API error: $error');
      _isLoading = false;
      _error = 'Unable to load RM dashboard summary.';
      notifyListeners();
    }
  }

  Future<void> retry() {
    return fetchSummary(_requestedAccessToken, forceRefresh: true);
  }
}
