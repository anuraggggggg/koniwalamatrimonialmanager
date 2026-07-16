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
    required this.resumeCount,
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
  final int resumeCount;

  factory RmLeadItem.fromJson(Map<String, dynamic> json) {
    final assignedTo = json['assignedTo'];
    final count = json['_count'];

    return RmLeadItem(
      id: _readText(json['id']),
      name: _readText(json['name'], fallback: 'Unnamed Lead'),
      phone: _readText(json['phone'], fallback: '-'),
      email: _readText(json['email'], fallback: '-'),
      stage: _readText(json['stage'], fallback: 'NEW'),
      source: _readText(json['source'], fallback: '-'),
      leadFor: _readText(json['leadFor'], fallback: 'UNKNOWN'),
      city: _readText(json['city'], fallback: 'Unknown City'),
      community: _readText(json['community']),
      notes: _readText(json['notes']),
      petitionerRelation: _readText(json['petitionerRelation']),
      assignedToId: assignedTo is Map<String, dynamic>
          ? _readText(assignedTo['id'])
          : _readText(json['assignedToId']),
      assignedToName: assignedTo is Map<String, dynamic>
          ? _readText(assignedTo['name'], fallback: 'Unassigned')
          : 'Unassigned',
      assignedToRole: assignedTo is Map<String, dynamic>
          ? _readText(assignedTo['role'])
          : '',
      intentScore: _readInt(json['intentScore']),
      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
      convertedAt: _readDate(json['convertedAt']),
      lastUserResponseAt: _readDate(json['lastUserResponseAt']),
      lastRmActionAt: _readDate(json['lastRMActionAt']),
      lastSystemActionAt: _readDate(json['lastSystemActionAt']),
      communicationLogs: _readList(json['communicationLogs'])
          .whereType<Map<String, dynamic>>()
          .map(RmCommunicationLog.fromJson)
          .toList(),
      tasks: _readList(
        json['tasks'],
      ).whereType<Map<String, dynamic>>().map(RmLeadTask.fromJson).toList(),
      resumeCount: count is Map<String, dynamic>
          ? _readInt(count['resumesReceived'])
          : 0,
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
      ...communicationLogs
          .map((log) => log.createdAt)
          .whereType<DateTime>()
          .toList(growable: false),
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
