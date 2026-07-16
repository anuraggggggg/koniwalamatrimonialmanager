import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:koniwalamatrimonial/models/leave_model.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/providers/hr_attendance_calendar_provider.dart';
import 'package:koniwalamatrimonial/providers/leave_provider.dart';
import 'package:koniwalamatrimonial/request_new_leave_screen.dart';
import 'package:provider/provider.dart';

class AttendanceArchivesScreen extends StatefulWidget {
  const AttendanceArchivesScreen({super.key, this.onMenuPressed});

  final VoidCallback? onMenuPressed;

  @override
  State<AttendanceArchivesScreen> createState() =>
      _AttendanceArchivesScreenState();
}

class _AttendanceArchivesScreenState extends State<AttendanceArchivesScreen> {
  static const Color _maroon = AppColors.primary;
  static const Color _surface = AppColors.rmSoftPink;
  String? _requestedAccessToken;
  bool _hasRequestedCalendar = false;
  bool _hasRequestedLeaves = false;

  static BoxDecoration _archiveCardDecoration({required double radius}) {
    return BoxDecoration(
      color: Colors.white,
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final accessToken = context
        .watch<AuthProvider>()
        .userModel
        ?.accessToken
        ?.trim();
    if (_hasRequestedCalendar && accessToken == _requestedAccessToken) {
      return;
    }

    _hasRequestedCalendar = true;
    _hasRequestedLeaves = false;
    _requestedAccessToken = accessToken;
    final now = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<HrAttendanceCalendarProvider>().fetchCalendar(
        accessToken: accessToken,
        month: now.month,
        year: now.year,
      );
    });

    if (!_hasRequestedLeaves && accessToken != null && accessToken.isNotEmpty) {
      _hasRequestedLeaves = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        context.read<LeaveProvider>().fetchMyLeaves(accessToken);
      });
    }
  }

  Future<void> _openRequestNewLeave() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RequestNewLeaveScreen()),
    );
  }

  String _leaveDurationLabel(LeaveModel leave) {
    if (leave.isHalfDay) {
      return 'Half Day';
    }

    final days = leave.endDate.difference(leave.startDate).inDays + 1;
    final normalizedDays = days < 1 ? 1 : days;
    return normalizedDays == 1 ? '1 Day' : '$normalizedDays Days';
  }

  Color _leaveStatusBackground(String status) {
    switch (status.trim().toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFFE7F6EC);
      case 'REJECTED':
      case 'DENIED':
        return const Color(0xFFFFE1E1);
      default:
        return const Color(0xFFFFF3CD);
    }
  }

  Color _leaveStatusForeground(String status) {
    switch (status.trim().toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFF2E7D32);
      case 'REJECTED':
      case 'DENIED':
        return const Color(0xFFB00020);
      default:
        return const Color(0xFF8D6E00);
    }
  }

  int _compareNewestLeaves(LeaveModel left, LeaveModel right) {
    final rightDate = right.updatedAt ?? right.createdAt ?? right.startDate;
    final leftDate = left.updatedAt ?? left.createdAt ?? left.startDate;
    final dateComparison = rightDate.compareTo(leftDate);
    if (dateComparison != 0) {
      return dateComparison;
    }
    return right.id.compareTo(left.id);
  }

  @override
  Widget build(BuildContext context) {
    final leaveProvider = context.watch<LeaveProvider>();
    final myLeaves = leaveProvider.myLeaves.toList()
      ..sort(_compareNewestLeaves);
    final pendingLeaveCount = myLeaves
        .where((leave) => leave.status.trim().toUpperCase().contains('PENDING'))
        .length;
    final approvedLeaveCount = myLeaves
        .where(
          (leave) => leave.status.trim().toUpperCase().contains('APPROVED'),
        )
        .length;
    final deniedLeaveCount = myLeaves.where((leave) {
      final status = leave.status.trim().toUpperCase();
      return status.contains('DENIED') || status.contains('REJECT');
    }).length;

    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 40.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.onMenuPressed != null) ...[
                    IconButton(
                      tooltip: 'Menu',
                      onPressed: widget.onMenuPressed,
                      icon: Icon(Icons.menu, color: _maroon, size: 26.sp),
                    ),
                    SizedBox(width: 6.w),
                  ],
                  Expanded(
                    child: Container(
                      height: 44.h,
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      decoration: _archiveCardDecoration(radius: 12.r),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Attendance Archives',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1D1B20),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.search,
                            size: 20.sp,
                            color: const Color(0xFF1E1F1F),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.notifications);
                    },
                    icon: Icon(
                      Icons.notifications_none,
                      color: _maroon,
                      size: 26.sp,
                    ),
                  ),
                  CircleAvatar(
                    radius: 18.r,
                    backgroundColor: Colors.grey.withOpacity(0.15),
                    child: Icon(
                      Icons.person,
                      size: 22.sp,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                'Personnel Attendance\nArchives',
                style: GoogleFonts.inter(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  height: 1.15,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Review your historical leave requests and current ledger balances.',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E1F1F),
                  height: 1.35,
                ),
              ),
              SizedBox(height: 18.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openRequestNewLeave,
                  icon: Icon(Icons.add, size: 21.sp),
                  label: Text(
                    'Request New Leave',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 17.sp,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withOpacity(0.45),
                      width: 1.3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Pending Requests',
                      count: '$pendingLeaveCount',
                      borderColor: const Color(0xFFFFD54F),
                      iconAsset: 'assets/filter_icon.png',
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Denied Entries',
                      count: '$deniedLeaveCount',
                      icon: Icons.cancel_outlined,
                      borderColor: const Color(0xFFEF5350),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Approved Leaves',
                      count: '$approvedLeaveCount',
                      icon: Icons.check_circle_outline,
                      borderColor: const Color(0xFF66BB6A),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Ledger',
                      count: '${myLeaves.length}',
                      icon: Icons.payments_outlined,
                      borderColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 22.h),
              Text(
                'My Leave History',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 6.h),
              Container(height: 3.h, width: 126.w, color: AppColors.primary),
              SizedBox(height: 18.h),
              if (leaveProvider.isLoading && myLeaves.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    child: const CircularProgressIndicator(),
                  ),
                )
              else if (myLeaves.isEmpty)
                _buildEmptyLeaveHistory()
              else
                for (final leave in myLeaves) ...[
                  _LeaveCard(
                    title: leave.type,
                    duration: _leaveDurationLabel(leave),
                    status: leave.status.toUpperCase(),
                    statusBg: _leaveStatusBackground(leave.status),
                    statusFg: _leaveStatusForeground(leave.status),
                    reason: leave.reason.isEmpty
                        ? 'No reason added'
                        : leave.reason,
                  ),
                  SizedBox(height: 14.h),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyLeaveHistory() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: _archiveCardDecoration(radius: 12.r),
      child: Text(
        'No leave requests found for your account.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 15.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF5F4B53),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required Color borderColor,
    IconData? icon,
    String? iconAsset,
  }) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 142.h),
      decoration: _archiveCardDecoration(radius: 12.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 2.h,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 12.w, 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (iconAsset != null)
                  Image.asset(
                    iconAsset,
                    width: 22.w,
                    height: 22.h,
                    fit: BoxFit.contain,
                  )
                else
                  Icon(icon, size: 22.sp, color: borderColor),
                SizedBox(height: 11.h),
                Text(
                  count,
                  style: GoogleFonts.inter(
                    fontSize: 29.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF181C1F),
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5F4B53),
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

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({
    required this.title,
    required this.duration,
    required this.status,
    required this.statusBg,
    required this.statusFg,
    required this.reason,
  });

  final String title;
  final String duration;
  final String status;
  final Color statusBg;
  final Color statusFg;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _AttendanceArchivesScreenState._archiveCardDecoration(
        radius: 12.r,
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(17.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1D1B20),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16.sp,
                            color: const Color(0xFF1E1F1F),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            duration,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E1F1F),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 11.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      color: statusFg,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1.h, color: const Color(0xFFEFF1F6)),
          Padding(
            padding: EdgeInsets.all(15.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reason:',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7FB),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    reason,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D1B20),
                    ),
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
