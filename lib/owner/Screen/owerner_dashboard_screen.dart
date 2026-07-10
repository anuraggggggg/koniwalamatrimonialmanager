import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/models/manager_dashboard.dart';
import 'package:koniwalamatrimonial/owner/models/hr_employee_item.dart';
import 'package:koniwalamatrimonial/owner/models/lead_follow_up_item.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/providers/manager_dashboard_provider.dart';
import 'package:koniwalamatrimonial/owner/providers/hr_employees_provider.dart';
import 'package:koniwalamatrimonial/owner/providers/lead_follow_ups_provider.dart';
import 'package:koniwalamatrimonial/widgets/koniwala_primary_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../routes/app_routes.dart';
import 'registry_screen.dart';
import 'leads_registry_screen.dart';
import 'client_registry_screen.dart';
import '../providers/dashboard_provider.dart';
import 'profile_digitizer_screen.dart';
import 'profile_screen.dart';

class OwernerDashboardScreen extends StatefulWidget {
  const OwernerDashboardScreen({super.key});

  @override
  State<OwernerDashboardScreen> createState() => _OwernerDashboardScreenState();
}

class _OwernerDashboardScreenState extends State<OwernerDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const List<int> _visibleBottomNavTabs = [0, 1, 2, 5];

  int _bottomNavIndexForTab(int selectedIndex) {
    final visibleIndex = _visibleBottomNavTabs.indexOf(selectedIndex);
    return visibleIndex == -1 ? 0 : visibleIndex;
  }

  int _tabIndexForBottomNav(int bottomNavIndex) {
    return _visibleBottomNavTabs[bottomNavIndex];
  }

  List<Widget> _buildScreens() {
    return [
      const HomeView(),
      RegistryScreen(
        onMenuPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.adminDrawer),
      ),
      LeadsRegistryScreen(
        onMenuPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.adminDrawer),
      ),
      ClientRegistryScreen(
        onMenuPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.adminDrawer),
      ),
      const ProfileDigitizerScreen(embeddedInDashboard: true),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        textTheme: GoogleFonts.manropeTextTheme(theme.textTheme),
        primaryTextTheme: GoogleFonts.manropeTextTheme(theme.primaryTextTheme),
      ),
      child: Consumer<DashboardProvider>(
        builder: (context, dashboardProvider, _) {
          final rawSelectedIndex = dashboardProvider.selectedIndex;
          final selectedIndex = rawSelectedIndex == 3 ? 0 : rawSelectedIndex;

          if (rawSelectedIndex != selectedIndex) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.read<DashboardProvider>().selectTab(selectedIndex);
              }
            });
          }

          final showParentAppBar =
              selectedIndex != 2 &&
              selectedIndex != 3 &&
              selectedIndex != 4 &&
              selectedIndex != 5;

          return Scaffold(
            key: _scaffoldKey,
            drawerScrimColor: Colors.black.withValues(alpha: 0.1),
            // drawerElevation: 0,
            backgroundColor: AppColors.rmSoftPink,
            appBar: showParentAppBar
                ? KoniwalaPrimaryAppBar(
                    showMenuButton: true,
                    onMenuPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.adminDrawer),
                  )
                : null,
            body: IndexedStack(
              index: selectedIndex,
              children: _buildScreens(),
            ),
            bottomNavigationBar: _buildBottomNav(context, selectedIndex),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    int selectedIndex,
  ) {
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
          context
              .read<DashboardProvider>()
              .selectTab(_tabIndexForBottomNav(index));
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12.sp,
        unselectedFontSize: 11.sp,
        selectedLabelStyle: GoogleFonts.manrope(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.manrope(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: _bottomNavImageIcon(Colors.grey),
            activeIcon: _bottomNavImageIcon(AppColors.primary),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined, size: 24),
            activeIcon: Icon(Icons.groups_rounded, size: 24),
            label: 'Matches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_search_outlined, size: 24),
            activeIcon: Icon(Icons.person_search_rounded, size: 24),
            label: 'Leads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded, size: 24),
            activeIcon: Icon(Icons.person_rounded, size: 24),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _bottomNavImageIcon(Color color) {
    return Image.asset(
      'assets/icon/dashbaord_icon.png',
      width: 24,
      height: 24,
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
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              'Admin',
                              style: GoogleFonts.manrope(
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
                      style: GoogleFonts.manrope(
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
                  _AdminDrawerItem(
                    label: 'Support',
                    icon: Icons.support_agent_outlined,
                    selected: false,
                    onTap: () => Navigator.of(context).maybePop(),
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
                            style: GoogleFonts.manrope(
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
                            style: GoogleFonts.manrope(
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
            style: GoogleFonts.manrope(
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
            style: GoogleFonts.manrope(
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
                    style: GoogleFonts.manrope(
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
      color: Colors.white

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

    final normalizedPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
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
    final activeCount = hrEmployees.where((employee) => employee.isActive).length;
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
                        style: GoogleFonts.manrope(
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
    final hrPresentCount = hrEmployees
        .where((employee) => employee.isPresentToday)
        .length;
    final callLeads = followUpsProvider.leads
        .where((lead) => lead.openFollowUps.isNotEmpty)
        .toList();
    final openCallTasks = _openCallTaskCount(followUpsProvider.leads);
    final hrMetricValue =
        employeesProvider.error != null && hrEmployees.isEmpty
        ? '--'
        : '${hrEmployees.length}';
    final hrMetricLabel = employeesProvider.isLoading
        ? 'Syncing'
        : employeesProvider.error != null && hrEmployees.isEmpty
        ? 'Unavailable'
        : '$hrPresentCount present';
    final callMetricValue =
        followUpsProvider.error != null && followUpsProvider.leads.isEmpty
        ? '--'
        : '$openCallTasks';
    final callMetricLabel = followUpsProvider.isLoading
        ? 'Syncing'
        : followUpsProvider.error != null && followUpsProvider.leads.isEmpty
        ? 'Unavailable'
        : '${callLeads.length} leads';
    final hrMetricLabelColor = employeesProvider.isLoading
        ? Colors.blueGrey[600]
        : employeesProvider.error != null && hrEmployees.isEmpty
        ? Colors.red[700]
        : Colors.green[700];
    final callMetricLabelColor = followUpsProvider.isLoading
        ? Colors.blueGrey[600]
        : followUpsProvider.error != null && followUpsProvider.leads.isEmpty
        ? Colors.red[700]
        : Colors.green[700];
    final presentCount =
        dashboard?.liveTeamStatus
            .where(
              (item) => item.todayAttendanceStatus.toLowerCase() == 'present',
            )
            .length ??
        0;
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

    final filteredActivities = dashboard?.recentActivity
        .where((activity) => activity.category == selectedCategory)
        .toList() ??
        [];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32),
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
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 24.h,
                    backgroundColor: AppColors.rmPrimary.withValues(
                      alpha: 0.12,
                    ),
                    backgroundImage: userImage != null && userImage.isNotEmpty
                        ? NetworkImage(userImage)
                        : null,
                    child: userImage == null || userImage.isEmpty
                        ? ClipOval(
                            child: Image.asset(
                              'assets/wedding_hero 1.png',
                              width: 48.w,
                              height: 48.h,
                              fit: BoxFit.cover,
                            ),
                          )
                        : null,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    '${_greetingForHour()} ${_firstName(user?.name)}!',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      color: Color(0xFF312F2F),
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KMS BUSINESS SNAPSHOT',
                  style: GoogleFonts.manrope(
                    color: Color(0xFF211A1B),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 15.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final entry in _periodTabs.entries) ...[
                        _buildTab(
                          entry.key,
                          entry.value == _selectedPeriod,
                          () => _selectPeriod(entry.value),
                        ),
                        SizedBox(width: 6.w),
                      ],
                    ],
                  ),
                ),
                // if ((dashboard?.period.displayText ?? '').isNotEmpty) ...[
                //   SizedBox(height: 12.h),
                //   Text(
                //     dashboard!.period.displayText,
                //     style: GoogleFonts.manrope(
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
                          style: GoogleFonts.manrope(
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
          SizedBox(height: 20.h),

          // Stats Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'NEW LEADS',
                        _formatCompactNumber(kpi?.matchesToday ?? 0),
                        trend: '+12%',
                        trendColor: const Color(0xFF0E9F6E),
                        hasTrendIcon: true,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Expanded(
                      child: _buildStatCard(
                        'TOTAL LEADS',
                        _formatCompactNumber(kpi?.totalLeads ?? 0),
                        // label: 'Stable',
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Expanded(
                      child: _buildStatCard(
                        'CONVERSIONS',
                        '${kpi?.conversionRate ?? 0}',
                        trend: '+2',
                        trendColor: const Color(0xFF0E9F6E),
                        labelIcon: Icons.check_circle_outline_rounded,
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
                        trend: '-8%!',
                        trendColor: const Color(0xFFC62828),
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Expanded(
                      child: _buildStatCard(
                        'ACTIVE CLIENTS',
                        _formatCompactNumber(kpi?.activeProfiles ?? 0),
                        trend: '+18%',
                        trendColor: const Color(0xFF0E9F6E),
                        hasCycleIcon: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 25.h),

          // Critical Alerts
          _buildConnectivitySection(child: _buildCriticalAlerts(dashboard)),



    _buildConnectivitySection(
    child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [const SizedBox(height: 16),

    Text('LIVE TEAM STATUS',style: GoogleFonts.manrope(fontSize: 20,
    fontWeight: FontWeight.w600, letterSpacing: 0.5,),),

    SizedBox(height: 16.h),

    if (dashboard?.liveTeamStatus.isEmpty ?? true)
    _buildSectionEmptyState(
    'No team activity available yet.',
    ) else
    SizedBox(height: 220.h, // Give the horizontal ListView a fixed height
    child: ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: dashboard!.liveTeamStatus.take(8).length,
    itemBuilder: (context, index) {
    final item = dashboard.liveTeamStatus[index];
    return _buildTeamCard(item);},),),],),),),
          SizedBox(height: 25.h),

          // Follow-up Control
          _buildConnectivitySection(
            child: _buildFollowUpControl(context, dashboard),
          ),

          SizedBox(height: 25.h),

          // Closing Pipeline
          _buildConnectivitySection(
            child: _buildClosingPipelineSection(dashboard),
          ),

          SizedBox(height: 25.h),
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
                        style: GoogleFonts.manrope(
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
                          color: Colors.black.withOpacity(.04),
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
                        for (int index = 0;
                        index < filteredActivities.take(5).length;
                        index++) ...[
                          if (index != 0)
                            Divider(
                              height: 24.h,
                              color: const Color(0xFFEAEAEA),
                            ),

                          _buildActivityRow(
                            Icon(
                              _activityIconForItem(filteredActivities[index]),
                              size: 20.sp,
                              color: _activityColorForItem(
                                filteredActivities[index],
                              ),
                            ),
                            filteredActivities[index].title,
                            filteredActivities[index].description,
                            backgroundColor: _activityColorForItem(
                              filteredActivities[index],
                            ).withOpacity(.12),
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
          SizedBox(height: 25.h),

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
                      style: GoogleFonts.manrope(
                        color: Color(0xFF181C1F),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),

                    SizedBox(height: 12.h),
                    Text(
                      'Group attendance, KPIs, and task progress in one section',
                      style: GoogleFonts.manrope(
                        color: Color(0xFF424754),
                        fontSize: 12,
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
                          style: GoogleFonts.manrope(
                            color: Color(0xFF181C1F),
                            fontSize: 14,
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
                            style: GoogleFonts.manrope(
                              color: AppColors.reddishBrown,
                              fontSize: 14,
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
          SizedBox(height: 25.h),

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
                    colors: [
                      Color(0xFF570013),
                      Color(0xFF800020),
                    ],
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
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      primarySuggestion?.description ??
                          primaryAiTask?.title ??
                          'No AI suggestions are available for this period.',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(
                          flex : 3,
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
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              primarySuggestion?.actionLabel ?? 'Execute',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.bold,
                                fontSize: 11  ,


                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          flex : 1,
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
                              style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold),

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
          SizedBox(height: 25.h),

          // Agency Growth Projection
          _buildConnectivitySection(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: _ownerCardDecoration(),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Agency Growth Projection',
                          style: GoogleFonts.manrope(
                            color: Color(0xFF181C1F),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Based on current RM performance and lead inflow',
                        style: GoogleFonts.manrope(
                          color: Color(0xFF424754),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    SizedBox(height: 40.h),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: CircularProgressIndicator(
                            value: _safeProgress(
                              agencyPerformance?.overallConversionRate ?? 0,
                              100,
                            ),
                            strokeWidth: 18,
                            backgroundColor: Colors.grey[200],
                            color: _primaryColor,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Text(
                          '${agencyPerformance?.overallConversionRate ?? 0}%',
                          style: GoogleFonts.manrope(
                            color: AppColors.primary,
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 40.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGrowthStat(
                            'Closed Clients',
                            '${agencyPerformance?.closedClients ?? 0}',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: Colors.grey[200],
                        ),
                        Expanded(
                          child: _buildGrowthStat(
                            'Task Completion',
                            '${agencyPerformance?.taskCompletionRate ?? 0}%',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15.h),
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

                          _showAgencyReport(dashboard);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary,),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'View full report',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primary
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 25.h),

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
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 22,
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
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontSize: 54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'LOST THIS MONTH',
                              style: GoogleFonts.manrope(
                                color: const Color(0xFFA8A29E),
                                fontSize: 15,
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
                          style: GoogleFonts.manrope(
                            color: Color(0xFFF2F1EE),
                            fontSize: 15,
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
          SizedBox(height: 25.h),

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
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color:  AppColors.whatsappGreen
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
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '420 auto-actions triggered today',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    InkWell(
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.adminSettings),
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
          SizedBox(height: 122.h),
        ],
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
              style: GoogleFonts.manrope(
                color: Color(0xFF2C2B2B),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.manrope(
                color: Color(0xFF2C2B2B),
                fontSize: 17,
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
              style: GoogleFonts.manrope(
                color: Colors.grey[600],
                fontSize: 14,
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

  Widget _buildGrowthStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            color: const Color(0xFF424754),
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 1.14,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: GoogleFonts.manrope(fontSize: 30, fontWeight: FontWeight.bold),
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
          style: GoogleFonts.manrope(color: Colors.white, fontSize: 14),
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

  void _showAgencyReport(ManagerDashboard dashboard) {
    final performance = dashboard.agencyPerformance;
    final kpi = dashboard.kpi;
    final onlineCount = dashboard.liveTeamStatus
        .where((item) => item.status.toLowerCase() == 'online')
        .length;
    final presentCount = dashboard.liveTeamStatus
        .where(
          (item) => item.todayAttendanceStatus.toLowerCase() == 'present',
        )
        .length;
    final totalTasksCompleted = dashboard.liveTeamStatus.fold<int>(
      0,
      (total, item) => total + item.tasksCompleted,
    );
    final totalProfilesHandled = dashboard.liveTeamStatus.fold<int>(
      0,
      (total, item) => total + item.profilesHandled,
    );
    final totalLeadsHandled = dashboard.liveTeamStatus.fold<int>(
      0,
      (total, item) => total + item.leadsHandled,
    );

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
                        'Agency Report',
                        style: GoogleFonts.manrope(
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
                if (dashboard.period.displayText.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    dashboard.period.displayText,
                    style: GoogleFonts.manrope(
                      color: const Color(0xFF6E5C61),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                SizedBox(height: 18.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildReportMetric(
                        'Conversion',
                        '${performance.overallConversionRate}%',
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _buildReportMetric(
                        'Closed',
                        '${performance.closedClients}',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildReportMetric(
                        'Tasks',
                        '${performance.taskCompletionRate}%',
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _buildReportMetric(
                        'Revenue',
                        _formatRevenue(kpi.revenue),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                _buildReportRow('Total leads', '${kpi.totalLeads}'),
                _buildReportRow('Active profiles', '${kpi.activeProfiles}'),
                _buildReportRow('Matches today', '${kpi.matchesToday}'),
                _buildReportRow('Follow-ups due', '${kpi.followUpsDue}'),
                _buildReportRow('Team online', '$onlineCount'),
                _buildReportRow('Present today', '$presentCount'),
                _buildReportRow('Leads handled', '$totalLeadsHandled'),
                _buildReportRow('Profiles handled', '$totalProfilesHandled'),
                _buildReportRow('Tasks completed', '$totalTasksCompleted'),
              ],
            ),
          ),
        );
      },
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
            style: GoogleFonts.manrope(
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
            style: GoogleFonts.manrope(
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
              style: GoogleFonts.manrope(
                color: const Color(0xFF424754),
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
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
                        style: GoogleFonts.manrope(
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
                    style: GoogleFonts.manrope(
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
                _buildDarkReportRow('Conversion rate', '${kpi.conversionRate}%'),
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
            style: GoogleFonts.manrope(
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
            style: GoogleFonts.manrope(
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
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$value%',
              style: GoogleFonts.manrope(
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
              style: GoogleFonts.manrope(
                color: const Color(0xFFA8A29E),
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
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

  String _formatRevenue(int value) {
    if (value >= 10000000) {
      return 'Rs ${(value / 10000000).toStringAsFixed(1)}Cr';
    }
    if (value >= 100000) {
      return 'Rs ${(value / 100000).toStringAsFixed(1)}L';
    }
    if (value >= 1000) {
      return 'Rs ${(value / 1000).toStringAsFixed(1)}K';
    }
    return 'Rs $value';
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

  double _safeProgress(int numerator, int denominator) {
    if (denominator <= 0) {
      return 0;
    }
    return (numerator / denominator).clamp(0, 1).toDouble();
  }

  String _formatRoleLabel(String role) {
    return role
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
      case 'present':
        return Colors.green;
      case 'offline':
      case 'absent':
        return Colors.red;
      default:
        return Colors.orange;
    }
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
        style: GoogleFonts.manrope(
          color: const Color(0xFF6E5C61),
          fontSize: 14,
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
            style: GoogleFonts.manrope(
              fontSize: 20,
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
                    style: GoogleFonts.manrope(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 12.sp,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.darkGray
            ),
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
            style: GoogleFonts.manrope(
              color: AppColors.darkGray,
              fontSize: 10,
              fontWeight: FontWeight.w700,

            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: color,
              fontSize: 26,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6
          ),
          decoration: isSelected
              ? BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _primaryColor, width: 1),
                )
              : _segmentControl(radius: 22),
          child: Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 12,
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
    bool hasTrendIcon = false,
    bool hasCycleIcon = false,
    String? label,
    Color? labelColor,
    IconData? labelIcon,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(18),
        splashColor: _primaryColor.withValues(alpha: 0.05),
        child: Container(


          width: double.infinity,
          constraints: BoxConstraints(minHeight: 96.h),
          padding: const EdgeInsets.all(8),
          decoration: _ownerCardDecoration(radius: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Center(
                    child: Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF302D31),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 12, right: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        value,
                        style: GoogleFonts.manrope(
                          color: AppColors.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (trend != null)
                              Flexible(
                                child: Text(
                                  trend,
                                  style: GoogleFonts.manrope(
                                    color: trendColor ?? Colors.green[700],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (hasTrendIcon)
                              Padding(
                                padding: EdgeInsets.only(
                                  left: trend != null ? 4.0 : 0.0,
                                ),
                                child: Icon(
                                  Icons.trending_up,
                                  size: 14,
                                  color: trendColor ?? Colors.green[700],
                                ),
                              ),
                            if (hasCycleIcon)
                              Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Icon(
                                  Icons.sync,
                                  size: 14,
                                  color: trendColor ?? const Color(0xFF388E3C),
                                ),
                              ),
                            if (label != null)
                              Flexible(
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 3.h),
                                  child: Text(
                                    label,
                                    style: GoogleFonts.manrope(
                                      color:
                                          labelColor ??
                                          (label == 'Stable'
                                              ? Colors.orange[700]
                                              : Colors.green[700]),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            if (labelIcon != null)
                              Padding(
                                padding: EdgeInsets.only(
                                  left: label != null ? 4.0 : 0.0,
                                ),
                                child: Icon(
                                  labelIcon,
                                  size: 14,
                                  color: trendColor ?? Colors.green[700],
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
        padding: const EdgeInsets.all(24),
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
                  height: 30.h,
                  width: 30.w,
                  child: Image.asset('assets/Triangle_Warning.png'),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Critical Alerts',
                  style: GoogleFonts.manrope(
                    color: Color(0xFFBA1A1A),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            if (overdueFollowUps == 0 &&
                pendingReplies == 0 &&
                unassignedLeads == 0 &&
                staleLeads == 0)
              _buildAlertRow(
                'No urgent issues',
                'The selected period has no critical dashboard alerts.',
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
                SizedBox(height: 16.h),
              ],
              if (pendingReplies > 0) ...[
                _buildAlertRow(
                  '$pendingReplies pending client replies',
                  'There are conversations waiting for action.',
                  'Review',
                  Icons.mark_email_unread_outlined,
                  onPressed: null,
                ),
                SizedBox(height: 16.h),
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
  }
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    color: Colors.grey[500],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100.w,
          ),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 17, color: AppColors.primary),
            label: Text(
              buttonText,
              style: GoogleFonts.manrope(
                fontSize: 12,
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

  Widget _buildTeamCard(ManagerTeamStatusItem item) {
    final statusColor = _statusColor(item.status);

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 8),
      decoration: _ownerCardDecoration(),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 12, left: 2 , right: 2),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [

                    SizedBox(
                      height: 90.h,
                      width: 150.w,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: (item.image != null && item.image!.isNotEmpty)
                            ? Image.network(
                          item.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.white,
                              alignment: Alignment.center,
                              child: Text(
                                item.name.isNotEmpty
                                    ? item.name[0].toUpperCase()
                                    : "?",
                                style: GoogleFonts.manrope(
                                  fontSize: 38.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            );
                          },
                        )
                            : Container(
                          color: const Color(0xFFF3F4F5),
                          alignment: Alignment.center,
                          child: Text(
                            item.name.isNotEmpty
                                ? item.name[0].toUpperCase()
                                : "?",
                            style: GoogleFonts.manrope(
                              fontSize: 38.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ==========================
                    // Attendance Status Dot
                    // ==========================
                    Positioned(
                      top: 5,
                      right: 8,
                      child: Container(
                        width: 18.w,
                        height: 18.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.todayAttendanceStatus
                              .toLowerCase()
                              .trim() ==
                              "present"
                              ? AppColors.darkGreen
                              : const Color(0xFFEF4444),
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  Center(
                    child: Text(
                      _formatRoleLabel(item.role),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF6E5C61),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Center(
                    child: Text(
                      item.todayAttendanceStatus,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),

                  // SizedBox(height: 4.h),

                  Row(
                    children: [
                      Expanded(

                        child: _buildMiniStat(
                          '${item.leadsHandled}',
                          'Leads',
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: _buildMiniStat(
                          '${item.tasksCompleted}',
                          'Tasks',
                        ),
                      ),
                    ],
                  ),

                  // Uncomment if you want to show profiles handled
                  /*
                SizedBox(height: 8.h),
                Text(
                  '${item.profilesHandled} profiles handled',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF6E5C61),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                */
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.lightGray,

            borderRadius: BorderRadius.circular(3.11),
          ),
          width: 70.w,
          // height: 36.h,

          child: Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 5),
            child: Column(
              children: [
                Text(
                  value,
                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  label,
                  style: GoogleFonts.manrope(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFollowUpControl(
    BuildContext context,
    ManagerDashboard? dashboard,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: _ownerCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'FOLLOW-UP CONTROL',
                    style: GoogleFonts.manrope(
                      color: Color(0xFF211A1B),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Remind All',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if ((dashboard?.followUpControl.isEmpty ?? true))
              _buildSectionEmptyState(
                'No follow-up ownership data in the selected period.',
              )
            else
              Column(
                children: [
                  for (
                    var index = 0;
                    index < dashboard!.followUpControl.take(4).length;
                    index++
                  ) ...[
                    if (index > 0) const Divider(),
                    _buildFollowUpRow(dashboard.followUpControl[index]),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpRow(ManagerFollowUpControlItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: AppColors.rmPrimary.withValues(alpha: 0.12),
            child: Text(
              _initialsForName(item.name),
              style: GoogleFonts.manrope(
                color: AppColors.rmPrimary,
                fontSize: 18,
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
                  item.name,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF1A1C1A),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3.h),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${item.pendingFollowUps} Pending',
                        style: GoogleFonts.manrope(
                          color: Colors.red.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${item.completedFollowUps} Done',
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF6E5C61),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildRoundIconButton(
            icon: Icons.chat_bubble_outline,
            background: AppColors.rmPrimary.withValues(alpha: 0.10),
            iconColor: AppColors.rmPrimary,
            onTap: () {
              // TODO: open chat/message action for item
            },
          ),
          SizedBox(width: 10.w),
          _buildRoundIconButton(
            icon: Icons.mic_none_rounded,
            background: AppColors.rmPrimary,
            iconColor: Colors.white,
            onTap: () {
              // TODO: trigger voice reminder for item
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoundIconButton({
    required IconData icon,
    required Color background,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }

  Widget _buildFollowUpMetricChip(
    String label,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
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
              style: GoogleFonts.manrope(
                color: Colors.orange[700],
                fontSize: 13,
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
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    details,
                    style: GoogleFonts.manrope(
                      color: Colors.grey[500],
                      fontSize: 17,
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
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(probability * 100).toInt()}%',
                style: GoogleFonts.manrope(
                  fontSize: 16,
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
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
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
          color: isSelected
              ? AppColors.primary
              : AppColors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          title,
          style: GoogleFonts.manrope(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }
}



