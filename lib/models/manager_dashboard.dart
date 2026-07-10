class ManagerDashboard {
  final ManagerDashboardPeriod period;
  final ManagerDashboardKpi kpi;
  final List<ManagerDashboardFunnelItem> funnel;
  final List<ManagerFollowUpControlItem> followUpControl;
  final List<ManagerTeamStatusItem> liveTeamStatus;
  final ManagerDashboardUrgent urgent;
  final ManagerDashboardAiPanel aiPanel;
  final List<ManagerRecentActivityItem> recentActivity;
  final List<ManagerRecentProfileItem> recentProfiles;
  final List<ManagerAiSuggestionItem> aiSuggestions;
  final ManagerAgencyPerformance agencyPerformance;
  final Map<String, dynamic> raw;

  ManagerDashboard({
    required this.period,
    required this.kpi,
    required this.funnel,
    required this.followUpControl,
    required this.liveTeamStatus,
    required this.urgent,
    required this.aiPanel,
    required this.recentActivity,
    required this.recentProfiles,
    required this.aiSuggestions,
    required this.agencyPerformance,
    required this.raw,
  });

  factory ManagerDashboard.fromJson(Map<String, dynamic> json) {
    final payload = _unwrapPayload(json);

    return ManagerDashboard(
      period: ManagerDashboardPeriod.fromJson(_readMap(payload['period'])),
      kpi: ManagerDashboardKpi.fromJson(payload),
      funnel: _readList(payload['funnel'])
          .whereType<Map<String, dynamic>>()
          .map(ManagerDashboardFunnelItem.fromJson)
          .toList(),
      followUpControl: _readList(payload['followUpControl'])
          .whereType<Map<String, dynamic>>()
          .map(ManagerFollowUpControlItem.fromJson)
          .toList(),
      liveTeamStatus: _readList(payload['liveTeamStatus'])
          .whereType<Map<String, dynamic>>()
          .map(ManagerTeamStatusItem.fromJson)
          .toList(),
      urgent: ManagerDashboardUrgent.fromJson(_readMap(payload['urgent'])),
      aiPanel: ManagerDashboardAiPanel.fromJson(_readMap(payload['aiPanel'])),
      recentActivity: _readList(payload['recentActivity'])
          .whereType<Map<String, dynamic>>()
          .map(ManagerRecentActivityItem.fromJson)
          .toList(),
      recentProfiles: _readList(payload['recentProfiles'])
          .whereType<Map<String, dynamic>>()
          .map(ManagerRecentProfileItem.fromJson)
          .toList(),
      aiSuggestions: _readList(payload['aiSuggestions'])
          .whereType<Map<String, dynamic>>()
          .map(ManagerAiSuggestionItem.fromJson)
          .toList(),
      agencyPerformance: ManagerAgencyPerformance.fromJson(
        _readMap(payload['agencyPerformance']),
      ),
      raw: payload,
    );
  }

  static Map<String, dynamic> _unwrapPayload(Map<String, dynamic> json) {
    for (final key in const ['data', 'dashboard', 'managerDashboard']) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
    }

    return json;
  }

  static Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const {};
  }

  static List<dynamic> _readList(dynamic value) {
    return value is List ? value : const [];
  }

  static int readInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double readDouble(dynamic value, {double fallback = 0}) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String readText(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static bool readBool(dynamic value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().trim().toLowerCase();
    if (text == 'true' || text == '1' || text == 'yes') {
      return true;
    }
    if (text == 'false' || text == '0' || text == 'no') {
      return false;
    }
    return fallback;
  }
}

class ManagerDashboardPeriod {
  final String key;
  final String label;
  final String startDate;
  final String endDate;
  final String displayText;

  ManagerDashboardPeriod({
    required this.key,
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.displayText,
  });

  factory ManagerDashboardPeriod.fromJson(Map<String, dynamic> json) {
    return ManagerDashboardPeriod(
      key: ManagerDashboard.readText(json['key'], fallback: 'past_month'),
      label: ManagerDashboard.readText(json['label'], fallback: 'Past Month'),
      startDate: ManagerDashboard.readText(json['startDate']),
      endDate: ManagerDashboard.readText(json['endDate']),
      displayText: ManagerDashboard.readText(json['displayText']),
    );
  }
}

class ManagerDashboardKpi {
  final int totalLeads;
  final int activeProfiles;
  final int matchesToday;
  final int conversionRate;
  final int revenue;
  final int followUpsDue;

  ManagerDashboardKpi({
    required this.totalLeads,
    required this.activeProfiles,
    required this.matchesToday,
    required this.conversionRate,
    required this.revenue,
    required this.followUpsDue,
  });

  factory ManagerDashboardKpi.fromJson(Map<String, dynamic> json) {
    final kpi = ManagerDashboard._readMap(json['kpi']);
    final topKpis = ManagerDashboard._readMap(json['topKpis']);
    final totalLeads = ManagerDashboard._readMap(topKpis['totalLeads']);
    final activeClients = ManagerDashboard._readMap(topKpis['activeClients']);
    final followUps = ManagerDashboard._readMap(topKpis['followUps']);

    return ManagerDashboardKpi(
      totalLeads: ManagerDashboard.readInt(
        kpi['totalLeads'],
        fallback: ManagerDashboard.readInt(totalLeads['value']),
      ),
      activeProfiles: ManagerDashboard.readInt(
        kpi['activeProfiles'],
        fallback: ManagerDashboard.readInt(activeClients['value']),
      ),
      matchesToday: ManagerDashboard.readInt(kpi['matchesToday']),
      conversionRate: ManagerDashboard.readInt(kpi['conversionRate']),
      revenue: ManagerDashboard.readInt(kpi['revenue']),
      followUpsDue: ManagerDashboard.readInt(
        kpi['followUpsDue'],
        fallback: ManagerDashboard.readInt(followUps['value']),
      ),
    );
  }
}

class ManagerDashboardFunnelItem {
  final String label;
  final int count;
  final double progress;

  ManagerDashboardFunnelItem({
    required this.label,
    required this.count,
    required this.progress,
  });

  double get normalizedProgress => progress > 1 ? progress / 100 : progress;

  factory ManagerDashboardFunnelItem.fromJson(Map<String, dynamic> json) {
    return ManagerDashboardFunnelItem(
      label: ManagerDashboard.readText(json['label'], fallback: 'Funnel'),
      count: ManagerDashboard.readInt(json['count']),
      progress: ManagerDashboard.readDouble(json['progress']),
    );
  }
}

class ManagerFollowUpControlItem {
  final String id;
  final String name;
  final String role;
  final String? image;
  final int pendingFollowUps;
  final int completedFollowUps;
  final int overdueFollowUps;

  ManagerFollowUpControlItem({
    required this.id,
    required this.name,
    required this.role,
    this.image,
    required this.pendingFollowUps,
    required this.completedFollowUps,
    required this.overdueFollowUps,
  });

  factory ManagerFollowUpControlItem.fromJson(Map<String, dynamic> json) {
    return ManagerFollowUpControlItem(
      id: ManagerDashboard.readText(json['id']),
      name: ManagerDashboard.readText(json['name'], fallback: 'Team Member'),
      role: ManagerDashboard.readText(json['role']),
      image: json['image']?.toString(),
      pendingFollowUps: ManagerDashboard.readInt(json['pendingFollowUps']),
      completedFollowUps: ManagerDashboard.readInt(json['completedFollowUps']),
      overdueFollowUps: ManagerDashboard.readInt(json['overdueFollowUps']),
    );
  }
}

class ManagerTeamStatusItem {
  final String id;
  final String name;
  final String role;
  final String? image;
  final String status;
  final String todayAttendanceStatus;
  final int leadsHandled;
  final int tasksCompleted;
  final int profilesHandled;

  ManagerTeamStatusItem({
    required this.id,
    required this.name,
    required this.role,
    this.image,
    required this.status,
    required this.todayAttendanceStatus,
    required this.leadsHandled,
    required this.tasksCompleted,
    required this.profilesHandled,
  });

  factory ManagerTeamStatusItem.fromJson(Map<String, dynamic> json) {
    return ManagerTeamStatusItem(
      id: ManagerDashboard.readText(json['id']),
      name: ManagerDashboard.readText(json['name'], fallback: 'Team Member'),
      role: ManagerDashboard.readText(json['role']),
      image: json['image']?.toString(),
      status: ManagerDashboard.readText(json['status'], fallback: 'offline'),
      todayAttendanceStatus: ManagerDashboard.readText(
        json['todayAttendanceStatus'],
        fallback: 'Not Checked In',
      ),
      leadsHandled: ManagerDashboard.readInt(json['leadsHandled']),
      tasksCompleted: ManagerDashboard.readInt(json['tasksCompleted']),
      profilesHandled: ManagerDashboard.readInt(json['profilesHandled']),
    );
  }
}

class ManagerDashboardUrgent {
  final int unassignedLeads;
  final int staleLeads;
  final int pendingReplies;
  final int readyToSend;

  ManagerDashboardUrgent({
    required this.unassignedLeads,
    required this.staleLeads,
    required this.pendingReplies,
    required this.readyToSend,
  });

  factory ManagerDashboardUrgent.fromJson(Map<String, dynamic> json) {
    return ManagerDashboardUrgent(
      unassignedLeads: ManagerDashboard.readInt(json['unassignedLeads']),
      staleLeads: ManagerDashboard.readInt(json['staleLeads']),
      pendingReplies: ManagerDashboard.readInt(json['pendingReplies']),
      readyToSend: ManagerDashboard.readInt(json['readyToSend']),
    );
  }
}

class ManagerDashboardAiPanel {
  final int successRate;
  final String score;
  final List<ManagerSuggestedMatchItem> suggestedMatches;
  final List<ManagerAiTaskItem> tasks;

  ManagerDashboardAiPanel({
    required this.successRate,
    required this.score,
    required this.suggestedMatches,
    required this.tasks,
  });

  factory ManagerDashboardAiPanel.fromJson(Map<String, dynamic> json) {
    return ManagerDashboardAiPanel(
      successRate: ManagerDashboard.readInt(json['successRate']),
      score: ManagerDashboard.readText(json['score']),
      suggestedMatches: ManagerDashboard._readList(json['suggestedMatches'])
          .whereType<Map<String, dynamic>>()
          .map(ManagerSuggestedMatchItem.fromJson)
          .toList(),
      tasks: ManagerDashboard._readList(json['tasks'])
          .whereType<Map<String, dynamic>>()
          .map(ManagerAiTaskItem.fromJson)
          .toList(),
    );
  }
}

class ManagerSuggestedMatchItem {
  final String leftName;
  final String rightName;
  final String match;
  final String leftSubtitle;
  final String rightSubtitle;

  ManagerSuggestedMatchItem({
    required this.leftName,
    required this.rightName,
    required this.match,
    required this.leftSubtitle,
    required this.rightSubtitle,
  });

  factory ManagerSuggestedMatchItem.fromJson(Map<String, dynamic> json) {
    final left = ManagerDashboard._readMap(json['left']);
    final right = ManagerDashboard._readMap(json['right']);
    final matchValue = ManagerDashboard.readText(
      json['match'],
      fallback: ManagerDashboard.readText(
        json['matchPercentage'],
        fallback: ManagerDashboard.readText(
          json['score'],
          fallback: ManagerDashboard.readText(json['compatibility']),
        ),
      ),
    );

    String normalizedMatch = matchValue;
    if (normalizedMatch.isNotEmpty &&
        !normalizedMatch.endsWith('%') &&
        double.tryParse(normalizedMatch) != null) {
      normalizedMatch = '$normalizedMatch%';
    }

    return ManagerSuggestedMatchItem(
      leftName: ManagerDashboard.readText(
        json['leftName'],
        fallback: ManagerDashboard.readText(
          left['name'],
          fallback: ManagerDashboard.readText(
            json['profileAName'],
            fallback: 'Profile A',
          ),
        ),
      ),
      rightName: ManagerDashboard.readText(
        json['rightName'],
        fallback: ManagerDashboard.readText(
          right['name'],
          fallback: ManagerDashboard.readText(
            json['profileBName'],
            fallback: 'Profile B',
          ),
        ),
      ),
      match: normalizedMatch.isEmpty ? '0%' : normalizedMatch,
      leftSubtitle: ManagerDashboard.readText(
        json['leftSubtitle'],
        fallback: ManagerDashboard.readText(
          left['subtitle'],
          fallback: ManagerDashboard.readText(left['location']),
        ),
      ),
      rightSubtitle: ManagerDashboard.readText(
        json['rightSubtitle'],
        fallback: ManagerDashboard.readText(
          right['subtitle'],
          fallback: ManagerDashboard.readText(right['location']),
        ),
      ),
    );
  }
}

class ManagerAiTaskItem {
  final String title;
  final String badge;
  final String priority;

  ManagerAiTaskItem({
    required this.title,
    required this.badge,
    required this.priority,
  });

  factory ManagerAiTaskItem.fromJson(Map<String, dynamic> json) {
    final priority = ManagerDashboard.readText(json['priority']);
    return ManagerAiTaskItem(
      title: ManagerDashboard.readText(
        json['title'],
        fallback: ManagerDashboard.readText(
          json['description'],
          fallback: 'Pending task',
        ),
      ),
      badge: ManagerDashboard.readText(
        json['badge'],
        fallback: priority.isEmpty ? 'Task' : priority,
      ),
      priority: priority,
    );
  }
}

class ManagerRecentActivityItem {
  final String id;
  final String category;
  final String title;
  final String description;
  final String action;
  final String icon;

  final String actorName;
  final String actorRole;

  ManagerRecentActivityItem({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.action,
    required this.icon,
    required this.actorName,
    required this.actorRole,
  });

  factory ManagerRecentActivityItem.fromJson(Map<String, dynamic> json) {
    return ManagerRecentActivityItem(
      id: ManagerDashboard.readText(json['id']),
      category: ManagerDashboard.readText(json['category']),
      title: ManagerDashboard.readText(
        json['title'],
        fallback: 'Activity',
      ),
      description: ManagerDashboard.readText(json['description']),
      action: ManagerDashboard.readText(json['action']),
      icon: ManagerDashboard.readText(json['icon']),
      actorName: ManagerDashboard.readText(json['actorName']),
      actorRole: ManagerDashboard.readText(json['actorRole']),
    );
  }
}

class ManagerRecentProfileItem {
  final String id;
  final String name;
  final String time;
  final String status;
  final String statusColor;
  final String client;
  final String source;
  final String? phone;
  final String notificationId;
  final bool verified;
  final String init;
  final String? image;

  ManagerRecentProfileItem({
    required this.id,
    required this.name,
    required this.time,
    required this.status,
    required this.statusColor,
    required this.client,
    required this.source,
    this.phone,
    required this.notificationId,
    required this.verified,
    required this.init,
    this.image,
  });

  String get initials {
    if (init.isNotEmpty) {
      return init;
    }

    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return parts.isEmpty ? 'NA' : parts;
  }

  factory ManagerRecentProfileItem.fromJson(Map<String, dynamic> json) {
    return ManagerRecentProfileItem(
      id: ManagerDashboard.readText(json['id']),
      name: ManagerDashboard.readText(json['name'], fallback: 'Profile'),
      time: ManagerDashboard.readText(json['time']),
      status: ManagerDashboard.readText(json['status']),
      statusColor: ManagerDashboard.readText(json['statusColor']),
      client: ManagerDashboard.readText(json['client']),
      source: ManagerDashboard.readText(json['source']),
      phone: json['phone']?.toString(),
      notificationId: ManagerDashboard.readText(
        json['notificationId'],
        fallback: ManagerDashboard.readText(json['notification_id']),
      ),
      verified: ManagerDashboard.readBool(json['verified']),
      init: ManagerDashboard.readText(json['init']),
      image: json['image']?.toString(),
    );
  }
}

class ManagerAiSuggestionItem {
  final String id;
  final String type;
  final String priority;
  final String title;
  final String description;
  final String actionLabel;
  final String targetRoute;

  ManagerAiSuggestionItem({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.targetRoute,
  });

  factory ManagerAiSuggestionItem.fromJson(Map<String, dynamic> json) {
    return ManagerAiSuggestionItem(
      id: ManagerDashboard.readText(json['id']),
      type: ManagerDashboard.readText(json['type']),
      priority: ManagerDashboard.readText(json['priority']),
      title: ManagerDashboard.readText(json['title'], fallback: 'Suggestion'),
      description: ManagerDashboard.readText(json['description']),
      actionLabel: ManagerDashboard.readText(
        json['actionLabel'],
        fallback: 'Review',
      ),
      targetRoute: ManagerDashboard.readText(json['targetRoute']),
    );
  }
}

class ManagerAgencyPerformance {
  final int overallConversionRate;
  final int closedClients;
  final int taskCompletionRate;

  ManagerAgencyPerformance({
    required this.overallConversionRate,
    required this.closedClients,
    required this.taskCompletionRate,
  });

  factory ManagerAgencyPerformance.fromJson(Map<String, dynamic> json) {
    return ManagerAgencyPerformance(
      overallConversionRate: ManagerDashboard.readInt(
        json['overallConversionRate'],
      ),
      closedClients: ManagerDashboard.readInt(json['closedClients']),
      taskCompletionRate: ManagerDashboard.readInt(json['taskCompletionRate']),
    );
  }
}
