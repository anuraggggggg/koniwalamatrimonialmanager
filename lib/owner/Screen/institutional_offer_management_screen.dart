import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';

class InstitutionalOfferManagementScreen extends StatelessWidget {
  const InstitutionalOfferManagementScreen({super.key, this.onMenuPressed});

  final VoidCallback? onMenuPressed;

  static const List<_OfferStat> _stats = [
    _OfferStat(
      eyebrow: 'INSTITUTIONAL\nFORMATS',
      value: '1',
      label: 'Active Templates',
      accentColor: Color(0xFF00A981),
    ),
    _OfferStat(
      eyebrow: 'ACTIVE DOCUMENT',
      value: 'Payroll\nwalkthrough\ntemplate',
      label: 'Default Template',
      accentColor: Color(0xFF2176FF),
      valueIsTitle: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      body: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.08)),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 28.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OfferTopBar(onMenuPressed: onMenuPressed),
                    SizedBox(height: 28.h),
                    Text(
                      'Institutional Offer\nManagement',
                      style: GoogleFonts.inter(
                        color: AppColors.rmPrimary,
                        fontSize: 27.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Design and standardize the documents used for offer letter delivery.',
                      style: GoogleFonts.inter(
                        color: AppColors.rmComparisonMuted,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.add, size: 22.sp),
                        label: Text(
                          'Create Template',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.rmPrimary,
                          foregroundColor: AppColors.white,
                          elevation: 8,
                          shadowColor: AppColors.rmPrimary.withOpacity(0.26),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    const _OfferStatsGrid(stats: _stats),
                    SizedBox(height: 28.h),
                    Text(
                      'Template Directory',
                      style: GoogleFonts.inter(
                        color: AppColors.rmPrimary,
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 7.h),
                    Text(
                      'Manage the available offer letter templates.',
                      style: GoogleFonts.inter(
                        color: AppColors.rmComparisonMuted,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    const _TemplateDirectoryCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferTopBar extends StatelessWidget {
  const _OfferTopBar({this.onMenuPressed});

  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38.h,
      child: Row(
        children: [
          IconButton(
            tooltip: onMenuPressed != null ? 'Menu' : 'Back',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tightFor(width: 38.w, height: 38.h),
            icon: Icon(
              onMenuPressed != null ? Icons.menu : Icons.arrow_back,
              color: AppColors.rmPrimary,
              size: 23.sp,
            ),
            onPressed: onMenuPressed ?? () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              'Institutional Offer Management',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.rmPrimary,
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          CircleAvatar(
            radius: 17.r,
            backgroundImage: const AssetImage('assets/wedding_hero 1.png'),
          ),
        ],
      ),
    );
  }
}

class _OfferStatsGrid extends StatelessWidget {
  const _OfferStatsGrid({required this.stats});

  final List<_OfferStat> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 10.w;
        final width = (constraints.maxWidth - spacing) / 2;

        return Row(
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              SizedBox(
                width: width,
                child: _OfferStatCard(stat: stats[i]),
              ),
              if (i != stats.length - 1) SizedBox(width: spacing),
            ],
          ],
        );
      },
    );
  }
}

class _OfferStatCard extends StatelessWidget {
  const _OfferStatCard({required this.stat});

  final _OfferStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 122.h,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 10.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border(top: BorderSide(color: stat.accentColor, width: 3)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.rmCardShadow,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.eyebrow,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.rmComparisonMuted,
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const Spacer(),
          Text(
            stat.value,
            maxLines: stat.valueIsTitle ? 3 : 1,
            overflow: TextOverflow.ellipsis,
            style: stat.valueIsTitle
                ? GoogleFonts.inter(
                    color: AppColors.rmPrimary,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.02,
                  )
                : GoogleFonts.inter(
                    color: AppColors.rmPrimary,
                    fontSize: 34.sp,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                  ),
          ),
          SizedBox(height: 6.h),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.rmComparisonMuted,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateDirectoryCard extends StatelessWidget {
  const _TemplateDirectoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 18.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.rmCardShadow,
            blurRadius: 12,
            offset: Offset(0, 5),
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
                  'Payroll walkthrough template',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.rmPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              const _TemplateBadge(),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Offer of employment',
            style: GoogleFonts.inter(
              color: AppColors.rmComparisonStrong,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 18.h),
          const _InfoLine(label: 'Company', value: 'Koniwala Matrimonials'),
          SizedBox(height: 11.h),
          const _InfoLine(label: 'Signatory', value: 'Sanjay Sharma'),
          SizedBox(height: 3.h),
          Text(
            'People and operations lead',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.rmPrimary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 11.h),
          const _InfoLine(label: 'Last Updated', value: '11 May 2026'),
          SizedBox(height: 24.h),
          const Divider(color: AppColors.rmPaleRoseBorder, height: 1),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _TemplateActionButton(
                  label: 'Preview',
                  filled: false,
                  onTap: () {},
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _TemplateActionButton(
                  label: 'Edit',
                  filled: true,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TemplateBadge extends StatelessWidget {
  const _TemplateBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F8),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.rmComparisonButtonBorder),
      ),
      child: Text(
        'Default',
        style: GoogleFonts.inter(
          color: AppColors.rmPrimary,
          fontSize: 11.sp,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.rmComparisonMuted,
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: AppColors.rmComparisonStrong,
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TemplateActionButton extends StatelessWidget {
  const _TemplateActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45.h,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: filled ? AppColors.rmPrimary : AppColors.white,
          foregroundColor: filled ? AppColors.white : AppColors.rmPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
            side: filled
                ? BorderSide.none
                : const BorderSide(color: AppColors.rmPrimary),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _OfferStat {
  const _OfferStat({
    required this.eyebrow,
    required this.value,
    required this.label,
    required this.accentColor,
    this.valueIsTitle = false,
  });

  final String eyebrow;
  final String value;
  final String label;
  final Color accentColor;
  final bool valueIsTitle;
}
