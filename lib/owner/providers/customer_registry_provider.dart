import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/owner/models/customer_registry_item.dart';

class CustomerRegistryProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _requestedAccessToken;
  bool _hasRequestedCustomers = false;
  List<CustomerRegistryItem> _customers = const [];
  final Set<String> _removingCustomerIds = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<CustomerRegistryItem> get customers => _customers;

  bool isRemovingCustomer(String customerId) {
    return _removingCustomerIds.contains(customerId);
  }

  Future<void> fetchCustomers(
    String? accessToken, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _hasRequestedCustomers &&
        accessToken == _requestedAccessToken) {
      return;
    }

    _hasRequestedCustomers = true;
    _requestedAccessToken = accessToken;

    if (accessToken == null || accessToken.isEmpty) {
      _isLoading = false;
      _error = 'Login required to load client registry.';
      _customers = const [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.customers}');
      debugPrint('Customers API: GET $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      debugPrint('Customers API response: ${response.statusCode}');
      debugPrint('Customers API body length: ${response.body.length}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Customers API failed with ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      final customerRows = _extractCustomerRows(decoded);

      _customers =
          customerRows
              .whereType<Map<String, dynamic>>()
              .map(CustomerRegistryItem.fromJson)
              .toList()
            ..sort((left, right) {
              final rightDate = right.createdAt;
              final leftDate = left.createdAt;

              if (rightDate == null && leftDate == null) return 0;
              if (rightDate == null) return -1;
              if (leftDate == null) return 1;

              return rightDate.compareTo(leftDate);
            });
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      _error = 'Unable to load client registry.';
      notifyListeners();
    }
  }

  Future<void> retry() {
    return fetchCustomers(_requestedAccessToken, forceRefresh: true);
  }

  Future<String?> deleteCustomer(
    CustomerRegistryItem customer,
    String? accessToken,
  ) async {
    if (accessToken == null || accessToken.isEmpty) {
      return 'Login required to delete client.';
    }

    if (customer.id.isEmpty) {
      return 'Client id is missing.';
    }

    _removingCustomerIds.add(customer.id);
    notifyListeners();

    try {
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.customer(customer.id)}';
      debugPrint('Calling customer delete API: $url');
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${accessToken.trim()}',
        },
      );

      debugPrint(
        'Customer delete API response status=${response.statusCode}, '
        'body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _extractErrorMessage(response.body) ??
            'Unable to delete client.';
      }

      _customers = _customers.where((item) => item.id != customer.id).toList();
      return null;
    } catch (error) {
      return 'Unable to delete client. ${error.toString()}';
    } finally {
      _removingCustomerIds.remove(customer.id);
      notifyListeners();
    }
  }

  List<dynamic> _extractCustomerRows(dynamic payload) {
    if (payload is List) {
      return payload;
    }

    if (payload is Map<String, dynamic>) {
      for (final key in const ['data', 'customers', 'items', 'results']) {
        final value = payload[key];

        if (value is List) {
          return value;
        }

        final nestedRows = _extractCustomerRows(value);
        if (nestedRows.isNotEmpty) {
          return nestedRows;
        }
      }
    }

    return const [];
  }

  String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        for (final key in const ['message', 'error', 'detail']) {
          final value = decoded[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
