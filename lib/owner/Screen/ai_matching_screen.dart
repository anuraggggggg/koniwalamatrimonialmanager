import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;
import 'package:http/http.dart' as http;
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/owner/models/match_comparison_args.dart';
import 'package:koniwalamatrimonial/owner/models/registry_profile_item.dart';
import 'package:koniwalamatrimonial/owner/providers/registry_profiles_provider.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:provider/provider.dart';

class GoogleFonts {
  const GoogleFonts._();

  static TextStyle manrope({
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return google_fonts.GoogleFonts.poppins(
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }
}

class AiMatchingScreen extends StatefulWidget {
  const AiMatchingScreen({super.key, this.onMenuPressed});

  final VoidCallback? onMenuPressed;

  @override
  State<AiMatchingScreen> createState() => _AiMatchingScreenState();
}

class _AiMatchingScreenState extends State<AiMatchingScreen> {
  bool _manualMatchSelected = false;
  final Set<String> _approvingSuggestionIds = {};
  final Set<String> _approvedSuggestionIds = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final accessToken = context.read<AuthProvider>().userModel?.accessToken;
      context.read<RegistryProfilesProvider>().fetchProfiles(accessToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profilesProvider = context.watch<RegistryProfilesProvider>();
    final profiles = profilesProvider.profiles;
    final suggestions = _buildSuggestions(profiles);
    final metrics = _buildMetrics(profiles, suggestions);
    final featuredSuggestion = suggestions.isEmpty ? null : suggestions.first;
    final insightSuggestions = suggestions.length <= 1
        ? suggestions
        : suggestions.skip(1).take(2).toList();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.3)),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _AiMatchingTopBar(
                      onBackTap:
                          widget.onMenuPressed ??
                          () => Navigator.of(context).maybePop(),
                      manualSelected: _manualMatchSelected,
                      onModeSelected: (isManual) =>
                          setState(() => _manualMatchSelected = isManual),
                      onNotificationsTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.notifications),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 22.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generate, review, and manage matches for your clients in one place.',
                            style: GoogleFonts.manrope(
                              color: AppColors.rmComparisonStrong,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          SizedBox(
                            width: double.infinity,
                            height: 44.h,
                            child: ElevatedButton.icon(
                              onPressed: _generateAiMatches,
                              icon: Icon(Icons.auto_awesome, size: 14.sp),
                              label: Text(
                                _manualMatchSelected
                                    ? 'RETURN TO AI MATCHES'
                                    : 'GENERATE AI MATCHES',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.rmPrimary,
                                foregroundColor: AppColors.white,
                                elevation: 0,
                                textStyle: GoogleFonts.manrope(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          if (profilesProvider.isLoading && profiles.isEmpty)
                            const _AiLoadingCard()
                          else if (profilesProvider.error != null &&
                              profiles.isEmpty)
                            _AiErrorCard(onRetry: profilesProvider.retry)
                          else
                            _manualMatchSelected
                                ? _ManualMatchPanel(profiles: profiles)
                                : _MetricsGrid(metrics: metrics),
                          SizedBox(height: 26.h),
                          Text(
                            'Auto Match Queue Preview',
                            style: GoogleFonts.manrope(
                              color: AppColors.rmHeading,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Intelligent synergy suggestions',
                            style: GoogleFonts.manrope(
                              color: AppColors.rmComparisonStrong,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          if (profilesProvider.isLoading && profiles.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: LinearProgressIndicator(
                                minHeight: 3,
                                color: AppColors.rmPrimary,
                                backgroundColor: AppColors.rmPrimary.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                            ),
                          if (featuredSuggestion != null)
                            _MatchSuggestionCard(
                              suggestion: featuredSuggestion,
                              isApproving: _approvingSuggestionIds.contains(
                                featuredSuggestion.id,
                              ),
                              isApproved: _approvedSuggestionIds.contains(
                                featuredSuggestion.id,
                              ),
                              onApprove: () =>
                                  _approveSuggestion(featuredSuggestion),
                              onCompare: () => _compareSuggestion(
                                context,
                                featuredSuggestion,
                              ),
                            )
                          else
                            _AiEmptyState(
                              message:
                                  profilesProvider.error ??
                                  'Profiles are loaded, but no bride-groom pairs are available yet.',
                            ),
                          SizedBox(height: 22.h),
                          _QuickInsightsCard(
                            suggestions: insightSuggestions,
                            profileCount: profiles.length,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 28.h)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<_MatchMetric> _buildMetrics(
    List<RegistryProfileItem> profiles,
    List<_MatchSuggestion> suggestions,
  ) {
    final topScore = suggestions.isEmpty ? 0 : suggestions.first.scoreValue;
    final reviewCount = suggestions
        .where((item) => item.pendingInfo != null)
        .length;
    final approvedCount = _approvedSuggestionIds.length;
    final approvedRate = suggestions.isEmpty
        ? 0
        : ((approvedCount / suggestions.length) * 100).round();

    return [
      _MatchMetric(
        title: 'CURRENT SUGGESTION',
        value: '$topScore%',
        caption: suggestions.isEmpty ? 'no live matches' : 'top live match',
        icon: Icons.trending_up,
        color: const Color(0xFF11A36A),
      ),
      _MatchMetric(
        title: 'NEED REVIEW',
        value: '$reviewCount',
        caption: 'created by your team',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF17B26A),
      ),
      _MatchMetric(
        title: 'APPROVED',
        value: '$approvedRate%',
        caption: '$approvedCount/${suggestions.length} completed',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF17B26A),
      ),
      _MatchMetric(
        title: 'REJECTED',
        value: '0',
        caption: 'review reasons',
        icon: Icons.cancel_outlined,
        color: const Color(0xFFF04438),
      ),
      _MatchMetric(
        title: 'SAVED MATCHES',
        value: '${max(0, suggestions.length - approvedCount - reviewCount)}',
        caption: 'left for later',
        icon: Icons.bookmark_border,
        color: AppColors.rmPrimary,
        isWide: true,
      ),
    ];
  }

  Future<void> _generateAiMatches() async {
    if (_manualMatchSelected) {
      setState(() => _manualMatchSelected = false);
    }

    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    await context.read<RegistryProfilesProvider>().fetchProfiles(
      accessToken,
      forceRefresh: true,
    );
  }

  void _compareSuggestion(BuildContext context, _MatchSuggestion suggestion) {
    final leftId = suggestion.leftProfile.originalId.trim();
    final rightId = suggestion.rightProfile.originalId.trim();

    if (leftId.isEmpty || rightId.isEmpty) {
      Navigator.of(
        context,
      ).pushNamed(AppRoutes.profileDetail, arguments: suggestion.leftProfile);
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.compareProfile,
      arguments: MatchComparisonArgs(
        profileId: leftId,
        candidateProfileId: rightId,
      ),
    );
  }

  List<_MatchSuggestion> _buildSuggestions(List<RegistryProfileItem> profiles) {
    final brides = profiles
        .where((profile) => profile.type == 'Bride')
        .toList();
    final grooms = profiles
        .where((profile) => profile.type == 'Groom')
        .toList();
    final suggestions = <_MatchSuggestion>[];

    if (brides.isEmpty || grooms.isEmpty) {
      return suggestions;
    }

    for (final bride in brides) {
      for (final groom in grooms) {
        suggestions.add(_createSuggestion(groom: groom, bride: bride));
      }
    }

    suggestions.sort((a, b) => b.scoreValue.compareTo(a.scoreValue));
    return suggestions.take(6).toList();
  }

  _MatchSuggestion _createSuggestion({
    required RegistryProfileItem groom,
    required RegistryProfileItem bride,
  }) {
    var score = 56;
    final reasons = <String>[];

    if (_normalized(groom.city) == _normalized(bride.city)) {
      score += 14;
      reasons.add('Both are based in ${groom.city}');
    }

    if (_normalized(groom.community) == _normalized(bride.community)) {
      score += 12;
      reasons.add('Community alignment is strong');
    }

    if (_normalized(groom.profession) != '-' &&
        _normalized(bride.profession) != '-') {
      score += 8;
      reasons.add('Both profiles show strong educational backgrounds');
    }

    if (_normalized(groom.work) != '-' && _normalized(bride.work) != '-') {
      score += 6;
      reasons.add('Career stability is present on both sides');
    }

    final ageGap = (_parseAge(groom.age) - _parseAge(bride.age)).abs();
    if (ageGap <= 2) {
      score += 10;
      reasons.add('Very close age bracket');
    } else if (ageGap <= 5) {
      score += 6;
      reasons.add('Age difference is within a comfortable range');
    }

    final pendingInfo =
        _normalized(groom.gotra) == '-' || _normalized(bride.gotra) == '-'
        ? 'Gotra details need manual verification'
        : _normalized(groom.community) != _normalized(bride.community)
        ? 'Cross-community review recommended before approval'
        : null;

    if (pendingInfo != null) {
      score -= 4;
    }

    final finalScore = score.clamp(58, 97);
    final reason = reasons.isEmpty
        ? 'Baseline compatibility generated from profile summary, location, age band, and education data.'
        : reasons.join('. ');

    return _MatchSuggestion(
      id: _uuidFromText('${groom.originalId}:${bride.originalId}'),
      leftProfile: groom,
      rightProfile: bride,
      names: '${groom.name} & ${bride.name}',
      time: '${groom.city} - ${bride.city}',
      score: '$finalScore%',
      scoreValue: finalScore,
      reason: reason.endsWith('.') ? reason : '$reason.',
      pendingInfo: pendingInfo,
    );
  }

  Future<void> _approveSuggestion(_MatchSuggestion suggestion) async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.userModel?.accessToken?.trim() ?? '';

    if (token.isEmpty) {
      _showMessage('Login required to approve match.', isError: true);
      return;
    }

    if (_approvingSuggestionIds.contains(suggestion.id) ||
        _approvedSuggestionIds.contains(suggestion.id)) {
      return;
    }

    setState(() => _approvingSuggestionIds.add(suggestion.id));

    final body = {
      'brideId': suggestion.rightProfile.originalId,
      'groomId': suggestion.leftProfile.originalId,
      'score': suggestion.scoreValue,
      'reasons': suggestion.reasons,
      'status': 'APPROVED',
    };

    try {
      final response = await http.post(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.matchingSuggestionsPersist}',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message =
            _extractApiErrorMessage(response.body) ??
            'Approve API failed with ${response.statusCode}';
        debugPrint(
          'AI approve API failed: status=${response.statusCode}, body=${response.body}',
        );
        throw Exception(message);
      }

      if (!mounted) {
        return;
      }

      setState(() => _approvedSuggestionIds.add(suggestion.id));
      _showMessage('Match approved successfully.');
    } catch (error) {
      if (mounted) {
        _showMessage(
          _cleanExceptionMessage(error, fallback: 'Unable to approve match.'),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _approvingSuggestionIds.remove(suggestion.id));
      }
    }
  }

  String? _extractApiErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        for (final key in const ['message', 'error', 'detail']) {
          final value = decoded[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
          if (value is List && value.isNotEmpty) {
            return value.join(', ');
          }
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String _cleanExceptionMessage(Object error, {required String fallback}) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? fallback : message;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : null,
      ),
    );
  }

  String _uuidFromText(String text) {
    var seed = 0;
    for (final codeUnit in text.codeUnits) {
      seed = 0x1fffffff & (seed + codeUnit);
      seed = 0x1fffffff & (seed + ((0x0007ffff & seed) << 10));
      seed ^= seed >> 6;
    }
    seed = 0x1fffffff & (seed + ((0x03ffffff & seed) << 3));
    seed ^= seed >> 11;
    seed = 0x1fffffff & (seed + ((0x00003fff & seed) << 15));

    final random = Random(seed);
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final value = bytes.map(hex).join();
    return '${value.substring(0, 8)}-'
        '${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-'
        '${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }

  String _normalized(String value) {
    final text = value.trim().toLowerCase();
    return text.isEmpty ? '-' : text;
  }

  int _parseAge(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }
}

class _AiMatchingTopBar extends StatelessWidget {
  const _AiMatchingTopBar({
    required this.onBackTap,
    required this.manualSelected,
    required this.onModeSelected,
    required this.onNotificationsTap,
  });

  final VoidCallback onBackTap;
  final bool manualSelected;
  final ValueChanged<bool> onModeSelected;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1E3D9))),
      ),
      child: Row(
        children: [
          _RoundIconButton(icon: Icons.arrow_back, onTap: onBackTap),
          Expanded(
            child: Text(
              'AI Matchmaking',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: google_fonts.GoogleFonts.playfairDisplay(
                color: const Color(0xFF2C2626),
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          PopupMenuButton<_AiTopMenuAction>(
            tooltip: 'More',
            onSelected: (action) {
              switch (action) {
                case _AiTopMenuAction.ai:
                  onModeSelected(false);
                  break;
                case _AiTopMenuAction.manual:
                  onModeSelected(true);
                  break;
                case _AiTopMenuAction.notifications:
                  onNotificationsTap();
                  break;
              }
            },
            icon: Icon(
              Icons.more_vert,
              color: const Color(0xFF2C2626),
              size: 22.sp,
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: manualSelected
                    ? _AiTopMenuAction.ai
                    : _AiTopMenuAction.manual,
                child: Text(
                  manualSelected ? 'AI Matchmaking' : 'Manual Match',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                ),
              ),
              PopupMenuItem(
                value: _AiTopMenuAction.notifications,
                child: Text(
                  'Notifications',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _AiTopMenuAction { ai, manual, notifications }

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: onTap,
      child: SizedBox(
        width: 40.w,
        height: 40.w,
        child: Icon(icon, color: const Color(0xFF2C2626), size: 22.sp),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final List<_MatchMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final regularMetrics = metrics.where((metric) => !metric.isWide).toList();
    _MatchMetric? wideMetric;
    for (final metric in metrics) {
      if (metric.isWide) {
        wideMetric = metric;
        break;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 8.w;
        final itemWidth = (constraints.maxWidth - spacing) / 2;

        return Column(
          children: [
            Wrap(
              spacing: spacing,
              runSpacing: 8.h,
              children: [
                for (final metric in regularMetrics)
                  SizedBox(
                    width: itemWidth,
                    child: _MetricCard(metric: metric),
                  ),
              ],
            ),
            if (wideMetric != null) ...[
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: _MetricCard(metric: wideMetric),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MatchMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: metric.isWide ? 86.h : 116.h),
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: const Color(0xFF3B3535),
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            metric.value,
            style: GoogleFonts.manrope(
              color: AppColors.rmPrimary,
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  metric.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF3B3535),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Icon(metric.icon, color: metric.color, size: 18.sp),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManualMatchPanel extends StatelessWidget {
  const _ManualMatchPanel({required this.profiles});

  final List<RegistryProfileItem> profiles;

  @override
  Widget build(BuildContext context) {
    final visibleProfiles = profiles.take(4).toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.manage_search_outlined,
            color: AppColors.rmPrimary,
            size: 22.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            'Manual Match Workspace',
            style: GoogleFonts.manrope(
              color: AppColors.rmPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Profiles loaded from /profiles. Review the registry and open profiles for manual pairing.',
            style: GoogleFonts.manrope(
              color: AppColors.rmComparisonMuted,
              fontSize: 13.sp,
              height: 1.35,
            ),
          ),
          SizedBox(height: 14.h),
          if (profiles.isEmpty)
            Text(
              'No profiles available yet.',
              style: GoogleFonts.manrope(
                color: AppColors.rmComparisonMuted,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Column(
              children: [
                for (
                  var index = 0;
                  index < visibleProfiles.length;
                  index++
                ) ...[
                  _ManualProfileTile(profile: visibleProfiles[index]),
                  if (index < visibleProfiles.length - 1)
                    SizedBox(height: 10.h),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _MatchSuggestionCard extends StatelessWidget {
  const _MatchSuggestionCard({
    required this.suggestion,
    required this.isApproving,
    required this.isApproved,
    required this.onApprove,
    required this.onCompare,
  });

  final _MatchSuggestion suggestion;
  final bool isApproving;
  final bool isApproved;
  final VoidCallback onApprove;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 14.h),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF8),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: const Color(0xFFF0E0D6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppColors.rmPrimary,
                  size: 14.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  'AI GENERATED BY MATCHMAKING AI',
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF2E2929),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _FeaturedProfileDetails(
                  profile: suggestion.rightProfile,
                  alignEnd: false,
                ),
              ),
              SizedBox(width: 8.w),
              SizedBox(
                width: 66.w,
                child: _ScoreBadge(score: suggestion.score),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 5,
                child: _FeaturedProfileDetails(
                  profile: suggestion.leftProfile,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Center(child: _ConfidencePill(scoreValue: suggestion.scoreValue)),
          SizedBox(height: 16.h),
          Text(
            'Reason for Match',
            style: GoogleFonts.manrope(
              color: const Color(0xFF2E2929),
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '"${suggestion.reason}"',
            style: GoogleFonts.manrope(
              color: AppColors.rmComparisonBody,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          SizedBox(height: 14.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                _ReasonChip(
                  icon: Icons.auto_awesome_outlined,
                  label: 'AI Reasoning',
                ),
                _ReasonChip(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Auto Ranked',
                ),
                _ReasonChip(icon: Icons.favorite_border, label: 'Kundali AI'),
              ],
            ),
          ),
          if (suggestion.pendingInfo != null) ...[
            SizedBox(height: 12.h),
            Text(
              'Pending Info',
              style: GoogleFonts.manrope(
                color: const Color(0xFF2E2929),
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.danger, size: 14.sp),
                SizedBox(width: 5.w),
                Expanded(
                  child: Text(
                    _pendingInfoLabel(suggestion.pendingInfo!),
                    style: GoogleFonts.manrope(
                      color: AppColors.danger,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton.icon(
              onPressed: onCompare,
              icon: Icon(Icons.compare_arrows, size: 16.sp),
              label: Text(
                'Compare Profiles',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rmPrimary,
                foregroundColor: AppColors.white,
                elevation: 0,
                textStyle: GoogleFonts.manrope(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _QueueActionButton(
                  label: 'Save',
                  icon: Icons.bookmark_border,
                  onTap: () {},
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: _QueueActionButton(
                  label: 'Reject',
                  bordered: true,
                  accentColor: const Color(0xFFF04438),
                  onTap: () {},
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: _QueueActionButton(
                  label: isApproving
                      ? 'Approving'
                      : isApproved
                      ? 'Approved'
                      : 'Approve',
                  filled: true,
                  accentColor: AppColors.whatsappGreen,
                  onTap: isApproving || isApproved ? null : onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final String score;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          score,
          style: GoogleFonts.manrope(
            color: AppColors.rmPrimary,
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'MATCH\nSCORE',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            color: const Color(0xFF2E2929),
            fontSize: 8.sp,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _FeaturedProfileDetails extends StatelessWidget {
  const _FeaturedProfileDetails({
    required this.profile,
    required this.alignEnd,
  });

  final RegistryProfileItem profile;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18.r,
          backgroundColor: const Color(0xFFF3E9ED),
          backgroundImage: _profileImageProvider(profile.image),
          child: _profileImageProvider(profile.image) == null
              ? Text(
                  _initialsFor(profile.name),
                  style: GoogleFonts.manrope(
                    color: AppColors.rmPrimary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : null,
        ),
        SizedBox(height: 10.h),
        SizedBox(
          width: double.infinity,
          child: Text(
            profile.name,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: const Color(0xFF111111),
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        SizedBox(
          width: double.infinity,
          child: Text(
            _profileMeta(profile),
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: const Color(0xFF111111),
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _QueueActionButton extends StatelessWidget {
  const _QueueActionButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.bordered = false,
    this.filled = false,
    this.accentColor,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool bordered;
  final bool filled;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final tone =
        accentColor ??
        (filled ? AppColors.whatsappGreen : AppColors.rmComparisonStrong);
    final foreground = filled ? AppColors.white : tone;

    return SizedBox(
      height: 42.h,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: filled ? tone : AppColors.white,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
            side: bordered
                ? BorderSide(color: tone.withValues(alpha: 0.7))
                : BorderSide.none,
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15.sp),
              SizedBox(width: 6.w),
            ],
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfidencePill extends StatelessWidget {
  const _ConfidencePill({required this.scoreValue});

  final int scoreValue;

  @override
  Widget build(BuildContext context) {
    final label = scoreValue >= 85
        ? 'Confidence: HIGH'
        : scoreValue >= 70
        ? 'Confidence: MEDIUM'
        : 'Confidence: LOW';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FFFA),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: const Color(0xFFB7E2C4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.settings_suggest_outlined,
            color: const Color(0xFF17B26A),
            size: 13.sp,
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: GoogleFonts.manrope(
              color: const Color(0xFF17B26A),
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(color: const Color(0xFFF0D8C8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.sp, color: const Color(0xFF2E2929)),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.manrope(
                color: const Color(0xFF2E2929),
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickInsightsCard extends StatelessWidget {
  const _QuickInsightsCard({
    required this.suggestions,
    required this.profileCount,
  });

  final List<_MatchSuggestion> suggestions;
  final int profileCount;

  @override
  Widget build(BuildContext context) {
    final pendingCount = suggestions
        .where((item) => item.pendingInfo != null)
        .length;
    final reviewSuggestions = suggestions.take(2).toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12B25C18),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Quick Insights',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF232323),
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.trending_up,
                color: const Color(0xFF232323),
                size: 18.sp,
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              const _InsightDot(),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Needs Review',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF232323),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '$pendingCount pending',
                  style: GoogleFonts.manrope(
                    color: AppColors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (reviewSuggestions.isEmpty)
            Padding(
              padding: EdgeInsets.only(left: 18.w),
              child: Text(
                'Load profiles to generate AI pairing insights.',
                style: GoogleFonts.manrope(
                  color: AppColors.rmComparisonMuted,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Column(
              children: [
                for (
                  var index = 0;
                  index < reviewSuggestions.length;
                  index++
                ) ...[
                  _QuickInsightSuggestionTile(
                    suggestion: reviewSuggestions[index],
                  ),
                  if (index < reviewSuggestions.length - 1)
                    SizedBox(height: 10.h),
                ],
              ],
            ),
          SizedBox(height: 16.h),
          Row(
            children: [
              const _InsightDot(),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Recent Rejections',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF232323),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.only(left: 18.w),
            child: Text(
              pendingCount > 0
                  ? '$pendingCount suggestion${pendingCount == 1 ? '' : 's'} need manual review out of $profileCount profiles.'
                  : 'No rejections yet',
              style: GoogleFonts.manrope(
                color: AppColors.rmComparisonMuted,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickInsightSuggestionTile extends StatelessWidget {
  const _QuickInsightSuggestionTile({required this.suggestion});

  final _MatchSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            suggestion.names,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: const Color(0xFF232323),
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            suggestion.reason,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: AppColors.rmComparisonMuted,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightDot extends StatelessWidget {
  const _InsightDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7.r,
      height: 7.r,
      decoration: const BoxDecoration(
        color: AppColors.rmPrimary,
        shape: BoxShape.circle,
      ),
    );
  }
}

ImageProvider? _profileImageProvider(String image) {
  final value = image.trim();
  if (value.isEmpty) {
    return null;
  }

  if (value.startsWith('http')) {
    return NetworkImage(value);
  }

  if (value.startsWith('assets/')) {
    return AssetImage(value);
  }

  return null;
}

String _initialsFor(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();
  if (parts.isEmpty) {
    return '?';
  }

  return parts.map((part) => part[0].toUpperCase()).join();
}

String _profileMeta(RegistryProfileItem profile) {
  final city = profile.city.trim().isEmpty || profile.city.trim() == '-'
      ? profile.birthPlace
      : profile.city;
  final work = profile.work.trim().isEmpty || profile.work.trim() == '-'
      ? profile.profession
      : profile.work;
  return '${profile.age} yrs ${String.fromCharCode(8226)} ${work.trim().isEmpty ? profile.type : work}\n$city';
}

String _pendingInfoLabel(String value) {
  final text = value.trim();
  if (text.isEmpty) {
    return 'Additional review required';
  }

  if (text.toLowerCase().contains('gotra')) {
    return 'Astro status pending verification';
  }

  return text;
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(14.r),
    border: Border.all(color: const Color(0xFFF0DED5)),
    boxShadow: const [
      BoxShadow(color: Color(0x12B25C18), blurRadius: 18, offset: Offset(0, 8)),
    ],
  );
}

class _MatchMetric {
  const _MatchMetric({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
    this.isWide = false,
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;
  final bool isWide;
}

class _MatchSuggestion {
  const _MatchSuggestion({
    required this.id,
    required this.leftProfile,
    required this.rightProfile,
    required this.names,
    required this.time,
    required this.score,
    required this.scoreValue,
    required this.reason,
    this.pendingInfo,
  });

  final String id;
  final RegistryProfileItem leftProfile;
  final RegistryProfileItem rightProfile;
  final String names;
  final String time;
  final String score;
  final int scoreValue;
  final String reason;
  final String? pendingInfo;

  List<String> get reasons {
    return [
      reason,
      if (pendingInfo != null && pendingInfo!.trim().isNotEmpty) pendingInfo!,
    ];
  }
}

class _ManualProfileTile extends StatelessWidget {
  const _ManualProfileTile({required this.profile});

  final RegistryProfileItem profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7FA),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundImage: profile.image.startsWith('http')
                ? NetworkImage(profile.image)
                : AssetImage(profile.image) as ImageProvider,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: AppColors.rmPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '${profile.type} • ${profile.age} yrs • ${profile.city}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: AppColors.rmComparisonMuted,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.profileDetail, arguments: profile),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}

class _AiLoadingCard extends StatelessWidget {
  const _AiLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Loading profiles from /profiles...',
              style: GoogleFonts.manrope(
                color: AppColors.rmPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiErrorCard extends StatelessWidget {
  const _AiErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unable to load live profiles.',
            style: GoogleFonts.manrope(
              color: AppColors.danger,
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Retry the /profiles request to rebuild AI suggestions.',
            style: GoogleFonts.manrope(
              color: AppColors.rmComparisonMuted,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _AiEmptyState extends StatelessWidget {
  const _AiEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: _cardDecoration(),
      child: Text(
        message,
        style: GoogleFonts.manrope(
          color: AppColors.rmComparisonMuted,
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}
