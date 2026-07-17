class RmLeadItem {
  const RmLeadItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.stage,
    required this.source,
    required this.leadFor,
    required this.city,
    required this.community,
    required this.notes,
    required this.petitionerRelation,
    required this.assignedToId,
    required this.assignedToName,
    required this.assignedToRole,
    required this.intentScore,
    required this.createdAt,
    required this.updatedAt,
    required this.convertedAt,
    required this.lastUserResponseAt,
    required this.lastRmActionAt,
    required this.lastSystemActionAt,
    required this.communicationLogs,
    required this.tasks,
    required this.comments,
    required this.resumesReceived,
    required this.inboundResumeAttachments,
    required this.resumeCount,
    this.avatarUrl = '',
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String stage;
  final String source;
  final String leadFor;
  final String city;
  final String community;
  final String notes;
  final String petitionerRelation;
  final String assignedToId;
  final String assignedToName;
  final String assignedToRole;
  final int intentScore;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? convertedAt;
  final DateTime? lastUserResponseAt;
  final DateTime? lastRmActionAt;
  final DateTime? lastSystemActionAt;
  final List<RmCommunicationLog> communicationLogs;
  final List<RmLeadTask> tasks;
  final List<RmLeadComment> comments;
  final List<RmLeadAttachment> resumesReceived;
  final List<RmLeadAttachment> inboundResumeAttachments;
  final int resumeCount;
  final String avatarUrl;

  factory RmLeadItem.fromJson(Map<String, dynamic> json) {
    final source = _extractLeadPayload(json);
    final assignedTo = _readMap(
      source['assignedTo'] ?? source['assigned_to'] ?? source['owner'],
    );
    final count = _readMap(source['_count'] ?? source['count']);
    final contact = _readMap(source['contact']);
    final customer = _readMap(source['customer']);
    final profile = _readMap(source['profile']);

    return RmLeadItem(
      id: _readText(source['id']),
      name: _readFirstText([
        source['name'],
        source['contactName'],
        source['contact_name'],
        contact['name'],
        customer['name'],
        profile['name'],
      ], fallback: 'Unnamed Lead'),
      phone: _readFirstText([
        source['phone'],
        source['mobile'],
        source['contactPhone'],
        source['contact_phone'],
        contact['phone'],
        customer['phone'],
      ], fallback: '-'),
      email: _readFirstText([
        source['email'],
        source['contactEmail'],
        source['contact_email'],
        contact['email'],
        customer['email'],
      ], fallback: '-'),
      stage: _readText(source['stage'] ?? source['status'], fallback: 'NEW'),
      source: _readText(source['source'], fallback: '-'),
      leadFor: _readText(
        source['leadFor'] ?? source['lead_for'] ?? source['project'],
        fallback: 'UNKNOWN',
      ),
      city: _readFirstText([
        source['city'],
        source['location'],
        source['addressCity'],
        source['address_city'],
        contact['city'],
        customer['city'],
      ], fallback: 'Unknown City'),
      community: _readText(source['community']),
      notes: _readFirstText([
        source['notes'],
        source['note'],
        source['leadNotes'],
        source['lead_notes'],
        source['internalNotes'],
        source['internal_notes'],
        source['followUpNotes'],
        source['follow_up_notes'],
        source['remark'],
        source['remarks'],
        source['description'],
      ]),
      petitionerRelation: _readText(
        source['petitionerRelation'] ?? source['petitioner_relation'],
      ),
      assignedToId: assignedTo.isNotEmpty
          ? _readText(assignedTo['id'])
          : _readText(source['assignedToId'] ?? source['assigned_to_id']),
      assignedToName: assignedTo.isNotEmpty
          ? _readText(assignedTo['name'], fallback: 'Unassigned')
          : _readText(source['assignedToName'], fallback: 'Unassigned'),
      assignedToRole: assignedTo.isNotEmpty
          ? _readText(assignedTo['role'])
          : '',
      intentScore: _readInt(source['intentScore'] ?? source['intent_score']),
      createdAt: _readDate(source['createdAt'] ?? source['created_at']),
      updatedAt: _readDate(source['updatedAt'] ?? source['updated_at']),
      convertedAt: _readDate(source['convertedAt'] ?? source['converted_at']),
      lastUserResponseAt: _readDate(
        source['lastUserResponseAt'] ?? source['last_user_response_at'],
      ),
      lastRmActionAt: _readDate(
        source['lastRMActionAt'] ??
            source['lastRmActionAt'] ??
            source['last_rm_action_at'],
      ),
      lastSystemActionAt: _readDate(
        source['lastSystemActionAt'] ?? source['last_system_action_at'],
      ),
      communicationLogs: _readList(source['communicationLogs'])
          .whereType<Map<String, dynamic>>()
          .map(RmCommunicationLog.fromJson)
          .toList(),
      tasks: _readList(
        source['tasks'],
      ).whereType<Map<String, dynamic>>().map(RmLeadTask.fromJson).toList(),
      comments: _readList(
        source['comments'],
      ).whereType<Map<String, dynamic>>().map(RmLeadComment.fromJson).toList(),
      resumesReceived: _readList(source['resumesReceived'])
          .whereType<Map<String, dynamic>>()
          .map(RmLeadAttachment.fromJson)
          .toList(),
      inboundResumeAttachments: _readList(source['inboundResumeAttachments'])
          .whereType<Map<String, dynamic>>()
          .map(RmLeadAttachment.fromJson)
          .toList(),
      resumeCount: _readInt(
        count['resumesReceived'] ??
            source['resumesSentCount'] ??
            source['resumeCount'],
      ),
      avatarUrl: _readFirstText([
        source['avatarUrl'],
        source['avatar'],
        source['photoUrl'],
        source['photo_url'],
        source['imageUrl'],
        source['image_url'],
        source['profileImage'],
        source['profile_image'],
        source['profilePicture'],
        source['profilePictureUrl'],
        source['profile_picture'],
        source['profile_picture_url'],
        source['profilePhoto'],
        source['profile_photo'],
        source['image'],
        source['photo'],
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
    );
  }

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'L';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String get stageLabel => _formatEnumLabel(stage, fallback: 'New');
  String get sourceLabel => _formatEnumLabel(source, fallback: '-');
  String get leadForLabel => _formatEnumLabel(leadFor, fallback: '-');
  String get communityLabel =>
      community.isEmpty ? 'Unknown' : _formatEnumLabel(community);
  String get petitionerRelationLabel =>
      _formatEnumLabel(petitionerRelation, fallback: '-');

  List<RmLeadTask> get openTasks =>
      tasks.where((task) => task.isOpen).toList(growable: false);

  int get openTasksCount => openTasks.length;

  bool get hasConversation => communicationLogs.isNotEmpty;

  RmLeadTask? get profileCreationTask {
    for (final task in tasks) {
      if (task.isProfileCreation) {
        return task;
      }
    }
    return null;
  }

  RmCommunicationLog? get latestCommunication {
    if (communicationLogs.isEmpty) {
      return null;
    }

    final sortedLogs = [...communicationLogs]
      ..sort((a, b) {
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return left.compareTo(right);
      });
    return sortedLogs.last;
  }

  DateTime? get latestActivityAt {
    final values = <DateTime>[
      ...communicationLogs.map((log) => log.createdAt).whereType<DateTime>(),
      ...[
        createdAt,
        updatedAt,
        convertedAt,
        lastUserResponseAt,
        lastRmActionAt,
        lastSystemActionAt,
      ].whereType<DateTime>(),
    ];

    if (values.isEmpty) {
      return null;
    }

    values.sort();
    return values.last;
  }

  String get latestMessagePreview {
    final latest = latestCommunication;
    if (latest != null) {
      return latest.previewText;
    }
    if (notes.isNotEmpty) {
      return notes;
    }
    return 'No WhatsApp conversation synced yet.';
  }
}

class RmLeadComment {
  const RmLeadComment({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.userName,
    required this.userRole,
  });

  final String id;
  final String content;
  final DateTime? createdAt;
  final String userName;
  final String userRole;

  factory RmLeadComment.fromJson(Map<String, dynamic> json) {
    final user = _readMap(json['user'] ?? json['createdBy'] ?? json['author']);
    return RmLeadComment(
      id: _readText(json['id']),
      content: _readText(json['content'] ?? json['comment'] ?? json['text']),
      createdAt: _readDate(json['createdAt'] ?? json['created_at']),
      userName: _readText(user['name'], fallback: 'Team Member'),
      userRole: _readText(user['role'], fallback: 'Team Member'),
    );
  }
}

class RmLeadAttachment {
  const RmLeadAttachment({
    required this.id,
    required this.name,
    required this.url,
    required this.createdAt,
    required this.status,
    required this.raw,
  });

  final String id;
  final String name;
  final String url;
  final DateTime? createdAt;
  final String status;
  final Map<String, dynamic> raw;

  factory RmLeadAttachment.fromJson(Map<String, dynamic> json) {
    final profile = _readMap(json['profile']);
    final file = _readMap(json['file'] ?? json['attachment'] ?? json['resume']);
    return RmLeadAttachment(
      id: _readText(json['id'] ?? file['id']),
      name: _readFirstText([
        json['name'],
        json['fileName'],
        json['filename'],
        json['title'],
        file['name'],
        file['fileName'],
        file['filename'],
        profile['name'],
      ], fallback: 'Resume'),
      url: _readFirstText([
        json['url'],
        json['fileUrl'],
        json['file_url'],
        json['mediaUrl'],
        file['url'],
        file['fileUrl'],
        file['file_url'],
      ]),
      createdAt: _readDate(
        json['createdAt'] ??
            json['created_at'] ??
            json['sentAt'] ??
            json['sent_at'],
      ),
      status: _readText(json['status'] ?? json['eventType']),
      raw: json,
    );
  }
}

class RmCommunicationLog {
  const RmCommunicationLog({
    required this.id,
    required this.channel,
    required this.direction,
    required this.content,
    required this.subject,
    required this.templateName,
    required this.whatsappStatus,
    required this.createdAt,
    this.imageUrl,
  });

  final String id;
  final String channel;
  final String direction;
  final String content;
  final String subject;
  final String templateName;
  final String whatsappStatus;
  final DateTime? createdAt;
  final String? imageUrl;

  factory RmCommunicationLog.fromJson(Map<String, dynamic> json) {
    return RmCommunicationLog(
      id: _readText(json['id']),
      channel: _readText(json['channel'], fallback: 'WHATSAPP'),
      direction: _readText(json['direction'], fallback: 'INBOUND'),
      content: _readText(json['content']),
      subject: _readText(json['subject']),
      templateName: _readText(json['templateName']),
      whatsappStatus: _readText(json['whatsappStatus']),
      createdAt: _readDate(json['createdAt']),
      imageUrl: _readText(json['imageUrl']),
    );
  }

  bool get isIncoming => direction.toUpperCase() != 'OUTBOUND';
  String get channelLabel => _formatEnumLabel(channel, fallback: '-');
  String get directionLabel => _formatEnumLabel(direction, fallback: '-');
  String get whatsappStatusLabel =>
      _formatEnumLabel(whatsappStatus, fallback: '-');

  String get previewText {
    if (content.isNotEmpty) {
      return content;
    }
    if (subject.isNotEmpty) {
      return subject;
    }
    if (templateName.isNotEmpty) {
      return 'Template: $templateName';
    }
    return 'WhatsApp update';
  }
}

class RmLeadTask {
  const RmLeadTask({
    required this.id,
    required this.title,
    required this.type,
    required this.priority,
    required this.status,
    required this.workflowStatus,
    required this.dueAt,
    required this.createdAt,
    required this.updatedAt,
    required this.assignedToName,
    required this.assignedToRole,
  });

  final String id;
  final String title;
  final String type;
  final String priority;
  final String status;
  final String workflowStatus;
  final DateTime? dueAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String assignedToName;
  final String assignedToRole;

  factory RmLeadTask.fromJson(Map<String, dynamic> json) {
    final assignedTo = json['assignedTo'];

    return RmLeadTask(
      id: _readText(json['id']),
      title: _readText(json['title'], fallback: 'Untitled Task'),
      type: _readText(json['type'], fallback: '-'),
      priority: _readText(json['priority'], fallback: '-'),
      status: _readText(json['status'], fallback: '-'),
      workflowStatus: _readText(json['workflowStatus'], fallback: '-'),
      dueAt: _readDate(json['dueAt']),
      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
      assignedToName: assignedTo is Map<String, dynamic>
          ? _readText(assignedTo['name'], fallback: 'Unassigned')
          : 'Unassigned',
      assignedToRole: assignedTo is Map<String, dynamic>
          ? _readText(assignedTo['role'])
          : '',
    );
  }

  bool get isDone {
    final normalizedStatus = status.toUpperCase();
    final normalizedWorkflow = workflowStatus.toUpperCase();
    return normalizedStatus == 'DONE' ||
        normalizedStatus == 'COMPLETED' ||
        normalizedWorkflow == 'COMPLETED';
  }

  bool get isOpen => !isDone;
  bool get isProfileCreation => type.toUpperCase() == 'PROFILE_CREATION';

  String get typeLabel => _formatEnumLabel(type, fallback: '-');
  String get priorityLabel => _formatEnumLabel(priority, fallback: '-');
  String get statusLabel => _formatEnumLabel(status, fallback: '-');
  String get workflowStatusLabel =>
      _formatEnumLabel(workflowStatus, fallback: '-');
}

String _readText(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
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

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

Map<String, dynamic> _extractLeadPayload(Map<String, dynamic> json) {
  if (_looksLikeLeadPayload(json)) {
    return json;
  }

  for (final key in const ['lead', 'data', 'item', 'result']) {
    final value = json[key];
    if (value is Map) {
      return _readMap(value);
    }
  }
  final customer = json['customer'];
  if (customer is Map) {
    return _readMap(customer);
  }
  return json;
}

bool _looksLikeLeadPayload(Map<String, dynamic> json) {
  return json.containsKey('id') ||
      json.containsKey('name') ||
      json.containsKey('phone') ||
      json.containsKey('stage') ||
      json.containsKey('leadFor');
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

DateTime? _readDate(dynamic value) {
  final raw = _readText(value);
  if (raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw)?.toLocal();
}

List<dynamic> _readList(dynamic value) {
  return value is List ? value : const [];
}

String _formatEnumLabel(String value, {String fallback = '-'}) {
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
