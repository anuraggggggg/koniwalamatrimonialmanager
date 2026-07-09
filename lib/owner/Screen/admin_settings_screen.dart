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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      body: SafeArea(
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.35)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 24.h, 12.w, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Settings',
                            style: GoogleFonts.manrope(
                              color: AppColors.rmPrimary,
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppColors.rmHeading,
                            size: 22.sp,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Manage organization-wide parameters, API\nintegrations, and system policies.',
                      style: GoogleFonts.manrope(
                        color: AppColors.rmBodyText,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      padding: EdgeInsets.zero,
                      labelPadding: EdgeInsets.only(right: 24.w),
                      indicatorSize: TabBarIndicatorSize.label,
                      indicatorColor: AppColors.rmPrimary,
                      dividerColor: AppColors.rmPinkBorder,
                      labelColor: AppColors.rmPrimary,
                      unselectedLabelColor: AppColors.rmHeading,
                      labelStyle: GoogleFonts.manrope(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: GoogleFonts.manrope(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: 'Payroll & HR'),
                        Tab(text: 'WhatsApp API'),
                        Tab(text: 'Email Templates'),
                      ],
                    ),
                  ],
                ),
              ),
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
            style: GoogleFonts.manrope(
              color: AppColors.rmPrimary,
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              height: 1.12,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            'Manage your Meta WhatsApp Business\nconnection and routing.',
            style: GoogleFonts.manrope(
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
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF145B31),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Using WhatsApp Business API v18.0',
                        style: GoogleFonts.manrope(
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
                  style: GoogleFonts.manrope(
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
              style: GoogleFonts.manrope(
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
                style: GoogleFonts.manrope(
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
                      textStyle: GoogleFonts.manrope(
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
                      textStyle: GoogleFonts.manrope(
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
      padding: EdgeInsets.fromLTRB(12.w, 24.h, 12.w, 24.h),
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
                  'Payroll & Incentive\nOperations',
                  style: GoogleFonts.manrope(
                    color: AppColors.rmHeading,
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.18,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Configure attendance math, payroll behavior, and\ndynamic incentive policies.',
                  style: GoogleFonts.manrope(
                    color: AppColors.rmBodyText,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 16.h),
                _SettingsActionButton(
                  icon: Icons.payments_outlined,
                  label: 'Payroll Settings',
                  filled: false,
                  onPressed: () {},
                ),
                SizedBox(height: 6.h),
                _SettingsActionButton(
                  icon: Icons.trending_up_rounded,
                  label: 'Incentive Settings',
                  filled: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          const _PolicyCard(
            icon: Icons.calendar_month_outlined,
            title: 'WORKING DAYS',
            body:
                'Standard organization week is currently defined. Attendance system will mark unchecked days as Holidays automatically.',
          ),
          SizedBox(height: 8.h),
          const _PolicyCard(
            icon: Icons.account_balance_outlined,
            title: 'DIVISOR POLICY',
            body:
                'Salary per-day rate calculation follows the global organizational policy (Fixed 30, Actual Days, or Working Days).',
          ),
          SizedBox(height: 8.h),
          const _PolicyCard(
            icon: Icons.stars_outlined,
            title: 'INCENTIVE ELIGIBILITY',
            body:
                'Centralize qualified lead rules, role-based tiers, payout percentages, and incentive cycle automation from one place.',
            premium: true,
          ),
          SizedBox(height: 18.h),
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
      painter: _DashedBorderPainter(color: AppColors.rmPinkBorder, radius: 9.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 18.h),
        child: Column(
          children: [
            Container(
              width: 29.r,
              height: 29.r,
              decoration: const BoxDecoration(
                color: Color(0xFFF8E8EF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.rmPrimary,
                size: 16.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Compensation\nAutomation Summary',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: AppColors.rmHeading,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Use the settings above to manage attendance\ncalculation rules and incentive policy\nautomation without code changes.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: AppColors.rmBodyText,
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              height: 34.h,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  textStyle: GoogleFonts.manrope(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('View Audit Logs'),
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
      height: 46.h,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18.sp),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9.r),
                ),
                textStyle: GoogleFonts.manrope(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18.sp),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9.r),
                ),
                textStyle: GoogleFonts.manrope(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({
    required this.icon,
    required this.title,
    required this.body,
    this.premium = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 10.w, 14.h),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.r,
            height: 28.r,
            decoration: const BoxDecoration(
              color: Color(0xFFF8E8EF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.rmPrimary, size: 16.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        color: AppColors.rmHeading,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
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
                          style: GoogleFonts.manrope(
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
                  style: GoogleFonts.manrope(
                    color: AppColors.rmBodyText,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 25.h),
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.rmModalClose,
              size: 20.sp,
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
              style: GoogleFonts.manrope(
                color: AppColors.rmHeading,
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
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
    borderRadius: BorderRadius.circular(9.r),
    border: Border.all(color: AppColors.rmPaleRoseBorder),
    boxShadow: const [
      BoxShadow(
        color: AppColors.rmStatShadow,
        blurRadius: 8,
        offset: Offset(0, 3),
      ),
    ],
  );
}
