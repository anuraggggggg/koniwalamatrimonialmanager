import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/models/user_model.dart';
import 'package:koniwalamatrimonial/owner/models/hr_employee_item.dart';
import 'package:koniwalamatrimonial/owner/providers/hr_employees_provider.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/providers/settings_provider.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_colors.dart';
import '../providers/app_flow_provider.dart';
import '../providers/dashboard_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _profileNumberColor = AppColors.primary;

  String _resolvedText(String? value, String fallback) {
    final text = value?.trim() ?? '';
    if (text.isEmpty || text == '-') {
      return fallback;
    }
    return text;
  }

  String _formatRoleLabel(String? role) {
    final text = _resolvedText(role, 'Employee');
    return text
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) {
          final lower = part.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  String _formatIsoDate(String? value) {
    final date = DateTime.tryParse(value ?? '')?.toLocal();
    if (date == null) {
      return '-';
    }

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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _displayName(HrEmployeeItem? employee, User? user) {
    return _resolvedText(employee?.name, _resolvedText(user?.name, 'Employee'));
  }

  String _displayEmail(HrEmployeeItem? employee, User? user) {
    return _resolvedText(employee?.email, _resolvedText(user?.email, '-'));
  }

  String _displayDepartment(HrEmployeeItem? employee, User? user) {
    return _resolvedText(
      employee?.department,
      _resolvedText(user?.department, 'Koniwala'),
    );
  }

  String _displayDesignation(HrEmployeeItem? employee, User? user) {
    return _resolvedText(employee?.designation, _formatRoleLabel(user?.role));
  }

  String _displayTier(HrEmployeeItem? employee) {
    return _resolvedText(employee?.incentiveTierLabel, 'Active Employee');
  }

  String _displayJoinedText(HrEmployeeItem? employee, User? user) {
    if (employee != null && employee.joiningDateText != '-') {
      return employee.tenureText;
    }
    return _formatIsoDate(user?.createdAt);
  }

  HrEmployeeItem? _findEmployeeById(
    List<HrEmployeeItem> employees,
    String? userId,
  ) {
    if (userId == null || userId.isEmpty) {
      return null;
    }

    for (final employee in employees) {
      if (employee.id == userId) {
        return employee;
      }
    }

    return null;
  }

  Future<void> _shareProfile(HrEmployeeItem? employee) async {
    if (employee == null) return;
    final message =
        '''
Employee Profile Details:
Name: ${employee.name}
Designation: ${employee.designation}
Phone: ${employee.phone}
Email: ${employee.email}
''';
    final url = 'whatsapp://send?text=${Uri.encodeComponent(message)}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not share via WhatsApp')),
        );
      }
    }
  }

  Future<void> _callEmployee(HrEmployeeItem? employee, User? user) async {
    final rawPhone = _resolvedText(
      employee?.phone,
      _resolvedText(user?.phone, ''),
    );
    final cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number not available.')),
        );
      }
      return;
    }

    final normalizedPhone = cleanPhone.length == 10
        ? '91$cleanPhone'
        : cleanPhone;
    final uri = Uri(scheme: 'tel', path: normalizedPhone);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone dialer is not available.')),
      );
    }
  }

  void _openAllActivity(HrEmployeeItem? employee, User? user) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _EmployeeActivityScreen(
          employeeName: _displayName(employee, user),
          displayRole: employee?.displayRole ?? _formatRoleLabel(user?.role),
          department: _displayDepartment(employee, user),
          joinedText: _displayJoinedText(employee, user),
          assignedLeads: employee?.assignedLeads ?? 0,
          assignedTasks: employee?.assignedTasks ?? 0,
          dataEntryProfiles: employee?.dataEntryProfiles ?? 0,
          closedLeads: employee?.closedLeads ?? 0,
          isPresentToday: employee?.isPresentToday ?? false,
          isActive: employee?.isActive ?? true,
          payrollConfigured: employee?.payrollEnabled ?? false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel?.user;
    final employeesProvider = context.watch<HrEmployeesProvider>();
    final employee = _findEmployeeById(employeesProvider.employees, user?.id);
    final profileTextScale = settings.fontSizeFactor * 1.15;

    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.deepBurgundy),
          onPressed: () => context.read<DashboardProvider>().selectTab(0),
        ),
        title: Text(
          'Employee Profile',
          style: GoogleFonts.manrope(
            color: AppColors.hrText,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            height: 1.4.h,
            letterSpacing: 0,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: SizedBox(
              height: 40.h,
              width: 40.w,
              child: IconButton(
                onPressed: () => _shareProfile(employee),
                padding: EdgeInsets.all(8.r),
                icon: Image.asset(
                  'assets/share_icon.png',
                  width: 22.w,
                  height: 22.h,
                ),
              ),
            ),
          ),
        ],
      ),
      body: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(profileTextScale)),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileHeader(employee, user),
              _sectionGap(),
              _buildStatsGrid(employee),
              _sectionGap(),
              _buildManagersNote(employee, user),
              _sectionGap(),
              _buildEmployeeDetails(employee, user),
              _sectionGap(),
              _buildRecentActivity(employee, user),
              _sectionGap(),
              _buildActionSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionGap() => SizedBox(height: 16.h);

  BoxDecoration _cardDecoration(Color color, {bool useRoseCard = false}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(color: const Color(0xFFF6E5DB)),
      boxShadow: useRoseCard
          ? const [
              BoxShadow(
                color: AppColors.hrBackground,
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ]
          : [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.03),
                blurRadius: 12.r,
                offset: Offset(0, 4.h),
              ),
            ],
    );
  }

  Widget _buildSectionCard({
    required Widget child,
    Color color = AppColors.white,
    bool useRoseCard = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: _cardDecoration(color, useRoseCard: useRoseCard),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        color: AppColors.rmHeading,
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
    );
  }

  Widget _buildProfileHeader(HrEmployeeItem? employee, User? user) {
    final present = employee?.isPresentToday ?? true;
    final statusColor = present ? AppColors.success : AppColors.danger;
    final statusBackground = present
        ? AppColors.successContainer
        : AppColors.dangerContainer;

    return _buildSectionCard(
      useRoseCard: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      employee?.statusLabel ?? 'PRESENT',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        color: statusColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_vert, color: AppColors.slateGray, size: 20.sp),
            ],
          ),
          SizedBox(height: 16.h),
          Stack(
            children: [
              Container(
                padding: EdgeInsets.all(4.r), // Gap between gradient border and image
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF780037), // Deep Burgundy
                      Color(0xFFFED65B), // Gold
                    ],
                    stops: [0.4087, 1.0], // 40.87%, 100%
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.all(4.r), // Controls border thickness
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: CircleAvatar(
                    radius: 45.r,
                    backgroundImage: employee != null && employee.image.isNotEmpty
                        ? NetworkImage(employee.image)
                        : const AssetImage('assets/app.logo.png') as ImageProvider,
                  ),
                ),
              ),
              Positioned(
                right: 5.w,
                bottom: 5.h,
                child: Container(
                  width: 18.r,
                  height: 18.r,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2.w),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            _displayName(employee, user),
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: AppColors.rmHeading,
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _displayDesignation(employee, user),
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: AppColors.rmBodyText,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            _displayTier(employee),
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: AppColors.rmMutedText,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildContactButton(
                'assets/call_icon.png',
                const Color(0x1A780037),
                onTap: () => _callEmployee(employee, user),
              ),
              SizedBox(width: 16.w),
              _buildContactButton(
                'assets/chat_icon.png',
                const Color(0x1A780037),
                onTap: () => _shareProfile(employee),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(
    String imagePath,
    Color color, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 48.r,
        height: 48.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Image.asset(
          imagePath,
          width: 18.w,
          height: 18.h,
          color: AppColors.deepBurgundy,
        ),
      ),
    );
  }

  Widget _buildStatsGrid(HrEmployeeItem? employee) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Leads',
                  '${employee?.assignedLeads ?? 0}',
                  trend: employee?.isActive == true ? 'Active' : null,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  'Profiles',
                  '${employee?.dataEntryProfiles ?? 0}',
                  hasChart: false,
                  iconAsset: "assets/margin.png"
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildStatCard(
                  'Tasks',
                  '${employee?.assignedTasks ?? 0}',
                  iconAsset: 'assets/call_icon.png',
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  'Closed Leads',
                  '${employee?.closedLeads ?? 0}',
                  iconAsset: 'assets/medal_icon.png',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value, {
    String? trend,
    bool hasChart = false,
    IconData? icon,
    String? iconAsset,
    IconData? badge,
  }) {
    Widget? trailing;

    if (trend != null) {
      trailing = Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: AppColors.successContainer,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Text(
          trend,
          style: GoogleFonts.manrope(
            color: AppColors.success,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (hasChart) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Bar(height: 10.h),
          SizedBox(width: 2.w),
          _Bar(height: 15.h),
          SizedBox(width: 2.w),
          _Bar(height: 8.h),
          SizedBox(width: 2.w),
          _Bar(height: 20.h, isPrimary: true),
        ],
      );
     } else if (iconAsset != null) {
  double width = 24.w;
  double height = 24.h;
  EdgeInsets padding = EdgeInsets.zero;

  if (iconAsset == 'assets/margin.png') {
  width = 48.w;
  height = 20.h;
  padding = EdgeInsets.only(bottom: 4.h);
  }

  trailing = Padding(
  padding: padding,
  child: Image.asset(
  iconAsset,
  width: width,
  height: height,
  fit: BoxFit.contain,
  ),
  );
  }

    else if (icon != null) {
      trailing = Icon(icon, color: AppColors.primary, size: 20.sp);
    } else if (badge != null) {
      trailing = Icon(badge, color: AppColors.accent, size: 20.sp);
    }

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 88.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        // border: Border.all(color: const Color(0xFFF6E5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: Color(0xFF424754),
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(

                    color: AppColors.black,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
              if (trailing != null) SizedBox(width: 8.w),
              ?trailing,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManagersNote(HrEmployeeItem? employee, User? user) {
    final managerName = _resolvedText(
      employee?.reportingManagerName,
      'Koniwala Leadership',
    );
    final displayName = _displayName(employee, user);
    final department = _displayDepartment(employee, user);

    return _buildSectionCard(
      color: AppColors.deepBurgundy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "MANAGER'S NOTE",
            style: GoogleFonts.manrope(
              color: AppColors.white.withValues(alpha: 0.7),
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              height: 1.4,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            '"$displayName is part of the $department team and contributes to daily matrimonial operations."',
            style: GoogleFonts.manrope(
              color: AppColors.white,
              fontSize: 14.sp,
              height: 1.5,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              CircleAvatar(
                radius: 12.r,
                backgroundImage: const AssetImage('assets/wedding_hero 1.png'),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  '$managerName, Reporting Manager',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: AppColors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeDetails(HrEmployeeItem? employee, User? user) {
    return _buildSectionCard(
      useRoseCard: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Employee Details'),
          SizedBox(height: 20.h),
          _buildDetailRow(
            'assets/card_profile_icon.png',
            'EMPLOYEE ID',
            _resolvedText(employee?.id, _resolvedText(user?.id, '-')),
          ),
          _buildDetailRow(
            'assets/email_address.png',
            'EMAIL ADDRESS',
            _displayEmail(employee, user),
          ),
          _buildDetailRow(
            'assets/date_right_icon.png',
            'DATE JOINED',
            _displayJoinedText(employee, user),
          ),
          _buildDetailRow(
            'assets/location_icon.png',
            'DEPARTMENT',
            _displayDepartment(employee, user),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    dynamic leading,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 18.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: leading is IconData
                ? Icon(leading, color: AppColors.black, size: 18.sp)
                : Image.asset(
                    leading.toString(),
                    width: 18.w,
                    height: 18.h,
                    color: AppColors.black,
                  ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    color: AppColors.rmMutedText,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    color: AppColors.rmHeading,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(HrEmployeeItem? employee, User? user) {
    final displayRole = employee?.displayRole ?? _formatRoleLabel(user?.role);
    final department = _displayDepartment(employee, user);
    final payrollConfigured = employee != null
        ? employee.baseSalary != '-'
        : false;

    return _buildSectionCard(
      useRoseCard: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Recent Activity'),
          SizedBox(height: 20.h),
          _buildActivityItem(
            AppColors.success,
            'Assigned Leads: ${employee?.assignedLeads ?? 0}',
            '$displayRole workspace',
          ),
          _buildActivityItem(
            AppColors.primary,
            'Assigned Tasks: ${employee?.assignedTasks ?? 0}',
            department,
          ),
          _buildActivityItem(
            AppColors.accent,
            'Data Entry Profiles: ${employee?.dataEntryProfiles ?? 0}',
            'Payroll ${payrollConfigured ? 'configured' : 'not configured'}',
            isLast: true,
          ),
          SizedBox(height: 20.h),
          Center(
            child: TextButton(
              onPressed: () => _openAllActivity(employee, user),
              child: Text(
                'VIEW ALL ACTIVITY',
                style: GoogleFonts.manrope(
                  color: AppColors.deepBurgundy,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    Color color,
    String title,
    String subtitle, {
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28.w,
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 6.h),
                  width: 8.r,
                  height: 8.r,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 1, color: AppColors.rmAvatarGrey),
                  ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      color: AppColors.rmHeading,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      color: AppColors.rmMutedText,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
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



  Widget _buildActionSection(BuildContext context) {
    return _buildActionButtons(context);
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48.h,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.employeeManagement);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.deepBurgundy,
                side: BorderSide(
                  color: AppColors.deepBurgundy,
                  width: 1.5,
                ),
                backgroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                'Edit Profile',
                style: GoogleFonts.manrope(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: SizedBox(
            height: 48.h,
            child: ElevatedButton(
              onPressed: () {
                context.read<DashboardProvider>().reset();
                context.read<AppFlowProvider>().logout();
                final authProvider = context.read<AuthProvider>();
                authProvider.logout();

                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepBurgundy,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.manrope(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmployeeActivityScreen extends StatelessWidget {
  const _EmployeeActivityScreen({
    required this.employeeName,
    required this.displayRole,
    required this.department,
    required this.joinedText,
    required this.assignedLeads,
    required this.assignedTasks,
    required this.dataEntryProfiles,
    required this.closedLeads,
    required this.isPresentToday,
    required this.isActive,
    required this.payrollConfigured,
  });

  final String employeeName;
  final String displayRole;
  final String department;
  final String joinedText;
  final int assignedLeads;
  final int assignedTasks;
  final int dataEntryProfiles;
  final int closedLeads;
  final bool isPresentToday;
  final bool isActive;
  final bool payrollConfigured;

  @override
  Widget build(BuildContext context) {
    final activities = <_EmployeeActivityData>[
      _EmployeeActivityData(
        icon: Icons.group_outlined,
        color: AppColors.success,
        title: 'Assigned Leads',
        value: '$assignedLeads',
        subtitle: displayRole,
      ),
      _EmployeeActivityData(
        icon: Icons.task_alt_outlined,
        color: AppColors.primary,
        title: 'Assigned Tasks',
        value: '$assignedTasks',
        subtitle: department,
      ),
      _EmployeeActivityData(
        icon: Icons.person_add_alt_1_outlined,
        color: AppColors.accent,
        title: 'Data Entry Profiles',
        value: '$dataEntryProfiles',
        subtitle: 'Profiles created by the employee',
      ),
      _EmployeeActivityData(
        icon: Icons.handshake_outlined,
        color: AppColors.success,
        title: 'Closed Leads',
        value: '$closedLeads',
        subtitle: 'Successfully closed leads',
      ),
      _EmployeeActivityData(
        icon: Icons.event_available_outlined,
        color: isPresentToday ? AppColors.success : AppColors.accent,
        title: 'Today\'s Attendance',
        value: isPresentToday ? 'Present' : 'Absent',
        subtitle: 'Current attendance status',
      ),
      _EmployeeActivityData(
        icon: Icons.badge_outlined,
        color: isActive ? AppColors.success : AppColors.rmMutedText,
        title: 'Employee Status',
        value: isActive ? 'Active' : 'Inactive',
        subtitle: 'Joined $joinedText',
      ),
      _EmployeeActivityData(
        icon: Icons.payments_outlined,
        color: payrollConfigured ? AppColors.success : AppColors.accent,
        title: 'Payroll',
        value: payrollConfigured ? 'Configured' : 'Not configured',
        subtitle: 'Employee payroll status',
      ),
    ];

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1.1)),
      child: Scaffold(
        backgroundColor: AppColors.rmSoftPink,
        appBar: AppBar(
          backgroundColor: AppColors.appBarBg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'All Activity',
            style: GoogleFonts.manrope(
              color: AppColors.hrText,
              fontSize: 19.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          children: [
            Text(
              employeeName,
              style: GoogleFonts.manrope(
                color: AppColors.rmHeading,
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '$displayRole - $department',
              style: GoogleFonts.manrope(
                color: AppColors.rmMutedText,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.h),
            for (final activity in activities)
              _EmployeeActivityCard(activity: activity),
          ],
        ),
      ),
    );
  }
}

class _EmployeeActivityData {
  const _EmployeeActivityData({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;
}

class _EmployeeActivityCard extends StatelessWidget {
  const _EmployeeActivityCard({required this.activity});

  final _EmployeeActivityData activity;
  static const Color _profileNumberColor = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF6E5DB)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.rmCardShadow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: activity.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(activity.icon, color: activity.color, size: 23.r),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: GoogleFonts.manrope(
                    color: AppColors.rmHeading,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  activity.subtitle,
                  style: GoogleFonts.manrope(
                    color: AppColors.rmMutedText,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            activity.value,
            textAlign: TextAlign.end,
            style: GoogleFonts.manrope(
              color: _profileNumberColor,
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final bool isPrimary;

  const _Bar({required this.height, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4.w,
      height: height,
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.hrBlue : AppColors.neutralBorderColorLight,
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }
}
