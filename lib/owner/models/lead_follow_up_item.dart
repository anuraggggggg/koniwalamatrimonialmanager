class LeadFollowUpItem {
  const LeadFollowUpItem({
    required this.id,
    required this.customerId,
    required this.name,
    required this.phone,
    required this.email,
    required this.stage,
    required this.source,
    required this.city,
    required this.assignedToName,
    required this.notes,
    required this.createdAt,
    required this.lastUserResponseAt,
    required this.lastRmActionAt,
    required this.tasks,
    required this.followUpTasks,
    required this.openFollowUps,
    required this.doneFollowUps,
    required this.latestTaskCreatedAt,
    required this.searchIndex,
  });

  final String id;
  final String customerId;
  final String name;
  final String phone;
  final String email;
  final String stage;
  final String source;
  final String city;
  final String assignedToName;
  final String notes;
  final DateTime? createdAt;
  final DateTime? lastUserResponseAt;
  final DateTime? lastRmActionAt;
  final List<LeadFollowUpTask> tasks;
  final List<LeadFollowUpTask> followUpTasks;
  final List<LeadFollowUpTask> openFollowUps;
  final List<LeadFollowUpTask> doneFollowUps;
  final DateTime? latestTaskCreatedAt;
  final String searchIndex;

  factory LeadFollowUpItem.fromJson(Map<String, dynamic> json) {
    final assignedTo = json['assignedTo'];
    final customer = json['customer'];
    final taskRows = json['tasks'];
    final tasks = taskRows is List
        ? taskRows
              .whereType<Map<String, dynamic>>()
              .map(LeadFollowUpTask.fromJson)
              .toList(growable: false)
        : const <LeadFollowUpTask>[];
    final followUps = _followUpTasksFor(tasks);
    final openFollowUps = followUps
        .where((task) => task.isOpen)
        .toList(growable: false);
    final doneFollowUps = followUps
        .where((task) => task.isDone)
        .toList(growable: false);

    final item = LeadFollowUpItem(
      id: _readText(json['id']),
      customerId: customer is Map<String, dynamic>
          ? _readText(customer['id'], fallback: _readText(json['customerId']))
          : _readText(json['customerId']),
      name: _readText(json['name'], fallback: 'Unnamed Lead'),
      phone: _readText(json['phone'], fallback: '-'),
      email: _readText(json['email'], fallback: '-'),
      stage: _formatEnumLabel(_readText(json['stage'], fallback: 'New')),
      source: _formatEnumLabel(_readText(json['source'], fallback: '-')),
      city: _readText(json['city'], fallback: '-'),
      assignedToName: assignedTo is Map<String, dynamic>
          ? _readText(assignedTo['name'], fallback: '-')
          : '-',
      notes: _readText(json['notes']),
      createdAt: _readDate(json['createdAt']),
      lastUserResponseAt: _readDate(json['lastUserResponseAt']),
      lastRmActionAt: _readDate(json['lastRMActionAt']),
      tasks: tasks,
      followUpTasks: followUps,
      openFollowUps: openFollowUps,
      doneFollowUps: doneFollowUps,
      latestTaskCreatedAt: _latestCreatedAt(followUps),
      searchIndex: '',
    );
    return item._withSearchIndex();
  }

  bool get hasOverdueFollowUp {
    return openFollowUps.any((task) => task.isOverdue);
  }

  bool get isWaiting {
    if (lastRmActionAt == null) {
      return false;
    }

    return lastUserResponseAt == null ||
        lastRmActionAt!.isAfter(lastUserResponseAt!);
  }

  bool get isCold {
    final anchor = lastUserResponseAt ?? createdAt;
    if (anchor == null) {
      return false;
    }

    return DateTime.now().difference(anchor).inDays >= 5;
  }

  String get initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return 'L';
    }

    if (words.length == 1) {
      return words.first[0].toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  String get leadMeta {
    final cityLabel = city == '-' ? 'Office' : '$city Office';
    return '$cityLabel • $stage • Active $activeDurationLabel';
  }

  String get activeDurationLabel {
    if (createdAt == null) {
      return 'recently';
    }

    final difference = DateTime.now().difference(createdAt!);
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    }

    if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    }

    return 'today';
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    return searchIndex.contains(normalized);
  }

  LeadFollowUpItem _withSearchIndex() {
    return LeadFollowUpItem(
      id: id,
      customerId: customerId,
      name: name,
      phone: phone,
      email: email,
      stage: stage,
      source: source,
      city: city,
      assignedToName: assignedToName,
      notes: notes,
      createdAt: createdAt,
      lastUserResponseAt: lastUserResponseAt,
      lastRmActionAt: lastRmActionAt,
      tasks: tasks,
      followUpTasks: followUpTasks,
      openFollowUps: openFollowUps,
      doneFollowUps: doneFollowUps,
      latestTaskCreatedAt: latestTaskCreatedAt,
      searchIndex: _buildSearchIndex(),
    );
  }

  String _buildSearchIndex() {
    return <String>[
      name,
      phone,
      email,
      stage,
      source,
      city,
      assignedToName,
      notes,
      ...tasks.map((task) => task.title),
      ...tasks.map((task) => task.priority),
      ...tasks.map((task) => task.workflowStatus),
    ].join(' ').toLowerCase();
  }
}

List<LeadFollowUpTask> _followUpTasksFor(List<LeadFollowUpTask> tasks) {
  final followUps = tasks.where((task) {
    final type = _enumKey(task.type);
    final workflowStatus = _enumKey(task.workflowStatus);
    final title = task.title.toLowerCase();

    return type == 'CALL' ||
        type == 'FOLLOW_UP' ||
        workflowStatus.contains('FOLLOW_UP') ||
        title.contains('follow');
  }).toList();

  followUps.sort((first, second) {
    final firstCreatedAt = first.createdAt;
    final secondCreatedAt = second.createdAt;
    if (firstCreatedAt == null && secondCreatedAt == null) return 0;
    if (firstCreatedAt == null) return 1;
    if (secondCreatedAt == null) return -1;
    return secondCreatedAt.compareTo(firstCreatedAt);
  });
  return followUps;
}

DateTime? _latestCreatedAt(List<LeadFollowUpTask> tasks) {
  DateTime? latest;
  for (final task in tasks) {
    final createdAt = task.createdAt;
    if (createdAt != null && (latest == null || createdAt.isAfter(latest))) {
      latest = createdAt;
    }
  }
  return latest;
}

class LeadFollowUpTask {
  const LeadFollowUpTask({
    required this.id,
    required this.title,
    required this.type,
    required this.priority,
    required this.status,
    required this.workflowStatus,
    required this.assignedToName,
    required this.dueAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String type;
  final String priority;
  final String status;
  final String workflowStatus;
  final String assignedToName;
  final DateTime? dueAt;
  final DateTime? createdAt;

  factory LeadFollowUpTask.fromJson(Map<String, dynamic> json) {
    final assignedTo = json['assignedTo'];

    return LeadFollowUpTask(
      id: _readText(json['id']),
      title: _readText(json['title'], fallback: 'Follow up with lead'),
      type: _formatEnumLabel(_readText(json['type'], fallback: 'Task')),
      priority: _formatEnumLabel(_readText(json['priority'], fallback: '-')),
      status: _formatEnumLabel(_readText(json['status'], fallback: 'Open')),
      workflowStatus: _formatEnumLabel(
        _readText(json['workflowStatus'], fallback: '-'),
      ),
      assignedToName: assignedTo is Map<String, dynamic>
          ? _readText(assignedTo['name'], fallback: '-')
          : '-',
      dueAt: _readDate(json['dueAt']),
      createdAt: _readDate(json['createdAt']),
    );
  }

  bool get isDone {
    final statusKey = _enumKey(status);
    final workflowKey = _enumKey(workflowStatus);

    return statusKey == 'DONE' ||
        statusKey == 'COMPLETED' ||
        statusKey == 'CLOSED' ||
        workflowKey == 'COMPLETED';
  }

  bool get isOpen => !isDone;

  bool get isOverdue {
    return isOpen && dueAt != null && dueAt!.isBefore(DateTime.now());
  }

  String get dueDateLabel {
    if (dueAt == null) {
      return '-';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final date = dueAt!.toLocal();
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

String _readText(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }

  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

DateTime? _readDate(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString())?.toLocal();
}

String _formatEnumLabel(String value) {
  if (value == '-') {
    return value;
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

String _enumKey(String value) {
  return value.trim().toUpperCase().replaceAll(' ', '_');
}
