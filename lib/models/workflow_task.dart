class WorkflowTask {
  final String id;
  final String type;
  final String priority;
  final String source;
  final String status;
  final String workflowKind;
  final String workflowStatus;
  final String title;
  final String description;
  final String? assignedToId;
  final String? customerId;
  final String? leadId;
  final DateTime dueAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final WorkflowTaskLead? lead;
  final WorkflowTaskSubjectDisplay subjectDisplay;
  final String displayTitle;
  final String displayReason;
  final String displaySummary;

  WorkflowTask({
    required this.id,
    required this.type,
    required this.priority,
    required this.source,
    required this.status,
    required this.workflowKind,
    required this.workflowStatus,
    required this.title,
    required this.description,
    this.assignedToId,
    this.customerId,
    this.leadId,
    required this.dueAt,
    required this.createdAt,
    required this.updatedAt,
    this.lead,
    required this.subjectDisplay,
    required this.displayTitle,
    required this.displayReason,
    required this.displaySummary,
  });

  factory WorkflowTask.fromJson(Map<String, dynamic> json) {
    return WorkflowTask(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      priority: json['priority'] ?? '',
      source: json['source'] ?? '',
      status: json['status'] ?? '',
      workflowKind: json['workflowKind'] ?? '',
      workflowStatus: json['workflowStatus'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      assignedToId: json['assignedToId'],
      customerId: json['customerId'],
      leadId: json['leadId'],
      dueAt: DateTime.parse(json['dueAt']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      lead: json['lead'] != null
          ? WorkflowTaskLead.fromJson(json['lead'])
          : null,
      subjectDisplay: WorkflowTaskSubjectDisplay.fromJson(
        json['subjectDisplay'] ?? {},
      ),
      displayTitle: json['displayTitle'] ?? '',
      displayReason: json['displayReason'] ?? '',
      displaySummary: json['displaySummary'] ?? '',
    );
  }
}

class WorkflowTaskLead {
  final String id;
  final String name;
  final String phone;
  final String stage;

  WorkflowTaskLead({
    required this.id,
    required this.name,
    required this.phone,
    required this.stage,
  });

  factory WorkflowTaskLead.fromJson(Map<String, dynamic> json) {
    return WorkflowTaskLead(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      stage: json['stage'] ?? '',
    );
  }
}

class WorkflowTaskSubjectDisplay {
  final String title;
  final String? subtitle;
  final String reference;
  final String? leadId;
  final String? customerId;
  final String? leadStage;
  final String? profileImageUrl;

  WorkflowTaskSubjectDisplay({
    required this.title,
    this.subtitle,
    required this.reference,
    this.leadId,
    this.customerId,
    this.leadStage,
    this.profileImageUrl,
  });

  factory WorkflowTaskSubjectDisplay.fromJson(Map<String, dynamic> json) {
    return WorkflowTaskSubjectDisplay(
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      reference: json['reference'] ?? '',
      leadId: json['leadId'],
      customerId: json['customerId'],
      leadStage: json['leadStage'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
}
