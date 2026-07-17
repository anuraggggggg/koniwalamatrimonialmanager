import 'package:koniwalamatrimonial/rm/models/rm_lead_item.dart';

class WhatsappPagedResult<T> {
  const WhatsappPagedResult({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
  });

  final List<T> items;
  final String? nextCursor;
  final bool hasMore;
}

class WhatsappApiStatus {
  const WhatsappApiStatus({
    required this.configured,
    required this.phone,
    required this.displayName,
    required this.raw,
  });

  final bool configured;
  final String phone;
  final String displayName;
  final Map<String, dynamic> raw;

  factory WhatsappApiStatus.fromAny(dynamic payload) {
    final map = _findFirstMap(payload);
    return WhatsappApiStatus(
      configured:
          _readBool(map['configured']) ||
          _readBool(map['isConfigured']) ||
          _readBool(map['connected']) ||
          _readBool(map['enabled']) ||
          _readBool(map['verified']) ||
          _readBool(map['isVerified']) ||
          _readText(map['status']).toLowerCase() == 'verified',
      phone: _readText(
        map['phone'] ??
            map['phoneNumber'] ??
            map['businessPhone'] ??
            map['business_phone_number'] ??
            map['displayPhoneNumber'] ??
            map['display_phone_number'],
      ),
      displayName: _readText(
        map['displayName'] ??
            map['businessName'] ??
            map['verifiedName'] ??
            map['verified_name'] ??
            map['name'],
        fallback: 'Koniwala Matrimonials',
      ),
      raw: map,
    );
  }
}

class WhatsappConversation {
  const WhatsappConversation({
    required this.id,
    required this.leadId,
    required this.phone,
    required this.name,
    required this.email,
    required this.city,
    required this.source,
    required this.status,
    required this.assignedToId,
    required this.assignedToName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastUserReplyAt,
    required this.createdAt,
    required this.unreadCount,
    required this.messageCount,
    required this.archived,
    required this.avatarUrl,
    required this.latestMessageId,
    required this.latestMessageWamId,
    required this.raw,
  });

  final String id;
  final String leadId;
  final String phone;
  final String name;
  final String email;
  final String city;
  final String source;
  final String status;
  final String assignedToId;
  final String assignedToName;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? lastUserReplyAt;
  final DateTime? createdAt;
  final int unreadCount;
  final int messageCount;
  final bool archived;
  final String avatarUrl;
  final String latestMessageId;
  final String latestMessageWamId;
  final Map<String, dynamic> raw;

  factory WhatsappConversation.fromJson(Map<String, dynamic> json) {
    final conversation = _readMap(
      json['conversation'] ??
          json['whatsAppConversation'] ??
          json['whatsappConversation'],
    );
    final lead = _readMap(
      json['lead'] ??
          json['whatsAppLead'] ??
          json['whatsappLead'] ??
          json['contact'] ??
          json['customer'] ??
          conversation['lead'] ??
          conversation['whatsAppLead'] ??
          conversation['whatsappLead'] ??
          conversation['contact'] ??
          conversation['customer'],
    );
    final contact = _readMap(
      json['contact'] ?? conversation['contact'] ?? lead['contact'],
    );
    final customer = _readMap(
      json['customer'] ?? conversation['customer'] ?? lead['customer'],
    );
    final profile = _readMap(
      json['profile'] ??
          conversation['profile'] ??
          lead['profile'] ??
          contact['profile'] ??
          customer['profile'],
    );
    final assignedTo = _readMap(
      json['assignedTo'] ??
          conversation['assignedTo'] ??
          lead['assignedTo'] ??
          json['owner'],
    );
    final latest = _readMap(
      json['latestMessage'] ??
          json['lastMessage'] ??
          json['message'] ??
          conversation['latestMessage'] ??
          conversation['lastMessage'] ??
          conversation['message'],
    );
    final count = _readMap(
      json['_count'] ?? json['count'] ?? conversation['_count'],
    );
    var leadId = _readText(
      json['leadId'] ??
          conversation['leadId'] ??
          json['whatsAppLeadId'] ??
          json['whatsappLeadId'] ??
          conversation['whatsAppLeadId'] ??
          lead['id'] ??
          json['lead_id'] ??
          json['contactId'],
    );
    if (leadId.isEmpty && _looksLikeWhatsAppLead(json)) {
      leadId = _readText(json['id']);
    }

    return WhatsappConversation(
      id: _readText(json['id'] ?? conversation['id'], fallback: leadId),
      leadId: leadId,
      phone: _readText(
        json['phone'] ??
            conversation['phone'] ??
            lead['phone'] ??
            json['waId'] ??
            json['wa_id'] ??
            json['from'] ??
            latest['from'],
      ),
      name: _readText(
        json['contactName'] ??
            json['name'] ??
            conversation['contactName'] ??
            conversation['name'] ??
            lead['contactName'] ??
            lead['name'] ??
            lead['businessName'] ??
            latest['contactName'],
        fallback: 'Unknown Contact',
      ),
      email: _readText(json['email'] ?? conversation['email'] ?? lead['email']),
      city: _readText(json['city'] ?? conversation['city'] ?? lead['city']),
      source: _readText(
        json['source'] ?? conversation['source'] ?? lead['source'],
      ),
      status: _readText(
        json['status'] ??
            json['state'] ??
            conversation['status'] ??
            conversation['state'] ??
            lead['stage'],
      ),
      assignedToId: _readText(
        json['assignedToId'] ??
            conversation['assignedToId'] ??
            assignedTo['id'] ??
            lead['assignedToId'],
      ),
      assignedToName: _readText(
        json['assignedToName'] ??
            conversation['assignedToName'] ??
            assignedTo['name'] ??
            lead['assignedToName'],
      ),
      lastMessage: _readText(
        latest['content'] ??
            latest['text'] ??
            json['lastMessageText'] ??
            json['lastMessagePreview'] ??
            conversation['lastMessageText'] ??
            conversation['lastMessagePreview'] ??
            json['content'],
        fallback: 'No messages yet',
      ),
      lastMessageAt: _readDate(
        latest['createdAt'] ??
            latest['timestamp'] ??
            json['lastMessageAt'] ??
            conversation['lastMessageAt'] ??
            conversation['updatedAt'] ??
            json['updatedAt'],
      ),
      lastUserReplyAt: _readDate(
        json['lastUserReplyAt'] ?? conversation['lastUserReplyAt'],
      ),
      createdAt: _readDate(
        json['createdAt'] ?? conversation['createdAt'] ?? lead['createdAt'],
      ),
      unreadCount: _readInt(
        json['unreadCount'] ??
            json['unread'] ??
            conversation['unreadCount'] ??
            count['unreadMessages'],
      ),
      messageCount: _readInt(
        json['messageCount'] ??
            conversation['messageCount'] ??
            count['messages'] ??
            count['whatsAppMessages'],
      ),
      archived: _readBool(
        json['archived'] ?? json['isArchived'] ?? conversation['archived'],
      ),
      avatarUrl: _readFirstText([
        json['avatarUrl'],
        json['avatar'],
        json['photoUrl'],
        json['photo_url'],
        json['imageUrl'],
        json['image_url'],
        json['profileImage'],
        json['profile_image'],
        json['profilePicture'],
        json['profilePictureUrl'],
        json['profile_picture'],
        json['profile_picture_url'],
        json['profilePhoto'],
        json['profile_photo'],
        conversation['avatarUrl'],
        conversation['avatar'],
        conversation['photoUrl'],
        conversation['photo_url'],
        conversation['imageUrl'],
        conversation['image_url'],
        conversation['profileImage'],
        conversation['profile_image'],
        conversation['profilePicture'],
        conversation['profilePictureUrl'],
        conversation['profile_picture'],
        conversation['profile_picture_url'],
        conversation['profilePhoto'],
        conversation['profile_photo'],
        lead['avatarUrl'],
        lead['avatar'],
        lead['photoUrl'],
        lead['photo_url'],
        lead['imageUrl'],
        lead['image_url'],
        lead['profileImage'],
        lead['profile_image'],
        lead['profilePicture'],
        lead['profilePictureUrl'],
        lead['profile_picture'],
        lead['profile_picture_url'],
        lead['profilePhoto'],
        lead['profile_photo'],
        lead['image'],
        lead['photo'],
        contact['avatarUrl'],
        contact['avatar'],
        contact['photoUrl'],
        contact['photo_url'],
        contact['imageUrl'],
        contact['image_url'],
        contact['profileImage'],
        contact['profile_image'],
        contact['profilePicture'],
        contact['profilePictureUrl'],
        contact['profile_picture'],
        contact['profile_picture_url'],
        contact['profilePhoto'],
        contact['profile_photo'],
        contact['image'],
        contact['photo'],
        customer['avatarUrl'],
        customer['avatar'],
        customer['photoUrl'],
        customer['photo_url'],
        customer['imageUrl'],
        customer['image_url'],
        customer['profileImage'],
        customer['profile_image'],
        customer['profilePicture'],
        customer['profilePictureUrl'],
        customer['profile_picture'],
        customer['profile_picture_url'],
        customer['profilePhoto'],
        customer['profile_photo'],
        customer['image'],
        customer['photo'],
        profile['avatarUrl'],
        profile['avatar'],
        profile['photoUrl'],
        profile['photo_url'],
        profile['imageUrl'],
        profile['image_url'],
        profile['profileImage'],
        profile['profile_image'],
        profile['profilePicture'],
        profile['profilePictureUrl'],
        profile['profile_picture'],
        profile['profile_picture_url'],
        profile['profilePhoto'],
        profile['profile_photo'],
        profile['image'],
        profile['photo'],
      ]),
      latestMessageId: _readText(
        latest['id'] ??
            json['latestMessageId'] ??
            conversation['latestMessageId'],
      ),
      latestMessageWamId: _readText(
        latest['wamId'] ??
            latest['messageId'] ??
            json['latestMessageWamId'] ??
            conversation['latestMessageWamId'],
      ),
      raw: json,
    );
  }

  factory WhatsappConversation.fromLead(RmLeadItem lead) {
    final latest = lead.latestCommunication;
    return WhatsappConversation(
      id: lead.id,
      leadId: lead.id,
      phone: lead.phone,
      name: lead.name,
      email: lead.email == '-' ? '' : lead.email,
      city: lead.city == 'Unknown City' ? '' : lead.city,
      source: lead.source,
      status: lead.stage,
      assignedToId: lead.assignedToId,
      assignedToName: lead.assignedToName,
      lastMessage: lead.latestMessagePreview,
      lastMessageAt: latest?.createdAt ?? lead.latestActivityAt,
      lastUserReplyAt: lead.lastUserResponseAt,
      createdAt: lead.createdAt,
      unreadCount: 0,
      messageCount: lead.communicationLogs.length,
      archived: false,
      avatarUrl: lead.avatarUrl,
      latestMessageId: latest?.id ?? '',
      latestMessageWamId: '',
      raw: const {},
    );
  }

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'WA';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  bool get canInferFreeformWindow {
    if (lastUserReplyAt == null) {
      return true;
    }
    return DateTime.now().difference(lastUserReplyAt!).inHours < 24;
  }

  WhatsappConversation copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    int? messageCount,
    String? latestMessageId,
    String? latestMessageWamId,
  }) {
    return WhatsappConversation(
      id: id,
      leadId: leadId,
      phone: phone,
      name: name,
      email: email,
      city: city,
      source: source,
      status: status,
      assignedToId: assignedToId,
      assignedToName: assignedToName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastUserReplyAt: lastUserReplyAt,
      createdAt: createdAt,
      unreadCount: unreadCount,
      messageCount: messageCount ?? this.messageCount,
      archived: archived,
      avatarUrl: avatarUrl,
      latestMessageId: latestMessageId ?? this.latestMessageId,
      latestMessageWamId: latestMessageWamId ?? this.latestMessageWamId,
      raw: raw,
    );
  }

  String get displayStatus => _formatEnum(status, fallback: 'Open');
  String get displaySource => _formatEnum(source, fallback: '-');
}

class WhatsappConversationLaunch {
  const WhatsappConversationLaunch({
    this.lead,
    this.conversation,
    this.openAttachment = false,
  });

  final RmLeadItem? lead;
  final WhatsappConversation? conversation;
  final bool openAttachment;
}

class WhatsappMessage {
  const WhatsappMessage({
    required this.id,
    required this.wamId,
    required this.conversationId,
    required this.leadId,
    required this.direction,
    required this.type,
    required this.content,
    required this.status,
    required this.createdAt,
    required this.templateName,
    required this.mediaId,
    required this.mediaUrl,
    required this.mediaFileName,
    required this.mediaMimeType,
    required this.mediaSize,
    required this.raw,
  });

  final String id;
  final String wamId;
  final String conversationId;
  final String leadId;
  final String direction;
  final String type;
  final String content;
  final String status;
  final DateTime? createdAt;
  final String templateName;
  final String mediaId;
  final String mediaUrl;
  final String mediaFileName;
  final String mediaMimeType;
  final int mediaSize;
  final Map<String, dynamic> raw;

  factory WhatsappMessage.fromJson(Map<String, dynamic> json) {
    final message = _readMap(
      json['message'] ?? json['whatsAppMessage'] ?? json['whatsappMessage'],
    );
    final media = _readMap(
      json['media'] ?? json['attachment'] ?? message['media'],
    );
    final metadata = _readMap(json['metadata'] ?? message['metadata']);
    final document = _readMap(metadata['document']);
    final image = _readMap(metadata['image']);
    final audio = _readMap(metadata['audio']);
    final video = _readMap(metadata['video']);
    final mediaSource = media.isNotEmpty
        ? media
        : document.isNotEmpty
        ? document
        : image.isNotEmpty
        ? image
        : audio.isNotEmpty
        ? audio
        : video;

    final rawDirection = _readText(
      json['direction'] ??
          message['direction'] ??
          json['messageDirection'] ??
          message['messageDirection'],
    );
    final senderType = _readText(
      json['sender_type'] ??
          json['senderType'] ??
          message['sender_type'] ??
          message['senderType'] ??
          _readMap(json['sender'])['type'] ??
          _readMap(message['sender'])['type'],
    );
    final isFromMe = _readBoolOrNull(
      json['is_from_me'] ??
          json['isFromMe'] ??
          json['from_me'] ??
          json['fromMe'] ??
          message['is_from_me'] ??
          message['isFromMe'] ??
          message['from_me'] ??
          message['fromMe'],
    );

    return WhatsappMessage(
      id: _readText(json['id'] ?? message['id'] ?? json['messageId']),
      wamId: _readText(json['wamId'] ?? message['wamId'] ?? json['messageId']),
      conversationId: _readText(
        json['conversationId'] ?? message['conversationId'],
      ),
      leadId: _readText(json['leadId'] ?? message['leadId']),
      direction: _normalizeMessageDirection(
        direction: rawDirection,
        senderType: senderType,
        isFromMe: isFromMe,
      ),
      type: _readText(
        json['type'] ??
            message['type'] ??
            json['whatsappMessageType'] ??
            json['whatsapp_message_type'] ??
            message['whatsappMessageType'] ??
            message['whatsapp_message_type'],
        fallback: 'text',
      ),
      content: _readText(
        json['content'] ??
            message['content'] ??
            json['text'] ??
            message['text'] ??
            _readMap(json['text'])['body'] ??
            _readMap(message['text'])['body'] ??
            json['whatsappCaption'] ??
            json['whatsapp_caption'] ??
            message['whatsappCaption'] ??
            message['whatsapp_caption'] ??
            document['caption'] ??
            image['caption'],
      ),
      status: _readText(json['status'] ?? message['status'], fallback: 'SENT'),
      createdAt: _readDate(
        json['createdAt'] ??
            message['createdAt'] ??
            json['timestamp'] ??
            message['timestamp'] ??
            json['sentAt'],
      ),
      templateName: _readText(json['templateName'] ?? message['templateName']),
      mediaId: _readText(
        mediaSource['id'] ??
            mediaSource['mediaId'] ??
            mediaSource['media_id'] ??
            json['mediaId'] ??
            json['media_id'] ??
            json['whatsappMediaId'] ??
            json['whatsapp_media_id'] ??
            message['mediaId'] ??
            message['media_id'] ??
            message['whatsappMediaId'] ??
            message['whatsapp_media_id'],
      ),
      mediaUrl: _readText(
        mediaSource['url'] ??
            mediaSource['mediaUrl'] ??
            mediaSource['media_url'] ??
            mediaSource['fileUrl'] ??
            mediaSource['file_url'] ??
            json['mediaUrl'] ??
            json['media_url'] ??
            json['whatsappMediaUrl'] ??
            json['whatsapp_media_url'] ??
            message['mediaUrl'] ??
            message['media_url'] ??
            message['whatsappMediaUrl'] ??
            message['whatsapp_media_url'],
      ),
      mediaFileName: _readText(
        mediaSource['filename'] ??
            mediaSource['fileName'] ??
            mediaSource['file_name'] ??
            mediaSource['name'] ??
            json['mediaFileName'] ??
            json['media_file_name'] ??
            json['whatsappFilename'] ??
            json['whatsapp_filename'] ??
            message['mediaFileName'] ??
            message['media_file_name'] ??
            message['whatsappFilename'] ??
            message['whatsapp_filename'],
      ),
      mediaMimeType: _readText(
        mediaSource['mime_type'] ??
            mediaSource['mimeType'] ??
            mediaSource['contentType'] ??
            mediaSource['content_type'] ??
            json['mediaMimeType'] ??
            json['media_mime_type'] ??
            json['whatsappMimeType'] ??
            json['whatsapp_mime_type'] ??
            message['mediaMimeType'] ??
            message['media_mime_type'] ??
            message['whatsappMimeType'] ??
            message['whatsapp_mime_type'],
      ),
      mediaSize: _readInt(
        mediaSource['size'] ??
            mediaSource['fileSize'] ??
            mediaSource['file_size'] ??
            json['mediaSize'] ??
            json['media_size'] ??
            message['mediaSize'] ??
            message['media_size'],
      ),
      raw: json,
    );
  }

  WhatsappMessage copyWith({
    String? id,
    String? wamId,
    String? conversationId,
    String? leadId,
    String? direction,
    String? type,
    String? content,
    String? status,
    DateTime? createdAt,
    String? templateName,
    String? mediaId,
    String? mediaUrl,
    String? mediaFileName,
    String? mediaMimeType,
    int? mediaSize,
    Map<String, dynamic>? raw,
  }) {
    return WhatsappMessage(
      id: id ?? this.id,
      wamId: wamId ?? this.wamId,
      conversationId: conversationId ?? this.conversationId,
      leadId: leadId ?? this.leadId,
      direction: direction ?? this.direction,
      type: type ?? this.type,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      templateName: templateName ?? this.templateName,
      mediaId: mediaId ?? this.mediaId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaFileName: mediaFileName ?? this.mediaFileName,
      mediaMimeType: mediaMimeType ?? this.mediaMimeType,
      mediaSize: mediaSize ?? this.mediaSize,
      raw: raw ?? this.raw,
    );
  }

  bool get isInbound => direction.toUpperCase() != 'OUTBOUND';
  bool get hasMedia {
    final normalizedType = type.toLowerCase();
    return mediaId.isNotEmpty ||
        mediaUrl.isNotEmpty ||
        mediaFileName.isNotEmpty ||
        mediaMimeType.isNotEmpty ||
        normalizedType == 'image' ||
        normalizedType == 'video' ||
        normalizedType == 'audio' ||
        normalizedType == 'document' ||
        _isMediaPlaceholder(content);
  }

  bool get isAudio {
    final normalizedType = type.toLowerCase();
    final normalizedMime = mediaMimeType.toLowerCase();
    final fileName = mediaFileName.toLowerCase();
    return normalizedType == 'audio' ||
        normalizedMime.startsWith('audio/') ||
        fileName.endsWith('.aac') ||
        fileName.endsWith('.amr') ||
        fileName.endsWith('.m4a') ||
        fileName.endsWith('.mp3') ||
        fileName.endsWith('.ogg') ||
        fileName.endsWith('.opus') ||
        fileName.endsWith('.wav');
  }

  bool get isDocument {
    final normalizedType = type.toLowerCase();
    final normalizedMime = mediaMimeType.toLowerCase();
    if (normalizedType == 'image' ||
        normalizedType == 'video' ||
        normalizedType == 'audio' ||
        normalizedMime.startsWith('image/') ||
        normalizedMime.startsWith('video/') ||
        normalizedMime.startsWith('audio/')) {
      return false;
    }
    return normalizedMime.contains('pdf') ||
        normalizedMime.startsWith('application/') ||
        normalizedType == 'document' ||
        mediaFileName.isNotEmpty;
  }

  String get displayText {
    if (content.isNotEmpty && !_isMediaPlaceholder(content)) {
      return content;
    }
    if (templateName.isNotEmpty) {
      return 'Template: $templateName';
    }
    if (isAudio) {
      return 'Voice message';
    }
    if (hasMedia) {
      return isDocument ? 'Document' : 'Media message';
    }
    return 'WhatsApp message';
  }
}

bool _isMediaPlaceholder(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll('{', '')
      .replaceAll('}', '')
      .replaceAll(RegExp(r'\s+'), ' ');
  return normalized == 'media message' ||
      normalized == 'image message' ||
      normalized == 'document message' ||
      normalized == 'audio message' ||
      normalized == 'video message';
}

class WhatsappTemplate {
  const WhatsappTemplate({
    required this.name,
    required this.language,
    required this.status,
    required this.category,
    required this.body,
    required this.raw,
  });

  final String name;
  final String language;
  final String status;
  final String category;
  final String body;
  final Map<String, dynamic> raw;

  factory WhatsappTemplate.fromJson(Map<String, dynamic> json) {
    final template = _readMap(
      json['template'] ??
          json['whatsappTemplate'] ??
          json['whatsAppTemplate'] ??
          json['messageTemplate'],
    );
    final components = _readList(json['components']).isNotEmpty
        ? _readList(json['components'])
        : _readList(template['components']);
    var body = _readFirstText([
      json['body'],
      json['text'],
      json['content'],
      json['message'],
      template['body'],
      template['text'],
      template['content'],
      template['message'],
    ]);
    for (final rawComponent in components) {
      final component = _readMap(rawComponent);
      if (_readText(component['type']).toUpperCase() == 'BODY') {
        body = _readText(component['text'], fallback: body);
      }
    }

    return WhatsappTemplate(
      name: _readFirstText([
        json['name'],
        json['templateName'],
        json['template_name'],
        json['elementName'],
        json['element_name'],
        json['id'],
        template['name'],
        template['templateName'],
        template['template_name'],
        template['elementName'],
        template['element_name'],
        template['id'],
      ]),
      language: _readText(
        _readMap(json['language']).isNotEmpty
            ? _readMap(json['language'])['code']
            : json['language'] ??
                  template['language'] ??
                  template['languageCode'] ??
                  template['language_code'],
        fallback: 'en',
      ),
      status: _readText(json['status'] ?? template['status']),
      category: _readText(json['category'] ?? template['category']),
      body: body,
      raw: json,
    );
  }

  String get title => name.isEmpty ? 'Approved template' : name;

  String previewForContact(String contactName, {String fallback = ''}) {
    return _resolveTemplateText(
      body,
      contactName: contactName,
      fallback: fallback,
      raw: raw,
    );
  }
}

WhatsappPagedResult<WhatsappConversation> parseWhatsappConversations(
  dynamic payload,
) {
  final rows = _extractRows(payload, const [
    'conversations',
    'data',
    'items',
    'results',
  ]);
  return WhatsappPagedResult(
    items: rows
        .whereType<Map<String, dynamic>>()
        .map(WhatsappConversation.fromJson)
        .where((item) => item.leadId.isNotEmpty || item.id.isNotEmpty)
        .toList(),
    nextCursor: _extractCursor(payload),
    hasMore: _extractHasMore(payload),
  );
}

WhatsappPagedResult<WhatsappMessage> parseWhatsappMessages(dynamic payload) {
  final rows = _extractRows(payload, const [
    'messages',
    'data',
    'items',
    'results',
  ]);
  final messages =
      rows
          .whereType<Map<String, dynamic>>()
          .map(WhatsappMessage.fromJson)
          .toList()
        ..sort((a, b) {
          final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return left.compareTo(right);
        });

  return WhatsappPagedResult(
    items: messages,
    nextCursor: _extractCursor(payload),
    hasMore: _extractHasMore(payload),
  );
}

WhatsappMessage? parseWhatsappMessage(dynamic payload) {
  final result = parseWhatsappMessages(payload);
  if (result.items.isNotEmpty) {
    return result.items.last;
  }

  for (final candidate in _messageCandidates(payload)) {
    final map = _readMap(candidate);
    if (_looksLikeMessageMap(map)) {
      return WhatsappMessage.fromJson(map);
    }
  }
  return null;
}

List<WhatsappTemplate> parseWhatsappTemplates(dynamic payload) {
  final rows = _extractTemplateRows(payload);
  return rows
      .map(WhatsappTemplate.fromJson)
      .where((template) => template.name.isNotEmpty || template.body.isNotEmpty)
      .toList();
}

List<Map<String, dynamic>> _extractTemplateRows(dynamic payload) {
  final rows = _extractRows(payload, const [
    'templates',
    'messageTemplates',
    'whatsappTemplates',
    'whatsAppTemplates',
    'data',
    'items',
    'results',
  ]).map(_readMap).where((row) => row.isNotEmpty).toList();
  if (rows.isNotEmpty) {
    return rows;
  }

  final found = <Map<String, dynamic>>[];
  void walk(dynamic value) {
    if (value is List) {
      for (final item in value) {
        walk(item);
      }
      return;
    }
    final map = _readMap(value);
    if (map.isEmpty) {
      return;
    }
    if (_looksLikeTemplateMap(map)) {
      found.add(map);
      return;
    }
    for (final child in map.values) {
      walk(child);
    }
  }

  walk(payload);
  return found;
}

bool _looksLikeTemplateMap(Map<String, dynamic> map) {
  final nested = _readMap(
    map['template'] ??
        map['whatsappTemplate'] ??
        map['whatsAppTemplate'] ??
        map['messageTemplate'],
  );
  final candidate = nested.isEmpty ? map : nested;
  final hasName = _readFirstText([
    candidate['name'],
    candidate['templateName'],
    candidate['template_name'],
    candidate['elementName'],
    candidate['element_name'],
    candidate['id'],
  ]).isNotEmpty;
  final hasTemplateShape =
      candidate.containsKey('components') ||
      candidate.containsKey('body') ||
      candidate.containsKey('content') ||
      candidate.containsKey('text') ||
      candidate.containsKey('language') ||
      candidate.containsKey('status') ||
      candidate.containsKey('category');
  return hasName && hasTemplateShape;
}

List<dynamic> _messageCandidates(dynamic payload) {
  final candidates = <dynamic>[];

  void walk(dynamic value) {
    if (value is List) {
      for (final item in value) {
        walk(item);
      }
      return;
    }
    final map = _readMap(value);
    if (map.isEmpty) {
      return;
    }
    candidates.add(map);
    for (final key in const [
      'data',
      'result',
      'message',
      'whatsappMessage',
      'whatsAppMessage',
      'sentMessage',
      'record',
    ]) {
      if (map.containsKey(key)) {
        walk(map[key]);
      }
    }
  }

  walk(payload);
  return candidates;
}

bool _looksLikeMessageMap(Map<String, dynamic> map) {
  if (map.isEmpty) {
    return false;
  }
  if (_readMap(
    map['message'] ?? map['whatsappMessage'] ?? map['whatsAppMessage'],
  ).isNotEmpty) {
    return true;
  }
  return map.containsKey('id') ||
      map.containsKey('wamId') ||
      map.containsKey('messageId') ||
      map.containsKey('content') ||
      map.containsKey('text') ||
      map.containsKey('templateName') ||
      map.containsKey('media');
}

String _normalizeMessageDirection({
  required String direction,
  required String senderType,
  required bool? isFromMe,
}) {
  if (isFromMe == true) {
    return 'OUTBOUND';
  }
  if (isFromMe == false) {
    return 'INBOUND';
  }

  final normalizedDirection = direction.trim().toUpperCase();
  if ([
    'OUTBOUND',
    'OUTGOING',
    'SENT',
    'SEND',
    'FROM_BUSINESS',
    'BUSINESS_TO_CUSTOMER',
  ].contains(normalizedDirection)) {
    return 'OUTBOUND';
  }
  if ([
    'INBOUND',
    'INCOMING',
    'RECEIVED',
    'RECEIVE',
    'FROM_CUSTOMER',
    'CUSTOMER_TO_BUSINESS',
  ].contains(normalizedDirection)) {
    return 'INBOUND';
  }

  final normalizedSender = senderType.trim().toUpperCase();
  if ([
    'BUSINESS',
    'AGENT',
    'ADMIN',
    'RM',
    'STAFF',
    'USER',
    'BUSINESS_USER',
    'OWNER',
    'SYSTEM',
  ].contains(normalizedSender)) {
    return 'OUTBOUND';
  }
  if (['CUSTOMER', 'CONTACT', 'LEAD', 'CLIENT'].contains(normalizedSender)) {
    return 'INBOUND';
  }

  return 'INBOUND';
}

String _resolveTemplateText(
  String text, {
  required String contactName,
  required String fallback,
  required Map<String, dynamic> raw,
}) {
  if (text.trim().isEmpty) {
    return text;
  }

  final matches = RegExp(r'\{\{\s*(\d+)\s*\}\}').allMatches(text).toList();
  if (matches.isEmpty) {
    return text;
  }

  final exampleValues = _templateExampleValues(raw);
  final contactValue = contactName.trim().isNotEmpty
      ? contactName.trim()
      : fallback.trim();

  return text.replaceAllMapped(RegExp(r'\{\{\s*(\d+)\s*\}\}'), (match) {
    final index = int.tryParse(match.group(1) ?? '') ?? 0;
    if (index <= 0) {
      return '';
    }
    if (index == 1 && contactValue.isNotEmpty) {
      return contactValue;
    }
    final exampleIndex = index - 1;
    if (exampleIndex >= 0 && exampleIndex < exampleValues.length) {
      final example = exampleValues[exampleIndex].trim();
      if (example.isNotEmpty) {
        return example;
      }
    }
    return contactValue;
  });
}

List<String> _templateExampleValues(Map<String, dynamic> raw) {
  final values = <String>[];

  void collect(dynamic value) {
    if (value is List) {
      for (final item in value) {
        collect(item);
      }
      return;
    }
    final text = _readText(value);
    if (text.isNotEmpty && !text.contains('{{')) {
      values.add(text);
    }
  }

  void walkComponent(dynamic rawComponent) {
    final component = _readMap(rawComponent);
    if (_readText(component['type']).toUpperCase() != 'BODY') {
      return;
    }
    final example = _readMap(component['example']);
    collect(
      example['body_text'] ??
          example['bodyText'] ??
          example['values'] ??
          component['exampleValues'],
    );
  }

  for (final component in _readList(raw['components'])) {
    walkComponent(component);
  }
  final template = _readMap(
    raw['template'] ??
        raw['whatsappTemplate'] ??
        raw['whatsAppTemplate'] ??
        raw['messageTemplate'],
  );
  for (final component in _readList(template['components'])) {
    walkComponent(component);
  }

  return values;
}

List<dynamic> _extractRows(dynamic payload, List<String> keys) {
  if (payload is List) {
    return payload;
  }

  if (payload is Map<String, dynamic>) {
    for (final key in keys) {
      final value = payload[key];
      if (value is List) {
        return value;
      }
      final nested = _extractRows(value, keys);
      if (nested.isNotEmpty) {
        return nested;
      }
    }
  }

  return const [];
}

String? _extractCursor(dynamic payload) {
  final map = _findFirstMap(payload);
  final pagination = _readMap(
    map['pagination'] ?? map['pageInfo'] ?? map['meta'],
  );
  final cursor = _readText(
    map['nextCursor'] ??
        map['cursor'] ??
        pagination['nextCursor'] ??
        pagination['cursor'] ??
        pagination['next'],
  );
  return cursor.isEmpty ? null : cursor;
}

bool _extractHasMore(dynamic payload) {
  final map = _findFirstMap(payload);
  final pagination = _readMap(
    map['pagination'] ?? map['pageInfo'] ?? map['meta'],
  );
  return _readBool(
    map['hasMore'] ?? pagination['hasMore'] ?? pagination['hasNextPage'],
  );
}

Map<String, dynamic> _findFirstMap(dynamic payload) {
  if (payload is List) {
    for (final item in payload) {
      if (item is Map<String, dynamic>) {
        return item;
      }
    }
  }
  if (payload is Map<String, dynamic>) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is List) {
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          return item;
        }
      }
    }
    return payload;
  }
  return const {};
}

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

List<dynamic> _readList(dynamic value) {
  return value is List ? value : const [];
}

String _readText(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  if (value is Map<String, dynamic>) {
    return _readFirstText([
      value['url'],
      value['secureUrl'],
      value['secure_url'],
      value['src'],
      value['text'],
      value['body'],
      value['content'],
      value['value'],
      value['path'],
      value['location'],
      value['fileUrl'],
      value['file_url'],
      value['mediaUrl'],
      value['media_url'],
    ], fallback: fallback);
  }
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String _readFirstText(List<dynamic> values, {String fallback = ''}) {
  for (final value in values) {
    final text = _readText(value);
    if (text.isNotEmpty) {
      return text;
    }
  }
  return fallback;
}

int _readInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(_readText(value)) ?? fallback;
}

bool _readBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  return _readText(value).toLowerCase() == 'true';
}

bool? _readBoolOrNull(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is bool) {
    return value;
  }
  final text = _readText(value).toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes') {
    return true;
  }
  if (text == 'false' || text == '0' || text == 'no') {
    return false;
  }
  return null;
}

DateTime? _readDate(dynamic value) {
  final raw = _readText(value);
  if (raw.isEmpty) {
    return null;
  }
  final numeric = int.tryParse(raw);
  if (numeric != null) {
    return DateTime.fromMillisecondsSinceEpoch(
      raw.length == 10 ? numeric * 1000 : numeric,
    ).toLocal();
  }
  return DateTime.tryParse(raw)?.toLocal();
}

String _formatEnum(String value, {String fallback = '-'}) {
  if (value.trim().isEmpty) {
    return fallback;
  }

  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) {
        final lower = part.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

bool _looksLikeWhatsAppLead(Map<String, dynamic> json) {
  return json.containsKey('phone') ||
      json.containsKey('contactName') ||
      json.containsKey('businessName') ||
      json.containsKey('conversations');
}
