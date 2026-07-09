
class RmDashboardSummary {
  const RmDashboardSummary({
    required this.assignedLeads,
    required this.openTasks,
    required this.needsReply,
    required this.followUpToday,
    required this.activeJourneys,
    required this.waiting,
    required this.overdue,
  });

  final int assignedLeads;
  final int openTasks;
  final int needsReply;
  final int followUpToday;
  final int activeJourneys;
  final int waiting;
  final int overdue;

  factory RmDashboardSummary.fromJson(Map<String, dynamic> json) {
    return RmDashboardSummary(
      assignedLeads: _readInt(json['assignedLeads']),
      openTasks: _readInt(json['openTasks']),
      needsReply: _readInt(json['needsReply']),
      followUpToday: _readInt(json['followUpToday']),
      activeJourneys: _readInt(json['activeJourneys']),
      waiting: _readInt(json['waiting']),
      overdue: _readInt(json['overdue']),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
