class HrEmployeeAttendanceResult {
  const HrEmployeeAttendanceResult({required this.summary, required this.days});

  final HrEmployeeAttendanceSummary summary;
  final List<HrEmployeeAttendanceDay> days;

  factory HrEmployeeAttendanceResult.fromResponse(dynamic data) {
    final source = data is Map<String, dynamic>
        ? data
        : data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    final days =
        (source['days'] is List ? source['days'] as List : const [])
            .whereType<Map>()
            .map((item) => HrEmployeeAttendanceDay.fromJson(item))
            .toList()
          ..sort((left, right) => left.date.compareTo(right.date));

    return HrEmployeeAttendanceResult(
      summary: HrEmployeeAttendanceSummary.fromJson(source, days),
      days: days,
    );
  }
}

class HrEmployeeAttendanceSummary {
  const HrEmployeeAttendanceSummary({
    required this.name,
    required this.email,
    required this.designation,
    required this.reportingManagerName,
    required this.month,
    required this.year,
    required this.presentDays,
    required this.absentDays,
    required this.leaveDays,
    required this.holidayDays,
    required this.lateDays,
  });

  final String name;
  final String email;
  final String designation;
  final String reportingManagerName;
  final int month;
  final int year;
  final int presentDays;
  final int absentDays;
  final int leaveDays;
  final int holidayDays;
  final int lateDays;

  factory HrEmployeeAttendanceSummary.fromJson(
    Map<String, dynamic> json,
    List<HrEmployeeAttendanceDay> days,
  ) {
    final reportingManager = _asMap(json['reportingManager']);

    return HrEmployeeAttendanceSummary(
      name: _readText(json['name']),
      email: _readText(json['email']),
      designation: _readText(json['designation']),
      reportingManagerName: _readText(reportingManager?['name']),
      month: _readInt(json['month']),
      year: _readInt(json['year']),
      presentDays: _countStatus(days, 'present'),
      absentDays: _countStatus(days, 'absent'),
      leaveDays: _countStatus(days, 'leave'),
      holidayDays: _countStatus(days, 'holiday'),
      lateDays: days.where((day) => day.isLate).length,
    );
  }

  static int _countStatus(List<HrEmployeeAttendanceDay> days, String status) {
    return days.where((day) => day.normalizedStatus == status).length;
  }
}

class HrEmployeeAttendanceDay {
  const HrEmployeeAttendanceDay({
    required this.id,
    required this.date,
    required this.status,
    required this.source,
    this.loggedInAt,
    this.notes,
    this.leaveType,
    this.holidayName,
    this.isHalfDay = false,
  });

  final String id;
  final DateTime date;
  final String status;
  final String source;
  final DateTime? loggedInAt;
  final String? notes;
  final String? leaveType;
  final String? holidayName;
  final bool isHalfDay;

  String get normalizedStatus {
    final text = status.trim().toLowerCase();
    if (isHalfDay || text.contains('half')) return 'half';
    if (text.contains('holiday')) return 'holiday';
    if (text.contains('leave')) return 'leave';
    if (text.contains('absent')) return 'absent';
    if (text.contains('present') || text.contains('late')) return 'present';
    return text;
  }

  bool get isLate {
    final loggedAt = loggedInAt;
    if (loggedAt == null || normalizedStatus != 'present') {
      return false;
    }
    final local = loggedAt.toLocal();
    return local.hour > 10 || (local.hour == 10 && local.minute > 15);
  }

  factory HrEmployeeAttendanceDay.fromJson(Map<dynamic, dynamic> json) {
    final leaveDetails = _asMap(json['leaveDetails']);
    final holidayDetails = _asMap(json['holidayDetails']);

    return HrEmployeeAttendanceDay(
      id: _readText(json['id']),
      date: DateTime.tryParse(_readText(json['date'])) ?? DateTime(1900),
      status: _readText(json['status']),
      source: _readText(json['source']),
      loggedInAt: DateTime.tryParse(_readText(json['loggedInAt'])),
      notes: _nullableText(json['notes']),
      leaveType: _nullableText(leaveDetails?['type']),
      holidayName: _nullableText(holidayDetails?['name']),
      isHalfDay:
          leaveDetails?['isHalfDay'] == true ||
          holidayDetails?['isHalfDay'] == true,
    );
  }
}

class HrPayrollHistoryItem {
  const HrPayrollHistoryItem({
    required this.id,
    required this.month,
    required this.year,
    required this.status,
    required this.workingDays,
    required this.payableDays,
    required this.presentDays,
    required this.absentDays,
    required this.leaveDays,
    required this.holidayDays,
    required this.baseSalary,
    required this.deductionAmount,
    required this.incentiveAmount,
    required this.netSalary,
    required this.payslipDeliveryStatus,
    this.payslipFileName,
    this.payslipGeneratedAt,
  });

  final String id;
  final int month;
  final int year;
  final String status;
  final int workingDays;
  final int payableDays;
  final int presentDays;
  final int absentDays;
  final int leaveDays;
  final int holidayDays;
  final double baseSalary;
  final double deductionAmount;
  final double incentiveAmount;
  final double netSalary;
  final String payslipDeliveryStatus;
  final String? payslipFileName;
  final DateTime? payslipGeneratedAt;

  DateTime get periodDate =>
      DateTime(year == 0 ? 1900 : year, month == 0 ? 1 : month);

  static List<HrPayrollHistoryItem> fromResponse(dynamic data) {
    final rows = _extractRows(data);
    return rows
        .whereType<Map>()
        .map((row) => HrPayrollHistoryItem.fromJson(row))
        .toList()
      ..sort((left, right) => right.periodDate.compareTo(left.periodDate));
  }

  factory HrPayrollHistoryItem.fromJson(Map<dynamic, dynamic> json) {
    final payrollRun =
        _asMap(json['payrollRun']) ??
        _asMap(json['run']) ??
        _asMap(json['payroll']);

    return HrPayrollHistoryItem(
      id: _readText(json['id']),
      month: _readInt(json['month'] ?? payrollRun?['month']),
      year: _readInt(json['year'] ?? payrollRun?['year']),
      status: _readText(
        json['status'] ?? payrollRun?['status'],
        fallback: 'PENDING',
      ),
      workingDays: _readInt(json['workingDays']),
      payableDays: _readInt(json['payableDays']),
      presentDays: _readInt(json['presentDays']),
      absentDays: _readInt(json['absentDays']),
      leaveDays: _readInt(json['leaveDays']),
      holidayDays: _readInt(json['holidayDays']),
      baseSalary: _readDouble(json['baseSalary']),
      deductionAmount: _readDouble(json['deductionAmount']),
      incentiveAmount: _readDouble(json['incentiveAmount']),
      netSalary: _readDouble(json['netSalary']),
      payslipDeliveryStatus: _readText(
        json['payslipDeliveryStatus'],
        fallback: 'PENDING',
      ),
      payslipFileName: _nullableText(json['payslipFileName']),
      payslipGeneratedAt: DateTime.tryParse(
        _readText(json['payslipGeneratedAt']),
      ),
    );
  }

  static List<dynamic> _extractRows(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      for (final key in const [
        'history',
        'entries',
        'payrolls',
        'data',
        'items',
      ]) {
        final value = data[key];
        if (value is List) {
          return value;
        }
        if (value is Map) {
          return _extractRows(value);
        }
      }
      return [data];
    }

    return const [];
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

String _readText(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String? _nullableText(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
