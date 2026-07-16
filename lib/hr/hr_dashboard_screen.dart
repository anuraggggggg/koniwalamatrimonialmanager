import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/attendance_archives_screen.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/rm/relationship_manager_account_screen.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:koniwalamatrimonial/widgets/koniwala_primary_app_bar.dart';
import 'package:provider/provider.dart';
import '../owner/Screen/owerner_dashboard_screen.dart';

class HrDashboardScreen extends StatefulWidget {
  const HrDashboardScreen({super.key});

  @override
  State<HrDashboardScreen> createState() => _HrDashboardScreenState();
}

class _HrDashboardScreenState extends State<HrDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    const HomeView(),
    AttendanceArchivesScreen(
      onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
    ),
    RelationshipManagerAccountScreen(
      showScaffold: false,
      onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
    ),
  ];

  Future<void> _handleLogout() async {
    await context.read<AuthProvider>().logout();

    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel?.user;

    return Scaffold(
      key: _scaffoldKey,
      drawerScrimColor: Colors.black.withValues(alpha: 0.1),
      // drawerElevation: 0,
      backgroundColor: AppColors.hrBackground,
      appBar: _selectedIndex == 0
          ? KoniwalaPrimaryAppBar(
              showMenuButton: true,
              onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
            )
          : null,
      drawer: _HrDashboardDrawer(
        userName: user?.name ?? 'HR Team',
        roleLabel: 'Human Resources',
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          if (index == 4) {
            Navigator.of(context).pushNamed(AppRoutes.employeeManagement);
          } else if (index == 3) {
            Navigator.of(context).pushNamed(AppRoutes.payrollManagement);
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        onLogout: _handleLogout,
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.hrPrimary,
        unselectedItemColor: AppColors.inactiveNavItemColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            label: 'Attend',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge_outlined),
            label: 'Staff',
          ),
        ],
      ),
    );
  }
}

class _HrDashboardDrawer extends StatelessWidget {
  const _HrDashboardDrawer({
    required this.userName,
    required this.roleLabel,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
  });

  final String userName;
  final String roleLabel;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    void selectTab(int index) {
      Navigator.of(context).maybePop();
      onItemSelected(index);
    }

    return Drawer(
      backgroundColor: AppColors.hrBackground,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
              decoration: const BoxDecoration(color: AppColors.hrPrimary),
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
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close, color: AppColors.white),
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
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'H',
                          style: GoogleFonts.inter(
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
                              style: GoogleFonts.inter(
                                color: AppColors.white,
                                fontSize: 19.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              roleLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: AppColors.white.withValues(alpha: 0.78),
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
                    children: const [
                      Expanded(
                        child: _HrDrawerMetric(value: '18', label: 'Staff'),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _HrDrawerMetric(value: '3', label: 'Leaves'),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _HrDrawerMetric(value: '5', label: 'Tasks'),
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
                      style: GoogleFonts.inter(
                        color: AppColors.hrMuted,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  _HrDrawerItem(
                    label: 'Home',
                    icon: Icons.dashboard_outlined,
                    selected: selectedIndex == 0,
                    onTap: () => selectTab(0),
                  ),
                  _HrDrawerItem(
                    label: 'Attendance',
                    icon: Icons.event_note_outlined,
                    selected: selectedIndex == 1,
                    onTap: () => selectTab(1),
                  ),
                  _HrDrawerItem(
                    label: 'Employee Management',
                    icon: Icons.manage_accounts_outlined,
                    selected: false,
                    onTap: () => selectTab(4),
                  ),
                  _HrDrawerItem(
                    label: 'Payroll Management',
                    icon: Icons.payments_outlined,
                    selected: false,
                    onTap: () => selectTab(3),
                  ),
                  _HrDrawerItem(
                    label: 'Leave Management',
                    icon: Icons.calendar_today_outlined,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).maybePop();
                      Navigator.of(context).pushNamed(AppRoutes.leaves);
                    },
                  ),
                  _HrDrawerItem(
                    label: 'Holiday Management',
                    icon: Icons.beach_access_outlined,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).maybePop();
                      Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.holidayManagement);
                    },
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
                      border: Border.all(color: AppColors.hrMetricBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34.r,
                          height: 34.r,
                          decoration: BoxDecoration(
                            color: AppColors.hrOpenTaskValue.withValues(
                              alpha: 0.12,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_outline,
                            color: AppColors.hrOpenTaskValue,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            'HR workspace active',
                            style: GoogleFonts.inter(
                              color: AppColors.hrText,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).maybePop();
                        onLogout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.hrPrimary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, size: 21.sp),
                          SizedBox(width: 10.w),
                          Text(
                            'Logout',
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
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
  }
}

class _HrDrawerMetric extends StatelessWidget {
  const _HrDrawerMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.white,
              fontSize: 19.sp,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.white.withValues(alpha: 0.78),
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HrDrawerItem extends StatelessWidget {
  const _HrDrawerItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.hrPrimary : AppColors.hrText;

    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Material(
        color: selected ? const Color(0xFFF0DDE4) : AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                Icon(icon, color: color, size: 23.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: 15.sp,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
