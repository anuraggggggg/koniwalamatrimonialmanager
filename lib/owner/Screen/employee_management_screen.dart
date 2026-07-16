import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/owner/models/hr_employee_item.dart';
import 'package:koniwalamatrimonial/owner/providers/hr_employees_provider.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:provider/provider.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _StaffStageFilter _selectedStageFilter = _StaffStageFilter.all;
  String? _selectedDepartment;
  String? _selectedRoleFilter;
  String? _selectedManager;
  _StaffIncentiveFilter _selectedIncentiveFilter = _StaffIncentiveFilter.all;
  _StaffSalaryFilter _selectedSalaryFilter = _StaffSalaryFilter.all;
  bool _hasRequestedEmployees = false;
  String? _requestedAccessToken;
  String? _requestedRole;

  bool _canAccessEmployeeManagement(String? role) {
    final normalizedRole = role?.toUpperCase();
    return normalizedRole == 'ADMIN' || normalizedRole == 'HR';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authProvider = Provider.of<AuthProvider>(context);
    final accessToken = authProvider.userModel?.accessToken;
    final role = authProvider.userModel?.user?.role;

    if (!authProvider.isInitialized ||
        (_hasRequestedEmployees &&
            accessToken == _requestedAccessToken &&
            role == _requestedRole)) {
      return;
    }

    _hasRequestedEmployees = true;
    _requestedAccessToken = accessToken;
    _requestedRole = role;

    if (!_canAccessEmployeeManagement(role)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<HrEmployeesProvider>().fetchEmployees(accessToken);
    });
  }

  Future<void> _refreshEmployees() {
    final authProvider = context.read<AuthProvider>();
    if (!_canAccessEmployeeManagement(authProvider.userModel?.user?.role)) {
      return Future<void>.value();
    }

    final accessToken = authProvider.userModel?.accessToken;
    return context.read<HrEmployeesProvider>().fetchEmployees(
      accessToken,
      forceRefresh: true,
    );
  }

  int _highestUnlockedPercent(List<HrEmployeeItem> employees) {
    var highest = 0.0;

    for (final employee in employees) {
      if (employee.earnedPercentage > highest) {
        highest = employee.earnedPercentage;
      }
    }

    return highest.round();
  }

  String _employeeDepartment(HrEmployeeItem employee) {
    return employee.department == '-'
        ? employee.designation
        : employee.department;
  }

  String _employeeManager(HrEmployeeItem employee) {
    if (employee.reportingManagerName.trim().isEmpty ||
        employee.reportingManagerName == '-') {
      return 'Management';
    }
    return employee.reportingManagerName;
  }

  bool _matchesSearch(HrEmployeeItem employee) {
    if (_searchQuery.isEmpty) return true;
    final query = _searchQuery.toLowerCase();
    return employee.name.toLowerCase().contains(query) ||
        employee.email.toLowerCase().contains(query) ||
        employee.id.toLowerCase().contains(query) ||
        employee.phone.toLowerCase().contains(query) ||
        _employeeDepartment(employee).toLowerCase().contains(query) ||
        employee.designation.toLowerCase().contains(query) ||
        _employeeManager(employee).toLowerCase().contains(query) ||
        employee.displayRole.toLowerCase().contains(query);
  }

  bool _matchesStaffFilters(HrEmployeeItem employee) {
    switch (_selectedStageFilter) {
      case _StaffStageFilter.all:
        break;
      case _StaffStageFilter.present:
        if (!employee.isPresentToday) return false;
        break;
      case _StaffStageFilter.absent:
        if (employee.isPresentToday) return false;
        break;
      case _StaffStageFilter.active:
        if (!employee.isActive) return false;
        break;
      case _StaffStageFilter.eligible:
        if (!employee.isIncentiveEligible) return false;
        break;
    }

    if (_selectedDepartment != null &&
        _employeeDepartment(employee) != _selectedDepartment) {
      return false;
    }

    if (_selectedRoleFilter != null &&
        employee.displayRole != _selectedRoleFilter) {
      return false;
    }

    if (_selectedManager != null &&
        _employeeManager(employee) != _selectedManager) {
      return false;
    }

    switch (_selectedIncentiveFilter) {
      case _StaffIncentiveFilter.all:
        break;
      case _StaffIncentiveFilter.eligible:
        if (!employee.isIncentiveEligible) return false;
        break;
      case _StaffIncentiveFilter.notEligible:
        if (employee.isIncentiveEligible) return false;
        break;
    }

    switch (_selectedSalaryFilter) {
      case _StaffSalaryFilter.all:
        return true;
      case _StaffSalaryFilter.configured:
        return _salaryAmount(employee.baseSalary) > 0;
      case _StaffSalaryFilter.notConfigured:
        return _salaryAmount(employee.baseSalary) <= 0;
    }
  }

  num _salaryAmount(String value) {
    final normalized = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return num.tryParse(normalized) ?? 0;
  }

  List<String> _filterOptions(
    List<HrEmployeeItem> employees,
    String Function(HrEmployeeItem employee) valueForEmployee,
  ) {
    final values = employees
        .map(valueForEmployee)
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && value != '-')
        .toSet()
        .toList();
    values.sort(
      (first, second) => first.toLowerCase().compareTo(second.toLowerCase()),
    );
    return values;
  }

  int get _activeStaffFilterCount {
    var count = 0;
    if (_selectedStageFilter != _StaffStageFilter.all) count++;
    if (_selectedDepartment != null) count++;
    if (_selectedRoleFilter != null) count++;
    if (_selectedManager != null) count++;
    if (_selectedIncentiveFilter != _StaffIncentiveFilter.all) count++;
    if (_selectedSalaryFilter != _StaffSalaryFilter.all) count++;
    return count;
  }

  Future<void> _showStaffFiltersSheet(List<HrEmployeeItem> employees) async {
    final result = await showModalBottomSheet<_StaffFilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) {
        return _StaffFiltersBottomSheet(
          departmentOptions: _filterOptions(employees, _employeeDepartment),
          roleOptions: _filterOptions(
            employees,
            (employee) => employee.displayRole,
          ),
          managerOptions: _filterOptions(employees, _employeeManager),
          initialSelection: _StaffFilterSelection(
            stageFilter: _selectedStageFilter,
            department: _selectedDepartment,
            role: _selectedRoleFilter,
            manager: _selectedManager,
            incentiveFilter: _selectedIncentiveFilter,
            salaryFilter: _selectedSalaryFilter,
          ),
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedStageFilter = result.stageFilter;
      _selectedDepartment = result.department;
      _selectedRoleFilter = result.role;
      _selectedManager = result.manager;
      _selectedIncentiveFilter = result.incentiveFilter;
      _selectedSalaryFilter = result.salaryFilter;
    });
  }

  Future<void> _showEditEmployeeDialog({
    required String initialName,
    required String initialEmail,
    required String initialImage,
    String? initialDepartment,
    String? initialManager,
    String? initialIncentive,
    String? initialSalary,
    required Future<String?> Function(Map<String, dynamic> data) onSave,
  }) async {
    final nameController = TextEditingController(text: initialName);
    final emailController = TextEditingController(text: initialEmail);
    final deptController = TextEditingController(text: initialDepartment ?? '');
    final managerController = TextEditingController(text: initialManager ?? '');
    final incentiveController = TextEditingController(
      text: initialIncentive ?? '',
    );
    final salaryController = TextEditingController(text: initialSalary ?? '');
    File? pickedImage;
    bool isSaving = false;
    String? saveError;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.white,
            insetPadding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 24.h,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              'Edit Employee Details',
              style: GoogleFonts.inter(
                color: AppColors.rmPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 20.sp,
              ),
            ),
            content: SizedBox(
              width: 1.sw,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (saveError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F4),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: const Color(
                              0xFFD94A4A,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          saveError!,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFD94A4A),
                            fontWeight: FontWeight.w600,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 14.h),
                    ],
                    GestureDetector(
                      onTap: isSaving
                          ? null
                          : () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (image != null) {
                                setDialogState(() {
                                  pickedImage = File(image.path);
                                });
                              }
                            },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 45.r,
                            backgroundColor: const Color(0xFFF2E7EA),
                            backgroundImage: pickedImage != null
                                ? FileImage(pickedImage!)
                                : _employeeImageProvider(initialImage),
                            child: pickedImage == null && initialImage.isEmpty
                                ? Icon(
                                    Icons.person_outline,
                                    size: 40.sp,
                                    color: AppColors.rmPrimary,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: const BoxDecoration(
                                color: AppColors.rmPrimary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: AppColors.white,
                                size: 16.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    _buildEditField('Full Name', nameController),
                    SizedBox(height: 14.h),
                    _buildEditField('Email Address', emailController),
                    SizedBox(height: 14.h),
                    _buildEditField('Department & Role', deptController),
                    SizedBox(height: 14.h),
                    _buildEditField('Reporting Manager', managerController),
                    SizedBox(height: 14.h),
                    _buildEditField('Incentive Tier', incentiveController),
                    SizedBox(height: 14.h),
                    _buildEditField('Base Salary', salaryController),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: AppColors.rmBodyText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        setDialogState(() {
                          isSaving = true;
                          saveError = null;
                        });

                        final error = await onSave({
                          'name': nameController.text,
                          'email': emailController.text,
                          'department': deptController.text,
                          'manager': managerController.text,
                          'incentive': incentiveController.text,
                          'salary': salaryController.text,
                          'image': pickedImage,
                        });

                        if (!context.mounted) {
                          return;
                        }

                        if (error != null) {
                          setDialogState(() {
                            isSaving = false;
                            saveError = error;
                          });
                          return;
                        }

                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rmPrimary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(
                  isSaving ? 'Updating...' : 'Update Records',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 15.sp,
        color: AppColors.rmPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: AppColors.rmBodyText,
          fontWeight: FontWeight.w500,
          fontSize: 14.sp,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE5CBD5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.rmPrimary, width: 1.5),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog({
    required String employeeName,
    required VoidCallback onConfirm,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: const Color(0xFFD94A4A),
              size: 28.sp,
            ),
            SizedBox(width: 10.w),
            Text(
              'Delete Record',
              style: GoogleFonts.inter(
                color: const Color(0xFFD94A4A),
                fontWeight: FontWeight.w800,
                fontSize: 18.sp,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the records for $employeeName? This action cannot be undone.',
          style: GoogleFonts.inter(
            color: AppColors.rmBodyText,
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppColors.rmBodyText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD94A4A),
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              'Confirm Delete',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final employeesProvider = context.watch<HrEmployeesProvider>();
    final canAccessEmployeeManagement = _canAccessEmployeeManagement(
      authProvider.userModel?.user?.role,
    );
    final employees = employeesProvider.employees;
    final activeRegistry = employees.length;
    final eligibleEmployees = employees
        .where((item) => item.isIncentiveEligible)
        .length;
    final qualifiedClosures = employees.fold<int>(
      0,
      (total, item) => total + item.closedLeads,
    );
    final highestUnlockedPercent = _highestUnlockedPercent(employees);

    final filteredEmployees = employees
        .where(
          (employee) =>
              _matchesSearch(employee) && _matchesStaffFilters(employee),
        )
        .toList();

    final previewEmployees =
        _searchQuery.isEmpty && _activeStaffFilterCount == 0
        ? filteredEmployees.take(6).toList()
        : filteredEmployees;

    final registryTextScale = MediaQuery.textScalerOf(context).scale(1);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F6),
      appBar: _StaffRegistryAppBar(
        onBackPressed: () {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
            return;
          }

          navigator.pushReplacementNamed(
            canAccessEmployeeManagement
                ? AppRoutes.ownerDashboard
                : AppRoutes.hrDashboard,
          );
        },
      ),
      body: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(registryTextScale)),
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: _refreshEmployees,
            color: AppColors.rmPrimary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeaderBlock(),
                  SizedBox(height: 16.h),
                  _SearchFilterRow(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  SizedBox(height: 18.h),
                  _FilterStageHeader(
                    activeFilterCount: _activeStaffFilterCount,
                    onFilterPressed: () => _showStaffFiltersSheet(employees),
                  ),
                  SizedBox(height: 18.h),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 8.h,
                    crossAxisSpacing: 8.w,
                    childAspectRatio: 1.52,
                    children: [
                      _SummaryCard(
                        title: 'Active Registry',
                        value: '$activeRegistry',
                        subtitle: 'institutional\nworkforce',
                        trailingIcon: Icons.trending_up_rounded,
                        trailingColor: const Color(0xFF00A36A),
                      ),
                      _SummaryCard(
                        title: 'Eligible Employees',
                        value: '$eligibleEmployees',
                        subtitle: eligibleEmployees > 0
                            ? 'current cycle\nunlocked'
                            : 'awaiting cycle\nunlock',
                        trailingIcon: Icons.check_circle_outline_rounded,
                        trailingColor: const Color(0xFF00A36A),
                      ),
                      _SummaryCard(
                        title: 'Qualified Closures',
                        value: '$qualifiedClosures',
                        subtitle: '40% average\ntarget progress',
                        trailingIcon: Icons.check_circle_outline_rounded,
                        trailingColor: const Color(0xFF00A36A),
                      ),
                      _SummaryCard(
                        title: 'Earned Percentage',
                        value: '$highestUnlockedPercent%',
                        subtitle: 'highest unlocked\n$highestUnlockedPercent%',
                        trailingIcon: Icons.cancel_outlined,
                        trailingColor: const Color(0xFFE1222E),
                      ),
                    ],
                  ),
                  if (employeesProvider.isLoading) ...[
                    SizedBox(height: 12.h),
                    LinearProgressIndicator(
                      minHeight: 3.h,
                      color: AppColors.rmPrimary,
                      backgroundColor: AppColors.rmPrimary.withValues(
                        alpha: 0.12,
                      ),
                    ),
                  ],
                  SizedBox(height: 20.h),
                  Text(
                    'FOLLOW-UP CONTROL',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1F1C19),
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  if (!canAccessEmployeeManagement)
                    const _MessageCard(
                      message:
                          'Employee Management is available only for admin and HR roles.',
                    )
                  else if (employeesProvider.error != null && employees.isEmpty)
                    _MessageCard(
                      message: employeesProvider.error!,
                      actionLabel: 'Retry',
                      onPressed: _refreshEmployees,
                    )
                  else if (!employeesProvider.isLoading &&
                      previewEmployees.isEmpty)
                    const _MessageCard(
                      message: 'No employee records are available right now.',
                    )
                  else
                    Column(
                      children: [
                        for (
                          var index = 0;
                          index < previewEmployees.length;
                          index++
                        ) ...[
                          if (index > 0) SizedBox(height: 12.h),
                          _EmployeeRegistryCard(
                            employee: previewEmployees[index],
                            onEdit: () {
                              final employee = previewEmployees[index];
                              final messenger = ScaffoldMessenger.of(context);
                              _showEditEmployeeDialog(
                                initialName: employee.name,
                                initialEmail: employee.email,
                                initialImage: employee.image,
                                initialDepartment: employee.department,
                                initialManager: employee.reportingManagerName,
                                initialIncentive:
                                    employee.incentiveProgressLabel,
                                initialSalary: employee.baseSalary.toString(),
                                onSave: (data) async {
                                  final error = await context
                                      .read<HrEmployeesProvider>()
                                      .updateEmployee(
                                        employee: employee,
                                        accessToken:
                                            authProvider.userModel?.accessToken,
                                        name: data['name']?.toString() ?? '',
                                        email: data['email']?.toString() ?? '',
                                        department:
                                            data['department']?.toString() ??
                                            '',
                                        reportingManagerName:
                                            data['manager']?.toString() ?? '',
                                        incentive:
                                            data['incentive']?.toString() ?? '',
                                        baseSalary:
                                            data['salary']?.toString() ?? '',
                                        image: data['image'] is File
                                            ? data['image'] as File
                                            : null,
                                      );

                                  if (error != null) {
                                    return error;
                                  }

                                  if (!mounted) {
                                    return null;
                                  }

                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Updated ${data['name']} records.',
                                      ),
                                    ),
                                  );
                                  return null;
                                },
                              );
                            },
                            onDelete: () {
                              _showDeleteConfirmationDialog(
                                employeeName: previewEmployees[index].name,
                                onConfirm: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Deleted ${previewEmployees[index].name} records.',
                                      ),
                                      backgroundColor: const Color(0xFFD94A4A),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StaffRegistryAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _StaffRegistryAppBar({required this.onBackPressed});

  final VoidCallback onBackPressed;

  @override
  Size get preferredSize => Size.fromHeight(64.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64.h,
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.white,
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
      titleSpacing: 0,
      title: Text(
        'Staff Management Registry',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: const Color(0xFF171412),
          fontSize: 20.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Container(height: 1.h, color: const Color(0xFFE7DCD5)),
      ),
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Manage staff records, incentive eligibility, and\ncompensation readiness.',
      style: GoogleFonts.inter(
        color: const Color(0xFF23201E),
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        height: 1.55,
      ),
    );
  }
}

class _FilterStageHeader extends StatelessWidget {
  const _FilterStageHeader({
    required this.activeFilterCount,
    required this.onFilterPressed,
  });

  final int activeFilterCount;
  final VoidCallback onFilterPressed;

  @override
  Widget build(BuildContext context) {
    final label = activeFilterCount == 0
        ? 'Filters'
        : 'Filters ($activeFilterCount)';

    return Row(
      children: [
        Expanded(
          child: Text(
            'FILTER BY STAGE',
            style: GoogleFonts.inter(
              color: const Color(0xFF1F1C19),
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ),
        SizedBox(
          height: 32.h,
          child: OutlinedButton.icon(
            onPressed: onFilterPressed,
            icon: Icon(
              Icons.tune_rounded,
              color: const Color(0xFF1F1C19),
              size: 18.sp,
            ),
            label: Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFF1F1C19),
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFD76322)),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9.r),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _StaffStageFilter { all, present, absent, active, eligible }

enum _StaffIncentiveFilter { all, eligible, notEligible }

enum _StaffSalaryFilter { all, configured, notConfigured }

class _StaffFilterSelection {
  const _StaffFilterSelection({
    required this.stageFilter,
    required this.department,
    required this.role,
    required this.manager,
    required this.incentiveFilter,
    required this.salaryFilter,
  });

  final _StaffStageFilter stageFilter;
  final String? department;
  final String? role;
  final String? manager;
  final _StaffIncentiveFilter incentiveFilter;
  final _StaffSalaryFilter salaryFilter;
}

class _StaffFiltersBottomSheet extends StatefulWidget {
  const _StaffFiltersBottomSheet({
    required this.departmentOptions,
    required this.roleOptions,
    required this.managerOptions,
    required this.initialSelection,
  });

  final List<String> departmentOptions;
  final List<String> roleOptions;
  final List<String> managerOptions;
  final _StaffFilterSelection initialSelection;

  @override
  State<_StaffFiltersBottomSheet> createState() =>
      _StaffFiltersBottomSheetState();
}

class _StaffFiltersBottomSheetState extends State<_StaffFiltersBottomSheet> {
  late _StaffStageFilter _stageFilter;
  String? _department;
  String? _role;
  String? _manager;
  late _StaffIncentiveFilter _incentiveFilter;
  late _StaffSalaryFilter _salaryFilter;

  @override
  void initState() {
    super.initState();
    final selection = widget.initialSelection;
    _stageFilter = selection.stageFilter;
    _department = selection.department;
    _role = selection.role;
    _manager = selection.manager;
    _incentiveFilter = selection.incentiveFilter;
    _salaryFilter = selection.salaryFilter;
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
            color: AppColors.white,
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
                        const _StaffFilterSectionTitle(
                          icon: Icons.flag_outlined,
                          label: 'Stage',
                        ),
                        SizedBox(height: 14.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 10.h,
                          children: [
                            _StaffFilterChip(
                              label: 'All',
                              selected: _stageFilter == _StaffStageFilter.all,
                              onTap: () => setState(
                                () => _stageFilter = _StaffStageFilter.all,
                              ),
                            ),
                            _StaffFilterChip(
                              label: 'Present',
                              selected:
                                  _stageFilter == _StaffStageFilter.present,
                              onTap: () => setState(
                                () => _stageFilter = _StaffStageFilter.present,
                              ),
                            ),
                            _StaffFilterChip(
                              label: 'Absent',
                              selected:
                                  _stageFilter == _StaffStageFilter.absent,
                              onTap: () => setState(
                                () => _stageFilter = _StaffStageFilter.absent,
                              ),
                            ),
                            _StaffFilterChip(
                              label: 'Active',
                              selected:
                                  _stageFilter == _StaffStageFilter.active,
                              onTap: () => setState(
                                () => _stageFilter = _StaffStageFilter.active,
                              ),
                            ),
                            _StaffFilterChip(
                              label: 'Eligible',
                              selected:
                                  _stageFilter == _StaffStageFilter.eligible,
                              onTap: () => setState(
                                () => _stageFilter = _StaffStageFilter.eligible,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30.h),
                        const _StaffFilterSectionTitle(
                          icon: Icons.business_center_outlined,
                          label: 'Department',
                        ),
                        SizedBox(height: 12.h),
                        _StaffFilterDropdown(
                          value: _department,
                          hintText: 'All Departments',
                          options: widget.departmentOptions,
                          onChanged: (value) =>
                              setState(() => _department = value),
                        ),
                        SizedBox(height: 28.h),
                        const _StaffFilterSectionTitle(
                          icon: Icons.badge_outlined,
                          label: 'Role',
                        ),
                        SizedBox(height: 12.h),
                        _StaffFilterDropdown(
                          value: _role,
                          hintText: 'All Roles',
                          options: widget.roleOptions,
                          onChanged: (value) => setState(() => _role = value),
                        ),
                        SizedBox(height: 28.h),
                        const _StaffFilterSectionTitle(
                          icon: Icons.manage_accounts_outlined,
                          label: 'Manager',
                        ),
                        SizedBox(height: 12.h),
                        _StaffFilterDropdown(
                          value: _manager,
                          hintText: 'All Managers',
                          options: widget.managerOptions,
                          onChanged: (value) =>
                              setState(() => _manager = value),
                        ),
                        SizedBox(height: 30.h),
                        const _StaffFilterSectionTitle(
                          icon: Icons.verified_outlined,
                          label: 'Incentive',
                        ),
                        SizedBox(height: 14.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 10.h,
                          children: [
                            _StaffFilterChip(
                              label: 'All',
                              selected:
                                  _incentiveFilter == _StaffIncentiveFilter.all,
                              onTap: () => setState(
                                () => _incentiveFilter =
                                    _StaffIncentiveFilter.all,
                              ),
                            ),
                            _StaffFilterChip(
                              label: 'Eligible',
                              selected:
                                  _incentiveFilter ==
                                  _StaffIncentiveFilter.eligible,
                              onTap: () => setState(
                                () => _incentiveFilter =
                                    _StaffIncentiveFilter.eligible,
                              ),
                            ),
                            _StaffFilterChip(
                              label: 'Not Eligible',
                              selected:
                                  _incentiveFilter ==
                                  _StaffIncentiveFilter.notEligible,
                              onTap: () => setState(
                                () => _incentiveFilter =
                                    _StaffIncentiveFilter.notEligible,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30.h),
                        const _StaffFilterSectionTitle(
                          icon: Icons.payments_outlined,
                          label: 'Salary',
                        ),
                        SizedBox(height: 14.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 10.h,
                          children: [
                            _StaffFilterChip(
                              label: 'All',
                              selected: _salaryFilter == _StaffSalaryFilter.all,
                              onTap: () => setState(
                                () => _salaryFilter = _StaffSalaryFilter.all,
                              ),
                            ),
                            _StaffFilterChip(
                              label: 'Configured',
                              selected:
                                  _salaryFilter ==
                                  _StaffSalaryFilter.configured,
                              onTap: () => setState(
                                () => _salaryFilter =
                                    _StaffSalaryFilter.configured,
                              ),
                            ),
                            _StaffFilterChip(
                              label: 'Not Configured',
                              selected:
                                  _salaryFilter ==
                                  _StaffSalaryFilter.notConfigured,
                              onTap: () => setState(
                                () => _salaryFilter =
                                    _StaffSalaryFilter.notConfigured,
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
                    color: AppColors.white,
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
                              fontSize: 12.sp,
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
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            minimumSize: Size.fromHeight(54.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'Apply Filters',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
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
      const _StaffFilterSelection(
        stageFilter: _StaffStageFilter.all,
        department: null,
        role: null,
        manager: null,
        incentiveFilter: _StaffIncentiveFilter.all,
        salaryFilter: _StaffSalaryFilter.all,
      ),
    );
  }

  void _applyFilters() {
    Navigator.of(context).pop(
      _StaffFilterSelection(
        stageFilter: _stageFilter,
        department: _department,
        role: _role,
        manager: _manager,
        incentiveFilter: _incentiveFilter,
        salaryFilter: _salaryFilter,
      ),
    );
  }
}

class _StaffFilterSectionTitle extends StatelessWidget {
  const _StaffFilterSectionTitle({required this.icon, required this.label});

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

class _StaffFilterChip extends StatelessWidget {
  const _StaffFilterChip({
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
            color: selected ? const Color(0xFFD76322) : AppColors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: const Color(0xFFD76322)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: selected ? AppColors.white : const Color(0xFF1F1C19),
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _StaffFilterDropdown extends StatelessWidget {
  const _StaffFilterDropdown({
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
        fillColor: AppColors.white,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.trailingIcon,
    required this.trailingColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData trailingIcon;
  final Color trailingColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 13.h, 12.w, 11.h),
      decoration: BoxDecoration(
        color: AppColors.white,
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
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF33302D),
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            maxLines: 1,
            style: GoogleFonts.inter(
              color: const Color(0xFFD76322),
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF35302D),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Icon(trailingIcon, color: trailingColor, size: 19.sp),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchFilterRow extends StatelessWidget {
  const _SearchFilterRow({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 51.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE4DDD8)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 22.sp,
            color: const Color(0xFF555D6B),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onChanged,
              textInputAction: TextInputAction.search,
              style: GoogleFonts.inter(
                color: const Color(0xFF1F1C19),
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText:
                    'Search by name, phone, email, city, note, or\nexecutive',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF555D6B),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.15,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeRegistryCard extends StatelessWidget {
  const _EmployeeRegistryCard({
    required this.employee,
    this.onEdit,
    this.onDelete,
  });

  final HrEmployeeItem employee;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  String get _reportingLabel {
    if (employee.reportingManagerName.trim().isEmpty ||
        employee.reportingManagerName == '-') {
      return 'Management';
    }
    return employee.reportingManagerName;
  }

  String get _statusLabel {
    if (employee.isPresentToday) {
      return 'PRESENT';
    }
    return 'ABSENT';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = employee.image.isNotEmpty;
    final imageProvider = _employeeImageProvider(employee.image);
    final statusBackground = employee.isPresentToday
        ? const Color(0xFFD8F8E3)
        : const Color(0xFFFFDFE4);
    final statusForeground = employee.isPresentToday
        ? const Color(0xFF188748)
        : const Color(0xFFD1213E);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8.w, 10.h, 8.w, 10.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5D8D0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(20.r),
                child: CircleAvatar(
                  radius: 20.r,
                  backgroundColor: const Color(0xFFDDF4E7),
                  backgroundImage: imageProvider,
                  child: hasImage
                      ? null
                      : Text(
                          employee.initials,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF1E5D47),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            employee.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF1F1C19),
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 9.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: statusBackground,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            _statusLabel,
                            style: GoogleFonts.inter(
                              color: statusForeground,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      employee.email == '-'
                          ? 'employee@koniwala.in'
                          : employee.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1F1C19),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tight(Size(28.w, 28.w)),
                icon: Icon(
                  Icons.edit_outlined,
                  color: const Color(0xFF5B3531),
                  size: 18.sp,
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tight(Size(28.w, 28.w)),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: const Color(0xFF5B3531),
                  size: 18.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Divider(height: 1.h, color: const Color(0xFFF0E5DF)),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _EmployeeInfoBlock(
                  title: 'Dept & Role',
                  value:
                      '${employee.department == '-' ? employee.designation : employee.department} • ${employee.displayRole}',
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: _EmployeeInfoBlock(
                  title: 'Manager',
                  value: _reportingLabel,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _EmployeeInfoBlock(
                  title: 'Incentive',
                  value: employee.incentiveProgressLabel,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: _EmployeeInfoBlock(
                  title: 'Base Salary',
                  value: _formatDirectorySalary(employee.baseSalary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmployeeInfoBlock extends StatelessWidget {
  const _EmployeeInfoBlock({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: const Color(0xFF5E5A63),
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: const Color(0xFF1F1C19),
            fontSize: 14.sp,
            fontWeight: FontWeight.w900,
            height: 1.08,
          ),
        ),
      ],
    );
  }
}

String _formatDirectorySalary(String value) {
  var text = value.trim();
  if (text.isEmpty || text == '-') {
    return '₹0';
  }

  if (text.startsWith('₹')) {
    return text;
  }

  final withoutPrefix = text
      .replaceFirst(RegExp(r'^(Rs\.?|INR)\s*', caseSensitive: false), '')
      .replaceFirst(RegExp(r'^[^0-9-]+'), '')
      .trim();
  if (withoutPrefix.isNotEmpty) {
    text = withoutPrefix;
  }

  return '₹$text';
}

ImageProvider? _employeeImageProvider(String image) {
  final text = image.trim();
  if (text.isEmpty) {
    return null;
  }

  if (text.startsWith('http')) {
    return NetworkImage(text);
  }

  if (text.startsWith('assets/')) {
    return AssetImage(text);
  }

  final file = File(text);
  if (file.existsSync()) {
    return FileImage(file);
  }

  if (text.startsWith('/')) {
    final apiOrigin = ApiConstants.baseUrl.replaceFirst('/api/v1', '');
    return NetworkImage('$apiOrigin$text');
  }

  return null;
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.actionLabel, this.onPressed});

  final String message;
  final String? actionLabel;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: GoogleFonts.inter(
              color: AppColors.rmBodyText,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (actionLabel != null && onPressed != null) ...[
            SizedBox(height: 10.h),
            SizedBox(
              height: 38.h,
              child: ElevatedButton(
                onPressed: () => onPressed!(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rmPrimary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
