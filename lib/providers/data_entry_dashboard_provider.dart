import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/models/data_entry_stats.dart';

class DataEntryUserOption {
  const DataEntryUserOption({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;

  factory DataEntryUserOption.fromJson(Map<String, dynamic> json) {
    return DataEntryUserOption(
      id: _readText(json['id']),
      name: _readText(json['name'], fallback: _readText(json['email'])),
      email: _readText(json['email']),
      phone: _readText(json['phone']),
      role: _readText(json['role']),
    );
  }

  static String _readText(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}

class DataEntryDashboardProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isLoadingUsers = false;
  String? _error;
  String? _requestedAccessToken;
  String? _requestedUsersAccessToken;
  bool _hasRequestedDashboard = false;
  bool _hasRequestedUsers = false;
  DataEntryStats? _dashboard;
  List<DataEntryUserOption> _dataEntryUsers = const [];

  bool get isLoading => _isLoading;
  bool get isLoadingUsers => _isLoadingUsers;
  String? get error => _error;
  DataEntryStats? get dashboard => _dashboard;
  List<DataEntryUserOption> get dataEntryUsers => _dataEntryUsers;

  Future<void> fetchDashboard(
    String? accessToken, {
    bool forceRefresh = false,
  }) async {
    debugPrint(
      'DataEntryDashboardProvider.fetchDashboard called. '
      'hasToken=${accessToken != null && accessToken.isNotEmpty}, '
      'forceRefresh=$forceRefresh',
    );

    if (!forceRefresh &&
        _hasRequestedDashboard &&
        accessToken == _requestedAccessToken) {
      debugPrint('Data entry dashboard API skipped: request already loaded.');
      return;
    }

    _hasRequestedDashboard = true;
    _requestedAccessToken = accessToken;

    if (accessToken == null || accessToken.isEmpty) {
      debugPrint('Data entry dashboard API not called: access token missing.');
      _isLoading = false;
      _error = 'Login required to load data entry dashboard.';
      _dashboard = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = '${ApiConstants.baseUrl}${ApiConstants.dataEntryDashboard}';
      final authorization = 'Bearer ${accessToken.trim()}';
      debugPrint('Calling data entry dashboard API: $url');
      debugPrint(
        'Data entry dashboard Authorization header: '
        'Bearer ${_tokenPreview(accessToken)}',
      );

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json', 'Authorization': authorization},
      );

      debugPrint(
        'Data entry dashboard API response '
        'status=${response.statusCode}, body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Data entry dashboard API failed with ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Data entry dashboard API returned invalid payload');
      }

      _dashboard = DataEntryStats.fromJson(decoded);
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (error) {
      debugPrint('Data entry dashboard API error: $error');
      _isLoading = false;
      _error = 'Unable to load data entry dashboard.';
      notifyListeners();
    }
  }

  Future<void> retry() {
    return fetchDashboard(_requestedAccessToken, forceRefresh: true);
  }

  Future<void> fetchDataEntryUsers(
    String? accessToken, {
    bool forceRefresh = false,
  }) async {
    debugPrint(
      'DataEntryDashboardProvider.fetchDataEntryUsers called. '
      'hasToken=${accessToken != null && accessToken.isNotEmpty}, '
      'forceRefresh=$forceRefresh',
    );

    if (!forceRefresh &&
        _hasRequestedUsers &&
        accessToken == _requestedUsersAccessToken) {
      debugPrint('Data entry users API skipped: request already loaded.');
      return;
    }

    _hasRequestedUsers = true;
    _requestedUsersAccessToken = accessToken;

    if (accessToken == null || accessToken.isEmpty) {
      debugPrint('Data entry users API not called: access token missing.');
      _isLoadingUsers = false;
      _dataEntryUsers = const [];
      notifyListeners();
      return;
    }

    _isLoadingUsers = true;
    notifyListeners();

    try {
      final url = '${ApiConstants.baseUrl}${ApiConstants.dataEntryUsers}';
      final authorization = 'Bearer ${accessToken.trim()}';
      debugPrint('Calling data entry users API: $url');
      debugPrint(
        'Data entry users Authorization header: '
        'Bearer ${_tokenPreview(accessToken)}',
      );

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json', 'Authorization': authorization},
      );

      debugPrint(
        'Data entry users API response '
        'status=${response.statusCode}, body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Data entry users API failed with ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      final rows = _extractRows(decoded);
      _dataEntryUsers = rows
          .whereType<Map<String, dynamic>>()
          .map(DataEntryUserOption.fromJson)
          .where((user) => user.id.isNotEmpty && user.name.isNotEmpty)
          .toList();
      _isLoadingUsers = false;
      notifyListeners();
    } catch (error) {
      debugPrint('Data entry users API error: $error');
      _isLoadingUsers = false;
      _dataEntryUsers = const [];
      notifyListeners();
    }
  }

  String _tokenPreview(String token) {
    final trimmed = token.trim();
    if (trimmed.length <= 12) {
      return trimmed;
    }

    return '${trimmed.substring(0, 6)}...${trimmed.substring(trimmed.length - 6)}';
  }

  List<dynamic> _extractRows(dynamic payload) {
    if (payload is List) {
      return payload;
    }

    if (payload is Map<String, dynamic>) {
      for (final key in const ['data', 'users', 'items', 'results']) {
        final value = payload[key];
        if (value is List) {
          return value;
        }

        final nestedRows = _extractRows(value);
        if (nestedRows.isNotEmpty) {
          return nestedRows;
        }
      }
    }

    return const [];
  }
}
