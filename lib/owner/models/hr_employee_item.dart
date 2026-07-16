class HrEmployeeItem {
  const HrEmployeeItem({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    required this.department,
    required this.image,
    required this.isActive,
    required this.isPresentToday,
    required this.designation,
    required this.baseSalary,
    required this.joiningDate,
    required this.joiningDateText,
    required this.reportingManagerName,
    required this.assignedLeads,
    required this.dataEntryProfiles,
    required this.assignedTasks,
    required this.closedLeads,
    required this.incentiveTierLabel,
    required this.incentiveProgressLabel,
    required this.isIncentiveEligible,
    required this.earnedPercentage,
    required this.payrollEnabled,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String department;
  final String image;
  final bool isActive;
  final bool isPresentToday;
  final String designation;
  final String baseSalary;
  final DateTime? joiningDate;
  final String joiningDateText;
  final String reportingManagerName;
  final int assignedLeads;
  final int dataEntryProfiles;
  final int assignedTasks;
  final int closedLeads;
  final String incentiveTierLabel;
  final String incentiveProgressLabel;
  final bool isIncentiveEligible;
  final double earnedPercentage;
  final bool payrollEnabled;

  HrEmployeeItem copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? department,
    String? image,
    bool? isActive,
    bool? isPresentToday,
    String? designation,
    String? baseSalary,
    DateTime? joiningDate,
    String? joiningDateText,
    String? reportingManagerName,
    int? assignedLeads,
    int? dataEntryProfiles,
    int? assignedTasks,
    int? closedLeads,
    String? incentiveTierLabel,
    String? incentiveProgressLabel,
    bool? isIncentiveEligible,
    double? earnedPercentage,
    bool? payrollEnabled,
  }) {
    return HrEmployeeItem(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      image: image ?? this.image,
      isActive: isActive ?? this.isActive,
      isPresentToday: isPresentToday ?? this.isPresentToday,
      designation: designation ?? this.designation,
      baseSalary: baseSalary ?? this.baseSalary,
      joiningDate: joiningDate ?? this.joiningDate,
      joiningDateText: joiningDateText ?? this.joiningDateText,
      reportingManagerName: reportingManagerName ?? this.reportingManagerName,
      assignedLeads: assignedLeads ?? this.assignedLeads,
      dataEntryProfiles: dataEntryProfiles ?? this.dataEntryProfiles,
      assignedTasks: assignedTasks ?? this.assignedTasks,
      closedLeads: closedLeads ?? this.closedLeads,
      incentiveTierLabel: incentiveTierLabel ?? this.incentiveTierLabel,
      incentiveProgressLabel:
          incentiveProgressLabel ?? this.incentiveProgressLabel,
      isIncentiveEligible: isIncentiveEligible ?? this.isIncentiveEligible,
      earnedPercentage: earnedPercentage ?? this.earnedPercentage,
      payrollEnabled: payrollEnabled ?? this.payrollEnabled,
    );
  }

  factory HrEmployeeItem.fromJson(Map<String, dynamic> json) {
    final employeeProfile = _readMap(json['employeeProfile']);
    final counts = _readMap(json['_count']);
    final incentiveSummary = _readMap(json['incentiveSummary']);
    final currentTier = _readMap(incentiveSummary?['currentTier']);
    final nextTier = _readMap(incentiveSummary?['nextTier']);
    final reportingManager =
        _readMap(json['reportingManager']) ??
        _readMap(employeeProfile?['reportingManager']);
    final role = _readText(json['role'], fallback: 'Employee');
    final joiningDateText = _readText(
      json['joiningDate'],
      fallback: _readText(employeeProfile?['joiningDate']),
    );
    final joiningDate = DateTime.tryParse(joiningDateText)?.toLocal();
    final currentEarnedPercentage = _readDouble(
      incentiveSummary?['earnedPercentage'],
    );
    final currentTierPayout = _readTierPayout(currentTier);

    return HrEmployeeItem(
      id: _readText(json['id']),
      name: _readText(json['name'], fallback: 'Employee'),
      email: _readText(json['email'], fallback: '-'),
      role: _readText(json['role'], fallback: '-'),
      phone: _readText(json['phone'], fallback: '-'),
      department: _readText(json['department'], fallback: '-'),
      image: _readText(json['image']),
      isActive: json['isActive'] == true,
      isPresentToday:
          json['isPresentToday'] == true ||
          _hasPresentAttendance(json['attendanceRecords']),
      designation: _firstNonEmpty([
        json['designation'],
        employeeProfile?['designation'],
      ], fallback: _formatRole(role)),
      baseSalary: _firstNonEmpty([
        json['baseSalary'],
        employeeProfile?['baseSalary'],
      ], fallback: '-'),
      joiningDate: joiningDate,
      joiningDateText: _formatDate(joiningDate),
      reportingManagerName: reportingManager is Map<String, dynamic>
          ? _readText(reportingManager['name'], fallback: '-')
          : '-',
      assignedLeads: _readInt(counts?['assignedLeads']),
      dataEntryProfiles: _readInt(counts?['dataEntryProfiles']),
      assignedTasks: _readInt(counts?['assignedTasks']),
      closedLeads: _readInt(counts?['closedLeads']),
      incentiveTierLabel: _readTierLabel(currentTier, nextTier),
      incentiveProgressLabel: _readIncentiveProgressLabel(
        incentiveSummary,
        currentTier,
        nextTier,
      ),
      isIncentiveEligible: incentiveSummary?['isEligible'] == true,
      earnedPercentage: currentEarnedPercentage > 0
          ? currentEarnedPercentage
          : currentTierPayout,
      payrollEnabled:
          json['payrollEnabled'] == true ||
          employeeProfile?['payrollEnabled'] == true,
    );
  }

  String get statusLabel {
    return isPresentToday ? 'PRESENT' : 'ABSENT';
  }

  String get displayRole {
    return _formatRole(role);
  }

  String get initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'E';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  String get tenureText {
    final date = joiningDate;
    if (date == null) {
      return joiningDateText;
    }

    final now = DateTime.now();
    var years = now.year - date.year;
    var months = now.month - date.month;

    if (now.day < date.day) {
      months--;
    }

    if (months < 0) {
      years--;
      months += 12;
    }

    if (years <= 0 && months <= 0) {
      return '$joiningDateText (new joiner)';
    }

    if (years <= 0) {
      return '$joiningDateText ($months months)';
    }

    return '$joiningDateText ($years.${months.clamp(0, 11)} years)';
  }

  static String _readTierLabel(dynamic currentTier, dynamic nextTier) {
    if (currentTier is Map<String, dynamic>) {
      final label = _readText(currentTier['label']);
      if (label.isNotEmpty) return '$label Tier';
    }

    if (nextTier is Map<String, dynamic>) {
      final label = _readText(nextTier['label']);
      if (label.isNotEmpty) return 'Next: $label';
    }

    return 'Active Employee';
  }

  static String _readIncentiveProgressLabel(
    Map<String, dynamic>? incentiveSummary,
    Map<String, dynamic>? currentTier,
    Map<String, dynamic>? nextTier,
  ) {
    if (incentiveSummary != null) {
      final qualifiedClosedLeads = _readInt(
        incentiveSummary['qualifiedClosedLeads'],
      );
      final requiredTarget = _readInt(incentiveSummary['requiredTarget']);
      if (requiredTarget > 0) {
        return '$qualifiedClosedLeads/$requiredTarget';
      }

      final earnedPercentage = _readDouble(
        incentiveSummary['earnedPercentage'],
      );
      if (earnedPercentage > 0) {
        return '${_formatPercent(earnedPercentage)}%';
      }
    }

    final currentTierPayout = _readTierPayout(currentTier);
    if (currentTierPayout > 0) {
      return '${_formatPercent(currentTierPayout)}%';
    }

    final nextTierPayout = _readTierPayout(nextTier);
    if (nextTierPayout > 0) {
      return 'Next ${_formatPercent(nextTierPayout)}%';
    }

    return 'N/A';
  }

  static String _readText(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return null;
  }

  static String _firstNonEmpty(
    List<dynamic> values, {
    required String fallback,
  }) {
    for (final value in values) {
      final text = _readText(value);
      if (text.isNotEmpty) {
        return text;
      }
    }

    return fallback;
  }

  static bool _hasPresentAttendance(dynamic value) {
    if (value is! List) {
      return false;
    }

    for (final entry in value) {
      if (entry is Map<String, dynamic> &&
          _readText(entry['status']).toUpperCase() == 'PRESENT') {
        return true;
      }
    }

    return false;
  }

  static double _readTierPayout(Map<String, dynamic>? tier) {
    if (tier == null) {
      return 0;
    }

    final payoutType = _readText(tier['payoutType']).toUpperCase();
    if (payoutType != 'PERCENTAGE') {
      return 0;
    }

    return _readDouble(tier['payoutValue']);
  }

  static String _formatPercent(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toStringAsFixed(1);
  }

  static String _formatRole(String value) {
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

  static String _formatDate(DateTime? value) {
    if (value == null) {
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

    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }
}
