import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/owner/models/match_comparison_args.dart';
import 'package:koniwalamatrimonial/owner/models/registry_profile_item.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:provider/provider.dart';

class CompareProfileScreen extends StatefulWidget {
  const CompareProfileScreen({super.key, this.args});

  final MatchComparisonArgs? args;

  static const _screenshotAsset = 'assets/Screenshot 2026-05-18 150112345.png';

  @override
  State<CompareProfileScreen> createState() => _CompareProfileScreenState();
}

class _CompareProfileScreenState extends State<CompareProfileScreen> {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _comparison;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchComparison());
  }

  Future<void> _fetchComparison() async {
    final args = widget.args;
    if (args == null ||
        args.profileId.trim().isEmpty ||
        args.candidateProfileId.trim().isEmpty) {
      setState(() => _error = 'Comparison profile ids are missing.');
      return;
    }

    final token = context.read<AuthProvider>().userModel?.accessToken?.trim();
    if (token == null || token.isEmpty) {
      setState(() => _error = 'Login required to load comparison.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}'
          '${ApiConstants.profileMatchComparison(args.profileId, args.candidateProfileId)}',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _extractErrorMessage(response.body) ??
              'Comparison API failed with ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (!mounted) {
        return;
      }

      setState(() {
        _comparison = decoded is Map<String, dynamic>
            ? decoded
            : {'data': decoded};
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final showStatusCard = _isLoading || _error != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.10)),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(12.w, 18.h, 12.w, 24.h),
                  child: Column(
                    children: [
                      if (showStatusCard) ...[
                        _buildApiStatusCard(),
                        SizedBox(height: 18.h),
                      ],
                      _buildWhyTheyFitCard(),
                      SizedBox(height: 18.h),
                      _buildMatchCard(),
                      SizedBox(height: 18.h),
                      _buildLifeHabitsCard(),
                      SizedBox(height: 18.h),
                      _buildPersonalBackgroundCard(),
                      SizedBox(height: 18.h),
                      _buildWhyItMatchesCard(),
                      SizedBox(height: 18.h),
                      _buildCareerEducationCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiStatusCard() {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: _cardDecoration(radius: 12.r),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: _cardDecoration(radius: 12.r),
        child: Column(
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: AppColors.danger,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 10.h),
            OutlinedButton(
              onPressed: _fetchComparison,
              child: Text(
                'Retry',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
    }

    if (_comparison == null) {
      return const SizedBox.shrink();
    }

    return const SizedBox.shrink();
  }

  dynamic _readNested(Map<String, dynamic> json, List<String> path) {
    dynamic current = json;
    for (final key in path) {
      if (current is! Map<String, dynamic>) {
        return null;
      }
      current = current[key];
    }
    return current;
  }

  String _firstText(List<dynamic> values) {
    for (final value in values) {
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        for (final key in const ['message', 'error', 'detail']) {
          final value = decoded[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
      }
    } catch (_) {}

    final text = body.trim();
    return text.isEmpty ? null : text;
  }

  _ComparisonProfileData get _leftProfile {
    return _readComparisonProfile(
      const [
        ['ownerProfile'],
        ['owner'],
        ['profile'],
        ['leftProfile'],
        ['profileA'],
        ['profile1'],
        ['data', 'ownerProfile'],
        ['data', 'owner'],
        ['data', 'profile'],
        ['data', 'leftProfile'],
        ['data', 'profileA'],
        ['data', 'profile1'],
      ],
      fallback: const _ComparisonProfileData(
        name: 'Simmi Chahal',
        age: '27',
        id: '#WA-F2FB',
        location: 'Mumbai',
        bio: '"No biography available."',
        community: 'OTHER',
        religion: 'Sikh',
        diet: 'Vegetarian',
        smokingDrinking: 'Non Smoker /\nNon\nConsumer',
        manglik: 'No',
        education:
            'Completed graduation\nwhile pursuing a\nprofessional acting\ncareer',
        occupation: 'Actress',
        familyHistory: 'Family of\nBusinessman',
      ),
    );
  }

  _ComparisonProfileData get _rightProfile {
    return _readComparisonProfile(
      const [
        ['candidateProfile'],
        ['candidate'],
        ['matchedProfile'],
        ['rightProfile'],
        ['profileB'],
        ['profile2'],
        ['data', 'candidateProfile'],
        ['data', 'candidate'],
        ['data', 'matchedProfile'],
        ['data', 'rightProfile'],
        ['data', 'profileB'],
        ['data', 'profile2'],
      ],
      fallback: const _ComparisonProfileData(
        name: 'Bhavesh\nChaudhary',
        age: '29',
        id: '#WA-3762',
        location: 'Gurgaon',
        bio:
            '"Fond of achieving more in life and enjoying life in whatever comes along the way"',
        community: 'OTHER',
        religion: 'Hindu',
        diet: 'Non-\nVegetarian',
        smokingDrinking: 'Non Smoker /\nNon\nConsumer',
        manglik: 'No',
        education: 'M.SC (INNOVATION\nAND\nENTREPRENEURSHIP)',
        occupation: 'Managing Director',
        familyHistory: 'Family of\nBusinessman',
      ),
    );
  }

  String get _matchScoreText {
    final root = _comparison;
    if (root == null) {
      return '96%';
    }

    final score = _firstText([
      root['score'],
      root['matchScore'],
      root['compatibilityScore'],
      root['percentage'],
      _readNested(root, ['data', 'score']),
      _readNested(root, ['data', 'matchScore']),
      _readNested(root, ['data', 'compatibilityScore']),
      _readNested(root, ['data', 'percentage']),
    ]);

    if (score.isEmpty) {
      return '96%';
    }

    return score.endsWith('%') ? score : '$score%';
  }

  int get _matchScoreValue {
    final numeric = _matchScoreText.replaceAll(RegExp(r'[^0-9]'), '');
    final value = int.tryParse(numeric) ?? 96;
    return value.clamp(0, 100);
  }

  _ComparisonProfileData _readComparisonProfile(
    List<List<String>> paths, {
    required _ComparisonProfileData fallback,
  }) {
    final root = _comparison;
    if (root == null) {
      return fallback;
    }

    for (final path in paths) {
      final value = _readNested(root, path);
      if (value is Map<String, dynamic>) {
        return _ComparisonProfileData.fromJson(value, fallback: fallback);
      }
    }

    return fallback;
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 64.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0E2D8))),
      ),
      child: Row(
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: const BoxDecoration(
              color: AppColors.rmPrimary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              color: AppColors.white,
              size: 15.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Match Comparison Overview',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                color: AppColors.rmPrimary,
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close, color: AppColors.rmModalClose, size: 20.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard() {
    final left = _leftProfile;
    final right = _rightProfile;
    final matchScore = _matchScoreText;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 18.h),
      decoration: _cardDecoration(radius: 18.r),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ProfileComparisonColumn(
                  avatarAlignment: const Alignment(-0.56, -0.72),
                  name: left.displayName,
                  id: left.id,
                  location: left.location,
                  bio: left.bio,
                  imageUrl: left.imageUrl,
                ),
              ),
              Container(
                width: 1,
                height: 298.h,
                color: const Color(0xFFE9E3DE),
              ),
              Expanded(
                child: _ProfileComparisonColumn(
                  avatarAlignment: const Alignment(0.55, -0.72),
                  name: right.displayName,
                  id: right.id,
                  location: right.location,
                  bio: right.bio,
                  imageUrl: right.imageUrl,
                ),
              ),
            ],
          ),
          Positioned(
            top: 14.h,
            child: _MatchScoreBadge(
              scoreText: matchScore,
              scoreValue: _matchScoreValue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyTheyFitCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      decoration: _cardDecoration(radius: 18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionCaption('WHY THEY FIT'),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _FitChip(
                  icon: Icons.groups_outlined,
                  text: 'Same Community',
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _FitChip(
                  icon: Icons.calendar_today_outlined,
                  text: 'Close Age Match',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLifeHabitsCard() {
    final left = _leftProfile;
    final right = _rightProfile;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 18.h),
      decoration: _cardDecoration(radius: 18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('LIFE & HABITS', color: AppColors.rmHeading),
          SizedBox(height: 20.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _HabitRow(label: 'DIETARY\nPREFERENCE', value: left.diet),
                    const _HabitGap(),
                    _HabitRow(
                      label: 'SMOKING\n/\nDRINKING',
                      value: left.smokingDrinking,
                    ),
                    const _HabitGap(),
                    _HabitRow(label: 'MANGLIK STATUS', value: left.manglik),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 122.h,
                margin: EdgeInsets.symmetric(horizontal: 12.w),
                color: const Color(0xFFE9E3DE),
              ),
              Expanded(
                child: Column(
                  children: [
                    _HabitRow(label: 'DIETARY\nPREFERENCE', value: right.diet),
                    const _HabitGap(),
                    _HabitRow(
                      label: 'SMOKING\n/\nDRINKING',
                      value: right.smokingDrinking,
                    ),
                    const _HabitGap(),
                    _HabitRow(label: 'MANGLIK STATUS', value: right.manglik),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalBackgroundCard() {
    final left = _leftProfile;
    final right = _rightProfile;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 18.h),
      decoration: _cardDecoration(radius: 18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('PERSONAL BACKGROUND'),
          SizedBox(height: 18.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ComparisonDetailColumn(
                  name: left.name,
                  rows: [
                    _ComparisonDetail(
                      label: 'COMMUNITY',
                      value: left.community,
                    ),
                    _ComparisonDetail(label: 'RELIGION', value: left.religion),
                    const _ComparisonDetail(
                      label: 'LANGUAGES',
                      value: 'ENGLISH',
                      chip: true,
                    ),
                    _ComparisonDetail(
                      label: 'FAMILY\nHISTORY',
                      value: left.familyHistory,
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 190.h,
                margin: EdgeInsets.symmetric(horizontal: 12.w),
                color: const Color(0xFFE9E3DE),
              ),
              Expanded(
                child: _ComparisonDetailColumn(
                  name: right.name,
                  rows: [
                    _ComparisonDetail(
                      label: 'COMMUNITY',
                      value: right.community,
                    ),
                    _ComparisonDetail(label: 'RELIGION', value: right.religion),
                    const _ComparisonDetail(
                      label: 'LANGUAGES',
                      value: 'ENGLISH',
                      chip: true,
                    ),
                    _ComparisonDetail(
                      label: 'FAMILY\nHISTORY',
                      value: right.familyHistory,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhyItMatchesCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 16.h),
      decoration: _cardDecoration(radius: 18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('WHY IT MATCHES'),
          SizedBox(height: 18.h),
          const _MatchReasonRow(
            color: AppColors.rmPrimary,
            icon: Icons.verified,
            text: 'Matches expectations',
          ),
          SizedBox(height: 16.h),
          const _MatchReasonRow(
            color: AppColors.success,
            icon: Icons.check_circle,
            text: 'Good family fit',
          ),
        ],
      ),
    );
  }

  Widget _buildCareerEducationCard() {
    final left = _leftProfile;
    final right = _rightProfile;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 18.h),
      decoration: _cardDecoration(radius: 18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('CAREER & EDUCATION'),
          SizedBox(height: 18.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ComparisonDetailColumn(
                  name: left.name,
                  rows: [
                    _ComparisonDetail(
                      label: 'ACADEMIC\nBACKGROUND',
                      value: left.education,
                    ),
                    _ComparisonDetail(
                      label: 'CURRENT JOB',
                      value: left.occupation,
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 210.h,
                margin: EdgeInsets.symmetric(horizontal: 12.w),
                color: const Color(0xFFE9E3DE),
              ),
              Expanded(
                child: _ComparisonDetailColumn(
                  name: right.name,
                  rows: [
                    _ComparisonDetail(
                      label: 'ACADEMIC\nBACKGROUND',
                      value: right.education,
                    ),
                    _ComparisonDetail(
                      label: 'CURRENT JOB',
                      value: right.occupation,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCaption(String text) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        color: AppColors.rmComparisonCaption,
        fontSize: 13.sp,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _sectionTitle(String text, {Color color = AppColors.rmPrimary}) {
    return Text(
      text,
      style: GoogleFonts.playfairDisplay(
        color: color,
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  BoxDecoration _cardDecoration({required double radius}) {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFF2DDD3)),
      boxShadow: [
        BoxShadow(
          color: const Color(0x14CD6124),
          blurRadius: 18.r,
          offset: Offset(0, 7.h),
        ),
      ],
    );
  }
}

class _ComparisonProfileData {
  const _ComparisonProfileData({
    required this.name,
    required this.age,
    required this.id,
    required this.location,
    required this.bio,
    required this.community,
    required this.religion,
    required this.diet,
    required this.smokingDrinking,
    required this.manglik,
    required this.education,
    required this.occupation,
    required this.familyHistory,
    this.imageUrl,
  });

  final String name;
  final String age;
  final String id;
  final String location;
  final String bio;
  final String community;
  final String religion;
  final String diet;
  final String smokingDrinking;
  final String manglik;
  final String education;
  final String occupation;
  final String familyHistory;
  final String? imageUrl;

  String get displayName {
    return age.isEmpty || age == '-' ? name : '$name, $age';
  }

  factory _ComparisonProfileData.fromJson(
    Map<String, dynamic> json, {
    required _ComparisonProfileData fallback,
  }) {
    final rawId = _firstText([
      json['referenceId'],
      json['profileCode'],
      json['shortCode'],
      json['id'],
    ]);
    final age = _firstText([json['age'], _ageFromDate(json['dateOfBirth'])]);

    return _ComparisonProfileData(
      name: _firstText([
        json['name'],
        json['fullName'],
      ], fallback: fallback.name),
      age: _firstText([age], fallback: fallback.age),
      id: rawId.isEmpty ? fallback.id : '#${_shortId(rawId)}',
      location: _firstText([
        json['currentResidential'],
        json['city'],
        json['nativePlace'],
        json['state'],
        json['country'],
      ], fallback: fallback.location),
      bio: _quoted(
        _firstText([
          json['aboutMe'],
          json['bio'],
          json['summary'],
        ], fallback: fallback.bio.replaceAll('"', '')),
      ),
      community: _firstText([json['community']], fallback: fallback.community),
      religion: _firstText([json['religion']], fallback: fallback.religion),
      diet: _firstText([json['diet']], fallback: fallback.diet),
      smokingDrinking: _firstText([
        json['smokingDrinking'],
        json['smoking'],
        json['drinking'],
      ], fallback: fallback.smokingDrinking),
      manglik: _manglikText(json['manglik'], fallback: fallback.manglik),
      education: _firstText([
        json['education'],
        json['educationDetails'],
      ], fallback: fallback.education),
      occupation: _firstText([
        json['occupation'],
        json['profession'],
        json['company'],
      ], fallback: fallback.occupation),
      familyHistory: _firstText([
        json['familyStatus'],
        json['familyType'],
        json['fatherOccupation'],
      ], fallback: fallback.familyHistory),
      imageUrl: _firstText([json['image'], _firstPhoto(json['photoUrls'])]),
    );
  }

  static String _firstText(List<dynamic> values, {String fallback = ''}) {
    for (final value in values) {
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return fallback;
  }

  static String? _firstPhoto(dynamic value) {
    if (value is List && value.isNotEmpty) {
      return _firstText(value);
    }
    return null;
  }

  static String _quoted(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith('"') && trimmed.endsWith('"')) {
      return trimmed;
    }
    return '"$trimmed"';
  }

  static String _manglikText(dynamic value, {required String fallback}) {
    if (value is bool) {
      return value ? 'Yes' : 'No';
    }
    return _firstText([value], fallback: fallback);
  }

  static String _ageFromDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) {
      return '';
    }
    final now = DateTime.now();
    var age = now.year - date.year;
    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      age--;
    }
    return '$age';
  }

  static String _shortId(String value) {
    final text = value.trim();
    if (text.isEmpty || text.startsWith('WA-')) {
      return text;
    }
    return text.length <= 8
        ? text.toUpperCase()
        : text.substring(0, 8).toUpperCase();
  }
}

class _ProfileComparisonColumn extends StatelessWidget {
  const _ProfileComparisonColumn({
    required this.avatarAlignment,
    required this.name,
    required this.id,
    required this.location,
    required this.bio,
    this.imageUrl,
  });

  final Alignment avatarAlignment;
  final String name;
  final String id;
  final String location;
  final String bio;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Column(
        children: [
          _ComparisonAvatar(alignment: avatarAlignment, imageUrl: imageUrl),
          SizedBox(height: 18.h),
          SizedBox(
            height: 56.h,
            child: Center(
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  color: AppColors.rmPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ),
          SizedBox(height: 4.h),
          _IdChip(id),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14.sp,
                color: AppColors.rmMutedText,
              ),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  location,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: AppColors.rmComparisonMeta,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          SizedBox(
            height: 92.h,
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                bio,
                textAlign: TextAlign.center,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  color: AppColors.rmComparisonBody,
                  fontSize: 10.8.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.profileDetail,
                arguments: _registryItemFromComparison(name, id, imageUrl),
              );
            },
            icon: Icon(Icons.remove_red_eye_outlined, size: 12.sp),
            label: Text(
              'View Full Profile',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 11.6.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.rmPrimary,
              side: BorderSide(color: AppColors.rmPrimary, width: 1.w),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              minimumSize: Size(0, 34.h),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  RegistryProfileItem _registryItemFromComparison(
    String name,
    String id,
    String? imageUrl,
  ) {
    return RegistryProfileItem(
      id: id.startsWith('#') ? id.substring(1) : id,
      originalId: id.startsWith('#') ? id.substring(1) : id,
      name: name,
      age: '-',
      height: '-',
      city: '-',
      work: '-',
      profession: '-',
      community: '-',
      type: 'Profile',
      isPremium: false,
      image: imageUrl ?? 'assets/wedding_hero 1.png',
      photoUrls: [imageUrl ?? 'assets/wedding_hero 1.png'],
      dateOfBirth: '-',
      birthTime: '-',
      birthPlace: '-',
      gotra: '-',
      residential: '-',
      aboutMe: '-',
      religion: '-',
      diet: '-',
      manglikLabel: '-',
      country: '-',
      fatherName: '-',
      motherName: '-',
      paternalDetails: '-',
      maternalDetails: '-',
    );
  }
}

class _ComparisonAvatar extends StatelessWidget {
  const _ComparisonAvatar({required this.alignment, this.imageUrl});

  final Alignment alignment;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: url.startsWith('http')
          ? Image.network(
              url,
              width: 92.r,
              height: 92.r,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallbackAvatar(),
            )
          : _fallbackAvatar(),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      width: 92.r,
      height: 92.r,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage(CompareProfileScreen._screenshotAsset),
          fit: BoxFit.none,
          alignment: alignment,
        ),
      ),
    );
  }
}

class _MatchScoreBadge extends StatelessWidget {
  const _MatchScoreBadge({required this.scoreText, required this.scoreValue});

  final String scoreText;
  final int scoreValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74.r,
      height: 74.r,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.07),
            blurRadius: 14.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(6.r),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: CircularProgressIndicator(
                value: scoreValue / 100,
                strokeWidth: 4.2,
                strokeCap: StrokeCap.round,
                backgroundColor: const Color(0xFFE5E5E5),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.rmTeal,
                ),
              ),
            ),
            Container(
              width: 50.r,
              height: 50.r,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    scoreText,
                    style: GoogleFonts.manrope(
                      color: AppColors.rmComparisonStrong,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'MATCH',
                    style: GoogleFonts.manrope(
                      color: AppColors.rmTeal,
                      fontSize: 7.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      height: 1,
                    ),
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

class _IdChip extends StatelessWidget {
  const _IdChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.rmComparisonIdBorder),
      ),
      child: Text(
        'ID: $text',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.manrope(
          color: AppColors.rmComparisonMuted,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FitChip extends StatelessWidget {
  const _FitChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppColors.rmComparisonTealBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.rmComparisonTealBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14.sp, color: AppColors.rmTeal),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: AppColors.rmTeal,
                fontSize: 11.4.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitGap extends StatelessWidget {
  const _HabitGap();

  @override
  Widget build(BuildContext context) => SizedBox(height: 14.h);
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 10.h),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE9E3DE))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                color: AppColors.rmComparisonMuted,
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(
                color: AppColors.rmComparisonStrong,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonDetail {
  const _ComparisonDetail({
    required this.label,
    required this.value,
    this.chip = false,
  });

  final String label;
  final String value;
  final bool chip;
}

class _ComparisonDetailColumn extends StatelessWidget {
  const _ComparisonDetailColumn({required this.name, required this.rows});

  final String name;
  final List<_ComparisonDetail> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PersonMiniHeader(name: name),
        SizedBox(height: 18.h),
        for (var i = 0; i < rows.length; i++) ...[
          _ComparisonDetailRow(detail: rows[i]),
          if (i != rows.length - 1) SizedBox(height: 16.h),
        ],
      ],
    );
  }
}

class _PersonMiniHeader extends StatelessWidget {
  const _PersonMiniHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28.r,
          height: 28.r,
          decoration: const BoxDecoration(
            color: AppColors.rmPersonBadgeBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_outline,
            color: AppColors.rmPrimary,
            size: 15.sp,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: AppColors.rmPrimary,
              fontSize: 12.6.sp,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _ComparisonDetailRow extends StatelessWidget {
  const _ComparisonDetailRow({required this.detail});

  final _ComparisonDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 8.h),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.rmRowDivider, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              detail.label,
              style: GoogleFonts.manrope(
                color: AppColors.rmComparisonLabel,
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: detail.chip
                  ? Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.rmComparisonChipBg,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        detail.value,
                        style: GoogleFonts.manrope(
                          color: AppColors.rmComparisonChipText,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : Text(
                      detail.value,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.manrope(
                        color: AppColors.rmComparisonStrong,
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchReasonRow extends StatelessWidget {
  const _MatchReasonRow({
    required this.color,
    required this.icon,
    required this.text,
  });

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.manrope(
              color: AppColors.rmComparisonStrong,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
