import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:koniwalamatrimonial/widgets/run_payroll_dialog.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class PayrollManagementScreen extends StatefulWidget {
  const PayrollManagementScreen({super.key});

  @override
  State<PayrollManagementScreen> createState() =>
      _PayrollManagementScreenState();
}

class _PayrollManagementScreenState extends State<PayrollManagementScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: 'Rs. ',
    locale: 'en_IN',
    decimalDigits: 0,
  );
  late int _selectedMonth;
  late int _selectedYear;
  final Set<String> _downloadingPayslipIds = <String>{};

  bool _isPayrollBlockedForRole(String? role) {
    final normalizedRole = role?.toUpperCase();
    return normalizedRole == 'MANAGER' ||
        normalizedRole == 'RELATIONSHIP_MANAGER';
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final role = context.read<AuthProvider>().userModel?.user?.role;
      if (_isPayrollBlockedForRole(role)) {
        return;
      }
      _fetchPayrollPreview();
    });
  }

  Future<void> _fetchPayrollPreview() {
    final role = context.read<AuthProvider>().userModel?.user?.role;
    if (_isPayrollBlockedForRole(role)) {
      return Future.value();
    }

    return context.read<AuthProvider>().fetchPayrollPreview(
      month: _selectedMonth,
      year: _selectedYear,
    );
  }

  Future<void> _showRecalculateDialog() async {
    final payroll = context.read<AuthProvider>().payrollPreview;
    if (payroll == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Payroll preview is not available.'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      return;
    }

    final selectedPeriod = await showDialog<_PayrollPeriod>(
      context: context,
      builder: (context) => _RecalculatePayrollDialog(
        initialMonth: _selectedMonth,
        initialYear: _selectedYear,
      ),
    );

    if (selectedPeriod == null || !mounted) {
      return;
    }

    final result = await context.read<AuthProvider>().recalculatePayroll(
      id: payroll.id,
      month: selectedPeriod.month,
      year: selectedPeriod.year,
      status: payroll.status.trim().isEmpty
          ? 'DRAFT'
          : payroll.status.trim().toUpperCase(),
    );
    final success = result.success;

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Payroll recalculated successfully.'
                : result.message ?? 'Failed to recalculate payroll.',
          ),
          backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
        ),
      );

    if (!success) {
      return;
    }

    setState(() {
      _selectedMonth = selectedPeriod.month;
      _selectedYear = selectedPeriod.year;
    });
    await _fetchPayrollPreview();
  }

  String _formatCurrency(String value) {
    try {
      final double amount = double.parse(value);
      return _currencyFormat.format(amount);
    } catch (e) {
      return 'Rs. $value';
    }
  }

  String _formatStatus(String status) {
    final normalizedStatus = status.trim();
    if (normalizedStatus.isEmpty) {
      return 'Pending';
    }

    return normalizedStatus[0].toUpperCase() +
        normalizedStatus.substring(1).toLowerCase();
  }

  Future<void> _downloadPayslip({
    required String payslipId,
    String? fileName,
  }) async {
    if (payslipId.trim().isEmpty || _downloadingPayslipIds.contains(payslipId)) {
      return;
    }

    setState(() => _downloadingPayslipIds.add(payslipId));
    final success = await context.read<AuthProvider>().downloadPayrollPayslip(
      payslipId: payslipId,
      fileName: fileName,
    );

    if (!mounted) {
      return;
    }

    setState(() => _downloadingPayslipIds.remove(payslipId));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Payroll slip downloaded successfully.'
                : 'Unable to download payroll slip.',
          ),
          backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
        ),
      );
  }

  Future<void> _runPayroll({required int month, required int year}) async {
    final success = await context.read<AuthProvider>().runPayroll(
      month: month,
      year: year,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Payroll processed successfully.'
              : 'Failed to process payroll.',
        ),
        backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
      ),
    );

    if (success) {
      _fetchPayrollPreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final role = authProvider.userModel?.user?.role;

    if (_isPayrollBlockedForRole(role)) {
      return Scaffold(
        backgroundColor: AppColors.rmSoftPink,
        appBar: AppBar(
          toolbarHeight: 44.h,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              'Payroll Management is not available for this role.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      );
    }

    final payroll = authProvider.payrollPreview;
    final isLoading = authProvider.isLoading;

    double totalNetPayout = 0;
    double totalIncentives = 0;
    double totalDeductions = 0;
    int totalEntries = 0;

    if (payroll != null) {
      totalEntries = payroll.entries.length;
      for (var entry in payroll.entries) {
        totalNetPayout += double.tryParse(entry.netSalary) ?? 0;
        totalIncentives += double.tryParse(entry.incentiveAmount) ?? 0;
        totalDeductions += double.tryParse(entry.deductionAmount) ?? 0;
      }
    }

    final statCards = <Widget>[
      _buildStatCard(
        title: 'TOTAL NET PAYOUT',
        value: _formatCurrency(totalNetPayout.toString()),
        trend: '+2.4% Trend',
        trendIcon: Icons.trending_up,
        color: const Color(0xFF2E7D32),
      ),
      _buildStatCard(
        title: 'INCENTIVES',
        value: _formatCurrency(totalIncentives.toString()),
        trend: '5.1% Growth',
        trendIcon: Icons.show_chart,
        color: const Color(0xFF9C27B0),
      ),
      _buildStatCard(
        title: 'DEDUCTIONS',
        value: _formatCurrency(totalDeductions.toString()),
        trend: 'Tax & PF',
        trendIcon: Icons.account_balance_outlined,
        color: const Color(0xFFEF6C00),
      ),
      _buildStatCard(
        title: 'PROGRESS',
        value: '0/$totalEntries',
        trend: 'Pending rows',
        trendIcon: Icons.assignment_outlined,
        color: const Color(0xFF1976D2),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      appBar: AppBar(
        toolbarHeight: 44.h,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: AppColors.primary,
            ),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.notifications);
            },
          ),
        ],
      ),
      body: isLoading && payroll == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _fetchPayrollPreview,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payroll Management',
                      style: GoogleFonts.manrope(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Institutional salary disbursement, incentives, and net payouts.',
                      style: GoogleFonts.manrope(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 42.h,
                            child: OutlinedButton(
                              onPressed: _showRecalculateDialog,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.refresh, size: 20),
                                  SizedBox(width: 8.w),
                                  Flexible(
                                    child: Text(
                                      'Recalculate',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.manrope(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Flexible(
                          child: Container(
                            height: 42.h,
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12.r),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 8.w),
                                Flexible(
                                  child: Text(
                                    _getMonthName(
                                      payroll?.month ?? _selectedMonth,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.manrope(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                const Text(
                                  '|',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Flexible(
                                  child: Text(
                                    '${payroll?.year ?? _selectedYear}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.manrope(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    SizedBox(
                      width: double.infinity,
                      height: 46.h,
                      child: ElevatedButton(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => RunPayrollDialog(
                            payroll: payroll,
                            onRun: () {
                              if (payroll != null) {
                                _runPayroll(
                                  month: payroll.month,
                                  year: payroll.year,
                                );
                              }
                            },
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8.w),
                            Flexible(
                              child: Text(
                                'Run Payroll',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: statCards.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10.h,
                        crossAxisSpacing: 10.w,
                        mainAxisExtent: 124,
                      ),
                      itemBuilder: (context, index) => statCards[index],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 42.h,
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                  size: 22,
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search by name, email or ID...',
                                      hintStyle: GoogleFonts.manrope(
                                        color: Colors.grey,
                                        fontSize: 13.sp,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Container(
                          height: 42.h,
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.filter_list,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              SizedBox(width: 6.w),
                              Flexible(
                                child: Text(
                                  'Filters',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(
                                    fontSize: 14.sp,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTab('All', true),
                          SizedBox(width: 8.w),
                          _buildTab('Draft', false),
                          SizedBox(width: 8.w),
                          _buildTab('Ready', false),
                          SizedBox(width: 8.w),
                          _buildTab('Failed', false),
                          SizedBox(width: 8.w),
                          _buildTab('Paid', false),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    if (payroll != null)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: payroll.entries.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 12.h),
                        itemBuilder: (context, index) {
                          final entry = payroll.entries[index];
                          return _buildPayrollCard(
                            payslipId: entry.id,
                            name: entry.user.name,
                            role: entry.user.role.replaceAll('_', ' '),
                            title:
                                entry.user.employeeProfile?.designation ??
                                'Employee',
                            baseSalary: _formatCurrency(entry.baseSalary),
                            attendance: '${entry.presentDays}d',
                            incentive:
                                '+${_formatCurrency(entry.incentiveAmount)}',
                            deductions:
                                '-${_formatCurrency(entry.deductionAmount)}',
                            netPayable: _formatCurrency(entry.netSalary),
                            status: entry.payslipDeliveryStatus,
                            payslipFileName: entry.payslipFileName,
                            isDownloading: _downloadingPayslipIds.contains(
                              entry.id,
                            ),
                          );
                        },
                      ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return 'Month';
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String trend,
    required IconData trendIcon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              color: Colors.grey[500],
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1D1B20),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(trendIcon, size: 12.sp, color: color),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  trend,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF7E6EB) : Colors.transparent,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 13.sp,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? AppColors.primary : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildPayrollCard({
    required String payslipId,
    required String name,
    required String role,
    required String title,
    required String baseSalary,
    required String attendance,
    required String incentive,
    required String deductions,
    required String netPayable,
    required String status,
    String? payslipFileName,
    bool isDownloading = false,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: const DecorationImage(
                    image: AssetImage('assets/wedding_hero 1.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.manrope(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1D1B20),
                            ),
                          ),
                        ),
                        Flexible(
                          flex: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Text(
                              _formatStatus(status),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7E6EB),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        role,
                        style: GoogleFonts.manrope(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 14.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF7F9),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFF7E6EB)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSalaryInfo('BASE SALARY', baseSalary),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildSalaryInfo(
                        'ATTENDANCE',
                        attendance,
                        isAttendance: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildSalaryInfo(
                        'INCENTIVE',
                        incentive,
                        valueColor: const Color(0xFF2E7D32),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildSalaryInfo(
                        'DEDUCTIONS',
                        deductions,
                        valueColor: const Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 10.h,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 170.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NET PAYABLE',
                      style: GoogleFonts.manrope(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[500],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      netPayable,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(Icons.send_outlined),
                  SizedBox(width: 6.w),
                  _buildActionButton(Icons.visibility_outlined),
                  SizedBox(width: 6.w),
                  _buildActionButton(
                    Icons.download_outlined,
                    isLoading: isDownloading,
                    onTap: () => _downloadPayslip(
                      payslipId: payslipId,
                      fileName: payslipFileName,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryInfo(
    String label,
    String value, {
    bool isAttendance = false,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            fontSize: 9.sp,
            fontWeight: FontWeight.w800,
            color: Colors.grey[500],
            letterSpacing: 0.4,
          ),
        ),
        SizedBox(height: 4.h),
        if (isAttendance)
          Row(
            children: [
              Container(
                width: 32.w,
                height: 3.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1D1B20),
                  ),
                ),
              ),
            ],
          )
        else
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: valueColor ?? const Color(0xFF1D1B20),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon, {
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(999.r),
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF7E6EB),
        ),
        child: isLoading
            ? SizedBox(
                width: 16.sp,
                height: 16.sp,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              )
            : Icon(icon, size: 16.sp, color: AppColors.primary),
      ),
    );
  }
}

class _PayrollPeriod {
  const _PayrollPeriod({required this.month, required this.year});

  final int month;
  final int year;
}

class _RecalculatePayrollDialog extends StatefulWidget {
  const _RecalculatePayrollDialog({
    required this.initialMonth,
    required this.initialYear,
  });

  final int initialMonth;
  final int initialYear;

  @override
  State<_RecalculatePayrollDialog> createState() =>
      _RecalculatePayrollDialogState();
}

class _RecalculatePayrollDialogState extends State<_RecalculatePayrollDialog> {
  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialMonth.clamp(1, 12);
    _selectedYear = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List<int>.generate(5, (index) => currentYear - 2 + index);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 448.w),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 22.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Recalculate Payroll',
                      style: GoogleFonts.manrope(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF2B292D),
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(999.r),
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Icon(
                        Icons.close,
                        size: 18.sp,
                        color: const Color(0xFF5D5B62),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                'Select the target period to preview and recalculate attendance, deductions, and incentives.',
                style: GoogleFonts.manrope(
                  fontSize: 14.sp,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6D6875),
                ),
              ),
              SizedBox(height: 28.h),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      label: 'MONTH',
                      value: _selectedMonth,
                      items: List<int>.generate(12, (index) => index + 1),
                      displayText: (month) => _months[month - 1],
                      onChanged: (month) {
                        if (month == null) return;
                        setState(() => _selectedMonth = month);
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildDropdownField(
                      label: 'YEAR',
                      value: _selectedYear,
                      items: years,
                      displayText: (year) => year.toString(),
                      onChanged: (year) {
                        if (year == null) return;
                        setState(() => _selectedYear = year);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(78.w, 38.h),
                      foregroundColor: const Color(0xFF2B292D),
                      side: const BorderSide(color: Color(0xFFE2E1E6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.manrope(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 20.w),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(
                      _PayrollPeriod(
                        month: _selectedMonth,
                        year: _selectedYear,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(104.w, 38.h),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    child: Text(
                      'Recalculate',
                      style: GoogleFonts.manrope(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required int value,
    required List<int> items,
    required String Function(int value) displayText,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2B292D),
          ),
        ),
        SizedBox(height: 9.h),
        Container(
          height: 36.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDAD8DE)),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20.sp,
                color: const Color(0xFF2B292D),
              ),
              style: GoogleFonts.manrope(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2B292D),
              ),
              onChanged: onChanged,
              items: items
                  .map(
                    (item) => DropdownMenuItem<int>(
                      value: item,
                      child: Text(
                        displayText(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
