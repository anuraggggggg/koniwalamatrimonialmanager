import 'dart:convert';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:koniwalamatrimonial/attendance_archives_screen.dart';
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/models/manager_dashboard.dart';
import 'package:koniwalamatrimonial/models/workflow_task.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/providers/lead_follow_up_provider.dart';
import 'package:koniwalamatrimonial/providers/manager_dashboard_provider.dart';
import 'package:koniwalamatrimonial/providers/navigation_provider.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:koniwalamatrimonial/owner/Screen/registry_screen.dart';
import 'package:koniwalamatrimonial/owner/Screen/client_registry_screen.dart';
import 'package:koniwalamatrimonial/widgets/koniwala_primary_app_bar.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

BoxDecoration _dashboardCardDecoration({double radius = 16}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.rmPaleRoseBorder),
    boxShadow: const [
      BoxShadow(
        color: AppColors.rmCardShadow,
        blurRadius: 14,
        offset: Offset(0, 6),
      ),
    ],
  );
}

String _formatDashboardLabel(String value) {
  if (value.trim().isEmpty) {
    return '';
  }

  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

String _buildRecentProfileSubtitle(ManagerRecentProfileItem profile) {
  final parts = <String>[];
  if (profile.client.isNotEmpty) {
    parts.add('Client: ${profile.client}');
  }
  if (profile.time.isNotEmpty) {
    parts.add(profile.time);
  }
  if (parts.isEmpty && profile.source.isNotEmpty) {
    parts.add(_formatDashboardLabel(profile.source));
  }
  return parts.isEmpty ? 'Profile ready for review' : parts.join(' - ');
}

class _DashboardBadgePalette {
  const _DashboardBadgePalette({required this.background, required this.text});

  final Color background;
  final Color text;
}

_DashboardBadgePalette _priorityPalette(String priority) {
  switch (priority.toLowerCase()) {
    case 'high':
      return _DashboardBadgePalette(
        background: const Color(0xFFFFDAD6),
        text: const Color(0xFFBA1A1A),
      );
    case 'medium':
      return _DashboardBadgePalette(
        background: const Color(0xFFFFE9C5),
        text: const Color(0xFF8D5A00),
      );
    case 'low':
      return _DashboardBadgePalette(
        background: const Color(0xFFDDF5E5),
        text: const Color(0xFF166534),
      );
    default:
      return _DashboardBadgePalette(
        background: const Color(0xFFF3E8FF),
        text: const Color(0xFF6B21A8),
      );
  }
}

_DashboardBadgePalette _profileStatusPalette(String status) {
  switch (status.toUpperCase()) {
    case 'ACTIVE':
      return _DashboardBadgePalette(
        background: const Color(0xFFDDF5E5),
        text: const Color(0xFF166534),
      );
    case 'INACTIVE':
    case 'FAILED':
      return _DashboardBadgePalette(
        background: const Color(0xFFFFDAD6),
        text: const Color(0xFFBA1A1A),
      );
    default:
      return _DashboardBadgePalette(
        background: const Color(0xFFFFE9C5),
        text: const Color(0xFF8D5A00),
      );
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

class _DashboardTaskCardData {
  const _DashboardTaskCardData({
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.textColor,
  });

  final String title;
  final String badge;
  final Color badgeColor;
  final Color textColor;
}

List<_DashboardTaskCardData> _buildDashboardTaskCards(
  ManagerDashboard? dashboard,
) {
  if (dashboard == null) {
    return const [
      _DashboardTaskCardData(
        title: 'Check Clara J. Profile',
        badge: 'New',
        badgeColor: Color(0xFFE3D31F),
        textColor: Color(0xFF5A4A00),
      ),
      _DashboardTaskCardData(
        title: 'Profile Verification',
        badge: 'Review',
        badgeColor: Color(0xFFBE4A82),
        textColor: Color(0xFFF5D5E6),
      ),
    ];
  }

  if (dashboard.aiSuggestions.isNotEmpty) {
    return dashboard.aiSuggestions.take(2).map((suggestion) {
      final palette = _priorityPalette(suggestion.priority);
      return _DashboardTaskCardData(
        title: suggestion.title,
        badge: suggestion.actionLabel,
        badgeColor: palette.background,
        textColor: palette.text,
      );
    }).toList();
  }

  if (dashboard.aiPanel.tasks.isNotEmpty) {
    return dashboard.aiPanel.tasks.take(2).map((task) {
      final palette = _priorityPalette(task.priority);
      return _DashboardTaskCardData(
        title: task.title,
        badge: _formatDashboardLabel(task.badge),
        badgeColor: palette.background,
        textColor: palette.text,
      );
    }).toList();
  }

  return const [
    _DashboardTaskCardData(
      title: 'No pending AI tasks right now',
      badge: 'Clear',
      badgeColor: Color(0xFFDDF5E5),
      textColor: Color(0xFF166534),
    ),
  ];
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Color _maroon = AppColors.primary;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<String> _ranges = const [
    'Today',
    'Weekly',
    'Past Month',
    'This Year',
  ];
  String _selectedRange = 'Past Month';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchManagerDashboard(forceRefresh: true);
      }
    });
  }

  String get _selectedPeriodKey => _periodKeyForRange(_selectedRange);

  String _periodKeyForRange(String range) {
    switch (range) {
      case 'Today':
        return 'today';
      case 'Weekly':
        return 'this_week';
      case 'This Year':
        return 'this_year';
      case 'Past Month':
      default:
        return 'past_month';
    }
  }

  void _fetchManagerDashboard({bool forceRefresh = false}) {
    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    context.read<ManagerDashboardProvider>().fetchDashboard(
      accessToken,
      period: _selectedPeriodKey,
      forceRefresh: forceRefresh,
    );
    context.read<LeadFollowUpProvider>().fetchFollowUps(accessToken);
  }

  void _selectRange(String range) {
    if (range == _selectedRange) {
      return;
    }

    setState(() => _selectedRange = range);
    _fetchManagerDashboard(forceRefresh: true);
  }

  void _openRegistryTab() {
    context.read<NavigationProvider>().setIndex(2);
  }

  Future<void> _openManualEntry() async {
    await Navigator.of(context).pushNamed(AppRoutes.newProfileDigitization);

    if (!mounted) {
      return;
    }

    _fetchManagerDashboard(forceRefresh: true);
  }

  Future<void> _showDashboardFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 22.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Filters',
                  style: GoogleFonts.inter(
                    color: AppColors.rmHeading,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Choose the activity period for dashboard metrics.',
                  style: GoogleFonts.inter(
                    color: AppColors.rmBodyText,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16.h),
                for (final range in _ranges) ...[
                  _DashboardFilterOption(
                    label: range,
                    selected: range == _selectedRange,
                    maroon: _maroon,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _selectRange(range);
                    },
                  ),
                  if (range != _ranges.last) SizedBox(height: 10.h),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatRevenue(int value) {
    if (value >= 10000000) {
      return 'Rs. ${(value / 10000000).toStringAsFixed(1)}Cr';
    }
    if (value >= 100000) {
      return 'Rs. ${(value / 100000).toStringAsFixed(1)}L';
    }
    if (value >= 1000) {
      return 'Rs. ${(value / 1000).toStringAsFixed(1)}K';
    }
    return 'Rs. $value';
  }

  List<Widget> _buildFunnelCards(List<ManagerDashboardFunnelItem>? items) {
    if (items == null || items.isEmpty) {
      return [
        _FunnelCard(
          maroon: _maroon,
          title: 'New Inquiries',
          count: 12,
          progress: 0.35,
        ),
        SizedBox(height: 10.h),
        _FunnelCard(
          maroon: _maroon,
          title: 'Profiling in Progress',
          count: 8,
          progress: 0.25,
        ),
        SizedBox(height: 10.h),
        _FunnelCard(
          maroon: _maroon,
          title: 'Match Selection',
          count: 15,
          progress: 0.55,
        ),
      ];
    }

    final visibleItems = items.take(3).toList();
    return [
      for (var index = 0; index < visibleItems.length; index++) ...[
        if (index > 0) SizedBox(height: 10.h),
        _FunnelCard(
          maroon: _maroon,
          title: visibleItems[index].label,
          count: visibleItems[index].count,
          progress: visibleItems[index].normalizedProgress,
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = context.watch<NavigationProvider>().selectedIndex;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel?.user;
    final accessToken = authProvider.userModel?.accessToken;
    final managerDashboardProvider = context.watch<ManagerDashboardProvider>();
    final managerDashboard = managerDashboardProvider.dashboard;
    final managerKpi = managerDashboard?.kpi;
    if (selectedTab == 0 &&
        accessToken != null &&
        accessToken.isNotEmpty &&
        !managerDashboardProvider.isLoading &&
        !managerDashboardProvider.hasRequestFor(
          accessToken: accessToken,
          period: _selectedPeriodKey,
        )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchManagerDashboard();
        }
      });
    }

    final statItems = [
      _StatItem('TOTAL LEADS', '${managerKpi?.totalLeads ?? 9}'),
      _StatItem('ACTIVE PROFILES', '${managerKpi?.activeProfiles ?? 18}'),
      _StatItem('MATCHES TODAY', '${managerKpi?.matchesToday ?? 0}'),
      _StatItem('CONVERSION RATE', '${managerKpi?.conversionRate ?? 0}%'),
      _StatItem('REVENUE', _formatRevenue(managerKpi?.revenue ?? 0)),
      _StatItem('FOLLOW-UPS', '${managerKpi?.followUpsDue ?? 18}'),
    ];

    String dashboardTitle = 'Manager Dashboard';
    if (user != null) {
      if (user.role == 'HR' || user.role == 'ADMIN') {
        dashboardTitle = '${user.role} Dashboard';
      } else {
        dashboardTitle = user.role
            .split('_')
            .map(
              (word) => word[0].toUpperCase() + word.substring(1).toLowerCase(),
            )
            .join(' ');
        dashboardTitle = '$dashboardTitle Dashboard';
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      drawerScrimColor: Colors.black.withValues(alpha: 0.1),
      // drawerElevation: 0,
      backgroundColor: AppColors.rmSoftPink,
      appBar: selectedTab == 1
          ? null
          : KoniwalaPrimaryAppBar(
              showMenuButton: true,
              onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
      drawer: _ManagerDashboardDrawer(
        userName: user?.name ?? 'Manager',
        roleLabel: dashboardTitle.replaceFirst(' Dashboard', ''),
        dashboard: managerDashboard,
        selectedIndex: selectedTab,
        onItemSelected: (index) =>
            context.read<NavigationProvider>().setIndex(index),
        onLogout: () async {
          await context.read<AuthProvider>().logout();

          if (!context.mounted) {
            return;
          }

          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        },
      ),
      bottomNavigationBar: _DashboardBottomNav(
        maroon: _maroon,
        selectedIndex: selectedTab,
        onChanged: (index) =>
            context.read<NavigationProvider>().setIndex(index),
      ),
      body: SafeArea(
        top: false,
        child: selectedTab == 0
            ? SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.h),
                    _SearchBar(maroon: _maroon),
                    SizedBox(height: 26.h),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _ActionPill(
                            label: 'Filters',
                            icon: Icons.tune,
                            imageAsset: 'assets/filter_icons.png',
                            maroon: _maroon,
                            filled: false,
                            onTap: _showDashboardFilters,
                          ),
                          SizedBox(width: 15.w),
                          _ActionPill(
                            label: 'Registry',
                            icon: Icons.list_alt,
                            maroon: _maroon,
                            filled: true,
                            onTap: _openRegistryTab,
                          ),
                          SizedBox(width: 15.w),
                          _ActionPill(
                            label: 'Manual Entry',
                            icon: Icons.edit_square,
                            imageAsset: 'assets/add.png',
                            maroon: _maroon,
                            filled: false,
                            onTap: _openManualEntry,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 28.h),
                    Row(
                      children: _ranges
                          .map(
                            (range) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                child: _RangeChip(
                                  label: range,
                                  selected: range == _selectedRange,
                                  maroon: _maroon,
                                  onTap: () => _selectRange(range),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    if (managerDashboardProvider.isLoading) ...[
                      SizedBox(height: 12.h),
                      LinearProgressIndicator(
                        minHeight: 3,
                        color: AppColors.primary,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ],
                    if ((managerDashboard?.period.displayText ?? '')
                        .isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      Text(
                        managerDashboard!.period.displayText,
                        style: GoogleFonts.inter(
                          color: AppColors.rmBodyText,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (managerDashboardProvider.error != null &&
                        managerDashboard == null) ...[
                      SizedBox(height: 10.h),
                      Text(
                        managerDashboardProvider.error!,
                        style: GoogleFonts.inter(
                          color: Colors.red.shade700,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    SizedBox(height: 25.h),
                    _StatsGrid(maroon: AppColors.primary, items: statItems),
                    SizedBox(height: 16.h),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: _dashboardCardDecoration(),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Assigned Funnel',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF181C1F),
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w600,
                                  height: 1.60,
                                ),
                              ),
                              SizedBox(
                                height: 20.h,
                                width: 20.h,
                                child: Image.asset(
                                  'assets/filter_red_funnel.png',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Divider(color: Colors.grey[100]),
                          SizedBox(height: 10.h),

                          ..._buildFunnelCards(managerDashboard?.funnel),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),
                    _UrgentFocusCard(
                      maroon: _maroon,
                      dashboard: managerDashboard,
                    ),
                    SizedBox(height: 16.h),
                    _ScreenshotAssetsPanel(
                      maroon: _maroon,
                      dashboard: managerDashboard,
                    ),
                    SizedBox(height: 14.h),
                    _LeadCardsPanel(
                      maroon: _maroon,
                      dashboard: managerDashboard,
                    ),
                    SizedBox(height: 14.h),
                    _LeadFollowUpsPanel(maroon: _maroon),
                  ],
                ),
              )
            : selectedTab == 1
            ? AttendanceArchivesScreen(
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : selectedTab == 2
            ? RegistryScreen(
                showScaffold: false,
                showEmbeddedAppBar: false,
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : selectedTab == 4
            ? const ClientRegistryScreen()
            : _ManagerChatWorkspace(
                maroon: _maroon,
                dashboard: managerDashboard,
                onOpenRegistry: () =>
                    context.read<NavigationProvider>().setIndex(2),
                onOpenClientRegistry: () =>
                    context.read<NavigationProvider>().setIndex(4),
                onOpenFollowUps: () =>
                    Navigator.of(context).pushNamed(AppRoutes.leadFollowUps),
                onOpenNotifications: () =>
                    Navigator.of(context).pushNamed(AppRoutes.notifications),
              ),
      ),
    );
  }
}

class _ManagerChatThreadData {
  const _ManagerChatThreadData({
    required this.name,
    required this.clientLabel,
    required this.preview,
    required this.stateLabel,
    required this.timeLabel,
    required this.initials,
    required this.unreadCount,
    required this.verified,
    required this.actionLabel,
    this.phone,
    this.notificationId,
  });

  final String name;
  final String clientLabel;
  final String preview;
  final String stateLabel;
  final String timeLabel;
  final String initials;
  final int unreadCount;
  final bool verified;
  final String actionLabel;
  final String? phone;
  final String? notificationId;
}

class _ManagerChatSuggestionData {
  const _ManagerChatSuggestionData({
    required this.title,
    required this.description,
    required this.priority,
    required this.actionLabel,
  });

  final String title;
  final String description;
  final String priority;
  final String actionLabel;
}

class _ManagerChatActivityData {
  const _ManagerChatActivityData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
}

class _ChatAccentPalette {
  const _ChatAccentPalette({
    required this.background,
    required this.border,
    required this.text,
    required this.soft,
  });

  final Color background;
  final Color border;
  final Color text;
  final Color soft;
}

_ChatAccentPalette _chatAccentPalette(String label) {
  final normalized = label.toLowerCase();

  if (normalized.contains('awaiting') || normalized.contains('overdue')) {
    return const _ChatAccentPalette(
      background: Color(0xFFFFECE7),
      border: Color(0xFFFFC2B5),
      text: Color(0xFFB42318),
      soft: Color(0xFFFFF5F2),
    );
  }

  if (normalized.contains('draft') || normalized.contains('ready')) {
    return const _ChatAccentPalette(
      background: Color(0xFFFFF1D6),
      border: Color(0xFFFFD493),
      text: Color(0xFF9A5B00),
      soft: Color(0xFFFFF9EC),
    );
  }

  if (normalized.contains('verified') || normalized.contains('sent')) {
    return const _ChatAccentPalette(
      background: Color(0xFFDDF5E5),
      border: Color(0xFFA9D8B6),
      text: Color(0xFF166534),
      soft: Color(0xFFF2FBF5),
    );
  }

  return const _ChatAccentPalette(
    background: Color(0xFFF4E7EE),
    border: Color(0xFFE7C7D5),
    text: AppColors.primary,
    soft: Color(0xFFFCF5F8),
  );
}

List<_ManagerChatThreadData> _buildManagerChatThreads(
  ManagerDashboard? dashboard,
) {
  final urgent = dashboard?.urgent;
  final pendingReplies = urgent?.pendingReplies ?? 0;
  final readyToSend = urgent?.readyToSend ?? 0;
  final profiles =
      dashboard?.recentProfiles ?? const <ManagerRecentProfileItem>[];

  if (profiles.isNotEmpty) {
    return profiles.take(4).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final profile = entry.value;
      final isPending = index < pendingReplies;
      final isDraftReady = !isPending && index < pendingReplies + readyToSend;

      final stateLabel = isPending
          ? 'Awaiting Reply'
          : isDraftReady
          ? 'Draft Ready'
          : profile.verified
          ? 'Verified'
          : profile.status.isNotEmpty
          ? _formatDashboardLabel(profile.status)
          : 'Monitoring';

      final preview = isPending
          ? 'The latest family note needs a confident reply before the lead cools down.'
          : isDraftReady
          ? 'A response draft is prepared. Review the tone, then send the next step.'
          : profile.verified
          ? 'Verified details are ready to share with the client without another call.'
          : 'Conversation context is active. Keep momentum with a tailored follow-up.';

      return _ManagerChatThreadData(
        name: profile.name,
        clientLabel: profile.client.isNotEmpty
            ? profile.client
            : profile.source.isNotEmpty
            ? _formatDashboardLabel(profile.source)
            : 'Client Queue',
        preview: preview,
        stateLabel: stateLabel,
        timeLabel: profile.time.isNotEmpty ? profile.time : 'Moments ago',
        initials: profile.initials,
        unreadCount: isPending ? (index % 3) + 1 : 0,
        verified: profile.verified,
        actionLabel: isDraftReady
            ? 'Review Draft'
            : isPending
            ? 'Reply Now'
            : 'Open Client',
        phone: profile.phone,
        notificationId: profile.notificationId,
      );
    }).toList();
  }

  return const [
    _ManagerChatThreadData(
      name: 'Anaya Family',
      clientLabel: 'Priority Registry',
      preview:
          'The family is waiting on a polished reply before tonight\'s review call.',
      stateLabel: 'Awaiting Reply',
      timeLabel: '2 min ago',
      initials: 'AF',
      unreadCount: 2,
      verified: true,
      actionLabel: 'Reply Now',
      phone: '919876543210',
    ),
    _ManagerChatThreadData(
      name: 'Ritwik Profile',
      clientLabel: 'South Desk',
      preview:
          'The draft reply is ready. Confirm tone and send the shortlist update.',
      stateLabel: 'Draft Ready',
      timeLabel: '11 min ago',
      initials: 'RP',
      unreadCount: 0,
      verified: false,
      actionLabel: 'Review Draft',
      phone: '919876543211',
    ),
    _ManagerChatThreadData(
      name: 'Misha Client',
      clientLabel: 'Elite Match Desk',
      preview:
          'Share the verified biodata summary and keep the conversation warm.',
      stateLabel: 'Verified',
      timeLabel: '28 min ago',
      initials: 'MC',
      unreadCount: 0,
      verified: true,
      actionLabel: 'Open Client',
      phone: '919876543212',
    ),
  ];
}

List<_ManagerChatSuggestionData> _buildManagerChatSuggestions(
  ManagerDashboard? dashboard,
) {
  if (dashboard != null && dashboard.aiSuggestions.isNotEmpty) {
    return dashboard.aiSuggestions.take(3).map((suggestion) {
      return _ManagerChatSuggestionData(
        title: suggestion.title,
        description: suggestion.description.isNotEmpty
            ? suggestion.description
            : 'Use this assistant prompt to move the conversation forward.',
        priority: suggestion.priority.isNotEmpty
            ? suggestion.priority
            : 'medium',
        actionLabel: suggestion.actionLabel,
      );
    }).toList();
  }

  if (dashboard != null && dashboard.aiPanel.tasks.isNotEmpty) {
    return dashboard.aiPanel.tasks.take(3).map((task) {
      return _ManagerChatSuggestionData(
        title: task.title,
        description:
            'Convert this task into a clean client-ready reply without losing warmth.',
        priority: task.priority.isNotEmpty ? task.priority : task.badge,
        actionLabel: task.badge.isNotEmpty ? task.badge : 'Review',
      );
    }).toList();
  }

  return const [
    _ManagerChatSuggestionData(
      title: 'Warm Re-entry Draft',
      description:
          'Re-open silent threads with a concise update and a strong next-step question.',
      priority: 'high',
      actionLabel: 'Use Draft',
    ),
    _ManagerChatSuggestionData(
      title: 'Shortlist Follow-up',
      description:
          'Summarize compatibility signals and ask for a clear yes/no decision.',
      priority: 'medium',
      actionLabel: 'Apply',
    ),
    _ManagerChatSuggestionData(
      title: 'Meeting Confirmation',
      description:
          'Lock timing, venue, and parent expectations in one polished message.',
      priority: 'low',
      actionLabel: 'Queue',
    ),
  ];
}

List<_ManagerChatActivityData> _buildManagerChatActivities(
  ManagerDashboard? dashboard,
) {
  if (dashboard != null && dashboard.recentActivity.isNotEmpty) {
    return dashboard.recentActivity.take(4).map((item) {
      return _ManagerChatActivityData(
        title: item.title,
        subtitle: item.description.isNotEmpty
            ? item.description
            : 'Recent manager activity captured in the conversation desk.',
        icon: _activityIconForItem(item),
        actionLabel: item.action.isNotEmpty
            ? _formatDashboardLabel(item.action)
            : 'Open',
      );
    }).toList();
  }

  return const [
    _ManagerChatActivityData(
      title: 'Draft sent to Anaya Family',
      subtitle: 'The response was approved and pushed to the live queue.',
      icon: Icons.send_rounded,
      actionLabel: 'Sent',
    ),
    _ManagerChatActivityData(
      title: 'Ritwik thread marked warm',
      subtitle:
          'Client intent is positive. The next step is a shortlist review.',
      icon: Icons.local_fire_department_outlined,
      actionLabel: 'Updated',
    ),
    _ManagerChatActivityData(
      title: 'New reply waiting in queue',
      subtitle: 'A fresh client message arrived and needs a manager decision.',
      icon: Icons.mark_chat_unread_outlined,
      actionLabel: 'Pending',
    ),
  ];
}

class _ManagerChatBubbleData {
  const _ManagerChatBubbleData({
    required this.text,
    required this.timeLabel,
    required this.isIncoming,
    this.showReadReceipt = false,
    this.imagePath,
  });

  final String text;
  final String timeLabel;
  final bool isIncoming;
  final bool showReadReceipt;
  final String? imagePath;
}

List<_ManagerChatBubbleData> _buildManagerChatBubbles(
  _ManagerChatThreadData thread,
) {
  final incomingFirst = thread.stateLabel.toLowerCase().contains('awaiting');
  final responseLabel = thread.actionLabel == 'Review Draft'
      ? 'Draft is prepared. I am checking the tone before sending it.'
      : thread.actionLabel == 'Open Client'
      ? 'Client details are verified. I can share the next profile now.'
      : 'I am on it. Sending the next update in a few minutes.';

  return [
    _ManagerChatBubbleData(
      text:
          '${thread.clientLabel} family asked for the next update on ${thread.name}.',
      timeLabel: '09:12 AM',
      isIncoming: incomingFirst,
    ),
    _ManagerChatBubbleData(
      text: responseLabel,
      timeLabel: '09:14 AM',
      isIncoming: !incomingFirst,
      showReadReceipt: !incomingFirst,
    ),
    _ManagerChatBubbleData(
      text: thread.preview,
      timeLabel: thread.timeLabel,
      isIncoming: true,
    ),
    _ManagerChatBubbleData(
      text:
          'Noted. I have linked the follow-up and kept the thread active for the manager desk.',
      timeLabel: 'Now',
      isIncoming: false,
      showReadReceipt: true,
    ),
  ];
}

String _managerChatThreadKey(_ManagerChatThreadData thread) {
  return '${thread.name}::${thread.clientLabel}';
}

String _formatManagerChatTime(DateTime timestamp) {
  final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
  final minute = timestamp.minute.toString().padLeft(2, '0');
  final suffix = timestamp.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

class _ManagerChatWorkspace extends StatefulWidget {
  const _ManagerChatWorkspace({
    required this.maroon,
    required this.dashboard,
    required this.onOpenRegistry,
    required this.onOpenClientRegistry,
    required this.onOpenFollowUps,
    required this.onOpenNotifications,
  });

  final Color maroon;
  final ManagerDashboard? dashboard;
  final VoidCallback onOpenRegistry;
  final VoidCallback onOpenClientRegistry;
  final VoidCallback onOpenFollowUps;
  final VoidCallback onOpenNotifications;

  @override
  State<_ManagerChatWorkspace> createState() => _ManagerChatWorkspaceState();
}

class _ManagerChatWorkspaceState extends State<_ManagerChatWorkspace> {
  static const List<String> _filters = ['All', 'Unread', 'Priority'];
  final TextEditingController _messageController = TextEditingController();
  final Map<String, List<_ManagerChatBubbleData>> _sentMessages = {};
  String _activeFilter = 'All';
  int _selectedThreadIndex = 0;
  bool _showMobileConversation = false;

  Future<void> _openWhatsApp(_ManagerChatThreadData thread) async {
    final phone = thread.phone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp number not available for this contact'),
        ),
      );
      return;
    }

    // Clean phone number: remove non-digits, ensuring it has country code
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone'; // Default to India if 10 digits
    }

    final message =
        "Hello ${thread.name}, I am following up from Koniwala Matrimonial regarding ${thread.clientLabel}.";
    final url =
        "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}";
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  List<_ManagerChatBubbleData> _messagesForThread(
    _ManagerChatThreadData thread,
  ) {
    final localMessages = _sentMessages[_managerChatThreadKey(thread)];
    if (localMessages == null || localMessages.isEmpty) {
      return _buildManagerChatBubbles(thread);
    }

    return [..._buildManagerChatBubbles(thread), ...localMessages];
  }

  _ManagerChatThreadData _threadWithLocalPreview(
    _ManagerChatThreadData thread,
  ) {
    final localMessages = _sentMessages[_managerChatThreadKey(thread)];
    if (localMessages == null || localMessages.isEmpty) {
      return thread;
    }

    final latestMessage = localMessages.last;
    return _ManagerChatThreadData(
      name: thread.name,
      clientLabel: thread.clientLabel,
      preview: latestMessage.text,
      stateLabel: thread.stateLabel,
      timeLabel: latestMessage.timeLabel,
      initials: thread.initials,
      unreadCount: 0,
      verified: thread.verified,
      actionLabel: thread.actionLabel,
      phone: thread.phone,
      notificationId: thread.notificationId,
    );
  }

  void _sendMessage(_ManagerChatThreadData thread, {String? imagePath}) {
    final text = _messageController.text.trim();
    if (text.isEmpty && imagePath == null) {
      return;
    }

    _postFollowUpControlMessage(thread.notificationId);

    final threadKey = _managerChatThreadKey(thread);
    final outgoingMessage = _ManagerChatBubbleData(
      text: text,
      timeLabel: _formatManagerChatTime(DateTime.now()),
      isIncoming: false,
      showReadReceipt: true,
      imagePath: imagePath,
    );

    setState(() {
      _sentMessages[threadKey] = [
        ...?_sentMessages[threadKey],
        outgoingMessage,
      ];
      _messageController.clear();
    });
  }

  Future<void> _postFollowUpControlMessage(String? notificationId) async {
    final normalizedNotificationId = notificationId?.trim();
    if (normalizedNotificationId == null || normalizedNotificationId.isEmpty) {
      return;
    }

    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    if (accessToken == null || accessToken.trim().isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required to send message.')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.followUpControlMessageUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${accessToken.trim()}',
        },
        body: jsonEncode({
          'success': true,
          'notificationId': normalizedNotificationId,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Follow-up message API failed with ${response.statusCode}',
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update follow-up message.')),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  List<_ManagerChatThreadData> _filteredThreads(
    List<_ManagerChatThreadData> threads,
  ) {
    switch (_activeFilter) {
      case 'Unread':
        return threads.where((thread) => thread.unreadCount > 0).toList();
      case 'Priority':
        return threads.where((thread) {
          final state = thread.stateLabel.toLowerCase();
          return state.contains('awaiting') || state.contains('draft');
        }).toList();
      case 'All':
      default:
        return threads;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allThreads = _buildManagerChatThreads(widget.dashboard);
    final filteredThreads = _filteredThreads(allThreads);
    final threads = (filteredThreads.isEmpty ? allThreads : filteredThreads)
        .map(_threadWithLocalPreview)
        .toList();
    final selectedThreadIndex = _selectedThreadIndex >= threads.length
        ? 0
        : _selectedThreadIndex;
    final selectedThread = threads[selectedThreadIndex];
    final messages = _messagesForThread(selectedThread);
    final pendingReplies =
        widget.dashboard?.urgent.pendingReplies ??
        threads.where((thread) => thread.unreadCount > 0).length;
    final readyDrafts =
        widget.dashboard?.urgent.readyToSend ??
        threads.where((thread) => thread.actionLabel == 'Review Draft').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (!isWide && _showMobileConversation) {
          return ColoredBox(
            color: const Color(0xFFF7F4F1),
            child: _ManagerChatConversationPane(
              thread: selectedThread,
              messages: messages,
              onOpenClientRegistry: widget.onOpenClientRegistry,
              onOpenFollowUps: widget.onOpenFollowUps,
              messageController: _messageController,
              onSendMessage: ({imagePath}) =>
                  _sendMessage(selectedThread, imagePath: imagePath),
              compact: true,
              onBack: () {
                setState(() {
                  _showMobileConversation = false;
                  _messageController.clear();
                });
              },
              fullScreen: true,
            ),
          );
        }

        return ColoredBox(
          color: const Color(0xFFF7F4F1),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 18.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WhatsApp Chat',
                            style: GoogleFonts.inter(
                              color: widget.maroon,
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '$pendingReplies pending replies and $readyDrafts draft-ready conversations in the manager queue.',
                            style: GoogleFonts.inter(
                              color: AppColors.rmBodyText,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Notifications',
                      onPressed: widget.onOpenNotifications,
                      icon: Icon(
                        Icons.notifications_none_outlined,
                        color: widget.maroon,
                        size: 22.sp,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Follow-ups',
                      onPressed: widget.onOpenFollowUps,
                      icon: Icon(
                        Icons.event_available_outlined,
                        color: widget.maroon,
                        size: 22.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: AppColors.rmPaleRoseBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: AppColors.rmMutedText,
                        size: 21.sp,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'Search chats, clients, or message intent',
                          style: GoogleFonts.inter(
                            color: AppColors.rmMutedText,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      _ManagerTopActionChip(
                        label: 'Registry',
                        onTap: widget.onOpenRegistry,
                      ),
                      SizedBox(width: 8.w),
                      _ManagerTopActionChip(
                        label: 'Clients',
                        onTap: widget.onOpenClientRegistry,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final selected = _activeFilter == filter;
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: _ManagerChatFilterChip(
                          label: filter,
                          selected: selected,
                          onTap: () {
                            setState(() {
                              _activeFilter = filter;
                              _selectedThreadIndex = 0;
                              _showMobileConversation = false;
                              _messageController.clear();
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 14.h),
                Expanded(
                  child: isWide
                      ? Row(
                          children: [
                            SizedBox(
                              width: 320.w,
                              child: _ManagerChatConversationList(
                                threads: threads,
                                selectedThreadIndex: selectedThreadIndex,
                                onThreadSelected: (index) {
                                  final thread = threads[index];
                                  _openWhatsApp(thread);
                                  setState(() {
                                    _selectedThreadIndex = index;
                                    _messageController.clear();
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: _ManagerChatConversationPane(
                                thread: selectedThread,
                                messages: messages,
                                onOpenClientRegistry:
                                    widget.onOpenClientRegistry,
                                onOpenFollowUps: widget.onOpenFollowUps,
                                messageController: _messageController,
                                onSendMessage: ({imagePath}) => _sendMessage(
                                  selectedThread,
                                  imagePath: imagePath,
                                ),
                                compact: false,
                                onBack: null,
                                fullScreen: false,
                              ),
                            ),
                          ],
                        )
                      : _ManagerChatConversationList(
                          threads: threads,
                          selectedThreadIndex: selectedThreadIndex,
                          onThreadSelected: (index) {
                            final thread = threads[index];
                            _openWhatsApp(thread);
                            setState(() {
                              _selectedThreadIndex = index;
                              _showMobileConversation = true;
                              _messageController.clear();
                            });
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ManagerTopActionChip extends StatelessWidget {
  const _ManagerTopActionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.rmSoftPink,
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.rmPrimary,
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ManagerChatFilterChip extends StatelessWidget {
  const _ManagerChatFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.rmPrimary : Colors.white,
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(
            color: selected ? AppColors.rmPrimary : AppColors.rmPaleRoseBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : AppColors.rmPrimary,
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ManagerChatConversationList extends StatelessWidget {
  const _ManagerChatConversationList({
    required this.threads,
    required this.selectedThreadIndex,
    required this.onThreadSelected,
  });

  final List<_ManagerChatThreadData> threads;
  final int selectedThreadIndex;
  final ValueChanged<int> onThreadSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
      ),
      child: ListView.separated(
        padding: EdgeInsets.all(12.w),
        itemCount: threads.length,
        separatorBuilder: (context, index) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          final thread = threads[index];
          return _ManagerChatConversationTile(
            thread: thread,
            selected: index == selectedThreadIndex,
            onTap: () => onThreadSelected(index),
          );
        },
      ),
    );
  }
}

class _ManagerChatConversationTile extends StatelessWidget {
  const _ManagerChatConversationTile({
    required this.thread,
    required this.selected,
    required this.onTap,
  });

  final _ManagerChatThreadData thread;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _chatAccentPalette(thread.stateLabel);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF7E7EE) : const Color(0xFFFDF9FA),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: selected ? AppColors.rmPrimary : AppColors.rmPaleRoseBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: AppColors.rmPrimary,
              child: Text(
                thread.initials,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
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
                          thread.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppColors.rmHeading,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        thread.timeLabel,
                        style: GoogleFonts.inter(
                          color: AppColors.rmMutedText,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    thread.clientLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.rmMutedText,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    thread.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.rmBodyText,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: palette.background,
                          borderRadius: BorderRadius.circular(999.r),
                        ),
                        child: Text(
                          thread.stateLabel,
                          style: GoogleFonts.inter(
                            color: palette.text,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (thread.unreadCount > 0)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 5.h,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.whatsappGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${thread.unreadCount}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
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
      ),
    );
  }
}

class _ManagerChatConversationPane extends StatelessWidget {
  const _ManagerChatConversationPane({
    required this.thread,
    required this.messages,
    required this.onOpenClientRegistry,
    required this.onOpenFollowUps,
    required this.messageController,
    required this.onSendMessage,
    required this.compact,
    required this.onBack,
    required this.fullScreen,
  });

  final _ManagerChatThreadData thread;
  final List<_ManagerChatBubbleData> messages;
  final VoidCallback onOpenClientRegistry;
  final VoidCallback onOpenFollowUps;
  final TextEditingController messageController;
  final Function({String? imagePath}) onSendMessage;
  final bool compact;
  final VoidCallback? onBack;
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final palette = _chatAccentPalette(thread.stateLabel);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: fullScreen ? null : BorderRadius.circular(22.r),
        border: fullScreen
            ? null
            : Border.all(color: AppColors.rmPaleRoseBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFCF4F7),
              borderRadius: fullScreen
                  ? null
                  : BorderRadius.only(
                      topLeft: Radius.circular(22.r),
                      topRight: Radius.circular(22.r),
                    ),
              border: Border(
                bottom: BorderSide(color: AppColors.rmPaleRoseBorder),
              ),
            ),
            child: Row(
              children: [
                if (compact && onBack != null)
                  IconButton(
                    tooltip: 'Back',
                    onPressed: onBack,
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.rmPrimary,
                      size: 22.sp,
                    ),
                  ),
                CircleAvatar(
                  radius: 22.r,
                  backgroundColor: AppColors.rmPrimary,
                  child: Text(
                    thread.initials,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14.sp,
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
                        thread.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppColors.rmPrimary,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${thread.clientLabel} - ${thread.timeLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppColors.rmMutedText,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (compact) ...[
                  IconButton(
                    tooltip: 'Client',
                    onPressed: onOpenClientRegistry,
                    icon: Icon(
                      Icons.assignment_ind_outlined,
                      color: AppColors.rmPrimary,
                      size: 20.sp,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Follow-ups',
                    onPressed: onOpenFollowUps,
                    icon: Icon(
                      Icons.event_available_outlined,
                      color: AppColors.rmPrimary,
                      size: 20.sp,
                    ),
                  ),
                ] else
                  _ManagerChatStatusBadge(
                    label: thread.stateLabel,
                    palette: palette,
                  ),
              ],
            ),
          ),
          if (!compact) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: _ManagerTopActionChip(
                      label: 'Client Screen',
                      onTap: onOpenClientRegistry,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _ManagerTopActionChip(
                      label: 'Lead Follow-ups',
                      onTap: onOpenFollowUps,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 14.w),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6E7),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: AppColors.rmBodyText,
                    size: 14.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Messages are shown in a WhatsApp-style manager conversation view.',
                      style: GoogleFonts.inter(
                        color: AppColors.rmBodyText,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
          ] else
            SizedBox(height: 6.h),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 8.h),
              children: [
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8E6E7),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Text(
                      'Today',
                      style: GoogleFonts.inter(
                        color: AppColors.rmPrimary,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                for (final message in messages)
                  _ManagerChatBubble(message: message),
              ],
            ),
          ),
          _ManagerChatComposer(
            actionLabel: thread.actionLabel,
            controller: messageController,
            onSend: onSendMessage,
            fullScreen: fullScreen,
          ),
        ],
      ),
    );
  }
}

class _ManagerChatStatusBadge extends StatelessWidget {
  const _ManagerChatStatusBadge({required this.label, required this.palette});

  final String label;
  final _ChatAccentPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: palette.text,
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ManagerChatBubble extends StatelessWidget {
  const _ManagerChatBubble({required this.message});

  final _ManagerChatBubbleData message;

  @override
  Widget build(BuildContext context) {
    final hasImage = message.imagePath != null && message.imagePath!.isNotEmpty;

    return Align(
      alignment: message.isIncoming
          ? Alignment.centerLeft
          : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: 260.w),
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: message.isIncoming ? Colors.white : const Color(0xFFE1F3EA),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
                child: Image.file(
                  File(message.imagePath!),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 10.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: GoogleFonts.inter(
                        color: AppColors.rmHeading,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.timeLabel,
                        style: GoogleFonts.inter(
                          color: AppColors.rmMutedText,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (message.showReadReceipt) ...[
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.done_all,
                          color: Colors.blueAccent,
                          size: 12.sp,
                        ),
                      ],
                    ],
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

class _ManagerChatComposer extends StatefulWidget {
  const _ManagerChatComposer({
    required this.actionLabel,
    required this.controller,
    required this.onSend,
    required this.fullScreen,
  });

  final String actionLabel;
  final TextEditingController controller;
  final Function({String? imagePath}) onSend;
  final bool fullScreen;

  @override
  State<_ManagerChatComposer> createState() => _ManagerChatComposerState();
}

class _ManagerChatComposerState extends State<_ManagerChatComposer> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _handleSend() {
    if (widget.controller.text.trim().isEmpty && _selectedImage == null) return;
    widget.onSend(imagePath: _selectedImage?.path);
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selectedImage != null)
          Container(
            padding: EdgeInsets.all(8.w),
            color: const Color(0xFFF7F4F1),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Image.file(
                    File(_selectedImage!.path),
                    height: 120.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImage = null),
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 8.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F4F1),
            borderRadius: widget.fullScreen
                ? null
                : BorderRadius.only(
                    bottomLeft: Radius.circular(22.r),
                    bottomRight: Radius.circular(22.r),
                  ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.photo_camera),
                            title: const Text('Camera'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Gallery'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.add, color: AppColors.rmPrimary, size: 26.sp),
              ),
              Expanded(
                child: Container(
                  constraints: BoxConstraints(minHeight: 44.h),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: const Color(0xFFE6DDDD)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sentiment_satisfied_alt,
                        color: AppColors.rmBodyText,
                        size: 22.sp,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _handleSend(),
                          style: GoogleFonts.inter(
                            color: AppColors.rmHeading,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: 'Type a message or ${widget.actionLabel}',
                            hintStyle: GoogleFonts.inter(
                              color: AppColors.rmMutedText,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      if (widget.controller.text.isEmpty &&
                          _selectedImage == null) ...[
                        IconButton(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: Icon(
                            Icons.attach_file,
                            color: AppColors.rmBodyText,
                            size: 21.sp,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        SizedBox(width: 10.w),
                        IconButton(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: Icon(
                            Icons.photo_camera_outlined,
                            color: AppColors.rmBodyText,
                            size: 21.sp,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (context, value, _) {
                  final hasContent =
                      value.text.trim().isNotEmpty || _selectedImage != null;
                  return InkWell(
                    onTap: hasContent ? _handleSend : null,
                    borderRadius: BorderRadius.circular(999.r),
                    child: Container(
                      width: 46.r,
                      height: 46.r,
                      decoration: BoxDecoration(
                        color: hasContent
                            ? AppColors.rmPrimary
                            : AppColors.rmPrimary.withValues(alpha: 0.78),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasContent ? Icons.send_rounded : Icons.mic,
                        color: Colors.white,
                        size: 22.sp,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ManagerDashboardDrawer extends StatelessWidget {
  const _ManagerDashboardDrawer({
    required this.selectedIndex,
    required this.userName,
    required this.roleLabel,
    required this.dashboard,
    required this.onItemSelected,
    required this.onLogout,
  });

  final int selectedIndex;
  final String userName;
  final String roleLabel;
  final ManagerDashboard? dashboard;
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
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'M',
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
                              roleLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                      Expanded(
                        child: _ManagerDrawerMetric(
                          value: '${dashboard?.kpi.totalLeads ?? 9}',
                          label: 'Leads',
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _ManagerDrawerMetric(
                          value: '${dashboard?.kpi.activeProfiles ?? 18}',
                          label: 'Active',
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _ManagerDrawerMetric(
                          value: '${dashboard?.kpi.matchesToday ?? 0}',
                          label: 'Matches',
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
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  _ManagerDrawerItem(
                    label: 'Dashboard',
                    icon: Icons.space_dashboard_outlined,
                    selected: selectedIndex == 0,
                    onTap: () => selectTab(0),
                  ),
                  _ManagerDrawerItem(
                    label: 'Focus',
                    icon: Icons.center_focus_strong_outlined,
                    selected: selectedIndex == 1,
                    onTap: () => selectTab(1),
                  ),
                  _ManagerDrawerItem(
                    label: 'Bride / Groom Profile',
                    icon: Icons.filter_alt_outlined,
                    selected: selectedIndex == 2,
                    onTap: () => selectTab(2),
                  ),
                  _ManagerDrawerItem(
                    label: 'Leads',
                    icon: Icons.person_search_outlined,
                    selected: false,
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      navigator.pushNamed(AppRoutes.relationshipManagerLeads);
                    },
                  ),
                  _ManagerDrawerItem(
                    label: 'Lead Follow-ups',
                    icon: Icons.event_available_outlined,
                    selected: false,
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      navigator.pushNamed(AppRoutes.leadFollowUps);
                    },
                  ),
                  _ManagerDrawerItem(
                    label: 'Clients',
                    icon: Icons.assignment_ind_outlined,
                    selected: selectedIndex == 4,
                    onTap: () => selectTab(4),
                  ),
                  _ManagerDrawerItem(
                    label: 'Leave Management',
                    icon: Icons.calendar_today_outlined,
                    selected: false,
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      navigator.pushNamed(AppRoutes.leaves);
                    },
                  ),
                  _ManagerDrawerItem(
                    label: 'Holiday Management',
                    icon: Icons.beach_access_outlined,
                    selected: false,
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      navigator.pushNamed(AppRoutes.holidayManagement);
                    },
                  ),
                  _ManagerDrawerItem(
                    label: 'AI Matching',
                    icon: Icons.auto_awesome_outlined,
                    selected: false,
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      navigator.pushNamed(AppRoutes.aiMatching);
                    },
                  ),
                  _ManagerDrawerItem(
                    label: 'Chat',
                    icon: Icons.chat_bubble_outline,
                    selected: selectedIndex == 3,
                    onTap: () => selectTab(3),
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
                            'Dashboard menu ready',
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

class _ManagerDrawerMetric extends StatelessWidget {
  const _ManagerDrawerMetric({required this.value, required this.label});

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

class _ManagerDrawerItem extends StatelessWidget {
  const _ManagerDrawerItem({
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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _BottomNavItem(
              label: 'DASHBOARD',
              icon: Icons.space_dashboard_outlined,
              iconAsset: 'assets/icon/dashbaord_icon.png',
              selected: selectedIndex == 0,
              maroon: maroon,
              onTap: () => onChanged(0),
            ),
            _BottomNavItem(
              label: 'FOCUS',
              icon: Icons.center_focus_strong_outlined,
              selected: selectedIndex == 1,
              maroon: maroon,
              onTap: () => onChanged(1),
            ),
            _BottomNavItem(
              label: 'REGISTRY',
              icon: Icons.filter_alt_outlined,
              selected: selectedIndex == 2,
              maroon: maroon,
              onTap: () => onChanged(2),
            ),
            _BottomNavItem(
              label: 'CHAT',
              icon: Icons.chat_bubble_outline,
              selected: selectedIndex == 3,
              maroon: maroon,
              onTap: () => onChanged(3),
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
    final Color inactive = const Color(0xFFB7B7B7);
    final Color selectedBackground = const Color(0xFFF5DDE7);
    final Color selectedColor = AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? selectedBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconAsset != null)
              Image.asset(
                iconAsset!,
                width: 18.sp,
                height: 18.sp,
                color: selected ? selectedColor : inactive,
              )
            else
              Icon(
                icon,
                size: 18.sp,
                color: selected ? selectedColor : inactive,
              ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w900,
                color: selected ? selectedColor : inactive,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadCardsPanel extends StatelessWidget {
  const _LeadCardsPanel({required this.maroon, required this.dashboard});

  final Color maroon;
  final ManagerDashboard? dashboard;

  @override
  Widget build(BuildContext context) {
    final recentProfiles = dashboard?.recentProfiles ?? const [];
    final totalLeads = dashboard?.kpi.totalLeads ?? 42;
    final visibleProfiles = recentProfiles.take(4).toList();
    final hasLiveData = dashboard != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: _dashboardCardDecoration(radius: 10),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 22.sp, color: Color(0xFF202328)),
                    SizedBox(width: 12),
                    Text(
                      'Search leads by nam....',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              height: 50,
              width: 50,
              decoration: _dashboardCardDecoration(radius: 10),
              child: const Icon(
                Icons.filter_list,
                color: Color(0xFF444B57),
                size: 24,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (hasLiveData && visibleProfiles.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: _dashboardCardDecoration(radius: 12),
            child: Text(
              'No recent profiles available in the selected period.',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.rmBodyText,
              ),
            ),
          )
        else
          Column(
            children: [
              if (visibleProfiles.isEmpty) ...[
                const _LeadCardItem(),
                SizedBox(height: 10.h),
                const _LeadCardItem(),
                SizedBox(height: 10.h),
                const _LeadCardItem(),
                SizedBox(height: 10.h),
                const _LeadCardItem(),
              ] else ...[
                for (
                  var index = 0;
                  index < visibleProfiles.length;
                  index++
                ) ...[
                  if (index > 0) SizedBox(height: 10.h),
                  _LeadCardItem(profile: visibleProfiles[index]),
                ],
              ],
            ],
          ),
        SizedBox(height: 12.h),
        Center(
          child: Text(
            hasLiveData
                ? visibleProfiles.isEmpty
                      ? 'No assigned leads available'
                      : 'Displaying queue 1-${visibleProfiles.length} of $totalLeads assigned leads'
                : 'Displaying queue 1-15 of 42 assigned leads',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1F1F),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: maroon,
                  side: BorderSide(color: maroon.withValues(alpha: 0.55)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15.sp,
                  ),
                ),
                onPressed: () {},
                child: const Text(
                  'Previous\nSequence',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: maroon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15.sp,
                  ),
                ),
                onPressed: () {},
                child: const Text('Next Segment'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LeadCardItem extends StatelessWidget {
  const _LeadCardItem({this.profile});

  final ManagerRecentProfileItem? profile;

  @override
  Widget build(BuildContext context) {
    const Color maroon = AppColors.primary;
    final currentProfile = profile;
    final status = currentProfile?.status ?? 'AWAITING_RESPONSE';
    final statusPalette = _profileStatusPalette(status);
    final hasImage =
        currentProfile?.image != null && currentProfile!.image!.isNotEmpty;
    final sourceText = currentProfile == null
        ? 'Direct Registration'
        : _formatDashboardLabel(currentProfile.source);
    final priorityStars = currentProfile == null
        ? 2
        : currentProfile.verified
        ? 3
        : 2;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _dashboardCardDecoration(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey.withValues(alpha: 0.15),
                backgroundImage: hasImage
                    ? NetworkImage(currentProfile.image!)
                    : null,
                child: hasImage
                    ? null
                    : Text(
                        currentProfile?.initials ?? 'AR',
                        style: TextStyle(
                          color: const Color(0xFF24262A),
                          fontWeight: FontWeight.w900,
                          fontSize: 16.sp,
                        ),
                      ),
              ),
              SizedBox(width: 10.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentProfile?.name ?? 'Aarav Reddy',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.50,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      currentProfile == null
                          ? 'Mumbai, 29, Software Engineer'
                          : _buildRecentProfileSubtitle(currentProfile),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF181C1F),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 30.h,
                width: 30.w,
                child: Image.asset("assets/right_icon.png"),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusPalette.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              currentProfile == null
                  ? 'AWAITING RESPONSE'
                  : _formatDashboardLabel(status),
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w900,
                color: statusPalette.text,
                letterSpacing: 0.2,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _LeadMetaTitle('PRIORITY'),
                    const SizedBox(height: 4),
                    _StarsRow(filledCount: priorityStars),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const _LeadMetaTitle('SOURCE', alignEnd: true),
                    const SizedBox(height: 4),
                    Text(
                      sourceText.isEmpty ? 'Unknown' : sourceText,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.remove_red_eye_outlined,
                size: 18,
                color: maroon.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.phone_outlined,
                size: 18,
                color: maroon.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.more_horiz,
                size: 18,
                color: maroon.withValues(alpha: 0.9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeadMetaTitle extends StatelessWidget {
  const _LeadMetaTitle(this.text, {this.alignEnd = false});

  final String text;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF1E1F1F),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _StarsRow extends StatelessWidget {
  const _StarsRow({this.filledCount = 2});

  final int filledCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.only(right: index == 2 ? 0 : 2),
          child: Icon(
            index < filledCount ? Icons.star : Icons.star_border,
            size: 16,
            color: const Color(0xFFFFC107),
          ),
        );
      }),
    );
  }
}

class _ScreenshotAssetsPanel extends StatelessWidget {
  const _ScreenshotAssetsPanel({required this.maroon, required this.dashboard});

  final Color maroon;
  final ManagerDashboard? dashboard;

  @override
  Widget build(BuildContext context) {
    final hasLiveData = dashboard != null;
    final successRate = dashboard == null
        ? 82
        : dashboard!.agencyPerformance.overallConversionRate > 0
        ? dashboard!.agencyPerformance.overallConversionRate
        : dashboard!.aiPanel.successRate;
    final taskCards = _buildDashboardTaskCards(dashboard);
    final score = dashboard?.aiPanel.score;
    final scoreSummary = dashboard == null
        ? 'Performance\nsummary across all\nactive profiles.'
        : '${dashboard!.agencyPerformance.closedClients} closed clients\n${dashboard!.agencyPerformance.taskCompletionRate}% task completion\nacross the agency.';
    final recentActivities = dashboard == null
        ? const <ManagerRecentActivityItem>[]
        : dashboard!.recentActivity.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.55),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MaroonSection(
                icon: Icons.trending_up,
                title: 'Success Rate',
                child: _SuccessRateBlock(
                  value: successRate,
                  description:
                      'of agency conversions closed in the selected period.',
                ),
              ),
              SizedBox(height: 14.h),
              _MaroonSection(
                icon: Icons.access_time_rounded,
                title: 'Tasks to Do',
                child: _TasksToDoBlock(cards: taskCards),
              ),
              SizedBox(height: 14.h),
              _MaroonSection(
                icon: Icons.workspace_premium_outlined,
                title: 'Score',
                child: _ScoreBlock(
                  score: score?.isNotEmpty == true ? score! : 'A+',
                  summary: scoreSummary,
                ),
              ),
              SizedBox(height: 14.h),
              _MaroonSection(
                icon: Icons.notifications_none,
                title: 'Suggested Matches',
                child: _SuggestedMatchesBlock(
                  matches: dashboard?.aiPanel.suggestedMatches ?? const [],
                  hasLiveData: hasLiveData,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          decoration: _dashboardCardDecoration(radius: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  color: Color(0xFF181C1F),
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.60,
                ),
              ),
              SizedBox(height: 12.h),
              const Divider(color: Color(0xFFE7EAF0), height: 1),
              SizedBox(height: 16.h),
              if (hasLiveData && recentActivities.isEmpty)
                Text(
                  'No recent activity available for the selected period.',
                  style: TextStyle(
                    color: AppColors.rmBodyText,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else if (recentActivities.isEmpty) ...[
                _ActivityRow(
                  icon: Icons.call_outlined,
                  title: 'Call with Anjali Sharma',
                  subtitle: 'Today, 10:30 AM - Assessed preferences',
                  maroon: maroon,
                ),
                SizedBox(height: 14.h),
                _ActivityRow(
                  icon: Icons.person_search_outlined,
                  title: 'Profile Approved: Rahul V.',
                  subtitle: 'Yesterday, 4:15 PM - Ready for matching',
                  maroon: maroon,
                ),
                SizedBox(height: 14.h),
                _ActivityRow(
                  icon: Icons.handshake_outlined,
                  title: 'Match Shared: P. Gupta & S. Roy',
                  subtitle: 'Yesterday, 1:00 PM - Awaiting mutual consent',
                  maroon: maroon,
                  isLast: true,
                ),
              ] else ...[
                for (
                  var index = 0;
                  index < recentActivities.length;
                  index++
                ) ...[
                  _ActivityRow(
                    icon: _activityIconForItem(recentActivities[index]),
                    title: recentActivities[index].title,
                    subtitle: recentActivities[index].description.isNotEmpty
                        ? recentActivities[index].description
                        : _formatDashboardLabel(recentActivities[index].action),
                    maroon: maroon,
                    isLast: index == recentActivities.length - 1,
                  ),
                  if (index != recentActivities.length - 1)
                    SizedBox(height: 14.h),
                ],
              ],
              SizedBox(height: 18.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: maroon,
                    side: BorderSide(color: maroon),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16.sp,
                    ),
                  ),
                  onPressed: () {},
                  child: const Text('View All Activity'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MaroonSection extends StatelessWidget {
  const _MaroonSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18.sp,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22.sp,
                fontWeight: FontWeight.w600,
                height: 1.87,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: ShapeDecoration(
            gradient: LinearGradient(
              begin: Alignment(0.00, 0.00),
              end: Alignment(1.00, 1.00),
              colors: [
                Colors.white.withValues(alpha: 0.16),
                Colors.white.withValues(alpha: 0.07),
              ],
            ),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                strokeAlign: BorderSide.strokeAlignCenter,
                color: Colors.white.withValues(alpha: 0.14),
              ),
              borderRadius: BorderRadius.circular(14),
              // border: Border.all(color: const Color(0xFFD84E91), width: 1),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _SuccessRateBlock extends StatelessWidget {
  const _SuccessRateBlock({required this.value, required this.description});

  final int value;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 4.h),
        Text(
          '$value%',
          style: TextStyle(
            fontSize: 80.sp,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
            height: 1.50,
          ),
        ),
      ],
    );
  }
}

class _TasksToDoBlock extends StatelessWidget {
  const _TasksToDoBlock({required this.cards});

  final List<_DashboardTaskCardData> cards;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < cards.length; index++) ...[
          _TaskItem(
            title: cards[index].title,
            badge: cards[index].badge,
            badgeColor: cards[index].badgeColor,
            textColor: cards[index].textColor,
          ),
          if (index != cards.length - 1) SizedBox(height: 10.h),
        ],
      ],
    );
  }
}

class _TaskItem extends StatelessWidget {
  const _TaskItem({
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.textColor,
  });

  final String title;
  final String badge;
  final Color badgeColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(0.00, 0.00),
          end: const Alignment(1.00, 1.00),
          colors: [
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBlock extends StatelessWidget {
  const _ScoreBlock({required this.score, required this.summary});

  final String score;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 92,
          height: 75,
          padding: const EdgeInsets.all(12),
          decoration: ShapeDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1.80,
                strokeAlign: BorderSide.strokeAlignCenter,
                color: const Color(0xFFD89F74),
              ),
              borderRadius: BorderRadius.circular(9),
            ),
          ),

          child: Center(
            child: Text(
              score,
              style: TextStyle(
                color: Color(0xFFFFE57A),
                fontSize: 35.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            summary,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.90),
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _SuggestedMatchesBlock extends StatelessWidget {
  const _SuggestedMatchesBlock({
    required this.matches,
    required this.hasLiveData,
  });

  final List<ManagerSuggestedMatchItem> matches;
  final bool hasLiveData;

  @override
  Widget build(BuildContext context) {
    final visibleMatches = matches.take(2).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(0.00, 0.00),
          end: const Alignment(1.00, 1.00),
          colors: [
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: hasLiveData && visibleMatches.isEmpty
          ? Text(
              'No suggested matches yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            )
          : Column(
              children: visibleMatches.isEmpty
                  ? [
                      _MiniPeopleRow(
                        leftName: 'Aarav M',
                        rightName: 'Kiara S.',
                        match: '93%',
                        leftSubtitle: 'Tier 1 City',
                        rightSubtitle: 'Tier 1 City',
                      ),
                      SizedBox(height: 10.h),
                      _MiniPeopleRow(
                        leftName: 'Aarav M',
                        rightName: 'Kiara S.',
                        match: '93%',
                        leftSubtitle: 'Tier 1 City',
                        rightSubtitle: 'Tier 1 City',
                      ),
                    ]
                  : [
                      for (
                        var index = 0;
                        index < visibleMatches.length;
                        index++
                      ) ...[
                        if (index > 0) SizedBox(height: 10.h),
                        _MiniPeopleRow(
                          leftName: visibleMatches[index].leftName,
                          rightName: visibleMatches[index].rightName,
                          match: visibleMatches[index].match,
                          leftSubtitle: visibleMatches[index].leftSubtitle,
                          rightSubtitle: visibleMatches[index].rightSubtitle,
                        ),
                      ],
                    ],
            ),
    );
  }
}

class _MiniPeopleRow extends StatelessWidget {
  const _MiniPeopleRow({
    required this.leftName,
    required this.rightName,
    required this.match,
    required this.leftSubtitle,
    required this.rightSubtitle,
  });

  final String leftName;
  final String rightName;
  final String match;
  final String leftSubtitle;
  final String rightSubtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _MiniPersonCard(name: leftName, subtitle: leftSubtitle),
        _MatchBadge(match: match),
        _MiniPersonCard(name: rightName, subtitle: rightSubtitle),
      ],
    );
  }
}

class _MiniPersonCard extends StatelessWidget {
  const _MiniPersonCard({required this.name, required this.subtitle});

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final Color maroon = AppColors.primary;
    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFF7D8E8),
          child: Icon(Icons.person, size: 20.sp, color: maroon),
        ),
        SizedBox(height: 5.h),
        Text(
          name,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          subtitle.isEmpty ? 'Suggested' : subtitle,
          style: TextStyle(
            fontSize: 9.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.match});

  final String match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, size: 14.sp, color: const Color(0xFFBD1E59)),
          const SizedBox(width: 6),
          Text(
            match,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: Color(0xFFBD1E59),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.maroon,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color maroon;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34.w,
          child: Column(
            children: [
              Container(
                height: 44.h,
                width: 44.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFCDD5E1)),
                ),
                child: Icon(icon, size: 24.sp, color: const Color(0xFF2A2F36)),
              ),
              if (!isLast)
                Container(
                  width: 1.2,
                  height: 30,
                  color: const Color(0xFFE1E6EF),
                ),
            ],
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF181C1F),
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.50,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: const Color(0xFF564146),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.maroon});

  final Color maroon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6C2CE), width: 1.4),
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          Icon(Icons.search, color: const Color(0xFF5F4A50), size: 34.sp),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Search profiles, IDs...',
              style: TextStyle(
                color: const Color(0xFF70758B),
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardFilterOption extends StatelessWidget {
  const _DashboardFilterOption({
    required this.label,
    required this.selected,
    required this.maroon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color maroon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? maroon.withValues(alpha: 0.08) : AppColors.white,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: selected ? maroon : AppColors.rmPaleRoseBorder,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: selected ? maroon : AppColors.rmHeading,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: maroon, size: 20.sp),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.icon,
    this.imageAsset,
    required this.maroon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String? imageAsset;
  final Color maroon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = filled ? maroon : Colors.white;
    final foreground = filled ? Colors.white : maroon;
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
        height: 52.h,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: filled ? maroon : AppColors.primary,
            width: 1.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            imageAsset != null
                ? Image.asset(
                    imageAsset!,
                    width: 20.sp,
                    height: 20.sp,
                    color: foreground,
                  )
                : Icon(icon, size: 24.sp, color: foreground),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.maroon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color maroon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(7627.81),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? maroon : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? maroon : const Color(0x334D4D4D),
            width: 0.76,
          ),
        ),

        alignment: Alignment.center,

        child: Text(
          label,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF181C1F),
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            height: 1.27,
          ),
        ),
      ),
    );
  }
}

class _StatItem {
  const _StatItem(this.label, this.value);

  final String label;
  final String value;
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.maroon, required this.items});

  final Color maroon;
  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _dashboardCardDecoration(radius: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.dashbaordcardtext,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 5.h),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 28.sp,
                  color: maroon,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FunnelCard extends StatelessWidget {
  const _FunnelCard({
    required this.maroon,
    required this.title,
    required this.count,
    required this.progress,
  });

  final Color maroon;
  final String title;
  final int count;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _dashboardCardDecoration(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: const Color(0xFF181C1F),
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
              height: 1.87,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'PROFILES',
                style: TextStyle(
                  fontSize: 14.sp,
                  letterSpacing: 0.8,
                  color: const Color(0xFF1E1F1F),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 6,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgentFocusCard extends StatelessWidget {
  const _UrgentFocusCard({required this.maroon, required this.dashboard});

  final Color maroon;
  final ManagerDashboard? dashboard;

  @override
  Widget build(BuildContext context) {
    final overdueFollowUps =
        dashboard?.followUpControl.fold<int>(
          0,
          (total, item) => total + item.overdueFollowUps,
        ) ??
        3;
    final pendingReplies = dashboard?.urgent.pendingReplies ?? 5;
    final unassignedLeads = dashboard?.urgent.unassignedLeads ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
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
                width: 30.h,
                child: Image.asset('assets/Triangle_Warning.png'),
              ),
              const SizedBox(width: 8),
              Text(
                'Urgent Focus',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.71,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _UrgentRow(
            maroon: maroon,
            title: '$overdueFollowUps overdue follow-ups',
            subtitle: overdueFollowUps > 0
                ? 'Requires immediate action'
                : 'No overdue follow-ups right now',
            actionLabel: 'Call',
            actionIcon: Icons.call,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _UrgentRow(
            maroon: maroon,
            title: pendingReplies > 0
                ? '$pendingReplies pending client replies'
                : '$unassignedLeads unassigned leads',
            subtitle: pendingReplies > 0
                ? 'Waiting on feedback'
                : unassignedLeads > 0
                ? 'Needs assignment'
                : 'Reply queue is clear',
            actionLabel: 'Assign',
            actionIcon: Icons.assignment_ind_outlined,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _UrgentRow extends StatelessWidget {
  const _UrgentRow({
    required this.maroon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.actionIcon,
    required this.onTap,
  });

  final Color maroon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: maroon.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF181C1F),
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: const Color(0xFF727785),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: maroon.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(actionIcon, size: 14.sp, color: maroon),
                  SizedBox(width: 6.w),
                  Text(
                    actionLabel,
                    style: TextStyle(
                      color: maroon,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
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

class _LeadFollowUpsPanel extends StatelessWidget {
  const _LeadFollowUpsPanel({required this.maroon});

  final Color maroon;

  @override
  Widget build(BuildContext context) {
    final followUpProvider = context.watch<LeadFollowUpProvider>();
    final followUps = followUpProvider.followUps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lead Follow-ups',
          style: GoogleFonts.inter(
            color: const Color(0xFF181C1F),
            fontSize: 24.sp,
            fontWeight: FontWeight.w600,
            height: 1.60,
          ),
        ),
        SizedBox(height: 12.h),
        if (followUpProvider.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (followUpProvider.error != null)
          Text(
            followUpProvider.error!,
            style: const TextStyle(color: Colors.red),
          )
        else if (followUps.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: _dashboardCardDecoration(radius: 12),
            child: const Text('No pending follow-ups.'),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: followUps.length,
            separatorBuilder: (context, index) => SizedBox(height: 10.h),
            itemBuilder: (context, index) {
              return _FollowUpItem(task: followUps[index], maroon: maroon);
            },
          ),
      ],
    );
  }
}

class _FollowUpItem extends StatelessWidget {
  const _FollowUpItem({required this.task, required this.maroon});

  final WorkflowTask task;
  final Color maroon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.leadFollowUps);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _dashboardCardDecoration(radius: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.rmSoftPink,
                  backgroundImage: task.subjectDisplay.profileImageUrl != null
                      ? NetworkImage(task.subjectDisplay.profileImageUrl!)
                      : null,
                  child: task.subjectDisplay.profileImageUrl == null
                      ? Text(
                          task.displayTitle.isNotEmpty
                              ? task.displayTitle[0].toUpperCase()
                              : 'L',
                          style: TextStyle(
                            color: maroon,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.displayTitle,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF181C1F),
                        ),
                      ),
                      Text(
                        task.displayReason,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(0xFF1E1F1F),
                        ),
                      ),
                    ],
                  ),
                ),
                _PriorityBadge(priority: task.priority),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              task.displaySummary,
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF444B57)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Color(0xFF1E1F1F),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _formatDate(task.dueAt),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF1E1F1F),
                      ),
                    ),
                  ],
                ),
                Text(
                  task.workflowStatus,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: maroon,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority.toUpperCase()) {
      case 'HIGH':
        color = Colors.red;
        break;
      case 'MEDIUM':
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
