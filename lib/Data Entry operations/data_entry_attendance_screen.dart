import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';

class DataEntryAttendanceScreen extends StatelessWidget {
  const DataEntryAttendanceScreen({super.key});

  static const List<_AttendanceRow> _rows = [
    _AttendanceRow('Today', 'Present', '09:45 AM', '6h 20m'),
    _AttendanceRow('Yesterday', 'Present', '09:58 AM', '8h 05m'),
    _AttendanceRow('Mon', 'Leave', '-', '0h'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 28.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance',
            style: GoogleFonts.manrope(
              fontSize: 29.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.rmPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Track daily punch-in and working-hour records.',
            style: GoogleFonts.manrope(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.rmMutedText,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  value: '2',
                  label: 'Present',
                  color: AppColors.success,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _MetricCard(
                  value: '1',
                  label: 'Leave',
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          for (final row in _rows) ...[
            _AttendanceCard(row: row),
            SizedBox(height: 12.h),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.event_available_outlined, color: color, size: 22.sp),
          SizedBox(height: 12.h),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 28.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.rmHeading,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.rmMutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.row});

  final _AttendanceRow row;

  @override
  Widget build(BuildContext context) {
    final isLeave = row.status == 'Leave';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.day,
                  style: GoogleFonts.manrope(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.rmHeading,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'In: ${row.punchIn}  |  Total: ${row.totalHours}',
                  style: GoogleFonts.manrope(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.rmMutedText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isLeave
                  ? AppColors.dangerContainer
                  : AppColors.successContainer,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Text(
              row.status,
              style: GoogleFonts.manrope(
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                color: isLeave ? AppColors.danger : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceRow {
  const _AttendanceRow(this.day, this.status, this.punchIn, this.totalHours);

  final String day;
  final String status;
  final String punchIn;
  final String totalHours;
}
