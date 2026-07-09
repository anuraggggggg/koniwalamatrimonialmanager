import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/models/app_notification.dart';

class NotificationsProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _requestedAccessToken;
  bool _hasRequestedNotifications = false;
  List<AppNotification> _notifications = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AppNotification> get notifications => _notifications;

  bool hasRequestFor({required String? accessToken}) {
    return _hasRequestedNotifications && _requestedAccessToken == accessToken;
  }

  Future<void> fetchNotifications(
    String? accessToken, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _hasRequestedNotifications &&
        accessToken == _requestedAccessToken) {
      return;
    }

    _hasRequestedNotifications = true;
    _requestedAccessToken = accessToken;

    if (accessToken == null || accessToken.isEmpty) {
      _isLoading = false;
      _error = 'Login required to load notifications.';
      _notifications = const [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.notifications}',
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Notifications API failed with ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      _notifications = AppNotification.listFromAny(decoded);
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      _error = 'Unable to load notifications.';
      notifyListeners();
    }
  }

  Future<void> retry() {
    return fetchNotifications(_requestedAccessToken, forceRefresh: true);
  }
}
