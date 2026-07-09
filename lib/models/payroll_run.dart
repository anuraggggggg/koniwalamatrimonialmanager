class PayrollRun {
  final String id;
  final int month;
  final int year;
  final String status;
  final DateTime? finalizedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PayrollEntry> entries;

  PayrollRun({
    required this.id,
    required this.month,
    required this.year,
    required this.status,
    this.finalizedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.entries,
  });

  factory PayrollRun.fromJson(Map<String, dynamic> json) {
    return PayrollRun(
      id: json['id'],
      month: json['month'],
      year: json['year'],
      status: json['status'],
      finalizedAt: json['finalizedAt'] != null
          ? DateTime.parse(json['finalizedAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      entries: (json['entries'] as List)
          .map((e) => PayrollEntry.fromJson(e))
          .toList(),
    );
  }
}

class PayrollEntry {
  final String id;
  final String payrollRunId;
  final String userId;
  final int workingDays;
  final int payableDays;
  final int presentDays;
  final int absentDays;
  final int leaveDays;
  final int holidayDays;
  final String baseSalary;
  final String deductionAmount;
  final String incentiveAmount;
  final dynamic incentiveSnapshot;
  final String netSalary;
  final bool netSalaryEdited;
  final DateTime? netSalaryEditedAt;
  final String? payslipFileName;
  final String? payslipFileUrl;
  final DateTime? payslipGeneratedAt;
  final String payslipDeliveryStatus;
  final DateTime? payslipSentAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserInfo user;

  PayrollEntry({
    required this.id,
    required this.payrollRunId,
    required this.userId,
    required this.workingDays,
    required this.payableDays,
    required this.presentDays,
    required this.absentDays,
    required this.leaveDays,
    required this.holidayDays,
    required this.baseSalary,
    required this.deductionAmount,
    required this.incentiveAmount,
    this.incentiveSnapshot,
    required this.netSalary,
    required this.netSalaryEdited,
    this.netSalaryEditedAt,
    this.payslipFileName,
    this.payslipFileUrl,
    this.payslipGeneratedAt,
    required this.payslipDeliveryStatus,
    this.payslipSentAt,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
  });

  factory PayrollEntry.fromJson(Map<String, dynamic> json) {
    return PayrollEntry(
      id: json['id'],
      payrollRunId: json['payrollRunId'],
      userId: json['userId'],
      workingDays: json['workingDays'] ?? 0,
      payableDays: json['payableDays'] ?? 0,
      presentDays: json['presentDays'] ?? 0,
      absentDays: json['absentDays'] ?? 0,
      leaveDays: json['leaveDays'] ?? 0,
      holidayDays: json['holidayDays'] ?? 0,
      baseSalary: json['baseSalary'] ?? '0',
      deductionAmount: json['deductionAmount'] ?? '0',
      incentiveAmount: json['incentiveAmount'] ?? '0',
      incentiveSnapshot: json['incentiveSnapshot'],
      netSalary: json['netSalary'] ?? '0',
      netSalaryEdited: json['netSalaryEdited'] ?? false,
      netSalaryEditedAt: json['netSalaryEditedAt'] != null
          ? DateTime.parse(json['netSalaryEditedAt'])
          : null,
      payslipFileName: json['payslipFileName'],
      payslipFileUrl: json['payslipFileUrl'],
      payslipGeneratedAt: json['payslipGeneratedAt'] != null
          ? DateTime.parse(json['payslipGeneratedAt'])
          : null,
      payslipDeliveryStatus: json['payslipDeliveryStatus'] ?? 'PENDING',
      payslipSentAt: json['payslipSentAt'] != null
          ? DateTime.parse(json['payslipSentAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      user: UserInfo.fromJson(json['user']),
    );
  }
}

class UserInfo {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? department;
  final String? image;
  final EmployeeProfile? employeeProfile;

  UserInfo({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.department,
    this.image,
    this.employeeProfile,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: json['role'],
      department: json['department'],
      image: json['image'],
      employeeProfile: json['employeeProfile'] != null
          ? EmployeeProfile.fromJson(json['employeeProfile'])
          : null,
    );
  }
}

class EmployeeProfile {
  final String id;
  final String designation;
  final String baseSalary;
  final DateTime joiningDate;
  final bool payrollEnabled;
  final ReportingManager? reportingManager;

  EmployeeProfile({
    required this.id,
    required this.designation,
    required this.baseSalary,
    required this.joiningDate,
    required this.payrollEnabled,
    this.reportingManager,
  });

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    return EmployeeProfile(
      id: json['id'],
      designation: json['designation'] ?? 'N/A',
      baseSalary: json['baseSalary'] ?? '0',
      joiningDate: DateTime.parse(json['joiningDate']),
      payrollEnabled: json['payrollEnabled'] ?? false,
      reportingManager: json['reportingManager'] != null
          ? ReportingManager.fromJson(json['reportingManager'])
          : null,
    );
  }
}

class ReportingManager {
  final String name;

  ReportingManager({required this.name});

  factory ReportingManager.fromJson(Map<String, dynamic> json) {
    return ReportingManager(name: json['name'] ?? 'N/A');
  }
}
