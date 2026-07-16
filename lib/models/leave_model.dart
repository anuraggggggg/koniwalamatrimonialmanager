class LeaveModel {
  final String id;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status;
  final bool isHalfDay;
  final String userId;
  final String userEmail;
  final String userName;
  final String userRole;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LeaveModel({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.isHalfDay,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.userRole,
    this.createdAt,
    this.updatedAt,
  });

  LeaveModel copyWith({
    String? id,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    String? status,
    bool? isHalfDay,
    String? userId,
    String? userEmail,
    String? userName,
    String? userRole,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeaveModel(
      id: id ?? this.id,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      isHalfDay: isHalfDay ?? this.isHalfDay,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    final user =
        json['user'] ??
        json['employee'] ??
        json['requester'] ??
        json['requestedBy'] ??
        json['applicant'] ??
        json['staff'] ??
        json['createdBy'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : null;
    final userValue = user is Map ? null : user;

    return LeaveModel(
      id: _readString(json['id'] ?? json['_id']),
      type: _readString(json['type'] ?? json['leaveType'] ?? json['category']),
      startDate: _readRequiredDate(json['startDate'] ?? json['fromDate']),
      endDate: _readRequiredDate(json['endDate'] ?? json['toDate']),
      reason: _readString(json['reason']),
      status: _readString(json['status']).isEmpty
          ? 'PENDING'
          : _readString(json['status']),
      isHalfDay: json['isHalfDay'] ?? false,
      userId: _readString(
        userMap?['id'] ??
            userMap?['_id'] ??
            json['userId'] ??
            json['employeeId'] ??
            json['requesterId'] ??
            json['requestedById'] ??
            json['applicantId'] ??
            json['staffId'] ??
            userValue ??
            (json['createdBy'] is Map ? null : json['createdBy']),
      ),
      userEmail: _readString(
        userMap?['email'] ??
            json['userEmail'] ??
            json['employeeEmail'] ??
            json['requesterEmail'] ??
            json['applicantEmail'],
      ),
      userName: _readString(
        userMap?['name'] ??
            json['userName'] ??
            json['employeeName'] ??
            json['requesterName'] ??
            json['applicantName'],
        fallback: 'Unknown',
      ),
      userRole: _readString(
        userMap?['role'] ??
            json['userRole'] ??
            json['employeeRole'] ??
            json['requesterRole'] ??
            json['applicantRole'],
        fallback: 'N/A',
      ),
      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
    );
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static DateTime _readRequiredDate(dynamic value) {
    final parsed = _readDate(value);
    if (parsed != null) {
      return parsed;
    }
    return DateTime.now();
  }

  static DateTime? _readDate(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toLocal();
  }
}
