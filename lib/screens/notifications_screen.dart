import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/models/app_notification.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/providers/notifications_provider.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final accessToken = context.read<AuthProvider>().userModel?.accessToken;
      context.read<NotificationsProvider>().fetchNotifications(
        accessToken,
        forceRefresh: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final notificationsProvider = context.watch<NotificationsProvider>();
    final user = authProvider.userModel?.user;
    final notifications = notificationsProvider.notifications;

    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      appBar: AppBar(
        backgroundColor: AppColors.rmPrimary,
        foregroundColor: AppColors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.inter(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              _roleLabel(user?.role ?? 'User'),
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.white.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: notificationsProvider.isLoading
                ? null
                : notificationsProvider.retry,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: notificationsProvider.retry,
          child: Builder(
            builder: (context) {
              if (notificationsProvider.isLoading && notifications.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (notificationsProvider.error != null &&
                  notifications.isEmpty) {
                return ListView(
                  padding: EdgeInsets.all(24.w),
                  children: [
                    SizedBox(height: 120.h),
                    Icon(
                      Icons.notifications_off_outlined,
                      color: AppColors.rmPrimary.withValues(alpha: 0.55),
                      size: 48.sp,
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      notificationsProvider.error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.rmPrimary,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Center(
                      child: ElevatedButton(
                        onPressed: notificationsProvider.retry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.rmPrimary,
                          foregroundColor: AppColors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
                );
              }

              if (notifications.isEmpty) {
                return ListView(
                  padding: EdgeInsets.all(24.w),
                  children: [
                    SizedBox(height: 120.h),
                    Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.rmPrimary.withValues(alpha: 0.55),
                      size: 48.sp,
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'No notifications available.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.rmPrimary,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16.w),
                itemCount: notifications.length,
                separatorBuilder: (_, index) => SizedBox(height: 10.h),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  return _NotificationCard(item: item);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    return role
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(item.priority, item.isRead);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: item.isRead
              ? AppColors.rmPaleRoseBorder
              : accent.withValues(alpha: 0.32),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.rmCardShadow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconForType(item.type), color: accent, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.inter(
                          color: AppColors.rmHeading,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    _PriorityChip(
                      label: item.priority.isEmpty ? 'normal' : item.priority,
                      color: accent,
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  item.message.isEmpty ? 'No details available.' : item.message,
                  style: GoogleFonts.inter(
                    color: AppColors.rmBodyText,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14.sp,
                      color: AppColors.rmMutedText,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        _formatDate(item.createdAt),
                        style: GoogleFonts.inter(
                          color: AppColors.rmMutedText,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!item.isRead)
                      Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle,
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

  static IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'follow_up':
      case 'follow-up':
        return Icons.event_available_outlined;
      case 'lead':
      case 'lead_assigned':
        return Icons.person_search_outlined;
      case 'payment':
        return Icons.payments_outlined;
      case 'profile':
        return Icons.account_circle_outlined;
      case 'attendance':
        return Icons.fingerprint_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  static Color _accentColor(String priority, bool isRead) {
    if (isRead) {
      return AppColors.rmPrimary;
    }

    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return const Color(0xFFB91C1C);
      case 'medium':
        return const Color(0xFFD97706);
      case 'low':
        return const Color(0xFF15803D);
      default:
        return AppColors.rmPrimary;
    }
  }

  static String _formatDate(String value) {
    if (value.trim().isEmpty) {
      return 'Recent';
    }

    final date = DateTime.tryParse(value);
    if (date == null) {
      return value;
    }

    return DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal());
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final normalized = label.trim().isEmpty ? 'normal' : label;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalized.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
