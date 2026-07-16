import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/owner/models/lead_follow_up_item.dart';
import 'package:koniwalamatrimonial/owner/providers/lead_follow_ups_provider.dart';
import 'package:koniwalamatrimonial/owner/providers/tasks_provider.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LeadFollowUpsScreen extends StatefulWidget {
  const LeadFollowUpsScreen({super.key});

  @override
  State<LeadFollowUpsScreen> createState() => _LeadFollowUpsScreenState();
}

class _LeadFollowUpsScreenState extends State<LeadFollowUpsScreen> {
  static const int _initialLeadLimit = 6;
  static const int _leadPageSize = 8;
  bool _hasRequestedFollowUps = false;
  String? _requestedAccessToken;
  String _query = '';
  String _selectedFilter = 'All follow-ups';
  Timer? _searchDebounce;
  int _visibleLeadLimit = _initialLeadLimit;

  final List<String> _filters = const [
    'All follow-ups',
    'Due today',
    'Overdue',
    'Waiting for client',
    'Cold leads',
  ];

  List<LeadFollowUpItem> _visibleLeads(List<LeadFollowUpItem> leads) {
    var filtered = leads.where((lead) => lead.matches(_query)).toList();

    if (_selectedFilter == 'Due today') {
      filtered = filtered.where(_hasTaskDueToday).toList();
    } else if (_selectedFilter == 'Overdue') {
      filtered = filtered.where((lead) => lead.hasOverdueFollowUp).toList();
    } else if (_selectedFilter == 'Waiting for client') {
      filtered = filtered.where((lead) => lead.isWaiting).toList();
    } else if (_selectedFilter == 'Cold leads') {
      filtered = filtered.where((lead) => lead.isCold).toList();
    }

    return filtered..sort((first, second) {
      final firstCreatedAt = first.latestTaskCreatedAt;
      final secondCreatedAt = second.latestTaskCreatedAt;
      if (firstCreatedAt != null || secondCreatedAt != null) {
        if (firstCreatedAt == null) return 1;
        if (secondCreatedAt == null) return -1;
        final comparison = secondCreatedAt.compareTo(firstCreatedAt);
        if (comparison != 0) return comparison;
      }
      if (first.hasOverdueFollowUp != second.hasOverdueFollowUp) {
        return first.hasOverdueFollowUp ? -1 : 1;
      }
      return first.name.compareTo(second.name);
    });
  }

  int _boundedLeadLimit(int requestedLimit, int totalLeadCount) {
    if (totalLeadCount <= 0) {
      return 0;
    }

    if (requestedLimit < _initialLeadLimit) {
      return totalLeadCount < _initialLeadLimit
          ? totalLeadCount
          : _initialLeadLimit;
    }

    if (requestedLimit > totalLeadCount) {
      return totalLeadCount;
    }

    return requestedLimit;
  }

  void _resetPagination() {
    _visibleLeadLimit = _initialLeadLimit;
  }

  bool _hasTaskDueToday(LeadFollowUpItem lead) {
    final now = DateTime.now();
    return lead.openFollowUps.any((task) {
      final due = task.dueAt;
      if (due == null) return false;
      final localDue = due.toLocal();
      return localDue.year == now.year &&
          localDue.month == now.month &&
          localDue.day == now.day;
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authProvider = Provider.of<AuthProvider>(context);
    final accessToken = authProvider.userModel?.accessToken;

    if (!authProvider.isInitialized ||
        (_hasRequestedFollowUps && accessToken == _requestedAccessToken)) {
      return;
    }

    _hasRequestedFollowUps = true;
    _requestedAccessToken = accessToken;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LeadFollowUpsProvider>().fetchFollowUps(accessToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    final followUpsProvider = context.watch<LeadFollowUpsProvider>();
    final leads = followUpsProvider.leads;
    final visibleLeads = _visibleLeads(leads);
    final displayLimit = _boundedLeadLimit(
      _visibleLeadLimit,
      visibleLeads.length,
    );
    final displayedLeads = visibleLeads
        .take(displayLimit)
        .toList(growable: false);

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF9F6),
        appBar: AppBar(
          toolbarHeight: 60.h,
          backgroundColor: const Color(0xFFFFFBF8),
          surfaceTintColor: const Color(0xFFFFFBF8),
          elevation: 0,
          scrolledUnderElevation: 0,
          shadowColor: AppColors.transparent,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 24.sp,
              color: const Color(0xFF171412),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Lead Follow-ups',
            style: GoogleFonts.inter(
              color: const Color(0xFF171412),
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () => context.read<LeadFollowUpsProvider>().retry(),
              icon: Icon(
                Icons.refresh_rounded,
                color: const Color(0xFF171412),
                size: 20.sp,
              ),
              tooltip: 'Refresh',
            ),
            // IconButton(
            //   onPressed: () {},
            //   icon: Icon(
            //     Icons.more_vert_rounded,
            //     color: const Color(0xFF171412),
            //     size: 24.sp,
            //   ),
            //   tooltip: 'Menu',
            // ),
            SizedBox(width: 4.w),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.h),
            child: Container(height: 1.h, color: const Color(0xFFEADDD5)),
          ),
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () => context.read<LeadFollowUpsProvider>().retry(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 20.h, 14.w, 14.h),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'One clean queue per lead. The first row\nshows who the lead is, the task explains\nwhat is pending.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF34302F),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
                _LeadFollowUpSummary(leads: leads),
                Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 10.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SearchBar(
                          onChanged: (value) {
                            _searchDebounce?.cancel();
                            _searchDebounce = Timer(
                              const Duration(milliseconds: 220),
                              () {
                                if (!mounted) {
                                  return;
                                }

                                setState(() {
                                  _query = value;
                                  _resetPagination();
                                });
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _FollowUpFilterDropdown(
                        filters: _filters,
                        selectedFilter: _selectedFilter,
                        onFilterSelected: (filter) => setState(() {
                          _selectedFilter = filter;
                          _resetPagination();
                        }),
                      ),
                    ],
                  ),
                ),
                _FollowUpList(
                  isLoading: followUpsProvider.isLoading,
                  error: followUpsProvider.error,
                  leads: displayedLeads,
                  totalLeadCount: visibleLeads.length,
                  isExpanded: displayLimit >= visibleLeads.length,
                  onLoadMore: visibleLeads.length > _initialLeadLimit
                      ? () => setState(() {
                          if (displayLimit >= visibleLeads.length) {
                            _visibleLeadLimit = _initialLeadLimit;
                            return;
                          }

                          _visibleLeadLimit = _boundedLeadLimit(
                            _visibleLeadLimit + _leadPageSize,
                            visibleLeads.length,
                          );
                        })
                      : null,
                  onRetry: () => context.read<LeadFollowUpsProvider>().retry(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 37.h,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFD8D8D8)),
      ),
      child: TextField(
        onChanged: onChanged,
        style: GoogleFonts.inter(
          color: AppColors.rmHeading,
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
        ),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: 'Search registry...',
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFF6E7683),
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: const Color(0xFF6E7683),
            size: 18.sp,
          ),
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 7.h),
        ),
      ),
    );
  }
}

class _LeadFollowUpSummary extends StatelessWidget {
  const _LeadFollowUpSummary({required this.leads});

  final List<LeadFollowUpItem> leads;

  @override
  Widget build(BuildContext context) {
    final activeCount = leads
        .where((lead) => lead.openFollowUps.isNotEmpty)
        .length;
    final overdueCount = leads.fold<int>(
      0,
      (count, lead) =>
          count + lead.openFollowUps.where((task) => task.isOverdue).length,
    );
    final waitingCount = leads.where((lead) => lead.isWaiting).length;
    final coldCount = leads.where((lead) => lead.isCold).length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _LeadMetricCard(
                  title: 'Active',
                  value: '$activeCount',
                  subtitle: 'Pending',
                  icon: Icons.schedule_rounded,
                  subtitleColor: const Color(0xFFE53A3A),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _LeadMetricCard(
                  title: 'Overdue',
                  value: '$overdueCount',
                  subtitle: 'Immediate',
                  icon: Icons.warning_amber_rounded,
                  subtitleColor: const Color(0xFFE76D22),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _LeadMetricCard(
                  title: 'Waiting',
                  value: '$waitingCount',
                  subtitle: 'Client',
                  icon: Icons.hourglass_empty_rounded,
                  subtitleColor: const Color(0xFFE7A100),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _LeadMetricCard(
                  title: 'Cold',
                  value: '$coldCount',
                  subtitle: 'Stagnant',
                  icon: Icons.ac_unit_rounded,
                  subtitleColor: const Color(0xFF305DFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeadMetricCard extends StatelessWidget {
  const _LeadMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.subtitleColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 102.h,
      padding: EdgeInsets.fromLTRB(12.w, 13.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(7.r),
        border: Border.all(color: const Color(0xFFF1DFD6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              color: const Color(0xFF3F3A38),
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              color: const Color(0xFFD76322),
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(icon, color: subtitleColor, size: 15.sp),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: subtitleColor == const Color(0xFFE7A100)
                        ? const Color(0xFF38312E)
                        : subtitleColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
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

class _FollowUpFilterDropdown extends StatelessWidget {
  const _FollowUpFilterDropdown({
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final buttonLabel = selectedFilter == 'All follow-ups'
        ? 'all'
        : selectedFilter
              .replaceAll(' follow-ups', '')
              .replaceAll(' for client', '')
              .toLowerCase();

    return Container(
      width: 84.w,
      height: 37.h,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE57742)),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Filter follow-ups',
        initialValue: selectedFilter,
        position: PopupMenuPosition.under,
        offset: Offset(0, 5.h),
        elevation: 3,
        color: AppColors.white,
        surfaceTintColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.r),
          side: const BorderSide(color: Color(0xFFE8E0DC)),
        ),
        onSelected: onFilterSelected,
        itemBuilder: (context) {
          return filters.map((filter) {
            final selected = filter == selectedFilter;
            return PopupMenuItem<String>(
              value: filter,
              height: 40.h,
              child: Row(
                children: [
                  SizedBox(
                    width: 22.w,
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            color: const Color(0xFF171412),
                            size: 18.sp,
                          )
                        : null,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    filter,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF171412),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  buttonLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF171412),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: const Color(0xFF6B7280),
                size: 19.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowUpList extends StatelessWidget {
  const _FollowUpList({
    required this.isLoading,
    required this.error,
    required this.leads,
    required this.totalLeadCount,
    required this.isExpanded,
    required this.onLoadMore,
    required this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final List<LeadFollowUpItem> leads;
  final int totalLeadCount;
  final bool isExpanded;
  final VoidCallback? onLoadMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _FollowUpLoadingSkeleton();
    }

    if (error != null) {
      return SizedBox(
        height: 260.h,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              error!,
              style: GoogleFonts.inter(
                color: AppColors.rmBodyText,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (leads.isEmpty) {
      return SizedBox(
        height: 260.h,
        child: Text(
          'No follow-ups found.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.rmMutedText,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(14.w),
      child: Column(
        children: [
          for (int index = 0; index < leads.length; index++) ...[
            if (index > 0) SizedBox(height: 14.h),
            _LeadFollowUpCard(lead: leads[index]),
          ],
          if (onLoadMore != null) ...[
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: OutlinedButton(
                onPressed: onLoadMore,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD76322),
                  side: const BorderSide(color: Color(0xFFD76322)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  isExpanded
                      ? 'Show Less'
                      : 'Show More (${totalLeadCount - leads.length})',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: 18.h),
        ],
      ),
    );
  }
}

class _FollowUpLoadingSkeleton extends StatefulWidget {
  const _FollowUpLoadingSkeleton();

  @override
  State<_FollowUpLoadingSkeleton> createState() =>
      _FollowUpLoadingSkeletonState();
}

class _FollowUpLoadingSkeletonState extends State<_FollowUpLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(14.w),
      child: Column(
        children: [
          for (int index = 0; index < 3; index++) ...[
            if (index > 0) SizedBox(height: 14.h),
            _SkeletonCard(animation: _controller),
          ],
          SizedBox(height: 18.h),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE9DDD8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonBlock(
                animation: animation,
                width: 38.r,
                height: 38.r,
                radius: 19.r,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBlock(
                      animation: animation,
                      width: 170.w,
                      height: 18.h,
                    ),
                    SizedBox(height: 8.h),
                    _SkeletonBlock(
                      animation: animation,
                      width: 130.w,
                      height: 12.h,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              _SkeletonBlock(
                animation: animation,
                width: 120.w,
                height: 30.h,
                radius: 15.r,
              ),
              SizedBox(width: 8.w),
              _SkeletonBlock(
                animation: animation,
                width: 105.w,
                height: 30.h,
                radius: 15.r,
              ),
            ],
          ),
          SizedBox(height: 18.h),
          _SkeletonBlock(animation: animation, width: 220.w, height: 18.h),
          SizedBox(height: 10.h),
          _SkeletonBlock(animation: animation, width: 150.w, height: 12.h),
          SizedBox(height: 18.h),
          _SkeletonBlock(
            animation: animation,
            width: double.infinity,
            height: 64.h,
            radius: 10.r,
          ),
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.animation,
    required this.width,
    required this.height,
    this.radius,
  });

  final Animation<double> animation;
  final double width;
  final double height;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius ?? 7.r),
            gradient: LinearGradient(
              begin: Alignment(-1 + animation.value * 2, 0),
              end: Alignment(animation.value * 2, 0),
              colors: const [
                Color(0xFFF3EAE5),
                Color(0xFFFFFAF7),
                Color(0xFFF3EAE5),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LeadFollowUpCard extends StatelessWidget {
  const _LeadFollowUpCard({required this.lead});

  final LeadFollowUpItem lead;

  @override
  Widget build(BuildContext context) {
    final task = lead.openFollowUps.isNotEmpty
        ? lead.openFollowUps.first
        : null;
    final isCompleting =
        task != null && context.watch<TasksProvider>().isCompleting(task.id);
    final progressCount = lead.followUpTasks.where((item) {
      final status = '${item.status} ${item.workflowStatus}'.toLowerCase();
      return item.isOpen && status.contains('progress');
    }).length;
    final notes = lead.notes.trim().isNotEmpty
        ? lead.notes.trim()
        : "Demo system task created from the 'Lead No Response Escalation' rule.";

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFF1B9A1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 9.h),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        lead.initials.substring(0, 1),
                        style: GoogleFonts.inter(
                          color: const Color(0xFF3A3532),
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  lead.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF171412),
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w900,
                                    height: 1.05,
                                  ),
                                ),
                              ),
                              SizedBox(width: 7.w),
                              _StageBadge(stage: lead.stage),
                            ],
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            '${lead.phone} • RM',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF2A2725),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          Text(
                            lead.assignedToName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF3C3835),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 17.h),
                Row(
                  children: [
                    _AttentionBadge(
                      label: lead.hasOverdueFollowUp
                          ? 'Needs attention'
                          : 'Follow-up',
                      filled: false,
                    ),
                    SizedBox(width: 6.w),
                    _AttentionBadge(
                      label: '${lead.openFollowUps.length} open items',
                      filled: false,
                      neutral: true,
                    ),
                    SizedBox(width: 6.w),
                    const Spacer(),
                    SizedBox(
                      height: 34.h,
                      child: ElevatedButton.icon(
                        onPressed: () => _openQuickTask(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD76322),
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 9.w),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                        ),
                        icon: Icon(Icons.add_rounded, size: 16.sp),
                        label: Text(
                          'Quick',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: const Color(0xFFEFE6E1)),
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 13.h, 12.w, 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _TaskStatusPill(
                      label: 'To Do',
                      count: lead.openFollowUps.length,
                      selected: true,
                    ),
                    _TaskStatusPill(label: 'Progress', count: progressCount),
                    _TaskStatusPill(
                      label: 'Done',
                      count: lead.doneFollowUps.length,
                    ),
                  ],
                ),
                SizedBox(height: 17.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: [
                    _SoftBadge(
                      label: _priorityLabel(task),
                      color: const Color(0xFFE83B45),
                      background: const Color(0xFFFFEEEE),
                    ),
                    if (task?.isOverdue ?? false)
                      _SoftBadge(
                        label: 'OVERDUE',
                        color: const Color(0xFFE67B22),
                        background: const Color(0xFFFFF3E6),
                        icon: Icons.warning_amber_rounded,
                      ),
                  ],
                ),
                SizedBox(height: 9.h),
                Text(
                  task?.title ?? 'Call client for follow-up',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF272321),
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  lead.leadMeta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF5C5652),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 14.h),
                Divider(height: 1, color: const Color(0xFFEFE6E1)),
                SizedBox(height: 12.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _TaskInfoBlock(
                        label: 'Task Type',
                        value: task?.type ?? 'Call',
                      ),
                    ),
                    Expanded(
                      child: _TaskInfoBlock(
                        label: 'Due Date',
                        value: task?.dueDateLabel ?? '-',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _TaskInfoBlock(
                  label: 'Assigned To',
                  value: task?.assignedToName == '-'
                      ? lead.assignedToName
                      : task?.assignedToName ?? lead.assignedToName,
                ),
                SizedBox(height: 12.h),
                Divider(height: 1, color: const Color(0xFFEFE6E1)),
                SizedBox(height: 16.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFAF8),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOTES',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF2F2B29),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 9.h),
                      Text(
                        notes,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF4A4542),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                InkWell(
                  borderRadius: BorderRadius.circular(9.r),
                  onTap: () => _openDialer(context, lead.phone),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(10.w, 9.h, 12.w, 9.h),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(9.r),
                      border: Border.all(color: const Color(0xFFF1BEA6)),
                    ),
                    child: Row(
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/wedding_hero 1.png',
                            width: 44.r,
                            height: 44.r,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CLIENT PROFILE',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF4B4542),
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                lead.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF171412),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.phone_in_talk_outlined,
                          color: const Color(0xFF171412),
                          size: 20.sp,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 34.h),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _openQuickTask(context),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            color: const Color(0xFF4A4542),
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Quick Task',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF4A4542),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 37.h,
                      width: 126.w,
                      child: ElevatedButton(
                        onPressed: task == null || isCompleting
                            ? null
                            : () => _markDone(context, task),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD76322),
                          foregroundColor: AppColors.white,
                          disabledBackgroundColor: const Color(0xFFE6C4B5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                        ),
                        child: isCompleting
                            ? SizedBox(
                                width: 18.r,
                                height: 18.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : Text(
                                'Mark Done',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: const Color(0xFFEFE6E1)),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 9.h, 12.w, 10.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatTimestamp(task?.createdAt ?? lead.createdAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF4A4542),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_month_outlined,
                  color: const Color(0xFF3E454E),
                  size: 17.sp,
                ),
                SizedBox(width: 14.w),
                Icon(
                  Icons.delete_outline_rounded,
                  color: const Color(0xFFE3262E),
                  size: 18.sp,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _priorityLabel(LeadFollowUpTask? task) {
    final priority = task?.priority.trim();
    if (priority == null || priority.isEmpty || priority == '-') {
      return 'HIGH PRIORITY';
    }
    return '${priority.toUpperCase()} PRIORITY';
  }

  String _formatTimestamp(DateTime? date) {
    if (date == null) {
      return '11 May, 03:13 pm';
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
    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final meridiem = local.hour >= 12 ? 'pm' : 'am';
    return '${local.day} ${months[local.month - 1]}, $hour:$minute $meridiem';
  }

  Future<void> _openQuickTask(BuildContext context) async {
    final created = await Navigator.pushNamed(
      context,
      AppRoutes.createNewTask,
      arguments: lead,
    );
    if (!context.mounted || created != true) return;
    await context.read<LeadFollowUpsProvider>().retry();
  }

  Future<void> _openDialer(BuildContext context, String phone) async {
    final messenger = ScaffoldMessenger.of(context);
    final normalizedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    if (normalizedPhone.isEmpty || normalizedPhone == '+') {
      messenger.showSnackBar(
        const SnackBar(content: Text('Phone number is unavailable')),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: normalizedPhone);
    final opened = await launchUrl(uri);
    if (!opened && context.mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to open phone dialer')),
      );
    }
  }

  Future<void> _markDone(BuildContext context, LeadFollowUpTask task) async {
    final messenger = ScaffoldMessenger.of(context);
    final token = context.read<AuthProvider>().userModel?.accessToken;
    final tasksProvider = context.read<TasksProvider>();
    final success = await tasksProvider.markTaskDone(
      accessToken: token,
      taskId: task.id,
    );

    if (!context.mounted) return;

    if (!success) {
      messenger.showSnackBar(
        SnackBar(content: Text(tasksProvider.error ?? 'Unable to update task')),
      );
      return;
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Task marked as done')),
    );
    await context.read<LeadFollowUpsProvider>().retry();
  }
}

class _AttentionBadge extends StatelessWidget {
  const _AttentionBadge({
    required this.label,
    required this.filled,
    this.neutral = false,
  });

  final String label;
  final bool filled;
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final color = neutral ? const Color(0xFF3B3735) : const Color(0xFFE33A3A);
    return Container(
      height: 34.h,
      padding: EdgeInsets.symmetric(horizontal: 11.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? color : AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: neutral ? const Color(0xFFDADADA) : color),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: filled ? AppColors.white : color,
          fontSize: 12.sp,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TaskStatusPill extends StatelessWidget {
  const _TaskStatusPill({
    required this.label,
    required this.count,
    this.selected = false,
  });

  final String label;
  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFD76322) : AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFEBA07A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: selected ? AppColors.white : const Color(0xFF3A3532),
              fontSize: 12.sp,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
          SizedBox(width: 7.w),
          Container(
            width: 18.r,
            height: 18.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.white.withValues(alpha: 0.2)
                  : const Color(0xFFFFEEE8),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                color: selected ? AppColors.white : const Color(0xFFD76322),
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftBadge extends StatelessWidget {
  const _SoftBadge({
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12.sp),
            SizedBox(width: 3.w),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 8.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskInfoBlock extends StatelessWidget {
  const _TaskInfoBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: const Color(0xFF8A8582),
            fontSize: 11.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: const Color(0xFF3A3532),
            fontSize: 15.sp,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.stage});

  final String stage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEBD9FF),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        stage.toUpperCase(),
        style: GoogleFonts.inter(
          color: const Color(0xFF6D35D3),
          fontSize: 10.sp,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
