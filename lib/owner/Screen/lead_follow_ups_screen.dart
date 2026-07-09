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
  bool _hasRequestedFollowUps = false;
  String? _requestedAccessToken;
  String _query = '';
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Today', 'Pending', 'Overdue'];

  List<LeadFollowUpItem> _visibleLeads(List<LeadFollowUpItem> leads) {
    var filtered = leads.where((lead) => lead.matches(_query)).toList();

    if (_selectedFilter == 'Today') {
      final now = DateTime.now();
      filtered = filtered.where((lead) {
        return lead.openFollowUps.any((task) {
          final due = task.dueAt;
          if (due == null) return false;
          return due.year == now.year &&
              due.month == now.month &&
              due.day == now.day;
        });
      }).toList();
    } else if (_selectedFilter == 'Pending') {
      filtered = filtered
          .where((lead) => lead.openFollowUps.isNotEmpty)
          .toList();
    } else if (_selectedFilter == 'Overdue') {
      filtered = filtered.where((lead) => lead.hasOverdueFollowUp).toList();
    }

    return filtered..sort((first, second) {
      final firstCreatedAt = _latestTaskCreatedAt(first);
      final secondCreatedAt = _latestTaskCreatedAt(second);
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

  DateTime? _latestTaskCreatedAt(LeadFollowUpItem lead) {
    DateTime? latest;
    for (final task in lead.followUpTasks) {
      final createdAt = task.createdAt;
      if (createdAt != null && (latest == null || createdAt.isAfter(latest))) {
        latest = createdAt;
      }
    }
    return latest;
  }

  Future<void> _openCreateTask() async {
    final created = await Navigator.pushNamed(context, AppRoutes.createNewTask);
    if (!mounted || created != true) return;

    setState(() {
      _query = '';
      _selectedFilter = 'All';
    });
    await context.read<LeadFollowUpsProvider>().retry();
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

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1.25)),
      child: Scaffold(
        backgroundColor: AppColors.rmBackground,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20.sp,
              color: AppColors.rmPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Lead Follow-ups',
            style: GoogleFonts.manrope(
              color: AppColors.rmPrimary,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _openCreateTask,
              icon: Icon(
                Icons.add_task_rounded,
                color: AppColors.rmPrimary,
                size: 24.sp,
              ),
              tooltip: 'Create New Task',
            ),
            Padding(
              padding: EdgeInsets.only(right: 14.w),
              child: CircleAvatar(
                radius: 16.r,
                backgroundColor: AppColors.rmPrimary,
                child: Text(
                  '${leads.length}',
                  style: GoogleFonts.manrope(
                    color: AppColors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _SearchBar(onChanged: (value) => setState(() => _query = value)),
              _FilterBar(
                filters: _filters,
                selectedFilter: _selectedFilter,
                onFilterSelected: (filter) =>
                    setState(() => _selectedFilter = filter),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      context.read<LeadFollowUpsProvider>().retry(),
                  child: _FollowUpList(
                    isLoading: followUpsProvider.isLoading,
                    error: followUpsProvider.error,
                    leads: visibleLeads,
                    onRetry: () =>
                        context.read<LeadFollowUpsProvider>().retry(),
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
      color: AppColors.white,
      child: TextField(
        onChanged: onChanged,
        style: GoogleFonts.manrope(
          color: AppColors.rmHeading,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Search by lead, phone, reason...',
          hintStyle: GoogleFonts.manrope(
            color: AppColors.rmHintText,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.rmMutedText,
            size: 22.sp,
          ),
          filled: true,
          fillColor: AppColors.rmBackground,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      color: AppColors.white,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selectedFilter;
          return ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) onFilterSelected(filter);
            },
            labelStyle: GoogleFonts.manrope(
              color: isSelected ? AppColors.white : AppColors.rmPrimary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
            selectedColor: AppColors.rmPrimary,
            backgroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
              side: BorderSide(color: AppColors.rmPrimary, width: 1),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

class _FollowUpList extends StatelessWidget {
  const _FollowUpList({
    required this.isLoading,
    required this.error,
    required this.leads,
    required this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final List<LeadFollowUpItem> leads;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              error!,
              style: GoogleFonts.manrope(
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
      return Center(
        child: Text(
          'No follow-ups found.',
          style: GoogleFonts.manrope(
            color: AppColors.rmMutedText,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(14.w),
      itemCount: leads.length,
      separatorBuilder: (context, index) => SizedBox(height: 14.h),
      itemBuilder: (context, index) {
        return _LeadFollowUpCard(lead: leads[index]);
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

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.rmPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.rmPrimary.withValues(alpha: 0.1),
                child: Text(
                  lead.initials,
                  style: GoogleFonts.manrope(
                    color: AppColors.rmPrimary,
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
                      children: [
                        Flexible(
                          child: Text(
                            lead.name,
                            style: GoogleFonts.manrope(
                              color: AppColors.rmHeading,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        _StageBadge(stage: lead.stage),
                      ],
                    ),
                    Text(
                      'Assigned to: ${lead.assignedToName}',
                      style: GoogleFonts.manrope(
                        color: AppColors.rmMutedText,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _openDialer(context, lead.phone),
                icon: Icon(
                  Icons.call_rounded,
                  color: AppColors.rmPrimary,
                  size: 22.sp,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.rmPrimary.withValues(alpha: 0.05),
                  padding: EdgeInsets.all(8.r),
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: () => _openWhatsApp(context, lead.phone),
                icon: Image.asset(
                  'assets/whatsapp.png',
                  width: 22.r,
                  height: 22.r,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.whatsappGreen.withValues(
                    alpha: 0.05,
                  ),
                  padding: EdgeInsets.all(8.r),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(color: AppColors.rmBorder, height: 1),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(
                Icons.phone_iphone_rounded,
                size: 16.sp,
                color: AppColors.rmMutedText,
              ),
              SizedBox(width: 6.w),
              Text(
                lead.phone,
                style: GoogleFonts.manrope(
                  color: AppColors.rmHeading,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (task != null) ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.rmSoftPink,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.rmPaleRoseBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      color: AppColors.rmHeading,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      _TaskBadge(label: task.type),
                      SizedBox(width: 7.w),
                      _TaskBadge(label: task.priority),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 16.sp,
                  color: AppColors.rmMutedText,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    'Next Follow-up: ${task.dueDateLabel}',
                    style: GoogleFonts.manrope(
                      color: task.isOverdue
                          ? AppColors.danger
                          : AppColors.rmHeading,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton(
              onPressed: task == null || isCompleting
                  ? null
                  : () => _markDone(context, task),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rmPrimary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
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
                      style: GoogleFonts.manrope(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    final messenger = ScaffoldMessenger.of(context);
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) {
      digits = '91$digits';
    }

    if (digits.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('WhatsApp number is unavailable')),
      );
      return;
    }

    final uri = Uri.parse('https://wa.me/$digits');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to open WhatsApp')),
      );
    }
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

class _TaskBadge extends StatelessWidget {
  const _TaskBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          color: AppColors.rmPrimary,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.stage});

  final String stage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.rmPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        stage.toUpperCase(),
        style: GoogleFonts.manrope(
          color: AppColors.rmPrimary,
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
