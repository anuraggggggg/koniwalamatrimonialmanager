import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/models/manager_dashboard.dart';
import 'package:koniwalamatrimonial/owner/models/hr_employee_item.dart';
import 'package:koniwalamatrimonial/owner/models/lead_registry_item.dart';
import 'package:koniwalamatrimonial/owner/models/lead_follow_up_item.dart';
import 'package:koniwalamatrimonial/owner/providers/leads_provider.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/providers/manager_dashboard_provider.dart';
import 'package:koniwalamatrimonial/owner/providers/hr_employees_provider.dart';
import 'package:koniwalamatrimonial/owner/providers/follow_up_control_actions_provider.dart';
import 'package:koniwalamatrimonial/owner/providers/lead_follow_ups_provider.dart';
import 'package:koniwalamatrimonial/widgets/koniwala_primary_app_bar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../routes/app_routes.dart';
import '../models/registry_profile_item.dart';
import '../providers/registry_profiles_provider.dart';
import 'registry_screen.dart';
import 'leads_registry_screen.dart';
import 'client_registry_screen.dart';
import '../providers/dashboard_provider.dart';
import 'admin_drawer_screen.dart';
import 'profile_digitizer_screen.dart';
import 'profile_screen.dart';
import 'employee_detail_screen.dart';

class OwernerDashboardScreen extends StatefulWidget {
  const OwernerDashboardScreen({super.key});

  @override
  State<OwernerDashboardScreen> createState() => _OwernerDashboardScreenState();
}

class _OwernerDashboardScreenState extends State<OwernerDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const List<int> _visibleBottomNavTabs = [0, 1, 2, 5];
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // PERF: Keep tab screens stable. Recreating every IndexedStack child on
    // dashboard/provider rebuilds causes unnecessary work and slower tab swaps.
    _screens = _buildScreens();
  }

  int _bottomNavIndexForTab(int selectedIndex) {
    final visibleIndex = _visibleBottomNavTabs.indexOf(selectedIndex);
    return visibleIndex == -1 ? 0 : visibleIndex;
  }

  int _tabIndexForBottomNav(int bottomNavIndex) {
    return _visibleBottomNavTabs[bottomNavIndex];
  }

  void _openAdminDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _selectAdminDrawerTab(int index) {
    Navigator.of(context).maybePop();
    context.read<DashboardProvider>().selectTab(index);
  }

  List<Widget> _buildScreens() {
    return [
      const HomeView(),
      RegistryScreen(onMenuPressed: _openAdminDrawer),
      LeadsRegistryScreen(onMenuPressed: _openAdminDrawer),
      ClientRegistryScreen(onMenuPressed: _openAdminDrawer),
      const ProfileDigitizerScreen(embeddedInDashboard: true),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        textTheme: GoogleFonts.interTextTheme(theme.textTheme),
        primaryTextTheme: GoogleFonts.interTextTheme(theme.primaryTextTheme),
      ),
      child: Consumer<DashboardProvider>(
        builder: (context, dashboardProvider, _) {
          final selectedIndex = dashboardProvider.selectedIndex;

          final showParentAppBar =
              selectedIndex != 1 &&
              selectedIndex != 2 &&
              selectedIndex != 3 &&
              selectedIndex != 4 &&
              selectedIndex != 5;

          return Scaffold(
            key: _scaffoldKey,
            drawerScrimColor: Colors.black.withValues(alpha: 0.1),
            // drawerElevation: 0,
            backgroundColor: AppColors.rmSoftPink,
            drawer: Drawer(
              width: MediaQuery.sizeOf(context).width * 0.68,
              backgroundColor: AppColors.rmSoftPink,
              child: AdminDrawerContent(
                onClose: () => Navigator.of(context).maybePop(),
                onSelectDashboardTab: _selectAdminDrawerTab,
              ),
            ),
            appBar: showParentAppBar
                ? KoniwalaPrimaryAppBar(
                    showMenuButton: true,
                    onMenuPressed: _openAdminDrawer,
                  )
                : null,
            body: IndexedStack(index: selectedIndex, children: _screens),
            bottomNavigationBar: _buildBottomNav(context, selectedIndex),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int selectedIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomNavIndexForTab(selectedIndex),
        onTap: (index) {
          context.read<DashboardProvider>().selectTab(
            _tabIndexForBottomNav(index),
          );
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.black,
        selectedFontSize: 12.sp,
        unselectedFontSize: 11.sp,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: _bottomNavImageIcon(Colors.black),
            activeIcon: _bottomNavImageIcon(AppColors.primary),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined, size: 24.sp),
            activeIcon: Icon(Icons.groups_rounded, size: 24.sp),
            label: 'Matches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_search_outlined, size: 24.sp),
            activeIcon: Icon(Icons.person_search_rounded, size: 24.sp),
            label: 'Leads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded, size: 24.sp),
            activeIcon: Icon(Icons.person_rounded, size: 24.sp),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _bottomNavImageIcon(Color color) {
    return Image.asset(
      'assets/icon/dashbaord_icon.png',
      width: 24.sp,
      height: 24.sp,
      color: color,
    );
  }
}

/*
class _AdminDashboardDrawer extends StatelessWidget {
  const _AdminDashboardDrawer({
    required this.selectedIndex,
    required this.userName,
    required this.onItemSelected,
    required this.onLogout,
  });

  final int selectedIndex;
  final String userName;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    void selectTab(int index) {
      Navigator.of(context).maybePop();
      onItemSelected(index);
    }

    return Drawer(
      backgroundColor: AppColors.rmSoftPink,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
              decoration: const BoxDecoration(color: AppColors.rmPrimary),
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
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
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
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              'Admin',
                              style: GoogleFonts.inter(
                                color: AppColors.white.withValues(alpha: 0.78),
                                fontSize: 13.sp,
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
                      const Expanded(
                        child: _AdminDrawerMetric(value: '7', label: 'Tabs'),
                      ),
                      SizedBox(width: 8.w),
                      const Expanded(
                        child: _AdminDrawerMetric(value: '9', label: 'Leads'),
                      ),
                      SizedBox(width: 8.w),
                      const Expanded(
                        child: _AdminDrawerMetric(value: '18', label: 'Active'),
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
                        color: AppColors.rmMutedText,
                        fontSize: 12.sp,
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
                      Navigator.of(context).maybePop();
                      Navigator.of(context).pushNamed(AppRoutes.leadFollowUps);
                    },
                  ),
                  _AdminDrawerItem(
                    label: 'Client Registry',
                    icon: Icons.assignment_ind_outlined,
                    selected: selectedIndex == 3,
                    onTap: () => selectTab(3),
                  ),
                  _AdminDrawerItem(
                    label: 'Profile Digitizer',
                    icon: Icons.edit_note_outlined,
                    selected: selectedIndex == 4,
                    onTap: () => selectTab(4),
                  ),
                  _AdminDrawerItem(
                    label: 'Employee Management',
                    icon: Icons.manage_accounts_outlined,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).maybePop();
                      Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.employeeManagement);
                    },
                  ),
                  _AdminDrawerItem(
                    label: 'Leaves',
                    icon: Icons.calendar_today_outlined,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).maybePop();
                      Navigator.of(context).pushNamed(AppRoutes.leaves);
                    },
                  ),
                  _AdminDrawerItem(
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
                  _AdminDrawerItem(
                    label: 'Profile',
                    icon: Icons.person_outline_rounded,
                    selected: selectedIndex == 5,
                    onTap: () => selectTab(5),
                  ),
                  _AdminDrawerItem(
                    label: 'Payroll Management',
                    icon: Icons.payments_outlined,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).maybePop();
                      Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.payrollManagement);
                    },
                  ),
                  Divider(height: 28.h, color: AppColors.rmPaleRoseBorder),
                  _AdminDrawerItem(
                    label: 'AI Matchmaking',
                    icon: Icons.auto_awesome_outlined,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).maybePop();
                      Navigator.of(context).pushNamed(AppRoutes.aiMatching);
                    },
                  ),
                  _AdminDrawerItem(
                    label: 'Notifications',
                    icon: Icons.notifications_none_outlined,
                    selected: false,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  _AdminDrawerItem(
                    label: 'Settings',
                    icon: Icons.settings_outlined,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).maybePop();
                      Navigator.of(context).pushNamed(AppRoutes.adminSettings);
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
                      border: Border.all(color: const Color(0xFFF6E5DB)),
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
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            'Admin workspace active',
                            style: GoogleFonts.inter(
                              color: AppColors.rmBodyText,
                              fontSize: 12.sp,
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
                        backgroundColor: AppColors.rmPrimary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, size: 20.sp),
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
*/

/*
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
        border: Border.all(color: AppColors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.white,
              fontSize: 18.sp,
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
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
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
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.rmPrimary : AppColors.rmBodyText;

    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Material(
        color: selected
            ? AppColors.selectedNavItemBackgroundColor
            : AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22.sp),
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
*/

class HomeView extends StatefulWidget {
  const HomeView({super.key, this.onMenuPressed});

  final VoidCallback? onMenuPressed;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  static const Map<String, String> _periodTabs = {
    'Today': 'today',
    'Weekly': 'this_week',
    'Past Month': 'past_month',
    'This Year': 'this_year',
  };

  String selectedCategory = "team";

  String _selectedPeriod = 'past_month';

  final Color _primaryColor = AppColors.primary;

  BoxDecoration _ownerCardDecoration({double radius = 12}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE4E4E4)),
      color: Colors.white,
    );
  }

  BoxDecoration _segmentControl({double radius = 12}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: AppColors.dashbaordcardtext.withValues(alpha: 0.2),
      ),
      boxShadow: const [
        BoxShadow(
          color: AppColors.rmCardShadow,
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  bool _isHrRole(String role) {
    final normalizedRole = role.trim().toUpperCase();
    return normalizedRole == 'HR' ||
        normalizedRole.contains('HUMAN RESOURCE') ||
        normalizedRole.contains('HUMAN_RESOURCES');
  }

  int _openCallTaskCount(List<LeadFollowUpItem> leads) {
    return leads.fold<int>(
      0,
      (total, lead) => total + lead.openFollowUps.length,
    );
  }

  Future<void> _callPhoneNumber(String? phone) async {
    final cleanPhone = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty) {
      _showDashboardMessage('Phone number not available.');
      return;
    }

    final normalizedPhone = cleanPhone.length == 10
        ? '91$cleanPhone'
        : cleanPhone;
    final uri = Uri(scheme: 'tel', path: normalizedPhone);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showDashboardMessage('Phone dialer is not available.');
      }
    } catch (_) {
      _showDashboardMessage('Unable to start phone call.');
    }
  }

  void _showDashboardMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showReportUnavailableMessage(ManagerDashboardProvider provider) {
    if (provider.isLoading) {
      _showDashboardMessage('Report is still loading. Please wait.');
      return;
    }

    _showDashboardMessage(
      provider.error ?? 'Report data is not available for this role.',
    );
  }

  void _showHrRoleReport({
    required List<HrEmployeeItem> hrEmployees,
    required List<LeadFollowUpItem> followUps,
  }) {
    final presentCount = hrEmployees
        .where((employee) => employee.isPresentToday)
        .length;
    final activeCount = hrEmployees
        .where((employee) => employee.isActive)
        .length;
    final payrollEnabledCount = hrEmployees
        .where((employee) => employee.payrollEnabled)
        .length;
    final assignedLeads = hrEmployees.fold<int>(
      0,
      (total, employee) => total + employee.assignedLeads,
    );
    final assignedTasks = hrEmployees.fold<int>(
      0,
      (total, employee) => total + employee.assignedTasks,
    );
    final profilesHandled = hrEmployees.fold<int>(
      0,
      (total, employee) => total + employee.dataEntryProfiles,
    );
    final closedLeads = hrEmployees.fold<int>(
      0,
      (total, employee) => total + employee.closedLeads,
    );
    final openFollowUps = _openCallTaskCount(followUps);
    final followUpLeadCount = followUps
        .where((lead) => lead.openFollowUps.isNotEmpty)
        .length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: EdgeInsets.all(12.w),
            padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 22.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'HR Full Report',
                        style: GoogleFonts.inter(
                          color: AppColors.rmPrimary,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, size: 22.sp),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildReportMetric(
                        'HR Staff',
                        '${hrEmployees.length}',
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _buildReportMetric('Present', '$presentCount'),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildReportMetric('Follow-ups', '$openFollowUps'),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _buildReportMetric(
                        'Payroll',
                        '$payrollEnabledCount',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                _buildReportRow('Active staff', '$activeCount'),
                _buildReportRow(
                  'Absent today',
                  '${hrEmployees.length - presentCount}',
                ),
                _buildReportRow('Assigned leads', '$assignedLeads'),
                _buildReportRow('Assigned tasks', '$assignedTasks'),
                _buildReportRow('Profiles handled', '$profilesHandled'),
                _buildReportRow('Closed leads', '$closedLeads'),
                _buildReportRow('Payroll enabled', '$payrollEnabledCount'),
                _buildReportRow('Follow-up leads', '$followUpLeadCount'),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel?.user;
    final userImage = user?.image?.trim();
    final ImageProvider<Object> avatarImage =
        userImage != null && userImage.isNotEmpty
        ? NetworkImage(userImage)
        : const AssetImage('assets/wedding_hero 1.png');
    final accessToken = authProvider.userModel?.accessToken;
    final managerDashboardProvider = context.watch<ManagerDashboardProvider>();
    final employeesProvider = context.watch<HrEmployeesProvider>();
    final followUpsProvider = context.watch<LeadFollowUpsProvider>();
    final dashboard = managerDashboardProvider.dashboard;
    final kpi = dashboard?.kpi;
    final agencyPerformance = dashboard?.agencyPerformance;
    final List<HrEmployeeItem> hrEmployees = employeesProvider.employees
        .where((employee) => _isHrRole(employee.role))
        .toList();
    final totalTeamCount = dashboard?.liveTeamStatus.length ?? 0;
    final presentCount =
        dashboard?.liveTeamStatus
            .where(
              (item) => item.todayAttendanceStatus.toLowerCase() == 'present',
            )
            .length ??
        0;
    final absentCount = totalTeamCount - presentCount;
    final onlineCount =
        dashboard?.liveTeamStatus
            .where((item) => item.status.toLowerCase() == 'online')
            .length ??
        0;
    final offlineCount = dashboard == null
        ? 0
        : dashboard.liveTeamStatus.length - onlineCount;
    final totalTasksCompleted =
        dashboard?.liveTeamStatus.fold<int>(
          0,
          (total, item) => total + item.tasksCompleted,
        ) ??
        0;
    final totalProfilesHandled =
        dashboard?.liveTeamStatus.fold<int>(
          0,
          (total, item) => total + item.profilesHandled,
        ) ??
        0;
    final totalLeadsHandled =
        dashboard?.liveTeamStatus.fold<int>(
          0,
          (total, item) => total + item.leadsHandled,
        ) ??
        0;
    final primarySuggestion =
        dashboard != null && dashboard.aiSuggestions.isNotEmpty
        ? dashboard.aiSuggestions.first
        : null;
    final primaryAiTask =
        dashboard != null && dashboard.aiPanel.tasks.isNotEmpty
        ? dashboard.aiPanel.tasks.first
        : null;

    if (accessToken != null &&
        accessToken.isNotEmpty &&
        !managerDashboardProvider.isLoading &&
        !managerDashboardProvider.hasRequestFor(
          accessToken: accessToken,
          period: _selectedPeriod,
        )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.read<ManagerDashboardProvider>().fetchDashboard(
            accessToken,
            period: _selectedPeriod,
          );
        }
      });
    }

    if (accessToken != null &&
        accessToken.isNotEmpty &&
        !employeesProvider.isLoading &&
        !employeesProvider.hasRequestFor(accessToken: accessToken)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.read<HrEmployeesProvider>().fetchEmployees(accessToken);
        }
      });
    }

    if (accessToken != null &&
        accessToken.isNotEmpty &&
        !followUpsProvider.isLoading &&
        !followUpsProvider.hasRequestFor(accessToken: accessToken)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.read<LeadFollowUpsProvider>().fetchFollowUps(accessToken);
        }
      });
    }

    final filteredActivities =
        dashboard?.recentActivity
            .where((activity) => activity.category == selectedCategory)
            .toList() ??
        [];
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.onMenuPressed != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: IconButton(
                tooltip: 'Menu',
                onPressed: widget.onMenuPressed,
                icon: const Icon(Icons.menu, color: AppColors.rmPrimary),
              ),
            ),
            SizedBox(height: 4.h),
          ],
          // Greeting Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14.h,
                  backgroundColor: AppColors.rmPrimary.withValues(alpha: 0.12),
                  backgroundImage: avatarImage,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    '${_greetingForHour()} ${_firstName(user?.name)}!',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Color(0xFF312F2F),
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KMS BUSINESS SNAPSHOT',
                  style: GoogleFonts.inter(
                    color: Color(0xFF211A1B),
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    for (final entry in _periodTabs.entries) ...[
                      Expanded(
                        child: _buildTab(
                          entry.key,
                          entry.value == _selectedPeriod,
                          () => _selectPeriod(entry.value),
                        ),
                      ),
                      if (entry.key != _periodTabs.keys.last)
                        SizedBox(width: 6.w),
                    ],
                  ],
                ),
                // if ((dashboard?.period.displayText ?? '').isNotEmpty) ...[
                //   SizedBox(height: 12.h),
                //   Text(
                //     dashboard!.period.displayText,
                //     style: GoogleFonts.inter(
                //       color: const Color(0xFF6E5C61),
                //       fontSize: 13.sp,
                //       fontWeight: FontWeight.w700,
                //     ),
                //   ),
                // ],
                if (managerDashboardProvider.isLoading) ...[
                  SizedBox(height: 14.h),
                  LinearProgressIndicator(
                    minHeight: 3,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ],
                if (managerDashboardProvider.error != null &&
                    dashboard == null) ...[
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          managerDashboardProvider.error!,
                          style: GoogleFonts.inter(
                            color: Colors.red.shade700,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: managerDashboardProvider.retry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Stats Grid
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'NEW LEADS',
                        _formatCompactNumber(kpi?.matchesToday ?? 0),
                        trend: kpi == null
                            ? null
                            : _formatSignedPercent(kpi.newLeadsTrendPercent),
                        trendColor: const Color(0xFF0E9F6E),
                        trendIcon: Icons.trending_up_rounded,
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.leadsRegistry, arguments: 'New'),
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Expanded(
                      child: _buildStatCard(
                        'TOTAL LEADS',
                        _formatCompactNumber(kpi?.totalLeads ?? 0),
                        label: 'Active',
                        trendIcon: Icons.groups_rounded,
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.leadsRegistry),
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Expanded(
                      child: _buildStatCard(
                        'CONVERSIONS',
                        _formatCompactNumber(kpi?.conversions ?? 0),
                        trend: kpi == null ? null : '${kpi.conversionRate}%',
                        trendColor: const Color(0xFF0E9F6E),
                        trendIcon: Icons.check_circle_outline_rounded,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.leadsRegistry,
                          arguments: 'Converted',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'FOLLOW-UPS',
                        _formatCompactNumber(kpi?.followUpsDue ?? 0),
                        label: 'Pending',
                        labelColor: const Color(0xFFC62828),
                        trendIcon: Icons.notifications_active_rounded,
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.leadFollowUps),
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Expanded(
                      child: _buildStatCard(
                        'ACTIVE CLIENTS',
                        _formatCompactNumber(kpi?.activeProfiles ?? 0),
                        label: 'Active',
                        trendIcon: Icons.sync_rounded,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.clientRegistry,
                          arguments: ClientRegistryInitialFilter.all,
                        ),
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Expanded(
                      child: _buildStatCard(
                        'VIP CLIENTS',
                        _formatCompactNumber(kpi?.vipClients ?? 0),
                        label: 'Priority',
                        trendIcon: Icons.workspace_premium_outlined,
                        titleIcon: Icons.workspace_premium_rounded,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.clientRegistry,
                          arguments: ClientRegistryInitialFilter.vip,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          _buildProfileShortlistSection(),

          SizedBox(height: 16.h),

          _buildAgencyGrowthProjection(
            dashboard: dashboard,
            agencyPerformance: agencyPerformance,
            userRole: user?.role,
            hrEmployees: hrEmployees,
            followUps: followUpsProvider.leads,
            managerDashboardProvider: managerDashboardProvider,
          ),

          SizedBox(height: 16.h),

          // Critical Alerts
          _buildConnectivitySection(child: _buildCriticalAlerts(dashboard)),

          SizedBox(height: 16.h),

          _buildConnectivitySection(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'LIVE TEAM STATUS',
                            maxLines: 1,
                            style: GoogleFonts.inter(
                              color: AppColors.titleColor,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        flex: 6,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTeamStatusPill(
                                'Total',
                                totalTeamCount,
                                AppColors.rmHeading,
                              ),
                              SizedBox(width: 5.w),
                              _buildTeamStatusPill(
                                'Present',
                                presentCount,
                                const Color(0xFF22C55E),
                              ),
                              SizedBox(width: 5.w),
                              _buildTeamStatusPill(
                                'Absent',
                                absentCount,
                                const Color(0xFFC62828),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  if (dashboard?.liveTeamStatus.isEmpty ?? true)
                    _buildSectionEmptyState('No team activity available yet.')
                  else
                    SizedBox(
                      height: 190.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: dashboard!.liveTeamStatus.take(8).length,
                        itemBuilder: (context, index) {
                          final item = dashboard.liveTeamStatus[index];
                          final employee = _findEmployeeForTeamMember(
                            item,
                            employeesProvider.employees,
                          );
                          return _buildTeamCard(item, employee: employee);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Follow-up Control
          _buildConnectivitySection(
            child: _buildFollowUpControl(context, dashboard),
          ),

          SizedBox(height: 16.h),

          // Closing Pipeline
          _buildConnectivitySection(
            child: _buildClosingPipelineSection(dashboard),
          ),

          SizedBox(height: 16.h),
          _buildConnectivitySection(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 1 TITLE
                  Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 10,
                        color: Color(0xFFD62F2F),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'LIVE ACTIVITY',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF211A1B),
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 18.h),

                  /// FILTER CHIPS
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _activityChip("Team", "team"),
                        SizedBox(width: 10.w),

                        _activityChip("Leads", "leads"),
                        SizedBox(width: 10.w),

                        _activityChip("Matches", "matches"),
                        SizedBox(width: 10.w),

                        _activityChip("Payments", "payments"),
                        SizedBox(width: 10.w),

                        // _activityChip("Payments", "payments"),
                      ],
                    ),
                  ),

                  SizedBox(height: 18.h),

                  /// ACTIVITY CARD
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 18.w,
                      vertical: 14.h,
                    ),
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
                    child: filteredActivities.isEmpty
                        ? _buildSectionEmptyState(
                            'No recent activity in the selected period.',
                          )
                        : Column(
                            children: [
                              for (
                                int index = 0;
                                index < filteredActivities.take(5).length;
                                index++
                              ) ...[
                                if (index != 0)
                                  Divider(
                                    height: 24.h,
                                    color: const Color(0xFFEAEAEA),
                                  ),

                                _buildActivityRow(
                                  Icon(
                                    _activityIconForItem(
                                      filteredActivities[index],
                                    ),
                                    size: 20.sp,
                                    color: _activityColorForItem(
                                      filteredActivities[index],
                                    ),
                                  ),
                                  filteredActivities[index].title,
                                  filteredActivities[index].description,
                                  backgroundColor: _activityColorForItem(
                                    filteredActivities[index],
                                  ).withValues(alpha: 0.12),
                                  onTap: () {
                                    final activity = filteredActivities[index];
                                    debugPrint(activity.title);
                                  },
                                ),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Employee Performance Overview
          _buildConnectivitySection(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: _ownerCardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EMPLOYEE PERFORMANCE OVERVIEW',
                      style: GoogleFonts.inter(
                        color: Color(0xFF181C1F),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),

                    SizedBox(height: 12.h),
                    Text(
                      'Group attendance, KPIs, and task progress in one section',
                      style: GoogleFonts.inter(
                        color: Color(0xFF424754),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    SizedBox(height: 32.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPerfStat(
                            'PRESENT',
                            '$presentCount',
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildPerfStat(
                            'ONLINE',
                            '$onlineCount',
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildPerfStat(
                            'OFFLINE',
                            '$offlineCount',
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 25.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Task Overview',
                          style: GoogleFonts.inter(
                            color: Color(0xFF181C1F),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${agencyPerformance?.taskCompletionRate ?? 0}% Completed',
                            style: GoogleFonts.inter(
                              color: AppColors.reddishBrown,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    _buildProgressRow(
                      'Tasks Completed',
                      '$totalTasksCompleted',
                      _safeProgress(
                        totalTasksCompleted,
                        totalTasksCompleted + (kpi?.followUpsDue ?? 0),
                      ),
                      Colors.pink,
                      pendingText:
                          '${kpi?.followUpsDue ?? 0} follow-ups still due',
                    ),
                    SizedBox(height: 24.h),
                    _buildProgressRow(
                      'Profiles Handled',
                      '$totalProfilesHandled',
                      _safeProgress(
                        totalProfilesHandled,
                        kpi?.activeProfiles ?? 0,
                      ),
                      Colors.orange,
                      pendingText: '$totalLeadsHandled leads handled today',
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // AI Suggestions
          _buildConnectivitySection(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF570013), Color(0xFF800020)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.orange,
                          size: 22,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'AI SUGGESTIONS',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      primarySuggestion?.description ??
                          primaryAiTask?.title ??
                          'No AI suggestions are available for this period.',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12.sp,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.leadFollowUps,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.goldYellow,
                              foregroundColor: AppColors.deepBurgundy,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              primarySuggestion?.actionLabel ?? 'Execute',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 11.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          flex: 1,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Dismiss',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Lost Customers
          _buildConnectivitySection(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF101828),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LOST CUSTOMERS',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '24',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 54.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'LOST THIS MONTH',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFA8A29E),
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                                height: 1.50,
                                letterSpacing: -0.50,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildMiniProgress(
                                'Pricing (65%)',
                                0.65,
                                Colors.yellow,
                              ),
                              const SizedBox(height: 16),
                              _buildMiniProgress(
                                'Competition (35%)',
                                0.35,
                                Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          if (dashboard == null) {
                            if (user != null && _isHrRole(user.role)) {
                              _showHrRoleReport(
                                hrEmployees: hrEmployees,
                                followUps: followUpsProvider.leads,
                              );
                              return;
                            }

                            _showReportUnavailableMessage(
                              managerDashboardProvider,
                            );
                            return;
                          }

                          _showLostCustomersReport(dashboard);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'VIEW FULL REPORT',
                          style: GoogleFonts.inter(
                            color: Color(0xFFF2F1EE),
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.50,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Automation Efficiency
          _buildConnectivitySection(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: _ownerCardDecoration(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            value: 0.94,
                            strokeWidth: 4,
                            backgroundColor: Colors.grey[100],
                            color: _primaryColor,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '94%',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.whatsappGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 24.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Automation Efficiency',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: AppColors.titleColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 18.sp,
                            ),
                          ),
                          Text(
                            '420 auto-actions triggered today',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: AppColors.titleColor,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    InkWell(
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.adminSettings),
                      // borderRadius: BorderRadius.circular(16.r),
                      child: SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: Image.asset(
                          'assets/settings_icon.png',
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgencyGrowthProjection({
    required ManagerDashboard? dashboard,
    required ManagerAgencyPerformance? agencyPerformance,
    required String? userRole,
    required List<HrEmployeeItem> hrEmployees,
    required List<LeadFollowUpItem> followUps,
    required ManagerDashboardProvider managerDashboardProvider,
  }) {
    final conversionRate = agencyPerformance?.overallConversionRate ?? 0;
    final closedClients = agencyPerformance?.closedClients ?? 0;
    final taskCompletionRate = agencyPerformance?.taskCompletionRate ?? 0;
    final periodText = dashboard?.period.displayText;

    return _buildConnectivitySection(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: _ownerCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3EC),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.query_stats_rounded,
                      color: AppColors.primary,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agency performance',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF181C1F),
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          periodText?.isNotEmpty == true
                              ? periodText!
                              : 'Current owner dashboard summary',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF626A75),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              _buildAgencyMetricTile(
                title: 'Overall conversion',
                value: '$conversionRate%',
                helperText: 'Closed clients compared with qualified lead flow',
                icon: Icons.trending_up_rounded,
                accentColor: const Color(0xFF0F9F6E),
                progress: _safeProgress(conversionRate, 100),
                isPrimary: true,
              ),
              SizedBox(height: 10.h),
              LayoutBuilder(
                builder: (context, constraints) {
                  final useStackedLayout = constraints.maxWidth < 330;
                  final closedClientsTile = _buildAgencyMetricTile(
                    title: 'Closed clients',
                    value: _formatCompactNumber(closedClients),
                    helperText: '$closedClients total closed',
                    icon: Icons.verified_user_outlined,
                    accentColor: const Color(0xFF2F80ED),
                  );
                  final taskCompletionTile = _buildAgencyMetricTile(
                    title: 'Task completion',
                    value: '$taskCompletionRate%',
                    helperText: 'Team tasks completed',
                    icon: Icons.task_alt_rounded,
                    accentColor: AppColors.primary,
                    progress: _safeProgress(taskCompletionRate, 100),
                  );

                  if (useStackedLayout) {
                    return Column(
                      children: [
                        closedClientsTile,
                        SizedBox(height: 10.h),
                        taskCompletionTile,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: closedClientsTile),
                      SizedBox(width: 10.w),
                      Expanded(child: taskCompletionTile),
                    ],
                  );
                },
              ),
              SizedBox(height: 14.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (dashboard == null) {
                      if (userRole != null && _isHrRole(userRole)) {
                        _showHrRoleReport(
                          hrEmployees: hrEmployees,
                          followUps: followUps,
                        );
                        return;
                      }

                      _showReportUnavailableMessage(managerDashboardProvider);
                      return;
                    }

                    _showAgencyReport(dashboard);
                  },
                  icon: Icon(Icons.assessment_outlined, size: 18.sp),
                  label: Text(
                    'View full report',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: Color(0xFFE4A17C)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    backgroundColor: const Color(0xFFFFFBF8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgencyMetricTile({
    required String title,
    required String value,
    required String helperText,
    required IconData icon,
    required Color accentColor,
    double? progress,
    bool isPrimary = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isPrimary ? 14.w : 12.w),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFFFFFBF8) : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isPrimary ? const Color(0xFFF0C6AE) : const Color(0xFFECE7E2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: accentColor, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF424754),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      helperText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF7A7F89),
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF181C1F),
                  fontSize: isPrimary ? 25.sp : 20.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            SizedBox(height: 12.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: isPrimary ? 8.h : 6.h,
                backgroundColor: accentColor.withValues(alpha: 0.12),
                color: accentColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileShortlistSection() {
    final registryProvider = context.watch<RegistryProfilesProvider>();
    final profiles = registryProvider.profiles.take(2).toList();

    if (registryProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (profiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROFILES READY FOR SHORTLISTING',
                        style: GoogleFonts.inter(
                          color: AppColors.titleColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profiles.length} profiles waiting for shortlist action.',
                        style: GoogleFonts.inter(
                          color: AppColors.titleColor,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3EC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.playlist_add_check_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            ...List.generate(
              profiles.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == profiles.length - 1 ? 0 : 12,
                ),
                child: _buildProfileShortlistCard(profiles[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileShortlistCard(RegistryProfileItem profile) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  profile.photoUrls.isNotEmpty
                      ? profile.photoUrls.first
                      : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.person,
                        color: AppColors.titleColor,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.titleColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text.rich(
                      TextSpan(
                        text: 'Client: ',
                        style: GoogleFonts.inter(
                          color: AppColors.titleColor,
                          fontSize: 15.sp,
                        ),
                        children: [
                          TextSpan(
                            text: profile.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    Text.rich(
                      TextSpan(
                        text: 'Owner: ',
                        style: GoogleFonts.inter(
                          color: AppColors.titleColor,
                          fontSize: 15.sp,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Relationship Manager',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              _buildChip(
                'due now',
                const Color(0xFFFFE7A9),
                const Color(0xFF9C5A00),
              ),
              const SizedBox(width: 8),
              _buildChip(
                'open shortlist',
                const Color(0xFFBFE2FF),
                const Color(0xFF1E5D91),
              ),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.shortlist,
                  arguments: profile,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'OPEN SHORTLIST',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildConnectivitySection({required Widget child}) {
    return Stack(
      alignment: Alignment.topLeft,
      children: [
        Positioned(
          left: 41.w, // Center aligned with the vertical line
          top: 0,
          child: Container(
            width: 14.w,
            height: 14.w,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildProgressRow(
    String label,
    String value,
    double progress,
    Color color, {
    String? pendingText,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: Color(0xFF2C2B2B),
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                color: Color(0xFF2C2B2B),
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        if (pendingText != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              pendingText,
              style: GoogleFonts.inter(
                color: AppColors.titleColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        SizedBox(height: 12.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[100],
            color: color,
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniProgress(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14.sp),
        ),
        SizedBox(height: 6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.white10,
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  void _selectPeriod(String period) {
    if (period == _selectedPeriod) {
      return;
    }

    setState(() => _selectedPeriod = period);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final accessToken = context.read<AuthProvider>().userModel?.accessToken;
      context.read<ManagerDashboardProvider>().fetchDashboard(
        accessToken,
        period: period,
        forceRefresh: true,
      );
    });
  }

  Future<void> _showAgencyReport(ManagerDashboard dashboard) async {
    final performance = dashboard.agencyPerformance;
    final kpi = dashboard.kpi;
    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    final leadsProvider = context.read<LeadsProvider>();

    if (leadsProvider.leads.isEmpty && !leadsProvider.isLoading) {
      await leadsProvider.fetchLeads(accessToken);
    }

    if (!mounted) {
      return;
    }

    final convertedLeads = leadsProvider.leads
        .where((lead) => _leadStageKey(lead.stage) == 'CONVERTED')
        .toList();
    final reportRmOptions = _agencyReportOptions([
      ...dashboard.liveTeamStatus.map((item) => item.name),
      ...convertedLeads.map((lead) => lead.assignedTo),
    ]);
    final reportConvertedByOptions = _agencyReportOptions(
      convertedLeads.map((lead) => lead.assignedTo),
    );
    final reportCreatorOptions = _agencyReportOptions([
      ...dashboard.recentActivity.map((activity) => activity.actorName),
      ...dashboard.recentProfiles.map((profile) => profile.client),
      ...convertedLeads.map((lead) => lead.assignedTo),
    ]);
    final reportStatusOptions = _agencyReportOptions(
      convertedLeads.map((lead) => lead.stage),
    );
    final totalTasksCompleted = dashboard.liveTeamStatus.fold<int>(
      0,
      (total, item) => total + item.tasksCompleted,
    );
    final totalLeadsHandled = dashboard.liveTeamStatus.fold<int>(
      0,
      (total, item) => total + item.leadsHandled,
    );
    final initialVisibleCount = convertedLeads.length > 5
        ? 5
        : convertedLeads.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        var visibleCount = initialVisibleCount;
        var selectedReportPeriod = _AgencyReportPeriod.all;
        DateTimeRange? customDateRange;
        var selectedRms = <String>{};
        String? selectedConvertedBy;
        String? selectedProfileCreator;
        String? selectedConversionStatus;
        var showReportFilters = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredConvertedLeads = convertedLeads.where((lead) {
              if (!_matchesAgencyReportPeriod(
                lead,
                selectedReportPeriod,
                customDateRange,
              )) {
                return false;
              }
              if (selectedRms.isNotEmpty &&
                  !selectedRms.contains(lead.assignedTo)) {
                return false;
              }
              if (selectedConvertedBy != null &&
                  lead.assignedTo != selectedConvertedBy) {
                return false;
              }
              if (selectedProfileCreator != null &&
                  lead.assignedTo != selectedProfileCreator) {
                return false;
              }
              if (selectedConversionStatus != null &&
                  lead.stage != selectedConversionStatus) {
                return false;
              }
              return true;
            }).toList();
            if (visibleCount > filteredConvertedLeads.length) {
              visibleCount = filteredConvertedLeads.length;
            }
            final effectiveVisibleCount = visibleCount == 0
                ? (filteredConvertedLeads.length > 5
                      ? 5
                      : filteredConvertedLeads.length)
                : visibleCount;
            final visibleLeads = filteredConvertedLeads
                .take(effectiveVisibleCount)
                .toList();
            final canLoadMore =
                effectiveVisibleCount < filteredConvertedLeads.length;
            final filteredRmNames = selectedRms.isEmpty
                ? reportRmOptions
                : selectedRms;
            final filteredTasksCompleted = selectedRms.isEmpty
                ? totalTasksCompleted
                : dashboard.liveTeamStatus
                      .where((item) => filteredRmNames.contains(item.name))
                      .fold<int>(
                        0,
                        (total, item) => total + item.tasksCompleted,
                      );
            final filteredLeadsHandled = selectedRms.isEmpty
                ? totalLeadsHandled
                : dashboard.liveTeamStatus
                      .where((item) => filteredRmNames.contains(item.name))
                      .fold<int>(0, (total, item) => total + item.leadsHandled);
            final reportConvertedCount = filteredConvertedLeads.isEmpty
                ? 0
                : filteredConvertedLeads.length;
            final reportTaskTarget =
                filteredLeadsHandled > filteredTasksCompleted
                ? filteredLeadsHandled
                : (filteredTasksCompleted > 0
                      ? filteredTasksCompleted
                      : kpi.totalLeads);
            final reportConversionRate = filteredConvertedLeads.isEmpty
                ? 0
                : performance.overallConversionRate;
            final activeFilterCount = _agencyReportActiveFilterCount(
              selectedPeriod: selectedReportPeriod,
              selectedRms: selectedRms,
              selectedConvertedBy: selectedConvertedBy,
              selectedProfileCreator: selectedProfileCreator,
              selectedConversionStatus: selectedConversionStatus,
            );

            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.96,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF8),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24.r),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFF0E2D8)),
                          ),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(20.r),
                              onTap: () => Navigator.of(context).pop(),
                              child: SizedBox(
                                width: 36.w,
                                height: 36.w,
                                child: Icon(
                                  Icons.arrow_back,
                                  color: const Color(0xFF2B2B2B),
                                  size: 22.sp,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Agency Performance',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF2C2626),
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 36.w,
                              height: 36.w,
                              child: Icon(
                                Icons.more_vert,
                                color: const Color(0xFF2B2B2B),
                                size: 22.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 24.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Agency Performance Report',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF222222),
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                dashboard.period.displayText.isNotEmpty
                                    ? dashboard.period.displayText
                                    : 'All-time overview of conversions, closed clients, and task completion',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF343434),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                  height: 1.45,
                                ),
                              ),
                              SizedBox(height: 18.h),
                              _buildAgencyReportFilterToggle(
                                activeFilterCount: activeFilterCount,
                                expanded: showReportFilters,
                                summaryText: _agencyReportFilterSummaryText(
                                  selectedPeriod: selectedReportPeriod,
                                  customDateRange: customDateRange,
                                  selectedRms: selectedRms,
                                  selectedConvertedBy: selectedConvertedBy,
                                  selectedProfileCreator:
                                      selectedProfileCreator,
                                  selectedConversionStatus:
                                      selectedConversionStatus,
                                ),
                                onTap: () {
                                  setModalState(() {
                                    showReportFilters = !showReportFilters;
                                  });
                                },
                              ),
                              if (showReportFilters) ...[
                                SizedBox(height: 10.h),
                                _buildAgencyReportFilters(
                                  selectedPeriod: selectedReportPeriod,
                                  customDateRange: customDateRange,
                                  rmOptions: reportRmOptions,
                                  selectedRms: selectedRms,
                                  convertedByOptions: reportConvertedByOptions,
                                  selectedConvertedBy: selectedConvertedBy,
                                  profileCreatorOptions: reportCreatorOptions,
                                  selectedProfileCreator:
                                      selectedProfileCreator,
                                  conversionStatusOptions: reportStatusOptions,
                                  selectedConversionStatus:
                                      selectedConversionStatus,
                                  onClearFilters: () {
                                    setModalState(() {
                                      selectedReportPeriod =
                                          _AgencyReportPeriod.all;
                                      customDateRange = null;
                                      selectedRms = <String>{};
                                      selectedConvertedBy = null;
                                      selectedProfileCreator = null;
                                      selectedConversionStatus = null;
                                      visibleCount = initialVisibleCount;
                                    });
                                  },
                                  onPeriodChanged: (period) async {
                                    if (period == _AgencyReportPeriod.custom) {
                                      final now = DateTime.now();
                                      final pickedRange = await showDateRangePicker(
                                        context: context,
                                        firstDate: DateTime(now.year - 5),
                                        lastDate: DateTime(now.year + 1),
                                        initialDateRange: customDateRange,
                                        builder: (context, child) {
                                          const pickerBackground = Color(
                                            0xFFFFF8F4,
                                          );
                                          return Theme(
                                            data: ThemeData.light().copyWith(
                                              scaffoldBackgroundColor:
                                                  pickerBackground,
                                              canvasColor: pickerBackground,
                                              dialogTheme:
                                                  const DialogThemeData(
                                                    backgroundColor:
                                                        pickerBackground,
                                                    surfaceTintColor:
                                                        AppColors.white,
                                                  ),
                                              colorScheme:
                                                  const ColorScheme.light(
                                                    primary: AppColors.primary,
                                                    onPrimary: AppColors.white,
                                                    surface: pickerBackground,
                                                    onSurface: Color(
                                                      0xFF211A1B,
                                                    ),
                                                  ),
                                              datePickerTheme:
                                                  const DatePickerThemeData(
                                                    backgroundColor:
                                                        pickerBackground,
                                                    surfaceTintColor:
                                                        AppColors.white,
                                                    headerBackgroundColor:
                                                        AppColors.primary,
                                                    headerForegroundColor:
                                                        AppColors.white,
                                                    rangeSelectionBackgroundColor:
                                                        Color(0xFFFFE6D7),
                                                    rangePickerBackgroundColor:
                                                        pickerBackground,
                                                    rangePickerSurfaceTintColor:
                                                        AppColors.white,
                                                  ),
                                            ),
                                            child: ColoredBox(
                                              color: pickerBackground,
                                              child:
                                                  child ??
                                                  const SizedBox.shrink(),
                                            ),
                                          );
                                        },
                                      );
                                      if (pickedRange == null) {
                                        return;
                                      }
                                      setModalState(() {
                                        selectedReportPeriod = period;
                                        customDateRange = pickedRange;
                                        visibleCount = initialVisibleCount;
                                      });
                                      return;
                                    }

                                    setModalState(() {
                                      selectedReportPeriod = period;
                                      customDateRange = null;
                                      visibleCount = initialVisibleCount;
                                    });
                                  },
                                  onRmsChanged: (values) {
                                    setModalState(() {
                                      selectedRms = values;
                                      visibleCount = initialVisibleCount;
                                    });
                                  },
                                  onConvertedByChanged: (value) {
                                    setModalState(() {
                                      selectedConvertedBy = value;
                                      visibleCount = initialVisibleCount;
                                    });
                                  },
                                  onProfileCreatorChanged: (value) {
                                    setModalState(() {
                                      selectedProfileCreator = value;
                                      visibleCount = initialVisibleCount;
                                    });
                                  },
                                  onConversionStatusChanged: (value) {
                                    setModalState(() {
                                      selectedConversionStatus = value;
                                      visibleCount = initialVisibleCount;
                                    });
                                  },
                                ),
                              ],
                              SizedBox(height: 18.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildAgencyPerformanceMetricCard(
                                      title: 'OVERALL CONVERSION\nRATE',
                                      value: '$reportConversionRate%',
                                      caption:
                                          'converted: $reportConvertedCount /\nqualified: $reportConvertedCount',
                                      icon: Icons.trending_up,
                                      iconColor: const Color(0xFF11A36A),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: _buildAgencyPerformanceMetricCard(
                                      title: 'CONVERTED CLIENTS',
                                      value: '$reportConvertedCount',
                                      caption: 'all-time\nconverted clients',
                                      icon: Icons.check_circle_outline,
                                      iconColor: const Color(0xFF17B26A),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              _buildAgencyPerformanceMetricCard(
                                title: 'TASK COMPLETION',
                                value: '${performance.taskCompletionRate}%',
                                caption:
                                    '$filteredTasksCompleted/$reportTaskTarget\ncompleted',
                                icon: Icons.check_circle_outline,
                                iconColor: const Color(0xFF17B26A),
                                isWide: true,
                              ),
                              SizedBox(height: 18.h),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.fromLTRB(
                                  10.w,
                                  12.h,
                                  10.w,
                                  12.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: const Color(0xFFE8DED6),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x12B25C18),
                                      blurRadius: 18,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 2.w,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Converted Clients',
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFF222222),
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            'Clients converted from leads across the CRM',
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFF343434),
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w500,
                                              height: 1.4,
                                            ),
                                          ),
                                          SizedBox(height: 12.h),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.w,
                                              vertical: 7.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFEDE2),
                                              borderRadius:
                                                  BorderRadius.circular(10.r),
                                            ),
                                            child: Text(
                                              '$reportConvertedCount records found',
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFF2A2A2A),
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 14.h),
                                    if (visibleLeads.isEmpty)
                                      Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          8.w,
                                          12.h,
                                          8.w,
                                          4.h,
                                        ),
                                        child: Text(
                                          leadsProvider.isLoading
                                              ? 'Loading converted clients...'
                                              : 'No converted clients available yet.',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF6B6B6B),
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    else
                                      Column(
                                        children: [
                                          for (
                                            var index = 0;
                                            index < visibleLeads.length;
                                            index++
                                          ) ...[
                                            _buildConvertedLeadCard(
                                              visibleLeads[index],
                                            ),
                                            if (index < visibleLeads.length - 1)
                                              SizedBox(height: 12.h),
                                          ],
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              if (canLoadMore) ...[
                                SizedBox(height: 22.h),
                                Center(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setModalState(() {
                                        final nextCount =
                                            effectiveVisibleCount + 5;
                                        visibleCount =
                                            nextCount >
                                                filteredConvertedLeads.length
                                            ? filteredConvertedLeads.length
                                            : nextCount;
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(
                                        color: AppColors.primary,
                                      ),
                                      minimumSize: Size(190.w, 48.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          14.r,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'Load More Records',
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _leadStageKey(String stage) {
    return stage.trim().toUpperCase().replaceAll(' ', '_');
  }

  List<String> _agencyReportOptions(Iterable<String> values) {
    final options = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && value != '-')
        .toSet()
        .toList();
    options.sort(
      (first, second) => first.toLowerCase().compareTo(second.toLowerCase()),
    );
    return options;
  }

  bool _matchesAgencyReportPeriod(
    LeadRegistryItem lead,
    _AgencyReportPeriod period,
    DateTimeRange? customRange,
  ) {
    final leadDate = _parseAgencyReportLeadDate(lead.createdOn);
    if (leadDate == null) {
      return true;
    }

    final today = DateTime.now();
    final leadDay = DateTime(leadDate.year, leadDate.month, leadDate.day);
    final currentDay = DateTime(today.year, today.month, today.day);

    switch (period) {
      case _AgencyReportPeriod.all:
        return true;
      case _AgencyReportPeriod.weekly:
        return !leadDay.isBefore(
              currentDay.subtract(const Duration(days: 6)),
            ) &&
            !leadDay.isAfter(currentDay);
      case _AgencyReportPeriod.monthly:
        return leadDay.year == today.year && leadDay.month == today.month;
      case _AgencyReportPeriod.custom:
        final range = customRange;
        if (range == null) {
          return true;
        }
        final start = DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
        );
        final end = DateTime(range.end.year, range.end.month, range.end.day);
        return !leadDay.isBefore(start) && !leadDay.isAfter(end);
    }
  }

  DateTime? _parseAgencyReportLeadDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '-') {
      return null;
    }

    final isoDate = DateTime.tryParse(trimmed);
    if (isoDate != null) {
      return isoDate.toLocal();
    }

    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = months[parts[1].toLowerCase()];
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  int _agencyReportActiveFilterCount({
    required _AgencyReportPeriod selectedPeriod,
    required Set<String> selectedRms,
    required String? selectedConvertedBy,
    required String? selectedProfileCreator,
    required String? selectedConversionStatus,
  }) {
    var count = selectedPeriod == _AgencyReportPeriod.all ? 0 : 1;
    if (selectedRms.isNotEmpty) {
      count++;
    }
    if (selectedConvertedBy != null) {
      count++;
    }
    if (selectedProfileCreator != null) {
      count++;
    }
    if (selectedConversionStatus != null) {
      count++;
    }
    return count;
  }

  String _agencyReportFilterSummaryText({
    required _AgencyReportPeriod selectedPeriod,
    required DateTimeRange? customDateRange,
    required Set<String> selectedRms,
    required String? selectedConvertedBy,
    required String? selectedProfileCreator,
    required String? selectedConversionStatus,
  }) {
    final filters = <String>[
      _agencyReportPeriodLabel(selectedPeriod, customDateRange),
    ];

    if (selectedRms.isNotEmpty) {
      filters.add(
        selectedRms.length == 1
            ? 'RM: ${selectedRms.first}'
            : 'RM: ${selectedRms.length} selected',
      );
    }
    if (selectedConvertedBy != null) {
      filters.add('Converted by: $selectedConvertedBy');
    }
    if (selectedProfileCreator != null) {
      filters.add('Creator: $selectedProfileCreator');
    }
    if (selectedConversionStatus != null) {
      filters.add('Status: $selectedConversionStatus');
    }

    return filters.join(' | ');
  }

  String _agencyReportPeriodLabel(
    _AgencyReportPeriod period,
    DateTimeRange? customDateRange,
  ) {
    switch (period) {
      case _AgencyReportPeriod.all:
        return 'All time';
      case _AgencyReportPeriod.weekly:
        return 'Weekly';
      case _AgencyReportPeriod.monthly:
        return 'Monthly';
      case _AgencyReportPeriod.custom:
        if (customDateRange == null) {
          return 'Custom date';
        }
        return '${_formatAgencyReportDate(customDateRange.start)} - ${_formatAgencyReportDate(customDateRange.end)}';
    }
  }

  String _formatAgencyReportDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Widget _buildAgencyReportFilterToggle({
    required int activeFilterCount,
    required bool expanded,
    required String summaryText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(12.w, 11.h, 12.w, 11.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFE8DED6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0FB25C18),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E8),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: AppColors.primary,
                size: 19.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Filters',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF211A1B),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (activeFilterCount > 0) ...[
                        SizedBox(width: 7.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            '$activeFilterCount',
                            style: GoogleFonts.inter(
                              color: AppColors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    summaryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B6662),
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: const Color(0xFF7D706A),
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgencyReportFilters({
    required _AgencyReportPeriod selectedPeriod,
    required DateTimeRange? customDateRange,
    required List<String> rmOptions,
    required Set<String> selectedRms,
    required List<String> convertedByOptions,
    required String? selectedConvertedBy,
    required List<String> profileCreatorOptions,
    required String? selectedProfileCreator,
    required List<String> conversionStatusOptions,
    required String? selectedConversionStatus,
    required VoidCallback onClearFilters,
    required ValueChanged<_AgencyReportPeriod> onPeriodChanged,
    required ValueChanged<Set<String>> onRmsChanged,
    required ValueChanged<String?> onConvertedByChanged,
    required ValueChanged<String?> onProfileCreatorChanged,
    required ValueChanged<String?> onConversionStatusChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 14.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: const Color(0xFFF0E2D8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0FB25C18),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filter options',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF211A1B),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: onClearFilters,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  minimumSize: Size(0, 34.h),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Clear all',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _AgencyReportPeriodButton(
                label: 'All',
                selected: selectedPeriod == _AgencyReportPeriod.all,
                onTap: () => onPeriodChanged(_AgencyReportPeriod.all),
              ),
              _AgencyReportPeriodButton(
                label: 'Weekly',
                selected: selectedPeriod == _AgencyReportPeriod.weekly,
                onTap: () => onPeriodChanged(_AgencyReportPeriod.weekly),
              ),
              _AgencyReportPeriodButton(
                label: 'Monthly',
                selected: selectedPeriod == _AgencyReportPeriod.monthly,
                onTap: () => onPeriodChanged(_AgencyReportPeriod.monthly),
              ),
              _AgencyReportPeriodButton(
                label: customDateRange == null ? 'Custom' : 'Custom Set',
                selected: selectedPeriod == _AgencyReportPeriod.custom,
                onTap: () => onPeriodChanged(_AgencyReportPeriod.custom),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720.w;
              final itemWidth = isWide
                  ? (constraints.maxWidth - 36.w) / 4
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12.w,
                runSpacing: 12.h,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _AgencyReportMultiSelectField(
                      label: 'Assigned RM',
                      valueText: selectedRms.isEmpty
                          ? 'All relationship managers'
                          : selectedRms.length == 1
                          ? selectedRms.first
                          : '${selectedRms.length} selected',
                      options: rmOptions,
                      selectedValues: selectedRms,
                      onChanged: onRmsChanged,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _AgencyReportDropdownField(
                      label: 'Converted by',
                      hintText: 'All converters',
                      options: convertedByOptions,
                      value: selectedConvertedBy,
                      onChanged: onConvertedByChanged,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _AgencyReportDropdownField(
                      label: 'Profile creator',
                      hintText: 'All creators',
                      options: profileCreatorOptions,
                      value: selectedProfileCreator,
                      onChanged: onProfileCreatorChanged,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _AgencyReportDropdownField(
                      label: 'Conversion status',
                      hintText: 'All conversion statuses',
                      options: conversionStatusOptions,
                      value: selectedConversionStatus,
                      onChanged: onConversionStatusChanged,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAgencyPerformanceMetricCard({
    required String title,
    required String value,
    required String caption,
    required IconData icon,
    required Color iconColor,
    bool isWide = false,
  }) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: isWide ? 114.h : 132.h),
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFEEDFD5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12B25C18),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF393434),
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              height: 1.2,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontSize: 25.sp,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  caption,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF393434),
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Icon(icon, color: iconColor, size: 18.sp),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConvertedLeadCard(LeadRegistryItem lead) {
    final email = lead.email.trim().isEmpty ? 'No email' : lead.email;
    final packageLabel = lead.leadFor.trim().isEmpty || lead.leadFor == '-'
        ? 'STANDARD'
        : lead.leadFor.toUpperCase();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE9DCD3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
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
              Expanded(
                child: Text(
                  lead.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF212121),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1E2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '[$packageLabel]',
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _buildLeadMetaItem(Icons.call_outlined, lead.phone),
              ),
              SizedBox(width: 12.w),
              Expanded(child: _buildLeadMetaItem(Icons.mail_outline, email)),
            ],
          ),
          SizedBox(height: 10.h),
          Divider(color: const Color(0xFFE8D4C8), height: 1.h),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _buildLeadMetaItem(
                  Icons.person_outline,
                  'RM: ${lead.assignedTo == '-' ? 'Unassigned' : lead.assignedTo}',
                ),
              ),
              SizedBox(width: 12.w),
              SizedBox(
                width: 116.w,
                child: _buildLeadMetaItem(
                  Icons.calendar_today_outlined,
                  lead.createdOn,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeadMetaItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: const Color(0xFF3E3E3E)),
        SizedBox(width: 4.w),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF2F2F2F),
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportMetric(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7FA),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFF6E5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF6E5C61),
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.rmPrimary,
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFF424754),
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.rmPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  void _showLostCustomersReport(ManagerDashboard dashboard) {
    const lostThisMonth = 24;
    const pricingShare = 65;
    const competitionShare = 35;
    final urgent = dashboard.urgent;
    final kpi = dashboard.kpi;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: EdgeInsets.all(12.w),
            padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 22.h),
            decoration: BoxDecoration(
              color: const Color(0xFF101828),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Lost Customers Report',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.white, size: 22.sp),
                    ),
                  ],
                ),
                if (dashboard.period.displayText.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    dashboard.period.displayText,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFA8A29E),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                SizedBox(height: 18.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildDarkReportMetric(
                        'Lost this month',
                        '$lostThisMonth',
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _buildDarkReportMetric(
                        'Follow-ups due',
                        '${kpi.followUpsDue}',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                _buildDarkReportProgress(
                  'Pricing',
                  pricingShare,
                  Colors.yellow,
                ),
                SizedBox(height: 12.h),
                _buildDarkReportProgress(
                  'Competition',
                  competitionShare,
                  Colors.orange,
                ),
                SizedBox(height: 18.h),
                _buildDarkReportRow('Stale leads', '${urgent.staleLeads}'),
                _buildDarkReportRow(
                  'Pending replies',
                  '${urgent.pendingReplies}',
                ),
                _buildDarkReportRow(
                  'Unassigned leads',
                  '${urgent.unassignedLeads}',
                ),
                _buildDarkReportRow('Ready to send', '${urgent.readyToSend}'),
                _buildDarkReportRow('Total leads', '${kpi.totalLeads}'),
                _buildDarkReportRow(
                  'Conversion rate',
                  '${kpi.conversionRate}%',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDarkReportMetric(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFFA8A29E),
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkReportProgress(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$value%',
              style: GoogleFonts.inter(
                color: const Color(0xFFA8A29E),
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        SizedBox(height: 7.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor: Colors.white10,
            color: color,
            minHeight: 6.h,
          ),
        ),
      ],
    );
  }

  Widget _buildDarkReportRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFFA8A29E),
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String _firstName(String? fullName) {
    final trimmed = (fullName ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Admin';
    }

    return trimmed.split(RegExp(r'\s+')).first;
  }

  String _initialsForName(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return parts.isEmpty ? 'A' : parts;
  }

  String _greetingForHour() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  String _formatCompactNumber(int value) {
    if (value >= 1000) {
      final compact = value / 1000;
      final text = compact % 1 == 0
          ? compact.toStringAsFixed(0)
          : compact.toStringAsFixed(1);
      return '${text}k';
    }
    return '$value';
  }

  String _formatSignedPercent(int value) {
    return value > 0 ? '+$value%' : '$value%';
  }

  double _safeProgress(int numerator, int denominator) {
    if (denominator <= 0) {
      return 0;
    }
    return (numerator / denominator).clamp(0, 1).toDouble();
  }

  IconData _activityIconForItem(ManagerRecentActivityItem item) {
    switch (item.icon.toLowerCase()) {
      case 'delete':
        return Icons.delete_outline;
      case 'account_circle':
        return Icons.person_add_alt_1_outlined;
      case 'history':
        break;
    }

    switch (item.action.toUpperCase()) {
      case 'LOGIN':
        return Icons.login;
      case 'LOGOUT':
        return Icons.logout;
      case 'PROFILE_VIEW':
        return Icons.remove_red_eye_outlined;
      case 'PROFILE_CREATE':
        return Icons.person_add_alt_1_outlined;
      case 'PROFILE_DELETE':
        return Icons.delete_outline;
      default:
        return Icons.history;
    }
  }

  Color _activityColorForItem(ManagerRecentActivityItem item) {
    switch (item.action.toUpperCase()) {
      case 'PROFILE_DELETE':
        return Colors.red.shade700;
      case 'PROFILE_CREATE':
      case 'LOGIN':
        return Colors.green.shade700;
      case 'LOGOUT':
        return Colors.orange.shade700;
      default:
        return AppColors.rmPrimary;
    }
  }

  Widget _buildSectionEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        message,
        style: GoogleFonts.inter(
          color: const Color(0xFF6E5C61),
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildClosingPipelineSection(ManagerDashboard? dashboard) {
    final closingPipeline = dashboard?.raw['closingPipeline'];
    final pipelineItems = closingPipeline is List ? closingPipeline : const [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CLOSING PIPELINE',
            style: GoogleFonts.inter(
              color: AppColors.titleColor,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 10.h),
          if (pipelineItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: _ownerCardDecoration(),
              child: _buildSectionEmptyState(
                'No active closing opportunities for this period.',
              ),
            )
          else
            _buildPipelineCard(
              'Closing opportunities',
              '${pipelineItems.length} match${pipelineItems.length == 1 ? '' : 'es'} in progress',
              _safeProgress(pipelineItems.length, pipelineItems.length),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityRow(
    Widget iconWidget,
    String title,
    String subtitle, {
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: backgroundColor ?? const Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: Center(child: iconWidget),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: AppColors.titleColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.darkGray),
          ],
        ),
      ),
    );
  }

  Widget _buildPerfStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1.08, color: const Color(0xFFF6E5DB)),
          borderRadius: BorderRadius.circular(12.90),
        ),
        shadows: [const BoxShadow(color: Color(0x0C000000))],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.darkGray,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 26.sp,
              fontWeight: FontWeight.w800,
              height: 1.40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String text, bool isSelected, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: isSelected
              ? BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _primaryColor, width: 1),
                )
              : _segmentControl(radius: 22),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value, {
    String? trend,
    Color? trendColor,
    IconData? trendIcon,
    IconData? titleIcon,
    String? label,
    Color? labelColor,
    VoidCallback? onTap,
  }) {
    final metricColor = const Color(0xFFD76322);
    final resolvedTrendColor = trendColor ?? const Color(0xFF009D71);
    final statusColor = labelColor ?? resolvedTrendColor;
    final cardBorderRadius = BorderRadius.circular(8.r);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: cardBorderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 1.5.r,
            offset: Offset(0, 1.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: cardBorderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: cardBorderRadius,
          splashColor: _primaryColor.withValues(alpha: 0.05),
          child: SizedBox(
            width: double.infinity,
            height: 80.h,
            child: Padding(
              padding: EdgeInsets.fromLTRB(15.w, 13.h, 10.w, 10.h),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: Row(
                          children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF302D31),
                                    fontSize: 10.8.sp,
                                    fontWeight: FontWeight.w700,
                                    height: 1.08,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                            ),
                            if (titleIcon != null) ...[
                              SizedBox(width: 3.w),
                              Icon(titleIcon, size: 14.sp, color: metricColor),
                            ],
                          ],
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 5,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                value,
                                maxLines: 1,
                                style: GoogleFonts.inter(
                                  color: metricColor,
                                  fontSize: 23.sp,
                                  fontWeight: FontWeight.w900,
                                  height: 0.95,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Flexible(
                            flex: 4,
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 3.h),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (trend != null)
                                        Text(
                                          trend,
                                          maxLines: 1,
                                          style: GoogleFonts.inter(
                                            color: resolvedTrendColor,
                                            fontSize: 10.5.sp,
                                            fontWeight: FontWeight.w900,
                                            height: 1,
                                          ),
                                        ),
                                      if (label != null)
                                        Text(
                                          label,
                                          maxLines: 1,
                                          style: GoogleFonts.inter(
                                            color: statusColor,
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w900,
                                            height: 1,
                                          ),
                                        ),
                                      if (trendIcon != null) ...[
                                        SizedBox(width: 2.w),
                                        Icon(
                                          trendIcon,
                                          size: 12.sp,
                                          color: statusColor,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildCriticalAlerts(ManagerDashboard? dashboard) {
    final overdueFollowUps =
        dashboard?.followUpControl.fold<int>(
          0,
          (total, item) => total + item.overdueFollowUps,
        ) ??
        0;
    final overdueCallLead = context
        .watch<LeadFollowUpsProvider>()
        .leads
        .where((lead) => lead.hasOverdueFollowUp)
        .cast<LeadFollowUpItem?>()
        .firstWhere((lead) => lead != null, orElse: () => null);
    final pendingReplies = dashboard?.urgent.pendingReplies ?? 0;
    final unassignedLeads = dashboard?.urgent.unassignedLeads ?? 0;
    final staleLeads = dashboard?.urgent.staleLeads ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: ShapeDecoration(
          color: const Color(0x66FFDAD6),
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: Color(0x60BA1A1A)),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  height: 15.h,
                  width: 15.w,
                  child: Image.asset('assets/Triangle_Warning.png'),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Priority Updates',
                  style: GoogleFonts.inter(
                    color: Color(0xFFBA1A1A),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            if (overdueFollowUps == 0 &&
                pendingReplies == 0 &&
                unassignedLeads == 0 &&
                staleLeads == 0)
              _buildAlertRow(
                'No urgent issues',
                'The selected period has no urgent dashboard updates.',
                'Review',
                Icons.check_circle_outline,
                onPressed: null,
              )
            else ...[
              if (overdueFollowUps > 0) ...[
                _buildAlertRow(
                  '$overdueFollowUps follow-ups overdue',
                  'Relationship managers need to re-engage these leads.',
                  'Call',
                  Icons.call_outlined,
                  onPressed: () => _callPhoneNumber(overdueCallLead?.phone),
                ),
                SizedBox(height: 10.h),
              ],
              if (pendingReplies > 0) ...[
                _buildAlertRow(
                  '$pendingReplies pending client replies',
                  'There are conversations waiting for action.',
                  'Review',
                  Icons.mark_email_unread_outlined,
                  onPressed: null,
                ),
                SizedBox(height: 10.h),
              ],
              if (unassignedLeads > 0 || staleLeads > 0)
                _buildAlertRow(
                  unassignedLeads > 0
                      ? '$unassignedLeads unassigned leads'
                      : '$staleLeads stale leads',
                  unassignedLeads > 0
                      ? 'Assign these leads to keep the funnel moving.'
                      : 'Reconnect before these opportunities go cold.',
                  'Assign',
                  Icons.check_circle_outlined,
                  onPressed: null,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertRow(
    String title,
    String subtitle,
    String buttonText,
    IconData icon, {
    VoidCallback? onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.titleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF211A1B),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          /// GAP BETWEEN TEXT & BUTTON
          SizedBox(width: 50.w),

          /// BUTTON
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 17.sp, color: AppColors.primary),
            label: Text(
              buttonText,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryColor,
              side: BorderSide(color: _primaryColor),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  HrEmployeeItem? _findEmployeeForTeamMember(
    ManagerTeamStatusItem item,
    List<HrEmployeeItem> employees,
  ) {
    if (item.id.isNotEmpty) {
      for (final employee in employees) {
        if (employee.id == item.id) {
          return employee;
        }
      }
    }

    final itemName = item.name.trim().toLowerCase();
    if (itemName.isNotEmpty) {
      for (final employee in employees) {
        if (employee.name.trim().toLowerCase() == itemName) {
          return employee;
        }
      }
    }

    return null;
  }

  void _openEmployeeDetail(
    ManagerTeamStatusItem item, {
    required HrEmployeeItem? employee,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            EmployeeDetailScreen(teamMember: item, employee: employee),
      ),
    );
  }

  Widget _buildTeamCard(
    ManagerTeamStatusItem item, {
    required HrEmployeeItem? employee,
  }) {
    final isPresent =
        item.todayAttendanceStatus.toLowerCase().trim() == 'present';
    final statusColor = isPresent
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);
    final statusText = isPresent ? 'Present' : 'Absent';

    return Container(
      width: 124.w,
      margin: EdgeInsets.only(right: 6.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8.r),
        child: InkWell(
          onTap: () => _openEmployeeDetail(item, employee: employee),
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.fromLTRB(6.w, 6.h, 6.w, 7.h),
            child: Column(
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: 94.h,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: (item.image != null && item.image!.isNotEmpty)
                            ? Image.network(
                                item.image!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildTeamImageFallback(item.name);
                                },
                              )
                            : _buildTeamImageFallback(item.name),
                      ),
                    ),
                    Positioned(
                      top: 6.h,
                      right: 6.w,
                      child: Container(
                        width: isPresent ? 11.r : 8.r,
                        height: isPresent ? 11.r : 8.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                          border: Border.all(
                            color: Colors.white,
                            width: isPresent ? 1.8 : 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1F1F1F),
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    height: 1,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat('${item.leadsHandled}', 'Leads'),
                    ),
                    SizedBox(width: 5.w),
                    Expanded(
                      child: _buildMiniStat('${item.tasksCompleted}', 'Calls'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamImageFallback(String name) {
    return Container(
      color: const Color(0xFFF3F4F5),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : "?",
        style: GoogleFonts.inter(
          fontSize: 34.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.titleColor,
        ),
      ),
    );
  }

  Widget _buildTeamStatusPill(String label, int count, Color color) {
    final isPresentPill = label.toLowerCase() == 'present';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPresentPill ? 8.5.w : 7.w,
        vertical: isPresentPill ? 5.h : 4.h,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isPresentPill ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: GoogleFonts.inter(
              color: color,
              fontSize: isPresentPill ? 12.sp : 11.sp,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(width: 3.w),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: isPresentPill ? 9.6.sp : 9.sp,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Container(
      height: 38.h,
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(3.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 1,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.black,
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpControl(
    BuildContext context,
    ManagerDashboard? dashboard,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'FOLLOW-UP CONTROL',
                    style: GoogleFonts.inter(
                      color: Color(0xFF211A1B),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.leadFollowUps);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryColor,
                    side: BorderSide(color: _primaryColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Remind All',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: _primaryColor,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if ((dashboard?.followUpControl.isEmpty ?? true))
              _buildSectionEmptyState(
                'No follow-up ownership data in the selected period.',
              )
            else
              SizedBox(
                height: dashboard!.followUpControl.length > 3 ? 150.h : null,
                child: ListView.separated(
                  itemCount: dashboard.followUpControl.length,
                  shrinkWrap: dashboard.followUpControl.length <= 3,
                  physics: dashboard.followUpControl.length > 3
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  separatorBuilder: (context, index) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    return _buildFollowUpRow(dashboard.followUpControl[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpRow(ManagerFollowUpControlItem item) {
    final actionsProvider = context.watch<FollowUpControlActionsProvider>();
    final teamMemberId = item.id.trim();
    final isSendingMessage = actionsProvider.isSendingMessage(teamMemberId);
    final isSendingVoiceNote = actionsProvider.isSendingVoiceNote(teamMemberId);

    return Row(
      children: [
        _buildFollowUpAvatar(item),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _shortName(item.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF1A1C1A),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              SizedBox(height: 4.h),
              RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${item.pendingFollowUps} Pending',
                      style: GoogleFonts.inter(
                        color: Colors.red.shade700,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    TextSpan(
                      text: ' / ${item.completedFollowUps} Done',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF211A1B),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        _buildRoundIconButton(
          icon: Icons.chat_bubble_outline_rounded,
          background: AppColors.rmPrimary.withValues(alpha: 0.10),
          iconColor: AppColors.rmPrimary,
          isLoading: isSendingMessage,
          onTap: isSendingMessage
              ? null
              : () => _showFollowUpMessageDialog(item),
        ),
        SizedBox(width: 8.w),
        _buildRoundIconButton(
          icon: Icons.mic_none_rounded,
          background: AppColors.rmPrimary,
          iconColor: Colors.white,
          isLoading: isSendingVoiceNote,
          onTap: isSendingVoiceNote
              ? null
              : () => _showFollowUpVoiceNoteDialog(item),
        ),
      ],
    );
  }

  Future<void> _showFollowUpMessageDialog(
    ManagerFollowUpControlItem item,
  ) async {
    final message = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _FollowUpMessageDialog(
        recipientName: item.name,
        initialMessage: _followUpControlMessage(item),
      ),
    );

    final normalizedMessage = message?.trim();
    if (normalizedMessage == null || normalizedMessage.isEmpty) {
      return;
    }

    await _sendFollowUpControlMessage(item, normalizedMessage);
  }

  Future<void> _sendFollowUpControlMessage(
    ManagerFollowUpControlItem item,
    String message,
  ) async {
    final provider = context.read<FollowUpControlActionsProvider>();
    final success = await provider.sendMessage(
      accessToken: context.read<AuthProvider>().userModel?.accessToken,
      teamMemberId: item.id,
      message: message,
    );
    debugPrint(
      'Owner follow-up message result -> success=$success teamMemberId=${item.id}',
    );

    if (!mounted) {
      return;
    }

    _showDashboardMessage(
      success
          ? 'Follow-up message sent for ${_shortName(item.name)}.'
          : provider.error ?? 'Unable to send follow-up message.',
    );
  }

  Future<void> _showFollowUpVoiceNoteDialog(
    ManagerFollowUpControlItem item,
  ) async {
    final voiceNote = await showDialog<_RecordedVoiceNote>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _FollowUpVoiceNoteDialog(recipientName: item.name),
    );

    if (voiceNote == null) {
      return;
    }

    await _sendFollowUpControlVoiceNote(item, voiceNote);
  }

  Future<void> _sendFollowUpControlVoiceNote(
    ManagerFollowUpControlItem item,
    _RecordedVoiceNote voiceNote,
  ) async {
    final provider = context.read<FollowUpControlActionsProvider>();
    final success = await provider.sendVoiceNote(
      accessToken: context.read<AuthProvider>().userModel?.accessToken,
      teamMemberId: item.id,
      audioPath: voiceNote.path,
      durationSeconds: voiceNote.durationSeconds,
    );
    debugPrint(
      'Owner follow-up voice-note result -> success=$success teamMemberId=${item.id}',
    );

    if (!mounted) {
      return;
    }

    _showDashboardMessage(
      success
          ? 'Voice note triggered for ${_shortName(item.name)}.'
          : provider.error ?? 'Unable to send follow-up voice note.',
    );
  }

  Widget _buildFollowUpAvatar(ManagerFollowUpControlItem item) {
    final image = item.image?.trim();

    return CircleAvatar(
      radius: 19.r,
      backgroundColor: AppColors.rmPrimary.withValues(alpha: 0.10),
      backgroundImage: image != null && image.isNotEmpty
          ? NetworkImage(image)
          : null,
      child: image == null || image.isEmpty
          ? Text(
              _initialsForName(item.name),
              style: GoogleFonts.inter(
                color: AppColors.rmPrimary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
              ),
            )
          : null,
    );
  }

  String _followUpControlMessage(ManagerFollowUpControlItem item) {
    final pendingText = item.pendingFollowUps == 1
        ? '1 pending follow-up'
        : '${item.pendingFollowUps} pending follow-ups';
    return 'Please complete $pendingText for your assigned leads.';
  }

  String _shortName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'Team Member';
    }

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first;
    }

    return '${parts.first} ${parts.last[0].toUpperCase()}.';
  }

  Widget _buildRoundIconButton({
    required IconData icon,
    required Color background,
    required Color iconColor,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34.r,
        height: 34.r,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: isLoading
            ? Padding(
                padding: EdgeInsets.all(9.r),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor,
                ),
              )
            : Icon(icon, size: 17.sp, color: iconColor),
      ),
    );
  }

  Widget _buildPipelineCard(String name, String details, double probability) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _ownerCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'NEGOTIATION',
              style: GoogleFonts.inter(
                color: Colors.orange[700],
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              const Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: AssetImage('assets/wedding_hero 1.png'),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: AssetImage('assets/wedding_hero 1.png'),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 28.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      color: AppColors.titleColor,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    details,
                    style: GoogleFonts.inter(
                      color: AppColors.titleColor,
                      fontSize: 17.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Closing Probability',
                style: GoogleFonts.inter(
                  color: AppColors.titleColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(probability * 100).toInt()}%',
                style: GoogleFonts.inter(
                  color: AppColors.titleColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          LinearProgressIndicator(
            value: probability,
            backgroundColor: Colors.grey[200],
            color: Colors.green[700],
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Push Match',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityChip(String title, String category) {
    final bool isSelected = selectedCategory == category;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }
}

class ProfileShortlistCard {
  const ProfileShortlistCard();
}

enum _AgencyReportPeriod { all, weekly, monthly, custom }

class _AgencyReportPeriodButton extends StatelessWidget {
  const _AgencyReportPeriodButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38.h,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? AppColors.primary : AppColors.white,
          foregroundColor: selected ? AppColors.white : const Color(0xFF111111),
          side: BorderSide(
            color: selected ? AppColors.primary : const Color(0xFFE8DED6),
          ),
          padding: EdgeInsets.symmetric(horizontal: 17.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.r),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _AgencyReportDropdownField extends StatelessWidget {
  const _AgencyReportDropdownField({
    required this.label,
    required this.hintText,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String hintText;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final currentValue = options.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AgencyReportFilterLabel(label),
        SizedBox(height: 7.h),
        DropdownButtonFormField<String>(
          initialValue: currentValue,
          isExpanded: true,
          dropdownColor: AppColors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: const Color(0xFFE3CABE),
            size: 19.sp,
          ),
          decoration: _agencyReportFieldDecoration(),
          hint: _AgencyReportOptionText(hintText, muted: true),
          items: [
            DropdownMenuItem<String>(
              value: '',
              child: _AgencyReportOptionText(hintText, muted: true),
            ),
            ...options.map(
              (option) => DropdownMenuItem<String>(
                value: option,
                child: _AgencyReportOptionText(option),
              ),
            ),
          ],
          onChanged: (nextValue) => onChanged(
            nextValue == null || nextValue.isEmpty ? null : nextValue,
          ),
        ),
      ],
    );
  }
}

class _AgencyReportMultiSelectField extends StatelessWidget {
  const _AgencyReportMultiSelectField({
    required this.label,
    required this.valueText,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
  });

  final String label;
  final String valueText;
  final List<String> options;
  final Set<String> selectedValues;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AgencyReportFilterLabel(label),
        SizedBox(height: 7.h),
        InkWell(
          borderRadius: BorderRadius.circular(6.r),
          onTap: () async {
            final selected = await showModalBottomSheet<Set<String>>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => _AgencyReportRmSelectorSheet(
                options: options,
                selectedValues: selectedValues,
              ),
            );

            if (selected != null) {
              onChanged(selected);
            }
          },
          child: InputDecorator(
            decoration: _agencyReportFieldDecoration(),
            child: Row(
              children: [
                Expanded(
                  child: _AgencyReportOptionText(
                    valueText,
                    muted: selectedValues.isEmpty,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFFE3CABE),
                  size: 19.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AgencyReportRmSelectorSheet extends StatefulWidget {
  const _AgencyReportRmSelectorSheet({
    required this.options,
    required this.selectedValues,
  });

  final List<String> options;
  final Set<String> selectedValues;

  @override
  State<_AgencyReportRmSelectorSheet> createState() =>
      _AgencyReportRmSelectorSheetState();
}

class _AgencyReportRmSelectorSheetState
    extends State<_AgencyReportRmSelectorSheet> {
  late Set<String> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = {...widget.selectedValues};
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: 0.72.sh),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Relationship Managers',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1F1C19),
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedValues.clear()),
                    child: Text(
                      'Clear',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0E2D8)),
            Flexible(
              child: widget.options.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Text(
                          'No relationship managers available.',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF6B6662),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: widget.options.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: Color(0xFFF7EEE9)),
                      itemBuilder: (context, index) {
                        final option = widget.options[index];
                        return CheckboxListTile(
                          value: _selectedValues.contains(option),
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedValues.add(option);
                              } else {
                                _selectedValues.remove(option);
                              }
                            });
                          },
                          activeColor: AppColors.primary,
                          checkColor: AppColors.white,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            option,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF211A1B),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 16.h),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_selectedValues),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    minimumSize: Size.fromHeight(46.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Apply Selection',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgencyReportFilterLabel extends StatelessWidget {
  const _AgencyReportFilterLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        color: const Color(0xFF211A1B),
        fontSize: 13.sp,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _AgencyReportOptionText extends StatelessWidget {
  const _AgencyReportOptionText(this.text, {this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        color: muted ? const Color(0xFF77716C) : const Color(0xFF211A1B),
        fontSize: 12.sp,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

InputDecoration _agencyReportFieldDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: AppColors.white,
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 12.h),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6.r),
      borderSide: const BorderSide(color: Color(0xFFF0E2D8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6.r),
      borderSide: const BorderSide(color: AppColors.primary),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6.r),
      borderSide: const BorderSide(color: Color(0xFFF0E2D8)),
    ),
  );
}

class _FollowUpMessageDialog extends StatefulWidget {
  const _FollowUpMessageDialog({
    required this.recipientName,
    required this.initialMessage,
  });

  final String recipientName;
  final String initialMessage;

  @override
  State<_FollowUpMessageDialog> createState() => _FollowUpMessageDialogState();
}

class _FollowUpMessageDialogState extends State<_FollowUpMessageDialog> {
  static const int _maxMessageLength = 500;
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: widget.initialMessage)
      ..addListener(_onMessageChanged);
  }

  @override
  void dispose() {
    _messageController
      ..removeListener(_onMessageChanged)
      ..dispose();
    super.dispose();
  }

  void _onMessageChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final messageLength = _messageController.text.characters.length;
    final canSend = _messageController.text.trim().isNotEmpty;

    return Dialog(
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 430.w),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 18.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Send Message',
                      style: GoogleFonts.inter(
                        color: AppColors.rmHeading,
                        fontSize: 25.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tight(Size(30.r, 30.r)),
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.rmMutedText,
                      size: 19.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                'Send an internal message to ${widget.recipientName}.',
                style: GoogleFonts.inter(
                  color: AppColors.rmBodyText,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCF7F8),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE6D7DC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RECIPIENT',
                      style: GoogleFonts.inter(
                        color: AppColors.rmMutedText,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      widget.recipientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.rmHeading,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Message',
                style: GoogleFonts.inter(
                  color: AppColors.rmHeading,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _messageController,
                maxLength: _maxMessageLength,
                maxLines: 5,
                minLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Type your message here',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFFB7ADB1),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: const BorderSide(color: Color(0xFFD9D4D6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: const BorderSide(
                      color: Color(0xFFD9D4D6),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: const BorderSide(
                      color: AppColors.rmPrimary,
                      width: 1.6,
                    ),
                  ),
                ),
                style: GoogleFonts.inter(
                  color: AppColors.rmHeading,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Maximum 500 characters',
                      style: GoogleFonts.inter(
                        color: AppColors.rmBodyText,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '$messageLength/$_maxMessageLength',
                    style: GoogleFonts.inter(
                      color: AppColors.rmBodyText,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 28.h),
              const Divider(height: 1, color: Color(0xFFEDE6E8)),
              SizedBox(height: 18.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.rmHeading,
                      side: const BorderSide(color: Color(0xFFE6D7DC)),
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  SizedBox(width: 14.w),
                  ElevatedButton(
                    onPressed: canSend
                        ? () => Navigator.of(
                            context,
                          ).pop(_messageController.text.trim())
                        : null,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.45,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('Send Message'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordedVoiceNote {
  const _RecordedVoiceNote({required this.path, required this.durationSeconds});

  final String path;
  final int durationSeconds;
}

class _FollowUpVoiceNoteDialog extends StatefulWidget {
  const _FollowUpVoiceNoteDialog({required this.recipientName});

  final String recipientName;

  @override
  State<_FollowUpVoiceNoteDialog> createState() =>
      _FollowUpVoiceNoteDialogState();
}

class _FollowUpVoiceNoteDialogState extends State<_FollowUpVoiceNoteDialog> {
  static const int _maxDurationSeconds = 60;

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;
  bool _isRecording = false;
  bool _isPreparing = false;
  bool _isPlayingPreview = false;
  String? _recordingPath;
  int _durationSeconds = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _isPlayingPreview = false);
      }
    });
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted && state != PlayerState.playing && _isPlayingPreview) {
        setState(() => _isPlayingPreview = false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
      return;
    }

    await _startRecording();
  }

  Future<void> _startRecording() async {
    setState(() {
      _isPreparing = true;
      _error = null;
    });

    try {
      await _stopPreview();
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        setState(() {
          _error = 'Microphone permission is required to record a voice note.';
          _isPreparing = false;
        });
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/follow_up_voice_${DateTime.now().microsecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );

      _timer?.cancel();
      setState(() {
        _recordingPath = null;
        _durationSeconds = 0;
        _isRecording = true;
        _isPreparing = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }

        final nextDuration = _durationSeconds + 1;
        setState(() {
          _durationSeconds = nextDuration;
        });

        if (nextDuration >= _maxDurationSeconds) {
          await _stopRecording();
        }
      });
    } catch (error) {
      setState(() {
        _error = 'Unable to start recording.';
        _isPreparing = false;
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _timer = null;

    try {
      final path = await _recorder.stop();
      if (!mounted) {
        return;
      }

      setState(() {
        _recordingPath = path;
        _isRecording = false;
        _isPreparing = false;
        if (_durationSeconds == 0) {
          _durationSeconds = 1;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Unable to stop recording.';
        _isRecording = false;
        _isPreparing = false;
      });
    }
  }

  Future<void> _togglePreview() async {
    final path = _recordingPath;
    if (path == null || _isRecording || _isPreparing) {
      return;
    }

    if (_isPlayingPreview) {
      await _stopPreview();
      return;
    }

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(path));
      if (mounted) {
        setState(() {
          _isPlayingPreview = true;
          _error = null;
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPlayingPreview = false;
        _error = 'Unable to preview this recording.';
      });
    }
  }

  Future<void> _stopPreview() async {
    await _audioPlayer.stop();
    if (mounted && _isPlayingPreview) {
      setState(() => _isPlayingPreview = false);
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hasRecording = _recordingPath != null;
    final canSend = hasRecording && !_isRecording && !_isPreparing;
    final statusText = _isRecording
        ? 'Recording...'
        : hasRecording
        ? 'Recording ready'
        : 'No recording yet';

    return Dialog(
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 430.w),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 18.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Send Voice Note',
                      style: GoogleFonts.inter(
                        color: AppColors.rmHeading,
                        fontSize: 25.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tight(Size(30.r, 30.r)),
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.rmMutedText,
                      size: 19.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                'Record and send an internal voice note to ${widget.recipientName}.',
                style: GoogleFonts.inter(
                  color: AppColors.rmBodyText,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCF7F8),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE6D7DC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RECIPIENT',
                      style: GoogleFonts.inter(
                        color: AppColors.rmMutedText,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      widget.recipientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.rmHeading,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE6D7DC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            statusText,
                            style: GoogleFonts.inter(
                              color: _isRecording
                                  ? AppColors.primary
                                  : AppColors.rmHeading,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          _formatDuration(_durationSeconds),
                          style: GoogleFonts.inter(
                            color: AppColors.rmHeading,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Maximum duration: 60 seconds',
                      style: GoogleFonts.inter(
                        color: AppColors.rmBodyText,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_error != null) ...[
                      SizedBox(height: 8.h),
                      Text(
                        _error!,
                        style: GoogleFonts.inter(
                          color: AppColors.error,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    SizedBox(height: 18.h),
                    OutlinedButton(
                      onPressed: _isPreparing ? null : _toggleRecording,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: Color(0xFFEED7CF)),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        textStyle: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(
                        _isPreparing
                            ? 'Preparing...'
                            : _isRecording
                            ? 'Stop Recording'
                            : hasRecording
                            ? 'Record Again'
                            : 'Start Recording',
                      ),
                    ),
                    if (hasRecording && !_isRecording) ...[
                      SizedBox(height: 10.h),
                      OutlinedButton.icon(
                        onPressed: _isPreparing ? null : _togglePreview,
                        icon: Icon(
                          _isPlayingPreview
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          size: 18.sp,
                        ),
                        label: Text(
                          _isPlayingPreview ? 'Stop Preview' : 'Preview Audio',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.rmHeading,
                          side: const BorderSide(color: Color(0xFFE6D7DC)),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          textStyle: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 40.h),
              const Divider(height: 1, color: Color(0xFFEDE6E8)),
              SizedBox(height: 18.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      await _stopPreview();
                      if (context.mounted) {
                        Navigator.of(context).maybePop();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.rmHeading,
                      side: const BorderSide(color: Color(0xFFE6D7DC)),
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  SizedBox(width: 14.w),
                  ElevatedButton(
                    onPressed: canSend
                        ? () async {
                            await _stopPreview();
                            if (context.mounted) {
                              Navigator.of(context).pop(
                                _RecordedVoiceNote(
                                  path: _recordingPath!,
                                  durationSeconds: _durationSeconds,
                                ),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.45,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('Send Voice Note'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
