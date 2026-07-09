import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/owner/Screen/client_registry_screen.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/providers/navigation_provider.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:koniwalamatrimonial/rm/relationship_manager_account_screen.dart';
import 'package:koniwalamatrimonial/rm/providers/rm_dashboard_summary_provider.dart';
import 'package:koniwalamatrimonial/owner/Screen/registry_screen.dart';
import 'package:koniwalamatrimonial/widgets/koniwala_primary_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class _RmMetrics {
  static const double cardPadding = 12;
  static const double innerPadding = 10;
  static const double sectionGap = 12;
  static const double contentGap = 12;
  static const double itemGap = 8;
  static const double smallGap = 4;
  static const double buttonGap = 4;
  static const double dividerHeight = 16;
  static const double actionButtonVerticalPadding = 7;
  static const double actionButtonHorizontalPadding = 6;
  static const double compactAvatarRadius = 22;
  static const double controlHeight = 50;
  static const double taskSmallCardHeight = 92;
  static const double queueInfoBlockHeight = 82;
  static const double conversationPadding = 18;
  static const double conversationGap = 16;
  static const double conversationButtonVerticalPadding = 11;
}

class RelationshipManagerDashboardScreen extends StatefulWidget {
  const RelationshipManagerDashboardScreen({
    super.key,
    this.showScaffold = true,
  });

  final bool showScaffold;

  @override
  State<RelationshipManagerDashboardScreen> createState() =>
      _RelationshipManagerDashboardScreenState();
}

class _RelationshipManagerDashboardScreenState
    extends State<RelationshipManagerDashboardScreen> {
  final Color _maroon = AppColors.rmPrimary;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _requestedSummaryAccessToken;
  bool _hasRequestedSummary = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final accessToken = context
        .watch<AuthProvider>()
        .userModel
        ?.accessToken
        ?.trim();
    if (_hasRequestedSummary && accessToken == _requestedSummaryAccessToken) {
      return;
    }

    _hasRequestedSummary = true;
    _requestedSummaryAccessToken = accessToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<RmDashboardSummaryProvider>().fetchSummary(accessToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rawSelectedTab = context.watch<NavigationProvider>().selectedIndex;
    final selectedTab = rawSelectedTab > 2 ? 2 : rawSelectedTab;
    final user = context.watch<AuthProvider>().userModel?.user;
    final summary = context.watch<RmDashboardSummaryProvider>().summary;

    if (rawSelectedTab != selectedTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<NavigationProvider>().setIndex(selectedTab);
        }
      });
    }

    final isAccountTab = selectedTab == 2;
    final isMatchesTab = selectedTab == 1;
    final content = isAccountTab
        ? const RelationshipManagerAccountScreen(showScaffold: false)
        : isMatchesTab
        ? RegistryScreen(
            showScaffold: false,
            showEmbeddedAppBar: false,
            onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
          )
        : ColoredBox(
            color: AppColors.rmSoftPink,
            child: SafeArea(
              top: false,
              child: selectedTab == 0
                  ? SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 14.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RM Dashboard',
                            style: GoogleFonts.manrope(
                              color: AppColors.rmHeading,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.33,
                              letterSpacing: 0,
                            ),
                          ),
                          SizedBox(height: _RmMetrics.smallGap.h),
                          Text(
                            'Follow up with your leads, reply faster, and clear your work for Saturday, 9 May.',
                            style: GoogleFonts.manrope(
                              fontSize: 14.sp,
                              color: AppColors.rmBodyText,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                          SizedBox(height: _RmMetrics.contentGap.h),
                          _StatCardGrid(
                            cards: [
                              _StatCardData(
                                title: 'Assigned Leads',
                                value: '${summary?.assignedLeads ?? 9}',
                                subtitle: 'In your care',
                                borderColor: AppColors.primary,
                                icon: Icons.groups_2_outlined,
                              ),
                              _StatCardData(
                                title: 'Open Tasks',
                                value: '${summary?.openTasks ?? 2}',
                                subtitle: 'Still active',
                                borderColor: AppColors.accent,
                                icon: Icons.task_alt_outlined,
                              ),
                              _StatCardData(
                                title: 'Needs Reply',
                                value: '${summary?.needsReply ?? 1}',
                                subtitle: 'Waiting',
                                borderColor: AppColors.rmTeal,
                                icon: Icons.mark_chat_unread_outlined,
                              ),
                              _StatCardData(
                                title: 'Follow Up',
                                value: '${summary?.followUpToday ?? 2}',
                                subtitle: 'Due today',
                                borderColor: AppColors.rmIndigo,
                                icon: Icons.event_available_outlined,
                              ),
                              _StatCardData(
                                title: 'Journeys',
                                value: '${summary?.activeJourneys ?? 0}',
                                subtitle: 'Progressing',
                                borderColor: AppColors.rmBrown,
                                icon: Icons.route_outlined,
                              ),
                              _StatCardData(
                                title: 'Waiting',
                                value: '${summary?.waiting ?? 1}',
                                subtitle: 'On the lead',
                                borderColor: AppColors.rmSky,
                                icon: Icons.hourglass_top_outlined,
                              ),
                            ],
                          ),
                          SizedBox(height: _RmMetrics.sectionGap.h),
                          Text(
                            'Overview',
                            style: TextStyle(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.rmPrimary,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          SizedBox(height: _RmMetrics.itemGap.h),
                          _OverviewCard(),
                          SizedBox(height: _RmMetrics.sectionGap.h),
                          _WhatsAppConversations(),
                          SizedBox(height: _RmMetrics.sectionGap.h),
                          _AIInsights(),
                          SizedBox(height: _RmMetrics.sectionGap.h),
                          _AIMatches(),
                          SizedBox(height: _RmMetrics.sectionGap.h),
                          _SmartFilters(),
                          SizedBox(height: _RmMetrics.sectionGap.h),
                          _ActionQueue(),
                          SizedBox(height: _RmMetrics.sectionGap.h),
                          _LeadConversationFocus(),
                        ],
                      ),
                    )
                  : Center(
                      child: Text(
                        'Selected Tab: $selectedTab',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          color: _maroon,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
            ),
          );

    if (!widget.showScaffold) {
      return ColoredBox(color: AppColors.rmSoftPink, child: content);
    }

    return Scaffold(
      key: _scaffoldKey,
      drawerScrimColor: Colors.black.withValues(alpha: 0.1),
      // drawerElevation: 0,
      backgroundColor: AppColors.rmSoftPink,
      appBar: isAccountTab
          ? null
          : KoniwalaPrimaryAppBar(
              showMenuButton: true,
              onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
      drawer: _RmDashboardDrawer(
        selectedIndex: selectedTab,
        userName: user?.name ?? 'Relationship Manager',
        assignedLeads: '${summary?.assignedLeads ?? 9}',
        openTasks: '${summary?.openTasks ?? 2}',
        needsReply: '${summary?.needsReply ?? 1}',
        onChanged: (index) =>
            context.read<NavigationProvider>().setIndex(index),
      ),
      bottomNavigationBar: _DashboardBottomNav(
        maroon: _maroon,
        selectedIndex: selectedTab,
        onChanged: (index) =>
            context.read<NavigationProvider>().setIndex(index),
      ),
      body: content,
    );
  }
}

class _RmDashboardDrawer extends StatelessWidget {
  const _RmDashboardDrawer({
    required this.selectedIndex,
    required this.userName,
    required this.assignedLeads,
    required this.openTasks,
    required this.needsReply,
    required this.onChanged,
  });

  final int selectedIndex;
  final String userName;
  final String assignedLeads;
  final String openTasks;
  final String needsReply;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    void selectTab(int index) {
      Navigator.of(context).pop();
      onChanged(index);
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
                        onPressed: () => Navigator.of(context).pop(),
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
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'R',
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
                              'Relationship Manager',
                              style: GoogleFonts.manrope(
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
                    children: [
                      Expanded(
                        child: _RmDrawerMetric(
                          value: assignedLeads,
                          label: 'Leads',
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _RmDrawerMetric(
                          value: openTasks,
                          label: 'Tasks',
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _RmDrawerMetric(
                          value: needsReply,
                          label: 'Reply',
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
                  _RmDrawerItem(
                    label: 'Dashboard',
                    icon: Icons.space_dashboard_outlined,
                    selected: selectedIndex == 0,
                    onTap: () => selectTab(0),
                  ),
                  _RmDrawerItem(
                    label: 'All Matches',
                    icon: Icons.filter_alt_outlined,
                    selected: selectedIndex == 1,
                    onTap: () => selectTab(1),
                  ),
                  _RmDrawerItem(
                    label: 'Leads',
                    icon: Icons.person_search_outlined,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.relationshipManagerLeads);
                    },
                  ),
                  _RmDrawerItem(
                    label: 'Lead Follow-ups',
                    icon: Icons.event_available_outlined,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed(AppRoutes.leadFollowUps);
                    },
                  ),
                  _RmDrawerItem(
                    label: 'Client',
                    icon: Icons.assignment_ind_outlined,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ClientRegistryScreen(),
                        ),
                      );
                    },
                  ),
                  _RmDrawerItem(
                    label: 'Leave Management',
                    icon: Icons.calendar_today_outlined,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed(AppRoutes.leaves);
                    },
                  ),
                  _RmDrawerItem(
                    label: 'Account',
                    icon: Icons.person_outline,
                    selected: selectedIndex == 2,
                    onTap: () => selectTab(2),
                  ),
                  Divider(height: 28.h, color: AppColors.rmPaleRoseBorder),
                  _RmDrawerItem(
                    label: 'AI Matchmaking',
                    icon: Icons.auto_awesome_outlined,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed(AppRoutes.aiMatching);
                    },
                  ),
                  _RmDrawerItem(
                    label: 'Notifications',
                    icon: Icons.notifications_none_outlined,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed(AppRoutes.notifications);
                    },
                  ),
                  _RmDrawerItem(
                    label: 'Support',
                    icon: Icons.support_agent_outlined,
                    selected: false,
                    onTap: () => Navigator.of(context).pop(),
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
                            Icons.check_circle_outline,
                            color: AppColors.whatsappGreen,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            'Online and ready for follow-ups',
                            style: GoogleFonts.manrope(
                              color: AppColors.rmBodyText,
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
                        context.read<AuthProvider>().logout();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.login,
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.rmPrimary,
                        foregroundColor: Colors.white,
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

class _RmDrawerMetric extends StatelessWidget {
  const _RmDrawerMetric({required this.value, required this.label});

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
              fontSize: 19.sp,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.manrope(
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

class _RmDrawerItem extends StatelessWidget {
  const _RmDrawerItem({
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
            : Colors.white,
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

class _DashboardBottomNav extends StatelessWidget {
  const _DashboardBottomNav({
    required this.maroon,
    required this.selectedIndex,
    required this.onChanged,
  });

  final Color maroon;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        color: AppColors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _BottomNavItem(
              label: 'Dashboard',
              icon: Icons.space_dashboard_outlined,
              iconAsset: 'assets/icon/dashbaord_icon.png',
              selected: selectedIndex == 0,
              maroon: maroon,
              onTap: () => onChanged(0),
            ),
            _BottomNavItem(
              label: 'Matches',
              icon: Icons.filter_alt_outlined,
              selected: selectedIndex == 1,
              maroon: maroon,
              onTap: () => onChanged(1),
            ),
            _BottomNavItem(
              label: 'Account',
              icon: Icons.person_outline,
              selected: selectedIndex == 2,
              maroon: maroon,
              onTap: () => onChanged(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.maroon,
    required this.onTap,
    this.iconAsset,
  });

  final String label;
  final IconData icon;
  final String? iconAsset;
  final bool selected;
  final Color maroon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color inactive = AppColors.inactiveNavItemColor;
    final Color selectedBackground = AppColors.selectedNavItemBackgroundColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? selectedBackground : AppColors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconAsset != null)
              Image.asset(
                iconAsset!,
                width: 26,
                height: 26,
                color: selected ? maroon : inactive,
              )
            else
              Icon(icon, size: 26, color: selected ? maroon : inactive),
            SizedBox(height: _RmMetrics.smallGap.h),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: selected ? maroon : inactive,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCardData {
  final String title;
  final String value;
  final String subtitle;
  final Color borderColor;
  final IconData icon;

  const _StatCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.borderColor,
    required this.icon,
  });
}

class _StatCardGrid extends StatelessWidget {
  final List<_StatCardData> cards;

  const _StatCardGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columnCount = 3;
        final spacing = 8.w;
        final cardWidth =
            (constraints.maxWidth - (spacing * (columnCount - 1))) /
            columnCount;

        return Wrap(
          spacing: spacing,
          runSpacing: 12.h,
          children: cards.map((card) {
            return SizedBox(
              width: cardWidth,
              height: 135.h,
              child: _StatCard(
                title: card.title,
                value: card.value,
                subtitle: card.subtitle,
                borderColor: card.borderColor,
                icon: card.icon,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color borderColor;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.borderColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
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
            children: [
              Container(
                width: 30.r,
                height: 30.r,
                decoration: BoxDecoration(
                  color: borderColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: borderColor, size: 18.sp),
              ),
              SizedBox(width: 7.w),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: AppColors.rmHeading,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: borderColor,
                    fontSize: 31.sp,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: AppColors.rmStatCaption,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const stats = [
      _PipelineMatrixData('All Registry', '9', AppColors.rmPipelinePurple),
      _PipelineMatrixData('Interested', '6', AppColors.rmPipelineGreen),
      _PipelineMatrixData('New', '1', AppColors.rmPipelineBlue),
      _PipelineMatrixData('Converted', '0', AppColors.rmPipelineLime),
      _PipelineMatrixData('Contacted', '2', AppColors.rmPipelineCyan),
      _PipelineMatrixData('Closed', '0', AppColors.rmPipelineYellow),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder, width: 1),
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
          Text(
            'Lead Pipeline',
            style: GoogleFonts.manrope(
              color: AppColors.rmDarkMaroon,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Relationship Conversion Overview',
            style: GoogleFonts.manrope(
              fontSize: 12.sp,
              color: AppColors.rmMutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 14.h),
            decoration: BoxDecoration(
              color: AppColors.rmSoftPink,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 128.h,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      _PipelineBar(
                        heightFactor: 0.92,
                        color: AppColors.rmPipelinePurple,
                      ),
                      _PipelineBar(
                        heightFactor: 0.68,
                        color: AppColors.rmPipelineBlue,
                      ),
                      _PipelineBar(
                        heightFactor: 0.46,
                        color: AppColors.rmPipelineCyan,
                      ),
                      _PipelineBar(
                        heightFactor: 0.38,
                        color: AppColors.rmPipelineGreen,
                      ),
                      _PipelineBar(
                        heightFactor: 0.34,
                        color: AppColors.rmPipelineLime,
                      ),
                      _PipelineBar(
                        heightFactor: 0.26,
                        color: AppColors.rmPipelineYellow,
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppColors.rmPaleRoseBorder),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _PipelineLegendPill(
                      color: AppColors.rmPipelinePurple,
                      label: 'Highest stage',
                    ),
                    SizedBox(width: 12),
                    _PipelineLegendPill(
                      color: AppColors.rmPipelineYellow,
                      label: 'Needs closure',
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Pipeline Matrix',
            style: GoogleFonts.manrope(
              color: AppColors.rmDarkMaroon,
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 10.w) / 2;
              return Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: stats
                    .map(
                      (stat) => SizedBox(
                        width: width,
                        child: _PipelineMatrixCard(data: stat),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          SizedBox(height: 14.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.successContainer,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              '+18% higher conversion this month',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: AppColors.success,
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineBar extends StatelessWidget {
  final Color color;
  final double heightFactor;

  const _PipelineBar({required this.color, required this.heightFactor});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: heightFactor,
      child: Container(
        width: 28.w,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(7.r),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _PipelineLegendPill extends StatelessWidget {
  const _PipelineLegendPill({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7.r,
            height: 7.r,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: GoogleFonts.manrope(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineMatrixData {
  const _PipelineMatrixData(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;
}

class _PipelineMatrixCard extends StatelessWidget {
  const _PipelineMatrixCard({required this.data});

  final _PipelineMatrixData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 7.r,
                height: 7.r,
                decoration: BoxDecoration(
                  color: data.color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: AppColors.rmMutedText,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            data.value,
            style: GoogleFonts.manrope(
              color: AppColors.rmHeading,
              fontSize: 27.sp,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppConversations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () => _openWhatsAppChat(
          context,
          name: 'Harpreet Kaur',
          phone: '+91 9000 0003',
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(_RmMetrics.cardPadding.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.rmPaleRoseBorder, width: 1),
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
                children: [
                  Container(
                    width: 44.r,
                    height: 44.r,
                    padding: EdgeInsets.all(7.r),
                    decoration: BoxDecoration(
                      color: AppColors.whatsappGreen.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset('assets/green_whatsapp_icon.png'),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WhatsApp Conversations',
                          style: GoogleFonts.manrope(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.whatsappGreen,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Recent family interactions',
                          style: GoogleFonts.manrope(
                            fontSize: 14.sp,
                            color: AppColors.rmMutedText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.whatsappGreen.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'LIVE',
                      style: GoogleFonts.manrope(
                        color: AppColors.whatsappGreen,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: _RmMetrics.contentGap.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFF4),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.whatsappGreen.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: AppColors.whatsappGreen,
                      size: 15.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Messages sync from active WhatsApp follow-ups.',
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF1F7A3B),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: _RmMetrics.contentGap.h),
              _ConversationItem(
                name: 'Harpreet Kaur',
                lastMessage: 'Interested In Biodata',
                time: '10:30 AM',
                badgeText: 'New',
                badgeColor: AppColors.successContainer,
                badgeTextColor: AppColors.success,
                avatarColor: AppColors.rmAvatarGrey,
              ),
              Divider(
                height: _RmMetrics.dividerHeight.h,
                color: AppColors.rmDivider,
              ),
              _ConversationItem(
                name: 'Simran Family',
                lastMessage: 'Meeting Discussion',
                time: '10:30 AM',
                avatarColor: AppColors.rmAvatarTan,
              ),
              Divider(
                height: _RmMetrics.dividerHeight.h,
                color: AppColors.rmDivider,
              ),
              _ConversationItem(
                name: 'Arjun Sharma',
                lastMessage: 'Horoscope Shared',
                time: '10:25 AM',
                badgeText: 'AI Suggested',
                badgeColor: AppColors.purpleContainer,
                badgeTextColor: AppColors.purpleText,
                avatarColor: AppColors.rmAvatarNavy,
              ),
              Divider(
                height: _RmMetrics.dividerHeight.h,
                color: AppColors.rmDivider,
              ),
              _ConversationItem(
                name: 'Kaur Residence',
                lastMessage: 'Need Parent Approval',
                time: '10:20 AM',
                avatarColor: AppColors.rmAvatarSlate,
              ),
              SizedBox(height: _RmMetrics.contentGap.h),
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => _openRelationshipManagerLeadHub(context),
                  borderRadius: BorderRadius.circular(8.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 4.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All Activity',
                          style: TextStyle(
                            color: AppColors.whatsappGreen,
                            fontSize: 18,
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: _RmMetrics.smallGap.w),
                        Icon(
                          Icons.arrow_forward,
                          size: 20.sp,
                          color: AppColors.whatsappGreen,
                        ),
                      ],
                    ),
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

class _ConversationItem extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final Color avatarColor;

  const _ConversationItem({
    required this.name,
    required this.lastMessage,
    required this.time,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    required this.avatarColor,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: _RmMetrics.compactAvatarRadius.r,
                backgroundColor: avatarColor,
                child: Text(
                  initials,
                  style: GoogleFonts.manrope(
                    color: AppColors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 14.r,
                  height: 14.r,
                  decoration: BoxDecoration(
                    color: AppColors.whatsappGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.rmHeading,
                  ),
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Icon(
                      Icons.done_all,
                      size: 15.sp,
                      color: AppColors.whatsappGreen,
                    ),
                    SizedBox(width: 5.w),
                    Expanded(
                      child: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 15.sp,
                          color: AppColors.rmMutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: GoogleFonts.manrope(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: badgeText != null
                      ? AppColors.whatsappGreen
                      : AppColors.rmMutedText,
                ),
              ),
              if (badgeText != null) ...[
                SizedBox(height: _RmMetrics.smallGap.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: badgeColor ?? AppColors.whatsappGreen,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeText!,
                    style: GoogleFonts.manrope(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: badgeTextColor ?? AppColors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AIInsights extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_RmMetrics.cardPadding.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder, width: 1),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Insights',
                    style: GoogleFonts.manrope(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.rmPrimary,
                    ),
                  ),
                  SizedBox(height: _RmMetrics.smallGap.h),
                  Text(
                    'Predictive Matchmaking Intelligence',
                    style: GoogleFonts.manrope(
                      fontSize: 14.sp,
                      color: AppColors.rmMutedText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.rmMutedText,
                size: 34.sp,
              ),
            ],
          ),
          SizedBox(height: _RmMetrics.contentGap.h),
          _InsightItem(
            label: 'Top RM',
            subtitle: 'Simran Kaur',
            value: '92%',
            valueLabel: 'Success Rate',
            valueColor: AppColors.success,
            avatarColor: AppColors.purpleContainer,
          ),
          Divider(
            height: _RmMetrics.dividerHeight.h,
            color: AppColors.rmDivider,
          ),
          _InsightItem(
            label: 'Avg Response',
            subtitle: 'System-wide',
            value: '8 Mins',
            valueLabel: '+24% Faster',
            valueColor: AppColors.success,
            avatarColor: AppColors.infoContainer,
          ),
          Divider(
            height: _RmMetrics.dividerHeight.h,
            color: AppColors.rmDivider,
          ),
          _InsightItem(
            label: 'Risk Alerts',
            subtitle: 'Likely To Ghost',
            value: '3 Profiles',
            valueLabel: 'Action Need',
            valueColor: AppColors.danger,
            avatarColor: AppColors.dangerContainer,
          ),
        ],
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final String label;
  final String subtitle;
  final String value;
  final String valueLabel;
  final Color valueColor;
  final Color avatarColor;

  const _InsightItem({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.valueLabel,
    required this.valueColor,
    required this.avatarColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: _RmMetrics.compactAvatarRadius.r,
          backgroundColor: avatarColor,
        ),
        SizedBox(width: _RmMetrics.itemGap.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.rmHeading,
                ),
              ),
              SizedBox(height: _RmMetrics.smallGap.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14.sp,
                  color: AppColors.rmMutedText,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.rmPrimary,
              ),
            ),
            SizedBox(height: _RmMetrics.smallGap.h),
            Text(
              valueLabel,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AIMatches extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_RmMetrics.cardPadding.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder, width: 1),
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
          Text(
            'AI Matches',
            style: GoogleFonts.manrope(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.rmPrimary,
            ),
          ),
          SizedBox(height: _RmMetrics.smallGap.h),
          Text(
            'High Compatibility Profiles',
            style: GoogleFonts.manrope(
              fontSize: 14.sp,
              color: AppColors.rmMutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: _RmMetrics.contentGap.h),
          _MatchCard(
            initials: 'JK',
            name: 'Jasmeet Kaur',
            details: '28 Yrs • Delhi',
            status: 'Verified Premium',
            matchPercentage: '94% Match',
            accentColor: AppColors.rmMatchAccent,
          ),
          SizedBox(height: _RmMetrics.itemGap.h),
          _MatchCard(
            initials: 'AS',
            name: 'Amanpreet Singh',
            details: '29 Yrs • Chandigarh',
            status: 'Horoscope Match',
            matchPercentage: '94% Match',
            accentColor: AppColors.rmMatchAccent,
          ),
          SizedBox(height: _RmMetrics.itemGap.h),
          _MatchCard(
            initials: 'NK',
            name: 'Navjot Kaur',
            details: '27 Yrs • Mumbai',
            status: 'Parent Approved',
            matchPercentage: '94% Match',
            accentColor: AppColors.rmMatchAccent,
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final String initials;
  final String name;
  final String details;
  final String status;
  final String matchPercentage;
  final Color accentColor;

  const _MatchCard({
    required this.initials,
    required this.name,
    required this.details,
    required this.status,
    required this.matchPercentage,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: const Color(0xFFFFF9FB),
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            width: 1,
            strokeAlign: BorderSide.strokeAlignCenter,
            color: AppColors.rmPaleRoseBorder,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        shadows: const [
          BoxShadow(
            color: AppColors.rmCardShadow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: _RmMetrics.compactAvatarRadius.r,
            backgroundColor: accentColor,
            child: Text(
              initials,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
          SizedBox(width: _RmMetrics.itemGap.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.rmHeading,
                  ),
                ),
                SizedBox(height: _RmMetrics.smallGap.h),
                Text(
                  details,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13.sp,
                    color: AppColors.rmMutedText,
                  ),
                ),
                SizedBox(height: _RmMetrics.smallGap.h),
                Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                matchPercentage,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppColors.rmPurple,
                  fontSize: 11,
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: _RmMetrics.smallGap.h),
              Container(
                width: 70.w,
                height: 6.h,
                decoration: BoxDecoration(
                  color: AppColors.rmPurple,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmartFilters extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Filters',
          style: GoogleFonts.manrope(
            fontSize: 22.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.rmHeading,
          ),
        ),
        SizedBox(height: _RmMetrics.smallGap.h),
        Text(
          'Search Your Leads, Narrow The Stage, And Stay On Top Of Scheduled Follow-Ups From One Place.',
          style: GoogleFonts.manrope(
            fontSize: 16.sp, // Increased from 14.sp
            color: AppColors.rmMutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: _RmMetrics.contentGap.h),
        Row(
          children: [
            Expanded(
              child: Container(
                height: _RmMetrics.controlHeight.h,
                padding: EdgeInsets.symmetric(
                  horizontal: _RmMetrics.cardPadding.w,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(25.r),
                  border: Border.all(color: AppColors.rmBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: AppColors.rmMutedText,
                      size: 26.sp,
                    ),
                    SizedBox(width: _RmMetrics.itemGap.w),
                    Expanded(
                      child: Text(
                        'Search By Name, Phone...',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16.sp,
                          color: AppColors.rmHintText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: _RmMetrics.itemGap.w),
            Container(
              height: _RmMetrics.controlHeight.h,
              width: _RmMetrics.controlHeight.h,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(25.r),
                border: Border.all(color: AppColors.rmBorder),
              ),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.rmMutedText,
                size: 28.sp,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionQueue extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Action Queue',
          style: GoogleFonts.manrope(
            fontSize: 24.sp, // Increased from 22.sp
            fontWeight: FontWeight.w600,
            color: AppColors.rmHeading,
          ),
        ),
        SizedBox(height: _RmMetrics.smallGap.h),
        Text(
          'Today - Work That Needs Action Today',
          style: GoogleFonts.manrope(
            fontSize: 14.sp,
            color: AppColors.rmMutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: _RmMetrics.contentGap.h),
        Row(
          children: [
            _FilterChip(label: 'Today', isSelected: true),
            SizedBox(width: _RmMetrics.itemGap.w),
            _FilterChip(label: 'Needs Reply', isSelected: false),
            SizedBox(width: _RmMetrics.itemGap.w),
            _FilterChip(label: 'Overdue', isSelected: false, isUrgent: true),
          ],
        ),
        SizedBox(height: _RmMetrics.contentGap.h),
        _QueueItem(
          title: 'Kayra Reply Demo',
          phone: '+91 9000 0003 • Udaipur',
          time: '09 May, 10:37 AM',
          status: 'Contacted',
          message:
              '"I saw the profile you sent, but I\'m looking for someone closer to my age..."',
          focus: 'Reply Now',
          source: 'Website',

          actions: ['Open Chat', 'Mark Done', 'Call Now'],
        ),
        SizedBox(height: _RmMetrics.contentGap.h),
        _QueueItem(
          title: 'Arjun No Response Demo',
          phone: '+91 9000 0002 • Indore',
          status: 'Contacted',
          isOverdue: true,
          message:
              'Automated follow-up triggered 2 days ago. No response received.',
          focus: 'Call Now',
          source: 'Ad Campaign',
          actions: ['Open Chat', 'Mark Done', 'Call Now'],
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isUrgent;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _RmMetrics.cardPadding.w,
        vertical: _RmMetrics.itemGap.h,
      ),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.rmPrimary : AppColors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isSelected ? AppColors.rmPrimary : AppColors.rmBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUrgent) ...[
            Container(
              width: 8.w,
              height: 8.w,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: _RmMetrics.smallGap.w),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14.sp, // Increased from 14.sp
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? AppColors.white
                  : (isUrgent ? AppColors.danger : AppColors.rmHeading),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueItem extends StatelessWidget {
  final String title;
  final String phone;
  final String? time;
  final String status;
  final String message;
  final String focus;
  final String source;
  final List<String> actions;
  final bool isOverdue;

  const _QueueItem({
    required this.title,
    required this.phone,
    this.time,
    required this.status,
    required this.message,
    required this.focus,
    required this.source,
    required this.actions,
    this.isOverdue = false,
  });

  @override
  Widget build(BuildContext context) {
    void handleActionTap(String action) {
      switch (action) {
        case 'Open Chat':
          _openWhatsAppChat(context, name: title, phone: phone);
          return;
        case 'Mark Done':
          _showDashboardActionMessage(
            context,
            'Open the manager lead hub to update this lead workflow.',
          );
          return;
        case 'Call Now':
          _showDashboardActionMessage(
            context,
            'Open the manager lead hub to continue the client conversation.',
          );
          return;
      }
    }

    return Container(
      padding: EdgeInsets.all(_RmMetrics.cardPadding.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder, width: 1),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.rmHeading,
                      ),
                    ),
                    SizedBox(height: _RmMetrics.smallGap.h),
                    Text(
                      phone,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14.sp,
                        color: AppColors.rmMutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (time != null)
                    Text(
                      time!,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.rmPrimary,
                      ),
                    ),
                  if (isOverdue)
                    Text(
                      'Overdue',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                      ),
                    ),
                  SizedBox(height: _RmMetrics.smallGap.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _RmMetrics.cardPadding.w,
                      vertical: _RmMetrics.smallGap.h,
                    ),
                    decoration: ShapeDecoration(
                      color: AppColors.rmStatusBg,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: AppColors.rmStatusBorder,
                        ),
                        borderRadius: BorderRadius.circular(38),
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.rmStatusText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: _RmMetrics.contentGap.h),
          Container(
            height: _RmMetrics.queueInfoBlockHeight.h,
            width: double.infinity,
            padding: EdgeInsets.all(_RmMetrics.innerPadding.w),
            decoration: BoxDecoration(
              color: AppColors.rmBackground,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16.sp,
                  color: AppColors.rmBodyText,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          SizedBox(height: _RmMetrics.contentGap.h),
          Container(
            height: _RmMetrics.queueInfoBlockHeight.h,
            width: double.infinity,
            padding: EdgeInsets.all(_RmMetrics.innerPadding.w),
            decoration: ShapeDecoration(
              color: AppColors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: AppColors.black.withValues(alpha: 0.20),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Focus',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.rmHintText,
                          ),
                        ),
                        Text(
                          focus,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Source',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.rmHintText,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.language,
                              size: 18.sp,
                              color: AppColors.rmMutedText,
                            ),
                            SizedBox(width: _RmMetrics.smallGap.w),
                            Text(
                              source,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.rmHeading,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: _RmMetrics.contentGap.h),
          Row(
            children: actions.asMap().entries.map((entry) {
              final actionIndex = entry.key;
              final action = entry.value;
              final isPrimary = actionIndex == 0;
              final isOpenChat = action == 'Open Chat';
              final isMarkDone = action == 'Mark Done';
              final isCallNow = action == 'Call Now';
              final actionIconAsset = isOpenChat
                  ? 'assets/open_chat_icon.png'
                  : isMarkDone
                  ? 'assets/mark_done_icon.png'
                  : isCallNow
                  ? 'assets/call_now_icon.png'
                  : null;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: actionIndex == actions.length - 1
                        ? 0
                        : _RmMetrics.buttonGap.w,
                  ),
                  child: Material(
                    color: AppColors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10.r),
                      onTap: () => handleActionTap(action),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              _RmMetrics.actionButtonHorizontalPadding.w,
                          vertical: _RmMetrics.actionButtonVerticalPadding.h,
                        ),
                        decoration: BoxDecoration(
                          color: isPrimary
                              ? AppColors.rmPrimary
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: isPrimary
                                ? AppColors.rmPrimary
                                : AppColors.rmBorder,
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (actionIconAsset != null) ...[
                                Image.asset(
                                  actionIconAsset,
                                  width: 15.w,
                                  height: 15.h,
                                  color: isPrimary ? AppColors.white : null,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(width: _RmMetrics.smallGap.w),
                              ],
                              Flexible(
                                child: Text(
                                  action,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800,
                                    color: isPrimary
                                        ? AppColors.white
                                        : AppColors.rmHeading,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: _RmMetrics.smallGap.h),
        ],
      ),
    );
  }
}

class _LeadConversationFocus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_RmMetrics.conversationPadding.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder, width: 1),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Conversation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.rmPrimary,
                  ),
                ),
              ),
              SizedBox(width: _RmMetrics.itemGap.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _RmMetrics.cardPadding.w,
                  vertical: _RmMetrics.smallGap.h + 2.h,
                ),
                decoration: ShapeDecoration(
                  color: AppColors.rmStatusBg,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: AppColors.rmStatusBorder),
                    borderRadius: BorderRadius.circular(38),
                  ),
                ),
                child: Text(
                  'Contacted',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.rmStatusText,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _RmMetrics.conversationGap.h),
          Text(
            'Kayra Reply Demo',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 23.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.rmPrimary,
            ),
          ),
          SizedBox(height: _RmMetrics.itemGap.h),
          Row(
            children: [
              Image.asset(
                'assets/green_whatsapp_icon.png',
                width: 26.sp,
                height: 26.sp,
              ),
              SizedBox(width: _RmMetrics.itemGap.w),
              Expanded(
                child: Text(
                  '+91 9000 0003',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.rmHeading,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _RmMetrics.conversationGap.h),
          Row(
            children: [
              _TaskSmallCard(
                label: 'Next Step',
                value: 'Reply Now',
                icon: Icons.add,
              ),
              SizedBox(width: _RmMetrics.itemGap.w),
              _TaskSmallCard(
                label: 'Open Task',
                value: 'No Open Task Linked',
                icon: Icons.close,
              ),
            ],
          ),
          SizedBox(height: _RmMetrics.conversationGap.h),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: AppColors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showDashboardActionMessage(
                      context,
                      'Open the manager lead hub to continue the client conversation.',
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: _RmMetrics.cardPadding.w,
                        vertical:
                            _RmMetrics.conversationButtonVerticalPadding.h,
                      ),
                      decoration: ShapeDecoration(
                        color: AppColors.rmPrimary,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            color: AppColors.black.withValues(alpha: 0.20),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.call, color: AppColors.white, size: 20.sp),
                          SizedBox(width: _RmMetrics.smallGap.w),
                          Flexible(
                            child: Text(
                              'Call Now',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: _RmMetrics.itemGap.w),
              Expanded(
                child: Material(
                  color: AppColors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _openRelationshipManagerLeadHub(context),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: _RmMetrics.cardPadding.w,
                        vertical:
                            _RmMetrics.conversationButtonVerticalPadding.h,
                      ),
                      decoration: ShapeDecoration(
                        color: AppColors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            color: AppColors.black.withValues(alpha: 0.20),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person,
                            color: AppColors.rmHeading,
                            size: 20.sp,
                          ),
                          SizedBox(width: _RmMetrics.smallGap.w),
                          Flexible(
                            child: Text(
                              'Open Lead',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.rmHeading,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _RmMetrics.conversationGap.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showDashboardActionMessage(
                  context,
                  'Scheduling follow-up will be connected in the manager lead hub next.',
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _RmMetrics.cardPadding.w,
                    vertical: _RmMetrics.conversationButtonVerticalPadding.h,
                  ),
                  decoration: ShapeDecoration(
                    color: AppColors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color: AppColors.black.withValues(alpha: 0.20),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: Image.asset('assets/circle_right_icon.png'),
                      ),
                      SizedBox(width: _RmMetrics.itemGap.w),
                      Flexible(
                        child: Text(
                          'Schedule Next Follow Up',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.rmHeading,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: _RmMetrics.conversationGap.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(_RmMetrics.conversationPadding.w),
            decoration: BoxDecoration(
              color: AppColors.rmBackground,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.rmPinkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Open The Full WhatsApp Chat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.rmPrimary,
                  ),
                ),
                SizedBox(height: _RmMetrics.itemGap.h),
                Text(
                  'Use The Lead Chatbox For Full Conversation History, Message Typing, And WhatsApp History, Message Typing, And WhatsApp Follow-Up.',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14.sp,
                    color: AppColors.rmBodyText,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: _RmMetrics.conversationGap.h),
                Material(
                  color: AppColors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14.r),
                    onTap: () => _openWhatsAppChat(
                      context,
                      name: 'Kayra Reply Demo',
                      phone: '+91 9000 0003',
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical:
                            _RmMetrics.conversationButtonVerticalPadding.h,
                        horizontal: _RmMetrics.cardPadding.w,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.whatsappGreen,
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 24.h,
                            width: 24.w,
                            child: Image.asset("assets/whatsapp.png"),
                          ),
                          SizedBox(width: _RmMetrics.smallGap.w),
                          Flexible(
                            child: Text(
                              'Open WhatsApp Chat',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w900,
                                color: AppColors.white,
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
          ),
        ],
      ),
    );
  }
}

class _TaskSmallCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TaskSmallCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity,
        height: _RmMetrics.taskSmallCardHeight.h,
        padding: EdgeInsets.all(_RmMetrics.innerPadding.w),
        decoration: ShapeDecoration(
          color: AppColors.rmOffWhite,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              strokeAlign: BorderSide.strokeAlignCenter,
              color: AppColors.rmPaleRoseBorder,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // padding: EdgeInsets.all(_RmMetrics.innerPadding.w),
        // decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14.r), border: Border.all(color: AppColors.rmBorder)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16.sp, color: AppColors.rmPrimary),
                SizedBox(width: _RmMetrics.smallGap.w),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.rmHintText,
                  ),
                ),
              ],
            ),
            SizedBox(height: _RmMetrics.smallGap.h),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.rmHeading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openRelationshipManagerLeadHub(BuildContext context) {
  Navigator.of(context).pushNamed(AppRoutes.relationshipManagerLeads);
}

Future<void> _openWhatsAppChat(
  BuildContext context, {
  required String name,
  required String phone,
}) async {
  var cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
  if (cleanPhone.length == 10) {
    cleanPhone = '91$cleanPhone';
  }

  if (cleanPhone.isEmpty) {
    _showDashboardActionMessage(
      context,
      'WhatsApp number not available for this contact.',
    );
    return;
  }

  final message = 'Hello $name, I am following up from Koniwala Matrimonial.';
  final uri = Uri.https('wa.me', '/$cleanPhone', {'text': message});

  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!context.mounted) {
      return;
    }
    _showDashboardActionMessage(
      context,
      'WhatsApp is not available on this device.',
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    _showDashboardActionMessage(context, 'Unable to open WhatsApp chat.');
  }
}

void _showDashboardActionMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
