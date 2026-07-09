import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/owner/models/lead_follow_up_item.dart';

class LeadFollowUpsProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _requestedAccessToken;
  bool _hasRequestedFollowUps = false;
  List<LeadFollowUpItem> _leads = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<LeadFollowUpItem> get leads => _leads;

  bool hasRequestFor({required String? accessToken}) {
    return _hasRequestedFollowUps && _requestedAccessToken == accessToken;
  }

  Future<void> fetchFollowUps(
    String? accessToken, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _hasRequestedFollowUps &&
        accessToken == _requestedAccessToken) {
      return;
    }

    _hasRequestedFollowUps = true;
    _requestedAccessToken = accessToken;

    if (accessToken == null || accessToken.isEmpty) {
      _isLoading = false;
      _error = 'Login required to load lead follow-ups.';
      _leads = const [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.leads}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Lead follow-ups API failed with ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      final rows = _extractLeadRows(decoded);

      _leads = rows
          .whereType<Map<String, dynamic>>()
          .map(LeadFollowUpItem.fromJson)
          .where((lead) => lead.followUpTasks.isNotEmpty)
          .toList();
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      _error = 'Unable to load lead follow-ups.';
      notifyListeners();
    }
  }

  Future<void> retry() {
    return fetchFollowUps(_requestedAccessToken, forceRefresh: true);
  }

  List<dynamic> _extractLeadRows(dynamic payload) {
    if (payload is List) {
      return payload;
    }

    if (payload is Map<String, dynamic>) {
      for (final key in const ['data', 'leads', 'items', 'results']) {
        final value = payload[key];

        if (value is List) {
          return value;
        }

        final nestedRows = _extractLeadRows(value);
        if (nestedRows.isNotEmpty) {
          return nestedRows;
        }
      }
    }

    return const [];
  }
}
