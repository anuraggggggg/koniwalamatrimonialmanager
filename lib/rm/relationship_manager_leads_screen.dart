import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/owner/Screen/client_registry_screen.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/providers/navigation_provider.dart';
import 'package:koniwalamatrimonial/rm/models/rm_lead_item.dart';
import 'package:koniwalamatrimonial/rm/providers/rm_leads_provider.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class RelationshipManagerLeadsScreen extends StatefulWidget {
  const RelationshipManagerLeadsScreen({super.key});

  @override
  State<RelationshipManagerLeadsScreen> createState() =>
      _RelationshipManagerLeadsScreenState();
}

class _RelationshipManagerLeadsScreenState
    extends State<RelationshipManagerLeadsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasRequestedLeads = false;
  String? _requestedAccessToken;

  int _selectedBottomNavIndex(int rawIndex) {
    return rawIndex > 2 ? 0 : rawIndex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authProvider = Provider.of<AuthProvider>(context);
    final accessToken = authProvider.userModel?.accessToken;

    if (!authProvider.isInitialized ||
        (_hasRequestedLeads && accessToken == _requestedAccessToken)) {
      return;
    }

    _hasRequestedLeads = true;
    _requestedAccessToken = accessToken;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<RmLeadsProvider>().fetchLeads(accessToken);
    });
  }

  Future<void> _refresh() {
    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    return context.read<RmLeadsProvider>().fetchLeads(
      accessToken,
      forceRefresh: true,
    );
  }

  List<RmLeadItem> _assignedLeads(List<RmLeadItem> leads, String? userId) {
    if (userId == null || userId.isEmpty) {
      return leads;
    }

    final assigned = leads
        .where((lead) => lead.assignedToId == userId)
        .toList();
    return assigned.isEmpty ? leads : assigned;
  }

  void _openTasksBottomSheet(RmLeadItem lead) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
      ),
      builder: (context) => _LeadTasksSheet(lead: lead),
    );
  }

  Future<void> _openChat(RmLeadItem lead) async {
    var cleanPhone = lead.phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }

    if (cleanPhone.isEmpty) {
      _showActionMessage('WhatsApp number not available for this contact.');
      return;
    }

    final message =
        'Hello ${lead.name}, I am following up from Koniwala Matrimonial.';
    final whatsappUri = Uri(
      scheme: 'whatsapp',
      host: 'send',
      queryParameters: {'phone': cleanPhone, 'text': message},
    );
    final webUri = Uri.https('wa.me', '/$cleanPhone', {'text': message});

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        return;
      }

      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }

      if (!mounted) {
        return;
      }
      _showActionMessage('WhatsApp is not available on this device.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showActionMessage('Unable to open WhatsApp chat.');
    }
  }

  void _showActionMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openDashboardTab(int index) {
    final navigator = Navigator.of(context);
    context.read<NavigationProvider>().setIndex(index);
    navigator.pushReplacementNamed(AppRoutes.relationshipManagerDashboard);
  }

  void _handleBottomNavTap(int index) {
    _openDashboardTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final leadsProvider = context.watch<RmLeadsProvider>();
    final rawSelectedTab = context.watch<NavigationProvider>().selectedIndex;
    final selectedTab = _selectedBottomNavIndex(rawSelectedTab);
    final user = authProvider.userModel?.user;
    final assignedLeads = _assignedLeads(leadsProvider.leads, user?.id);
    final syncedChats = assignedLeads
        .where((lead) => lead.hasConversation)
        .length;
    final openTasks = assignedLeads.fold<int>(
      0,
      (count, lead) => count + lead.openTasksCount,
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.rmSoftPink,
      drawer: _RelationshipManagerLeadsDrawer(
        userName: user?.name ?? 'Relationship Manager',
        onDashboardTap: () => _openDashboardTab(0),
        onMatchesTap: () => _openDashboardTab(1),
        onLeadsTap: () => Navigator.of(context).pop(),
        onLeadFollowUpsTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed(AppRoutes.leadFollowUps);
        },
        onClientTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ClientRegistryScreen()),
          );
        },
        onLeaveManagementTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed(AppRoutes.leaves);
        },
        onHolidayManagementTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed(AppRoutes.holidayManagement);
        },
        onAccountTap: () => _openDashboardTab(2),
        onAiMatchmakingTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed(AppRoutes.aiMatching);
        },
        onNotificationsTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed(AppRoutes.notifications);
        },
        onSupportTap: () => Navigator.of(context).pop(),
        onLogoutTap: () async {
          await context.read<AuthProvider>().logout();
          if (!context.mounted) {
            return;
          }

          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        },
      ),
      bottomNavigationBar: _RelationshipManagerBottomNav(
        selectedIndex: selectedTab,
        onChanged: _handleBottomNavTap,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.rmPrimary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 22.h),
            children: [
              _LeadHubHeader(
                managerName: user?.name ?? 'Relationship Manager',
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                onRefresh: () {
                  _refresh();
                },
              ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Assigned Leads',
                      value: '${assignedLeads.length}',
                      subtitle: 'From /leads',
                      accent: AppColors.rmPrimary,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Chats Synced',
                      value: '$syncedChats',
                      subtitle: 'WhatsApp logs',
                      accent: AppColors.whatsappGreen,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Open Tasks',
                      value: '$openTasks',
                      subtitle: 'Follow-ups',
                      accent: AppColors.accent,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.rmPaleRoseBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38.r,
                      height: 38.r,
                      decoration: BoxDecoration(
                        color: AppColors.whatsappGreen.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.forum_outlined,
                        color: AppColors.whatsappGreen,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dynamic Manager Chat Hub',
                            style: GoogleFonts.inter(
                              color: AppColors.rmHeading,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'This screen reads live manager lead data from `/leads` using the current bearer token.',
                            style: GoogleFonts.inter(
                              color: AppColors.rmBodyText,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (leadsProvider.isLoading && assignedLeads.isNotEmpty) ...[
                SizedBox(height: 14.h),
                const LinearProgressIndicator(
                  color: AppColors.rmPrimary,
                  backgroundColor: Color(0xFFF5DDE7),
                ),
              ],
              SizedBox(height: 18.h),
              if (leadsProvider.isLoading && assignedLeads.isEmpty)
                const _LeadHubMessage(
                  message: 'Loading manager leads and WhatsApp activity...',
                  showLoader: true,
                )
              else if (leadsProvider.error != null && assignedLeads.isEmpty)
                _LeadHubMessage(
                  message: leadsProvider.error!,
                  actionLabel: 'Retry',
                  onActionPressed: () =>
                      context.read<RmLeadsProvider>().retry(),
                )
              else if (assignedLeads.isEmpty)
                _LeadHubMessage(
                  message: user == null
                      ? 'No leads available for this manager.'
                      : 'No `/leads` records are assigned to ${user.name} yet.',
                )
              else ...[
                Text(
                  'Conversation Queue',
                  style: GoogleFonts.inter(
                    color: AppColors.rmPrimary,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Open a lead to continue the conversation in WhatsApp.',
                  style: GoogleFonts.inter(
                    color: AppColors.rmBodyText,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 14.h),
                for (int index = 0; index < assignedLeads.length; index++) ...[
                  _ManagerLeadCard(
                    lead: assignedLeads[index],
                    onOpenChat: () =>
                        unawaited(_openChat(assignedLeads[index])),
                    onViewTasks: () =>
                        _openTasksBottomSheet(assignedLeads[index]),
                  ),
                  if (index != assignedLeads.length - 1) SizedBox(height: 14.h),
                ],
              ],
              if (leadsProvider.error != null && assignedLeads.isNotEmpty) ...[
                SizedBox(height: 16.h),
                _LeadHubMessage(
                  message: leadsProvider.error!,
                  actionLabel: 'Retry',
                  onActionPressed: () =>
                      context.read<RmLeadsProvider>().retry(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RelationshipManagerBottomNav extends StatelessWidget {
  const _RelationshipManagerBottomNav({
    required this.selectedIndex,
    required this.onChanged,
  });

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
            _RelationshipManagerBottomNavItem(
              label: 'Dashboard',
              icon: Icons.space_dashboard_outlined,
              iconAsset: 'assets/icon/dashbaord_icon.png',
              selected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
            _RelationshipManagerBottomNavItem(
              label: 'Matches',
              icon: Icons.filter_alt_outlined,
              selected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
            _RelationshipManagerBottomNavItem(
              label: 'Account',
              icon: Icons.person_outline,
              selected: selectedIndex == 2,
              onTap: () => onChanged(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelationshipManagerBottomNavItem extends StatelessWidget {
  const _RelationshipManagerBottomNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.iconAsset,
  });

  final String label;
  final IconData icon;
  final String? iconAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inactive = AppColors.inactiveNavItemColor;
    final maroon = AppColors.rmPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.selectedNavItemBackgroundColor
              : AppColors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconAsset != null)
              Image.asset(
                iconAsset!,
                width: 26.sp,
                height: 26.sp,
                color: selected ? maroon : inactive,
              )
            else
              Icon(icon, size: 26.sp, color: selected ? maroon : inactive),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
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

class _LeadHubHeader extends StatelessWidget {
  const _LeadHubHeader({
    required this.managerName,
    required this.onMenuPressed,
    required this.onRefresh,
  });

  final String managerName;
  final VoidCallback onMenuPressed;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: onMenuPressed,
          icon: Icon(Icons.menu, color: AppColors.rmPrimary, size: 24.sp),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WhatsApp Chat Queue',
                style: GoogleFonts.inter(
                  color: AppColors.rmPrimary,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Manager: $managerName',
                style: GoogleFonts.inter(
                  color: AppColors.rmBodyText,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: onRefresh,
          icon: Icon(Icons.refresh, color: AppColors.rmPrimary, size: 22.sp),
        ),
      ],
    );
  }
}

class _RelationshipManagerLeadsDrawer extends StatelessWidget {
  const _RelationshipManagerLeadsDrawer({
    required this.userName,
    required this.onDashboardTap,
    required this.onMatchesTap,
    required this.onLeadsTap,
    required this.onLeadFollowUpsTap,
    required this.onClientTap,
    required this.onLeaveManagementTap,
    required this.onHolidayManagementTap,
    required this.onAccountTap,
    required this.onAiMatchmakingTap,
    required this.onNotificationsTap,
    required this.onSupportTap,
    required this.onLogoutTap,
  });

  final String userName;
  final VoidCallback onDashboardTap;
  final VoidCallback onMatchesTap;
  final VoidCallback onLeadsTap;
  final VoidCallback onLeadFollowUpsTap;
  final VoidCallback onClientTap;
  final VoidCallback onLeaveManagementTap;
  final VoidCallback onHolidayManagementTap;
  final VoidCallback onAccountTap;
  final VoidCallback onAiMatchmakingTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onSupportTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
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
                              'Relationship Manager',
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
                    children: [
                      Expanded(
                        child: _RelationshipManagerLeadsDrawerMetric(
                          value: '9',
                          label: 'Leads',
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _RelationshipManagerLeadsDrawerMetric(
                          value: '2',
                          label: 'Tasks',
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _RelationshipManagerLeadsDrawerMetric(
                          value: '1',
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
                      style: GoogleFonts.inter(
                        color: AppColors.rmMutedText,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  _RelationshipManagerLeadsDrawerItem(
                    label: 'Dashboard',
                    icon: Icons.space_dashboard_outlined,
                    selected: false,
                    onTap: onDashboardTap,
                  ),
                  _RelationshipManagerLeadsDrawerItem(
                    label: 'All Matches',
                    icon: Icons.filter_alt_outlined,
                    selected: false,
                    onTap: onMatchesTap,
                  ),
                  _RelationshipManagerLeadsDrawerItem(
                    label: 'Leads',
                    icon: Icons.person_search_outlined,
                    selected: true,
                    onTap: onLeadsTap,
                  ),
                  _RelationshipManagerLeadsDrawerItem(
                    label: 'Lead Follow-ups',
                    icon: Icons.event_available_outlined,
                    selected: false,
                    onTap: onLeadFollowUpsTap,
                  ),
                  _RelationshipManagerLeadsDrawerItem(
                    label: 'Clients',
                    icon: Icons.assignment_ind_outlined,
                    selected: false,
                    onTap: onClientTap,
                  ),
                  _RelationshipManagerLeadsDrawerItem(
                    label: 'Leave Management',
                    icon: Icons.calendar_today_outlined,
                    selected: false,
                    onTap: onLeaveManagementTap,
                  ),
                  _RelationshipManagerLeadsDrawerItem(
                    label: 'Holiday Management',
                    icon: Icons.beach_access_outlined,
                    selected: false,
                    onTap: onHolidayManagementTap,
                  ),
                  _RelationshipManagerLeadsDrawerItem(
                    label: 'Account',
                    icon: Icons.person_outline,
                    selected: false,
                    onTap: onAccountTap,
                  ),
                  Divider(height: 28.h, color: AppColors.rmPaleRoseBorder),
                  _RelationshipManagerLeadsDrawerItem(
                    label: 'AI Matching',
                    icon: Icons.auto_awesome_outlined,
                    selected: false,
                    onTap: onAiMatchmakingTap,
                  ),
                  _RelationshipManagerLeadsDrawerItem(
                    label: 'Notifications',
                    icon: Icons.notifications_none_outlined,
                    selected: false,
                    onTap: onNotificationsTap,
                  ),
                  _RelationshipManagerLeadsDrawerItem(
                    label: 'Support',
                    icon: Icons.support_agent_outlined,
                    selected: false,
                    onTap: onSupportTap,
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
                            style: GoogleFonts.inter(
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
                      onPressed: onLogoutTap,
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

class _RelationshipManagerLeadsDrawerMetric extends StatelessWidget {
  const _RelationshipManagerLeadsDrawerMetric({
    required this.value,
    required this.label,
  });

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

class _RelationshipManagerLeadsDrawerItem extends StatelessWidget {
  const _RelationshipManagerLeadsDrawerItem({
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
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
            width: 28.r,
            height: 28.r,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.insights_outlined, color: accent, size: 16.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.rmMutedText,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.rmHeading,
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.rmBodyText,
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadHubMessage extends StatelessWidget {
  const _LeadHubMessage({
    required this.message,
    this.actionLabel,
    this.onActionPressed,
    this.showLoader = false,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final bool showLoader;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
      ),
      child: Column(
        children: [
          if (showLoader) ...[
            const CircularProgressIndicator(color: AppColors.rmPrimary),
            SizedBox(height: 14.h),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.rmBodyText,
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (actionLabel != null && onActionPressed != null) ...[
            SizedBox(height: 14.h),
            OutlinedButton(
              onPressed: onActionPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rmPrimary,
                side: const BorderSide(color: AppColors.rmPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                actionLabel!,
                style: GoogleFonts.inter(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ManagerLeadCard extends StatelessWidget {
  const _ManagerLeadCard({
    required this.lead,
    required this.onOpenChat,
    required this.onViewTasks,
  });

  final RmLeadItem lead;
  final VoidCallback onOpenChat;
  final VoidCallback onViewTasks;

  @override
  Widget build(BuildContext context) {
    final profileTask = lead.profileCreationTask;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
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
              CircleAvatar(
                radius: 28.r,
                backgroundColor: const Color(0xFFF7D9E3),
                child: Text(
                  lead.initials,
                  style: GoogleFonts.inter(
                    color: AppColors.rmPrimary,
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
                      lead.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.rmPrimary,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      '${lead.phone} - ${lead.city}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.rmBodyText,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      lead.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.rmMutedText,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              _StageBadge(label: lead.stageLabel),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _InfoChip(
                icon: Icons.language,
                label: lead.sourceLabel,
                textColor: AppColors.rmHeading,
                background: const Color(0xFFF7F0F3),
              ),
              _InfoChip(
                icon: Icons.person_search_outlined,
                label: lead.leadForLabel,
                textColor: AppColors.rmHeading,
                background: const Color(0xFFF6F8FF),
              ),
              _InfoChip(
                icon: Icons.apartment_outlined,
                label: lead.communityLabel,
                textColor: AppColors.rmHeading,
                background: const Color(0xFFF9F5ED),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBF8),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: AppColors.whatsappGreen.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.whatsappGreen,
                  size: 18.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    lead.latestMessagePreview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.rmBodyText,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Open Tasks',
                  value: '${lead.openTasksCount}',
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _MetricTile(
                  label: 'Intent Score',
                  value: '${lead.intentScore}%',
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _MetricTile(
                  label: 'Latest Activity',
                  value: _formatDateTime(
                    lead.latestActivityAt,
                    fallback: '-',
                    includeTime: false,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.rmBackground,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.rmPinkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InlineMetaRow(
                  label: 'Assigned To',
                  value: lead.assignedToName,
                ),
                SizedBox(height: 6.h),
                _InlineMetaRow(
                  label: 'Petitioner Relation',
                  value: lead.petitionerRelationLabel,
                ),
                SizedBox(height: 6.h),
                _InlineMetaRow(
                  label: 'Profile Creation',
                  value: profileTask == null
                      ? 'No profile task'
                      : '${profileTask.title} - ${profileTask.statusLabel}',
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onOpenChat,
                  icon: Icon(Icons.chat_bubble_outline, size: 18.sp),
                  label: Text(
                    'Open WhatsApp',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rmPrimary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewTasks,
                  icon: Icon(Icons.task_alt_outlined, size: 18.sp),
                  label: Text(
                    'View Tasks',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.rmHeading,
                    side: const BorderSide(color: AppColors.rmPinkBorder),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.rmStatusBg,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: AppColors.rmStatusBorder),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: AppColors.rmStatusText,
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color textColor;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 15.sp),
          SizedBox(width: 6.w),
          Text(
            label,
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCFD),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.rmMutedText,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.rmHeading,
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMetaRow extends StatelessWidget {
  const _InlineMetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.rmMutedText,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              color: AppColors.rmHeading,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _LeadTasksSheet extends StatelessWidget {
  const _LeadTasksSheet({required this.lead});

  final RmLeadItem lead;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 22.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 54.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              '${lead.name} Tasks',
              style: GoogleFonts.inter(
                color: AppColors.rmPrimary,
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Tasks synced from `/leads` for this manager conversation.',
              style: GoogleFonts.inter(
                color: AppColors.rmBodyText,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16.h),
            if (lead.tasks.isEmpty)
              const _LeadHubMessage(
                message: 'No tasks are attached to this lead yet.',
              )
            else
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: lead.tasks.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final task = lead.tasks[index];
                    return Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: AppColors.rmBackground,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: AppColors.rmPinkBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: GoogleFonts.inter(
                                    color: AppColors.rmHeading,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              _SheetStatusChip(label: task.statusLabel),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: [
                              _SheetMetaChip(label: task.typeLabel),
                              _SheetMetaChip(label: task.priorityLabel),
                              _SheetMetaChip(label: task.workflowStatusLabel),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            'Assigned to ${task.assignedToName}',
                            style: GoogleFonts.inter(
                              color: AppColors.rmBodyText,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Due: ${_formatDateTime(task.dueAt, fallback: 'Not scheduled')}',
                            style: GoogleFonts.inter(
                              color: AppColors.rmMutedText,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SheetStatusChip extends StatelessWidget {
  const _SheetStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.rmStatusBg,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: AppColors.rmStatusBorder),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: AppColors.rmStatusText,
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SheetMetaChip extends StatelessWidget {
  const _SheetMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: AppColors.rmPinkBorder),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: AppColors.rmHeading,
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _formatDateTime(
  DateTime? value, {
  String fallback = '-',
  bool includeTime = true,
}) {
  if (value == null) {
    return fallback;
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

  final buffer = StringBuffer(
    '${value.day} ${months[value.month - 1]} ${value.year}',
  );

  if (!includeTime) {
    return buffer.toString();
  }

  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final meridiem = value.hour >= 12 ? 'PM' : 'AM';
  buffer.write(' - $hour:$minute $meridiem');
  return buffer.toString();
}
