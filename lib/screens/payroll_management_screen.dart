import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/models/payroll_run.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
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
    symbol: '₹',
    locale: 'en_IN',
    decimalDigits: 0,
  );
  final TextEditingController _searchController = TextEditingController();
  late int _selectedMonth;
  late int _selectedYear;
  final Set<String> _downloadingPayslipIds = <String>{};
  String _searchQuery = '';
  _PayrollStatusFilter _selectedStatusFilter = _PayrollStatusFilter.all;
  String? _selectedDepartment;
  String? _selectedRole;
  String? _selectedManager;
  _PayrollPayoutFilter _selectedPayoutFilter = _PayrollPayoutFilter.all;

  bool _isPayrollBlockedForRole(String? role) {
    final normalizedRole = role?.toUpperCase();
    return normalizedRole == 'MANAGER' ||
        normalizedRole == 'RELATIONSHIP_MANAGER';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  String _formatCurrency(String value) {
    try {
      final double amount = double.parse(value);
      return _currencyFormat.format(amount);
    } catch (e) {
      return '₹$value';
    }
  }

  String _entryStatusLabel(PayrollEntry entry) {
    switch (_entryStatusFilter(entry)) {
      case _PayrollStatusFilter.all:
        return 'All';
      case _PayrollStatusFilter.draft:
        return 'Draft';
      case _PayrollStatusFilter.ready:
        return 'Ready';
      case _PayrollStatusFilter.failed:
        return 'Failed';
      case _PayrollStatusFilter.paid:
        return 'Paid';
    }
  }

  _PayrollStatusFilter _entryStatusFilter(PayrollEntry entry) {
    final raw = entry.payslipDeliveryStatus.trim().toUpperCase();
    if (raw == 'PAID' || raw == 'SENT' || entry.payslipSentAt != null) {
      return _PayrollStatusFilter.paid;
    }
    if (raw == 'FAILED' || raw == 'ERROR') {
      return _PayrollStatusFilter.failed;
    }
    if (raw == 'READY' ||
        raw == 'GENERATED' ||
        entry.payslipGeneratedAt != null) {
      return _PayrollStatusFilter.ready;
    }
    return _PayrollStatusFilter.draft;
  }

  String _entryRole(PayrollEntry entry) {
    final role = entry.user.role.replaceAll('_', ' ').trim();
    if (role.isEmpty) {
      return 'Employee';
    }
    return role
        .split(RegExp(r'\s+'))
        .map((word) {
          final lower = word.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  String _entryDepartment(PayrollEntry entry) {
    final department = entry.user.department?.trim();
    if (department != null && department.isNotEmpty && department != '-') {
      return department;
    }
    return entry.user.employeeProfile?.designation ?? 'General';
  }

  String _entryManager(PayrollEntry entry) {
    final manager = entry.user.employeeProfile?.reportingManager?.name.trim();
    if (manager == null || manager.isEmpty || manager == 'N/A') {
      return 'Management';
    }
    return manager;
  }

  String _entryDesignation(PayrollEntry entry) {
    final designation = entry.user.employeeProfile?.designation.trim();
    if (designation == null || designation.isEmpty || designation == 'N/A') {
      return 'Employee';
    }
    return designation;
  }

  double _readAmount(String value) {
    return double.tryParse(value.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0;
  }

  bool _matchesSearch(PayrollEntry entry) {
    if (_searchQuery.trim().isEmpty) {
      return true;
    }

    final query = _searchQuery.trim().toLowerCase();
    final haystack = <String>[
      entry.user.name,
      entry.user.email,
      entry.user.id,
      _entryRole(entry),
      _entryDepartment(entry),
      _entryManager(entry),
      _entryDesignation(entry),
      _entryStatusLabel(entry),
    ].join(' ').toLowerCase();

    return haystack.contains(query);
  }

  bool _matchesPayrollFilters(PayrollEntry entry) {
    if (_selectedStatusFilter != _PayrollStatusFilter.all &&
        _entryStatusFilter(entry) != _selectedStatusFilter) {
      return false;
    }

    if (_selectedDepartment != null &&
        _entryDepartment(entry) != _selectedDepartment) {
      return false;
    }

    if (_selectedRole != null && _entryRole(entry) != _selectedRole) {
      return false;
    }

    if (_selectedManager != null && _entryManager(entry) != _selectedManager) {
      return false;
    }

    switch (_selectedPayoutFilter) {
      case _PayrollPayoutFilter.all:
        return true;
      case _PayrollPayoutFilter.withIncentive:
        return _readAmount(entry.incentiveAmount) > 0;
      case _PayrollPayoutFilter.withDeductions:
        return _readAmount(entry.deductionAmount) > 0;
      case _PayrollPayoutFilter.editedNet:
        return entry.netSalaryEdited;
    }
  }

  List<String> _filterOptions(
    List<PayrollEntry> entries,
    String Function(PayrollEntry entry) valueForEntry,
  ) {
    final values = entries
        .map(valueForEntry)
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && value != '-')
        .toSet()
        .toList();
    values.sort(
      (first, second) => first.toLowerCase().compareTo(second.toLowerCase()),
    );
    return values;
  }

  int get _activeFilterCount {
    var count = 0;
    if (_selectedStatusFilter != _PayrollStatusFilter.all) count++;
    if (_selectedDepartment != null) count++;
    if (_selectedRole != null) count++;
    if (_selectedManager != null) count++;
    if (_selectedPayoutFilter != _PayrollPayoutFilter.all) count++;
    return count;
  }

  Future<void> _showPayrollFiltersSheet(List<PayrollEntry> entries) async {
    final result = await showModalBottomSheet<_PayrollFilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) {
        return _PayrollFiltersBottomSheet(
          departmentOptions: _filterOptions(entries, _entryDepartment),
          roleOptions: _filterOptions(entries, _entryRole),
          managerOptions: _filterOptions(entries, _entryManager),
          initialSelection: _PayrollFilterSelection(
            statusFilter: _selectedStatusFilter,
            department: _selectedDepartment,
            role: _selectedRole,
            manager: _selectedManager,
            payoutFilter: _selectedPayoutFilter,
          ),
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedStatusFilter = result.statusFilter;
      _selectedDepartment = result.department;
      _selectedRole = result.role;
      _selectedManager = result.manager;
      _selectedPayoutFilter = result.payoutFilter;
    });
  }

  Future<void> _downloadPayslip({
    required String payslipId,
    String? fileName,
  }) async {
    if (payslipId.trim().isEmpty ||
        _downloadingPayslipIds.contains(payslipId)) {
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
          backgroundColor: success
              ? Colors.green.shade600
              : Colors.red.shade600,
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
              style: GoogleFonts.inter(
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

    final entries = payroll?.entries ?? const <PayrollEntry>[];
    final filteredEntries = entries
        .where(
          (entry) => _matchesSearch(entry) && _matchesPayrollFilters(entry),
        )
        .toList();
    final readyCount = entries
        .where(
          (entry) => _entryStatusFilter(entry) == _PayrollStatusFilter.ready,
        )
        .length;

    final statCards = <Widget>[
      _buildStatCard(
        title: 'TOTAL NET PAYOUT',
        value: _formatCurrency(totalNetPayout.toString()),
        trend: '+2.4% trend',
        trendIcon: Icons.trending_up,
        color: const Color(0xFF2E7D32),
      ),
      _buildStatCard(
        title: 'INCENTIVES',
        value: _formatCurrency(totalIncentives.toString()),
        trend: '5.1% growth',
        trendIcon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF00A36A),
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
        value: '$readyCount/$totalEntries',
        trend: 'pending rows',
        trendIcon: Icons.pending_actions_outlined,
        color: const Color(0xFF6F5F64),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F6),
      appBar: _PayrollAppBar(
        onBackPressed: () => Navigator.of(context).maybePop(),
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
                      'Manage staff records, incentive eligibility, and\ncompensation readiness.',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        color: const Color(0xFF23201E),
                        fontWeight: FontWeight.w500,
                        height: 1.55,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      height: 36.h,
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
                          backgroundColor: const Color(0xFFD76322),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8.w),
                            Flexible(
                              child: Text(
                                'PROVISION STAFF',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: statCards.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8.h,
                        crossAxisSpacing: 8.w,
                        mainAxisExtent: 102.h,
                      ),
                      itemBuilder: (context, index) => statCards[index],
                    ),
                    SizedBox(height: 22.h),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 45.h,
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: const Color(0xFFBCC1C8),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  color: const Color(0xFF69717F),
                                  size: 22.sp,
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (value) =>
                                        setState(() => _searchQuery = value),
                                    onSubmitted: (value) =>
                                        setState(() => _searchQuery = value),
                                    textInputAction: TextInputAction.search,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search by name, email or ID...',
                                      hintStyle: GoogleFonts.inter(
                                        color: const Color(0xFF69717F),
                                        fontSize: 15.sp,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        SizedBox(
                          height: 45.h,
                          child: OutlinedButton.icon(
                            onPressed: () => _showPayrollFiltersSheet(entries),
                            icon: Icon(
                              Icons.tune_rounded,
                              color: const Color(0xFF1F1C19),
                              size: 18.sp,
                            ),
                            label: Text(
                              _activeFilterCount == 0
                                  ? 'Filters'
                                  : 'Filters ($_activeFilterCount)',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: const Color(0xFF1F1C19),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFD76322)),
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9.r),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 22.h),
                    Container(
                      height: 36.h,
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: const Color(0xFFD76322)),
                      ),
                      child: Row(
                        children: [
                          _buildTab('All', _PayrollStatusFilter.all),
                          _buildTab('Draft', _PayrollStatusFilter.draft),
                          _buildTab('Ready', _PayrollStatusFilter.ready),
                          _buildTab('Failed', _PayrollStatusFilter.failed),
                          _buildTab('Paid', _PayrollStatusFilter.paid),
                        ],
                      ),
                    ),
                    SizedBox(height: 22.h),
                    if (payroll != null && filteredEntries.isEmpty)
                      const _PayrollMessageCard(
                        message: 'No payroll rows match the selected filters.',
                      )
                    else if (payroll != null)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredEntries.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 12.h),
                        itemBuilder: (context, index) {
                          final entry = filteredEntries[index];
                          return _buildPayrollCard(
                            payslipId: entry.id,
                            name: entry.user.name,
                            role: _entryRole(entry),
                            title: _entryDesignation(entry),
                            baseSalary: _formatCurrency(entry.baseSalary),
                            attendance: '${entry.presentDays}d',
                            incentive:
                                '+${_formatCurrency(entry.incentiveAmount)}',
                            deductions:
                                '-${_formatCurrency(entry.deductionAmount)}',
                            netPayable: _formatCurrency(entry.netSalary),
                            status: _entryStatusLabel(entry),
                            image: entry.user.image,
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required String trend,
    required IconData trendIcon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 13.h, 12.w, 11.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFF0DFD7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF33302D),
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 7.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 23.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFD76322),
              height: 1,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  trend,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF35302D),
                  ),
                ),
              ),
              Icon(trendIcon, size: 18.sp, color: color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, _PayrollStatusFilter filter) {
    final isSelected = _selectedStatusFilter == filter;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedStatusFilter = filter),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFE8DE) : Colors.transparent,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: isSelected
                  ? const Color(0xFFD76322)
                  : const Color(0xFF6A5D59),
            ),
          ),
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
    String? image,
    String? payslipFileName,
    bool isDownloading = false,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 14.h, 12.w, 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
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
                  border: Border.all(color: const Color(0xFFD76322), width: 2),
                  image: DecorationImage(
                    image: _payrollImageProvider(image),
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
                            style: GoogleFonts.inter(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1D1B20),
                              height: 1.05,
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
                              border: Border.all(
                                color: const Color(0xFFEFA882),
                              ),
                            ),
                            child: Text(
                              status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF6F4C42),
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
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFD76322),
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
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0xFF1F1C19),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF7F9),
              borderRadius: BorderRadius.circular(12.r),
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
          const Divider(height: 1, color: Color(0xFFEACDC5)),
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
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E1F1F),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      netPayable,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1D1B20),
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
    final resolvedValueColor = valueColor ?? const Color(0xFF1D1B20);
    final labelColor = isAttendance
        ? const Color(0xFF43A047)
        : const Color(0xFF2F2B29);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w900,
            color: labelColor,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: 4.h),
        if (isAttendance)
          Row(
            children: [
              Container(
                width: 32.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4DDD8),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 7.w),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1D1B20),
                    height: 1,
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
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: resolvedValueColor,
              height: 1.05,
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
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: isLoading
            ? SizedBox(
                width: 16.sp,
                height: 16.sp,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E1F1F)),
                ),
              )
            : Icon(icon, size: 18.sp, color: Color(0xFF1E1F1F)),
      ),
    );
  }
}

class _PayrollAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _PayrollAppBar({required this.onBackPressed});

  final VoidCallback onBackPressed;

  @override
  Size get preferredSize => Size.fromHeight(64.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64.h,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      shadowColor: AppColors.transparent,
      leadingWidth: 54.w,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: onBackPressed,
        icon: Icon(
          Icons.arrow_back_rounded,
          color: const Color(0xFF171412),
          size: 24.sp,
        ),
      ),
      title: Text(
        'Payroll Management',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: const Color(0xFF171412),
          fontSize: 20.sp,
          fontWeight: FontWeight.w900,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Container(height: 1.h, color: const Color(0xFFE7DCD5)),
      ),
    );
  }
}

class _PayrollMessageCard extends StatelessWidget {
  const _PayrollMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFF0DFD7)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: const Color(0xFF6A5D59),
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

ImageProvider _payrollImageProvider(String? image) {
  final text = image?.trim() ?? '';
  if (text.startsWith('http')) {
    return NetworkImage(text);
  }
  if (text.startsWith('assets/')) {
    return AssetImage(text);
  }
  return const AssetImage('assets/wedding_hero 1.png');
}

enum _PayrollStatusFilter { all, draft, ready, failed, paid }

enum _PayrollPayoutFilter { all, withIncentive, withDeductions, editedNet }

class _PayrollFilterSelection {
  const _PayrollFilterSelection({
    required this.statusFilter,
    required this.department,
    required this.role,
    required this.manager,
    required this.payoutFilter,
  });

  final _PayrollStatusFilter statusFilter;
  final String? department;
  final String? role;
  final String? manager;
  final _PayrollPayoutFilter payoutFilter;
}

class _PayrollFiltersBottomSheet extends StatefulWidget {
  const _PayrollFiltersBottomSheet({
    required this.departmentOptions,
    required this.roleOptions,
    required this.managerOptions,
    required this.initialSelection,
  });

  final List<String> departmentOptions;
  final List<String> roleOptions;
  final List<String> managerOptions;
  final _PayrollFilterSelection initialSelection;

  @override
  State<_PayrollFiltersBottomSheet> createState() =>
      _PayrollFiltersBottomSheetState();
}

class _PayrollFiltersBottomSheetState
    extends State<_PayrollFiltersBottomSheet> {
  late _PayrollStatusFilter _statusFilter;
  String? _department;
  String? _role;
  String? _manager;
  late _PayrollPayoutFilter _payoutFilter;

  @override
  void initState() {
    super.initState();
    final selection = widget.initialSelection;
    _statusFilter = selection.statusFilter;
    _department = selection.department;
    _role = selection.role;
    _manager = selection.manager;
    _payoutFilter = selection.payoutFilter;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x24000000),
                blurRadius: 26,
                offset: Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(22.w, 18.h, 22.w, 18.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Filter',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF1F1C19),
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(
                                Icons.close_rounded,
                                color: const Color(0xFF5F5753),
                                size: 24.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 26.h),
                        const _PayrollFilterSectionTitle(
                          icon: Icons.flag_outlined,
                          label: 'Status',
                        ),
                        SizedBox(height: 14.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 10.h,
                          children: [
                            _PayrollFilterChip(
                              label: 'All',
                              selected:
                                  _statusFilter == _PayrollStatusFilter.all,
                              onTap: () => setState(
                                () => _statusFilter = _PayrollStatusFilter.all,
                              ),
                            ),
                            _PayrollFilterChip(
                              label: 'Draft',
                              selected:
                                  _statusFilter == _PayrollStatusFilter.draft,
                              onTap: () => setState(
                                () =>
                                    _statusFilter = _PayrollStatusFilter.draft,
                              ),
                            ),
                            _PayrollFilterChip(
                              label: 'Ready',
                              selected:
                                  _statusFilter == _PayrollStatusFilter.ready,
                              onTap: () => setState(
                                () =>
                                    _statusFilter = _PayrollStatusFilter.ready,
                              ),
                            ),
                            _PayrollFilterChip(
                              label: 'Failed',
                              selected:
                                  _statusFilter == _PayrollStatusFilter.failed,
                              onTap: () => setState(
                                () =>
                                    _statusFilter = _PayrollStatusFilter.failed,
                              ),
                            ),
                            _PayrollFilterChip(
                              label: 'Paid',
                              selected:
                                  _statusFilter == _PayrollStatusFilter.paid,
                              onTap: () => setState(
                                () => _statusFilter = _PayrollStatusFilter.paid,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30.h),
                        const _PayrollFilterSectionTitle(
                          icon: Icons.business_center_outlined,
                          label: 'Department',
                        ),
                        SizedBox(height: 12.h),
                        _PayrollFilterDropdown(
                          value: _department,
                          hintText: 'All Departments',
                          options: widget.departmentOptions,
                          onChanged: (value) =>
                              setState(() => _department = value),
                        ),
                        SizedBox(height: 28.h),
                        const _PayrollFilterSectionTitle(
                          icon: Icons.badge_outlined,
                          label: 'Role',
                        ),
                        SizedBox(height: 12.h),
                        _PayrollFilterDropdown(
                          value: _role,
                          hintText: 'All Roles',
                          options: widget.roleOptions,
                          onChanged: (value) => setState(() => _role = value),
                        ),
                        SizedBox(height: 28.h),
                        const _PayrollFilterSectionTitle(
                          icon: Icons.manage_accounts_outlined,
                          label: 'Manager',
                        ),
                        SizedBox(height: 12.h),
                        _PayrollFilterDropdown(
                          value: _manager,
                          hintText: 'All Managers',
                          options: widget.managerOptions,
                          onChanged: (value) =>
                              setState(() => _manager = value),
                        ),
                        SizedBox(height: 30.h),
                        const _PayrollFilterSectionTitle(
                          icon: Icons.payments_outlined,
                          label: 'Payout',
                        ),
                        SizedBox(height: 14.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 10.h,
                          children: [
                            _PayrollFilterChip(
                              label: 'All',
                              selected:
                                  _payoutFilter == _PayrollPayoutFilter.all,
                              onTap: () => setState(
                                () => _payoutFilter = _PayrollPayoutFilter.all,
                              ),
                            ),
                            _PayrollFilterChip(
                              label: 'With Incentive',
                              selected:
                                  _payoutFilter ==
                                  _PayrollPayoutFilter.withIncentive,
                              onTap: () => setState(
                                () => _payoutFilter =
                                    _PayrollPayoutFilter.withIncentive,
                              ),
                            ),
                            _PayrollFilterChip(
                              label: 'With Deductions',
                              selected:
                                  _payoutFilter ==
                                  _PayrollPayoutFilter.withDeductions,
                              onTap: () => setState(
                                () => _payoutFilter =
                                    _PayrollPayoutFilter.withDeductions,
                              ),
                            ),
                            _PayrollFilterChip(
                              label: 'Edited Net',
                              selected:
                                  _payoutFilter ==
                                  _PayrollPayoutFilter.editedNet,
                              onTap: () => setState(
                                () => _payoutFilter =
                                    _PayrollPayoutFilter.editedNet,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(22.w, 14.h, 22.w, 16.h),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFF0E2DA))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearFilters,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD76322),
                            side: const BorderSide(color: Color(0xFFD76322)),
                            minimumSize: Size.fromHeight(54.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'Clear All',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD76322),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: Size.fromHeight(54.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'Apply Filters',
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _clearFilters() {
    Navigator.of(context).pop(
      const _PayrollFilterSelection(
        statusFilter: _PayrollStatusFilter.all,
        department: null,
        role: null,
        manager: null,
        payoutFilter: _PayrollPayoutFilter.all,
      ),
    );
  }

  void _applyFilters() {
    Navigator.of(context).pop(
      _PayrollFilterSelection(
        statusFilter: _statusFilter,
        department: _department,
        role: _role,
        manager: _manager,
        payoutFilter: _payoutFilter,
      ),
    );
  }
}

class _PayrollFilterSectionTitle extends StatelessWidget {
  const _PayrollFilterSectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: const Color(0xFF1F1C19)),
        SizedBox(width: 8.w),
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF1F1C19),
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PayrollFilterChip extends StatelessWidget {
  const _PayrollFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          height: 38.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFD76322) : Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: const Color(0xFFD76322)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: selected ? Colors.white : const Color(0xFF1F1C19),
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _PayrollFilterDropdown extends StatelessWidget {
  const _PayrollFilterDropdown({
    required this.value,
    required this.hintText,
    required this.options,
    required this.onChanged,
  });

  final String? value;
  final String hintText;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final currentValue = options.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: const Color(0xFF71757F),
        size: 24.sp,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFFD3D3D3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFFD76322)),
        ),
      ),
      hint: Text(
        hintText,
        style: GoogleFonts.inter(
          color: const Color(0xFF1F1C19),
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      items: [
        DropdownMenuItem<String>(
          value: '',
          child: Text(
            hintText,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF1F1C19),
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...options.map(
          (option) => DropdownMenuItem<String>(
            value: option,
            child: Text(
              option,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFF1F1C19),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) =>
          onChanged(value == null || value.isEmpty ? null : value),
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
                      style: GoogleFonts.inter(
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
                style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
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
          style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
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
