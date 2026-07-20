import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/owner/Screen/admin_drawer_screen.dart';
import 'package:koniwalamatrimonial/owner/Screen/admin_settings_screen.dart';
import 'package:koniwalamatrimonial/owner/Screen/leads_registry_screen.dart';
import 'package:koniwalamatrimonial/owner/Screen/registry_screen.dart';
import 'package:koniwalamatrimonial/owner/providers/dashboard_provider.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/providers/navigation_provider.dart';
import 'package:koniwalamatrimonial/rm/models/rm_lead_item.dart';
import 'package:koniwalamatrimonial/rm/models/whatsapp_models.dart';
import 'package:koniwalamatrimonial/rm/providers/whatsapp_provider.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:provider/provider.dart';

enum WhatsappInboxFilter { all, unread, mine, archived }

enum _LeadDetailTab { overview, notes, conversation, resumes, history }

class WhatsappInboxScreen extends StatefulWidget {
  const WhatsappInboxScreen({super.key});

  @override
  State<WhatsappInboxScreen> createState() => _WhatsappInboxScreenState();
}

class _WhatsappInboxScreenState extends State<WhatsappInboxScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  Timer? _pollTimer;
  WhatsappInboxFilter _filter = WhatsappInboxFilter.all;
  bool _requestedInitialLoad = false;
  String? _requestedAccessToken;
  int _selectedBottomIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    final accessToken = auth.userModel?.accessToken;
    if (!auth.isInitialized ||
        (_requestedInitialLoad && accessToken == _requestedAccessToken)) {
      return;
    }

    _requestedInitialLoad = true;
    _requestedAccessToken = accessToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<WhatsappProvider>().initialize(accessToken);
      _startPolling();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _pollTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  bool _isRelationshipManagerRole(String? role) {
    final normalizedRole = role?.trim().toUpperCase() ?? '';
    return normalizedRole == 'RELATIONSHIP_MANAGER' || normalizedRole == 'RM';
  }

  void _openDashboardTab(int dashboardTabIndex) {
    final role = context.read<AuthProvider>().userModel?.user?.role;
    final navigator = Navigator.of(context);

    if (_isRelationshipManagerRole(role)) {
      switch (dashboardTabIndex) {
        case 0:
        case 1:
        case 5:
          context.read<NavigationProvider>().setIndex(
            dashboardTabIndex == 5 ? 2 : dashboardTabIndex,
          );
          navigator.pushReplacementNamed(
            AppRoutes.relationshipManagerDashboard,
          );
          return;
        case 2:
          navigator.pushReplacementNamed(AppRoutes.relationshipManagerLeads);
          return;
        case 3:
          navigator.pushReplacementNamed(AppRoutes.clientRegistry);
          return;
        default:
          context.read<NavigationProvider>().setIndex(0);
          navigator.pushReplacementNamed(
            AppRoutes.relationshipManagerDashboard,
          );
          return;
      }
    }

    context.read<DashboardProvider>().selectTab(dashboardTabIndex);
    navigator.pushReplacementNamed(AppRoutes.ownerDashboard);
  }

  void _openDashboardFromDrawer(int dashboardTabIndex) {
    Navigator.of(context).maybePop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _openDashboardTab(dashboardTabIndex);
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || _selectedBottomIndex != 0) {
        return;
      }
      _fetch(forceRefresh: true);
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels > position.maxScrollExtent - 220) {
      context.read<WhatsappProvider>().loadMoreConversations();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      _fetch(forceRefresh: true);
    });
  }

  Future<void> _showStartChatDialog() async {
    final conversation = await showDialog<WhatsappConversation>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _StartWhatsappChatDialog(),
    );
    if (!mounted || conversation == null) {
      return;
    }
    Navigator.of(context).pushNamed(
      AppRoutes.whatsappConversation,
      arguments: WhatsappConversationLaunch(conversation: conversation),
    );
  }

  Future<void> _fetch({bool forceRefresh = false}) {
    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    return context.read<WhatsappProvider>().fetchConversations(
      accessToken: accessToken,
      search: _searchController.text.trim(),
      includeArchived: _filter == WhatsappInboxFilter.archived,
      forceRefresh: forceRefresh,
    );
  }

  void _selectBottomTab(int index) {
    if (_selectedBottomIndex == index) {
      return;
    }
    setState(() => _selectedBottomIndex = index);
    if (index == 0) {
      _fetch(forceRefresh: true);
    }
  }

  List<WhatsappConversation> _visibleConversations({
    required List<WhatsappConversation> conversations,
    required String? userId,
  }) {
    switch (_filter) {
      case WhatsappInboxFilter.unread:
        return conversations
            .where((conversation) => conversation.unreadCount > 0)
            .toList();
      case WhatsappInboxFilter.mine:
        if (userId == null || userId.isEmpty) {
          return conversations;
        }
        return conversations
            .where((conversation) => conversation.assignedToId == userId)
            .toList();
      case WhatsappInboxFilter.archived:
        return conversations;
      case WhatsappInboxFilter.all:
        return conversations
            .where((conversation) => !conversation.archived)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<WhatsappProvider>();
    final status = provider.status;
    final conversations = _visibleConversations(
      conversations: provider.conversations,
      userId: auth.userModel?.user?.id,
    );
    final isRelationshipManager = _isRelationshipManagerRole(
      auth.userModel?.user?.role,
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: Drawer(
        width: MediaQuery.sizeOf(context).width * 0.72,
        backgroundColor: AppColors.rmSoftPink,
        child: AdminDrawerContent(
          activeRoute: AppRoutes.whatsappInbox,
          onClose: () => Navigator.of(context).maybePop(),
          onSelectDashboardTab: _openDashboardFromDrawer,
        ),
      ),
      bottomNavigationBar: isRelationshipManager
          ? _RmWhatsappBottomNav(
              onDashboard: () => _openDashboardTab(0),
              onMatches: () => _openDashboardTab(1),
              onAccount: () => _openDashboardTab(5),
            )
          : _WhatsappBottomNav(
              selected: _selectedBottomIndex,
              onInbox: () => _selectBottomTab(0),
              onLeads: () => _selectBottomTab(1),
              onMatches: () => _selectBottomTab(2),
              onSettings: () => _selectBottomTab(3),
            ),
      body: SafeArea(
        child: isRelationshipManager || _selectedBottomIndex == 0
            ? _buildInboxBody(auth, provider, status, conversations)
            : _WhatsappEmbeddedTab(
                selectedIndex: _selectedBottomIndex,
                onMenuPressed: _openDrawer,
              ),
      ),
    );
  }

  Widget _buildInboxBody(
    AuthProvider auth,
    WhatsappProvider provider,
    WhatsappApiStatus? status,
    List<WhatsappConversation> conversations,
  ) {
    return RefreshIndicator(
      color: AppColors.rmPrimary,
      onRefresh: () => _fetch(forceRefresh: true),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InboxHeader(onMenuTap: _openDrawer, onSearchTap: () {}),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0),
                  child: _BusinessAccountCard(status: status),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ConversationSearchField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      _StartChatButton(onTap: _showStartChatDialog),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: WhatsappInboxFilter.values.map((filter) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: _FilterChip(
                          label: _filterLabel(filter),
                          selected: _filter == filter,
                          onTap: () {
                            setState(() => _filter = filter);
                            _fetch(forceRefresh: true);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 22.h),
              ],
            ),
          ),
          if (provider.isLoadingConversations && conversations.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _InboxStateMessage(
                icon: Icons.forum_outlined,
                message: 'Loading WhatsApp conversations...',
                showLoader: true,
              ),
            )
          else if (provider.error != null && conversations.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _InboxStateMessage(
                icon: Icons.error_outline,
                message: provider.error!,
                actionLabel: 'Retry',
                onActionPressed: () => _fetch(forceRefresh: true),
              ),
            )
          else if (conversations.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _InboxStateMessage(
                icon: Icons.chat_bubble_outline,
                message: _searchController.text.trim().isEmpty
                    ? 'No WhatsApp conversations found.'
                    : 'No matching conversations found.',
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 18.h),
              sliver: SliverList.separated(
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  return _ConversationTile(
                    conversation: conversation,
                    highlighted: index == 0,
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.whatsappConversation,
                      arguments: conversation,
                    ),
                  );
                },
                separatorBuilder: (_, _) => SizedBox(height: 10.h),
                itemCount: conversations.length,
              ),
            ),
          if (provider.isLoadingMoreConversations)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 18.h),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.rmPrimary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _filterLabel(WhatsappInboxFilter filter) {
    switch (filter) {
      case WhatsappInboxFilter.all:
        return 'All';
      case WhatsappInboxFilter.unread:
        return 'Unread';
      case WhatsappInboxFilter.mine:
        return 'Mine';
      case WhatsappInboxFilter.archived:
        return 'Archived';
    }
  }
}

class _WhatsappEmbeddedTab extends StatelessWidget {
  const _WhatsappEmbeddedTab({
    required this.selectedIndex,
    required this.onMenuPressed,
  });

  final int selectedIndex;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    switch (selectedIndex) {
      case 1:
        return LeadsRegistryScreen(onMenuPressed: onMenuPressed);
      case 2:
        return RegistryScreen(
          showScaffold: false,
          showEmbeddedAppBar: true,
          onMenuPressed: onMenuPressed,
        );
      case 3:
        return const AdminSettingsScreen();
      default:
        return const SizedBox.shrink();
    }
  }
}

class WhatsappLeadDetailsScreen extends StatefulWidget {
  const WhatsappLeadDetailsScreen({super.key, required this.conversation});

  final WhatsappConversation conversation;

  @override
  State<WhatsappLeadDetailsScreen> createState() =>
      _WhatsappLeadDetailsScreenState();
}

class _WhatsappLeadDetailsScreenState extends State<WhatsappLeadDetailsScreen> {
  bool _requestedLead = false;
  String? _requestedAccessToken;
  final TextEditingController _commentController = TextEditingController();
  _LeadDetailTab _selectedTab = _LeadDetailTab.overview;

  WhatsappConversation get conversation => widget.conversation;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final accessToken = context.watch<AuthProvider>().userModel?.accessToken;
    if (_requestedLead && accessToken == _requestedAccessToken) {
      return;
    }

    _requestedLead = true;
    _requestedAccessToken = accessToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<WhatsappProvider>().fetchLeadDetail(
        accessToken: accessToken,
        conversation: conversation,
      );
    });
  }

  void _retryLeadDetail() {
    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    context.read<WhatsappProvider>().fetchLeadDetail(
      accessToken: accessToken,
      conversation: conversation,
      forceRefresh: true,
    );
  }

  Future<void> _addComment() async {
    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    final message = await context.read<WhatsappProvider>().addLeadComment(
      accessToken: accessToken,
      leadId: conversation.leadId,
      content: _commentController.text,
    );
    if (!mounted) {
      return;
    }
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WhatsappProvider>();
    final lead = provider.leadDetailFor(conversation.leadId);
    final isLoading = provider.isLoadingLeadDetail(conversation.leadId);
    final error = provider.leadDetailErrorFor(conversation.leadId);
    final comments = provider.commentsFor(conversation.leadId);
    final isLoadingComments = provider.isLoadingComments(conversation.leadId);
    final isAddingComment = provider.isAddingComment(conversation.leadId);
    final commentError = provider.commentErrorFor(conversation.leadId);
    final status = _leadValue(lead?.stageLabel, conversation.displayStatus);
    final source = _leadValue(lead?.sourceLabel, conversation.displaySource);
    final assignedTo = _leadValue(
      lead?.assignedToName == 'Unassigned' ? '' : lead?.assignedToName,
      conversation.assignedToName,
      fallback: '-',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F1),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  _LeadDetailsAppBar(conversation: conversation),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 30.h),
                      children: [
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: [
                            _StatusPill(
                              label: status,
                              background: const Color(0xFFE9FBE9),
                              foreground: const Color(0xFF008A2E),
                            ),
                            _StatusPill(
                              label: source,
                              background: const Color(0xFFECEFFD),
                              foreground: const Color(0xFF274B9F),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          _leadValue(lead?.name, conversation.name),
                          style: GoogleFonts.playfairDisplay(
                            color: AppColors.rmHeading,
                            fontSize: 30.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Created on ${_dateLabel(lead?.createdAt ?? conversation.createdAt)} • Currently assigned to $assignedTo.',
                          style: GoogleFonts.playfairDisplay(
                            color: AppColors.rmBodyText,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                        SizedBox(height: 22.h),
                        _LeadDetailsTabs(
                          selected: _selectedTab,
                          onSelected: (tab) => setState(() {
                            _selectedTab = tab;
                          }),
                        ),
                        if (isLoading) ...[
                          SizedBox(height: 12.h),
                          const LinearProgressIndicator(
                            color: AppColors.rmPrimary,
                            minHeight: 2,
                          ),
                        ],
                        if (error != null && lead == null) ...[
                          SizedBox(height: 14.h),
                          _LeadDetailError(
                            message: error,
                            onRetry: _retryLeadDetail,
                          ),
                        ],
                        SizedBox(height: 18.h),
                        _LeadDetailTabContent(
                          tab: _selectedTab,
                          conversation: conversation,
                          lead: lead,
                          comments: comments,
                          isLoadingComments: isLoadingComments,
                          isAddingComment: isAddingComment,
                          commentError: commentError,
                          commentController: _commentController,
                          assignedTo: assignedTo,
                          source: source,
                          status: status,
                          onAddComment: _addComment,
                          onRetryComments: () => context
                              .read<WhatsappProvider>()
                              .fetchLeadComments(
                                accessToken: context
                                    .read<AuthProvider>()
                                    .userModel
                                    ?.accessToken,
                                leadId: conversation.leadId,
                                forceRefresh: true,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeadDetailError extends StatelessWidget {
  const _LeadDetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFF4CDBB)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.rmPrimary, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: AppColors.rmBodyText,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

String _leadValue(
  String? value,
  String? fallbackValue, {
  String fallback = '-',
}) {
  final primary = _cleanLeadValue(value);
  if (primary.isNotEmpty) {
    return primary;
  }
  final secondary = _cleanLeadValue(fallbackValue);
  return secondary.isEmpty ? fallback : secondary;
}

String _cleanLeadValue(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty ||
      text == '-' ||
      text.toLowerCase() == 'unknown city' ||
      text.toLowerCase() == 'unknown') {
    return '';
  }
  return text;
}

class _InboxHeader extends StatelessWidget {
  const _InboxHeader({required this.onMenuTap, required this.onSearchTap});

  final VoidCallback onMenuTap;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF7F1),
        border: Border(bottom: BorderSide(color: Color(0xFFF4E8E1))),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Menu',
            onPressed: onMenuTap,
            icon: Icon(
              Icons.menu_rounded,
              color: AppColors.rmPrimary,
              size: 25.sp,
            ),
          ),
          SizedBox(width: 2.w),
          Image.asset(
            'assets/app.logo.png',
            width: 108.w,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Search',
            onPressed: onSearchTap,
            icon: Icon(
              Icons.search_rounded,
              color: AppColors.rmPrimary,
              size: 25.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessAccountCard extends StatelessWidget {
  const _BusinessAccountCard({required this.status});

  final WhatsappApiStatus? status;

  @override
  Widget build(BuildContext context) {
    final configured = status?.configured ?? false;
    final phone = status?.phone ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 13.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDFD),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFF6CBB8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status?.displayName ?? 'Koniwala Matrimonials',
            style: GoogleFonts.playfairDisplay(
              color: AppColors.rmHeading,
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: AppColors.rmBodyText,
                size: 15.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'WhatsApp Business Account',
                  style: GoogleFonts.inter(
                    color: AppColors.rmBodyText,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 8.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 205.w),
                child: Text(
                  phone.isEmpty ? 'No business phone returned' : phone,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.rmBodyText,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999.r),
                  color: configured
                      ? AppColors.successContainer
                      : AppColors.dangerContainer,
                  border: Border.all(
                    color: configured ? AppColors.success : AppColors.danger,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5.r,
                      height: 5.r,
                      decoration: BoxDecoration(
                        color: configured
                            ? AppColors.success
                            : AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      configured ? 'Configured' : 'Unavailable',
                      style: GoogleFonts.inter(
                        color: configured
                            ? AppColors.success
                            : AppColors.danger,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConversationSearchField extends StatelessWidget {
  const _ConversationSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search conversations',
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.rmBodyText),
        hintStyle: GoogleFonts.inter(
          color: AppColors.rmBodyText,
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 13.h),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.r),
          borderSide: const BorderSide(color: Color(0xFF8C8C8C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.r),
          borderSide: const BorderSide(color: AppColors.rmPrimary, width: 1.2),
        ),
      ),
    );
  }
}

class _StartChatButton extends StatelessWidget {
  const _StartChatButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Start WhatsApp chat',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          width: 50.r,
          height: 50.r,
          decoration: BoxDecoration(
            color: AppColors.rmPrimary,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(
            Icons.add_comment_outlined,
            color: Colors.white,
            size: 22.sp,
          ),
        ),
      ),
    );
  }
}

class _StartWhatsappChatDialog extends StatefulWidget {
  const _StartWhatsappChatDialog();

  @override
  State<_StartWhatsappChatDialog> createState() =>
      _StartWhatsappChatDialogState();
}

class _StartWhatsappChatDialogState extends State<_StartWhatsappChatDialog> {
  final _formKey = GlobalKey<FormState>();
  final _countryController = TextEditingController(text: '+91');
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _countryController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final accessToken = context.read<AuthProvider>().userModel?.accessToken;
      final conversation = await context.read<WhatsappProvider>().startChat(
        accessToken: accessToken,
        countryCode: _countryController.text,
        phone: _phoneController.text,
        name: _nameController.text,
      );
      if (!mounted) {
        return;
      }
      if (conversation == null) {
        _showMessage('Unable to start WhatsApp chat.');
        return;
      }
      Navigator.of(context).pop(conversation);
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
  }

  String? _countryValidator(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return 'Required';
    }
    if (digits.length > 4) {
      return 'Invalid';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return 'Enter valid number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 24.h),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 440.w),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22.r),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 18.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Start WhatsApp chat',
                          style: GoogleFonts.playfairDisplay(
                            color: AppColors.rmHeading,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).maybePop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.rmBodyText,
                          size: 22.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Enter a mobile number to open an existing lead conversation or create a new WhatsApp lead.',
                    style: GoogleFonts.inter(
                      color: AppColors.rmBodyText,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: 22.h),
                  Text(
                    'WhatsApp number',
                    style: GoogleFonts.inter(
                      color: AppColors.rmHeading,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 92.w,
                        child: _StartChatTextField(
                          controller: _countryController,
                          hintText: '+91',
                          keyboardType: TextInputType.phone,
                          validator: _countryValidator,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9+]'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _StartChatTextField(
                          controller: _phoneController,
                          hintText: '98765 43210',
                          keyboardType: TextInputType.phone,
                          validator: _phoneValidator,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9 ]'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Country code is required and will be used when sending through WhatsApp.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Name',
                    style: GoogleFonts.inter(
                      color: AppColors.rmHeading,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _StartChatTextField(
                    controller: _nameController,
                    hintText: 'Optional',
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: const Color(0xFFFAD7B7)),
                    ),
                    child: Text(
                      'First contact must use an approved WhatsApp template. Free-form typing unlocks for 24 hours after the customer replies.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFE14B17),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ),
                  SizedBox(height: 26.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).maybePop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.rmPrimary,
                            side: const BorderSide(color: Color(0xFFF2D7CA)),
                            minimumSize: Size(0, 44.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.rmPrimary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFE8B6A2),
                            elevation: 0,
                            minimumSize: Size(0, 44.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  width: 18.r,
                                  height: 18.r,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Open chat',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13.sp,
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
      ),
    );
  }
}

class _StartChatTextField extends StatelessWidget {
  const _StartChatTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      style: GoogleFonts.inter(
        color: AppColors.rmHeading,
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF94A3B8),
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9.r),
          borderSide: const BorderSide(color: AppColors.rmPrimary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9.r),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9.r),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
      borderRadius: BorderRadius.circular(9.r),
      child: Container(
        constraints: BoxConstraints(minWidth: 59.w),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.rmPrimary : Colors.white,
          borderRadius: BorderRadius.circular(9.r),
          border: Border.all(color: AppColors.rmPrimary.withValues(alpha: 0.7)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : AppColors.rmBodyText,
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.highlighted,
    required this.onTap,
  });

  final WhatsappConversation conversation;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2.r),
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
        decoration: BoxDecoration(
          color: highlighted ? const Color(0xFFFFFBF8) : Colors.white,
          border: highlighted
              ? Border.all(color: const Color(0xFFF8E4DA))
              : null,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            _ConversationAvatar(conversation: conversation),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.rmHeading,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.rmBodyText,
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _conversationTime(conversation.lastMessageAt),
                  style: GoogleFonts.inter(
                    color: highlighted
                        ? AppColors.rmPrimary
                        : AppColors.rmBodyText.withValues(alpha: 0.65),
                    fontSize: 11.5.sp,
                    fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                if (conversation.unreadCount > 0) ...[
                  SizedBox(height: 8.h),
                  Container(
                    constraints: BoxConstraints(minWidth: 20.r),
                    height: 20.r,
                    padding: EdgeInsets.symmetric(horizontal: 5.w),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.rmPrimary,
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Text(
                      '${conversation.unreadCount}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({required this.conversation});

  final WhatsappConversation conversation;

  @override
  Widget build(BuildContext context) {
    final resolvedAvatarUrl = _resolveAssetUrl(conversation.avatarUrl);
    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    if (resolvedAvatarUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          resolvedAvatarUrl,
          headers: _authHeadersForUrl(resolvedAvatarUrl, accessToken),
          width: 48.r,
          height: 48.r,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              _InitialsAvatar(conversation: conversation),
        ),
      );
    }
    return _InitialsAvatar(conversation: conversation);
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.conversation});

  final WhatsappConversation conversation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.r,
      height: 48.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFEFDCD4)),
      ),
      child: Text(
        conversation.initials,
        style: GoogleFonts.playfairDisplay(
          color: AppColors.rmPrimary,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InboxStateMessage extends StatelessWidget {
  const _InboxStateMessage({
    required this.icon,
    required this.message,
    this.showLoader = false,
    this.actionLabel,
    this.onActionPressed,
  });

  final IconData icon;
  final String message;
  final bool showLoader;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.rmPrimary, size: 36.sp),
            SizedBox(height: 12.h),
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
            if (showLoader) ...[
              SizedBox(height: 16.h),
              const CircularProgressIndicator(color: AppColors.rmPrimary),
            ],
            if (actionLabel != null && onActionPressed != null) ...[
              SizedBox(height: 16.h),
              OutlinedButton(
                onPressed: onActionPressed,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RmWhatsappBottomNav extends StatelessWidget {
  const _RmWhatsappBottomNav({
    required this.onDashboard,
    required this.onMatches,
    required this.onAccount,
  });

  final VoidCallback onDashboard;
  final VoidCallback onMatches;
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 16.h),
        color: AppColors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _BottomNavItem(
              icon: Icons.space_dashboard_outlined,
              label: 'Dashboard',
              selected: false,
              onTap: onDashboard,
            ),
            _BottomNavItem(
              icon: Icons.filter_alt_outlined,
              label: 'Matches',
              selected: false,
              onTap: onMatches,
            ),
            _BottomNavItem(
              icon: Icons.person_outline,
              label: 'Account',
              selected: false,
              onTap: onAccount,
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsappBottomNav extends StatelessWidget {
  const _WhatsappBottomNav({
    required this.selected,
    required this.onInbox,
    required this.onLeads,
    required this.onMatches,
    required this.onSettings,
  });

  final int selected;
  final VoidCallback onInbox;
  final VoidCallback onLeads;
  final VoidCallback onMatches;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 68.h,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFECE8E5))),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _BottomNavItem(
              icon: Icons.chat_bubble_outline,
              label: 'Inbox',
              selected: selected == 0,
              onTap: onInbox,
            ),
            _BottomNavItem(
              icon: Icons.manage_search_outlined,
              label: 'Leads',
              selected: selected == 1,
              onTap: onLeads,
            ),
            _BottomNavItem(
              icon: Icons.favorite_border,
              label: 'Matches',
              selected: selected == 2,
              onTap: onMatches,
            ),
            _BottomNavItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              selected: selected == 3,
              onTap: onSettings,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4.r),
      child: Container(
        width: 63.w,
        padding: EdgeInsets.symmetric(vertical: 4.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.rmPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : AppColors.rmBodyText,
              size: 23.sp,
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              maxLines: 1,
              style: GoogleFonts.inter(
                color: selected ? Colors.white : AppColors.rmBodyText,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadDetailsAppBar extends StatelessWidget {
  const _LeadDetailsAppBar({required this.conversation});

  final WhatsappConversation conversation;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58.h,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF2DDD1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '',
              style: GoogleFonts.playfairDisplay(
                color: AppColors.rmHeading,
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close, color: AppColors.rmHeading),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999.r),
        color: background,
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          color: foreground,
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _LeadDetailsTabs extends StatelessWidget {
  const _LeadDetailsTabs({required this.selected, required this.onSelected});

  final _LeadDetailTab selected;
  final ValueChanged<_LeadDetailTab> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      (_LeadDetailTab.overview, 'Overview', Icons.info_outline),
      (_LeadDetailTab.notes, 'Notes & Follow-up', Icons.description_outlined),
      (_LeadDetailTab.conversation, 'Conversation', Icons.groups_outlined),
      (_LeadDetailTab.resumes, 'Resumes Sent', Icons.badge_outlined),
      (_LeadDetailTab.history, 'History', Icons.history),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          final isSelected = item.$1 == selected;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: InkWell(
              onTap: () => onSelected(item.$1),
              borderRadius: BorderRadius.circular(11.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(11.r),
                  border: Border.all(color: const Color(0xFFE9E2DE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.$3,
                      color: isSelected ? Colors.white : AppColors.rmBodyText,
                      size: 14.sp,
                    ),
                    SizedBox(width: 7.w),
                    Text(
                      item.$2,
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.white : AppColors.rmBodyText,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LeadDetailTabContent extends StatelessWidget {
  const _LeadDetailTabContent({
    required this.tab,
    required this.conversation,
    required this.lead,
    required this.comments,
    required this.isLoadingComments,
    required this.isAddingComment,
    required this.commentError,
    required this.commentController,
    required this.assignedTo,
    required this.source,
    required this.status,
    required this.onAddComment,
    required this.onRetryComments,
  });

  final _LeadDetailTab tab;
  final WhatsappConversation conversation;
  final RmLeadItem? lead;
  final List<RmLeadComment> comments;
  final bool isLoadingComments;
  final bool isAddingComment;
  final String? commentError;
  final TextEditingController commentController;
  final String assignedTo;
  final String source;
  final String status;
  final VoidCallback onAddComment;
  final VoidCallback onRetryComments;

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case _LeadDetailTab.notes:
        return _NotesFollowUpTab(
          lead: lead,
          comments: comments,
          isLoading: isLoadingComments,
          isAdding: isAddingComment,
          error: commentError,
          controller: commentController,
          onAddComment: onAddComment,
          onRetry: onRetryComments,
        );
      case _LeadDetailTab.conversation:
        return _ConversationTab(conversation: conversation, lead: lead);
      case _LeadDetailTab.resumes:
        return _ResumesTab(lead: lead);
      case _LeadDetailTab.history:
        return _HistoryTab(
          lead: lead,
          conversation: conversation,
          assignedTo: assignedTo,
        );
      case _LeadDetailTab.overview:
        return Column(
          children: [
            _LeadContactCard(
              conversation: conversation,
              lead: lead,
              onOpenChat: () => Navigator.of(context).pushNamed(
                AppRoutes.whatsappConversation,
                arguments: conversation,
              ),
            ),
            SizedBox(height: 16.h),
            _AssignedUserCard(name: assignedTo),
            SizedBox(height: 16.h),
            _LeadInfoGrid(
              source: source,
              leadFor: lead?.leadForLabel ?? '-',
              city: _leadValue(lead?.city, conversation.city),
              status: status,
              assignedTo: assignedTo,
            ),
            SizedBox(height: 16.h),
            _MetaSummaryCard(
              community: lead?.communityLabel ?? '-',
              lastUpdate: _dateLabel(lead?.updatedAt),
            ),
          ],
        );
    }
  }
}

class _NotesFollowUpTab extends StatelessWidget {
  const _NotesFollowUpTab({
    required this.lead,
    required this.comments,
    required this.isLoading,
    required this.isAdding,
    required this.error,
    required this.controller,
    required this.onAddComment,
    required this.onRetry,
  });

  final RmLeadItem? lead;
  final List<RmLeadComment> comments;
  final bool isLoading;
  final bool isAdding;
  final String? error;
  final TextEditingController controller;
  final VoidCallback onAddComment;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NotesCard(notes: lead?.notes ?? '', comments: comments),
        SizedBox(height: 16.h),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comments',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.rmHeading,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 14.h),
              TextField(
                controller: controller,
                minLines: 4,
                maxLines: 6,
                cursorColor: AppColors.rmPrimary,
                style: GoogleFonts.inter(
                  color: AppColors.rmHeading,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a note, update, or follow-up comment...',
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.rmBodyText.withValues(alpha: 0.55),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFFFEFD),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFFE5DED9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFFE5DED9)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: AppColors.rmPrimary),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: isAdding ? null : onAddComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rmPrimary,
                    disabledBackgroundColor: AppColors.rmPrimary.withValues(
                      alpha: 0.42,
                    ),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white.withValues(
                      alpha: 0.78,
                    ),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 14.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    isAdding ? 'Adding...' : 'Add Comment',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (isLoading) ...[
                SizedBox(height: 18.h),
                const Center(
                  child: CircularProgressIndicator(color: AppColors.rmPrimary),
                ),
              ] else if (error != null) ...[
                SizedBox(height: 18.h),
                _LeadDetailError(message: error!, onRetry: onRetry),
              ] else ...[
                SizedBox(height: 18.h),
                if (comments.isEmpty)
                  _EmptyPanel(
                    message:
                        'No comments yet. Add the first update for this lead.',
                  )
                else
                  ...comments.map(
                    (comment) => Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: _CommentCard(comment: comment),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final RmLeadComment comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAFA),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFF0E2DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment.userName,
            style: GoogleFonts.inter(
              color: AppColors.rmHeading,
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            _formatEnumLabel(comment.userRole),
            style: GoogleFonts.inter(
              color: AppColors.rmBodyText,
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            comment.content,
            style: GoogleFonts.inter(
              color: AppColors.rmHeading,
              fontSize: 13.sp,
              height: 1.45,
            ),
          ),
          if (comment.createdAt != null) ...[
            SizedBox(height: 8.h),
            Text(
              _dateTimeLabel(comment.createdAt),
              style: GoogleFonts.inter(
                color: AppColors.rmBodyText,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConversationTab extends StatelessWidget {
  const _ConversationTab({required this.conversation, required this.lead});

  final WhatsappConversation conversation;
  final RmLeadItem? lead;

  @override
  Widget build(BuildContext context) {
    final logs = lead?.communicationLogs ?? const <RmCommunicationLog>[];
    return Column(
      children: [
        _QuickActionButton(
          icon: Icons.chat_bubble_outline,
          label: 'Open WhatsApp Conversation',
          onTap: () => Navigator.of(
            context,
          ).pushNamed(AppRoutes.whatsappConversation, arguments: conversation),
        ),
        SizedBox(height: 16.h),
        if (logs.isEmpty)
          const _EmptyPanel(message: 'No CRM conversation logs returned yet.')
        else
          ...logs.reversed
              .take(12)
              .map(
                (log) => Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: _TimelineCard(
                    title: log.previewText,
                    subtitle: '${log.channelLabel} • ${log.directionLabel}',
                    date: log.createdAt,
                  ),
                ),
              ),
      ],
    );
  }
}

class _ResumesTab extends StatelessWidget {
  const _ResumesTab({required this.lead});

  final RmLeadItem? lead;

  @override
  Widget build(BuildContext context) {
    final resumes = [
      ...?lead?.resumesReceived,
      ...?lead?.inboundResumeAttachments,
    ];
    if (resumes.isEmpty) {
      return _EmptyPanel(
        message: (lead?.resumeCount ?? 0) > 0
            ? '${lead!.resumeCount} resume(s) tracked for this lead.'
            : 'No resumes have been tracked for this lead.',
      );
    }
    return Column(
      children: resumes
          .map(
            (resume) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: _TimelineCard(
                title: resume.name,
                subtitle: resume.status.isEmpty
                    ? 'Resume attachment'
                    : _formatEnumLabel(resume.status),
                date: resume.createdAt,
                icon: Icons.badge_outlined,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({
    required this.lead,
    required this.conversation,
    required this.assignedTo,
  });

  final RmLeadItem? lead;
  final WhatsappConversation conversation;
  final String assignedTo;

  @override
  Widget build(BuildContext context) {
    final events = <_LeadTimelineEvent>[
      _LeadTimelineEvent(
        title: 'Created On',
        date: lead?.createdAt ?? conversation.createdAt,
        icon: Icons.add_circle_outline,
      ),
      if (lead?.convertedAt != null)
        _LeadTimelineEvent(
          title: 'Converted On',
          date: lead?.convertedAt,
          icon: Icons.verified_outlined,
        ),
      if (lead?.updatedAt != null)
        _LeadTimelineEvent(
          title: 'Last Update',
          date: lead?.updatedAt,
          icon: Icons.history,
        ),
      _LeadTimelineEvent(
        title: 'Assigned User',
        text: assignedTo,
        icon: Icons.person_outline,
      ),
      ...?lead?.comments.map(
        (comment) => _LeadTimelineEvent(
          title: 'Comment',
          text: comment.content,
          date: comment.createdAt,
          icon: Icons.notes_outlined,
        ),
      ),
    ];

    return Column(
      children: [
        _AssignedUserCard(name: assignedTo),
        SizedBox(height: 16.h),
        _MetaSummaryCard(
          community: lead?.communityLabel ?? '-',
          lastUpdate: _dateLabel(lead?.updatedAt),
        ),
        SizedBox(height: 16.h),
        ...events.map(
          (event) => Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _TimelineCard(
              title: event.title,
              subtitle: event.text ?? 'Not available',
              date: event.date,
              icon: event.icon,
            ),
          ),
        ),
      ],
    );
  }
}

class _LeadTimelineEvent {
  const _LeadTimelineEvent({
    required this.title,
    required this.icon,
    this.text,
    this.date,
  });

  final String title;
  final IconData icon;
  final String? text;
  final DateTime? date;
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.title,
    required this.subtitle,
    this.date,
    this.icon = Icons.history,
  });

  final String title;
  final String subtitle;
  final DateTime? date;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38.r,
            height: 38.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: AppColors.rmHeading, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppColors.rmHeading,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  date == null ? subtitle : _dateTimeLabel(date),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.rmBodyText,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                if (date != null && subtitle != 'Not available') ...[
                  SizedBox(height: 5.h),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.rmHeading,
                      fontSize: 12.5.sp,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAFA),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFEDE1DD)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: AppColors.rmBodyText,
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }
}

class _LeadContactCard extends StatelessWidget {
  const _LeadContactCard({
    required this.conversation,
    required this.lead,
    required this.onOpenChat,
  });

  final WhatsappConversation conversation;
  final RmLeadItem? lead;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final phone = _leadValue(lead?.phone, conversation.phone);
    final email = _leadValue(lead?.email, conversation.email, fallback: '');

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFF2CBB9)),
      ),
      child: Column(
        children: [
          _ContactRow(
            icon: Icons.phone_outlined,
            label: 'Mobile',
            value: phone,
            trailing: Icons.copy_outlined,
          ),
          _ContactRow(
            icon: Icons.chat,
            iconColor: AppColors.whatsappGreen,
            label: 'WhatsApp',
            value: 'Open WhatsApp chat',
            valueColor: AppColors.whatsappGreen,
            trailing: Icons.open_in_new,
            onTap: onOpenChat,
          ),
          if (email.isNotEmpty)
            _ContactRow(
              icon: Icons.mail_outline,
              label: 'Email',
              value: email,
              trailing: Icons.copy_outlined,
              showDivider: false,
            ),
          if (email.isEmpty) const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? valueColor;
  final IconData? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: Color(0xFFF0E7E1)))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5ED),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.rmHeading,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: AppColors.rmHeading,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: valueColor ?? AppColors.rmHeading,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Icon(trailing, color: AppColors.rmPrimary, size: 21.sp),
          ],
        ),
      ),
    );
  }
}

class _AssignedUserCard extends StatelessWidget {
  const _AssignedUserCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Row(
        children: [
          Container(
            width: 46.r,
            height: 46.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.rmPrimary,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              _initialsForName(name),
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigned Users'.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: AppColors.rmHeading,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    color: AppColors.rmHeading,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
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

class _LeadInfoGrid extends StatelessWidget {
  const _LeadInfoGrid({
    required this.source,
    required this.leadFor,
    required this.city,
    required this.status,
    required this.assignedTo,
  });

  final String source;
  final String leadFor;
  final String city;
  final String status;
  final String assignedTo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FactCard(label: 'Source', value: source),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _FactCard(
                label: 'Lead For',
                value: leadFor,
                chipColor: const Color(0xFFE7EFFD),
                chipTextColor: const Color(0xFF274B9F),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _FactCard(label: 'City', value: city),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _FactCard(
                label: 'Stage',
                value: status,
                dotColor: AppColors.success,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        _FactCard(label: 'Assigned Users', value: assignedTo),
      ],
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.label,
    required this.value,
    this.chipColor,
    this.chipTextColor,
    this.dotColor,
  });

  final String label;
  final String value;
  final Color? chipColor;
  final Color? chipTextColor;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final text = _cleanLeadValue(value).isEmpty ? '-' : value;
    final content = dotColor == null
        ? Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.rmHeading,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8.r,
                height: 8.r,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 5.w),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    color: AppColors.rmHeading,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );

    return _SectionCard(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 13.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              color: AppColors.rmHeading,
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          SizedBox(height: 8.h),
          if (chipColor == null)
            content
          else
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    color: chipTextColor ?? AppColors.rmHeading,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaSummaryCard extends StatelessWidget {
  const _MetaSummaryCard({required this.community, required this.lastUpdate});

  final String community;
  final String lastUpdate;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _MetaRow(label: 'Community', value: community),
          const Divider(height: 1, color: Color(0xFFF0E7E1)),
          _MetaRow(label: 'Last Update', value: lastUpdate),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.playfairDisplay(
                color: AppColors.rmBodyText,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                color: AppColors.rmHeading,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes, required this.comments});

  final String notes;
  final List<RmLeadComment> comments;

  @override
  Widget build(BuildContext context) {
    final cleanNotes = _cleanLeadValue(notes);
    final fallbackComment = comments.isEmpty ? '' : comments.first.content;
    final displayNotes = cleanNotes.isNotEmpty
        ? cleanNotes
        : _cleanLeadValue(fallbackComment);
    final hasNotes = displayNotes.isNotEmpty;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Notes'.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: AppColors.rmHeading,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Icon(Icons.add, color: AppColors.rmPrimary, size: 21.sp),
            ],
          ),
          SizedBox(height: 22.h),
          Center(
            child: Text(
              hasNotes
                  ? displayNotes
                  : 'No notes have been recorded for this lead yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: AppColors.rmBodyText,
                fontSize: 15.sp,
                fontStyle: hasNotes ? FontStyle.normal : FontStyle.italic,
                height: 1.35,
              ),
            ),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFF2CBB9)),
      ),
      child: child,
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.rmPrimary.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0B7189), size: 22.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: AppColors.rmHeading,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.rmPrimary, size: 24.sp),
          ],
        ),
      ),
    );
  }
}

String _conversationTime(DateTime? value) {
  if (value == null) {
    return '';
  }
  final now = DateTime.now();
  final date = DateTime(value.year, value.month, value.day);
  final today = DateTime(now.year, now.month, now.day);
  final days = today.difference(date).inDays;
  if (days == 0) {
    return DateFormat('hh:mm a').format(value);
  }
  if (days == 1) {
    return 'Yesterday';
  }
  if (days < 7) {
    return '${days}d ago';
  }
  if (days < 28) {
    return '${(days / 7).floor()}w ago';
  }
  return DateFormat('dd MMM').format(value);
}

String _dateLabel(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return DateFormat('dd MMM yyyy').format(value);
}

String _dateTimeLabel(DateTime? value) {
  if (value == null) {
    return 'Not available';
  }
  return DateFormat('dd MMM yyyy, hh:mm a').format(value);
}

String _formatEnumLabel(String value) {
  final text = value.trim();
  if (text.isEmpty) {
    return '-';
  }
  return text
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) {
        final lower = part.toLowerCase();
        return '${lower.substring(0, 1).toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

String _initialsForName(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty || value == '-') {
    return 'U';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

String _resolveAssetUrl(String value) {
  final raw = value.trim();
  if (raw.isEmpty) {
    return '';
  }
  if (raw.startsWith('//')) {
    return 'https:$raw';
  }
  final uri = Uri.tryParse(raw);
  if (uri != null && uri.hasScheme) {
    return raw;
  }

  final base = Uri.parse(ApiConstants.baseUrl);
  final origin = '${base.scheme}://${base.authority}';
  if (raw.startsWith('/')) {
    return '$origin$raw';
  }
  return '${ApiConstants.baseUrl}/$raw';
}

Map<String, String>? _authHeadersForUrl(String url, String? accessToken) {
  if (accessToken == null || accessToken.trim().isEmpty) {
    return null;
  }
  final base = Uri.parse(ApiConstants.baseUrl);
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host != base.host) {
    return null;
  }
  return {'Authorization': 'Bearer $accessToken'};
}
