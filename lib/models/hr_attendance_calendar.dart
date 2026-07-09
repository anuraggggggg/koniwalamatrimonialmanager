class HrAttendanceCalendar {
  const HrAttendanceCalendar({
    required this.month,
    required this.year,
    required this.employees,
  });

  final int month;
  final int year;
  final List<HrAttendanceEmployee> employees;

  factory HrAttendanceCalendar.fromJson(Map<String, dynamic> json) {
    return HrAttendanceCalendar(
      month: _readInt(json['month']),
      year: _readInt(json['year']),
      employees: _readList(json['employees'])
          .whereType<Map<String, dynamic>>()
          .map(HrAttendanceEmployee.fromJson)
          .toList(),
    );
  }

  int get presentCount => _countStatus('present');
  int get absentCount => _countStatus('absent');
  int get leaveCount => _countStatus('leave');
  int get holidayCount => _countStatus('holiday');
  int get totalEntries => employees.fold<int>(
        0,
        (total, employee) => total + employee.days.length,
      );

  int _countStatus(String status) {
    return employees.fold<int>(
      0,
      (total, employee) =>
          total +
          employee.days
              .where((day) => day.status.toLowerCase() == status)
              .length,
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

  static List<dynamic> _readList(dynamic value) {
    return value is List ? value : const [];
  }

  static String readText(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}

class HrAttendanceEmployee {
  const HrAttendanceEmployee({
    required this.id,
    required this.name,
    required this.email,
    required this.designation,
    required this.reportingManagerName,
    required this.days,
  });

  final String id;
  final String name;
  final String email;
  final String designation;
  final String reportingManagerName;
  final List<HrAttendanceDay> days;

  factory HrAttendanceEmployee.fromJson(Map<String, dynamic> json) {
    final reportingManager = json['reportingManager'];
    return HrAttendanceEmployee(
      id: HrAttendanceCalendar.readText(json['id']),
      name: HrAttendanceCalendar.readText(json['name'], fallback: 'Unknown'),
      email: HrAttendanceCalendar.readText(json['email']),
      designation: HrAttendanceCalendar.readText(
        json['designation'],
        fallback: '-',
      ),
      reportingManagerName: reportingManager is Map<String, dynamic>
          ? HrAttendanceCalendar.readText(reportingManager['name'])
          : '-',
      days: HrAttendanceCalendar._readList(json['days'])
          .whereType<Map<String, dynamic>>()
          .map(HrAttendanceDay.fromJson)
          .toList(),
    );
  }
}

class HrAttendanceDay {
  const HrAttendanceDay({required this.date, required this.status});

  final String date;
  final String status;

  factory HrAttendanceDay.fromJson(Map<String, dynamic> json) {
    return HrAttendanceDay(
      date: HrAttendanceCalendar.readText(json['date']),
      status: HrAttendanceCalendar.readText(json['status']),
    );
  }
}
