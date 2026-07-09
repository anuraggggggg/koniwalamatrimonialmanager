import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/rm/models/rm_lead_item.dart';

class RmLeadsProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _requestedAccessToken;
  bool _hasRequestedLeads = false;
  List<RmLeadItem> _leads = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<RmLeadItem> get leads => _leads;

  Future<void> fetchLeads(
    String? accessToken, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _hasRequestedLeads &&
        accessToken == _requestedAccessToken) {
      return;
    }

    _hasRequestedLeads = true;
    _requestedAccessToken = accessToken;

    if (accessToken == null || accessToken.isEmpty) {
      _isLoading = false;
      _error = 'Login required to load manager leads.';
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
        throw Exception('Leads API failed with ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      final leadRows = _extractLeadRows(decoded);

      final parsedLeads = leadRows
          .whereType<Map<String, dynamic>>()
          .map(RmLeadItem.fromJson)
          .toList()
        ..sort((a, b) {
          final left = a.latestActivityAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final right =
              b.latestActivityAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return right.compareTo(left);
        });

      _leads = parsedLeads;
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      _error = 'Unable to load manager chat leads.';
      notifyListeners();
    }
  }

  Future<void> retry() {
    return fetchLeads(_requestedAccessToken, forceRefresh: true);
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
