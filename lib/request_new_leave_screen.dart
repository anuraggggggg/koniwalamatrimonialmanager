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
  bool _isHalfDay = false;

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    setState(() => _isHalfDay = false);
    _showMessage('Leave request sent to admin queue.');
    Navigator.pop(context, true);
  }

  void _closeScreen() {
    context.read<LeaveRequestProvider>().reset();
    setState(() => _isHalfDay = false);
    Navigator.pop(context);
  }

  bool _shouldFetchAllLeaves(String? role) {
    final normalizedRole = role?.trim().toUpperCase() ?? '';
    return normalizedRole == 'ADMIN' ||
        normalizedRole == 'OWNER' ||
        normalizedRole == 'HR';
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: const Color(0xFF27292D),
        fontWeight: FontWeight.w500,
        fontSize: 16.sp,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      filled: true,
      fillColor: AppColors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFD76322)),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestProvider = context.watch<LeaveRequestProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxWidth: 390.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 18.h, 14.w, 18.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Request New Leave',
                                style: GoogleFonts.inter(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF171412),
                                  height: 1.1,
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                'Initiate a formal leave request for\nadministrative review.',
                                style: GoogleFonts.inter(
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF171412),
                                  height: 1.28,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: _closeScreen,
                          icon: Icon(
                            Icons.close_rounded,
                            color: const Color(0xFF111827),
                            size: 24.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE7DCD5)),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Leave Categorization'),
                        SizedBox(height: 14.h),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          dropdownColor: AppColors.white,
                          menuMaxHeight: 300.h,
                          borderRadius: BorderRadius.circular(12.r),
                          initialValue: requestProvider.selectedCategory,
                          items: _categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    style: GoogleFonts.inter(
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
                            color: const Color(0xFF27292D),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        _buildLabel('Departure Date'),
                        SizedBox(height: 14.h),
                        TextFormField(
                          controller: requestProvider.departureDateController,
                          readOnly: true,
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          onTap: () =>
                              _pickDate(requestProvider.setDepartureDate),
                          decoration: _fieldDecoration('mm/dd/yyyy'),
                        ),
                        SizedBox(height: 20.h),
                        _buildLabel('Return Date'),
                        SizedBox(height: 14.h),
                        TextFormField(
                          controller: requestProvider.returnDateController,
                          readOnly: true,
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          onTap: () => _pickDate(requestProvider.setReturnDate),
                          decoration: _fieldDecoration('mm/dd/yyyy'),
                        ),
                        SizedBox(height: 20.h),
                        InkWell(
                          onTap: () => setState(() => _isHalfDay = !_isHalfDay),
                          borderRadius: BorderRadius.circular(999.r),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 16.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3ED),
                              borderRadius: BorderRadius.circular(999.r),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 16.w,
                                  height: 16.w,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4.r),
                                    border: Border.all(
                                      color: const Color(0xFFFF6B2C),
                                    ),
                                    color: _isHalfDay
                                        ? const Color(0xFFFF6B2C)
                                        : Colors.white,
                                  ),
                                  child: _isHalfDay
                                      ? Icon(
                                          Icons.check_rounded,
                                          size: 12.sp,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                SizedBox(width: 14.w),
                                Text(
                                  'This is a Half-Day Leave',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF2C2522),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        _buildLabel('Justification & Context'),
                        SizedBox(height: 10.h),
                        TextFormField(
                          controller: requestProvider.justificationController,
                          maxLines: 5,
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                          decoration: _fieldDecoration(
                            'Provide reason or context for this request...',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE7DCD5)),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 14.h),
                    child: _buildActionButtons(requestProvider),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(LeaveRequestProvider requestProvider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 44.h,
          child: ElevatedButton(
            onPressed: requestProvider.isSubmitting ? null : _submitLeave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD76322),
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999.r),
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
                    'AUTHORIZE REQUEST',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
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
            style: GoogleFonts.inter(
              color: const Color(0xFFB3261E),
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        SizedBox(height: 10.h),
        SizedBox(
          width: double.infinity,
          height: 44.h,
          child: OutlinedButton(
            onPressed: requestProvider.isSubmitting ? null : _closeScreen,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD71920),
              side: const BorderSide(color: Color(0xFFD71920)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999.r),
              ),
            ),
            child: Text(
              'DISCARD',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFFD71920),
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF27292D),
        letterSpacing: 0.4,
      ),
    );
  }
}
