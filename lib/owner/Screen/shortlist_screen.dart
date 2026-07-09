import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/owner/models/match_comparison_args.dart';
import 'package:koniwalamatrimonial/owner/models/registry_profile_item.dart';
import 'package:koniwalamatrimonial/owner/providers/registry_profiles_provider.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:provider/provider.dart';

class ShortlistScreen extends StatefulWidget {
  const ShortlistScreen({super.key, this.profile});

  final RegistryProfileItem? profile;

  @override
  State<ShortlistScreen> createState() => _ShortlistScreenState();
}

class _ShortlistScreenState extends State<ShortlistScreen> {
  List<_ShortlistedProfile> _shortlistedProfiles = const [];
  bool _isLoadingShortlist = false;
  String? _shortlistError;
  String? _requestedAccessToken;
  bool _hasRequestedShortlist = false;
  final Set<String> _addingShortlistProfileIds = <String>{};
  final Set<String> _sendingShortlistCandidateIds = <String>{};

  String get _currentProfileId {
    final profileId = widget.profile?.originalId.trim() ?? '';
    return profileId == '-' ? '' : profileId;
  }

  bool get _hasCurrentProfile => _currentProfileId.isNotEmpty;

  bool get _showLegacyGroomCard => false;

  bool get _isCurrentProfileGroom => widget.profile?.type == 'Groom';

  String get _candidateProfileType => _isCurrentProfileGroom ? 'bride' : 'groom';

  String get _candidateOppositeGenderOf =>
      _isCurrentProfileGroom ? 'male' : 'female';

  String get _candidateProfileLabel =>
      _isCurrentProfileGroom ? 'Bride' : 'Groom';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authProvider = context.watch<AuthProvider>();
    final accessToken = authProvider.userModel?.accessToken;

    if (!authProvider.isInitialized ||
        (_hasRequestedShortlist && accessToken == _requestedAccessToken)) {
      return;
    }

    _requestedAccessToken = accessToken;
    _hasRequestedShortlist = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _fetchShortlist(accessToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final displayName = profile?.name ?? 'Simmi Chahal';
    final headerImage = profile?.image ?? 'assets/wedding_hero 1.png';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.rmSoftPink,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 200.h,
              backgroundColor: AppColors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.rmPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    _buildHeaderImage(headerImage),
                    Positioned(
                      top: 80.h,
                      left: 16.w,
                      right: 16.w,
                      child: Container(
                        padding: EdgeInsets.fromLTRB(12.r, 0.r, 10.r, 12.r),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: AppColors.rmPaleRoseBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoGrid(profile),
                            // SizedBox(height: 10.h),
                            // const Divider(),
                            _buildInfoItem(
                              Icons.attach_money,
                              'Budget Not Specified',
                              'Budget',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.r, 8.h, 16.r, 4.r),
                child: Column(
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 40.h),
                        side: BorderSide(color: AppColors.rmPrimary),
                      ),
                      child: Text(
                        'View $displayName Profile',
                        style: GoogleFonts.manrope(
                          color: AppColors.rmPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ElevatedButton(
                      onPressed: () {
                        if (!_hasCurrentProfile) {
                          _showSnackBar(
                            context,
                            'Open shortlist from a profile card before adding candidates.',
                            isError: true,
                          );
                          return;
                        }

                        final accessToken = context
                            .read<AuthProvider>()
                            .userModel
                            ?.accessToken;
                        context.read<RegistryProfilesProvider>().fetchProfiles(
                          accessToken,
                          forceRefresh: true,
                          oppositeGenderOf: _candidateOppositeGenderOf,
                          profileType: _candidateProfileType,
                        );
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: AppColors.transparent,
                          builder: (context) => Material(
                            color: AppColors.transparent,
                            child: SingleChildScrollView(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(
                                  context,
                                ).viewInsets.bottom,
                              ),
                              child: Container(
                                padding: EdgeInsets.all(16.r),
                                constraints: BoxConstraints(minHeight: 400.h),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20.r),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Add $_candidateProfileLabel Profiles',
                                      style: GoogleFonts.manrope(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      'Select a profile to add directly into $displayName\'s shortlist.',
                                      style: GoogleFonts.manrope(
                                        color: AppColors.rmHeading,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w400,
                                        height: 1.43,
                                      ),
                                    ),
                                    SizedBox(height: 16.h),
                                    Container(
                                      height: 40.h,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        border: Border.all(
                                          color: AppColors.rmBorder,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.search,
                                            color: AppColors.rmMutedText,
                                          ),
                                          SizedBox(width: 8.w),
                                          Expanded(
                                            child: TextField(
                                              decoration: InputDecoration(
                                                hintText: 'Search profiles...',
                                                hintStyle: GoogleFonts.manrope(
                                                  color: AppColors.rmMutedText,
                                                  fontSize: 14.sp,
                                                ),
                                                border: InputBorder.none,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 7.h),
                                    Consumer<RegistryProfilesProvider>(
                                      builder: (context, profilesProvider, _) {
                                        return _buildGroomProfilesSheetList(
                                          profilesProvider,
                                        );
                                      },
                                    ),
                                    if (_showLegacyGroomCard)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: ShapeDecoration(
                                        color: AppColors.white,
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                            width: 1,
                                            color: AppColors.hrMetricBorder,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10.r),
                                                child: Image.asset(
                                                  'assets/wedding_hero 1.png',
                                                  width: 70.w,
                                                  height: 70.w,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              SizedBox(width: 14.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            'Bhavesh Chaudhary',
                                                            style: GoogleFonts.manrope(
                                                              fontSize: 16.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              color: AppColors
                                                                  .rmPrimary,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        SizedBox(width: 8.w),
                                                        TextButton(
                                                          onPressed: () {},
                                                          style: TextButton.styleFrom(
                                                            minimumSize:
                                                                Size.zero,
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      6.w,
                                                                  vertical: 4.h,
                                                                ),
                                                            tapTargetSize:
                                                                MaterialTapTargetSize
                                                                    .shrinkWrap,
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Image.asset(
                                                                'assets/view_icon.png',
                                                                width: 16.w,
                                                                height: 16.w,
                                                              ),
                                                              SizedBox(
                                                                width: 4.w,
                                                              ),
                                                              Text(
                                                                'View',
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: GoogleFonts.manrope(
                                                                  color: AppColors
                                                                      .rmPrimary,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  fontSize:
                                                                      14.sp,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      'ID: #WA-3762',
                                                      style:
                                                          GoogleFonts.manrope(
                                                            fontSize: 12.sp,
                                                            color: AppColors
                                                                .rmMutedText,
                                                          ),
                                                    ),
                                                    SizedBox(height: 2.h),
                                                    Text(
                                                      '29 Yrs • 6\'2" • Surat',
                                                      style:
                                                          GoogleFonts.manrope(
                                                            fontSize: 13.sp,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 14.h),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: () {},
                                                  style: OutlinedButton.styleFrom(
                                                    side: BorderSide(
                                                      color:
                                                          AppColors.rmPrimary,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            18.r,
                                                          ),
                                                    ),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8.w,
                                                        ),
                                                    minimumSize: Size(0, 36.h),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Image.asset(
                                                        'assets/view_icon.png',
                                                        width: 16.w,
                                                        height: 16.w,
                                                      ),
                                                      SizedBox(width: 4.w),
                                                      Flexible(
                                                        child: Text(
                                                          'View',
                                                          style:
                                                              GoogleFonts.manrope(
                                                                color: AppColors
                                                                    .rmPrimary,
                                                                fontSize: 13.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () {},
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.rmPrimary,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            18.r,
                                                          ),
                                                    ),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8.w,
                                                        ),
                                                    minimumSize: Size(0, 36.h),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Image.asset(
                                                        'assets/add_white_icon.png',
                                                        width: 16.w,
                                                        height: 16.w,
                                                      ),
                                                      SizedBox(width: 4.w),
                                                      Flexible(
                                                        child: Text(
                                                          'Add to Shortlist',
                                                          style:
                                                              GoogleFonts.manrope(
                                                                color: AppColors
                                                                    .white,
                                                                fontSize: 13.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 16.h),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.rmPrimary,
                        minimumSize: Size(double.infinity, 44.h),
                      ),
                      child: Text(
                        'Add $_candidateProfileLabel Profiles',
                        style: GoogleFonts.manrope(
                          color: AppColors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Container(
                      color: AppColors.white,
                      child: TabBar(
                        isScrollable: true,
                        labelColor: AppColors.rmPrimary,
                        unselectedLabelColor: AppColors.rmMutedText,
                        indicatorColor: AppColors.rmPrimary,
                        indicatorWeight: 2.w,
                        indicatorPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                        ),
                        labelStyle: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp,
                        ),
                        unselectedLabelStyle: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp,
                        ),
                        tabs: const [
                          Tab(text: 'Manual Shortlists'),
                          Tab(text: 'AI Shortlists'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(8.r, 8.r, 8.r, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 50.h,
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(18.r),
                                border: Border.all(color: AppColors.rmBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.search,
                                    color: AppColors.rmMutedText,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      'Search...',
                                      style: GoogleFonts.manrope(
                                        color: AppColors.rmMutedText,
                                        fontSize: 16.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.tune, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [_buildList(), const SizedBox.shrink()],
          ),
        ),
      ),
    );
  }

  Widget _buildGroomProfilesSheetList(
    RegistryProfilesProvider profilesProvider,
  ) {
    if (profilesProvider.isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 28.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (profilesProvider.error != null) {
      return _ShortlistMessage(
        message: profilesProvider.error!,
        actionLabel: 'Retry',
        onActionPressed: () {
          final accessToken = context
              .read<AuthProvider>()
              .userModel
              ?.accessToken;
          context.read<RegistryProfilesProvider>().fetchProfiles(
            accessToken,
            forceRefresh: true,
            oppositeGenderOf: _candidateOppositeGenderOf,
            profileType: _candidateProfileType,
          );
        },
      );
    }

    final candidateProfiles = profilesProvider.profiles
        .where(
          (profile) =>
              profile.type == _candidateProfileLabel &&
              profile.originalId != _currentProfileId,
        )
        .toList();

    if (candidateProfiles.isEmpty) {
      return _ShortlistMessage(
        message: 'No ${_candidateProfileLabel.toLowerCase()} profiles found.',
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 420.h),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: candidateProfiles.length,
        separatorBuilder: (_, _) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          return _buildGroomProfileSheetCard(candidateProfiles[index]);
        },
      ),
    );
  }

  Widget _buildGroomProfileSheetCard(RegistryProfileItem profile) {
    final isAdding = _addingShortlistProfileIds.contains(profile.originalId);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: ShapeDecoration(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: AppColors.hrMetricBorder),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: _buildRegistryProfileThumb(profile.image),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.name,
                            style: GoogleFonts.manrope(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.rmPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        TextButton(
                          onPressed: () => _viewRegistryProfile(profile),
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 4.h,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/view_icon.png',
                                width: 16.w,
                                height: 16.w,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'View',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  color: AppColors.rmPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'ID: #${profile.id}',
                      style: GoogleFonts.manrope(
                        fontSize: 12.sp,
                        color: AppColors.rmMutedText,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${profile.age} Yrs - ${profile.height} - ${profile.city}',
                      style: GoogleFonts.manrope(fontSize: 13.sp),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _viewRegistryProfile(profile),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.rmPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    minimumSize: Size(0, 36.h),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/view_icon.png',
                        width: 16.w,
                        height: 16.w,
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          'View',
                          style: GoogleFonts.manrope(
                            color: AppColors.rmPrimary,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: isAdding
                      ? null
                      : () => _addGroomToShortlist(profile),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rmPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    minimumSize: Size(0, 36.h),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/add_white_icon.png',
                        width: 16.w,
                        height: 16.w,
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          isAdding ? 'Adding...' : 'Add to Shortlist',
                          style: GoogleFonts.manrope(
                            color: AppColors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegistryProfileThumb(String image) {
    if (image.startsWith('http')) {
      return Image.network(
        image,
        width: 70.w,
        height: 70.w,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackRegistryProfileThumb(),
      );
    }

    return Image.asset(
      image,
      width: 70.w,
      height: 70.w,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _fallbackRegistryProfileThumb(),
    );
  }

  Widget _fallbackRegistryProfileThumb() {
    return Image.asset(
      'assets/wedding_hero 1.png',
      width: 70.w,
      height: 70.w,
      fit: BoxFit.cover,
    );
  }

  void _viewRegistryProfile(RegistryProfileItem profile) {
    Navigator.of(context).pushNamed(AppRoutes.profileDetail, arguments: profile);
  }

  Future<void> _addGroomToShortlist(RegistryProfileItem profile) async {
    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    final token = accessToken?.trim() ?? '';

    if (token.isEmpty) {
      _showSnackBar(
        context,
        'Login required to add shortlisted profile.',
        isError: true,
      );
      return;
    }

    if (!_hasCurrentProfile) {
      _showSnackBar(
        context,
        'Open shortlist from a profile card before adding candidates.',
        isError: true,
      );
      return;
    }

    setState(() => _addingShortlistProfileIds.add(profile.originalId));

    try {
      var response = await _postShortlistCandidate(
        token: token,
        ownerProfileId: _currentProfileId,
        candidateProfileId: profile.originalId,
        bodyKey: 'shortlistedProfileId',
      );

      if (_shouldRetryShortlistAddWithCandidateProfileId(response)) {
        response = await _postShortlistCandidate(
          token: token,
          ownerProfileId: _currentProfileId,
          candidateProfileId: profile.originalId,
          bodyKey: 'candidateProfileId',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _extractApiErrorMessage(response.body) ??
              'Shortlist add API failed with ${response.statusCode}',
        );
      }

      await _fetchShortlist(token);

      if (!mounted) {
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Success',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
          ),
          content: Text(
            '${profile.name} added to shortlist.',
            style: GoogleFonts.manrope(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close bottom sheet
              },
              child: Text(
                'OK',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        _showSnackBar(
          context,
          _cleanExceptionMessage(
            error,
            fallback: 'Unable to add shortlisted profile.',
          ),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _addingShortlistProfileIds.remove(profile.originalId));
      }
    }
  }

  Future<http.Response> _postShortlistCandidate({
    required String token,
    required String ownerProfileId,
    required String candidateProfileId,
    required String bodyKey,
  }) {
    return http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}'
        '${ApiConstants.shortlistProfileCandidates(_currentProfileId)}',
      ),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'ownerProfileId': ownerProfileId,
        bodyKey: candidateProfileId,
      }),
    );
  }

  bool _shouldRetryShortlistAddWithCandidateProfileId(
    http.Response response,
  ) {
    if (response.statusCode != 400 &&
        response.statusCode != 422 &&
        response.statusCode != 500) {
      return false;
    }

    final message = (_extractApiErrorMessage(response.body) ?? '').toLowerCase();
    return message.contains('candidateprofileid') ||
        message.contains('shortlistedprofileid') ||
        message.contains('property');
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
            return value
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .join(', ');
          }
        }
      }
    } catch (_) {}

    final text = body.trim();
    return text.isEmpty ? null : text;
  }

  String _cleanExceptionMessage(Object error, {required String fallback}) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? fallback : message;
  }

  Future<void> _fetchShortlist(String? accessToken) async {
    if (!_hasCurrentProfile) {
      setState(() {
        _isLoadingShortlist = false;
        _shortlistError = 'Open shortlist from a profile card first.';
        _shortlistedProfiles = const [];
      });
      return;
    }

    if (accessToken == null || accessToken.isEmpty) {
      setState(() {
        _isLoadingShortlist = false;
        _shortlistError = 'Login required to load shortlist.';
        _shortlistedProfiles = const [];
      });
      return;
    }

    setState(() {
      _isLoadingShortlist = true;
      _shortlistError = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.shortlistProfile(_currentProfileId)}',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Shortlist API failed with ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      final rows = _extractShortlistRows(decoded);
      final profiles = rows
          .whereType<Map<String, dynamic>>()
          .map(_ShortlistedProfile.fromJson)
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _shortlistedProfiles = profiles;
        _isLoadingShortlist = false;
        _shortlistError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingShortlist = false;
        _shortlistError = 'Unable to load shortlist.';
        _shortlistedProfiles = const [];
      });
    }
  }

  List<dynamic> _extractShortlistRows(dynamic payload) {
    if (payload is List) {
      return payload;
    }

    if (payload is Map<String, dynamic>) {
      for (final key in const [
        'data',
        'shortlists',
        'candidates',
        'items',
        'results',
      ]) {
        final value = payload[key];

        if (value is List) {
          return value;
        }

        final nestedRows = _extractShortlistRows(value);
        if (nestedRows.isNotEmpty) {
          return nestedRows;
        }
      }
    }

    return const [];
  }

  Future<void> _retryShortlist() {
    return _fetchShortlist(_requestedAccessToken);
  }

  Widget _buildList() {
    if (_isLoadingShortlist) {
      return ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 28.h),
        children: const [Center(child: CircularProgressIndicator())],
      );
    }

    if (_shortlistError != null) {
      return ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 28.h),
        children: [
          _ShortlistMessage(
            message: _shortlistError!,
            actionLabel: 'Retry',
            onActionPressed: _retryShortlist,
          ),
        ],
      );
    }

    if (_shortlistedProfiles.isEmpty) {
      return ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 28.h),
        children: [
          const _ShortlistMessage(message: 'No shortlisted profiles found.'),
        ],
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: _shortlistedProfiles.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) =>
          _buildProfileCard(context, _shortlistedProfiles[index]),
    );
  }

  Widget _buildProfileCard(BuildContext context, _ShortlistedProfile profile) {
    final isSending = _sendingShortlistCandidateIds.contains(
      profile.shortlistCandidateId,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: _ShortlistProfileImage(
                    image: profile.image,
                    width: 70.w,
                    height: 70.w,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: GoogleFonts.manrope(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.rmPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '#${profile.shortCode} - ${profile.statusLabel}',
                        style: GoogleFonts.manrope(
                          fontSize: 12.sp,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          _buildShortInfoItem(
                            Icons.person,
                            '${profile.age} Yrs',
                          ),
                          SizedBox(width: 8.w),
                          _buildShortInfoItem(Icons.height, profile.height),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                _buildTag(profile.work),
                _buildTag(profile.company),
                _buildTag(profile.manglik),
              ],
            ),
            SizedBox(height: 14.h),
            ElevatedButton(
              onPressed: () => _openCompareProfile(profile),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rmPrimary,
                minimumSize: Size(double.infinity, 44.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Compare Profile',
                style: GoogleFonts.manrope(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSending
                        ? null
                        : () => _sendShortlistedProfile(profile),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(0, 36.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      isSending ? 'Sending...' : 'Send Profile',
                      style: GoogleFonts.manrope(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _showRemoveFromShortlistSheet(context, profile),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(0, 36.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Remove',
                      style: GoogleFonts.manrope(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openCompareProfile(_ShortlistedProfile profile) {
    if (!_hasCurrentProfile || profile.profileId.isEmpty) {
      _showSnackBar(
        context,
        'Comparison profile ids are missing.',
        isError: true,
      );
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.compareProfile,
      arguments: MatchComparisonArgs(
        profileId: _currentProfileId,
        candidateProfileId: profile.profileId,
      ),
    );
  }

  Future<void> _sendShortlistedProfile(_ShortlistedProfile profile) async {
    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    final token = accessToken?.trim() ?? '';

    if (token.isEmpty) {
      _showSnackBar(
        context,
        'Login required to send shortlisted profile.',
        isError: true,
      );
      return;
    }

    if (!_hasCurrentProfile) {
      _showSnackBar(
        context,
        'Open shortlist from a profile card before sending profiles.',
        isError: true,
      );
      return;
    }

    final candidateId = profile.shortlistCandidateId.trim();
    if (candidateId.isEmpty) {
      _showSnackBar(
        context,
        'Shortlist candidate id is missing.',
        isError: true,
      );
      return;
    }

    setState(() => _sendingShortlistCandidateIds.add(candidateId));

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.shortlistsSend}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'ownerProfileId': _currentProfileId,
          'shortlistCandidateId': candidateId,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _extractApiErrorMessage(response.body) ??
              'Send profile API failed with ${response.statusCode}',
        );
      }

      await _fetchShortlist(token);

      if (!mounted) {
        return;
      }

      _showSnackBar(context, '${profile.name} sent successfully.');
    } catch (error) {
      if (mounted) {
        _showSnackBar(
          context,
          _cleanExceptionMessage(
            error,
            fallback: 'Unable to send shortlisted profile.',
          ),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sendingShortlistCandidateIds.remove(candidateId));
      }
    }
  }

  void _showRemoveFromShortlistSheet(
    BuildContext context,
    _ShortlistedProfile profile,
  ) {
    final screenContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) {
        var isRemoving = false;

        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final colorScheme = Theme.of(modalContext).colorScheme;
            final sheetSurfaceColor = colorScheme.surface;
            final primaryColor = AppColors.rmPrimary;
            final titleColor = AppColors.rmHeading;
            final bodyColor = AppColors.rmBodyText;
            final mutedColor = AppColors.rmMutedText;
            final dangerColor = AppColors.danger;
            final warningBgColor = AppColors.rmStatusBg;
            final warningBorderColor = AppColors.rmStatusBorder;

            Future<void> confirmRemoval() async {
              if (isRemoving) {
                return;
              }

              setModalState(() => isRemoving = true);
              final removed = await _deleteShortlistCandidate(
                screenContext,
                profile,
              );

              if (!modalContext.mounted) {
                return;
              }

              if (removed) {
                Navigator.pop(modalContext);
                if (screenContext.mounted) {
                  _showSnackBar(
                    screenContext,
                    'Profile removed from shortlist.',
                  );
                }
              } else {
                setModalState(() => isRemoving = false);
              }
            }

            return SafeArea(
              top: false,
              child: Container(
                padding: EdgeInsets.fromLTRB(14.w, 14.h, 12.w, 12.h),
                decoration: BoxDecoration(
                  color: sheetSurfaceColor,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.r),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Remove from Shortlist',
                                style: GoogleFonts.manrope(
                                  color: titleColor,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Are you sure you want to remove this\nprofile from the shortlist?',
                                style: GoogleFonts.manrope(
                                  color: bodyColor,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: isRemoving
                              ? null
                              : () => Navigator.pop(modalContext),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints.tight(Size(34.r, 34.r)),
                          icon: Icon(
                            Icons.close,
                            color: mutedColor,
                            size: 26.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: sheetSurfaceColor,
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(color: primaryColor),
                      ),
                      child: Row(
                        children: [
                          ClipOval(
                            child: _ShortlistProfileImage(
                              image: profile.image,
                              width: 42.r,
                              height: 42.r,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(
                                    color: titleColor,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  '#${profile.shortCode}',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(
                                    color: bodyColor,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: isRemoving ? null : confirmRemoval,
                            style: TextButton.styleFrom(
                              foregroundColor: dangerColor,
                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              minimumSize: Size(0, 32.h),
                            ),
                            child: Text(
                              'REMOVE',
                              style: GoogleFonts.manrope(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: warningBgColor,
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(color: warningBorderColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 17.sp,
                            color: bodyColor,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              'This will only remove the candidate from\nthis client\'s shortlist. The profile will remain\nactive in the main registry.',
                              style: GoogleFonts.manrope(
                                color: bodyColor,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 22.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isRemoving
                                ? null
                                : () => Navigator.pop(modalContext),
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                              minimumSize: Size(double.infinity, 44.h),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.manrope(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isRemoving ? null : confirmRemoval,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: dangerColor,
                              foregroundColor: AppColors.white,
                              minimumSize: Size(double.infinity, 44.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              elevation: 0,
                            ),
                            child: isRemoving
                                ? SizedBox(
                                    width: 18.r,
                                    height: 18.r,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : Text(
                                    'Remove Profile',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _deleteShortlistCandidate(
    BuildContext context,
    _ShortlistedProfile profile,
  ) async {
    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    final candidateId = profile.shortlistCandidateId.trim();

    if (accessToken == null || accessToken.isEmpty) {
      _showSnackBar(
        context,
        'Login required to remove shortlisted profile.',
        isError: true,
      );
      return false;
    }

    if (candidateId.isEmpty) {
      _showSnackBar(
        context,
        'Shortlist candidate id is missing.',
        isError: true,
      );
      return false;
    }

    try {
      final response = await http.delete(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.shortlistCandidate(candidateId)}',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _extractApiErrorMessage(response.body) ??
              'Shortlist delete API failed with ${response.statusCode}',
        );
      }

      if (!mounted) {
        return false;
      }

      setState(() {
        _shortlistedProfiles = _shortlistedProfiles
            .where(
              (item) =>
                  item.shortlistCandidateId != profile.shortlistCandidateId,
            )
            .toList();
      });

      return true;
    } catch (error) {
      if (context.mounted) {
        _showSnackBar(
          context,
          _cleanExceptionMessage(
            error,
            fallback: 'Unable to remove shortlisted profile.',
          ),
          isError: true,
        );
      }
      return false;
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.danger : AppColors.success,
        ),
      );
  }

  Widget _buildInfoGrid(RegistryProfileItem? profile) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 2.5,
      children: [
        _buildInfoItem(Icons.person, profile?.age ?? '27 Yrs', 'Age'),
        _buildInfoItem(Icons.height, profile?.height ?? '5\'6"', 'Height'),
        _buildInfoItem(
          Icons.location_on,
          profile?.city ?? 'Mumbai',
          'Resident',
        ),
        _buildInfoItem(
          Icons.work,
          profile?.profession ?? 'Actress',
          'Profession',
        ),
        _buildInfoItem(Icons.church, profile?.religion ?? 'Sikh', 'Religion'),
        _buildInfoItem(
          Icons.star,
          profile?.manglikLabel ?? 'Non-Manglik',
          'Manglik',
        ),
      ],
    );
  }

  Widget _buildHeaderImage(String image) {
    if (image.startsWith('http')) {
      return Image.network(
        image,
        height: 300.h,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackHeaderImage(),
      );
    }
    return Image.asset(
      image,
      height: 300.h,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallbackHeaderImage(),
    );
  }

  Widget _fallbackHeaderImage() {
    return Image.asset(
      'assets/wedding_hero 1.png',
      height: 300.h,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.sp, color: AppColors.rmPrimary),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12.sp,
            color: AppColors.rmMutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildShortInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: AppColors.rmMutedText),
        SizedBox(width: 4.w),
        Text(text, style: GoogleFonts.manrope(fontSize: 13.sp)),
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.lightGreyBg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(text, style: GoogleFonts.manrope(fontSize: 14.sp)),
    );
  }
}

class _ShortlistedProfile {
  const _ShortlistedProfile({
    required this.shortlistCandidateId,
    required this.profileId,
    required this.name,
    required this.shortCode,
    required this.statusLabel,
    required this.age,
    required this.height,
    required this.city,
    required this.work,
    required this.company,
    required this.manglik,
    required this.image,
  });

  final String shortlistCandidateId;
  final String profileId;
  final String name;
  final String shortCode;
  final String statusLabel;
  final String age;
  final String height;
  final String city;
  final String work;
  final String company;
  final String manglik;
  final String image;

  factory _ShortlistedProfile.fromJson(Map<String, dynamic> json) {
    final profile = _readProfileJson(json);
    final profileId = _firstText([
      profile['id'],
      json['shortlistedProfileId'],
      json['profileId'],
      json['candidateProfileId'],
    ]);
    final dateOfBirth = DateTime.tryParse(
      _firstText([profile['dateOfBirth'], json['dateOfBirth']]),
    );

    return _ShortlistedProfile(
      shortlistCandidateId: _firstText([
        json['id'],
        json['shortlistCandidateId'],
        json['candidateId'],
      ]),
      profileId: profileId,
      name: _firstText([
        profile['name'],
        json['name'],
        json['shortlistedProfileName'],
      ], fallback: 'Unnamed Profile'),
      shortCode: _firstText([
        profile['referenceId'],
        profile['profileCode'],
        json['referenceId'],
        json['profileCode'],
      ], fallback: _shortId(profileId)),
      statusLabel: _formatEnumLabel(
        _firstText([profile['status'], json['status']], fallback: 'ACTIVE'),
      ),
      age: _ageFromDate(dateOfBirth),
      height: _formatHeight(_firstValue([profile['height'], json['height']])),
      city: _firstText([
        profile['currentResidential'],
        profile['nativePlace'],
        profile['state'],
        profile['country'],
        json['city'],
      ], fallback: '-'),
      work: _firstText([
        profile['occupation'],
        json['occupation'],
        json['work'],
      ], fallback: '-'),
      company: _firstText([
        profile['company'],
        profile['education'],
        json['company'],
      ], fallback: '-'),
      manglik: _manglikLabel(
        _firstValue([profile['manglik'], json['manglik']]),
      ),
      image: _readImage(
        _firstValue([profile['image'], json['image']]),
        _firstValue([profile['photoUrls'], json['photoUrls']]),
      ),
    );
  }

  static Map<String, dynamic> _readProfileJson(Map<String, dynamic> json) {
    for (final key in const [
      'shortlistedProfile',
      'profile',
      'candidate',
      'candidateProfile',
      'shortlistedCandidate',
    ]) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
    }

    return json;
  }

  static dynamic _firstValue(List<dynamic> values) {
    for (final value in values) {
      if (value == null) {
        continue;
      }

      if (value is String && value.trim().isEmpty) {
        continue;
      }

      return value;
    }

    return null;
  }

  static String _firstText(List<dynamic> values, {String fallback = ''}) {
    final value = _firstValue(values);
    return _readText(value, fallback: fallback);
  }

  static String _readText(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String _readImage(dynamic image, dynamic photoUrls) {
    final imageText = _readText(image);
    if (imageText.isNotEmpty) {
      return imageText;
    }

    if (photoUrls is List) {
      for (final photoUrl in photoUrls) {
        final text = _readText(photoUrl);
        if (text.isNotEmpty) {
          return text;
        }
      }
    }

    return 'assets/wedding_hero 1.png';
  }

  static String _shortId(String id) {
    if (id.isEmpty) {
      return '-';
    }

    return id.length <= 8 ? id.toUpperCase() : id.substring(0, 8).toUpperCase();
  }

  static String _ageFromDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final today = DateTime.now();
    var age = today.year - value.year;

    if (today.month < value.month ||
        (today.month == value.month && today.day < value.day)) {
      age--;
    }

    return '$age';
  }

  static String _formatHeight(dynamic value) {
    if (value is num) {
      final totalInches = (value / 2.54).round();
      final feet = totalInches ~/ 12;
      final inches = totalInches % 12;
      return '$feet\'$inches"';
    }

    return _readText(value, fallback: '-');
  }

  static String _manglikLabel(dynamic value) {
    if (value is bool) {
      return value ? 'Manglik' : 'Non-Manglik';
    }

    final text = _readText(value);
    if (text.isEmpty) {
      return '-';
    }

    return text.toUpperCase() == 'TRUE' ? 'Manglik' : _formatEnumLabel(text);
  }

  static String _formatEnumLabel(String value) {
    if (value == '-') {
      return value;
    }

    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) {
          final lower = part.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }
}

class _ShortlistMessage extends StatelessWidget {
  const _ShortlistMessage({
    required this.message,
    this.actionLabel,
    this.onActionPressed,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: AppColors.rmBodyText,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (actionLabel != null && onActionPressed != null) ...[
            SizedBox(height: 12.h),
            OutlinedButton(
              onPressed: onActionPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rmPrimary,
                side: BorderSide(color: AppColors.rmPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                actionLabel!,
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShortlistProfileImage extends StatelessWidget {
  const _ShortlistProfileImage({
    required this.image,
    required this.width,
    required this.height,
  });

  final String image;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (image.startsWith('http')) {
      return Image.network(
        image,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }

    return Image.asset(
      image,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() {
    return Image.asset(
      'assets/wedding_hero 1.png',
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  }
}
