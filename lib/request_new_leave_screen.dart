import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/owner/providers/leave_request_provider.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/providers/leave_provider.dart';
import 'package:provider/provider.dart';

class RequestNewLeaveScreen extends StatefulWidget {
  const RequestNewLeaveScreen({super.key});

  @override
  State<RequestNewLeaveScreen> createState() => _RequestNewLeaveScreenState();
}



class _RequestNewLeaveScreenState extends State<RequestNewLeaveScreen> {
  final List<String> _categories = const [
    'Annual leave',
    'Sick leave',
    'Unpaid leave',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveRequestProvider>().reset();
    });
  }

  Future<void> _pickDate(void Function(DateTime date) onSelected) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              onSurface: AppColors.rmHeading,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    onSelected(date);
  }

  DateTime? _parseDate(String input) {
    final parts = input.split('/');
    if (parts.length != 3) {
      return null;
    }

    final month = int.tryParse(parts[0]);
    final day = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (month == null || day == null || year == null) {
      return null;
    }

    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submitLeave() async {
    final requestProvider = context.read<LeaveRequestProvider>();
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.userModel?.accessToken?.trim() ?? '';
    final selectedCategory = requestProvider.selectedCategory;
    final departureText = requestProvider.departureDateController.text.trim();
    final returnText = requestProvider.returnDateController.text.trim();
    final reason = requestProvider.justificationController.text.trim();

    if (selectedCategory == null || selectedCategory.isEmpty) {
      _showMessage('Select a leave category.');
      return;
    }

    if (departureText.isEmpty || returnText.isEmpty) {
      _showMessage('Select both departure and return dates.');
      return;
    }

    final startDate = _parseDate(departureText);
    final endDate = _parseDate(returnText);
    if (startDate == null || endDate == null) {
      _showMessage('Invalid date selected.');
      return;
    }

    if (endDate.isBefore(startDate)) {
      _showMessage('Return date cannot be earlier than departure date.');
      return;
    }

    if (token.isEmpty) {
      _showMessage('Your session has expired. Please log in again.');
      return;
    }

    FocusScope.of(context).unfocus();

    final success = await requestProvider.submitLeave(
      token: token,
      type: selectedCategory,
      startDate: startDate,
      endDate: endDate,
      reason: reason.isEmpty ? null : reason,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(
        requestProvider.errorMessage ?? 'Failed to submit leave request.',
      );
      return;
    }

    final authUser = authProvider.userModel?.user;
    final submittedLeave = requestProvider.submittedLeave?.copyWith(
      userId: authUser?.id,
      userEmail: authUser?.email,
      userName: authUser?.name,
      userRole: authUser?.role,
    );
    final leaveProvider = context.read<LeaveProvider>();
    final includeAllLeaves = _shouldFetchAllLeaves(authUser?.role);
    await leaveProvider.fetchLeaves(token, includeAll: includeAllLeaves);
    if (!mounted) {
      return;
    }
    if (submittedLeave != null) {
      leaveProvider.upsertLeave(submittedLeave);
      leaveProvider.upsertMyLeave(submittedLeave);
    }

    requestProvider.reset();
    _showMessage('Leave request sent to admin queue.');
    Navigator.pop(context, true);
  }

  void _closeScreen() {
    context.read<LeaveRequestProvider>().reset();
    Navigator.pop(context);
  }

  bool _shouldFetchAllLeaves(String? role) {
    final normalizedRole = role?.trim().toUpperCase() ?? '';
    return normalizedRole == 'ADMIN' ||
        normalizedRole == 'OWNER' ||
        normalizedRole == 'HR';
  }

  BoxDecoration _requestCardDecoration({double radius = 12}) {
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

  Widget _buildDecoratedField({required Widget child}) {
    return Container(
      decoration: _requestCardDecoration(radius: 12.r),
      child: child,
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.manrope(
        color: AppColors.rmHintText,
        fontWeight: FontWeight.w500,
        fontSize: 18.sp,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      filled: true,
      fillColor: AppColors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestProvider = context.watch<LeaveRequestProvider>();

    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        toolbarHeight: 66.h,
        automaticallyImplyLeading: false,
        title: Text(
          'New Request',
          style: GoogleFonts.manrope(
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.rmHeading,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _closeScreen,
            icon: Icon(Icons.close, color: AppColors.primary, size: 24.sp),
          ),
          SizedBox(width: 12.w),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request New Leave',
                style: GoogleFonts.manrope(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Initiate a formal leave request for administrative review and ledger adjustment.',
                style: GoogleFonts.manrope(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.rmMutedText,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 12.h),
              _buildLabel('Leave Categorization'),
              SizedBox(height: 6.h),
              _buildDecoratedField(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  dropdownColor: AppColors.white,
                  menuMaxHeight: 300.h,
                  borderRadius: BorderRadius.circular(12.r),
                  value: requestProvider.selectedCategory,
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            c,
                            style: GoogleFonts.manrope(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.rmHeading,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: requestProvider.setSelectedCategory,
                  decoration: _fieldDecoration('Select category...'),
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 24.sp,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              _buildLabel('Departure Date'),
              SizedBox(height: 6.h),
              _buildDecoratedField(
                child: TextFormField(
                  controller: requestProvider.departureDateController,
                  readOnly: true,
                  style: GoogleFonts.manrope(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  onTap: () => _pickDate(requestProvider.setDepartureDate),
                  decoration: _fieldDecoration('mm/dd/yyyy').copyWith(
                    prefixIcon: Icon(
                      Icons.calendar_today_outlined,
                      size: 20.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              _buildLabel('Return Date'),
              SizedBox(height: 6.h),
              _buildDecoratedField(
                child: TextFormField(
                  controller: requestProvider.returnDateController,
                  readOnly: true,
                  style: GoogleFonts.manrope(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  onTap: () => _pickDate(requestProvider.setReturnDate),
                  decoration: _fieldDecoration('mm/dd/yyyy').copyWith(
                    prefixIcon: Icon(
                      Icons.calendar_today_outlined,
                      size: 20.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              _buildLabel('Justification & Context'),
              SizedBox(height: 6.h),
              _buildDecoratedField(
                child: TextFormField(
                  controller: requestProvider.justificationController,
                  maxLines: 8,
                  style: GoogleFonts.manrope(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                  decoration: _fieldDecoration(
                    'Provide reason or context for this request...',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
        decoration: _requestCardDecoration(radius: 0),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: requestProvider.isSubmitting ? null : _submitLeave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: requestProvider.isSubmitting
                      ? SizedBox(
                          width: 22.r,
                          height: 22.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Authorize Request',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            color: AppColors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              if (requestProvider.errorMessage != null &&
                  requestProvider.errorMessage!.isNotEmpty) ...[
                SizedBox(height: 10.h),
                Text(
                  requestProvider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFFB3261E),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 40.h,
                decoration: _requestCardDecoration(radius: 12.r),
                child: OutlinedButton(
                  onPressed: requestProvider.isSubmitting ? null : _closeScreen,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppColors.primary,
                    side: BorderSide.none,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Discard',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      color: AppColors.primary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 17.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
        letterSpacing: 0,
      ),
    );
  }
}
