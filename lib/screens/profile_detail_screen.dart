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

class ProfileDetailScreen extends StatelessWidget {
  const ProfileDetailScreen({super.key, this.profile});

  final RegistryProfileItem? profile;

  @override
  Widget build(BuildContext context) {
    final displayProfile = _ProfileDetailViewData.fromProfile(profile);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return DefaultTabController(
      length: 2,
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.05)),
        child: Scaffold(
          backgroundColor: AppColors.rmSoftPink,
          appBar: _ProfileDetailHeader(profile: displayProfile),
          body: Column(
            children: [
              Container(
                color: AppColors.white,
                child: TabBar(
                  labelColor: AppColors.rmPrimary,
                  unselectedLabelColor: AppColors.inactiveNavItemColor,
                  indicatorColor: AppColors.rmPrimary,
                  labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'Profile Info'),
                    Tab(text: 'Match History'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        12.w,
                        10.h,
                        12.w,
                        bottomInset + 24.h,
                      ),
                      child: Column(
                        children: [
                          _ProfileHeroImage(profile: displayProfile),
                          SizedBox(height: 18.h),
                          Text(
                            displayProfile.name,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              color: AppColors.rmPrimary,
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18.w),
                            child: Text(
                              displayProfile.summary,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                color: AppColors.rmBodyText,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                                height: 1.45,
                              ),
                            ),
                          ),
                          SizedBox(height: 14.h),
                          _ProfileFactsCard(profile: displayProfile),
                          SizedBox(height: 20.h),
                          _PersonalNarrativeSection(profile: displayProfile),
                          SizedBox(height: 18.h),
                          _EducationProfessionSection(profile: displayProfile),
                          SizedBox(height: 20.h),
                          _KeyDetailsSection(profile: displayProfile),
                          SizedBox(height: 22.h),
                          _FamilyBackgroundSection(profile: displayProfile),
                          SizedBox(height: 22.h),
                          _PhotoGallerySection(profile: displayProfile),
                          SizedBox(height: 22.h),
                          _ProfileActionsSection(
                            profile: displayProfile,
                            sourceProfile: profile,
                          ),
                        ],
                      ),
                    ),
                    _MatchHistorySection(profile: profile),
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

class _MatchHistorySection extends StatefulWidget {
  const _MatchHistorySection({this.profile});

  final RegistryProfileItem? profile;

  @override
  State<_MatchHistorySection> createState() => _MatchHistorySectionState();
}

class _MatchHistorySectionState extends State<_MatchHistorySection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final accessToken = authProvider.userModel?.accessToken?.trim();

      if (widget.profile != null &&
          accessToken != null &&
          accessToken.isNotEmpty) {
        context.read<MatchHistoryProvider>().fetchMatchHistory(
          profileId: widget.profile!.originalId,
          accessToken: accessToken,
          page: 1,
          limit: 20,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatchHistoryProvider>();
    final timeline = provider.timeline;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1.35)),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(13.w, 14.h, 13.w, bottomInset + 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Summary',
              style: GoogleFonts.manrope(
                color: AppColors.rmPrimary,
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 14.h),
            _MatchActivitySummary(
              timeline: timeline,
              summary: provider.summary,
              total: provider.total,
            ),
            SizedBox(height: 20.h),
            Text(
              'Detailed Timeline',
              style: GoogleFonts.manrope(
                color: AppColors.rmPrimary,
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 12.h),
            if (provider.error != null)
              _MatchHistoryMessage(message: provider.error!, isError: true)
            else if (timeline.isEmpty)
              const _MatchHistoryMessage(message: 'No match history found.')
            else
              _MatchHistoryTimeline(
                timeline: timeline,
                profileName: widget.profile?.name ?? 'Profile',
              ),
          ],
        ),
      ),
    );
  }
}

class _MatchActivitySummary extends StatelessWidget {
  const _MatchActivitySummary({
    required this.timeline,
    required this.summary,
    required this.total,
  });

  final List<dynamic> timeline;
  final Map<String, dynamic> summary;
  final int total;

  int _count(String pattern) {
    return timeline.where((entry) {
      if (entry is! Map) return false;
      final action = '${entry['action'] ?? entry['status'] ?? ''}'
          .toLowerCase();
      return action.contains(pattern);
    }).length;
  }

  int _summaryValue(List<String> keys, int fallback) {
    for (final key in keys) {
      final value = summary[key];
      if (value is int) return value;
      final parsed = int.tryParse('$value');
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final totalSent = _summaryValue(const [
      'totalSent',
      'total_sent',
      'total',
    ], total);
    final rejected = _summaryValue(const [
      'totalRejected',
      'rejected',
      'rejectedCount',
      'rejected_count',
    ], _count('reject'));
    final cards = [
      _MatchSummaryData('TOTAL SENT', totalSent, const Color(0xFF9B7A24)),
      _MatchSummaryData(
        'MANUAL\nSHORTLIST',
        _summaryValue(const [
          'manualShortlisted',
          'manualShortlist',
          'manual_shortlist',
        ], _count('manual')),
        const Color(0xFF5B94FF),
      ),
      _MatchSummaryData(
        'AI SHORTLIST',
        _summaryValue(const [
          'aiShortlisted',
          'aiShortlist',
          'ai_shortlist',
        ], _count('ai')),
        const Color(0xFF9565FF),
      ),
      _MatchSummaryData('REJECTED', rejected, const Color(0xFFD94343)),
      _MatchSummaryData(
        'APPROVED',
        _summaryValue(const [
          'totalApproved',
          'approved',
          'approvedCount',
        ], _count('approv')),
        const Color(0xFF39C995),
      ),
      _MatchSummaryData(
        'ACCEPTED',
        _summaryValue(const [
          'totalAccepted',
          'accepted',
          'acceptedCount',
        ], _count('accept')),
        const Color(0xFFA9DDB5),
      ),
    ];
    final rejectionRate =
        num.tryParse('${summary['rejectionRate']}') ??
        (totalSent == 0 ? 0.0 : (rejected / totalSent) * 100);

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 6.w,
            mainAxisSpacing: 8.h,
            childAspectRatio: 1.42,
          ),
          itemBuilder: (context, index) => _SummaryCard(data: cards[index]),
        ),
        // SizedBox.shrink(),
        _SummaryCard(
          data: _MatchSummaryData(
            'REJECTION RATE',
            rejectionRate,
            const Color(0xFFFF8150),
            isRate: true,
          ),
          wide: true,
        ),
      ],
    );
  }
}

class _MatchHistoryTimeline extends StatelessWidget {
  const _MatchHistoryTimeline({
    required this.timeline,
    required this.profileName,
  });

  final List<dynamic> timeline;
  final String profileName;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: timeline.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final item = timeline[index];
        final map = item is Map ? item : const {};
        final relatedProfile = map['relatedProfile'] is Map
            ? map['relatedProfile'] as Map
            : const {};
        final customer = relatedProfile['customer'] is Map
            ? relatedProfile['customer'] as Map
            : const {};
        final lead = customer['lead'] is Map
            ? customer['lead'] as Map
            : const {};
        final actionByUser = map['actionByUser'] is Map
            ? map['actionByUser'] as Map
            : const {};
        final date = _formatMatchHistoryDate(
          '${map['createdAt'] ?? map['created_at'] ?? map['date'] ?? '-'}',
        );
        final title =
            '${map['eventType'] ?? map['action'] ?? map['status'] ?? 'Match update'}';
        final source = '${map['source'] ?? map['created_by'] ?? '-'}';
        final note =
            '${map['notes'] ?? map['note'] ?? map['reason'] ?? map['remarks'] ?? '-'}';
        final relatedProfileName =
            '${relatedProfile['name'] ?? map['profile_name'] ?? profileName}';
        final phone = '${lead['phone'] ?? ''}';
        final profileImage = '${relatedProfile['image'] ?? ''}';

        return Container(
          padding: EdgeInsets.fromLTRB(12.w, 11.h, 12.w, 12.h),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.rmBorder),
            boxShadow: const [
              BoxShadow(
                color: AppColors.rmCardShadow,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    size: 12.sp,
                    color: AppColors.rmBodyText,
                  ),
                  SizedBox(width: 5.w),
                  Expanded(
                    child: Text(
                      date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: AppColors.rmBodyText,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F6FB),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Text(
                      title.toUpperCase(),
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF61758B),
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _TimelineField(
                      icon: Icons.auto_awesome_outlined,
                      label: 'SOURCE',
                      value: source,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _TimelineField(
                      icon: Icons.person_outline,
                      label: 'USER',
                      value:
                          '${actionByUser['name'] ?? map['user'] ?? map['user_name'] ?? '-'}',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _TimelineField(
                      icon: Icons.account_circle_outlined,
                      label: 'PROFILE',
                      value: phone.isEmpty
                          ? relatedProfileName
                          : '$relatedProfileName\n$phone',
                      imageUrl: profileImage,
                      highlighted: true,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _TimelineField(
                      icon: Icons.description_outlined,
                      label: 'NOTE',
                      value: note,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

String _formatMatchHistoryDate(String value) {
  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) return value;

  final hour = date.hour == 0
      ? 12
      : (date.hour > 12 ? date.hour - 12 : date.hour);
  final minute = date.minute.toString().padLeft(2, '0');
  final second = date.second.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '${date.month}/${date.day}/${date.year}, $hour:$minute:$second $period';
}

class _TimelineField extends StatelessWidget {
  const _TimelineField({
    required this.icon,
    required this.label,
    required this.value,
    this.highlighted = false,
    this.imageUrl,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlighted;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 11.sp, color: AppColors.rmPrimary),
            SizedBox(width: 4.w),
            Text(
              label,
              style: GoogleFonts.manrope(
                color: AppColors.rmPrimary,
                fontSize: 8.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl!.trim().isNotEmpty) ...[
              ClipOval(
                child: Image.network(
                  imageUrl!,
                  width: 44.r,
                  height: 44.r,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 44.r,
                    height: 44.r,
                    color: AppColors.rmPersonBadgeBg,
                    child: Icon(
                      Icons.person_outline,
                      size: 24.sp,
                      color: AppColors.rmPrimary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 9.w),
            ],
            Expanded(
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  color: highlighted
                      ? const Color(0xFFC48716)
                      : AppColors.rmHeading,
                  fontSize: 10.sp,
                  fontWeight: highlighted ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MatchHistoryMessage extends StatelessWidget {
  const _MatchHistoryMessage({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 22.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.rmBorder),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.manrope(
          color: isError ? AppColors.danger : AppColors.rmMutedText,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MatchSummaryData {
  const _MatchSummaryData(
    this.label,
    this.value,
    this.accent, {
    this.isRate = false,
  });

  final String label;
  final num value;
  final Color accent;
  final bool isRate;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data, this.wide = false});

  final _MatchSummaryData data;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final displayValue = data.isRate
        ? '${data.value.toStringAsFixed(1)}%'
        : data.value.toInt().toString();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 7.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: const [
          BoxShadow(
            color: AppColors.rmStatShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: -8.h,
            child: Container(
              height: 1.6.h,
              decoration: BoxDecoration(
                color: data.accent,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: AppColors.rmStatCaption,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: wide ? 5.h : 3.h),
                Text(
                  displayValue,
                  style: GoogleFonts.manrope(
                    color: AppColors.rmHeading,
                    fontSize: wide ? 22.sp : 20.sp,
                    fontWeight: FontWeight.w700,
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

class _ProfileDetailHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const _ProfileDetailHeader({required this.profile});

  final _ProfileDetailViewData profile;

  @override
  Size get preferredSize => const Size.fromHeight(96);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      toolbarHeight: 96,
      titleSpacing: 16.w,
      title: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'View ${profile.name} Profile',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: AppColors.rmPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'REF : #${profile.reference}',
              style: GoogleFonts.manrope(
                color: AppColors.rmBodyText,
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(Icons.close, color: AppColors.rmHeading, size: 21.sp),
        ),
      ],
    );
  }
}

class _ProfileHeroImage extends StatelessWidget {
  const _ProfileHeroImage({required this.profile});

  final _ProfileDetailViewData profile;

  @override
  Widget build(BuildContext context) {
    final images = profile.galleryImages.isEmpty
        ? <String>[profile.image]
        : profile.galleryImages;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: SizedBox(
            height: 350.h,
            child: PageView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) {
                return _ProfileImageView(
                  image: images[index],
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                );
              },
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            top: 10.h,
            right: 10.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Text(
                '${images.length} Photos',
                style: GoogleFonts.manrope(
                  color: AppColors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 10.h,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFCA3A),
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.rmCardShadow,
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ACTIVE MEMBER',
                  style: GoogleFonts.manrope(
                    color: AppColors.rmHeading,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(width: 7.w),
                Icon(
                  Icons.verified_outlined,
                  color: AppColors.rmPrimary,
                  size: 14.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileFactsCard extends StatelessWidget {
  const _ProfileFactsCard({required this.profile});

  final _ProfileDetailViewData profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 22.h, 14.w, 4.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 2.95,
        mainAxisSpacing: 6.h,
        crossAxisSpacing: 14.w,
        children: [

          _ProfileFact(label: 'DATE OF BIRTH', value: profile.dateOfBirth),
          _ProfileFact(label: 'BIRTH TIME', value: profile.birthTime),
          _ProfileFact(label: 'BIRTH PLACE', value: profile.birthPlace),
          _ProfileFact(label: 'HEIGHT', value: profile.height),
          _ProfileFact(label: 'GOTRA', value: profile.gotra),
          _ProfileFact(label: 'RESIDENTIAL', value: profile.residential),
        ],
      ),
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
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            color: AppColors.rmBodyText,
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            color: AppColors.rmPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.w900,
            height: 1.08,
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
        Text(
          'PERSONAL NARRATIVE',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            color: AppColors.rmBodyText,
            fontSize: 11.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          profile.aboutTitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            color: AppColors.rmPrimary,
            fontSize: 27.sp,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        SizedBox(height: 14.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 20.h),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.rmPaleRoseBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.narrativeInitial,
                style: GoogleFonts.manrope(
                  color: const Color(0xFFF2C23C),
                  fontSize: 44.sp,
                  fontWeight: FontWeight.w500,
                  height: 0.95,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  profile.narrativeBody,
                  style: GoogleFonts.manrope(
                    color: AppColors.rmPrimary,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ),
            ],
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
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              'Education & Profession',
              style: GoogleFonts.manrope(
                color: AppColors.rmPrimary,
                fontSize: 26.sp,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
        ),
        SizedBox(height: 14.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 22.h),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBFC),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.rmPaleRoseBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: const BoxDecoration(
                      color: AppColors.rmHeading,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 1.w,
                    height: 160.h,
                    color: AppColors.rmPaleRoseBorder,
                  ),
                ],
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Role',
                      style: GoogleFonts.manrope(
                        color: AppColors.rmHeading,
                        fontSize: 21.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      profile.currentRole,
                      style: GoogleFonts.manrope(
                        color: AppColors.rmPrimary,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: 22.h),
                    Text(
                      'Education',
                      style: GoogleFonts.manrope(
                        color: AppColors.rmHeading,
                        fontSize: 21.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Academic Background',
                      style: GoogleFonts.manrope(
                        color: AppColors.rmPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      profile.education,
                      style: GoogleFonts.manrope(
                        color: AppColors.rmMutedText,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: AppColors.rmPrimary,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book_outlined,
                color: const Color(0xFFF2C23C),
                size: 24.sp,
              ),
              SizedBox(width: 10.w),
              Text(
                'Key Details',
                style: GoogleFonts.manrope(
                  color: const Color(0xFFF2C23C),
                  fontSize: 25.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Divider(color: AppColors.white.withValues(alpha: 0.18), height: 1),
          _KeyDetailRow(
            label: 'RELIGION / CASTE',
            value: profile.religionCaste,
          ),
          _KeyDetailRow(label: 'BIRTH PLACE', value: profile.birthPlace),
          _KeyDetailRow(label: 'GOTRA', value: profile.gotra),
          _KeyDetailRow(label: 'DIET', value: profile.diet),
          _KeyDetailRow(label: 'HOROSCOPE', value: profile.horoscope),
          _KeyDetailRow(
            label: 'COUNTRY',
            value: profile.country,
            showDivider: false,
          ),
        ],
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
                  style: GoogleFonts.manrope(
                    color: const Color(0xFFF2C23C),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
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
                  style: GoogleFonts.manrope(
                    color: AppColors.white,
                    fontSize: 15.sp,
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

class _FamilyBackgroundSection extends StatelessWidget {
  const _FamilyBackgroundSection({required this.profile});

  final _ProfileDetailViewData profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Family Background',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            color: AppColors.rmPrimary,
            fontSize: 25.sp,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        SizedBox(height: 16.h),
        _FamilySideCard(
          side: 'FATHER\'S SIDE',
          name: profile.fatherSide,
          relatives: [
            _FamilyRelative(label: 'Grandfather', value: profile.grandfather),
            _FamilyRelative(label: 'Grandmother', value: profile.grandmother),
            _FamilyRelative(label: 'Bua', value: profile.bua),
          ],
        ),
        SizedBox(height: 10.h),
        _FamilySideCard(
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
                    style: GoogleFonts.manrope(
                      color: AppColors.rmBodyText,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    name,
                    style: GoogleFonts.manrope(
                      color: AppColors.rmPrimary,
                      fontSize: 18.sp,
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
        style: GoogleFonts.manrope(
          color: AppColors.rmBodyText,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
        children: [
          TextSpan(
            text: '$label : ',
            style: GoogleFonts.manrope(
              color: AppColors.rmPrimary,
              fontSize: 14.sp,
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
        Text(
          'Photo Gallery',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            color: AppColors.rmPrimary,
            fontSize: 25.sp,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'A GLIMPSE INTO $galleryPronoun LIFE AND PASSIONS.',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            color: AppColors.rmPrimary,
            fontSize: 11.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 18.h),
        GestureDetector(
          onTap: () => _showGalleryImage(context, 0, galleryImages),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: _ProfileImageView(
              image: galleryImages.first,
              height: 326.h,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ),
        if (galleryImages.length > 1) ...[
          SizedBox(height: 12.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 12.w) / 2;
              final remainingImages = galleryImages.skip(1).toList();

              return Wrap(
                spacing: 12.w,
                runSpacing: 12.h,
                children: [
                  for (var index = 0; index < remainingImages.length; index++)
                    GestureDetector(
                      onTap: () =>
                          _showGalleryImage(context, index + 1, galleryImages),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3.r),
                        child: SizedBox(
                          width: itemWidth,
                          height: 126.h,
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
      padding: EdgeInsets.symmetric(horizontal: 26.w),
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
              icon: Icons.download,
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
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14.sp),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        minimumSize: Size(0, 38.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        textStyle: GoogleFonts.manrope(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
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
