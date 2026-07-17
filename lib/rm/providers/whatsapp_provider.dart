import 'package:flutter/foundation.dart';
import 'package:koniwalamatrimonial/rm/models/rm_lead_item.dart';
import 'package:koniwalamatrimonial/rm/models/whatsapp_models.dart';
import 'package:koniwalamatrimonial/services/whatsapp_service.dart';

class WhatsappProvider extends ChangeNotifier {
  WhatsappProvider(this._service);

  final WhatsappService _service;

  bool _isLoadingConversations = false;
  bool _isLoadingMoreConversations = false;
  bool _isLoadingMessages = false;
  bool _isLoadingTemplates = false;
  bool _isSending = false;
  String? _error;
  String? _messageError;
  String? _conversationCursor;
  bool _hasMoreConversations = false;
  String? _requestedAccessToken;
  String _lastSearch = '';
  bool _lastIncludeArchived = false;
  WhatsappApiStatus? _status;
  List<WhatsappConversation> _conversations = const [];
  List<WhatsappTemplate> _templates = const [];
  final Map<String, List<WhatsappMessage>> _messagesByLead = {};
  final Map<String, ValueNotifier<List<WhatsappMessage>>> _messageNotifiers =
      {};
  final Map<String, String?> _messageCursorByLead = {};
  final Map<String, bool> _hasMoreMessagesByLead = {};
  final Map<String, RmLeadItem> _leadDetailsById = {};
  final Set<String> _loadingLeadDetailIds = {};
  final Map<String, String> _leadDetailErrorsById = {};
  final Map<String, List<RmLeadComment>> _leadCommentsById = {};
  final Set<String> _loadingLeadCommentIds = {};
  final Set<String> _addingLeadCommentIds = {};
  final Map<String, String> _leadCommentErrorsById = {};

  bool get isLoadingConversations => _isLoadingConversations;
  bool get isLoadingMoreConversations => _isLoadingMoreConversations;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isLoadingTemplates => _isLoadingTemplates;
  bool get isSending => _isSending;
  String? get error => _error;
  String? get messageError => _messageError;
  WhatsappApiStatus? get status => _status;
  List<WhatsappConversation> get conversations => _conversations;
  List<WhatsappTemplate> get templates => _templates;
  bool get hasMoreConversations => _hasMoreConversations;

  List<WhatsappMessage> messagesFor(String leadId) {
    return _messagesByLead[leadId] ?? const [];
  }

  ValueListenable<List<WhatsappMessage>> messagesListenableFor(String leadId) {
    return _messageNotifierFor(leadId);
  }

  bool hasMoreMessagesFor(String leadId) {
    return _hasMoreMessagesByLead[leadId] ?? false;
  }

  RmLeadItem? leadDetailFor(String leadId) {
    return _leadDetailsById[leadId];
  }

  bool isLoadingLeadDetail(String leadId) {
    return _loadingLeadDetailIds.contains(leadId);
  }

  String? leadDetailErrorFor(String leadId) {
    return _leadDetailErrorsById[leadId];
  }

  List<RmLeadComment> commentsFor(String leadId) {
    return _leadCommentsById[leadId] ??
        _leadDetailsById[leadId]?.comments ??
        const [];
  }

  bool isLoadingComments(String leadId) {
    return _loadingLeadCommentIds.contains(leadId);
  }

  bool isAddingComment(String leadId) {
    return _addingLeadCommentIds.contains(leadId);
  }

  String? commentErrorFor(String leadId) {
    return _leadCommentErrorsById[leadId];
  }

  Future<void> initialize(String? accessToken) async {
    if (accessToken == null || accessToken.trim().isEmpty) {
      _error = 'Login required to load WhatsApp conversations.';
      _conversations = const [];
      notifyListeners();
      return;
    }

    if (_requestedAccessToken == accessToken && _conversations.isNotEmpty) {
      return;
    }

    _requestedAccessToken = accessToken;
    await Future.wait([
      fetchStatus(accessToken),
      fetchTemplates(accessToken),
      fetchConversations(accessToken: accessToken, forceRefresh: true),
    ]);
  }

  Future<void> fetchStatus(String accessToken) async {
    try {
      final payload = await _service.fetchStatus(accessToken: accessToken);
      _status = WhatsappApiStatus.fromAny(payload);
      notifyListeners();
    } catch (_) {
      _status = null;
      notifyListeners();
    }
  }

  Future<void> fetchTemplates(
    String accessToken, {
    String status = 'ALL',
  }) async {
    if (accessToken.trim().isEmpty) {
      _templates = const [];
      _isLoadingTemplates = false;
      notifyListeners();
      return;
    }

    _isLoadingTemplates = true;
    notifyListeners();

    try {
      final payload = await _service.fetchTemplates(
        accessToken: accessToken,
        status: status,
      );
      var templates = parseWhatsappTemplates(payload);
      if (templates.isEmpty && status.toUpperCase() != 'ALL') {
        final fallbackPayload = await _service.fetchTemplates(
          accessToken: accessToken,
          status: 'ALL',
        );
        templates = parseWhatsappTemplates(fallbackPayload);
      }
      _templates = templates;
      _isLoadingTemplates = false;
      notifyListeners();
    } catch (error) {
      if (status.toUpperCase() != 'ALL') {
        try {
          final fallbackPayload = await _service.fetchTemplates(
            accessToken: accessToken,
            status: 'ALL',
          );
          _templates = parseWhatsappTemplates(fallbackPayload);
          _isLoadingTemplates = false;
          notifyListeners();
          return;
        } catch (_) {
          // Keep the original error path below.
        }
      }
      if (kDebugMode) {
        debugPrint('[WhatsApp Provider] fetch templates failed: $error');
      }
      _templates = const [];
      _isLoadingTemplates = false;
      notifyListeners();
    }
  }

  Future<void> fetchLeadDetail({
    required String? accessToken,
    required WhatsappConversation conversation,
    bool forceRefresh = false,
  }) async {
    final leadId = conversation.leadId;
    if (leadId.isEmpty) {
      _leadDetailErrorsById[leadId] = 'Lead details are unavailable.';
      notifyListeners();
      return;
    }

    if (!forceRefresh && _leadDetailsById.containsKey(leadId)) {
      return;
    }

    if (accessToken == null || accessToken.trim().isEmpty) {
      _leadDetailErrorsById[leadId] = 'Login required to load lead details.';
      notifyListeners();
      return;
    }

    if (_loadingLeadDetailIds.contains(leadId)) {
      return;
    }

    _loadingLeadDetailIds.add(leadId);
    _leadDetailErrorsById.remove(leadId);
    notifyListeners();

    try {
      final payload = await _service.fetchLeadDetail(
        accessToken: accessToken,
        leadId: leadId,
      );
      final leadMap = _extractLeadDetailMap(payload);
      if (leadMap == null) {
        final fallbackLead = await _findLeadByConversation(
          accessToken: accessToken,
          conversation: conversation,
        );
        if (fallbackLead == null) {
          _leadDetailErrorsById[leadId] = 'No lead details returned.';
        } else {
          _leadDetailsById[leadId] = fallbackLead;
          _leadCommentsById[leadId] = fallbackLead.comments;
          _leadDetailErrorsById.remove(leadId);
        }
      } else {
        final lead = RmLeadItem.fromJson(leadMap);
        _leadDetailsById[leadId] = lead;
        _leadCommentsById[leadId] = lead.comments;
        _leadDetailErrorsById.remove(leadId);
      }
    } catch (error) {
      final fallbackLead = await _findLeadByConversation(
        accessToken: accessToken,
        conversation: conversation,
      );
      if (fallbackLead == null) {
        _leadDetailErrorsById[leadId] = _cleanError(
          error,
          'Unable to load lead details.',
        );
      } else {
        _leadDetailsById[leadId] = fallbackLead;
        _leadCommentsById[leadId] = fallbackLead.comments;
        _leadDetailErrorsById.remove(leadId);
      }
    } finally {
      _loadingLeadDetailIds.remove(leadId);
      notifyListeners();
    }
  }

  Future<void> fetchLeadComments({
    required String? accessToken,
    required String leadId,
    bool forceRefresh = false,
  }) async {
    if (leadId.isEmpty) {
      return;
    }
    if (!forceRefresh && _leadCommentsById.containsKey(leadId)) {
      return;
    }
    if (accessToken == null || accessToken.trim().isEmpty) {
      _leadCommentErrorsById[leadId] = 'Login required to load comments.';
      notifyListeners();
      return;
    }
    if (_loadingLeadCommentIds.contains(leadId)) {
      return;
    }

    _loadingLeadCommentIds.add(leadId);
    _leadCommentErrorsById.remove(leadId);
    notifyListeners();

    try {
      final payload = await _service.fetchLeadDetail(
        accessToken: accessToken,
        leadId: leadId,
      );
      final leadMap = _extractLeadDetailMap(payload);
      if (leadMap == null) {
        _leadCommentsById[leadId] = _parseLeadComments(payload);
      } else {
        final lead = RmLeadItem.fromJson(leadMap);
        _leadDetailsById[leadId] = lead;
        _leadCommentsById[leadId] = lead.comments;
      }
      _leadCommentErrorsById.remove(leadId);
    } catch (error) {
      _leadCommentErrorsById[leadId] = _cleanError(
        error,
        'Unable to refresh lead comments.',
      );
    } finally {
      _loadingLeadCommentIds.remove(leadId);
      notifyListeners();
    }
  }

  Future<String?> addLeadComment({
    required String? accessToken,
    required String leadId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return 'Please enter a comment.';
    }
    if (accessToken == null || accessToken.trim().isEmpty) {
      return 'Login required to add comments.';
    }
    if (_addingLeadCommentIds.contains(leadId)) {
      return null;
    }

    _addingLeadCommentIds.add(leadId);
    notifyListeners();

    try {
      final payload = await _service.addLeadComment(
        accessToken: accessToken,
        leadId: leadId,
        content: trimmed,
      );
      final createdComments = _parseLeadComments(payload);
      if (createdComments.isNotEmpty) {
        final existing = commentsFor(leadId);
        _leadCommentsById[leadId] = [
          createdComments.first,
          ...existing.where((item) => item.id != createdComments.first.id),
        ];
        notifyListeners();
      }
      try {
        await fetchLeadComments(
          accessToken: accessToken,
          leadId: leadId,
          forceRefresh: true,
        );
      } catch (_) {
        // The POST succeeded. Keep the optimistic comment if refresh fails.
      }
      return null;
    } catch (error) {
      return _cleanError(error, 'Unable to add comment.');
    } finally {
      _addingLeadCommentIds.remove(leadId);
      notifyListeners();
    }
  }

  Future<void> fetchConversations({
    required String? accessToken,
    String search = '',
    bool includeArchived = false,
    bool forceRefresh = false,
  }) async {
    if (accessToken == null || accessToken.trim().isEmpty) {
      _isLoadingConversations = false;
      _error = 'Login required to load WhatsApp conversations.';
      _conversations = const [];
      notifyListeners();
      return;
    }

    if (!forceRefresh &&
        _requestedAccessToken == accessToken &&
        _lastSearch == search &&
        _lastIncludeArchived == includeArchived &&
        _conversations.isNotEmpty) {
      return;
    }

    _requestedAccessToken = accessToken;
    _lastSearch = search;
    _lastIncludeArchived = includeArchived;
    _isLoadingConversations = true;
    _error = null;
    notifyListeners();

    try {
      final payload = await _service.fetchConversations(
        accessToken: accessToken,
        search: search,
        includeArchived: includeArchived,
        debug: kDebugMode,
        limit: 20,
      );
      final result = parseWhatsappConversations(payload);
      _conversations = result.items;
      _conversationCursor = result.nextCursor;
      _hasMoreConversations = result.hasMore || result.nextCursor != null;
      _isLoadingConversations = false;
      _error = null;
      notifyListeners();
    } catch (error) {
      _isLoadingConversations = false;
      _error = _cleanError(error, 'Unable to load WhatsApp conversations.');
      notifyListeners();
    }
  }

  Future<void> loadMoreConversations() async {
    final accessToken = _requestedAccessToken;
    final cursor = _conversationCursor;
    if (_isLoadingMoreConversations ||
        !_hasMoreConversations ||
        accessToken == null ||
        cursor == null) {
      return;
    }

    _isLoadingMoreConversations = true;
    notifyListeners();

    try {
      final payload = await _service.fetchConversations(
        accessToken: accessToken,
        search: _lastSearch,
        includeArchived: _lastIncludeArchived,
        debug: kDebugMode,
        limit: 20,
        cursor: cursor,
      );
      final result = parseWhatsappConversations(payload);
      _conversations = [..._conversations, ...result.items];
      _conversationCursor = result.nextCursor;
      _hasMoreConversations = result.hasMore || result.nextCursor != null;
      _isLoadingMoreConversations = false;
      notifyListeners();
    } catch (_) {
      _isLoadingMoreConversations = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages({
    required String? accessToken,
    required String leadId,
    bool forceRefresh = false,
  }) async {
    if (accessToken == null || accessToken.trim().isEmpty) {
      _messageError = 'Login required to load WhatsApp messages.';
      notifyListeners();
      return;
    }

    if (!forceRefresh && (_messagesByLead[leadId]?.isNotEmpty ?? false)) {
      return;
    }

    _isLoadingMessages = true;
    _messageError = null;
    notifyListeners();

    try {
      final payload = await _service.fetchMessages(
        accessToken: accessToken,
        leadId: leadId,
        limit: 30,
      );
      final result = parseWhatsappMessages(payload);
      final localMessages = messagesFor(
        leadId,
      ).where(_isLocalMessage).toList(growable: false);
      _setMessages(leadId, _mergeMessages(result.items, localMessages));
      _messageCursorByLead[leadId] = result.nextCursor;
      _hasMoreMessagesByLead[leadId] =
          result.hasMore || result.nextCursor != null;
      _isLoadingMessages = false;
      _messageError = null;
      notifyListeners();
    } catch (error) {
      _isLoadingMessages = false;
      _messageError = _cleanError(error, 'Unable to load WhatsApp messages.');
      notifyListeners();
    }
  }

  Future<void> loadMoreMessages({
    required String accessToken,
    required String leadId,
  }) async {
    final cursor = _messageCursorByLead[leadId];
    if (_isLoadingMessages ||
        cursor == null ||
        !(_hasMoreMessagesByLead[leadId] ?? false)) {
      return;
    }

    _isLoadingMessages = true;
    notifyListeners();

    try {
      final payload = await _service.fetchMessages(
        accessToken: accessToken,
        leadId: leadId,
        limit: 30,
        cursor: cursor,
      );
      final result = parseWhatsappMessages(payload);
      _setMessages(leadId, [...result.items, ...messagesFor(leadId)]);
      _messageCursorByLead[leadId] = result.nextCursor;
      _hasMoreMessagesByLead[leadId] =
          result.hasMore || result.nextCursor != null;
      _isLoadingMessages = false;
      notifyListeners();
    } catch (_) {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<String?> sendText({
    required String? accessToken,
    required WhatsappConversation conversation,
    required String content,
  }) {
    return _send(
      accessToken: accessToken,
      conversation: conversation,
      content: content,
    );
  }

  Future<String?> sendTemplate({
    required String? accessToken,
    required WhatsappConversation conversation,
    required WhatsappTemplate template,
  }) {
    final content = template.previewForContact(
      conversation.name,
      fallback: conversation.phone,
    );
    return _send(
      accessToken: accessToken,
      conversation: conversation,
      content: content,
      templateName: template.name,
      templateLanguage: template.language,
    );
  }

  Future<String?> sendMedia({
    required String? accessToken,
    required WhatsappConversation conversation,
    required String mediaDataUrl,
    required String mediaType,
    required String mediaFileName,
    required String mediaMimeType,
    required int mediaSize,
    String content = '',
  }) {
    return _send(
      accessToken: accessToken,
      conversation: conversation,
      content: content,
      media: mediaDataUrl,
      mediaType: mediaType,
      mediaFileName: mediaFileName,
      mediaMimeType: mediaMimeType,
      mediaSize: mediaSize,
    );
  }

  Future<String?> _send({
    required String? accessToken,
    required WhatsappConversation conversation,
    required String content,
    String? templateName,
    String templateLanguage = 'en',
    dynamic media,
    String? mediaType,
    String mediaFileName = '',
    String mediaMimeType = '',
    int mediaSize = 0,
  }) async {
    if (accessToken == null || accessToken.trim().isEmpty) {
      return 'Login required to send WhatsApp messages.';
    }
    if (conversation.leadId.isEmpty || conversation.phone.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[WhatsApp Provider] Missing send identity: '
          'leadId="${conversation.leadId}", phone="${conversation.phone}", '
          'conversationId="${conversation.id}", raw=${conversation.raw}',
        );
      }
      return 'Lead id or phone number is missing.';
    }

    _isSending = true;
    final localMessage = _localOutgoingMessage(
      conversation: conversation,
      content: content,
      templateName: templateName,
      media: media,
      mediaType: mediaType,
      mediaFileName: mediaFileName,
      mediaMimeType: mediaMimeType,
      mediaSize: mediaSize,
    );
    appendMessages(conversation.leadId, [localMessage]);
    _updateConversationPreview(conversation.leadId, localMessage);
    notifyListeners();

    try {
      final payload = await _service.sendMessage(
        accessToken: accessToken,
        leadId: conversation.leadId,
        phone: conversation.phone,
        content: content,
        templateName: templateName,
        templateLanguage: templateLanguage,
        media: media,
      );
      final responseMessage = parseWhatsappMessage(payload);
      final sentMessage = _normalizeSentMessage(
        responseMessage,
        fallback: localMessage.copyWith(status: 'SENT'),
      );
      _replaceMessage(conversation.leadId, localMessage, sentMessage);
      _updateConversationPreview(conversation.leadId, sentMessage);

      if (responseMessage == null) {
        await refreshLatestMessages(
          accessToken: accessToken,
          leadId: conversation.leadId,
        );
      }
      await fetchConversations(
        accessToken: accessToken,
        search: _lastSearch,
        includeArchived: _lastIncludeArchived,
        forceRefresh: true,
      );
      return null;
    } catch (error) {
      final failedMessage = localMessage.copyWith(status: 'FAILED');
      _replaceMessage(conversation.leadId, localMessage, failedMessage);
      _updateConversationPreview(conversation.leadId, failedMessage);
      return _cleanError(error, 'Unable to send WhatsApp message.');
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<int> refreshLatestMessages({
    required String accessToken,
    required String leadId,
  }) async {
    if (accessToken.trim().isEmpty || leadId.isEmpty) {
      return 0;
    }

    final payload = await _service.fetchMessages(
      accessToken: accessToken,
      leadId: leadId,
      limit: 30,
    );
    final result = parseWhatsappMessages(payload);
    return appendMessages(leadId, result.items);
  }

  Future<String?> clearConversation({
    required String? accessToken,
    required WhatsappConversation conversation,
  }) async {
    if (accessToken == null || accessToken.trim().isEmpty) {
      return 'Login required to clear this conversation.';
    }
    if (conversation.leadId.isEmpty) {
      return 'Lead id is missing for this conversation.';
    }

    try {
      await _service.clearConversation(
        accessToken: accessToken,
        leadId: conversation.leadId,
      );
      _setMessages(conversation.leadId, const []);
      _messageCursorByLead.remove(conversation.leadId);
      _hasMoreMessagesByLead[conversation.leadId] = false;
      await fetchConversations(
        accessToken: accessToken,
        search: _lastSearch,
        includeArchived: _lastIncludeArchived,
        forceRefresh: true,
      );
      notifyListeners();
      return null;
    } catch (error) {
      return _cleanError(error, 'Unable to clear this conversation.');
    }
  }

  int appendMessages(String leadId, List<WhatsappMessage> incoming) {
    if (incoming.isEmpty) {
      return 0;
    }

    final current = messagesFor(leadId);
    final merged = _mergeMessages(current, incoming);
    if (merged.length == current.length && _messageKeysEqual(merged, current)) {
      return 0;
    }

    _setMessages(leadId, merged);
    return merged.length - current.length;
  }

  Future<void> markConversationRead({
    required String? accessToken,
    required WhatsappConversation conversation,
  }) async {
    if (accessToken == null ||
        accessToken.trim().isEmpty ||
        conversation.leadId.isEmpty) {
      return;
    }

    final messageId = conversation.latestMessageWamId.isNotEmpty
        ? conversation.latestMessageWamId
        : conversation.latestMessageId;
    if (messageId.isEmpty) {
      return;
    }

    try {
      await _service.markConversationRead(
        accessToken: accessToken,
        leadId: conversation.leadId,
        messageId: messageId,
      );
    } catch (_) {
      // Read receipts are secondary; keep the conversation usable.
    }
  }

  String _cleanError(Object error, String fallback) {
    final text = error.toString().replaceFirst('Exception: ', '').trim();
    return text.isEmpty ? fallback : text;
  }

  Map<String, dynamic>? _extractLeadDetailMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      if (_looksLikeLeadMap(payload)) {
        return payload;
      }
      for (final key in const ['lead', 'data', 'item', 'result', 'customer']) {
        final value = payload[key];
        if (value is List) {
          return null;
        }
        if (value is Map<String, dynamic>) {
          return value;
        }
        if (value is Map) {
          return value.map((key, value) => MapEntry(key.toString(), value));
        }
      }
      return payload;
    }
    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  List<RmLeadComment> _parseLeadComments(dynamic payload) {
    if (payload is Map<String, dynamic> && _looksLikeCommentMap(payload)) {
      return [RmLeadComment.fromJson(payload)];
    }
    if (payload is Map) {
      final map = payload.map((key, value) => MapEntry(key.toString(), value));
      if (_looksLikeCommentMap(map)) {
        return [RmLeadComment.fromJson(map)];
      }
    }
    final rows = _extractLeadRows(payload);
    return rows
        .whereType<Map<String, dynamic>>()
        .map(RmLeadComment.fromJson)
        .toList();
  }

  bool _looksLikeCommentMap(Map<String, dynamic> value) {
    return value.containsKey('content') ||
        value.containsKey('comment') ||
        value.containsKey('text');
  }

  bool _looksLikeLeadMap(Map<String, dynamic> value) {
    return value.containsKey('id') ||
        value.containsKey('name') ||
        value.containsKey('phone') ||
        value.containsKey('stage') ||
        value.containsKey('leadFor');
  }

  Future<RmLeadItem?> _findLeadByConversation({
    required String accessToken,
    required WhatsappConversation conversation,
  }) async {
    try {
      final payload = await _service.fetchLeads(accessToken: accessToken);
      final rows = _extractLeadRows(payload);
      final conversationPhone = _normalizePhone(conversation.phone);
      final conversationName = conversation.name.trim().toLowerCase();
      for (final row in rows) {
        final map = row is Map<String, dynamic>
            ? row
            : row is Map
            ? row.map((key, value) => MapEntry(key.toString(), value))
            : null;
        if (map == null) {
          continue;
        }
        final lead = RmLeadItem.fromJson(map);
        final phoneMatches =
            conversationPhone.isNotEmpty &&
            _normalizePhone(lead.phone) == conversationPhone;
        final nameMatches =
            conversationName.isNotEmpty &&
            lead.name.trim().toLowerCase() == conversationName;
        if (phoneMatches || nameMatches) {
          return lead;
        }
      }
    } catch (_) {
      // Fallback lookup is best effort; keep the original error visible.
    }
    return null;
  }

  List<dynamic> _extractLeadRows(dynamic payload) {
    if (payload is List) {
      return payload;
    }
    if (payload is Map) {
      final map = payload is Map<String, dynamic>
          ? payload
          : payload.map((key, value) => MapEntry(key.toString(), value));
      for (final key in const [
        'data',
        'leads',
        'comments',
        'items',
        'results',
      ]) {
        final value = map[key];
        if (value is List) {
          return value;
        }
        final nested = _extractLeadRows(value);
        if (nested.isNotEmpty) {
          return nested;
        }
      }
    }
    return const [];
  }

  String _normalizePhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10 && digits.startsWith('91')) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  ValueNotifier<List<WhatsappMessage>> _messageNotifierFor(String leadId) {
    return _messageNotifiers.putIfAbsent(
      leadId,
      () => ValueNotifier<List<WhatsappMessage>>(
        _messagesByLead[leadId] ?? const [],
      ),
    );
  }

  void _setMessages(String leadId, List<WhatsappMessage> messages) {
    _messagesByLead[leadId] = messages;
    _messageNotifierFor(leadId).value = List.unmodifiable(messages);
  }

  WhatsappMessage _localOutgoingMessage({
    required WhatsappConversation conversation,
    required String content,
    String? templateName,
    dynamic media,
    String? mediaType,
    String mediaFileName = '',
    String mediaMimeType = '',
    int mediaSize = 0,
  }) {
    final now = DateTime.now();
    final localId = 'local-${now.microsecondsSinceEpoch}';
    final localMediaUrl = media is String ? media : '';
    return WhatsappMessage(
      id: localId,
      wamId: '',
      conversationId: conversation.id,
      leadId: conversation.leadId,
      direction: 'OUTBOUND',
      type: mediaType ?? (templateName == null ? 'text' : 'template'),
      content: content,
      status: 'SENDING',
      createdAt: now,
      templateName: templateName ?? '',
      mediaId: '',
      mediaUrl: localMediaUrl,
      mediaFileName: mediaFileName,
      mediaMimeType: mediaMimeType,
      mediaSize: mediaSize,
      raw: {'localMessage': true, 'localId': localId},
    );
  }

  WhatsappMessage _normalizeSentMessage(
    WhatsappMessage? responseMessage, {
    required WhatsappMessage fallback,
  }) {
    final message = responseMessage ?? fallback;
    return message.copyWith(
      id: message.id.isEmpty ? fallback.id : message.id,
      wamId: message.wamId,
      conversationId: message.conversationId.isEmpty
          ? fallback.conversationId
          : message.conversationId,
      leadId: message.leadId.isEmpty ? fallback.leadId : message.leadId,
      direction: 'OUTBOUND',
      type: message.type.isEmpty ? fallback.type : message.type,
      content: message.content.isEmpty ? fallback.content : message.content,
      status: message.status.isEmpty ? 'SENT' : message.status,
      createdAt: message.createdAt ?? fallback.createdAt,
      templateName: message.templateName.isEmpty
          ? fallback.templateName
          : message.templateName,
      mediaId: message.mediaId.isEmpty ? fallback.mediaId : message.mediaId,
      mediaUrl: message.mediaUrl.isEmpty ? fallback.mediaUrl : message.mediaUrl,
      mediaFileName: message.mediaFileName.isEmpty
          ? fallback.mediaFileName
          : message.mediaFileName,
      mediaMimeType: message.mediaMimeType.isEmpty
          ? fallback.mediaMimeType
          : message.mediaMimeType,
      mediaSize: message.mediaSize == 0
          ? fallback.mediaSize
          : message.mediaSize,
      raw: responseMessage == null ? fallback.raw : message.raw,
    );
  }

  void _replaceMessage(
    String leadId,
    WhatsappMessage target,
    WhatsappMessage replacement,
  ) {
    final current = messagesFor(leadId);
    final targetKey = _messageKey(target);
    final next = <WhatsappMessage>[];
    var replaced = false;

    for (final message in current) {
      if (!replaced &&
          (_messageKey(message) == targetKey ||
              _matchesLocalOutgoing(message, replacement))) {
        next.add(replacement);
        replaced = true;
      } else if (!_sameServerMessage(message, replacement)) {
        next.add(message);
      }
    }

    if (!replaced) {
      next.add(replacement);
    }
    _setMessages(leadId, _sortMessages(next));
  }

  List<WhatsappMessage> _mergeMessages(
    List<WhatsappMessage> base,
    List<WhatsappMessage> incoming,
  ) {
    final merged = [...base];

    for (final message in incoming) {
      final existingIndex = merged.indexWhere(
        (item) => _messageKey(item) == _messageKey(message),
      );
      if (existingIndex >= 0) {
        merged[existingIndex] = message;
        continue;
      }

      final matchingLocalIndex = merged.indexWhere(
        (item) => _matchesLocalOutgoing(item, message),
      );
      if (matchingLocalIndex >= 0) {
        merged[matchingLocalIndex] = message;
        continue;
      }

      final matchesExistingServer = merged.any(
        (item) => _sameServerMessage(item, message),
      );
      if (!matchesExistingServer) {
        merged.add(message);
      }
    }

    return _sortMessages(merged);
  }

  List<WhatsappMessage> _sortMessages(List<WhatsappMessage> messages) {
    return [...messages]..sort((a, b) {
      final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return left.compareTo(right);
    });
  }

  bool _messageKeysEqual(
    List<WhatsappMessage> left,
    List<WhatsappMessage> right,
  ) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (_messageKey(left[index]) != _messageKey(right[index]) ||
          left[index].status != right[index].status) {
        return false;
      }
    }
    return true;
  }

  bool _isLocalMessage(WhatsappMessage message) {
    return message.raw['localMessage'] == true ||
        message.id.startsWith('local-');
  }

  bool _matchesLocalOutgoing(
    WhatsappMessage local,
    WhatsappMessage serverMessage,
  ) {
    if (!_isLocalMessage(local) ||
        local.isInbound ||
        serverMessage.isInbound ||
        _isLocalMessage(serverMessage)) {
      return false;
    }
    final localCreatedAt = local.createdAt;
    final serverCreatedAt = serverMessage.createdAt;
    final closeInTime =
        localCreatedAt == null ||
        serverCreatedAt == null ||
        localCreatedAt.difference(serverCreatedAt).abs().inMinutes <= 10;
    final sameTemplate =
        local.templateName.isNotEmpty &&
        local.templateName == serverMessage.templateName;
    final sameContent =
        local.content.isNotEmpty && local.content == serverMessage.content;
    final sameMedia =
        local.hasMedia &&
        (local.mediaFileName == serverMessage.mediaFileName ||
            local.mediaMimeType == serverMessage.mediaMimeType ||
            local.type == serverMessage.type);
    return closeInTime && (sameTemplate || sameContent || sameMedia);
  }

  bool _sameServerMessage(WhatsappMessage left, WhatsappMessage right) {
    if (_isLocalMessage(left) || _isLocalMessage(right)) {
      return false;
    }
    if (_messageKey(left) == _messageKey(right)) {
      return true;
    }
    if (left.isInbound || right.isInbound) {
      return false;
    }
    final sameTemplate =
        left.templateName.isNotEmpty && left.templateName == right.templateName;
    final sameContent =
        left.content.isNotEmpty && left.content == right.content;
    final sameMedia =
        left.hasMedia &&
        right.hasMedia &&
        (left.mediaFileName == right.mediaFileName ||
            left.mediaMimeType == right.mediaMimeType ||
            left.type == right.type);
    final leftCreatedAt = left.createdAt;
    final rightCreatedAt = right.createdAt;
    final closeInTime =
        leftCreatedAt != null &&
        rightCreatedAt != null &&
        leftCreatedAt.difference(rightCreatedAt).abs().inMinutes <= 2;
    return closeInTime && (sameTemplate || sameContent || sameMedia);
  }

  void _updateConversationPreview(String leadId, WhatsappMessage message) {
    final index = _conversations.indexWhere(
      (conversation) =>
          conversation.leadId == leadId || conversation.id == leadId,
    );
    if (index < 0) {
      return;
    }
    final current = _conversations[index];
    final visibleMessageCount = messagesFor(leadId).length;
    final next = current.copyWith(
      lastMessage: message.displayText,
      lastMessageAt: message.createdAt ?? DateTime.now(),
      messageCount: visibleMessageCount > current.messageCount
          ? visibleMessageCount
          : current.messageCount,
      latestMessageId: message.id.isEmpty
          ? current.latestMessageId
          : message.id,
      latestMessageWamId: message.wamId.isEmpty
          ? current.latestMessageWamId
          : message.wamId,
    );
    _conversations = [
      ..._conversations.take(index),
      next,
      ..._conversations.skip(index + 1),
    ];
  }

  String _messageKey(WhatsappMessage message) {
    if (message.wamId.isNotEmpty) {
      return 'wam:${message.wamId}';
    }
    if (message.id.isNotEmpty) {
      return 'id:${message.id}';
    }
    final createdAt = message.createdAt?.toIso8601String() ?? '';
    return 'fallback:${message.direction}:${message.content}:$createdAt';
  }

  @override
  void dispose() {
    for (final notifier in _messageNotifiers.values) {
      notifier.dispose();
    }
    super.dispose();
  }
}
