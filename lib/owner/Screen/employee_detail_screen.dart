import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/models/holiday_model.dart';
import 'package:koniwalamatrimonial/models/manager_dashboard.dart';
import 'package:koniwalamatrimonial/owner/models/hr_employee_detail.dart';
import 'package:koniwalamatrimonial/owner/models/hr_employee_item.dart';
import 'package:koniwalamatrimonial/owner/models/lead_follow_up_item.dart';
import 'package:koniwalamatrimonial/owner/models/lead_registry_item.dart';
import 'package:koniwalamatrimonial/owner/providers/hr_employees_provider.dart';
import 'package:koniwalamatrimonial/owner/providers/lead_follow_ups_provider.dart';
import 'package:koniwalamatrimonial/owner/providers/leads_provider.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/providers/holiday_provider.dart';
import 'package:provider/provider.dart';

class EmployeeDetailScreen extends StatefulWidget {
  const EmployeeDetailScreen({
    super.key,
    required this.teamMember,
    this.employee,
  });

  final ManagerTeamStatusItem teamMember;
  final HrEmployeeItem? employee;

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  static const Color _pageBackground = Color(0xFFFFF8F4);
  static const Color _borderColor = Color(0xFFF0DFD8);
  static const Color _bodyText = Color(0xFF2B2929);

  late DateTime _visibleMonth;
  bool _showHistory = false;
  String? _requestedAttendanceAccessToken;
  String? _requestedAttendanceEmployeeId;
  int? _requestedAttendanceMonth;
  int? _requestedAttendanceYear;
  String? _requestedPayrollAccessToken;
  String? _requestedPayrollEmployeeId;
  String? _requestedHolidayAccessToken;
  int? _requestedHolidayYear;
  String? _requestedLeadsAccessToken;
  String? _requestedFollowUpsAccessToken;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  String get _employeeId {
    final employeeId = widget.employee?.id.trim() ?? '';
    if (employeeId.isNotEmpty) {
      return employeeId;
    }
    return widget.teamMember.id.trim();
  }

  void _requestDetailDataIfNeeded(String? accessToken) {
    final employeeId = _employeeId;
    if (accessToken == null || accessToken.isEmpty || employeeId.isEmpty) {
      return;
    }

    final shouldFetchAttendance =
        _requestedAttendanceAccessToken != accessToken ||
        _requestedAttendanceEmployeeId != employeeId ||
        _requestedAttendanceMonth != _visibleMonth.month ||
        _requestedAttendanceYear != _visibleMonth.year;
    final shouldFetchPayroll =
        _requestedPayrollAccessToken != accessToken ||
        _requestedPayrollEmployeeId != employeeId;
    final shouldFetchHolidays =
        _requestedHolidayAccessToken != accessToken ||
        _requestedHolidayYear != _visibleMonth.year;
    final shouldFetchLeads = _requestedLeadsAccessToken != accessToken;
    final shouldFetchFollowUps = _requestedFollowUpsAccessToken != accessToken;

    if (!shouldFetchAttendance &&
        !shouldFetchPayroll &&
        !shouldFetchHolidays &&
        !shouldFetchLeads &&
        !shouldFetchFollowUps) {
      return;
    }

    if (shouldFetchAttendance) {
      _requestedAttendanceAccessToken = accessToken;
      _requestedAttendanceEmployeeId = employeeId;
      _requestedAttendanceMonth = _visibleMonth.month;
      _requestedAttendanceYear = _visibleMonth.year;
    }

    if (shouldFetchPayroll) {
      _requestedPayrollAccessToken = accessToken;
      _requestedPayrollEmployeeId = employeeId;
    }

    if (shouldFetchHolidays) {
      _requestedHolidayAccessToken = accessToken;
      _requestedHolidayYear = _visibleMonth.year;
    }
    if (shouldFetchLeads) {
      _requestedLeadsAccessToken = accessToken;
    }
    if (shouldFetchFollowUps) {
      _requestedFollowUpsAccessToken = accessToken;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (shouldFetchAttendance) {
        context.read<HrEmployeesProvider>().fetchEmployeeAttendance(
          accessToken: accessToken,
          employeeId: employeeId,
          month: _visibleMonth.month,
          year: _visibleMonth.year,
        );
      }
      if (shouldFetchPayroll) {
        context.read<HrEmployeesProvider>().fetchPayrollHistory(
          accessToken: accessToken,
          employeeId: employeeId,
        );
      }
      if (shouldFetchHolidays) {
        context.read<HolidayProvider>().fetchHolidays(
          _visibleMonth.year,
          accessToken,
        );
      }
      if (shouldFetchLeads) {
        context.read<LeadsProvider>().fetchLeads(accessToken);
      }
      if (shouldFetchFollowUps) {
        context.read<LeadFollowUpsProvider>().fetchFollowUps(accessToken);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accessToken = context.watch<AuthProvider>().userModel?.accessToken;
    _requestDetailDataIfNeeded(accessToken);

    final employeesProvider = context.watch<HrEmployeesProvider>();
    final holidayProvider = context.watch<HolidayProvider>();
    final leadsProvider = context.watch<LeadsProvider>();
    final followUpsProvider = context.watch<LeadFollowUpsProvider>();
    final attendance = _employeeId.isEmpty
        ? null
        : employeesProvider.employeeAttendance(
            employeeId: _employeeId,
            month: _visibleMonth.month,
            year: _visibleMonth.year,
          );
    final payrollHistory = _employeeId.isEmpty
        ? const <HrPayrollHistoryItem>[]
        : employeesProvider.payrollHistory(_employeeId);
    final days = attendance?.days ?? const <HrEmployeeAttendanceDay>[];
    final counts = attendance == null
        ? _AttendanceCounts.fromToday(widget.teamMember.todayAttendanceStatus)
        : _AttendanceCounts.fromAttendance(attendance);
    final holidays = holidayProvider.holidays
        .where((holiday) => holiday.date.toLocal().year == _visibleMonth.year)
        .toList();
    final isAttendanceLoading =
        employeesProvider.isEmployeeAttendanceLoading && attendance == null;

    final roleText = _firstNonEmpty([
      attendance?.summary.designation,
      widget.employee?.designation,
      widget.teamMember.role,
    ]);
    final reportingManager = _firstNonEmpty([
      attendance?.summary.reportingManagerName,
      widget.employee?.reportingManagerName,
    ]);
    final email = _firstNonEmpty([
      attendance?.summary.email,
      widget.employee?.email,
    ]);
    final name = _firstNonEmpty([
      attendance?.summary.name,
      widget.teamMember.name,
    ]);

    final pageData = _EmployeeDetailData(
      name: name,
      role: roleText,
      reportingManager: reportingManager,
      email: email,
    );
    final activitySummary = _buildActivitySummary(
      leads: leadsProvider.leads,
      followUpLeads: followUpsProvider.leads,
      employeeName: name,
      employeeEmail: email,
    );
    final isActivityLoading =
        (leadsProvider.isLoading && leadsProvider.leads.isEmpty) ||
        (followUpsProvider.isLoading && followUpsProvider.leads.isEmpty);

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _pageBackground,
        surfaceTintColor: _pageBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          'Employee',
          style: GoogleFonts.inter(
            color: const Color(0xFF1F1D1D),
            fontSize: 22.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        // actions: [
        //   IconButton(
        //     onPressed: () {},
        //     icon: const Icon(Icons.more_vert, color: Colors.black),
        //   ),
        // ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
          children: [
            _buildProfileHeader(pageData),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    label: 'DEPARTMENT',
                    value: _employeeText(
                      widget.employee?.department,
                      fallback: '-',
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _InfoTile(
                    label: 'JOINED ON',
                    value: _employeeText(
                      widget.employee?.joiningDateText,
                      fallback: '-',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    label: 'REPORTING MANAGER',
                    value: _employeeText(reportingManager, fallback: '-'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _InfoTile(
                    label: 'BASE SALARY',
                    value: _formatSalary(widget.employee?.baseSalary),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            _EmployeeActivitySummaryCard(
              summary: activitySummary,
              isLoading: isActivityLoading,
              leadsError: leadsProvider.error,
              followUpsError: followUpsProvider.error,
            ),
            SizedBox(height: 14.h),
            _buildSegmentedTabs(),
            SizedBox(height: 14.h),
            if (_showHistory)
              _buildHistory(
                payrollHistory: payrollHistory,
                isLoading: employeesProvider.isPayrollHistoryLoading,
                error: employeesProvider.payrollHistoryError,
                email: email,
              )
            else ...[
              _buildAttendanceSummary(counts),
              SizedBox(height: 18.h),
              if (isAttendanceLoading)
                const Center(child: CircularProgressIndicator())
              else
                _buildCalendarCard(days, holidays: holidays),
              if (employeesProvider.employeeAttendanceError != null &&
                  attendance == null) ...[
                SizedBox(height: 10.h),
                Text(
                  employeesProvider.employeeAttendanceError!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.danger,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(_EmployeeDetailData data) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 24.h),
      decoration: _cardDecoration(radius: 10),
      child: Column(
        children: [
          _buildAvatar(radius: 30.r),
          SizedBox(height: 24.h),
          Text(
            _formatRole(data.role),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _bodyText,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            data.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF202020),
              fontSize: 30.sp,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Attendance and employment archival details for this employee are consolidated here for HR review.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF3F3C3C),
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Attendance',
              selected: !_showHistory,
              onTap: () => setState(() => _showHistory = false),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _SegmentButton(
              label: 'History',
              selected: _showHistory,
              onTap: () => setState(() => _showHistory = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary(_AttendanceCounts counts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance',
          style: GoogleFonts.inter(
            color: const Color(0xFF202020),
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          DateFormat('MMMM yyyy').format(_visibleMonth).toUpperCase(),
          style: GoogleFonts.inter(
            color: const Color(0xFF6D5E5A),
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 18.h),
        Row(
          children: [
            Expanded(
              child: _AttendanceMetric(
                value: counts.present,
                label: 'PRESENT',
                color: const Color(0xFF16A15F),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _AttendanceMetric(
                value: counts.absent,
                label: 'ABSENT',
                color: const Color(0xFFC91C23),
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
              child: _AttendanceMetric(
                value: counts.leave,
                label: 'LEAVE',
                color: const Color(0xFFFF8B2C),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _AttendanceMetric(
                value: counts.halfDay,
                label: 'HALF DAY',
                color: const Color(0xFF2B76BC),
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        _LateDaysMetric(value: counts.late),
      ],
    );
  }

  Widget _buildCalendarCard(
    List<HrEmployeeAttendanceDay> days, {
    required List<HolidayModel> holidays,
  }) {
    final statusByDay = <int, String>{};
    for (final holiday in holidays) {
      final date = holiday.date.toLocal();
      if (date.year == _visibleMonth.year &&
          date.month == _visibleMonth.month) {
        statusByDay[date.day] = holiday.isHalfDay ? 'half' : 'holiday';
      }
    }

    for (final day in days) {
      final date = day.date.toLocal();
      if (date.year == _visibleMonth.year &&
          date.month == _visibleMonth.month) {
        statusByDay[date.day] = day.normalizedStatus;
      }
    }

    final cells = _buildCalendarCells(_visibleMonth);

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 18.h),
      decoration: _cardDecoration(radius: 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left),
                color: const Color(0xFF55505A),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(_visibleMonth),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF202020),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
                color: const Color(0xFF55505A),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: const [
              'S',
              'M',
              'T',
              'W',
              'T',
              'F',
              'S',
            ].map((label) => Expanded(child: _WeekdayLabel(label))).toList(),
          ),
          SizedBox(height: 8.h),
          GridView.builder(
            itemCount: cells.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final cell = cells[index];
              final status = cell.inCurrentMonth
                  ? statusByDay[cell.date.day]
                  : null;
              return _CalendarDayCell(cell: cell, status: status);
            },
          ),
          SizedBox(height: 10.h),
          const Divider(color: Color(0xFFF4EBE8), height: 1),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 8.h,
            alignment: WrapAlignment.center,
            children: const [
              _LegendItem(label: 'Present', color: Color(0xFF16A15F)),
              _LegendItem(label: 'Absent', color: Color(0xFFC91C23)),
              _LegendItem(label: 'Leave', color: Color(0xFFFF8B2C)),
              _LegendItem(label: 'Half Day', color: Color(0xFF2B76BC)),
              _LegendItem(label: 'Holiday', color: Color(0xFF8E6CEF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistory({
    required List<HrPayrollHistoryItem> payrollHistory,
    required bool isLoading,
    required String? error,
    required String email,
  }) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs. ',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: GoogleFonts.inter(
            color: const Color(0xFF202020),
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 14.h),
        _HistoryRow(
          label: 'Current Status',
          value: _capitalize(widget.teamMember.status),
        ),
        _HistoryRow(
          label: 'Today Attendance',
          value: widget.teamMember.todayAttendanceStatus,
        ),
        if (email.isNotEmpty) _HistoryRow(label: 'Email', value: email),
        _HistoryRow(
          label: 'Leads Handled',
          value: '${widget.teamMember.leadsHandled}',
        ),
        _HistoryRow(
          label: 'Tasks Completed',
          value: '${widget.teamMember.tasksCompleted}',
        ),
        _HistoryRow(
          label: 'Profiles Handled',
          value: '${widget.teamMember.profilesHandled}',
        ),
        SizedBox(height: 10.h),
        Text(
          'Payroll History',
          style: GoogleFonts.inter(
            color: const Color(0xFF202020),
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 12.h),
        if (isLoading && payrollHistory.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (error != null && payrollHistory.isEmpty)
          _HistoryMessage(message: error)
        else if (payrollHistory.isEmpty)
          const _HistoryMessage(message: 'No payroll history available.')
        else
          ...payrollHistory.map(
            (item) =>
                _PayrollHistoryCard(item: item, currencyFormat: currencyFormat),
          ),
      ],
    );
  }

  _EmployeeActivitySummary _buildActivitySummary({
    required List<LeadRegistryItem> leads,
    required List<LeadFollowUpItem> followUpLeads,
    required String employeeName,
    required String employeeEmail,
  }) {
    final assignedLeads = leads
        .where(
          (lead) => _matchesEmployeeAssignment(
            assignedId: lead.assignedToId,
            assignedName: lead.assignedTo,
            employeeName: employeeName,
            employeeEmail: employeeEmail,
          ),
        )
        .toList(growable: false);

    final todayLeads = assignedLeads
        .where((lead) => _isToday(_parseRegistryDate(lead.createdOn)))
        .length;
    final conversions = assignedLeads
        .where((lead) => _statusKey(lead.stage) == 'CONVERTED')
        .length;
    final totalAssignedLeads = assignedLeads.isNotEmpty
        ? assignedLeads.length
        : _firstPositive([
            widget.employee?.assignedLeads,
            widget.teamMember.leadsHandled,
          ]);
    final totalConversions = conversions > 0
        ? conversions
        : _firstPositive([widget.employee?.closedLeads]);

    var todayCalls = 0;
    var openFollowUps = 0;
    var dueTodayFollowUps = 0;
    var completedFollowUpsToday = 0;

    for (final lead in followUpLeads) {
      final leadMatches = _matchesEmployeeName(
        lead.assignedToName,
        employeeName,
        employeeEmail,
      );

      for (final task in lead.tasks) {
        final taskMatches =
            leadMatches ||
            _matchesEmployeeName(
              task.assignedToName,
              employeeName,
              employeeEmail,
            );
        if (!taskMatches) {
          continue;
        }

        if (_isCallTask(task) && task.isDone && _isToday(task.createdAt)) {
          todayCalls++;
        }

        if (_isFollowUpTask(task)) {
          if (task.isOpen) {
            openFollowUps++;
            if (_isToday(task.dueAt)) {
              dueTodayFollowUps++;
            }
          } else if (task.isDone && _isToday(task.createdAt)) {
            completedFollowUpsToday++;
          }
        }
      }
    }

    if (todayCalls == 0 && followUpLeads.isEmpty) {
      todayCalls = widget.teamMember.tasksCompleted;
    }

    return _EmployeeActivitySummary(
      todayLeads: todayLeads,
      todayCalls: todayCalls,
      totalConversions: totalConversions,
      openFollowUps: openFollowUps,
      dueTodayFollowUps: dueTodayFollowUps,
      completedFollowUpsToday: completedFollowUpsToday,
      totalAssignedLeads: totalAssignedLeads,
      profilesHandled: widget.teamMember.profilesHandled,
    );
  }

  bool _matchesEmployeeAssignment({
    required String assignedId,
    required String assignedName,
    required String employeeName,
    required String employeeEmail,
  }) {
    final employeeId = _employeeId.trim();
    if (employeeId.isNotEmpty && assignedId.trim() == employeeId) {
      return true;
    }

    return _matchesEmployeeName(assignedName, employeeName, employeeEmail);
  }

  bool _matchesEmployeeName(
    String assignedName,
    String employeeName,
    String employeeEmail,
  ) {
    final assigned = _normalizeMatchText(assignedName);
    if (assigned.isEmpty || assigned == '-') {
      return false;
    }

    final name = _normalizeMatchText(employeeName);
    final email = _normalizeMatchText(employeeEmail);
    return assigned == name ||
        (email.isNotEmpty && assigned == email) ||
        (name.isNotEmpty && assigned.contains(name)) ||
        (name.isNotEmpty && name.contains(assigned));
  }

  bool _isCallTask(LeadFollowUpTask task) {
    final type = _statusKey(task.type);
    final title = task.title.toLowerCase();
    return type == 'CALL' || title.contains('call');
  }

  bool _isFollowUpTask(LeadFollowUpTask task) {
    final type = _statusKey(task.type);
    final workflow = _statusKey(task.workflowStatus);
    final title = task.title.toLowerCase();
    return type == 'CALL' ||
        type == 'FOLLOW_UP' ||
        workflow.contains('FOLLOW_UP') ||
        title.contains('follow');
  }

  bool _isToday(DateTime? value) {
    if (value == null) {
      return false;
    }

    final local = value.toLocal();
    final now = DateTime.now();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  DateTime? _parseRegistryDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '-') {
      return null;
    }

    final parsedIso = DateTime.tryParse(trimmed);
    if (parsedIso != null) {
      return parsedIso.toLocal();
    }

    try {
      return DateFormat('d MMM yyyy').parseLoose(trimmed).toLocal();
    } catch (_) {
      return null;
    }
  }

  int _firstPositive(List<int?> values) {
    for (final value in values) {
      if (value != null && value > 0) {
        return value;
      }
    }
    return 0;
  }

  String _statusKey(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '_');
  }

  String _normalizeMatchText(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Widget _buildAvatar({required double radius}) {
    final image = _firstNonEmpty([
      widget.teamMember.image,
      widget.employee?.image,
    ]);

    if (image.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          image,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _InitialsAvatar(
            initials: _initials(widget.teamMember.name),
            radius: radius,
          ),
        ),
      );
    }

    return _InitialsAvatar(
      initials: _initials(widget.teamMember.name),
      radius: radius,
    );
  }

  List<_CalendarCell> _buildCalendarCells(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final previousMonthDays = DateTime(month.year, month.month, 0).day;
    final leadingDays = firstDay.weekday % 7;
    final totalCells = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;

    return List.generate(totalCells, (index) {
      final monthDay = index - leadingDays + 1;
      if (monthDay < 1) {
        return _CalendarCell(
          date: DateTime(
            month.year,
            month.month - 1,
            previousMonthDays + monthDay,
          ),
          inCurrentMonth: false,
        );
      }
      if (monthDay > daysInMonth) {
        return _CalendarCell(
          date: DateTime(month.year, month.month + 1, monthDay - daysInMonth),
          inCurrentMonth: false,
        );
      }
      return _CalendarCell(
        date: DateTime(month.year, month.month, monthDay),
        inCurrentMonth: true,
      );
    });
  }

  void _previousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
  }

  BoxDecoration _cardDecoration({required double radius}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius.r),
      border: Border.all(color: _borderColor),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFB98770).withValues(alpha: 0.08),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  String _formatSalary(String? salary) {
    final value = _employeeText(salary, fallback: '-');
    if (value == '-') {
      return value;
    }

    final numeric = value.replaceAll(RegExp(r'[^0-9.]'), '');
    final amount = double.tryParse(numeric);
    if (amount == null) {
      return value;
    }

    return 'Rs. ${NumberFormat.decimalPattern('en_IN').format(amount)}';
  }

  static String _employeeText(String? value, {required String fallback}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty || text == '-') {
      return fallback;
    }
    return text;
  }

  static String _formatRole(String role) {
    final clean = role.replaceAll('_', ' ').trim();
    if (clean.isEmpty) return 'EMPLOYEE';
    return clean.toUpperCase();
  }

  static String _capitalize(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return '-';
    return clean[0].toUpperCase() + clean.substring(1).toLowerCase();
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'E';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _EmployeeDetailScreenState._borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB98770).withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF2E2C2D),
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeActivitySummaryCard extends StatelessWidget {
  const _EmployeeActivitySummaryCard({
    required this.summary,
    required this.isLoading,
    required this.leadsError,
    required this.followUpsError,
  });

  final _EmployeeActivitySummary summary;
  final bool isLoading;
  final String? leadsError;
  final String? followUpsError;

  @override
  Widget build(BuildContext context) {
    final hasError = leadsError != null || followUpsError != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _EmployeeDetailScreenState._borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB98770).withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "TODAY'S WORK",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF202020),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 16.r,
                  height: 16.r,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.insights_rounded,
                  color: AppColors.primary,
                  size: 18.sp,
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _ActivityMetricCard(
                  value: summary.todayLeads,
                  label: 'TODAY LEADS',
                  color: AppColors.primary,
                  icon: Icons.person_add_alt_1_outlined,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _ActivityMetricCard(
                  value: summary.todayCalls,
                  label: 'TODAY CALLS',
                  color: const Color(0xFF338AF3),
                  icon: Icons.call_outlined,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _ActivityMetricCard(
                  value: summary.totalConversions,
                  label: 'CONVERSIONS',
                  color: const Color(0xFF16A15F),
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _ActivityMetricCard(
                  value: summary.openFollowUps,
                  label: 'FOLLOW-UPS',
                  color: const Color(0xFFFF8B2C),
                  icon: Icons.event_available_outlined,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _ActivityMiniPill(
                label: 'Assigned leads',
                value: summary.totalAssignedLeads,
              ),
              _ActivityMiniPill(
                label: 'Due today',
                value: summary.dueTodayFollowUps,
              ),
              _ActivityMiniPill(
                label: 'Done follow-ups',
                value: summary.completedFollowUpsToday,
              ),
              _ActivityMiniPill(
                label: 'Profiles',
                value: summary.profilesHandled,
              ),
            ],
          ),
          if (hasError) ...[
            SizedBox(height: 10.h),
            Text(
              'Some activity data could not be loaded.',
              style: GoogleFonts.inter(
                color: AppColors.danger,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityMetricCard extends StatelessWidget {
  const _ActivityMetricCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  final int value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9.r),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 30.r,
            height: 30.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16.sp),
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF202020),
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityMiniPill extends StatelessWidget {
  const _ActivityMiniPill({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F4),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: const Color(0xFFF0DFD8)),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.inter(
          color: const Color(0xFF5E5559),
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmployeeActivitySummary {
  const _EmployeeActivitySummary({
    required this.todayLeads,
    required this.todayCalls,
    required this.totalConversions,
    required this.openFollowUps,
    required this.dueTodayFollowUps,
    required this.completedFollowUpsToday,
    required this.totalAssignedLeads,
    required this.profilesHandled,
  });

  final int todayLeads;
  final int todayCalls;
  final int totalConversions;
  final int openFollowUps;
  final int dueTodayFollowUps;
  final int completedFollowUpsToday;
  final int totalAssignedLeads;
  final int profilesHandled;
}

class _EmployeeDetailData {
  const _EmployeeDetailData({
    required this.name,
    required this.role,
    required this.reportingManager,
    required this.email,
  });

  final String name;
  final String role;
  final String reportingManager;
  final String email;
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38.h,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: selected ? AppColors.primary : Colors.black,
          side: BorderSide(
            color: selected ? AppColors.primary : Colors.transparent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7.r),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _AttendanceMetric extends StatelessWidget {
  const _AttendanceMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _EmployeeDetailScreenState._borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB98770).withValues(alpha: 0.09),
            blurRadius: 13,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: GoogleFonts.inter(
              color: color,
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF151515),
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LateDaysMetric extends StatelessWidget {
  const _LateDaysMetric({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _EmployeeDetailScreenState._borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB98770).withValues(alpha: 0.09),
            blurRadius: 13,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              color: const Color(0xFF151515),
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
            children: [
              TextSpan(
                text: value.toString().padLeft(2, '0'),
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const TextSpan(text: '  LATE DAYS'),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        color: const Color(0xFF1F1F1F),
        fontSize: 12.sp,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({required this.cell, required this.status});

  final _CalendarCell cell;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final isHalfDay = _normalizedStatus(status) == 'half';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36.w,
          height: 30.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isHalfDay ? const Color(0xFFFFF4F8) : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            '${cell.date.day}',
            style: GoogleFonts.inter(
              color: cell.inCurrentMonth
                  ? (isHalfDay
                        ? const Color(0xFF2B76BC)
                        : const Color(0xFF313132))
                  : const Color(0xFF8E8A8E),
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(
            color: color ?? Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  static Color? _statusColor(String? status) {
    switch (_normalizedStatus(status)) {
      case 'present':
        return const Color(0xFF16A15F);
      case 'absent':
        return const Color(0xFFC91C23);
      case 'leave':
        return const Color(0xFFFF8B2C);
      case 'half':
        return const Color(0xFF2B76BC);
      case 'holiday':
        return const Color(0xFF8E6CEF);
      default:
        return null;
    }
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF5E5559),
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _EmployeeDetailScreenState._borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFF5E5559),
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _EmployeeDetailScreenState._borderColor),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: const Color(0xFF5E5559),
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PayrollHistoryCard extends StatelessWidget {
  const _PayrollHistoryCard({required this.item, required this.currencyFormat});

  final HrPayrollHistoryItem item;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final period = item.month == 0 || item.year == 0
        ? 'Payroll period'
        : DateFormat('MMMM yyyy').format(DateTime(item.year, item.month));
    final generatedAt = item.payslipGeneratedAt == null
        ? null
        : DateFormat('dd MMM yyyy').format(item.payslipGeneratedAt!.toLocal());

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _EmployeeDetailScreenState._borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  period,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF202020),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              _SmallPill(label: item.status),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            currencyFormat.format(item.netSalary),
            style: GoogleFonts.inter(
              color: const Color(0xFF16A15F),
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _SmallPill(label: 'Payable ${item.payableDays}d'),
              _SmallPill(label: 'Present ${item.presentDays}d'),
              _SmallPill(label: 'Absent ${item.absentDays}d'),
              _SmallPill(label: 'Leave ${item.leaveDays}d'),
              _SmallPill(label: 'Holiday ${item.holidayDays}d'),
              _SmallPill(label: item.payslipDeliveryStatus),
              if (generatedAt != null) _SmallPill(label: generatedAt),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF0DFD8)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: const Color(0xFF5E5559),
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials, required this.radius});

  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFF4ECE8),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: GoogleFonts.inter(
          color: AppColors.primary,
          fontSize: 18.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CalendarCell {
  const _CalendarCell({required this.date, required this.inCurrentMonth});

  final DateTime date;
  final bool inCurrentMonth;
}

class _AttendanceCounts {
  const _AttendanceCounts({
    required this.present,
    required this.absent,
    required this.leave,
    required this.halfDay,
    required this.late,
  });

  final int present;
  final int absent;
  final int leave;
  final int halfDay;
  final int late;

  factory _AttendanceCounts.fromAttendance(HrEmployeeAttendanceResult result) {
    return _AttendanceCounts(
      present: result.summary.presentDays,
      absent: result.summary.absentDays,
      leave: result.summary.leaveDays,
      halfDay: result.days
          .where((day) => day.normalizedStatus == 'half')
          .length,
      late: result.summary.lateDays,
    );
  }

  factory _AttendanceCounts.fromToday(String todayStatus) {
    final normalized = _normalizedStatus(todayStatus);
    return _AttendanceCounts(
      present: normalized == 'present' ? 1 : 0,
      absent: normalized == 'absent' ? 1 : 0,
      leave: normalized == 'leave' ? 1 : 0,
      halfDay: normalized == 'half' ? 1 : 0,
      late: todayStatus.toLowerCase().contains('late') ? 1 : 0,
    );
  }
}

String _normalizedStatus(String? status) {
  final text = status?.trim().toLowerCase() ?? '';
  if (text.contains('half')) return 'half';
  if (text.contains('holiday')) return 'holiday';
  if (text.contains('leave')) return 'leave';
  if (text.contains('absent')) return 'absent';
  if (text.contains('present') || text.contains('late')) return 'present';
  return '';
}
