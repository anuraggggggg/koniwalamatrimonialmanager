import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/models/data_entry_stats.dart';
import 'package:koniwalamatrimonial/owner/Screen/registry_screen.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/providers/data_entry_dashboard_provider.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'data_entry_attendance_screen.dart';

class DataEntryOperationsDashboardScreen extends StatefulWidget {
  const DataEntryOperationsDashboardScreen({super.key});

  @override
  State<DataEntryOperationsDashboardScreen> createState() =>
      _DataEntryOperationsDashboardScreenState();
}

class _DataEntryDashboardDrawer extends StatelessWidget {
  const _DataEntryDashboardDrawer({
    required this.selectedIndex,
    required this.userName,
    required this.digitizedToday,
    required this.totalPhotos,
    required this.activeDrafts,
    required this.onItemSelected,
    required this.onLogout,
  });

  final int selectedIndex;
  final String userName;
  final String digitizedToday;
  final String totalPhotos;
  final String activeDrafts;
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
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'D',
                          style: GoogleFonts.manrope(
                            color: AppColors.white,
                            fontSize: 28.sp,
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
                                fontSize: 21.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              'Data Entry',
                              style: GoogleFonts.manrope(
                                color: AppColors.white.withValues(alpha: 0.78),
                                fontSize: 16.sp,
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
                        child: _DataEntryDrawerMetric(
                          value: digitizedToday,
                          label: 'Today',
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _DataEntryDrawerMetric(
                          value: totalPhotos,
                          label: 'Photos',
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _DataEntryDrawerMetric(
                          value: activeDrafts,
                          label: 'Drafts',
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
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  _DataEntryDrawerItem(
                    label: 'Main Dashboard',
                    icon: Icons.home_outlined,
                    selected: selectedIndex == 0,
                    onTap: () => selectTab(0),
                  ),
                  _DataEntryDrawerItem(
                    label: 'Bride / Groom Profile',
                    icon: Icons.groups_outlined,
                    selected: selectedIndex == 2,
                    onTap: () => selectTab(2),
                  ),
                  _DataEntryDrawerItem(
                    label: 'Profile Digitizer',
                    icon: Icons.auto_awesome_motion_outlined,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).maybePop();
                      Navigator.of(context).pushNamed(AppRoutes.profileDigitizer);
                    },
                  ),
                  _DataEntryDrawerItem(
                    label: 'Leave Management',
                    icon: Icons.calendar_today_outlined,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).maybePop();
                      Navigator.of(context).pushNamed(AppRoutes.leaves);
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
                      border: Border.all(color: AppColors.rmPaleRoseBorder),
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
                            Icons.edit_document,
                            color: AppColors.whatsappGreen,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            'Data entry workspace active',
                            style: GoogleFonts.manrope(
                              color: AppColors.rmBodyText,
                              fontSize: 17.sp,
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
                          Icon(Icons.logout_rounded, size: 21.sp),
                          SizedBox(width: 10.w),
                          Text(
                            'Logout',
                            style: GoogleFonts.manrope(
                              fontSize: 17.sp,
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

class _DataEntryDrawerMetric extends StatelessWidget {
  const _DataEntryDrawerMetric({required this.value, required this.label});

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
              fontSize: 17.sp,
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
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DataEntryDrawerItem extends StatelessWidget {
  const _DataEntryDrawerItem({
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
                Icon(icon, color: color, size: 23.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      color: color,
                      fontSize: 17.sp,
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

class _DataEntryOperationsDashboardScreenState
    extends State<DataEntryOperationsDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  String? _requestedAccessToken;
  bool _hasRequestedDashboard = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final accessToken = context.watch<AuthProvider>().userModel?.accessToken?.trim();
    if (_hasRequestedDashboard && accessToken == _requestedAccessToken) {
      return;
    }

    _hasRequestedDashboard = true;
    _requestedAccessToken = accessToken;
    debugPrint(
      'DataEntryOperationsDashboardScreen requesting dashboard. '
      'hasToken=${accessToken != null && accessToken.isNotEmpty}',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<DataEntryDashboardProvider>().fetchDashboard(accessToken);
      context.read<DataEntryDashboardProvider>().fetchDataEntryUsers(accessToken);
    });
  }

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
    final authProvider = context.watch<AuthProvider>();
    final dashboardProvider = context.watch<DataEntryDashboardProvider>();
    final user = authProvider.userModel?.user;
    final stats = dashboardProvider.dashboard;

    return Scaffold(
      key: _scaffoldKey,
      drawerScrimColor: Colors.black.withValues(alpha: 0.1),
      backgroundColor: AppColors.rmSoftPink,
      drawer: _DataEntryDashboardDrawer(
        userName: user?.name ?? 'Data Entry',
        selectedIndex: _selectedIndex,
        digitizedToday: '${stats?.digitizedToday ?? 0}',
        totalPhotos: '${stats?.totalPhotos ?? 0}',
        activeDrafts: '${stats?.activeDrafts ?? 0}',
        onItemSelected: (index) => setState(() => _selectedIndex = index),
        onLogout: _handleLogout,
      ),
      appBar: _selectedIndex == 2
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              titleSpacing: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF4A2334)),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: Text(
                'Data Entry Dashboard',
                style: GoogleFonts.manrope(
                  color: const Color(0xFF4A2334),
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Container(
                    width: 34.r,
                    height: 34.r,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7F9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE7D9DE)),
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.rmPrimary,
                      size: 18.sp,
                    ),
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(1.h),
                child: Divider(
                  height: 1.h,
                  thickness: 1,
                  color: const Color(0xFFF0E8EB),
                ),
              ),
            ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeScreen(stats),
          const DataEntryAttendanceScreen(),
          RegistryScreen(
            showScaffold: false,
            onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey[400],
          selectedFontSize: 14.sp,
          unselectedFontSize: 14.sp,
          selectedLabelStyle: GoogleFonts.manrope(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.manrope(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups_rounded),
              label: 'Matches',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen(DataEntryStats? stats) {
    final recentProfiles = stats?.recentProfiles ?? const <RecentProfile>[];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Entry Operations',
            style: GoogleFonts.manrope(
              fontSize: 30.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E1E22),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Manage and track profile digitization progress.',
            style: GoogleFonts.manrope(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6E6770),
            ),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.profileDigitizer);
              },
              icon: Icon(
                Icons.add_rounded,
                color: AppColors.rmPrimary,
                size: 20.sp,
              ),
              label: Text(
                'New Client',
                style: GoogleFonts.manrope(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rmPrimary,
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                side: BorderSide(color: AppColors.rmPrimary.withValues(alpha: 0.75)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          _buildStatsGrid(stats),
          SizedBox(height: 14.h),
          _buildDraftsCard(),
          SizedBox(height: 14.h),
          _buildRecentlyDigitizedProfiles(recentProfiles),
          SizedBox(height: 14.h),
          _buildProfileCreationQueue(recentProfiles),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(DataEntryStats? stats) {
    final totalProfiles = stats?.totalContribution ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 0.90,
      children: [
        _buildStatCard(
          icon: Icons.description_outlined,
          iconColor: const Color(0xFFE85DB4),
          iconBackground: const Color(0xFFFFEDF7),
          title: 'Digitized Today',
          count: '${stats?.digitizedToday ?? 0}',
          footerText: 'Count for today',
        ),
        _buildStatCard(
          icon: Icons.groups_outlined,
          iconColor: const Color(0xFFFF6792),
          iconBackground: const Color(0xFFFFEEF2),
          title: 'Total Profiles',
          count: '$totalProfiles',
          footerText: 'All verified profiles',
        ),
        _buildStatCard(
          icon: Icons.collections_outlined,
          iconColor: const Color(0xFF27B35F),
          iconBackground: const Color(0xFFEFFFF5),
          title: 'Photos Digitized',
          count: '${stats?.totalPhotos ?? 0}',
          footerText: 'Images uploaded',
        ),
        _buildStatCard(
          icon: Icons.note_alt_outlined,
          iconColor: const Color(0xFFF0A72A),
          iconBackground: const Color(0xFFFFF6E4),
          title: 'Drafts',
          count: '${stats?.activeDrafts ?? 0}',
          footerText: 'Profiles in draft',
        ),
      ],
    );
  }

  Widget _buildDraftsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          Container(
            width: 42.r,
            height: 42.r,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F4F7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.image_not_supported_outlined,
              color: const Color(0xFFD58888),
              size: 20.sp,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'No active drafts found',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1E22),
            ),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.profileDigitizer);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rmPrimary,
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                side: BorderSide(
                    color: AppColors.rmPrimary.withValues(alpha: 0.75)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Continue Last Session',
                    style: GoogleFonts.manrope(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 11.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2DA),
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Text(
                      'PENDING',
                      style: GoogleFonts.manrope(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFD59A18),
                      ),
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

  Widget _buildRecentlyDigitizedProfiles(List<RecentProfile> recentProfiles) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 16.h),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Recently Digitized Profiles',
                  style: GoogleFonts.manrope(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1E22),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F3),
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF4A4A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'LIVE FEED',
                      style: GoogleFonts.manrope(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFF4A4A),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 2.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: const Color(0xFFF0F0F0)),
              ),
            ),
            child: Row(
              children: [
                _buildTableHeader('PROFILE NAME', flex: 2, alignEnd: false),
                _buildTableHeader('CREATION TIME', flex: 2),
              ],
            ),
          ),
          if (recentProfiles.isEmpty) ...[
            SizedBox(height: 24.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 22.h),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    Icons.hourglass_empty_rounded,
                    size: 28.sp,
                    color: const Color(0xFFC3BBC0),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'No profiles digitized yet.',
                    style: GoogleFonts.manrope(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6E6770),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentProfiles.length > 4 ? 4 : recentProfiles.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Color(0xFFF1F1F1), height: 1),
              itemBuilder: (context, index) {
                final profile = recentProfiles[index];
                return Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 12.h,
                    horizontal: 2.w,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E22),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatDate(profile.createdAt),
                          textAlign: TextAlign.right,
                          style: GoogleFonts.manrope(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6E6770),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildProfileCreationQueue(List<RecentProfile> recentProfiles) {
    final queuedProfile = recentProfiles.isEmpty ? null : recentProfiles.first;
    final queueTitle = queuedProfile?.name ?? 'Meena';
    final queueActionLabel = _queueActionLabel(queuedProfile).toUpperCase();
    final queueSide = _queueSideLabel(queuedProfile);
    final queuePhone = _queuePhone(queuedProfile);
    final queueSource = _queueSourceLabel(queuedProfile);
    final queueAssignedRm = _queueAssignedRm(queuedProfile);
    final queueRequirements = _queueRequirements(queuedProfile);
    final queueAge = _queueAddedAgo(queuedProfile?.createdAt);
    final queueInitials = _queueInitials(queueTitle);
    final activeCount = recentProfiles.isEmpty ? 1 : recentProfiles.length;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile creation queue',
            style: GoogleFonts.manrope(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.rmPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Converted clients waiting for profile\ndigitization.',
                  style: GoogleFonts.manrope(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6E6770),
                    height: 1.32,
                  ),
                ),
              ),
              Container(
                width: 34.r,
                height: 34.r,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF1F4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sync_rounded,
                  color: const Color(0xFFC06A8E),
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F5),
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  '$activeCount Active',
                  style: GoogleFonts.manrope(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.rmPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBFC),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFF1E5E9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4F7),
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        queueActionLabel,
                        style: GoogleFonts.manrope(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.rmPrimary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 11.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2DA),
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        'PENDING',
                        style: GoogleFonts.manrope(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFD59A18),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42.r,
                      height: 42.r,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE8EF),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        queueInitials,
                        style: GoogleFonts.manrope(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.rmPrimary,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                size: 15.sp,
                                color: const Color(0xFF786E75),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'Added $queueAge',
                                style: GoogleFonts.manrope(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF786E75),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            queueTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 33.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.rmPrimary,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Divider(height: 1, color: const Color(0xFFF0E5E8)),
                SizedBox(height: 14.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildQueueDetail(
                        label: 'PROFILE TYPE',
                        value: queueSide,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: _buildQueueDetail(
                        label: 'PHONE',
                        value: queuePhone,
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildQueueDetail(
                        label: 'SOURCE',
                        value: queueSource,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: _buildQueueDetail(
                        label: 'ASSIGNED RM',
                        value: queueAssignedRm,
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _buildQueueDetail(label: 'SIDE', value: queueSide),
                SizedBox(height: 14.h),
                Divider(height: 1, color: const Color(0xFFF0E5E8)),
                SizedBox(height: 14.h),
                Text(
                  'REQUIREMENTS',
                  style: GoogleFonts.manrope(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFA39AA0),
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  queueRequirements,
                  style: GoogleFonts.manrope(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF665C63),
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 14.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    _buildQueueChip(
                      label: queuePhone,
                      foreground: const Color(0xFF8D4A63),
                      background: const Color(0xFFFFF3F6),
                      icon: Icons.phone_outlined,
                    ),
                    _buildQueueChip(
                      label: queueSide.toUpperCase(),
                      foreground: AppColors.rmPrimary,
                      background: const Color(0xFFFFEDF3),
                    ),
                    _buildQueueChip(
                      label: queueSource.toUpperCase(),
                      foreground: const Color(0xFF2EAD60),
                      background: const Color(0xFFEAF9EF),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Container(
                      width: 34.r,
                      height: 34.r,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3F4),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: const Color(0xFFF1D9DE)),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: const Color(0xFFE16C75),
                        size: 18.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: SizedBox(
                        height: 42.h,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.profileDigitizer,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.rmPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999.r),
                            ),
                          ),
                          child: Text(
                            'Start Digitizing',
                            style: GoogleFonts.manrope(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
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
    } catch (e) {
      return dateStr;
    }
  }

  String _queueActionLabel(RecentProfile? profile) {
    final side = _queueSideLabel(profile).toLowerCase();
    return side == 'bride' ? 'Create Bride Profile' : 'Create Groom Profile';
  }

  String _queueSideLabel(RecentProfile? profile) {
    final gender = profile?.gender.trim().toLowerCase() ?? '';
    if (gender.contains('female') || gender.contains('bride')) {
      return 'Bride';
    }
    return 'Groom';
  }

  String _queuePhone(RecentProfile? profile) {
    if (profile == null) {
      return '+919564215470';
    }
    final digits = profile.id.replaceAll(RegExp(r'\D'), '');
    final body = (digits.isEmpty ? '9564215470' : digits.padRight(10, '0'))
        .substring(0, 10);
    return '+91$body';
  }

  String _queueSourceLabel(RecentProfile? profile) {
    return 'WHATSAPP';
  }

  String _queueAssignedRm(RecentProfile? profile) {
    final gotra = profile?.gotra.trim() ?? '';
    if (gotra.isEmpty || gotra == '-') {
      return 'Priya Maheshwari';
    }
    return gotra;
  }

  String _queueRequirements(RecentProfile? profile) {
    final community = profile?.community.trim() ?? '';
    if (community.isEmpty || community == '-') {
      return 'No additional requirements provided.';
    }
    return '$community preferences captured for digitization.';
  }

  String _queueAddedAgo(String? createdAt) {
    if (createdAt == null || createdAt.trim().isEmpty) {
      return '8 days ago';
    }
    try {
      final created = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final difference = now.difference(created);
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      }
      if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      }
      final minutes = difference.inMinutes < 1 ? 1 : difference.inMinutes;
      return '$minutes min ago';
    } catch (_) {
      return '8 days ago';
    }
  }

  String _queueInitials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'ME';
    }
    if (parts.length == 1) {
      final word = parts.first.toUpperCase();
      return word.length >= 2 ? word.substring(0, 2) : word;
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildQueueDetail({
    required String label,
    required String value,
    bool alignEnd = false,
  }) {
    final textAlign = alignEnd ? TextAlign.right : TextAlign.left;
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: textAlign,
          style: GoogleFonts.manrope(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFA39AA0),
            letterSpacing: 0.6,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          value,
          textAlign: textAlign,
          style: GoogleFonts.manrope(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF463D42),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildQueueChip({
    required String label,
    required Color foreground,
    required Color background,
    IconData? icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: foreground.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13.sp, color: foreground),
            SizedBox(width: 5.w),
          ],
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String label, {int flex = 1, bool alignEnd = true}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        style: GoogleFonts.manrope(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF6E6770),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    required String count,
    required String footerText,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34.r,
            height: 34.r,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5E545B),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            count,
            style: GoogleFonts.manrope(
              fontSize: 25.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E1E22),
              height: 1,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            footerText,
            style: GoogleFonts.manrope(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6E6770),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      boxShadow: [
        BoxShadow(
          color: const Color(0x140F172A),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

