import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;
import 'package:http/http.dart' as http;
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
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

    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
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
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 22.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AiMatchingTopBar(
                            onMenuPressed: widget.onMenuPressed,
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            'AI Matchmaking',
                            style: GoogleFonts.manrope(
                              color: AppColors.rmPrimary,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Generate, review, and manage matches for your clients in one place.',
                            style: GoogleFonts.manrope(
                              color: AppColors.rmComparisonMuted,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                          SizedBox(height: 18.h),
                          _MatchModeSwitch(
                            manualSelected: _manualMatchSelected,
                            onChanged: (value) =>
                                setState(() => _manualMatchSelected = value),
                          ),
                          SizedBox(height: 20.h),
                          if (profilesProvider.isLoading && profiles.isEmpty)
                            const _AiLoadingCard()
                          else if (profilesProvider.error != null &&
                              profiles.isEmpty)
                            _AiErrorCard(onRetry: profilesProvider.retry)
                          else
                            _manualMatchSelected
                                ? _ManualMatchPanel(profiles: profiles)
                                : _MetricsGrid(metrics: metrics),
                          SizedBox(height: 24.h),
                          Text(
                            'Auto Match Queue Preview',
                            style: GoogleFonts.manrope(
                              color: AppColors.rmPrimary,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Live suggestions generated from /profiles',
                            style: GoogleFonts.manrope(
                              color: AppColors.rmComparisonMuted,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 12.h),
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
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 18.h),
                    sliver: suggestions.isEmpty
                        ? SliverToBoxAdapter(
                            child: _AiEmptyState(
                              message:
                                  profilesProvider.error ??
                                  'Profiles are loaded, but no bride-groom pairs are available yet.',
                            ),
                          )
                        : SliverList.separated(
                            itemCount: suggestions.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: 16.h),
                            itemBuilder: (context, index) {
                              return _MatchSuggestionCard(
                                suggestion: suggestions[index],
                                isApproving: _approvingSuggestionIds.contains(
                                  suggestions[index].id,
                                ),
                                isApproved: _approvedSuggestionIds.contains(
                                  suggestions[index].id,
                                ),
                                onApprove: () =>
                                    _approveSuggestion(suggestions[index]),
                              );
                            },
                          ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 28.h),
                      child: _QuickInsightsCard(
                        suggestions: suggestions,
                        profileCount: profiles.length,
                      ),
                    ),
                  ),
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
    final brides = profiles.where((profile) => profile.type == 'Bride').length;
    final grooms = profiles.where((profile) => profile.type == 'Groom').length;
    final reviewCount = suggestions
        .where((item) => item.pendingInfo != null)
        .length;

    return [
      _MatchMetric(
        title: 'Total Matches',
        value: '${suggestions.length}',
        caption: '$brides brides paired with $grooms grooms',
        icon: Icons.trending_up,
        color: const Color(0xFF00BFA6),
      ),
      _MatchMetric(
        title: 'Manual Matches',
        value: '0',
        caption: '${profiles.length} profiles available',
        icon: Icons.group_add_outlined,
        color: AppColors.rmComparisonMuted,
      ),
      _MatchMetric(
        title: 'Needs Review',
        value: '$reviewCount',
        caption: 'Check pending family details',
        icon: Icons.info_outline,
        color: AppColors.accent,
      ),
      _MatchMetric(
        title: 'Saved Matches',
        value: '0',
        caption: 'No saved shortlist yet',
        icon: Icons.bookmark_outline,
        color: AppColors.accent,
      ),
      _MatchMetric(
        title: 'Approved',
        value: '0',
        caption: 'Ready for outreach',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF00BFA6),
      ),
      _MatchMetric(
        title: 'Rejected',
        value: '0',
        caption: 'Review reasons',
        icon: Icons.cancel_outlined,
        color: AppColors.danger,
      ),
    ];
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
  const _AiMatchingTopBar({this.onMenuPressed});

  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      child: Row(
        children: [
          _RoundIconButton(
            icon: onMenuPressed != null ? Icons.menu : Icons.arrow_back,
            onTap: onMenuPressed ?? () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              'VIP Registry',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: AppColors.rmPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _RoundIconButton(
            icon: Icons.notifications_none,
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.notifications),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44.r,
          height: 44.r,
          child: Icon(icon, color: AppColors.rmPrimary, size: 22.sp),
        ),
      ),
    );
  }
}

class _MatchModeSwitch extends StatelessWidget {
  const _MatchModeSwitch({
    required this.manualSelected,
    required this.onChanged,
  });

  final bool manualSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62.h,
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeOption(
              label: 'AI Matchmaking',
              selected: !manualSelected,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _ModeOption(
              label: 'Manual Match',
              selected: manualSelected,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.selectedNavItemBackgroundColor : Colors.white,
      borderRadius: BorderRadius.circular(22.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(22.r),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: selected
                  ? AppColors.rmPrimary
                  : AppColors.rmComparisonMuted,
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final List<_MatchMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 10.w;
        final itemWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: 10.h,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: itemWidth,
                child: _MetricCard(metric: metric),
              ),
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
      padding: EdgeInsets.all(12.r),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: AppColors.rmComparisonMuted,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            metric.value,
            style: GoogleFonts.manrope(
              color: AppColors.rmPrimary,
              fontSize: 26.sp,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Icon(metric.icon, color: metric.color, size: 12.sp),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  metric.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: metric.color,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ),
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
  });

  final _MatchSuggestion suggestion;
  final bool isApproving;
  final bool isApproved;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfilePairAvatars(suggestion: suggestion),
              SizedBox(width: 12.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.names,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          color: AppColors.rmPrimary,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        suggestion.time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          color: AppColors.rmComparisonMuted,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              _ScoreBadge(score: suggestion.score),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            'Reason for Match',
            style: GoogleFonts.manrope(
              color: AppColors.rmPrimary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '"${suggestion.reason}"',
            style: GoogleFonts.manrope(
              color: AppColors.rmComparisonBody,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          if (suggestion.pendingInfo != null) ...[
            SizedBox(height: 12.h),
            Text(
              'Pending Info',
              style: GoogleFonts.manrope(
                color: AppColors.rmPrimary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(Icons.schedule, color: AppColors.danger, size: 13.sp),
                SizedBox(width: 5.w),
                Expanded(
                  child: Text(
                    suggestion.pendingInfo!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            height: 52.h,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(
                AppRoutes.profileDetail,
                arguments: suggestion.leftProfile,
              ),
              icon: Icon(Icons.compare_arrows, size: 16.sp),
              label: Text(
                'View Lead Profile',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rmPrimary,
                foregroundColor: AppColors.white,
                elevation: 0,
                textStyle: GoogleFonts.manrope(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _QueueActionButton(label: 'Save', onTap: () {}),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: _QueueActionButton(
                  label: 'Reject',
                  bordered: true,
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

class _ProfilePairAvatars extends StatelessWidget {
  const _ProfilePairAvatars({required this.suggestion});

  final _MatchSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54.w,
      height: 34.h,
      child: Stack(
        children: [
          _AvatarImage(image: suggestion.leftProfile.image, left: 0),
          _AvatarImage(image: suggestion.rightProfile.image, left: 24.w),
        ],
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.image, required this.left});

  final String image;
  final double left;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: 0,
      child: Container(
        width: 32.r,
        height: 32.r,
        decoration: BoxDecoration(
          color: AppColors.selectedNavItemBackgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 2),
          image: DecorationImage(
            image: image.startsWith('http')
                ? NetworkImage(image)
                : AssetImage(image) as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          score,
          style: GoogleFonts.manrope(
            color: AppColors.rmPrimary,
            fontSize: 24.sp,
            fontWeight: FontWeight.w900,
            height: 0.95,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'MATCH\nSCORE',
          textAlign: TextAlign.right,
          style: GoogleFonts.manrope(
            color: AppColors.rmComparisonMuted,
            fontSize: 9.sp,
            fontWeight: FontWeight.w900,
            height: 1.05,
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
    this.bordered = false,
    this.filled = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool bordered;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? AppColors.white : AppColors.rmComparisonStrong;

    return SizedBox(
      height: 48.h,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: filled ? AppColors.whatsappGreen : AppColors.white,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
            side: bordered
                ? const BorderSide(color: AppColors.rmPaleRoseBorder)
                : BorderSide.none,
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
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
    final topSuggestion = suggestions.isNotEmpty ? suggestions.first : null;
    final pendingCount = suggestions
        .where((item) => item.pendingInfo != null)
        .length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 18.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F8),
        borderRadius: BorderRadius.circular(18.r),
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
            children: [
              Expanded(
                child: Text(
                  'Quick Insights',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: AppColors.rmPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.trending_up, color: AppColors.rmPrimary, size: 18.sp),
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
                    color: AppColors.rmPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
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
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(12.w, 11.h, 12.w, 11.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.rmPaleRoseBorder),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.rmCardShadow,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topSuggestion?.names ?? 'No live suggestions yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: AppColors.rmPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  topSuggestion == null
                      ? 'Load profiles to generate AI pairing insights.'
                      : topSuggestion.reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: AppColors.rmComparisonMuted,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
                    color: AppColors.rmPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
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

BoxDecoration _cardDecoration() {
  return BoxDecoration(
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
  );
}

class _MatchMetric {
  const _MatchMetric({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;
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
