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
import 'package:koniwalamatrimonial/widgets/koniwala_primary_app_bar.dart';
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
              style: GoogleFonts.manrope(
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
                          style: GoogleFonts.manrope(
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
                  style: GoogleFonts.manrope(
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
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
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
      style: GoogleFonts.manrope(
        fontWeight: FontWeight.w600,
        fontSize: 15.sp,
        color: AppColors.rmPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.manrope(
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
              style: GoogleFonts.manrope(
                color: const Color(0xFFD94A4A),
                fontWeight: FontWeight.w800,
                fontSize: 18.sp,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the records for $employeeName? This action cannot be undone.',
          style: GoogleFonts.manrope(
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
              style: GoogleFonts.manrope(
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
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  List<_EmployeeDirectoryEntry> _buildDirectoryEntries(
    List<HrEmployeeItem> employees,
  ) {
    if (employees.isNotEmpty) {
      return employees
          .take(6)
          .map(_EmployeeDirectoryEntry.fromEmployee)
          .toList();
    }

    return _EmployeeDirectoryEntry.fallbackEntries;
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
    final employeesWithClosures = employees
        .where((item) => item.closedLeads > 0)
        .length;
    final highestUnlockedPercent = _highestUnlockedPercent(employees);

    final filteredEmployees = employees.where((employee) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return employee.name.toLowerCase().contains(query) ||
          employee.email.toLowerCase().contains(query) ||
          employee.id.toLowerCase().contains(query);
    }).toList();

    final previewEmployees = _searchQuery.isEmpty
        ? filteredEmployees.take(6).toList()
        : filteredEmployees;

    final headerEmployee = employeesProvider.findEmployee(
      userId: authProvider.userModel?.user?.id,
      role: authProvider.userModel?.user?.role,
    );
    final directoryEntries = canAccessEmployeeManagement
        ? _buildDirectoryEntries(employees)
        : const <_EmployeeDirectoryEntry>[];
    final registryTextScale = MediaQuery.textScalerOf(context).scale(1) * 1.1;

    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      appBar: KoniwalaPrimaryAppBar(
        showMenuButton: true,
        showActions: false,
        onMenuPressed: () {
          final navigator = Navigator.of(context);
          if (canAccessEmployeeManagement) {
            navigator.pushNamed(AppRoutes.adminDrawer);
            return;
          }

          if (navigator.canPop()) {
            navigator.pop();
            return;
          }

          navigator.pushReplacementNamed(AppRoutes.hrDashboard);
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
              padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderBlock(employee: headerEmployee),
                  SizedBox(height: 22.h),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12.h,
                    crossAxisSpacing: 12.w,
                    childAspectRatio: 1.05,
                    children: [
                      _SummaryCard(
                        title: 'Active Registry',
                        value: '$activeRegistry',
                        subtitle: 'Institutional workforce',
                        accentColor: const Color(0xFFE5358B),
                      ),
                      _SummaryCard(
                        title: 'Eligible Employees',
                        value: '$eligibleEmployees',
                        subtitle: eligibleEmployees > 0
                            ? 'Current cycle unlocked'
                            : 'Awaiting cycle unlock',
                        accentColor: const Color(0xFF2D79D7),
                      ),
                      _SummaryCard(
                        title: 'Qualified Closures',
                        value: '$qualifiedClosures',
                        subtitle: employeesWithClosures > 0
                            ? '$employeesWithClosures employees with closures'
                            : 'No closures recorded',
                        accentColor: const Color(0xFF1E9B74),
                      ),
                      _SummaryCard(
                        title: 'Earned Percentage',
                        value: '$highestUnlockedPercent',
                        subtitle: 'Highest unlocked $highestUnlockedPercent%',
                        accentColor: const Color(0xFFF2B82F),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _SearchFilterRow(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
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

                                  ScaffoldMessenger.of(context).showSnackBar(
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
                  if (canAccessEmployeeManagement) ...[
                    SizedBox(height: 20.h),
                    _TemplateDirectorySection(
                      entries: directoryEntries,
                      onEdit: (entry) {
                        HrEmployeeItem? employee;
                        for (final item in employeesProvider.employees) {
                          if (item.id == entry.employeeId) {
                            employee = item;
                            break;
                          }
                        }

                        if (employee == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Employee id is missing.'),
                            ),
                          );
                          return;
                        }

                        final selectedEmployee = employee;
                        _showEditEmployeeDialog(
                          initialName: selectedEmployee.name,
                          initialEmail: selectedEmployee.email,
                          initialImage: selectedEmployee.image,
                          initialDepartment: selectedEmployee.department,
                          initialManager: selectedEmployee.reportingManagerName,
                          initialIncentive:
                              selectedEmployee.incentiveProgressLabel,
                          initialSalary: selectedEmployee.baseSalary,
                          onSave: (data) async {
                            final error = await context
                                .read<HrEmployeesProvider>()
                                .updateEmployee(
                                  employee: selectedEmployee,
                                  accessToken:
                                      authProvider.userModel?.accessToken,
                                  name: data['name']?.toString() ?? '',
                                  email: data['email']?.toString() ?? '',
                                  department:
                                      data['department']?.toString() ?? '',
                                  reportingManagerName:
                                      data['manager']?.toString() ?? '',
                                  incentive:
                                      data['incentive']?.toString() ?? '',
                                  baseSalary: data['salary']?.toString() ?? '',
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

                            ScaffoldMessenger.of(context).showSnackBar(
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
                      onDelete: (entry) {
                        _showDeleteConfirmationDialog(
                          employeeName: entry.name,
                          onConfirm: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Deleted ${entry.name} records.'),
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
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock({this.employee});

  final HrEmployeeItem? employee;

  @override
  Widget build(BuildContext context) {
    final hasImage = employee != null && employee!.image.isNotEmpty;
    final imageProvider = employee == null
        ? null
        : _employeeImageProvider(employee!.image);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18.r,
          backgroundColor: const Color(0xFFF2E7EA),
          backgroundImage: imageProvider,
          child: hasImage
              ? null
              : Icon(
                  Icons.badge_outlined,
                  color: AppColors.rmPrimary,
                  size: 18.sp,
                ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Staff Management\nRegistry',
                style: GoogleFonts.manrope(
                  color: AppColors.rmPrimary,
                  fontSize: 27.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Manage staff records, incentive eligibility, and compensation readiness.',
                style: GoogleFonts.manrope(
                  color: AppColors.rmBodyText,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.rmCardShadow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4.h,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      color: AppColors.rmBodyText,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: GoogleFonts.manrope(
                      color: AppColors.rmHeading,
                      fontSize: 33.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      color: accentColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
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
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFD5CCD1)),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 22.sp, color: AppColors.rmMutedText),
                SizedBox(width: 10.w),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    onSubmitted: onChanged,
                    textInputAction: TextInputAction.search,
                    style: GoogleFonts.manrope(
                      color: AppColors.rmPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by name, email or ID...',
                      hintStyle: GoogleFonts.manrope(
                        color: AppColors.rmMutedText,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
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
        SizedBox(width: 8.w),
        Container(
          height: 44.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFD5CCD1)),
          ),
          child: Row(
            children: [
              Icon(Icons.filter_list, size: 18.sp, color: AppColors.rmPrimary),
              SizedBox(width: 6.w),
              Text(
                'Filters',
                style: GoogleFonts.manrope(
                  color: AppColors.rmPrimary,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
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
      return 'Active Today';
    }
    if (employee.isActive) {
      return 'Available';
    }
    return 'Offline Today';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = employee.image.isNotEmpty;
    final imageProvider = _employeeImageProvider(employee.image);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.rmCardShadow,
            blurRadius: 14,
            offset: Offset(0, 6),
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
                  backgroundColor: const Color(0xFFF2E7EA),
                  backgroundImage: imageProvider,
                  child: hasImage
                      ? null
                      : Text(
                          employee.initials,
                          style: GoogleFonts.manrope(
                            color: AppColors.rmPrimary,
                            fontSize: 16.sp,
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
                    Text(
                      employee.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: AppColors.rmPrimary,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      employee.displayRole.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: AppColors.rmBodyText,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onEdit,
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2E7EA),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 18.sp,
                        color: AppColors.rmPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  InkWell(
                    onTap: onDelete,
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F4),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18.sp,
                        color: const Color(0xFFD94A4A),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _EmployeeInfoBox(
                  title: 'Reporting To',
                  value: _reportingLabel,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _EmployeeInfoBox(title: 'Status', value: _statusLabel),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _EmployeeInfoBox(
                  title: 'Department',
                  value: employee.department == '-'
                      ? employee.designation
                      : employee.department,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _EmployeeInfoBox(
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

class _EmployeeInfoBox extends StatelessWidget {
  const _EmployeeInfoBox({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8FA),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: AppColors.rmBodyText,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: AppColors.rmPrimary,
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeDirectoryEntry {
  const _EmployeeDirectoryEntry({
    required this.employeeId,
    required this.name,
    required this.email,
    required this.statusLabel,
    required this.isPresent,
    required this.departmentRole,
    required this.manager,
    required this.incentive,
    required this.baseSalary,
    required this.initials,
    this.image = '',
  });

  final String employeeId;
  final String name;
  final String email;
  final String statusLabel;
  final bool isPresent;
  final String departmentRole;
  final String manager;
  final String incentive;
  final String baseSalary;
  final String initials;
  final String image;

  bool get hasImage => image.isNotEmpty;

  factory _EmployeeDirectoryEntry.fromEmployee(HrEmployeeItem employee) {
    return _EmployeeDirectoryEntry(
      employeeId: employee.id,
      name: employee.name,
      email: employee.email == '-' ? 'employee@koniwala.in' : employee.email,
      statusLabel: employee.isPresentToday ? 'PRESENT' : 'ABSENT',
      isPresent: employee.isPresentToday,
      departmentRole: _buildDepartmentRole(employee),
      manager: employee.reportingManagerName == '-'
          ? 'Management'
          : employee.reportingManagerName,
      incentive: employee.incentiveProgressLabel,
      baseSalary: _formatDirectorySalary(employee.baseSalary),
      initials: employee.initials,
      image: employee.image,
    );
  }

  static String _buildDepartmentRole(HrEmployeeItem employee) {
    final department = employee.department == '-'
        ? employee.designation
        : employee.department;
    return '$department - ${employee.displayRole}';
  }

  static const fallbackEntries = [
    _EmployeeDirectoryEntry(
      employeeId: '',
      name: 'Alok Agrawal',
      email: 'admin@koniwala.in',
      statusLabel: 'PRESENT',
      isPresent: true,
      departmentRole: 'Executive - Admin',
      manager: 'Management',
      incentive: 'N/A',
      baseSalary: 'Rs 0',
      initials: 'AA',
    ),
    _EmployeeDirectoryEntry(
      employeeId: '',
      name: 'Amit Singh',
      email: 'data@koniwala.in',
      statusLabel: 'PRESENT',
      isPresent: true,
      departmentRole: 'Data Systems - Data Entry',
      manager: 'Sanjay Sharma',
      incentive: 'N/A',
      baseSalary: 'Rs 33,000',
      initials: 'AS',
    ),
    _EmployeeDirectoryEntry(
      employeeId: '',
      name: 'Ishika Bafna',
      email: 'payroll.support@koniwala.in',
      statusLabel: 'ABSENT',
      isPresent: false,
      departmentRole: 'Member Support - Data Entry',
      manager: 'Megha Jain',
      incentive: 'N/A',
      baseSalary: 'Rs 31,000',
      initials: 'IB',
    ),
    _EmployeeDirectoryEntry(
      employeeId: '',
      name: 'Jane Sharma',
      email: 'jane@koniwala.in',
      statusLabel: 'ABSENT',
      isPresent: false,
      departmentRole: 'Sales - Relationship Manager',
      manager: 'Management',
      incentive: '0/5',
      baseSalary: 'Rs 0',
      initials: 'JS',
    ),
  ];
}

String _formatDirectorySalary(String value) {
  var text = value.trim();
  if (text.isEmpty || text == '-') {
    return 'Rs 0';
  }

  if (text.startsWith('Rs ')) {
    return text;
  }

  final withoutPrefix = text.replaceFirst(RegExp(r'^[^0-9-]+'), '').trim();
  if (withoutPrefix.isNotEmpty) {
    text = withoutPrefix;
  }

  return 'Rs $text';
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

class _TemplateDirectorySection extends StatelessWidget {
  const _TemplateDirectorySection({
    required this.entries,
    this.onEdit,
    this.onDelete,
  });

  final List<_EmployeeDirectoryEntry> entries;
  final Function(_EmployeeDirectoryEntry)? onEdit;
  final Function(_EmployeeDirectoryEntry)? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Template Directory',
                style: GoogleFonts.manrope(
                  color: AppColors.rmPrimary,
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              'Showing ${entries.length} entries',
              style: GoogleFonts.manrope(
                color: AppColors.rmBodyText,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Column(
          children: [
            for (var index = 0; index < entries.length; index++) ...[
              if (index > 0) SizedBox(height: 12.h),
              _TemplateDirectoryCard(
                entry: entries[index],
                onEdit: onEdit != null ? () => onEdit!(entries[index]) : null,
                onDelete: onDelete != null
                    ? () => onDelete!(entries[index])
                    : null,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _TemplateDirectoryCard extends StatelessWidget {
  const _TemplateDirectoryCard({
    required this.entry,
    this.onEdit,
    this.onDelete,
  });

  final _EmployeeDirectoryEntry entry;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final imageProvider = _employeeImageProvider(entry.image);
    final statusBackground = entry.isPresent
        ? const Color(0xFFE8F7EA)
        : const Color(0xFFFFE5E5);
    final statusForeground = entry.isPresent
        ? const Color(0xFF2E8B57)
        : const Color(0xFFD94A4A);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.rmCardShadow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(20.r),
                child: CircleAvatar(
                  radius: 20.r,
                  backgroundColor: const Color(0xFFF2E7EA),
                  backgroundImage: imageProvider,
                  child: entry.hasImage
                      ? null
                      : Text(
                          entry.initials,
                          style: GoogleFonts.manrope(
                            color: AppColors.rmPrimary,
                            fontSize: 15.sp,
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
                            entry.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              color: AppColors.rmHeading,
                              fontSize: 19.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: statusBackground,
                            borderRadius: BorderRadius.circular(999.r),
                          ),
                          child: Text(
                            entry.statusLabel,
                            style: GoogleFonts.manrope(
                              color: statusForeground,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      entry.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: AppColors.rmBodyText,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onEdit,
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16.sp,
                      color: AppColors.rmBodyText,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  InkWell(
                    onTap: onDelete,
                    child: Icon(
                      Icons.delete_outline,
                      size: 16.sp,
                      color: const Color(0xFFD94A4A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(color: const Color(0xFFF0E5E8), height: 1.h),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DirectoryInfoItem(
                  title: 'Department & Role',
                  value: entry.departmentRole,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: _DirectoryInfoItem(
                  title: 'Manager',
                  value: entry.manager,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DirectoryInfoItem(
                  title: 'Incentive',
                  value: entry.incentive,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: _DirectoryInfoItem(
                  title: 'Base Salary',
                  value: entry.baseSalary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DirectoryInfoItem extends StatelessWidget {
  const _DirectoryInfoItem({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            color: AppColors.rmBodyText,
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          style: GoogleFonts.manrope(
            color: AppColors.rmHeading,
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
        ),
      ],
    );
  }
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
            style: GoogleFonts.manrope(
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
                  style: GoogleFonts.manrope(
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
