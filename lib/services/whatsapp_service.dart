import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:koniwalamatrimonial/constants/api_constants.dart';

class WhatsappService {
  const WhatsappService();

  Future<dynamic> fetchStatus({required String accessToken}) async {
    final uri = _uri(ApiConstants.whatsappStatus);
    _debugRequest('GET', uri);
    return _decode(await http.get(uri, headers: _headers(accessToken)));
  }

  Future<dynamic> fetchProfilePicture({required String accessToken}) async {
    final uri = _uri(ApiConstants.whatsappProfilePicture);
    _debugRequest('GET', uri);
    return _decode(await http.get(uri, headers: _headers(accessToken)));
  }

  Future<dynamic> fetchConversations({
    required String accessToken,
    String? search,
    bool? includeArchived,
    bool? debug,
    int limit = 20,
    String? cursor,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
      if (_hasValue(search)) 'search': search!.trim(),
      if (includeArchived != null) 'includeArchived': '$includeArchived',
      if (debug != null) 'debug': '$debug',
      if (_hasValue(cursor)) 'cursor': cursor!.trim(),
    };
    final uri = _uri(ApiConstants.whatsappConversations, query);
    _debugRequest('GET', uri);

    return _decode(await http.get(uri, headers: _headers(accessToken)));
  }

  Future<dynamic> fetchMessages({
    required String accessToken,
    required String leadId,
    int limit = 20,
    String? cursor,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
      if (_hasValue(cursor)) 'cursor': cursor!.trim(),
    };
    final uri = _uri(ApiConstants.whatsappConversationMessages(leadId), query);
    _debugRequest('GET', uri);

    return _decode(await http.get(uri, headers: _headers(accessToken)));
  }

  Future<dynamic> fetchTemplates({
    required String accessToken,
    String status = 'ALL',
  }) async {
    final uri = _uri(ApiConstants.whatsappTemplates, {'status': status});
    _debugRequest('GET', uri);
    return _decode(await http.get(uri, headers: _headers(accessToken)));
  }

  Future<dynamic> fetchLeadDetail({
    required String accessToken,
    required String leadId,
  }) async {
    final uri = _uri(ApiConstants.lead(leadId));
    _debugRequest('GET', uri);
    return _decode(await http.get(uri, headers: _headers(accessToken)));
  }

  Future<dynamic> addLeadComment({
    required String accessToken,
    required String leadId,
    required String content,
  }) async {
    final uri = _uri(ApiConstants.leadComments(leadId));
    final body = {'content': content};
    _debugRequest('POST', uri, body: body);
    return _decode(
      await http.post(
        uri,
        headers: _headers(accessToken, json: true),
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> fetchLeads({required String accessToken}) async {
    final uri = _uri(ApiConstants.leads);
    _debugRequest('GET', uri);
    return _decode(await http.get(uri, headers: _headers(accessToken)));
  }

  Future<dynamic> createLead({
    required String accessToken,
    required String name,
    required String phone,
    required String source,
    required String leadFor,
    String city = '',
    String notes = '',
  }) async {
    final uri = _uri(ApiConstants.leads);
    final body = {
      'name': name,
      'phone': phone,
      'source': source,
      'leadFor': leadFor,
      if (city.trim().isNotEmpty) 'city': city.trim(),
      if (notes.trim().isNotEmpty) 'notes': notes.trim(),
    };
    _debugRequest('POST', uri, body: body);
    return _decode(
      await http.post(
        uri,
        headers: _headers(accessToken, json: true),
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> sendMessage({
    required String accessToken,
    required String leadId,
    required String phone,
    required String content,
    String? templateName,
    String templateLanguage = 'en',
    dynamic media,
  }) async {
    final uri = _uri(ApiConstants.whatsappSend);
    final body = {
      'leadId': leadId,
      'phone': phone,
      'content': content,
      'templateName': templateName,
      'templateLanguage': templateLanguage,
      'media': media,
    };
    _debugRequest('POST', uri, body: body);
    return _decode(
      await http.post(
        uri,
        headers: _headers(accessToken, json: true),
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> markConversationRead({
    required String accessToken,
    required String leadId,
    required String messageId,
  }) async {
    final uri = _uri(ApiConstants.whatsappConversationRead(leadId));
    final body = {'messageId': messageId};
    _debugRequest('POST', uri, body: body);
    return _decode(
      await http.post(
        uri,
        headers: _headers(accessToken, json: true),
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> markMessageRead({
    required String accessToken,
    required String messageId,
  }) async {
    final uri = _uri(ApiConstants.whatsappMessagesRead);
    final body = {'messageId': messageId};
    _debugRequest('POST', uri, body: body);
    return _decode(
      await http.post(
        uri,
        headers: _headers(accessToken, json: true),
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> editMessage({
    required String accessToken,
    required String messageId,
    required String content,
  }) async {
    final uri = _uri(ApiConstants.whatsappMessage(messageId));
    final body = {'content': content};
    _debugRequest('PATCH', uri, body: body);
    return _decode(
      await http.patch(
        uri,
        headers: _headers(accessToken, json: true),
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> deleteMessage({
    required String accessToken,
    required String messageId,
    bool forEveryone = false,
  }) async {
    final uri = _uri(ApiConstants.whatsappMessage(messageId), {
      'forEveryone': '$forEveryone',
    });
    _debugRequest('DELETE', uri);
    return _decode(await http.delete(uri, headers: _headers(accessToken)));
  }

  Future<dynamic> clearConversation({
    required String accessToken,
    required String leadId,
  }) async {
    final uri = _uri(ApiConstants.whatsappConversation(leadId));
    _debugRequest('DELETE', uri);
    return _decode(await http.delete(uri, headers: _headers(accessToken)));
  }

  Uri mediaUri(String mediaId) {
    return _uri(ApiConstants.whatsappMedia(mediaId));
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse('${ApiConstants.baseUrl}$path');
    if (query == null || query.isEmpty) {
      return base;
    }
    return base.replace(queryParameters: query);
  }

  Map<String, String> _headers(String accessToken, {bool json = false}) {
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      'Authorization': 'Bearer ${accessToken.trim()}',
    };
  }

  dynamic _decode(http.Response response) {
    _debugResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractApiError(response.body) ??
            'WhatsApp API failed with ${response.statusCode}',
      );
    }

    if (response.body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  String? _extractApiError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final message = decoded['message'] ?? decoded['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
        if (message is List && message.isNotEmpty) {
          return message.join(', ');
        }
      }
    } catch (_) {}
    return null;
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  void _debugRequest(String method, Uri uri, {Object? body}) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('[WhatsApp API] -> $method $uri');
    debugPrint('[WhatsApp API] -> headers: Authorization=<redacted>');
    if (body != null) {
      debugPrint('[WhatsApp API] -> body: ${_safeDebugJson(body)}');
    }
  }

  void _debugResponse(http.Response response) {
    if (!kDebugMode) {
      return;
    }

    final request = response.request;
    final requestLabel = request == null
        ? ''
        : ' ${request.method} ${request.url}';
    debugPrint(
      '[WhatsApp API] <-${requestLabel.isEmpty ? '' : requestLabel} '
      'status=${response.statusCode}',
    );
    debugPrint('[WhatsApp API] <- body: ${_safeDebugBody(response.body)}');
  }

  String _safeDebugJson(Object value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  String _safeDebugBody(String body) {
    if (body.trim().isEmpty) {
      return '<empty>';
    }

    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(body));
    } catch (_) {
      return body;
    }
  }
}
