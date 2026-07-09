import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';

class RunPayrollDialog extends StatefulWidget {
  final dynamic payroll;
  final VoidCallback onRun;

  const RunPayrollDialog({super.key, required this.payroll, required this.onRun});

  @override
  State<RunPayrollDialog> createState() => _RunPayrollDialogState();
}

class _RunPayrollDialogState extends State<RunPayrollDialog> {
  late String _selectedMonth;
  late String _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedMonth = _getMonthName(widget.payroll?.month ?? DateTime.now().month);
    _selectedYear = (widget.payroll?.year ?? DateTime.now().year).toString();
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppColors.rmSoftPink,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Run Payroll',
                  style: GoogleFonts.manrope(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1D1B20),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF7E7E7E)),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'Finalize calculations and prepare payslips for the selected period. This will enable row-level processing.',
              style: GoogleFonts.manrope(
                fontSize: 14.sp,
                color: const Color(0xFF727785),
                height: 1.4,
              ),
            ),
            SizedBox(height: 24.h),
            _buildLabel('MONTH'),
            SizedBox(height: 8.h),
            _buildDropdown(_selectedMonth, ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']),
            SizedBox(height: 16.h),
            _buildLabel('YEAR'),
            SizedBox(height: 8.h),
            _buildDropdown(_selectedYear, ['2026', '2027']),
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('PERIOD', '$_selectedMonth $_selectedYear'),
                  SizedBox(height: 12.h),
                  _buildSummaryRow('STAFF COUNT', '${widget.payroll?.entries.length ?? 0} records'),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: () {
                  widget.onRun();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text('Run Payroll', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text('Cancel', style: GoogleFonts.manrope(color: AppColors.primary, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.manrope(fontSize: 10.sp, fontWeight: FontWeight.w800, color: const Color(0xFF727785)),
    );
  }

  Widget _buildDropdown(String value, List<String> items) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEBEBEB)),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          onChanged: (val) => setState(() => val == '2026' || val == '2027' ? _selectedYear = val! : _selectedMonth = val!),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 13.sp, color: const Color(0xFF727785))),
        Text(value, style: GoogleFonts.manrope(fontSize: 13.sp, fontWeight: FontWeight.w800, color: const Color(0xFF1D1B20))),
      ],
    );
  }
}
