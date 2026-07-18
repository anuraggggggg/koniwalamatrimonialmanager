import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/owner/models/registry_profile_item.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/providers/match_history_provider.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key, this.profile});

  final RegistryProfileItem? profile;

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  String? _requestedHistoryProfileId;
  String? _requestedHistoryToken;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final profileId = widget.profile?.originalId.trim() ?? '';
    final accessToken = context.watch<AuthProvider>().userModel?.accessToken;
    if (profileId.isEmpty ||
        (_requestedHistoryProfileId == profileId &&
            _requestedHistoryToken == accessToken)) {
      return;
    }

    _requestedHistoryProfileId = profileId;
    _requestedHistoryToken = accessToken;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<MatchHistoryProvider>().fetchMatchHistory(
        profileId: profileId,
        accessToken: accessToken,
        page: 1,
        limit: 20,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayProfile = _ProfileDetailViewData.fromProfile(widget.profile);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1.05)),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomInset + 28.h),
            child: Column(
              children: [
                _ProfileHeaderSection(profile: displayProfile),
                SizedBox(height: 12.h),
                _ProfileHeroImage(profile: displayProfile),
                SizedBox(height: 16.h),
                _ProfileIntroSection(profile: displayProfile),
                SizedBox(height: 20.h),
                _ProfileFactsCard(profile: displayProfile),
                SizedBox(height: 14.h),
                _ProfileActionsSection(
                  profile: displayProfile,
                  sourceProfile: widget.profile,
                ),
                SizedBox(height: 22.h),
                _PersonalNarrativeSection(profile: displayProfile),
                SizedBox(height: 22.h),
                _EducationProfessionSection(profile: displayProfile),
                SizedBox(height: 20.h),
                _KeyDetailsSection(profile: displayProfile),
                SizedBox(height: 20.h),
                _ShortlistHistorySection(sourceProfile: widget.profile),
                SizedBox(height: 22.h),
                _FamilyBackgroundSection(profile: displayProfile),
                SizedBox(height: 22.h),
                _PhotoGallerySection(profile: displayProfile),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeaderSection extends StatelessWidget {
  const _ProfileHeaderSection({required this.profile});

  final _ProfileDetailViewData profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF3E5E9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32.w,
            height: 32.w,
            child: IconButton(
              tooltip: 'Back',
              padding: EdgeInsets.zero,
              splashRadius: 18.r,
              onPressed: () => Navigator.maybePop(context),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.maroonPrimary,
                size: 20.sp,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'View Profile',
                  style: GoogleFonts.inter(
                    color: AppColors.maroonPrimary,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'REF: #${profile.reference}',
                  style: GoogleFonts.inter(
                    color: AppColors.maroonPrimary,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 32.w,
            height: 32.w,
            child: IconButton(
              padding: EdgeInsets.zero,
              splashRadius: 18.r,
              onPressed: () => Navigator.maybePop(context),
              icon: Icon(
                Icons.close_rounded,
                color: AppColors.rmSubtleRoseText,
                size: 18.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroImage extends StatelessWidget {
  const _ProfileHeroImage({required this.profile});

  final _ProfileDetailViewData profile;

  @override
  Widget build(BuildContext context) {
    final heroImage = profile.galleryImages.isNotEmpty
        ? profile.galleryImages.first
        : profile.image;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: _ProfileImageView(
              image: heroImage,
              height: 264.h,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned(
            top: 10.h,
            right: 10.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const _ActiveMemberBadge(),
                SizedBox(height: 8.h),
                _PhotoManagerBadge(
                  managerName: profile.assignedRmName == '-'
                      ? 'Not assigned'
                      : profile.assignedRmName,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveMemberBadge extends StatelessWidget {
  const _ActiveMemberBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF5C94B),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ACTIVE MEMBER',
            style: GoogleFonts.inter(
              color: const Color(0xFF4F4312),
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          SizedBox(width: 5.w),
          Icon(
            Icons.check_circle_rounded,
            color: const Color(0xFF7B6618),
            size: 13.sp,
          ),
        ],
      ),
    );
  }
}

class _PhotoManagerBadge extends StatelessWidget {
  const _PhotoManagerBadge({required this.managerName});

  final String managerName;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 260.w),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: const Color(0xF7FFFFFF),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFE9D5DA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.support_agent_rounded,
            color: AppColors.maroonPrimary,
            size: 14.sp,
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              'RM: $managerName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AppColors.maroonPrimary,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileIntroSection extends StatelessWidget {
  const _ProfileIntroSection({required this.profile});

  final _ProfileDetailViewData profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 26.w),
      child: Column(
        children: [
          Text(
            profile.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.maroonPrimary,
              fontSize: 28.sp,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            profile.summary,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF56525A),
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileFactsCard extends StatelessWidget {
  const _ProfileFactsCard({required this.profile});

  final _ProfileDetailViewData profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 18.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFF0DDE4)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Container(width: 1, color: const Color(0xFFF4EDF0)),
              ),
            ),
            Column(
              children: [
                _ProfileFactRow(
                  left: _ProfileFact(
                    label: 'DATE OF BIRTH',
                    value: profile.dateOfBirth,
                  ),
                  right: _ProfileFact(
                    label: 'BIRTH TIME',
                    value: profile.birthTime,
                  ),
                ),
                SizedBox(height: 26.h),
                _ProfileFactRow(
                  left: _ProfileFact(
                    label: 'BIRTH PLACE',
                    value: profile.birthPlace,
                  ),
                  right: _ProfileFact(label: 'HEIGHT', value: profile.height),
                ),
                SizedBox(height: 28.h),
                _ProfileFactRow(
                  left: _ProfileFact(label: 'GOTRA', value: profile.gotra),
                  right: _ProfileFact(
                    label: 'RESIDENTIAL',
                    value: profile.residential,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        color: const Color(0xFF70666D),
        fontSize: 10.sp,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        color: AppColors.maroonPrimary,
        fontSize: 24.sp,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
        height: 1.08,
      ),
    );
  }
}

class _ProfileFactRow extends StatelessWidget {
  const _ProfileFactRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        SizedBox(width: 34.w),
        Expanded(child: right),
      ],
    );
  }
}

class _ProfileFact extends StatelessWidget {
  const _ProfileFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: const Color(0xFF544E54),
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: AppColors.maroonPrimary,
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            height: 1.28,
          ),
        ),
      ],
    );
  }
}

class _PersonalNarrativeSection extends StatelessWidget {
  const _PersonalNarrativeSection({required this.profile});

  final _ProfileDetailViewData profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionEyebrow(label: 'PERSONAL NARRATIVE'),
        SizedBox(height: 8.h),
        _SectionHeading(title: profile.aboutTitle),
        SizedBox(height: 14.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 18.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.rmPaleRoseBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Text(
                    profile.narrativeInitial,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFE2B743),
                      fontSize: 42.sp,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      height: 0.9,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    profile.narrativeBody,
                    style: GoogleFonts.inter(
                      color: AppColors.rmSubtleRoseText,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
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

class _EducationProfessionSection extends StatelessWidget {
  const _EducationProfessionSection({required this.profile});

  final _ProfileDetailViewData profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionHeading(title: 'Education & Profession'),
        SizedBox(height: 14.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 18.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBFC),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.rmPaleRoseBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8.r,
                      height: 8.r,
                      margin: EdgeInsets.only(top: 7.h),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3A3438),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Current Role',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF353137),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(left: 20.w, top: 8.h),
                  child: Text(
                    profile.currentRole,
                    style: GoogleFonts.inter(
                      color: AppColors.rmPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Education',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF353137),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Academic Background',
                  style: GoogleFonts.inter(
                    color: AppColors.rmPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  profile.education,
                  style: GoogleFonts.inter(
                    color: AppColors.rmMutedText,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
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

class _KeyDetailsSection extends StatelessWidget {
  const _KeyDetailsSection({required this.profile});

  final _ProfileDetailViewData profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 18.h),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  color: const Color(0xFFE1B645),
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Key Details',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFE1B645),
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    height: 1.05,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Divider(color: AppColors.white.withValues(alpha: 0.18), height: 1),
            _KeyDetailRow(
              label: 'RELIGION / CASTE',
              value: profile.religionCaste,
            ),
            _KeyDetailRow(label: 'BIRTH PLACE', value: profile.birthPlace),
            _KeyDetailRow(label: 'GOTRA', value: profile.gotra),
            _KeyDetailRow(label: 'DIET', value: profile.diet),
            _KeyDetailRow(label: 'HOROSCOPE', value: profile.horoscope),
            if (profile.assignedRmName != '-')
              _KeyDetailRow(
                label: 'RELATIONSHIP MANAGER',
                value: profile.assignedRmName,
              ),
            if (profile.clientStatus != '-')
              _KeyDetailRow(
                label: 'CLIENT STATUS',
                value: profile.clientStatus,
              ),
            if (profile.shortlistLabel.isNotEmpty)
              _KeyDetailRow(label: 'SHORTLIST', value: profile.shortlistLabel),
            _KeyDetailRow(
              label: 'COUNTRY',
              value: profile.country,
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyDetailRow extends StatelessWidget {
  const _KeyDetailRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFF2C23C),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(color: AppColors.white.withValues(alpha: 0.14), height: 1),
      ],
    );
  }
}

class _ShortlistHistorySection extends StatelessWidget {
  const _ShortlistHistorySection({required this.sourceProfile});

  final RegistryProfileItem? sourceProfile;

  @override
  Widget build(BuildContext context) {
    final profileId = sourceProfile?.originalId.trim() ?? '';
    if (profileId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 16.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBFC),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.rmPaleRoseBorder),
        ),
        child: Consumer<MatchHistoryProvider>(
          builder: (context, history, _) {
            final belongsToProfile = history.profileId == profileId;
            final isLoading = history.isLoading || !belongsToProfile;
            final summary = belongsToProfile
                ? history.summary
                : const <String, dynamic>{};
            final rows = belongsToProfile ? history.timeline : const [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      color: AppColors.maroonPrimary,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Shortlist History',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppColors.maroonPrimary,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh history',
                      visualDensity: VisualDensity.compact,
                      onPressed: history.isLoading
                          ? null
                          : () {
                              final token = context
                                  .read<AuthProvider>()
                                  .userModel
                                  ?.accessToken;
                              context
                                  .read<MatchHistoryProvider>()
                                  .fetchMatchHistory(
                                    profileId: profileId,
                                    accessToken: token,
                                    page: 1,
                                    limit: 20,
                                  );
                            },
                      icon: Icon(Icons.refresh_rounded, size: 18.sp),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _ShortlistHistorySummary(summary: summary),
                if (isLoading) ...[
                  SizedBox(height: 14.h),
                  const LinearProgressIndicator(minHeight: 2),
                ] else if (history.error != null) ...[
                  SizedBox(height: 14.h),
                  _ShortlistHistoryMessage(message: history.error!),
                ] else if (rows.isEmpty) ...[
                  SizedBox(height: 14.h),
                  const _ShortlistHistoryMessage(
                    message: 'No shortlist history has been sent yet.',
                  ),
                ] else ...[
                  SizedBox(height: 14.h),
                  for (var index = 0; index < rows.length; index++) ...[
                    _ShortlistHistoryTimelineItem(row: rows[index]),
                    if (index != rows.length - 1)
                      Divider(height: 16.h, color: AppColors.rmPaleRoseBorder),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ShortlistHistorySummary extends StatelessWidget {
  const _ShortlistHistorySummary({required this.summary});

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _HistoryMetric('Sent', _asInt(summary['totalSent'])),
      _HistoryMetric('Manual', _asInt(summary['manualShortlisted'])),
      _HistoryMetric('AI', _asInt(summary['aiShortlisted'])),
      _HistoryMetric('Approved', _asInt(summary['totalApproved'])),
      _HistoryMetric('Accepted', _asInt(summary['totalAccepted'])),
      _HistoryMetric('Rejected', _asInt(summary['totalRejected'])),
    ];
    final lastSentDate = _formatHistoryDate(summary['lastSentDate']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 16.w) / 3;

            return Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: metrics
                  .map((metric) => _HistoryMetricChip(metric: metric))
                  .map((child) => SizedBox(width: itemWidth, child: child))
                  .toList(),
            );
          },
        ),
        if (lastSentDate != '-') ...[
          SizedBox(height: 10.h),
          Text(
            'Last sent on $lastSentDate',
            style: GoogleFonts.inter(
              color: AppColors.rmMutedText,
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _HistoryMetricChip extends StatelessWidget {
  const _HistoryMetricChip({required this.metric});

  final _HistoryMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFF0DDE4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${metric.value}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.maroonPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.rmBodyText,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortlistHistoryMessage extends StatelessWidget {
  const _ShortlistHistoryMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFF0DDE4)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: AppColors.rmMutedText,
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    );
  }
}

class _ShortlistHistoryTimelineItem extends StatelessWidget {
  const _ShortlistHistoryTimelineItem({required this.row});

  final dynamic row;

  @override
  Widget build(BuildContext context) {
    final item = _asMap(row);
    final candidate = _firstMap([
      item['candidateProfile'],
      item['candidate'],
      item['matchedProfile'],
      item['shortlistedProfile'],
      item['profile'],
      item['toProfile'],
      item['receiverProfile'],
    ]);
    final name = _firstText([
      item['candidateName'],
      item['profileName'],
      item['matchedProfileName'],
      candidate['name'],
      item['name'],
    ], fallback: 'Shortlisted profile');
    final status = _formatHistoryLabel(
      _firstText([
        item['status'],
        item['decision'],
        item['outcome'],
        item['action'],
      ], fallback: 'Sent'),
    );
    final source = _formatHistoryLabel(
      _firstText([
        item['source'],
        item['type'],
        item['shortlistType'],
        item['createdByType'],
      ], fallback: 'Shortlist'),
    );
    final date = _formatHistoryDate(
      _firstText([
        item['sentAt'],
        item['createdAt'],
        item['updatedAt'],
        item['date'],
      ], fallback: ''),
    );
    final note = _firstText([
      item['note'],
      item['notes'],
      item['reason'],
      item['message'],
      item['comment'],
    ], fallback: '');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30.r,
          height: 30.r,
          decoration: BoxDecoration(
            color: const Color(0xFFF6EEF2),
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: AppColors.rmPaleRoseBorder),
          ),
          child: Icon(
            Icons.bookmark_added_outlined,
            color: AppColors.maroonPrimary,
            size: 15.sp,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.black,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                [source, status, date]
                    .where((value) => value.trim().isNotEmpty && value != '-')
                    .join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.rmBodyText,
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (note.isNotEmpty) ...[
                SizedBox(height: 5.h),
                Text(
                  note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.rmMutedText,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
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

class _HistoryMetric {
  const _HistoryMetric(this.label, this.value);

  final String label;
  final int value;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return const {};
}

Map<String, dynamic> _firstMap(List<dynamic> values) {
  for (final value in values) {
    final map = _asMap(value);
    if (map.isNotEmpty) {
      return map;
    }
  }

  return const {};
}

String _firstText(List<dynamic> values, {String fallback = '-'}) {
  for (final value in values) {
    if (value == null) {
      continue;
    }

    final text = value.toString().trim();
    if (text.isNotEmpty && text != 'null') {
      return text;
    }
  }

  return fallback;
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatHistoryLabel(String value) {
  final text = value.trim();
  if (text.isEmpty || text == '-') {
    return '-';
  }

  return text
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) {
        final lower = part.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

String _formatHistoryDate(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty || text == 'null') {
    return '-';
  }

  final parsed = DateTime.tryParse(text);
  if (parsed == null) {
    return text;
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
  final local = parsed.toLocal();
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

class _FamilyBackgroundSection extends StatelessWidget {
  const _FamilyBackgroundSection({required this.profile});

  final _ProfileDetailViewData profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionHeading(title: 'Family Background'),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: _FamilySideCard(
            side: 'FATHER\'S SIDE',
            name: profile.fatherSide,
            relatives: [
              _FamilyRelative(label: 'Grandfather', value: profile.grandfather),
              _FamilyRelative(label: 'Grandmother', value: profile.grandmother),
              _FamilyRelative(label: 'Bua', value: profile.bua),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: _FamilySideCard(
            side: 'MOTHER\'S SIDE',
            name: profile.motherSide,
            relatives: [
              _FamilyRelative(
                label: 'Grandfather (Nanaji)',
                value: profile.maternalGrandfather,
              ),
              _FamilyRelative(
                label: 'Grandmother',
                value: profile.maternalGrandmother,
              ),
              _FamilyRelative(label: 'Uncle', value: profile.uncle),
            ],
          ),
        ),
      ],
    );
  }
}

class _FamilySideCard extends StatelessWidget {
  const _FamilySideCard({
    required this.side,
    required this.name,
    required this.relatives,
  });

  final String side;
  final String name;
  final List<_FamilyRelative> relatives;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF2C23C),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    side,
                    style: GoogleFonts.inter(
                      color: AppColors.rmBodyText,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      color: AppColors.maroonPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ...relatives.expand(
                    (relative) => [
                      _FamilyLine(label: relative.label, value: relative.value),
                      SizedBox(height: 8.h),
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

class _FamilyRelative {
  const _FamilyRelative({required this.label, required this.value});

  final String label;
  final String value;
}

class _FamilyLine extends StatelessWidget {
  const _FamilyLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          color: AppColors.rmBodyText,
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
        children: [
          TextSpan(
            text: '$label : ',
            style: GoogleFonts.inter(
              color: AppColors.maroonPrimary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _PhotoGallerySection extends StatelessWidget {
  const _PhotoGallerySection({required this.profile});

  final _ProfileDetailViewData profile;

  @override
  Widget build(BuildContext context) {
    final galleryImages = profile.galleryImages;
    final galleryPronoun = profile.aboutTitle.endsWith('Her') ? 'HER' : 'HIS';

    return Column(
      children: [
        const _SectionHeading(title: 'Photo Gallery'),
        SizedBox(height: 8.h),
        Text(
          'A GLIMPSE INTO $galleryPronoun LIFE AND PASSIONS.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.rmSubtleRoseText,
            fontSize: 10.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 18.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: GestureDetector(
            onTap: () => _showGalleryImage(context, 0, galleryImages),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: _ProfileImageView(
                image: galleryImages.first,
                height: 298.h,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
        ),
        if (galleryImages.length > 1) ...[
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 10.w) / 2;
                final remainingImages = galleryImages.skip(1).take(2).toList();

                return Wrap(
                  spacing: 10.w,
                  runSpacing: 10.h,
                  children: [
                    for (var index = 0; index < remainingImages.length; index++)
                      GestureDetector(
                        onTap: () => _showGalleryImage(
                          context,
                          index + 1,
                          galleryImages,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2.r),
                          child: SizedBox(
                            width: itemWidth,
                            height: 108.h,
                            child: _ProfileImageView(
                              image: remainingImages[index],
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  void _showGalleryImage(
    BuildContext context,
    int initialIndex,
    List<String> galleryImages,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.86),
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 28.h),
          backgroundColor: AppColors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: SizedBox(
                  width: double.infinity,
                  height: 620.h,
                  child: PageView.builder(
                    controller: PageController(initialPage: initialIndex),
                    itemCount: galleryImages.length,
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: _ProfileImageView(
                          image: galleryImages[index],
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 8.h,
                right: 8.w,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.black.withValues(alpha: 0.58),
                    foregroundColor: AppColors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, size: 22.sp),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileActionsSection extends StatelessWidget {
  const _ProfileActionsSection({required this.profile, this.sourceProfile});

  final _ProfileDetailViewData profile;
  final RegistryProfileItem? sourceProfile;

  Future<void> _downloadPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text('Generating profile PDF...')),
    );

    try {
      final file = await _ProfilePdfService.generate(profile);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('PDF saved to ${file.path}'),
            duration: const Duration(seconds: 4),
          ),
        );
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Unable to download profile PDF.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(
        children: [
          Expanded(
            child: _ProfileActionButton(
              icon: Icons.edit,
              label: 'Edit Profile',
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamed(AppRoutes.editProfile, arguments: sourceProfile);
              },
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: _ProfileActionButton(
              icon: Icons.file_download_outlined,
              label: 'Download PDF',
              onPressed: () => _downloadPdf(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x17000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 13.sp),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: Size(0, 40.h),
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ProfileImageView extends StatelessWidget {
  const _ProfileImageView({
    required this.image,
    required this.fit,
    required this.alignment,
    this.height,
  });

  final String image;
  final BoxFit fit;
  final Alignment alignment;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (image.startsWith('http')) {
      return Image.network(
        image,
        height: height,
        width: double.infinity,
        fit: fit,
        alignment: alignment,
        errorBuilder: (context, error, stackTrace) => _FallbackProfileImage(
          fit: fit,
          alignment: alignment,
          height: height,
        ),
      );
    }

    return Image.asset(
      image,
      height: height,
      width: double.infinity,
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) =>
          _FallbackProfileImage(fit: fit, alignment: alignment, height: height),
    );
  }
}

class _FallbackProfileImage extends StatelessWidget {
  const _FallbackProfileImage({
    required this.fit,
    required this.alignment,
    this.height,
  });

  final BoxFit fit;
  final Alignment alignment;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/wedding_hero 1.png',
      height: height,
      width: double.infinity,
      fit: fit,
      alignment: alignment,
    );
  }
}

class _ProfilePdfService {
  static Future<File> generate(_ProfileDetailViewData profile) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Text(
            profile.name,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Reference: ${profile.reference}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            profile.summary,
            style: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
          ),
          pw.SizedBox(height: 18),
          _buildSection('Personal Details', [
            _PdfField('Date of Birth', profile.dateOfBirth),
            _PdfField('Birth Time', profile.birthTime),
            _PdfField('Birth Place', profile.birthPlace),
            _PdfField('Height', profile.height),
            _PdfField('Gotra', profile.gotra),
            _PdfField('Residential', profile.residential),
            _PdfField('Religion / Caste', profile.religionCaste),
            _PdfField('Diet', profile.diet),
            _PdfField('Horoscope', profile.horoscope),
            _PdfField('Country', profile.country),
          ]),
          _buildSection('About', [
            _PdfField(
              profile.aboutTitle,
              '${profile.narrativeInitial}${profile.narrativeBody}',
            ),
          ]),
          _buildSection('Education & Profession', [
            _PdfField('Current Role', profile.currentRole),
            _PdfField('Education', profile.education),
          ]),
          _buildSection('Family Background', [
            _PdfField('Father Side', profile.fatherSide),
            _PdfField('Grandfather', profile.grandfather),
            _PdfField('Grandmother', profile.grandmother),
            _PdfField('Bua', profile.bua),
            _PdfField('Mother Side', profile.motherSide),
            _PdfField('Maternal Grandfather', profile.maternalGrandfather),
            _PdfField('Maternal Grandmother', profile.maternalGrandmother),
            _PdfField('Uncle', profile.uncle),
          ]),
        ],
      ),
    );

    final directory = await _resolveDirectory();
    final filename = _sanitizeFileName('${profile.name}_${profile.reference}');
    final file = File(
      '${directory.path}${Platform.pathSeparator}$filename.pdf',
    );
    await file.writeAsBytes(await document.save(), flush: true);
    return file;
  }

  static pw.Widget _buildSection(String title, List<_PdfField> fields) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          color: PdfColors.grey200,
          child: pw.Text(
            title,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 8),
        ...fields.map(_buildField),
        pw.SizedBox(height: 14),
      ],
    );
  }

  static pw.Widget _buildField(_PdfField field) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.RichText(
        text: pw.TextSpan(
          style: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
          children: [
            pw.TextSpan(
              text: '${field.label}: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(text: field.value),
          ],
        ),
      ),
    );
  }

  static Future<Directory> _resolveDirectory() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final externalDirectory = await getExternalStorageDirectory();
        if (externalDirectory != null) {
          final directory = Directory(
            '${externalDirectory.path}${Platform.pathSeparator}profile_pdfs',
          );
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          return directory;
        }
      }

      final downloadsDirectory = await getDownloadsDirectory();
      if (downloadsDirectory != null) {
        final directory = Directory(
          '${downloadsDirectory.path}${Platform.pathSeparator}profile_pdfs',
        );
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        return directory;
      }
    } catch (_) {}

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}profile_pdfs',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  static String _sanitizeFileName(String value) {
    final sanitized = value
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*]+'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    return sanitized.isEmpty ? 'profile' : sanitized;
  }
}

class _PdfField {
  const _PdfField(this.label, this.value);

  final String label;
  final String value;
}

class _ProfileDetailViewData {
  const _ProfileDetailViewData({
    required this.reference,
    required this.name,
    required this.summary,
    required this.image,
    required this.dateOfBirth,
    required this.birthTime,
    required this.birthPlace,
    required this.height,
    required this.gotra,
    required this.residential,
    required this.aboutTitle,
    required this.narrativeInitial,
    required this.narrativeBody,
    required this.currentRole,
    required this.education,
    required this.religionCaste,
    required this.diet,
    required this.horoscope,
    required this.country,
    required this.fatherSide,
    required this.grandfather,
    required this.grandmother,
    required this.bua,
    required this.motherSide,
    required this.maternalGrandfather,
    required this.maternalGrandmother,
    required this.uncle,
    required this.galleryImages,
    this.assignedRmName = '-',
    this.clientStatus = '-',
    this.shortlistLabel = '',
  });

  final String reference;
  final String name;
  final String summary;
  final String image;
  final String dateOfBirth;
  final String birthTime;
  final String birthPlace;
  final String height;
  final String gotra;
  final String residential;
  final String aboutTitle;
  final String narrativeInitial;
  final String narrativeBody;
  final String currentRole;
  final String education;
  final String religionCaste;
  final String diet;
  final String horoscope;
  final String country;
  final String fatherSide;
  final String grandfather;
  final String grandmother;
  final String bua;
  final String motherSide;
  final String maternalGrandfather;
  final String maternalGrandmother;
  final String uncle;
  final List<String> galleryImages;
  final String assignedRmName;
  final String clientStatus;
  final String shortlistLabel;

  factory _ProfileDetailViewData.fromProfile(RegistryProfileItem? profile) {
    if (profile == null) {
      return const _ProfileDetailViewData(
        reference: 'WA-6C6D',
        name: 'Aaryan Lalit Punamiya',
        summary:
            'Currently handling entire sales of USA market in Family business',
        image: 'assets/wedding_hero 1.png',
        dateOfBirth: '09 Dec 2000',
        birthTime: '08:01 AM',
        birthPlace: 'Mumbai',
        height: '5\'10"',
        gotra: 'Punamilya And Gundecha',
        residential: 'Mumbai',
        aboutTitle: 'About Him',
        narrativeInitial: 'A',
        narrativeBody:
            'ryan is social and fun loving . He gives lot of value to relationships with family and friends.',
        currentRole:
            'Currently handling entire sales of USA market in Family business',
        education: 'MSC from Westminster London',
        religionCaste: 'Jain, JAIN',
        diet: 'Vegetarian',
        horoscope: 'Non-Manglik',
        country: 'India',
        fatherSide: 'Shri Lalit Punamiya',
        grandfather: 'Shri Navratna Mulchandji Punamiya',
        grandmother: 'Smt. Vimla Navratnaji Punamiya',
        bua: 'Smt. Sonal Khimesra',
        motherSide: 'Smt. Pallavi Punamiya',
        maternalGrandfather: 'Late Shri Hastira ji Gundecha',
        maternalGrandmother: 'Late Smt. Meena Hastira ji Gundecha',
        uncle: 'Shri Paras Gundecha',
        galleryImages: [
          'assets/wedding_hero 1.png',
          'assets/wedding_hero 1.png',
          'assets/wedding_hero 1.png',
        ],
        assignedRmName: '-',
        clientStatus: '-',
        shortlistLabel: '',
      );
    }

    final firstName = _firstName(profile.name);
    final aboutPronoun = profile.type == 'Bride' ? 'Her' : 'Him';
    final currentRole = _currentRoleFor(profile);
    final fallbackAbout = firstName.isEmpty
        ? 'Profile details are available for review.'
        : '$firstName is social and fun loving. '
              '${profile.type == 'Bride' ? 'She' : 'He'} gives a lot of value to relationships with family and friends.';
    final aboutText = _fallback(profile.aboutMe, fallbackAbout);

    return _ProfileDetailViewData(
      reference: profile.id,
      name: profile.name,
      summary: _summaryFor(profile),
      image: profile.image,
      dateOfBirth: profile.dateOfBirth,
      birthTime: profile.birthTime,
      birthPlace: profile.birthPlace,
      height: profile.height,
      gotra: profile.gotra,
      residential: profile.residential,
      aboutTitle: 'About $aboutPronoun',
      narrativeInitial: aboutText.isEmpty ? 'A' : aboutText[0].toUpperCase(),
      narrativeBody: aboutText.length <= 1 ? '' : aboutText.substring(1),
      currentRole: currentRole,
      education: _fallback(profile.profession, 'Academic background not added'),
      religionCaste: _religionCaste(profile),
      diet: _fallback(profile.diet, '-'),
      horoscope: _fallback(profile.manglikLabel, '-'),
      country: _fallback(profile.country, '-'),
      fatherSide: _fallback(profile.fatherName, 'Family details not added'),
      grandfather: _detailValue(profile.paternalDetails, const ['Grandfather']),
      grandmother: _detailValue(profile.paternalDetails, const ['Grandmother']),
      bua: _detailValue(profile.paternalDetails, const ['Bua', 'Tau']),
      motherSide: _fallback(profile.motherName, 'Family details not added'),
      maternalGrandfather: _detailValue(profile.maternalDetails, const [
        'Grandfather (Nanaji)',
        'Grandfather',
      ]),
      maternalGrandmother: _detailValue(profile.maternalDetails, const [
        'Grandmother',
      ]),
      uncle: _detailValue(profile.maternalDetails, const ['Uncle', 'Mama']),
      galleryImages: profile.photoUrls,
      assignedRmName: _fallback(profile.assignedRmName, '-'),
      clientStatus: _fallback(profile.clientStatus, '-'),
      shortlistLabel: profile.shortlistLabel,
    );
  }

  static String _summaryFor(RegistryProfileItem profile) {
    final work = _clean(profile.work);
    final profession = _clean(profile.profession);
    final city = _clean(profile.city);

    if (_isCompleteSentence(work)) {
      return work;
    }

    if (work.isNotEmpty && city.isNotEmpty) {
      return 'Currently handling $work in $city';
    }

    if (work.isNotEmpty && profession.isNotEmpty) {
      return 'Currently handling $work in $profession';
    }

    if (work.isNotEmpty) {
      return 'Currently handling $work';
    }

    return 'Profile details are available for review.';
  }

  static String _currentRoleFor(RegistryProfileItem profile) {
    final work = _clean(profile.work);
    final city = _clean(profile.city);

    if (_isCompleteSentence(work)) {
      return work;
    }

    if (work.isNotEmpty && city.isNotEmpty) {
      return 'Currently handling $work in $city';
    }

    if (work.isNotEmpty) {
      return 'Currently handling $work';
    }

    return 'Current role details not added';
  }

  static String _religionCaste(RegistryProfileItem profile) {
    final religion = _clean(profile.religion);
    final community = _clean(profile.community);

    if (religion.isNotEmpty && community.isNotEmpty) {
      return '$religion, $community';
    }

    if (religion.isNotEmpty) {
      return religion;
    }

    return community.isEmpty ? '-' : community;
  }

  static String _detailValue(
    String details,
    List<String> labels, {
    String fallback = 'Not added',
  }) {
    final text = _clean(details);
    if (text.isEmpty) {
      return fallback;
    }

    final normalizedLabels = labels
        .map((label) => label.trim().toLowerCase())
        .where((label) => label.isNotEmpty)
        .toSet();

    for (final part in text.split('|')) {
      final pieces = part.split(':');
      if (pieces.length < 2) {
        continue;
      }

      final label = pieces.first.trim().toLowerCase();
      final value = pieces.sublist(1).join(':').trim();
      if (normalizedLabels.contains(label) && value.isNotEmpty) {
        return value;
      }
    }

    return fallback;
  }

  static bool _isCompleteSentence(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('currently ') ||
        lower.startsWith('handles ') ||
        lower.startsWith('handling ') ||
        lower.startsWith('freelancer');
  }

  static String _fallback(String value, String fallback) {
    final text = _clean(value);
    return text.isEmpty ? fallback : text;
  }

  static String _firstName(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first;
  }

  static String _clean(String value) {
    final text = value.trim();
    return text == '-' ? '' : text;
  }
}
