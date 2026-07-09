import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/providers/manager_dashboard_provider.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';

class AdminDrawerScreen extends StatelessWidget {
  const AdminDrawerScreen({super.key});

  String _roleLabel(String? role) {
    final normalizedRole = role?.trim().toUpperCase() ?? '';
    if (normalizedRole == 'HR') {
      return 'HR';
    }
    if (normalizedRole.isEmpty) {
      return 'Admin';
    }

    return normalizedRole
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) {
          final lower = part.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel?.user;
    final normalizedRole = user?.role.trim().toUpperCase() ?? '';
    final roleLabel = _roleLabel(user?.role);
    final userName = user?.name ?? (roleLabel == 'HR' ? 'HR Team' : 'Owner');
    final dashboardProvider = context.watch<DashboardProvider>();
    final managerDashboard = context
        .watch<ManagerDashboardProvider>()
        .dashboard;
    final selectedIndex = dashboardProvider.selectedIndex;

    void selectTab(int index) {
      dashboardProvider.selectTab(index);
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.ownerDashboard, (route) => false);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              color: AppColors.rmSoftPink,
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
                      decoration: const BoxDecoration(
                        color: AppColors.rmPrimary,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Image.asset(
                                  'assets/app.logo.png',
                                  height: 58.h,
                                  color: AppColors.white,
                                  alignment: Alignment.centerLeft,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Close',
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 26.r,
                                backgroundColor: AppColors.white.withValues(
                                  alpha: 0.16,
                                ),
                                child: Text(
                                  userName.isNotEmpty
                                      ? userName[0].toUpperCase()
                                      : 'A',
                                  style: GoogleFonts.manrope(
                                    color: AppColors.white,
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.manrope(
                                        color: AppColors.white,
                                        fontSize: 19.sp,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 3.h),
                                    Text(
                                      roleLabel,
                                      style: GoogleFonts.manrope(
                                        color: AppColors.white.withValues(
                                          alpha: 0.78,
                                        ),
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            children: [
                              Expanded(
                                child: _AdminDrawerMetric(
                                  value:
                                      '${managerDashboard?.kpi.totalLeads ?? 0}',
                                  label: 'Leads',
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: _AdminDrawerMetric(
                                  value:
                                      '${managerDashboard?.kpi.activeProfiles ?? 0}',
                                  label: 'Active',
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: _AdminDrawerMetric(
                                  value:
                                      '${managerDashboard?.kpi.followUpsDue ?? 0}',
                                  label: 'Follow-ups',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(12.w, 14.h, 12.w, 14.h),
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 10.h),
                            child: Text(
                              'Main Menu',
                              style: GoogleFonts.manrope(
                                color: AppColors.rmMutedText,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          _AdminDrawerItem(
                            label: 'Dashboard',
                            icon: Icons.space_dashboard_outlined,
                            selected: selectedIndex == 0,
                            onTap: () => selectTab(0),
                          ),
                          _AdminDrawerItem(
                            label: 'Matches',
                            icon: Icons.groups_outlined,
                            selected: selectedIndex == 1,
                            onTap: () => selectTab(1),
                          ),
                          if (normalizedRole != 'ADMIN')
                            _AdminDrawerItem(
                              label: 'Profile Digitizer',
                              icon: Icons.edit_note_outlined,
                              selected: selectedIndex == 4,
                              onTap: () => selectTab(4),
                            ),
                          _AdminDrawerItem(
                            label: 'AI Matchmaking',
                            icon: Icons.auto_awesome_outlined,
                            selected: false,
                            onTap: () {
                              Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.aiMatching);
                            },
                          ),
                          _AdminDrawerItem(
                            label: 'Employee Management',
                            icon: Icons.manage_accounts_outlined,
                            selected: false,
                            onTap: () {
                              final navigator = Navigator.of(context);
                              navigator.pop();
                              navigator.pushNamed(AppRoutes.employeeManagement);
                            },
                          ),
                          _AdminDrawerItem(
                            label: 'Payroll Management',
                            icon: Icons.payments_outlined,
                            selected: false,
                            onTap: () {
                              Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.payrollManagement);
                            },
                          ),
                          _AdminDrawerItem(
                            label: 'Holiday Management',
                            icon: Icons.beach_access_outlined,
                            selected: false,
                            onTap: () {
                              final navigator = Navigator.of(context);
                              navigator.pop();
                              navigator.pushNamed(AppRoutes.holidayManagement);
                            },
                          ),
                          _AdminDrawerItem(
                            label: 'Leaves',
                            icon: Icons.event_note_outlined,
                            selected: false,
                            onTap: () {
                              final navigator = Navigator.of(context);
                              navigator.pop();
                              navigator.pushNamed(AppRoutes.leaves);
                            },
                          ),
                          _AdminDrawerItem(
                            label: 'Leads',
                            icon: Icons.person_search_outlined,
                            selected: selectedIndex == 2,
                            onTap: () => selectTab(2),
                          ),
                          _AdminDrawerItem(
                            label: 'Lead Follow-ups',
                            icon: Icons.event_available_outlined,
                            selected: false,
                            onTap: () {
                              Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.leadFollowUps);
                            },
                          ),
                          _AdminDrawerItem(
                            label: 'Profile',
                            icon: Icons.person_outline_rounded,
                            selected: selectedIndex == 5,
                            onTap: () => selectTab(5),
                          ),
                          Divider(
                            height: 28.h,
                            color: AppColors.rmPaleRoseBorder,
                          ),
                          _AdminDrawerItem(
                            label: 'Notifications',
                            icon: Icons.notifications_none_outlined,
                            selected: false,
                            onTap: () {
                              Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.notifications);
                            },
                          ),
                          if (normalizedRole == 'ADMIN')
                            _AdminDrawerItem(
                              label: 'Settings',
                              icon: Icons.settings_outlined,
                              selected: false,
                              onTap: () {
                                final navigator = Navigator.of(context);
                                navigator.pop();
                                navigator.pushNamed(AppRoutes.adminSettings);
                              },
                            ),
                          _AdminDrawerItem(
                            label: 'Support',
                            icon: Icons.support_agent_outlined,
                            selected: false,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: AppColors.rmPaleRoseBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34.r,
                                  height: 34.r,
                                  decoration: BoxDecoration(
                                    color: AppColors.whatsappGreen.withValues(
                                      alpha: 0.12,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.admin_panel_settings_outlined,
                                    color: AppColors.whatsappGreen,
                                    size: 21.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$roleLabel workspace',
                                        style: GoogleFonts.manrope(
                                          color: AppColors.rmHeading,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        'active',
                                        style: GoogleFonts.manrope(
                                          color: AppColors.whatsappGreen,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.whatsappGreen,
                                  size: 19.sp,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12.h),
                          _AdminDrawerItem(
                            label: 'Logout',
                            icon: Icons.logout_rounded,
                            selected: false,
                            isLogout: true,
                            onTap: () async {
                              await authProvider.logout();
                              if (context.mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  AppRoutes.login,
                                  (route) => false,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.black.withValues(alpha: 0.1)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminDrawerMetric extends StatelessWidget {
  const _AdminDrawerMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: AppColors.white,
              fontSize: 19.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: AppColors.white.withValues(alpha: 0.7),
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminDrawerItem extends StatelessWidget {
  const _AdminDrawerItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.isLogout = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isLogout;

  @override
  Widget build(BuildContext context) {
    final color = isLogout
        ? AppColors.error
        : selected
        ? AppColors.rmPrimary
        : AppColors.rmHeading;

    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.selectedNavItemBackgroundColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 23.sp),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: color,
                    fontSize: 15.sp,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
