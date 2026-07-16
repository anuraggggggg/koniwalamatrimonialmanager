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
  static const Color _orange = Color(0xFFD76322);
  static const Color _surface = Color(0xFFFFF9F6);

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
      appBar: _PersonnelAttendanceAppBar(
        onBackPressed: () {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
            return;
          }
          if (canOpenAdminDrawer) {
            navigator.pushNamed(AppRoutes.adminDrawer);
          }
        },
      ),
      body: SafeArea(
        top: false,
        child: Consumer<LeaveProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final leaves = provider.leaves.toList()..sort(_compareNewestLeaves);
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
            final showManagementQueue = canManageLeaves && _showManagementQueue;
            final visibleLeaves = showManagementQueue
                ? managementQueue
                : myHistory;
            final statLeaves = canManageLeaves ? leaves : myHistory;
            final pendingCount = _countByStatus(statLeaves, _isPendingStatus);
            final approvedCount = _countByStatus(statLeaves, _isApprovedStatus);
            final deniedCount = _countByStatus(statLeaves, _isDeniedStatus);

            final stats = [
              _ArchiveMetric(
                value: '$pendingCount',
                title: 'Pending Requests',
                subtitle: 'up 12% from last\nmonth',
                accent: _orange,
                icon: Icons.hourglass_empty_rounded,
              ),
              _ArchiveMetric(
                value: '$deniedCount',
                title: 'Pending Requests',
                subtitle: 'created by your\nteam',
                accent: _orange,
                icon: Icons.cancel_outlined,
              ),
              _ArchiveMetric(
                value: '$approvedCount',
                title: 'Approved Leaves',
                subtitle: '10/433\ncompleted',
                accent: _orange,
                icon: Icons.check_circle_outline_rounded,
              ),
              _ArchiveMetric(
                value: '${statLeaves.length}',
                title: 'Total Ledger',
                subtitle: 'review reasons',
                accent: _orange,
                icon: Icons.cancel_outlined,
              ),
            ];

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(14.w, 22.h, 14.w, 28.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generate, review, and manage matches for your\nclients in one place.',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF23201E),
                      height: 1.55,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    height: 42.h,
                    child: ElevatedButton.icon(
                      onPressed: _openRequestNewLeave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      icon: Icon(Icons.add_rounded, size: 20.sp),
                      label: Text(
                        'REQUEST NEW LEAVE',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stats.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8.w,
                      mainAxisSpacing: 8.h,
                      mainAxisExtent: 116.h,
                    ),
                    itemBuilder: (context, index) {
                      return _ArchiveStatCard(metric: stats[index]);
                    },
                  ),
                  SizedBox(height: 22.h),
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFF0DFD7)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _QueueTab(
                                label: 'My Leave History',
                                selected: !showManagementQueue,
                                activeColor: _orange,
                                onTap: () {
                                  if (showManagementQueue) {
                                    setState(
                                      () => _showManagementQueue = false,
                                    );
                                  }
                                },
                              ),
                            ),
                            if (canManageLeaves) ...[
                              SizedBox(width: 8.w),
                              Expanded(
                                child: _QueueTab(
                                  label: 'Management queue',
                                  selected: showManagementQueue,
                                  activeColor: _orange,
                                  onTap: () {
                                    if (!_showManagementQueue) {
                                      setState(
                                        () => _showManagementQueue = true,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 12.h),
                        if (visibleLeaves.isEmpty)
                          _EmptyArchiveCard(
                            title: showManagementQueue
                                ? 'No pending leave requests available right now.'
                                : 'No leave history available for this user.',
                          )
                        else
                          Column(
                            children: [
                              for (
                                int index = 0;
                                index < visibleLeaves.length;
                                index++
                              ) ...[
                                if (index > 0) SizedBox(height: 12.h),
                                _LeaveArchiveCard(
                                  leave: visibleLeaves[index],
                                  statusForeground: _statusForeground(
                                    visibleLeaves[index].status,
                                  ),
                                  statusBackground: _statusBackground(
                                    visibleLeaves[index].status,
                                  ),
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
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /*
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
                    style: GoogleFonts.inter(
                      fontSize: 29.sp,
                      fontWeight: FontWeight.w900,
                      color: _maroon,
                      height: 1.12,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Manage and track institutional leave requests\nwith real-time oversight.',
                    style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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
  */

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
    return leaves.where((leave) {
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
    }).toList();
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
    final result = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.requestNewLeave);
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
}

class _PersonnelAttendanceAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _PersonnelAttendanceAppBar({required this.onBackPressed});

  final VoidCallback onBackPressed;

  @override
  Size get preferredSize => Size.fromHeight(64.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64.h,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      shadowColor: AppColors.transparent,
      leadingWidth: 54.w,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: onBackPressed,
        icon: Icon(
          Icons.arrow_back_rounded,
          color: const Color(0xFF171412),
          size: 24.sp,
        ),
      ),
      title: Text(
        'Personnel Attendance',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: const Color(0xFF171412),
          fontSize: 21.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Container(height: 1.h, color: const Color(0xFFE7DCD5)),
      ),
    );
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
  const _ArchiveStatCard({required this.metric});

  final _ArchiveMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFF0DFD7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF33302D),
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            metric.value,
            style: GoogleFonts.inter(
              fontSize: 23.sp,
              fontWeight: FontWeight.w900,
              color: metric.accent,
              height: 1,
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  metric.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF35302D),
                    height: 1.12,
                  ),
                ),
              ),
              Icon(
                metric.icon,
                size: 18.sp,
                color: _metricIconColor(metric.icon),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _metricIconColor(IconData icon) {
    if (icon == Icons.check_circle_outline_rounded) {
      return const Color(0xFF00A36A);
    }
    if (icon == Icons.hourglass_empty_rounded) {
      return const Color(0xFFE5B428);
    }
    return const Color(0xFFE1222E);
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
    return SizedBox(
      height: 38.h,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11.r),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(11.r),
            border: Border.all(color: const Color(0xFFD76322)),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : const Color(0xFF2C2522),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaveArchiveCard extends StatelessWidget {
  const _LeaveArchiveCard({
    required this.leave,
    required this.statusForeground,
    required this.statusBackground,
    this.onActionPressed,
    this.isActionLoading = false,
  });

  final LeaveModel leave;
  final Color statusForeground;
  final Color statusBackground;
  final VoidCallback? onActionPressed;
  final bool isActionLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 14.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFF0DFD7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 9,
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
                  _typeLabel(leave),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1F1C19),
                  ),
                ),
              ),
              Icon(
                Icons.visibility_outlined,
                color: const Color(0xFF4A4E5C),
                size: 20.sp,
              ),
              SizedBox(width: 18.w),
              InkWell(
                onTap: isActionLoading ? null : onActionPressed,
                borderRadius: BorderRadius.circular(8.r),
                child: isActionLoading
                    ? SizedBox(
                        width: 18.sp,
                        height: 18.sp,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.edit_rounded,
                        color: const Color(0xFF4A4E5C),
                        size: 20.sp,
                      ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                color: const Color(0xFF5F5B62),
                size: 15.sp,
              ),
              SizedBox(width: 4.w),
              Text(
                _durationLabel(leave),
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF5F5B62),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999.r),
                  border: Border.all(color: statusForeground),
                ),
                child: Text(
                  _statusLabel(leave.status),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: statusForeground,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FB),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'Reason: ${leave.reason.trim().isEmpty ? 'No description provided.' : leave.reason}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF4F4750),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _typeLabel(LeaveModel leave) {
    if (leave.isHalfDay) {
      return leave.type;
    }
    return leave.type;
  }

  static String _durationLabel(LeaveModel leave) {
    if (leave.isHalfDay) {
      return '0.5 Day';
    }
    final days = leave.endDate.difference(leave.startDate).inDays + 1;
    return '$days ${days == 1 ? 'Day' : 'Days'}';
  }

  static String _statusLabel(String status) {
    final normalized = status.trim().toUpperCase();
    if (normalized.contains('REJECT')) {
      return 'DENIED';
    }
    if (normalized.isEmpty) {
      return 'PENDING';
    }
    return normalized;
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
                style: GoogleFonts.inter(
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
                style: GoogleFonts.inter(
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
            style: GoogleFonts.inter(
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
