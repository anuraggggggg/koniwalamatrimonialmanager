import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(context),
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 22.h, 14.w, 0),
              child: Text(
                'Manage organization-wide parameters, API integrations, and system policies.',
                style: GoogleFonts.inter(
                  color: AppColors.rmBodyText,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 30.h),
            _buildSettingsTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _PayrollSettingsTab(),
                  _WhatsAppApiSettingsTab(),
                  _SettingsPlaceholder(
                    icon: Icons.email_outlined,
                    title: 'Email Templates',
                    subtitle:
                        'Manage organization-wide email templates and delivery defaults.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 64.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: const BoxDecoration(
        color: AppColors.rmSoftPink,
        border: Border(
          bottom: BorderSide(color: AppColors.rmHeaderDivider, width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40.w,
            child: IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.rmHeading,
                size: 23.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Settings',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.rmHeading,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 40.w),
        ],
      ),
    );
  }

  Widget _buildSettingsTabs() {
    final tabs = const [
      _SettingsTabData(icon: Icons.payments_outlined, label: 'Payroll & HR'),
      _SettingsTabData(icon: Icons.message_outlined, label: 'WhatsApp API'),
      _SettingsTabData(icon: Icons.email_outlined, label: 'Email Templates'),
    ];

    return SizedBox(
      height: 36.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          return _SettingsTabPill(
            icon: tabs[index].icon,
            label: tabs[index].label,
            selected: _tabController.index == index,
            onTap: () => _tabController.animateTo(index),
          );
        },
      ),
    );
  }
}

class _SettingsTabData {
  const _SettingsTabData({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _SettingsTabPill extends StatelessWidget {
  const _SettingsTabPill({
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
    final foreground = selected ? AppColors.white : const Color(0xFF062A52);

    return Material(
      color: selected ? AppColors.primary : AppColors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 34.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: selected
                ? null
                : Border.all(color: const Color(0xFFCBD5E1), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foreground, size: 16.sp),
              SizedBox(width: 6.w),
              Text(
                label,
                maxLines: 1,
                style: GoogleFonts.inter(
                  color: foreground,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhatsAppApiSettingsTab extends StatelessWidget {
  const _WhatsAppApiSettingsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(15.w, 22.h, 15.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WhatsApp API\nIntegration',
            style: GoogleFonts.inter(
              color: AppColors.rmPrimary,
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              height: 1.12,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            'Manage your Meta WhatsApp Business\nconnection and routing.',
            style: GoogleFonts.inter(
              color: AppColors.rmBodyText,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          SizedBox(height: 18.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(11.r),
            decoration: BoxDecoration(
              color: const Color(0xFFE9FAEF),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: const Color(0xFF9EDDB4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 31.r,
                  height: 31.r,
                  decoration: const BoxDecoration(
                    color: Color(0xFF20D66B),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.white,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 11.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'API Status: Connected',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF145B31),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Using WhatsApp Business API v18.0',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF42765A),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          _WhatsAppSettingsCard(
            icon: Icons.sync_rounded,
            title: 'Template Synchronization',
            body: 'Auto-sync WhatsApp templates from Meta\nportal.',
            buttonLabel: 'Sync Now',
            buttonIcon: Icons.sync_rounded,
            onPressed: () {},
          ),
          SizedBox(height: 12.h),
          _WhatsAppSettingsCard(
            icon: Icons.webhook_outlined,
            title: 'Webhook Endpoint',
            endpoint: 'https://api.koniwala.com/api/v1/whatsapp/webhook',
            buttonLabel: 'Copy',
            buttonIcon: Icons.copy_outlined,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Webhook endpoint copied')),
              );
            },
          ),
          SizedBox(height: 12.h),
          _WhatsAppSettingsCard(
            icon: Icons.speed_outlined,
            title: 'Message Rate Limit',
            body: 'Currently set to 100 messages/minute',
            buttonLabel: 'Configure',
            buttonIcon: Icons.settings_outlined,
            filledButton: true,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _WhatsAppSettingsCard extends StatelessWidget {
  const _WhatsAppSettingsCard({
    required this.icon,
    required this.title,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onPressed,
    this.body,
    this.endpoint,
    this.filledButton = false,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? endpoint;
  final String buttonLabel;
  final IconData buttonIcon;
  final bool filledButton;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 25.r,
                height: 25.r,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8E8EF),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.rmPrimary, size: 14.sp),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppColors.rmHeading,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (body != null) ...[
            SizedBox(height: 14.h),
            Text(
              body!,
              style: GoogleFonts.inter(
                color: AppColors.rmBodyText,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
          if (endpoint != null) ...[
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F3),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: AppColors.rmPinkBorder),
              ),
              child: Text(
                endpoint!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.rmMutedText,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            height: 31.h,
            child: filledButton
                ? ElevatedButton.icon(
                    onPressed: onPressed,
                    icon: Icon(buttonIcon, size: 15.sp),
                    label: Text(buttonLabel),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: onPressed,
                    icon: Icon(buttonIcon, size: 15.sp),
                    label: Text(buttonLabel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PayrollSettingsTab extends StatelessWidget {
  const _PayrollSettingsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 32.h),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.r),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payroll & Incentive Operations',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF062A52),
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Configure attendance math, payroll behavior, and dynamic incentive policies.',
                  style: GoogleFonts.inter(
                    color: AppColors.rmBodyText,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: _SettingsActionButton(
                        icon: Icons.payments_outlined,
                        label: 'Payroll Settings',
                        filled: false,
                        onPressed: () {},
                      ),
                    ),
                    SizedBox(width: 20.w),
                    Expanded(
                      child: _SettingsActionButton(
                        icon: Icons.trending_up_rounded,
                        label: 'Incentive Settings',
                        filled: true,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          const _PolicyCard(
            icon: Icons.calendar_month_outlined,
            iconBackground: Color(0xFFEAF3FF),
            iconColor: Color(0xFF062A52),
            title: 'WORKING DAYS',
            body:
                'Standard organization week is currently defined. Attendance system will mark unchecked days as Holidays automatically.',
          ),
          SizedBox(height: 12.h),
          const _PolicyCard(
            icon: Icons.account_balance_outlined,
            iconBackground: Color(0xFFF3EEFF),
            iconColor: Color(0xFF062A52),
            title: 'DIVISOR POLICY',
            body:
                'Salary per-day rate calculation follows the global organizational policy (Fixed 30, Actual Days, or Working Days).',
          ),
          SizedBox(height: 12.h),
          const _PolicyCard(
            icon: Icons.stars_outlined,
            iconBackground: Color(0xFFE0F9EF),
            iconColor: Color(0xFF00A878),
            title: 'INCENTIVE ELIGIBILITY',
            body:
                'Centralize qualified lead rules, role-based tiers, payout percentages, and incentive cycle automation from one place.',
            premium: true,
          ),
          SizedBox(height: 14.h),
          const _CompensationAutomationCard(),
        ],
      ),
    );
  }
}

class _CompensationAutomationCard extends StatelessWidget {
  const _CompensationAutomationCard();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(
        color: const Color(0xFFFFB899),
        radius: 18.r,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20.w, 34.h, 20.w, 24.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEFE8),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Column(
          children: [
            Container(
              width: 48.r,
              height: 48.r,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.rmPrimary,
                size: 22.sp,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'Compensation Automation Summary',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF062A52),
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Use the settings above to manage attendance calculation rules and incentive policy automation without code changes.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.rmBodyText,
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const dashLength = 4.0;
    const gapLength = 3.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashLength),
          paint,
        );
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _SettingsActionButton extends StatelessWidget {
  const _SettingsActionButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 34.h,
      child: filled
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.r),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: FittedBox(child: Text(label)),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF062A52),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.r),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: FittedBox(child: Text(label)),
            ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.body,
    this.premium = false,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String body;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(13.w, 13.h, 14.w, 15.h),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 19.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF062A52),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    if (premium) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5D8),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'PREMIUM',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF9A7100),
                            fontSize: 7.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    color: AppColors.rmBodyText,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    height: 1.45,
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

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12.r),
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: _cardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.rmPrimary, size: 34.sp),
            SizedBox(height: 12.h),
            Text(
              title,
              style: GoogleFonts.inter(
                color: AppColors.rmHeading,
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.rmBodyText,
                fontSize: 12.sp,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(10.r),
    border: Border.all(color: const Color(0xFFE8DCE0)),
    boxShadow: const [
      BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 3)),
    ],
  );
}
