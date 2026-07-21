import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/models/holiday_model.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/providers/holiday_provider.dart';
import 'package:provider/provider.dart';

class RelationshipManagerAccountScreen extends StatefulWidget {
  const RelationshipManagerAccountScreen({
    super.key,
    this.showScaffold = true,
    this.onMenuPressed,
    this.onBackPressed,
    this.employeeId,
  });

  final bool showScaffold;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onBackPressed;
  final String? employeeId;

  @override
  State<RelationshipManagerAccountScreen> createState() =>
      _RelationshipManagerAccountScreenState();
}

class _RelationshipManagerAccountScreenState
    extends State<RelationshipManagerAccountScreen> {
  final Dio _dio = Dio();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: 'Rs. ',
    locale: 'en_IN',
    decimalDigits: 0,
  );
  bool _showAttendance = true;
  bool _hasRequestedHolidays = false;
  String? _requestedHolidayToken;
  bool _isPayrollHistoryLoading = false;
  String? _payrollHistoryError;
  String? _requestedPayrollHistoryToken;
  String? _requestedPayrollHistoryEmployeeId;
  List<_PayrollHistoryItem> _payrollHistory = const [];
  bool _isAttendanceLoading = false;
  String? _attendanceError;
  String? _requestedAttendanceToken;
  String? _requestedAttendanceEmployeeId;
  _EmployeeAttendanceSummary _attendanceSummary =
      _EmployeeAttendanceSummary.empty();
  List<_EmployeeAttendanceDay> _attendanceDays = const [];

  int get _attendanceMonth => DateTime.now().month;
  int get _attendanceYear => DateTime.now().year;
  int get _holidayYear => _attendanceYear;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _requestHolidaysIfNeeded();
    _requestPayrollHistoryIfNeeded();
    _requestAttendanceIfNeeded();
  }

  void _requestHolidaysIfNeeded() {
    final accessToken = context.watch<AuthProvider>().userModel?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    if (_hasRequestedHolidays && _requestedHolidayToken == accessToken) {
      return;
    }

    _hasRequestedHolidays = true;
    _requestedHolidayToken = accessToken;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<HolidayProvider>().fetchHolidays(_holidayYear, accessToken);
    });
  }

  void _refreshHolidays() {
    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    _requestedHolidayToken = accessToken;
    context.read<HolidayProvider>().fetchHolidays(_holidayYear, accessToken);
  }

  String? _currentEmployeeId() {
    final explicitEmployeeId = widget.employeeId?.trim();
    if (explicitEmployeeId != null && explicitEmployeeId.isNotEmpty) {
      return explicitEmployeeId;
    }

    return context.read<AuthProvider>().userModel?.user?.id.trim();
  }

  String _loggedInUserName() {
    final name = context.watch<AuthProvider>().userModel?.user?.name.trim();
    return name == null || name.isEmpty ? 'Relationship Manager' : name;
  }

  String _loggedInRoleLabel() {
    final user = context.watch<AuthProvider>().userModel?.user;
    final department = user?.department?.trim();
    if (department != null && department.isNotEmpty) {
      return department;
    }

    final role = user?.role.trim();
    if (role == null || role.isEmpty) {
      return 'Relationship Manager';
    }

    return role
        .split('_')
        .where((part) => part.trim().isNotEmpty)
        .map((part) {
          final lower = part.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  void _requestPayrollHistoryIfNeeded() {
    final authProvider = context.watch<AuthProvider>();
    final accessToken = authProvider.userModel?.accessToken?.trim();
    final employeeId = widget.employeeId?.trim().isNotEmpty == true
        ? widget.employeeId!.trim()
        : authProvider.userModel?.user?.id.trim();

    if (accessToken == null ||
        accessToken.isEmpty ||
        employeeId == null ||
        employeeId.isEmpty) {
      return;
    }

    if (_requestedPayrollHistoryToken == accessToken &&
        _requestedPayrollHistoryEmployeeId == employeeId) {
      return;
    }

    _requestedPayrollHistoryToken = accessToken;
    _requestedPayrollHistoryEmployeeId = employeeId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _fetchPayrollHistory(accessToken: accessToken, employeeId: employeeId);
    });
  }

  void _requestAttendanceIfNeeded() {
    final authProvider = context.watch<AuthProvider>();
    final accessToken = authProvider.userModel?.accessToken?.trim();
    final employeeId = widget.employeeId?.trim().isNotEmpty == true
        ? widget.employeeId!.trim()
        : authProvider.userModel?.user?.id.trim();

    if (accessToken == null ||
        accessToken.isEmpty ||
        employeeId == null ||
        employeeId.isEmpty) {
      return;
    }

    if (_requestedAttendanceToken == accessToken &&
        _requestedAttendanceEmployeeId == employeeId) {
      return;
    }

    _requestedAttendanceToken = accessToken;
    _requestedAttendanceEmployeeId = employeeId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _fetchAttendance(accessToken: accessToken, employeeId: employeeId);
    });
  }

  Future<void> _refreshAccountData() async {
    _refreshHolidays();

    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    final employeeId = _currentEmployeeId();
    if (accessToken == null ||
        accessToken.trim().isEmpty ||
        employeeId == null ||
        employeeId.isEmpty) {
      return;
    }

    await _fetchPayrollHistory(
      accessToken: accessToken.trim(),
      employeeId: employeeId,
    );
    await _fetchAttendance(
      accessToken: accessToken.trim(),
      employeeId: employeeId,
    );
  }

  Future<void> _fetchPayrollHistory({
    required String accessToken,
    required String employeeId,
  }) async {
    if (_isPayrollHistoryLoading) {
      return;
    }

    setState(() {
      _isPayrollHistoryLoading = true;
      _payrollHistoryError = null;
    });

    final url =
        '${ApiConstants.baseUrl}${ApiConstants.payrollEmployeeHistory(employeeId)}';

    try {
      final response = await _dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        final items = _PayrollHistoryItem.fromResponse(response.data)
          ..sort((left, right) => right.periodDate.compareTo(left.periodDate));
        setState(() {
          _payrollHistory = items;
          _isPayrollHistoryLoading = false;
        });
      } else {
        setState(() {
          _payrollHistoryError = 'Unable to load payroll history.';
          _isPayrollHistoryLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _payrollHistoryError = 'Unable to load payroll history.';
        _isPayrollHistoryLoading = false;
      });
    }
  }

  Future<void> _fetchAttendance({
    required String accessToken,
    required String employeeId,
  }) async {
    if (_isAttendanceLoading) {
      return;
    }

    setState(() {
      _isAttendanceLoading = true;
      _attendanceError = null;
    });

    final url =
        '${ApiConstants.baseUrl}${ApiConstants.hrEmployeeAttendance(employeeId: employeeId, month: _attendanceMonth, year: _attendanceYear)}';

    try {
      final response = await _dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        final parsed = _EmployeeAttendanceResult.fromResponse(response.data);
        setState(() {
          _attendanceSummary = parsed.summary;
          _attendanceDays = parsed.days;
          _isAttendanceLoading = false;
        });
      } else {
        setState(() {
          _attendanceError = 'Unable to load attendance.';
          _isAttendanceLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _attendanceError = 'Unable to load attendance.';
        _isAttendanceLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
              child: Column(
                children: [
                  _buildProfileCard(),
                  SizedBox(height: 18.h),
                  _buildInfoGrid(),
                  SizedBox(height: 18.h),
                  _buildIncentiveCard(),
                  SizedBox(height: 18.h),
                  _buildHolidaySection(),
                  SizedBox(height: 18.h),
                  _buildSegmentControl(),
                  SizedBox(height: 18.h),
                  _showAttendance
                      ? _buildAttendanceSection()
                      : _buildHistorySection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (!widget.showScaffold) {
      return ColoredBox(color: AppColors.rmSoftPink, child: content);
    }

    return Scaffold(backgroundColor: AppColors.rmSoftPink, body: content);
  }

  Widget _buildHeader(BuildContext context) {
    final backLabel = widget.onBackPressed == null
        ? 'Back To Employees'
        : 'Back To Dashboard';

    return Container(
      height: 54,
      color: AppColors.lightGreyBg,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          if (widget.onMenuPressed != null)
            IconButton(
              tooltip: 'Menu',
              onPressed: widget.onMenuPressed,
              icon: Icon(Icons.menu, color: AppColors.rmPrimary, size: 24.sp),
            )
          else
            TextButton.icon(
              onPressed: () {
                final onBackPressed = widget.onBackPressed;
                if (onBackPressed != null) {
                  onBackPressed();
                  return;
                }
                Navigator.of(context).maybePop();
              },
              icon: Icon(Icons.arrow_back, size: 16.sp),
              label: Text(
                backLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.rmPrimary,
                padding: EdgeInsets.symmetric(horizontal: 4),
                textStyle: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.30,
                ),
              ),
            ),
          const Spacer(),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              _refreshAccountData();
            },
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tightFor(width: 40.w, height: 40.h),
            icon: Icon(
              Icons.refresh,
              size: 22.sp,
              color: AppColors.standardIconColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHolidaySection() {
    return Consumer<HolidayProvider>(
      builder: (context, provider, _) {
        final holidays = provider.holidays.toList()
          ..sort((left, right) => left.date.compareTo(right.date));

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(radius: 12.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Holidays $_holidayYear',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.rmPrimary,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                  ),
                  if (provider.isLoading)
                    SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.rmPrimary,
                      ),
                    )
                  else
                    Text(
                      '${holidays.length}',
                      style: TextStyle(
                        color: AppColors.rmMutedText,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 14.h),
              if (provider.isLoading && holidays.isEmpty)
                const _HolidayEmptyState(message: 'Loading holidays...')
              else if (holidays.isEmpty)
                const _HolidayEmptyState(message: 'No holidays available.')
              else
                Column(
                  children: [
                    for (var index = 0; index < holidays.length; index++) ...[
                      _HolidayListTile(holiday: holidays[index]),
                      if (index != holidays.length - 1)
                        Divider(height: 18.h, color: AppColors.rmDivider),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileCard() {
    final employeeName = _attendanceSummary.name.isEmpty
        ? _loggedInUserName()
        : _attendanceSummary.name;
    final designation = _attendanceSummary.designation.isEmpty
        ? _loggedInRoleLabel()
        : _attendanceSummary.designation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
      decoration: _cardDecoration(radius: 12.r),
      child: Column(
        children: [
          CircleAvatar(
            radius: 34.r,
            backgroundColor: AppColors.rmAvatarGrey,
            child: Icon(Icons.person, color: AppColors.white, size: 38.sp),
          ),
          SizedBox(height: 18.h),
          Text(
            designation,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.rmPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            employeeName,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.rmPrimary,
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              height: 1.15.h,
            ),
          ),
          SizedBox(height: 12.h),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              'Attendance and employment archival details for this employee are consolidated here for HR review.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.rmBodyText,
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                height: 1.40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    final items = [
      _InfoTileData(
        'Department',
        _attendanceSummary.designation.isEmpty
            ? _loggedInRoleLabel()
            : _attendanceSummary.designation,
      ),
      const _InfoTileData('Joined On', 'Not available'),
      _InfoTileData(
        'Reporting Manager',
        _attendanceSummary.reportingManagerName.isEmpty
            ? 'Not assigned'
            : _attendanceSummary.reportingManagerName,
      ),
      const _InfoTileData('Base Salary', 'Not available'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: _InfoTile(data: item),
              ),
          ],
        );
      },
    );
  }

  Widget _buildIncentiveCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Incentive Eligibility',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.rmMutedText,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.25.h,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Eligible',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.20.h,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            'Starter',
            style: TextStyle(
              color: AppColors.rmPrimary,
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
              height: 1.20.h,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Current unlocked tier',
            style: TextStyle(
              color: AppColors.rmBodyText,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.5,
              minHeight: 8,
              backgroundColor: AppColors.rmDivider,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.rmPrimary,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  '5 qualified closures',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.rmMutedText,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Target 10',
                style: TextStyle(
                  color: AppColors.rmMutedText,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          const _IncentiveDetailCard(
            label: 'Earned Incentive',
            value: '5% unlocked',
          ),
          SizedBox(height: 12.h),
          const _IncentiveDetailCard(
            label: 'Current Tier',
            value: 'Starter at 5%',
          ),
          SizedBox(height: 12.h),
          const _IncentiveDetailCard(
            label: 'Next Unlock',
            value: '5 more qualified leads for Growth',
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentControl() {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.rmCardShadow,
            blurRadius: 14.r,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Attendance',
              selected: _showAttendance,
              onTap: () => setState(() => _showAttendance = true),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'History',
              selected: !_showAttendance,
              onTap: () => setState(() => _showAttendance = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAttendanceHeader(),
        SizedBox(height: 14.h),
        _buildAttendanceStats(),
        SizedBox(height: 18.h),
        _buildCalendarCard(),
      ],
    );
  }

  Widget _buildAttendanceHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.rmPrimary,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        DateFormat(
                          'MMMM yyyy',
                        ).format(DateTime(_attendanceYear, _attendanceMonth)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.rmMutedText,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    if (_isAttendanceLoading) ...[
                      SizedBox(width: 8.w),
                      SizedBox(
                        width: 14.w,
                        height: 14.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.rmPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStats() {
    final stats = [
      _AttendanceStatData(
        _attendanceSummary.presentDays.toString().padLeft(2, '0'),
        'Present',
        AppColors.success,
      ),
      _AttendanceStatData(
        _attendanceSummary.absentDays.toString().padLeft(2, '0'),
        'Absent',
        AppColors.danger,
      ),
      _AttendanceStatData(
        _attendanceSummary.leaveDays.toString().padLeft(2, '0'),
        'Leave',
        AppColors.accent,
      ),
      _AttendanceStatData(
        _attendanceSummary.holidayDays.toString().padLeft(2, '0'),
        'Holiday',
        AppColors.rmPrimary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final stat in stats)
              SizedBox(
                width: itemWidth,
                child: _AttendanceStatCard(data: stat),
              ),
            SizedBox(
              width: constraints.maxWidth,
              child: _AttendanceStatCard(
                data: _AttendanceStatData(
                  _attendanceSummary.lateDays.toString().padLeft(2, '0'),
                  'Late Days',
                  AppColors.rmMutedText,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendarCard() {
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final days = _calendarDays();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: _cardDecoration(radius: 12.r),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.chevron_left,
                    color: AppColors.rmMutedText,
                    size: 24.sp,
                  ),
                ),
                Expanded(
                  child: Text(
                    DateFormat(
                      'MMMM yyyy',
                    ).format(DateTime(_attendanceYear, _attendanceMonth)),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.rmHeading,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.chevron_right,
                    color: AppColors.rmMutedText,
                    size: 24.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.25,
            children: [
              for (final day in weekdays)
                Center(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.rmMutedText,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      height: 1.20,
                    ),
                  ),
                ),
            ],
          ),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.02,
            children: [for (final day in days) _CalendarDayCell(day: day)],
          ),
          if (_attendanceError != null) ...[
            SizedBox(height: 12.h),
            Text(
              _attendanceError!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
          SizedBox(height: 14.h),
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _LegendDot(color: AppColors.success, label: 'Present'),
              _LegendDot(color: AppColors.danger, label: 'Absent'),
              _LegendDot(color: AppColors.accent, label: 'Leave'),
              _LegendDot(color: AppColors.rmPrimary, label: 'Holiday'),
            ],
          ),
        ],
      ),
    );
  }

  List<_CalendarDay> _calendarDays() {
    final attendanceByDay = {
      for (final day in _attendanceDays) day.date.day: day,
    };
    final firstDate = DateTime(_attendanceYear, _attendanceMonth);
    final daysInMonth = DateTime(_attendanceYear, _attendanceMonth + 1, 0).day;
    final previousMonthDays = DateTime(
      _attendanceYear,
      _attendanceMonth,
      0,
    ).day;
    final leadingDays = firstDate.weekday % 7;
    final cells = <_CalendarDay>[];

    for (var index = leadingDays; index > 0; index--) {
      cells.add(_CalendarDay('${previousMonthDays - index + 1}', muted: true));
    }

    for (var day = 1; day <= daysInMonth; day++) {
      final attendanceDay = attendanceByDay[day];
      cells.add(
        _CalendarDay(
          '$day',
          selected:
              day == DateTime.now().day &&
              _attendanceMonth == DateTime.now().month &&
              _attendanceYear == DateTime.now().year,
          statusColor: _attendanceStatusColor(attendanceDay?.status),
        ),
      );
    }

    var nextDay = 1;
    while (cells.length % 7 != 0) {
      cells.add(_CalendarDay('${nextDay++}', muted: true));
    }

    return cells;
  }

  Color? _attendanceStatusColor(String? status) {
    switch (status?.trim().toLowerCase()) {
      case 'present':
        return AppColors.success;
      case 'absent':
        return AppColors.danger;
      case 'leave':
        return AppColors.accent;
      case 'holiday':
        return AppColors.rmPrimary;
      case 'half_day':
      case 'half-day':
      case 'half day':
        return AppColors.rmMutedText;
      default:
        return null;
    }
  }

  Widget _buildHistorySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Payroll History',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.rmPrimary,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ),
              if (_isPayrollHistoryLoading)
                SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.rmPrimary,
                  ),
                )
              else
                Text(
                  '${_payrollHistory.length}',
                  style: TextStyle(
                    color: AppColors.rmMutedText,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          SizedBox(height: 14.h),
          if (_isPayrollHistoryLoading && _payrollHistory.isEmpty)
            const _HistoryEmptyState(message: 'Loading payroll history...')
          else if (_payrollHistoryError != null && _payrollHistory.isEmpty)
            _HistoryEmptyState(message: _payrollHistoryError!)
          else if (_payrollHistory.isEmpty)
            const _HistoryEmptyState(message: 'No payroll history available.')
          else
            Column(
              children: [
                for (
                  var index = 0;
                  index < _payrollHistory.length;
                  index++
                ) ...[
                  _PayrollHistoryTile(
                    item: _payrollHistory[index],
                    currencyFormat: _currencyFormat,
                  ),
                  if (index != _payrollHistory.length - 1)
                    Divider(height: 20.h, color: AppColors.rmDivider),
                ],
              ],
            ),
        ],
      ),
    );
  }

  static BoxDecoration _cardDecoration({required double radius}) {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.rmPaleRoseBorder),
      boxShadow: const [
        BoxShadow(
          color: AppColors.rmCardShadow,
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    );
  }
}

String _asString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
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

String _firstNonEmpty(Iterable<dynamic> values, {String fallback = ''}) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) {
      return text;
    }
  }
  return fallback;
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class _EmployeeAttendanceResult {
  const _EmployeeAttendanceResult({required this.summary, required this.days});

  final _EmployeeAttendanceSummary summary;
  final List<_EmployeeAttendanceDay> days;

  factory _EmployeeAttendanceResult.fromResponse(dynamic data) {
    final source = data is Map<String, dynamic>
        ? data
        : data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    final days =
        (source['days'] is List ? source['days'] as List : const [])
            .whereType<Map>()
            .map((item) => _EmployeeAttendanceDay.fromJson(item))
            .toList()
          ..sort((left, right) => left.date.compareTo(right.date));

    return _EmployeeAttendanceResult(
      summary: _EmployeeAttendanceSummary.fromJson(source, days),
      days: days,
    );
  }
}

class _EmployeeAttendanceSummary {
  const _EmployeeAttendanceSummary({
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

  factory _EmployeeAttendanceSummary.empty() {
    final now = DateTime.now();
    return _EmployeeAttendanceSummary(
      name: '',
      email: '',
      designation: '',
      reportingManagerName: '',
      month: now.month,
      year: now.year,
      presentDays: 0,
      absentDays: 0,
      leaveDays: 0,
      holidayDays: 0,
      lateDays: 0,
    );
  }

  factory _EmployeeAttendanceSummary.fromJson(
    Map<String, dynamic> json,
    List<_EmployeeAttendanceDay> days,
  ) {
    final employee =
        _asMap(json['employee']) ??
        _asMap(json['user']) ??
        _asMap(json['employeeProfile']) ??
        const <String, dynamic>{};
    final reportingManager =
        _asMap(json['reportingManager']) ??
        _asMap(employee['reportingManager']) ??
        const <String, dynamic>{};

    return _EmployeeAttendanceSummary(
      name: _firstNonEmpty([json['name'], employee['name']]),
      email: _firstNonEmpty([json['email'], employee['email']]),
      designation: _firstNonEmpty([
        json['designation'],
        employee['designation'],
        employee['department'],
        employee['role'],
      ]),
      reportingManagerName: _asString(reportingManager['name']),
      month: _asInt(json['month']),
      year: _asInt(json['year']),
      presentDays: _countStatus(days, 'present'),
      absentDays: _countStatus(days, 'absent'),
      leaveDays: _countStatus(days, 'leave'),
      holidayDays: _countStatus(days, 'holiday'),
      lateDays: days.where((day) => day.isLate).length,
    );
  }

  static int _countStatus(List<_EmployeeAttendanceDay> days, String status) {
    return days
        .where((day) => day.status.trim().toLowerCase() == status)
        .length;
  }
}

class _EmployeeAttendanceDay {
  const _EmployeeAttendanceDay({
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

  bool get isLate {
    final loggedAt = loggedInAt;
    if (loggedAt == null || status.trim().toLowerCase() != 'present') {
      return false;
    }
    final local = loggedAt.toLocal();
    return local.hour > 10 || (local.hour == 10 && local.minute > 15);
  }

  factory _EmployeeAttendanceDay.fromJson(Map<dynamic, dynamic> json) {
    final leaveDetails = json['leaveDetails'] is Map
        ? Map<String, dynamic>.from(json['leaveDetails'] as Map)
        : const <String, dynamic>{};
    final holidayDetails = json['holidayDetails'] is Map
        ? Map<String, dynamic>.from(json['holidayDetails'] as Map)
        : const <String, dynamic>{};

    return _EmployeeAttendanceDay(
      id: _asString(json['id']),
      date: DateTime.tryParse(_asString(json['date'])) ?? DateTime(1900),
      status: _asString(json['status']),
      source: _asString(json['source']),
      loggedInAt: DateTime.tryParse(_asString(json['loggedInAt'])),
      notes: _nullableString(json['notes']),
      leaveType: _nullableString(leaveDetails['type']),
      holidayName: _nullableString(holidayDetails['name']),
      isHalfDay:
          leaveDetails['isHalfDay'] == true ||
          holidayDetails['isHalfDay'] == true,
    );
  }
}

class _PayrollHistoryItem {
  const _PayrollHistoryItem({
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

  static List<_PayrollHistoryItem> fromResponse(dynamic data) {
    final rows = _extractRows(data);
    return rows
        .whereType<Map>()
        .map(
          (row) => _PayrollHistoryItem.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  factory _PayrollHistoryItem.fromJson(Map<String, dynamic> json) {
    final payrollRun =
        _asMap(json['payrollRun']) ??
        _asMap(json['run']) ??
        _asMap(json['payroll']);

    return _PayrollHistoryItem(
      id: _asString(json['id']),
      month: _asInt(json['month'] ?? payrollRun?['month']),
      year: _asInt(json['year'] ?? payrollRun?['year']),
      status: _asString(
        json['status'] ?? payrollRun?['status'],
        fallback: 'PENDING',
      ),
      workingDays: _asInt(json['workingDays']),
      payableDays: _asInt(json['payableDays']),
      presentDays: _asInt(json['presentDays']),
      absentDays: _asInt(json['absentDays']),
      leaveDays: _asInt(json['leaveDays']),
      holidayDays: _asInt(json['holidayDays']),
      baseSalary: _asDouble(json['baseSalary']),
      deductionAmount: _asDouble(json['deductionAmount']),
      incentiveAmount: _asDouble(json['incentiveAmount']),
      netSalary: _asDouble(json['netSalary']),
      payslipDeliveryStatus: _asString(
        json['payslipDeliveryStatus'],
        fallback: 'PENDING',
      ),
      payslipFileName: json['payslipFileName']?.toString(),
      payslipGeneratedAt: _asDateTime(json['payslipGeneratedAt']),
    );
  }

  static List<dynamic> _extractRows(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      for (final key in ['history', 'entries', 'payrolls', 'data', 'items']) {
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

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _asDateTime(dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text);
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.rmOffWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.rmDivider),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.rmMutedText,
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    );
  }
}

class _PayrollHistoryTile extends StatelessWidget {
  const _PayrollHistoryTile({required this.item, required this.currencyFormat});

  final _PayrollHistoryItem item;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final period = item.month == 0 || item.year == 0
        ? 'Payroll period'
        : DateFormat('MMMM yyyy').format(DateTime(item.year, item.month));
    final generatedAt = item.payslipGeneratedAt == null
        ? null
        : DateFormat('dd MMM yyyy').format(item.payslipGeneratedAt!.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.rmSoftPink,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: AppColors.rmPrimary,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.rmHeading,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    currencyFormat.format(item.netSalary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                      height: 1.20,
                    ),
                  ),
                ],
              ),
            ),
            _PayrollStatusPill(label: item.status),
          ],
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PayrollMetaChip(label: 'Payable ${item.payableDays}d'),
            _PayrollMetaChip(label: 'Present ${item.presentDays}d'),
            _PayrollMetaChip(label: 'Absent ${item.absentDays}d'),
            _PayrollMetaChip(label: 'Leave ${item.leaveDays}d'),
            _PayrollMetaChip(label: 'Holiday ${item.holidayDays}d'),
            _PayrollMetaChip(
              label: 'Incentive ${currencyFormat.format(item.incentiveAmount)}',
            ),
            _PayrollMetaChip(
              label: 'Deduction ${currencyFormat.format(item.deductionAmount)}',
            ),
            _PayrollMetaChip(label: item.payslipDeliveryStatus),
            if (generatedAt != null) _PayrollMetaChip(label: generatedAt),
          ],
        ),
      ],
    );
  }
}

class _PayrollStatusPill extends StatelessWidget {
  const _PayrollStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.successContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.success,
          fontSize: 11.sp,
          fontWeight: FontWeight.w900,
          height: 1.15,
        ),
      ),
    );
  }
}

class _PayrollMetaChip extends StatelessWidget {
  const _PayrollMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.rmOffWhite,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.rmDivider),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.rmMutedText,
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
      ),
    );
  }
}

class _HolidayEmptyState extends StatelessWidget {
  const _HolidayEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.rmOffWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.rmDivider),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.rmMutedText,
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    );
  }
}

class _HolidayListTile extends StatelessWidget {
  const _HolidayListTile({required this.holiday});

  final HolidayModel holiday;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd MMM yyyy').format(holiday.date.toLocal());
    final typeLabel = holiday.type.trim().isEmpty ? 'Holiday' : holiday.type;
    final accent = holiday.isHalfDay ? AppColors.accent : AppColors.success;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44.w,
          height: 44.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            holiday.isHalfDay ? Icons.timelapse : Icons.event_available,
            color: accent,
            size: 22.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                holiday.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.rmHeading,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
              SizedBox(height: 5.h),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _HolidayMetaChip(label: dateLabel),
                  _HolidayMetaChip(label: typeLabel),
                  if (holiday.isHalfDay)
                    const _HolidayMetaChip(label: 'Half day'),
                ],
              ),
              if (holiday.description.trim().isNotEmpty) ...[
                SizedBox(height: 7.h),
                Text(
                  holiday.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.rmBodyText,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HolidayMetaChip extends StatelessWidget {
  const _HolidayMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.rmOffWhite,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.rmDivider),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.rmMutedText,
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
      ),
    );
  }
}

class _InfoTileData {
  const _InfoTileData(this.label, this.value);

  final String label;
  final String value;
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.data});

  final _InfoTileData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.all(14),
      decoration: _RelationshipManagerAccountScreenState._cardDecoration(
        radius: 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.rmMutedText,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.rmPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              height: 1.20,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncentiveDetailCard extends StatelessWidget {
  const _IncentiveDetailCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.rmOffWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.rmDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.rmMutedText,
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.rmHeading,
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceStatData {
  const _AttendanceStatData(this.value, this.label, this.color);

  final String value;
  final String label;
  final Color color;
}

class _AttendanceStatCard extends StatelessWidget {
  const _AttendanceStatCard({required this.data});

  final _AttendanceStatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86.h,
      alignment: Alignment.center,
      decoration: _RelationshipManagerAccountScreenState._cardDecoration(
        radius: 12.sp,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            data.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: data.color,
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.rmBodyText,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              height: 1.20,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDay {
  const _CalendarDay(
    this.label, {
    this.muted = false,
    this.selected = false,
    this.statusColor,
  });

  final String label;
  final bool muted;
  final bool selected;
  final Color? statusColor;
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({required this.day});

  final _CalendarDay day;

  @override
  Widget build(BuildContext context) {
    final textColor = day.selected
        ? AppColors.rmPrimary
        : day.muted
        ? const Color(0xFFD6CDD0)
        : AppColors.rmBodyText;

    return Center(
      child: Container(
        width: 34.w,
        height: 34.h,
        decoration: BoxDecoration(
          color: day.selected ? AppColors.rmSoftPink : AppColors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                height: 1.00,
              ),
            ),
            SizedBox(height: 4.h),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: day.statusColor ?? AppColors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 5.w),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.rmBodyText,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            height: 1.20,
          ),
        ),
      ],
    );
  }
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.rmSoftPink : AppColors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppColors.rmPrimary : AppColors.rmMutedText,
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            height: 1.20,
          ),
        ),
      ),
    );
  }
}
