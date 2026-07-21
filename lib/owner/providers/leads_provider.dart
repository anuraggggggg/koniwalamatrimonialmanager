import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/owner/models/lead_registry_item.dart';

class RelationshipManagerOption {
  const RelationshipManagerOption({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  String get displayLabel => email.isEmpty ? name : '$name - $email';
}

class LeadsProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isCreatingLead = false;
  String? _error;
  String? _requestedAccessToken;
  bool _hasRequestedLeads = false;
  List<LeadRegistryItem> _leads = const [];
  List<RelationshipManagerOption> _managers = const [];
  final Set<String> _removingLeadKeys = <String>{};

  bool get isLoading => _isLoading;
  bool get isCreatingLead => _isCreatingLead;
  String? get error => _error;
  List<LeadRegistryItem> get leads => _leads;
  List<RelationshipManagerOption> get managers => _managers;

  bool isRemovingLead(LeadRegistryItem lead) {
    return _removingLeadKeys.contains(_leadKey(lead));
  }

  Future<void> fetchManagers(String? accessToken) async {
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.relationshipManagers}',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final rows = _extractRows(decoded);
        _managers = rows
            .whereType<Map<String, dynamic>>()
            .map(
              (json) => RelationshipManagerOption(
                id: _readText(json['id']),
                name: _readText(json['name']),
                email: _readText(json['email']),
              ),
            )
            .toList();
        notifyListeners();
      }
    } catch (_) {
      // Silently fail for managers as it's secondary to leads
    }
  }

  List<dynamic> _extractRows(dynamic payload) {
    if (payload is List) {
      return payload;
    }

    if (payload is Map<String, dynamic>) {
      for (final key in const [
        'data',
        'users',
        'items',
        'results',
        'managers',
      ]) {
        final value = payload[key];
        if (value is List) {
          return value;
        }

        final nested = _extractRows(value);
        if (nested.isNotEmpty) {
          return nested;
        }
      }
    }

    return const [];
  }

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
      _error = 'Login required to load leads.';
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

      _leads = await compute(_parseLeadRegistryItems, response.body);
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      _error = 'Unable to load leads.';
      notifyListeners();
    }
  }

  Future<void> retry() {
    return fetchLeads(_requestedAccessToken, forceRefresh: true);
  }

  Future<String?> createLead({
    required String? accessToken,
    required String name,
    required String phone,
    required String email,
    required String source,
    required String leadFor,
    required String city,
    String? assignedToId,
  }) async {
    if (accessToken == null || accessToken.isEmpty) {
      return 'Login required to create lead.';
    }

    final normalizedPhone = _normalizePhone(phone);
    final data = <String, dynamic>{
      'name': name.trim(),
      'phone': normalizedPhone,
      if (_hasRealValue(email)) 'email': email.trim(),
      'source': _enumValue(source),
      'leadFor': _enumValue(leadFor),
      if (_hasRealValue(city)) 'city': city.trim(),
      if (_hasRealValue(assignedToId ?? '')) 'assignedToId': assignedToId,
    };

    _isCreatingLead = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.leads}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${accessToken.trim()}',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _extractErrorMessage(response.body) ?? 'Unable to create lead.';
      }

      final decoded = response.body.trim().isEmpty
          ? null
          : jsonDecode(response.body);
      final responseLead = decoded is List
          ? (decoded.isNotEmpty && decoded.first is Map<String, dynamic>
                ? _extractLeadMap(decoded.first as Map<String, dynamic>)
                : null)
          : (decoded is Map<String, dynamic> ? _extractLeadMap(decoded) : null);

      if (responseLead != null) {
        _leads = [LeadRegistryItem.fromJson(responseLead), ..._leads];
      } else {
        await fetchLeads(accessToken, forceRefresh: true);
      }

      return null;
    } catch (error) {
      return 'Unable to create lead. ${error.toString()}';
    } finally {
      _isCreatingLead = false;
      notifyListeners();
    }
  }

  Future<List<RelationshipManagerOption>> fetchRelationshipManagers(
    String? accessToken,
  ) async {
    if (accessToken == null || accessToken.isEmpty) {
      return const [];
    }

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.relationshipManagers}',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }

      final rows = _extractLeadRows(jsonDecode(response.body));
      return rows
          .whereType<Map<String, dynamic>>()
          .map(
            (row) => RelationshipManagerOption(
              id: _readText(row['id']),
              name: _readText(row['name'], fallback: _readText(row['email'])),
              email: _readText(row['email']),
            ),
          )
          .where((manager) => manager.id.isNotEmpty && manager.name.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<String?> updateLead({
    required LeadRegistryItem lead,
    required String? accessToken,
    required String name,
    required String phone,
    required String email,
    required String stage,
    required String city,
    required String source,
    required String leadFor,
    required String assignedToId,
    required String assignedToName,
    File? image,
  }) async {
    if (accessToken == null || accessToken.isEmpty) {
      return 'Login required to update lead.';
    }

    if (lead.id.isEmpty) {
      return 'Lead id is missing.';
    }

    final normalizedPhone = _normalizePhone(phone);
    final data = <String, dynamic>{
      'name': name.trim(),
      if (_hasRealValue(normalizedPhone)) 'phone': normalizedPhone,
      if (_hasRealValue(email)) 'email': email.trim(),
      if (_hasRealValue(city)) 'city': city.trim(),
      if (_hasRealValue(source)) 'source': _enumValue(source),
      if (_hasRealValue(leadFor)) 'leadFor': _enumValue(leadFor),
    };

    try {
      final url = '${ApiConstants.baseUrl}${ApiConstants.lead(lead.id)}';
      debugPrint('Calling lead update API: $url');
      debugPrint('Lead update payload: ${jsonEncode(data)}');
      final response = image == null
          ? await http.patch(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${accessToken.trim()}',
              },
              body: jsonEncode(data),
            )
          : await _patchLeadMultipart(
              url: url,
              accessToken: accessToken,
              data: data,
              image: image,
            );

      debugPrint(
        'Lead update API response status=${response.statusCode}, '
        'body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _extractErrorMessage(response.body) ?? 'Unable to update lead.';
      }

      final decoded = response.body.trim().isEmpty
          ? null
          : jsonDecode(response.body);
      final responseLead = decoded is Map<String, dynamic>
          ? _extractLeadMap(decoded)
          : null;
      final updatedLead = responseLead == null
          ? lead.copyWith(
              name: name.trim(),
              phone: _hasRealValue(normalizedPhone)
                  ? normalizedPhone
                  : lead.phone,
              email: _hasRealValue(email) ? email.trim() : lead.email,
              stage: lead.stage,
              city: _hasRealValue(city) ? city.trim() : lead.city,
              source: _hasRealValue(source)
                  ? _formatEnumLabel(data['source'])
                  : lead.source,
              leadFor: _hasRealValue(leadFor)
                  ? _formatEnumLabel(data['leadFor'])
                  : lead.leadFor,
              assignedToId: lead.assignedToId,
              assignedTo: lead.assignedTo,
              image: image?.path,
            )
          : LeadRegistryItem.fromJson(responseLead);

      _leads = _leads
          .map((item) => _leadKey(item) == _leadKey(lead) ? updatedLead : item)
          .toList();
      notifyListeners();
      return null;
    } catch (error) {
      return 'Unable to update lead. ${error.toString()}';
    }
  }

  Future<String?> updateLeadStage({
    required LeadRegistryItem lead,
    required String? accessToken,
    required String stage,
  }) async {
    if (accessToken == null || accessToken.isEmpty) {
      return 'Login required to update lead status.';
    }

    if (lead.id.isEmpty) {
      return 'Lead id is missing.';
    }

    final normalizedStage = _enumValue(stage);
    final data = {'stage': normalizedStage};

    try {
      final url = '${ApiConstants.baseUrl}${ApiConstants.lead(lead.id)}/stage';
      debugPrint('Calling lead stage API: $url');
      debugPrint('Lead stage payload: ${jsonEncode(data)}');
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${accessToken.trim()}',
        },
        body: jsonEncode(data),
      );

      debugPrint(
        'Lead stage API response status=${response.statusCode}, '
        'body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _extractErrorMessage(response.body) ??
            'Unable to update lead status.';
      }

      final decoded = response.body.trim().isEmpty
          ? null
          : jsonDecode(response.body);
      final responseLead = decoded is Map<String, dynamic>
          ? _extractLeadMap(decoded)
          : null;
      final updatedLead = responseLead == null
          ? lead.copyWith(stage: _formatEnumLabel(normalizedStage))
          : LeadRegistryItem.fromJson(responseLead);

      _leads = _leads
          .map((item) => _leadKey(item) == _leadKey(lead) ? updatedLead : item)
          .toList();
      notifyListeners();
      return null;
    } catch (error) {
      return 'Unable to update lead status. ${error.toString()}';
    }
  }

  Future<http.Response> _patchLeadMultipart({
    required String url,
    required String accessToken,
    required Map<String, dynamic> data,
    required File image,
  }) async {
    final request = http.MultipartRequest('PATCH', Uri.parse(url));
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer ${accessToken.trim()}',
    });
    request.fields.addAll(
      data.map((key, value) => MapEntry(key, value.toString())),
    );
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }

  Future<String?> deleteLead(LeadRegistryItem lead, String? accessToken) async {
    if (accessToken == null || accessToken.isEmpty) {
      return 'Login required to delete lead.';
    }

    if (lead.id.isEmpty) {
      return 'Lead id is missing.';
    }

    final leadKey = _leadKey(lead);
    _removingLeadKeys.add(leadKey);
    notifyListeners();

    try {
      final url = '${ApiConstants.baseUrl}${ApiConstants.lead(lead.id)}';
      debugPrint('Calling lead delete API: $url');
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${accessToken.trim()}',
        },
      );

      debugPrint(
        'Lead delete API response status=${response.statusCode}, '
        'body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _extractErrorMessage(response.body) ?? 'Unable to delete lead.';
      }

      _leads = _leads.where((item) => _leadKey(item) != leadKey).toList();
      return null;
    } catch (error) {
      return 'Unable to delete lead. ${error.toString()}';
    } finally {
      _removingLeadKeys.remove(leadKey);
      notifyListeners();
    }
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

  String _leadKey(LeadRegistryItem lead) {
    if (lead.shortlistCandidateId.isNotEmpty) {
      return 'candidate:${lead.shortlistCandidateId}';
    }

    if (lead.id.isNotEmpty) {
      return 'lead:${lead.id}';
    }

    return '${lead.name}|${lead.phone}|${lead.email}';
  }

  String _readText(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _enumValue(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '_');
  }

  bool _hasRealValue(String value) {
    final text = value.trim();
    return text.isNotEmpty && text != '-';
  }

  String _normalizePhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      return digits.substring(2);
    }

    if (digits.length > 10) {
      return digits.substring(digits.length - 10);
    }

    return digits;
  }

  Map<String, dynamic>? _extractLeadMap(Map<String, dynamic> payload) {
    if (payload.containsKey('id') || payload.containsKey('phone')) {
      return payload;
    }

    for (final key in const ['data', 'lead', 'result']) {
      final value = payload[key];
      if (value is Map<String, dynamic>) {
        final nested = _extractLeadMap(value);
        if (nested != null) {
          return nested;
        }
      }
    }

    return null;
  }

  String _formatEnumLabel(dynamic value) {
    final text = _readText(value);
    if (text.isEmpty) {
      return '-';
    }

    return text
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) {
          final lower = part.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  String? _extractErrorMessage(String body) {
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }

        if (message is List) {
          final messages = message
              .whereType<Object>()
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .join('\n');
          if (messages.isNotEmpty) {
            return messages;
          }
        }

        final error = decoded['error'];
        if (error is String && error.trim().isNotEmpty) {
          return error;
        }
      }
    } catch (_) {
      return body;
    }

    return null;
  }
}

List<LeadRegistryItem> _parseLeadRegistryItems(String responseBody) {
  final decoded = jsonDecode(responseBody);
  final leadRows = _extractLeadRowsForRegistry(decoded);
  return leadRows
      .whereType<Map<String, dynamic>>()
      .map(LeadRegistryItem.fromJson)
      .toList(growable: false);
}

List<dynamic> _extractLeadRowsForRegistry(dynamic payload) {
  if (payload is List) {
    return payload;
  }

  if (payload is Map<String, dynamic>) {
    for (final key in const ['data', 'leads', 'items', 'results']) {
      final value = payload[key];

      if (value is List) {
        return value;
      }

      final nestedRows = _extractLeadRowsForRegistry(value);
      if (nestedRows.isNotEmpty) {
        return nestedRows;
      }
    }
  }

  return const [];
}
