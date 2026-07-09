import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/models/leave_model.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/providers/leave_provider.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:provider/provider.dart';

enum _LeaveManagementAction { approve, reject, delete }

class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  static const Color _maroon = AppColors.primary;
  static const Color _surface = AppColors.rmSoftPink;

  bool _showManagementQueue = true;
  String? _lastRoleForDefaultTab;

  bool _isAdminRole(String? role) {
    final normalizedRole = role?.trim().toUpperCase() ?? '';
    return normalizedRole == 'ADMIN' || normalizedRole == 'OWNER';
  }

  bool _isHrRole(String? role) {
    final normalizedRole = role?.trim().toUpperCase() ?? '';
    return normalizedRole == 'HR';
  }

  bool _shouldFetchAllLeaves(String? role) {
    return _isAdminRole(role) || _isHrRole(role);
  }

  bool _canManageLeaves(String? role) {
    return _shouldFetchAllLeaves(role);
  }

  bool _canApproveLeaves(String? role) {
    return _isAdminRole(role);
  }

  bool _canOpenAdminDrawer(String? role) {
    return _isAdminRole(role) || _isHrRole(role);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showPendingLeaveActions(LeaveModel leave) async {
    final provider = context.read<LeaveProvider>();
    final token =
        context.read<AuthProvider>().userModel?.accessToken?.trim() ?? '';
    if (provider.isProcessingLeave(leave.id)) {
      return;
    }

    final action = await showModalBottomSheet<_LeaveManagementAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _LeaveActionSheet(
          onSelected: (selectedAction) {
            Navigator.of(sheetContext).pop(selectedAction);
          },
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    String? errorMessage;
    var successMessage = '';
    switch (action) {
      case _LeaveManagementAction.approve:
        errorMessage = await provider.approveLeave(leave.id, token);
        successMessage = 'Leave approved.';
        break;
      case _LeaveManagementAction.reject:
        errorMessage = await provider.rejectLeave(leave.id, token);
        successMessage = 'Leave rejected.';
        break;
      case _LeaveManagementAction.delete:
        errorMessage = await provider.deleteLeave(leave.id);
        successMessage = 'Leave application deleted.';
        break;
    }

    if (!mounted) {
      return;
    }

    _showMessage(errorMessage ?? successMessage);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final leaveProvider = context.read<LeaveProvider>();
      final user = authProvider.userModel?.user;
      leaveProvider.fetchLeaves(
        authProvider.userModel?.accessToken ?? '',
        includeAll: _shouldFetchAllLeaves(user?.role),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().userModel?.user;
    final isHrRole = _isHrRole(authUser?.role);
    final canManageLeaves = _canManageLeaves(authUser?.role);
    final canApproveLeaves = _canApproveLeaves(authUser?.role);
    final canOpenAdminDrawer = _canOpenAdminDrawer(authUser?.role);
    final currentRole = authUser?.role;
    if (_lastRoleForDefaultTab != currentRole) {
      _lastRoleForDefaultTab = currentRole;
      _showManagementQueue = canManageLeaves;
    }

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        toolbarHeight: 70.h,
        backgroundColor: AppColors.rmPrimary,
        surfaceTintColor: AppColors.rmPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 56.w,
        leading: IconButton(
          tooltip: canOpenAdminDrawer ? 'Menu' : 'Back',
          onPressed: () {
            final navigator = Navigator.of(context);
            if (canOpenAdminDrawer) {
              navigator.pushNamed(AppRoutes.adminDrawer);
              return;
            }
            navigator.maybePop();
          },
          icon: Icon(
            canOpenAdminDrawer ? Icons.menu : Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        title: Image.asset(
          'assets/app.logo.png',
          height: 70.h,
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Consumer<LeaveProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final leaves = provider.leaves.toList()
              ..sort(_compareNewestLeaves);
            final managementQueue = leaves
                .where(
                  (leave) =>
                      _isPendingStatus(leave.status) ||
                      (isHrRole && _isApprovedStatus(leave.status)),
                )
                .toList();
            final myHistory = canManageLeaves
                ? _myHistory(
                    leaves,
                    includeUnassignedLeaves: false,
                    currentUserId: authUser?.id,
                    currentUserEmail: authUser?.email,
                    currentUserName: authUser?.name,
                  )
                : leaves;
            final showManagementQueue =
                canManageLeaves && _showManagementQueue;
            final visibleLeaves = showManagementQueue
                ? managementQueue
                : myHistory;
            final statLeaves = canManageLeaves ? leaves : myHistory;

            final stats = [
              _ArchiveMetric(
                value: '${_countByStatus(statLeaves, _isPendingStatus)}',
                title: 'Pending\nRequests',
                subtitle: 'AWAITING OVERSIGHT',
                accent: const Color(0xFFE5B428),
                icon: Icons.inventory_2_outlined,
              ),
              _ArchiveMetric(
                value: '${_countByStatus(statLeaves, _isApprovedStatus)}',
                title: 'Approved Leaves',
                subtitle: 'AUTHORIZED ABSENCE',
                accent: const Color(0xFF66C66E),
                icon: Icons.check_circle_outline,
              ),
              _ArchiveMetric(
                value: '${_countByStatus(statLeaves, _isDeniedStatus)}',
                title: 'Denied Entries',
                subtitle: 'REGISTRY REJECTIONS',
                accent: const Color(0xFFE64848),
                icon: Icons.cancel_outlined,
              ),
              _ArchiveMetric(
                value: '${statLeaves.length}',
                title: 'Total Ledger',
                subtitle: 'CUMULATIVE HISTORY',
                accent: const Color(0xFFB16AE3),
                icon: Icons.menu_book_outlined,
              ),
            ];

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 28.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personnel Attendance\nArchives',
                    style: GoogleFonts.manrope(
                      fontSize: 29.sp,
                      fontWeight: FontWeight.w900,
                      color: _maroon,
                      height: 1.12,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Manage and track institutional leave requests\nwith real-time oversight.',
                    style: GoogleFonts.manrope(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6E6268),
                      height: 1.42,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _openRequestNewLeave();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _maroon,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: Size.fromHeight(48.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      icon: Icon(Icons.add, size: 18.sp),
                      label: Text(
                        'Request New Leave',
                        style: GoogleFonts.manrope(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 22.h),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stats.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      mainAxisExtent: 136.h,
                    ),
                    itemBuilder: (context, index) {
                      return _ArchiveStatCard(metric: stats[index], maroon: _maroon);
                    },
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      if (canManageLeaves)
                        Expanded(
                          child: _QueueTab(
                            label: 'Management Queue',
                            selected: showManagementQueue,
                            activeColor: _maroon,
                            onTap: () {
                              if (!_showManagementQueue) {
                                setState(() => _showManagementQueue = true);
                              }
                            },
                          ),
                        ),
                      Expanded(
                        child: _QueueTab(
                          label: 'My Leave History',
                          selected: !showManagementQueue,
                          activeColor: AppColors.primary,
                          onTap: () {
                            if (showManagementQueue) {
                              setState(() => _showManagementQueue = false);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  if (visibleLeaves.isEmpty)
                    _EmptyArchiveCard(
                      title: showManagementQueue
                          ? 'No pending leave requests available right now.'
                          : 'No leave history available for this user.',
                    )
                  else
                    Column(
                      children: [
                        for (int index = 0; index < visibleLeaves.length; index++) ...[
                          if (index > 0) SizedBox(height: 14.h),
                          _LeaveArchiveCard(
                            leave: visibleLeaves[index],
                            footerLabel: showManagementQueue
                                ? 'Requested by ${visibleLeaves[index].userName}'
                                : 'Filed by ${visibleLeaves[index].userName}',
                            dateText: _formatCardDate(visibleLeaves[index]),
                            initials: _initialsFor(visibleLeaves[index].userName),
                            statusForeground: _statusForeground(visibleLeaves[index].status),
                            statusBackground: _statusBackground(visibleLeaves[index].status),
                            leadingColor: _avatarColor(index),
                            onActionPressed:
                                showManagementQueue && canApproveLeaves
                                ? () => _showPendingLeaveActions(
                                    visibleLeaves[index],
                                  )
                                : null,
                            isActionLoading: provider.isProcessingLeave(
                              visibleLeaves[index].id,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<LeaveModel> _myHistory(
    List<LeaveModel> leaves, {
    required bool includeUnassignedLeaves,
    required String? currentUserId,
    required String? currentUserEmail,
    required String? currentUserName,
  }) {
    final normalizedId = currentUserId?.trim().toLowerCase() ?? '';
    final normalizedEmail = currentUserEmail?.trim().toLowerCase() ?? '';
    final normalizedName = currentUserName?.trim().toLowerCase() ?? '';
    if (normalizedId.isEmpty &&
        normalizedEmail.isEmpty &&
        normalizedName.isEmpty) {
      return const [];
    }
    return leaves
        .where((leave) {
          if (normalizedId.isNotEmpty &&
              leave.userId.trim().toLowerCase() == normalizedId) {
            return true;
          }
          if (normalizedEmail.isNotEmpty &&
              leave.userEmail.trim().toLowerCase() == normalizedEmail) {
            return true;
          }
          if (normalizedName.isNotEmpty &&
              leave.userName.trim().toLowerCase() == normalizedName) {
            return true;
          }
          return includeUnassignedLeaves && !_hasOwnerIdentity(leave);
        })
        .toList();
  }

  bool _hasOwnerIdentity(LeaveModel leave) {
    final hasUserId = leave.userId.trim().isNotEmpty;
    final hasUserEmail = leave.userEmail.trim().isNotEmpty;
    final normalizedName = leave.userName.trim().toLowerCase();
    final hasUserName =
        normalizedName.isNotEmpty && normalizedName != 'unknown';
    return hasUserId || hasUserEmail || hasUserName;
  }

  Future<void> _openRequestNewLeave() async {
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.requestNewLeave,
    );
    final submitted = result is bool && result;
    if (!mounted || submitted != true) {
      return;
    }
    setState(() => _showManagementQueue = false);
  }

  int _countByStatus(
    List<LeaveModel> leaves,
    bool Function(String status) predicate,
  ) {
    return leaves.where((leave) => predicate(leave.status)).length;
  }

  int _compareNewestLeaves(LeaveModel left, LeaveModel right) {
    final rightDate = right.updatedAt ?? right.createdAt ?? right.startDate;
    final leftDate = left.updatedAt ?? left.createdAt ?? left.startDate;
    final dateComparison = rightDate.compareTo(leftDate);
    if (dateComparison != 0) {
      return dateComparison;
    }
    return right.id.compareTo(left.id);
  }

  bool _isPendingStatus(String status) {
    final normalized = status.trim().toUpperCase();
    return normalized.contains('PENDING') ||
        normalized.contains('WAIT') ||
        normalized.contains('QUEUE') ||
        normalized.contains('REQUEST') ||
        normalized == 'NEW' ||
        normalized == 'SUBMITTED';
  }

  bool _isApprovedStatus(String status) {
    return status.trim().toUpperCase().contains('APPROVED');
  }

  bool _isDeniedStatus(String status) {
    final normalized = status.trim().toUpperCase();
    return normalized.contains('DENIED') || normalized.contains('REJECT');
  }

  Color _statusForeground(String status) {
    if (_isApprovedStatus(status)) {
      return const Color(0xFF56A85E);
    }
    if (_isDeniedStatus(status)) {
      return const Color(0xFFE25A5A);
    }
    return const Color(0xFFD29D15);
  }

  Color _statusBackground(String status) {
    if (_isApprovedStatus(status)) {
      return const Color(0xFFE7F7E9);
    }
    if (_isDeniedStatus(status)) {
      return const Color(0xFFFFECEC);
    }
    return const Color(0xFFFFF5D6);
  }

  Color _avatarColor(int index) {
    const colors = [
      Color(0xFFFFE1EC),
      Color(0xFFE8E7FF),
      Color(0xFFFFF0DA),
      Color(0xFFE4F6EA),
    ];
    return colors[index % colors.length];
  }

  static String _initialsFor(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'NA';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String _formatCardDate(LeaveModel leave) {
    final start = _formatDateLabel(leave.startDate);
    final end = _formatDateLabel(leave.endDate);
    if (_sameDay(leave.startDate, leave.endDate)) {
      return start;
    }
    return '$start - $end';
  }

  static bool _sameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  static String _formatDateLabel(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _ArchiveMetric {
  const _ArchiveMetric({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  final String value;
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
}

class _ArchiveStatCard extends StatelessWidget {
  const _ArchiveStatCard({required this.metric, required this.maroon});

  final _ArchiveMetric metric;
  final Color maroon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
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
            height: 3.h,
            decoration: BoxDecoration(
              color: metric.accent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          metric.value,
                          style: GoogleFonts.manrope(
                            fontSize: 35.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1F1B20),
                            height: 1,
                          ),
                        ),
                      ),
                      Icon(metric.icon, size: 20.sp, color: metric.accent),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    metric.title,
                    style: GoogleFonts.manrope(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF665A60),
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    metric.subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: metric.accent,
                      letterSpacing: 0.4,
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

class _QueueTab extends StatelessWidget {
  const _QueueTab({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(bottom: 11.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? activeColor : const Color(0xFFE7D9E0),
              width: selected ? 2.2 : 1.1,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 14.sp,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? activeColor : const Color(0xFF8A8086),
          ),
        ),
      ),
    );
  }
}

class _LeaveArchiveCard extends StatelessWidget {
  const _LeaveArchiveCard({
    required this.leave,
    required this.footerLabel,
    required this.dateText,
    required this.initials,
    required this.statusForeground,
    required this.statusBackground,
    required this.leadingColor,
    this.onActionPressed,
    this.isActionLoading = false,
  });

  final LeaveModel leave;
  final String footerLabel;
  final String dateText;
  final String initials;
  final Color statusForeground;
  final Color statusBackground;
  final Color leadingColor;
  final VoidCallback? onActionPressed;
  final bool isActionLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
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
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40.r,
                      height: 40.r,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: leadingColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        initials,
                        style: GoogleFonts.manrope(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFA33C68),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leave.userName,
                            style: GoogleFonts.manrope(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF433A3F),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            leave.userRole.replaceAll('_', ' ').toUpperCase(),
                            style: GoogleFonts.manrope(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFA3989F),
                              letterSpacing: 0.3,
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
                        color: statusBackground,
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        leave.status.toUpperCase(),
                        style: GoogleFonts.manrope(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: statusForeground,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 15.sp,
                      color: const Color(0xFF9B9097),
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        _typeLabel(leave),
                        style: GoogleFonts.manrope(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF72666D),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.event_outlined,
                      size: 15.sp,
                      color: const Color(0xFF9B9097),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      dateText,
                      style: GoogleFonts.manrope(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF72666D),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 15.sp,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        leave.reason.trim().isEmpty ? 'No description provided.' : leave.reason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: const Color(0xFFF0E4E8),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 11.h, 14.w, 11.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    footerLabel,
                    style: GoogleFonts.manrope(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF90858B),
                    ),
                  ),
                ),
                if (onActionPressed != null)
                  InkWell(
                    onTap: isActionLoading ? null : onActionPressed,
                    borderRadius: BorderRadius.circular(999.r),
                    child: Container(
                      width: 34.r,
                      height: 34.r,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4F7),
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: isActionLoading
                          ? SizedBox(
                              width: 16.r,
                              height: 16.r,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.rmPrimary,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.more_horiz_rounded,
                              size: 20.sp,
                              color: AppColors.rmPrimary,
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

  static String _typeLabel(LeaveModel leave) {
    if (leave.isHalfDay) {
      return '${leave.type} • Half-day';
    }
    return leave.type;
  }
}

class _LeaveActionSheet extends StatelessWidget {
  const _LeaveActionSheet({required this.onSelected});

  final ValueChanged<_LeaveManagementAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 18.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9C8CF),
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Pending Leave Actions',
                style: GoogleFonts.manrope(
                  color: AppColors.rmHeading,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 14.h),
              _LeaveActionTile(
                icon: Icons.check_circle_outline,
                label: 'Approve Leave',
                color: const Color(0xFF2E8B57),
                onTap: () => onSelected(_LeaveManagementAction.approve),
              ),
              SizedBox(height: 10.h),
              _LeaveActionTile(
                icon: Icons.cancel_outlined,
                label: 'Reject Leave',
                color: const Color(0xFFD16E00),
                onTap: () => onSelected(_LeaveManagementAction.reject),
              ),
              SizedBox(height: 10.h),
              _LeaveActionTile(
                icon: Icons.delete_outline,
                label: 'Delete Application',
                color: const Color(0xFFE04F5F),
                onTap: () => onSelected(_LeaveManagementAction.delete),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaveActionTile extends StatelessWidget {
  const _LeaveActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9FB),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.rmPaleRoseBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.manrope(
                  color: AppColors.rmHeading,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.rmMutedText,
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyArchiveCard extends StatelessWidget {
  const _EmptyArchiveCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 26.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 28.sp,
            color: const Color(0xFFB7A6AD),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF746970),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
