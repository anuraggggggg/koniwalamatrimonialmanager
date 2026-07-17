import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
  String _shortlistSearchQuery = '';
  final bool _sortNewestFirst = true;
  bool _shortlistGridView = false;

  String get _currentProfileId {
    final profileId = widget.profile?.originalId.trim() ?? '';
    return profileId == '-' ? '' : profileId;
  }

  bool get _hasCurrentProfile => _currentProfileId.isNotEmpty;

  bool get _isCurrentProfileGroom => widget.profile?.type == 'Groom';

  String get _candidateProfileType =>
      _isCurrentProfileGroom ? 'bride' : 'groom';

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
      length: 3,
      child: Builder(
        builder: (tabContext) {
          final tabController = DefaultTabController.of(tabContext);

          return Scaffold(
            backgroundColor: const Color(0xFFFFFBF8),
            body: SafeArea(
              bottom: false,
              child: AnimatedBuilder(
                animation: tabController,
                builder: (context, _) {
                  final tabIndex = tabController.index;

                  return Column(
                    children: [
                      _buildTopBar(context),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 26.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18.r),
                                child: _buildHeaderImage(headerImage),
                              ),
                              SizedBox(height: 6.h),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.fromLTRB(
                                  14.w,
                                  12.h,
                                  14.w,
                                  12.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(18.r),
                                  border: Border.all(
                                    color: const Color(0xFFEEDFD5),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x12B25C18),
                                      blurRadius: 18,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    _buildInfoGrid(profile),
                                    SizedBox(height: 4.h),
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 10.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF8F2),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      child: _buildInfoItem(
                                        Icons.account_balance_wallet_outlined,
                                        'Budget Not Specified',
                                        'Budget',
                                        fullWidth: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: widget.profile == null
                                          ? null
                                          : () =>
                                                Navigator.of(context).pushNamed(
                                                  AppRoutes.profileDetail,
                                                  arguments: widget.profile,
                                                ),
                                      icon: Icon(
                                        Icons.visibility_outlined,
                                        size: 18.sp,
                                      ),
                                      label: const Text('ViewProfile'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.rmPrimary,
                                        side: const BorderSide(
                                          color: AppColors.rmPaleRoseBorder,
                                        ),
                                        backgroundColor: AppColors.white,
                                        minimumSize: Size(
                                          double.infinity,
                                          48.h,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14.r,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showSnackBar(
                                        context,
                                        'Chat support will be available soon.',
                                      ),
                                      icon: Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 18.sp,
                                      ),
                                      label: const Text('Open chat'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.rmPrimary,
                                        side: const BorderSide(
                                          color: AppColors.rmPaleRoseBorder,
                                        ),
                                        backgroundColor: AppColors.white,
                                        minimumSize: Size(
                                          double.infinity,
                                          48.h,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14.r,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                              ElevatedButton.icon(
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
                                  context
                                      .read<RegistryProfilesProvider>()
                                      .fetchProfiles(
                                        accessToken,
                                        forceRefresh: true,
                                        oppositeGenderOf:
                                            _candidateOppositeGenderOf,
                                        profileType: _candidateProfileType,
                                      );
                                  _showAddProfilesSheet(displayName);
                                },
                                icon: Icon(Icons.person_add_alt_1, size: 18.sp),
                                label: Text(
                                  'Add $_candidateProfileLabel Profiles',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.rmPrimary,
                                  foregroundColor: AppColors.white,
                                  minimumSize: Size(double.infinity, 44.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  elevation: 0,
                                  textStyle: GoogleFonts.inter(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              SizedBox(height: 18.h),
                              TabBar(
                                isScrollable: true,
                                tabAlignment: TabAlignment.start,
                                labelColor: AppColors.rmPrimary,
                                unselectedLabelColor: AppColors.rmMutedText,
                                indicatorColor: AppColors.rmPrimary,
                                indicatorWeight: 2.2,
                                labelStyle: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.sp,
                                ),
                                unselectedLabelStyle: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.sp,
                                ),
                                tabs: const [
                                  Tab(text: 'All Shortlists'),
                                  Tab(text: 'Manual Shortlists'),
                                  Tab(text: 'AI Shortlists'),
                                ],
                              ),
                              SizedBox(height: 18.h),
                              Container(
                                height: 50.h,
                                padding: EdgeInsets.symmetric(horizontal: 14.w),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: const Color(0xFFE9DDD5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.search_rounded,
                                      color: AppColors.rmMutedText,
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: TextField(
                                        onChanged: (value) => setState(
                                          () => _shortlistSearchQuery = value,
                                        ),
                                        style: GoogleFonts.inter(
                                          color: AppColors.rmHeading,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        decoration: InputDecoration(
                                          hintText:
                                              'Search by name, ID, city, or keyword...',
                                          hintStyle: GoogleFonts.inter(
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
                              SizedBox(height: 14.h),
                              // Row(
                              //   children: [
                              //     OutlinedButton.icon(
                              //       onPressed: () => _showSnackBar(
                              //         context,
                              //         'Filters panel coming soon.',
                              //       ),
                              //       icon: Icon(Icons.tune, size: 16.sp),
                              //       label: const Text('FILTERS'),
                              //       style: OutlinedButton.styleFrom(
                              //         foregroundColor: AppColors.rmPrimary,
                              //         side: const BorderSide(
                              //           color:
                              //               AppColors.rmComparisonButtonBorder,
                              //         ),
                              //         minimumSize: Size(0, 38.h),
                              //         shape: RoundedRectangleBorder(
                              //           borderRadius: BorderRadius.circular(
                              //             999.r,
                              //           ),
                              //         ),
                              //       ),
                              //     ),
                              //     const Spacer(),
                              //     OutlinedButton.icon(
                              //       onPressed: () => setState(
                              //         () =>
                              //             _sortNewestFirst = !_sortNewestFirst,
                              //       ),
                              //       icon: Icon(
                              //         Icons.swap_vert_rounded,
                              //         size: 16.sp,
                              //       ),
                              //       label: Text(
                              //         _sortNewestFirst
                              //             ? 'NEWEST SHORTLISTED'
                              //             : 'OLDEST SHORTLISTED',
                              //       ),
                              //       style: OutlinedButton.styleFrom(
                              //         foregroundColor: AppColors.rmPrimary,
                              //         side: const BorderSide(
                              //           color:
                              //               AppColors.rmComparisonButtonBorder,
                              //         ),
                              //         minimumSize: Size(0, 38.h),
                              //         shape: RoundedRectangleBorder(
                              //           borderRadius: BorderRadius.circular(
                              //             999.r,
                              //           ),
                              //         ),
                              //       ),
                              //     ),
                              //   ],
                              // ),
                              SizedBox(height: 26.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${_visibleShortlistedProfiles(tabIndex).length} Profiles Shortlisted Total',
                                      style: GoogleFonts.inter(
                                        color: AppColors.rmPrimary,
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.all(4.r),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(12.r),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x10CD6124),
                                          blurRadius: 12,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        _buildLayoutToggle(
                                          icon: Icons.view_agenda_rounded,
                                          selected: !_shortlistGridView,
                                          onTap: () => setState(
                                            () => _shortlistGridView = false,
                                          ),
                                        ),
                                        SizedBox(width: 4.w),
                                        _buildLayoutToggle(
                                          icon: Icons.grid_view_rounded,
                                          selected: _shortlistGridView,
                                          onTap: () => setState(
                                            () => _shortlistGridView = true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 14.h),
                              _buildList(tabIndex: tabIndex),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroomProfilesSheetList(
    RegistryProfilesProvider profilesProvider,
    String searchQuery,
    _AddProfileFilterSelection filters,
  ) {
    if (profilesProvider.isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28.h),
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (profilesProvider.error != null) {
      return Center(
        child: _ShortlistMessage(
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
        ),
      );
    }

    final candidateProfiles = _filteredCandidateProfiles(
      profilesProvider.profiles,
      searchQuery,
      filters,
    );

    if (candidateProfiles.isEmpty) {
      return Center(
        child: _ShortlistMessage(
          message: searchQuery.trim().isEmpty && !filters.hasActiveFilters
              ? 'No ${_candidateProfileLabel.toLowerCase()} profiles found.'
              : 'No ${_candidateProfileLabel.toLowerCase()} profiles match your filters.',
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(top: 6.h, bottom: 10.h),
      itemCount: candidateProfiles.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        return _buildGroomProfileSheetCard(candidateProfiles[index]);
      },
    );
  }

  List<RegistryProfileItem> _candidateBaseProfiles(
    List<RegistryProfileItem> profiles,
  ) {
    return profiles
        .where(
          (profile) =>
              profile.type == _candidateProfileLabel &&
              profile.originalId != _currentProfileId,
        )
        .toList();
  }

  List<RegistryProfileItem> _filteredCandidateProfiles(
    List<RegistryProfileItem> profiles,
    String searchQuery,
    _AddProfileFilterSelection filters,
  ) {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final candidateProfiles = _candidateBaseProfiles(profiles).where((profile) {
      if (normalizedQuery.isNotEmpty) {
        final searchIndex = [
          profile.name,
          profile.id,
          profile.city,
          profile.work,
          profile.profession,
          profile.community,
          profile.religion,
          profile.manglikLabel,
        ].join(' ').toLowerCase();

        if (!searchIndex.contains(normalizedQuery)) {
          return false;
        }
      }

      if (!_matchesAddProfileAge(profile, filters.ageFilter)) {
        return false;
      }

      if (filters.city != null && _filterText(profile.city) != filters.city) {
        return false;
      }

      if (filters.occupation != null &&
          _filterText(profile.work) != filters.occupation) {
        return false;
      }

      if (filters.community != null &&
          _filterText(profile.community) != filters.community) {
        return false;
      }

      if (filters.manglik != null &&
          _filterText(profile.manglikLabel) != filters.manglik) {
        return false;
      }

      switch (filters.tierFilter) {
        case _AddProfileTierFilter.all:
          return true;
        case _AddProfileTierFilter.premium:
          return profile.isPremium;
        case _AddProfileTierFilter.standard:
          return !profile.isPremium;
      }
    }).toList();

    candidateProfiles.sort(
      (first, second) =>
          first.name.toLowerCase().compareTo(second.name.toLowerCase()),
    );
    return candidateProfiles;
  }

  bool _matchesAddProfileAge(
    RegistryProfileItem profile,
    _AddProfileAgeFilter filter,
  ) {
    final age = int.tryParse(profile.age);
    switch (filter) {
      case _AddProfileAgeFilter.all:
        return true;
      case _AddProfileAgeFilter.below25:
        return age != null && age < 25;
      case _AddProfileAgeFilter.twentyFiveToThirty:
        return age != null && age >= 25 && age <= 30;
      case _AddProfileAgeFilter.thirtyOneToThirtyFive:
        return age != null && age >= 31 && age <= 35;
      case _AddProfileAgeFilter.above35:
        return age != null && age > 35;
    }
  }

  List<String> _profileFilterOptions(
    List<RegistryProfileItem> profiles,
    String Function(RegistryProfileItem profile) valueForProfile,
  ) {
    final values = profiles
        .map(valueForProfile)
        .map(_filterText)
        .where((value) => value != null)
        .cast<String>()
        .toSet()
        .toList();
    values.sort(
      (first, second) => first.toLowerCase().compareTo(second.toLowerCase()),
    );
    return values;
  }

  String? _filterText(String value) {
    final text = value.trim();
    if (text.isEmpty || text == '-') {
      return null;
    }
    return text;
  }

  Future<_AddProfileFilterSelection?> _showAddProfileFiltersSheet(
    BuildContext context, {
    required List<RegistryProfileItem> profiles,
    required _AddProfileFilterSelection initialSelection,
  }) {
    return showModalBottomSheet<_AddProfileFilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) {
        return _AddProfileFiltersSheet(
          cityOptions: _profileFilterOptions(
            profiles,
            (profile) => profile.city,
          ),
          occupationOptions: _profileFilterOptions(
            profiles,
            (profile) => profile.work,
          ),
          communityOptions: _profileFilterOptions(
            profiles,
            (profile) => profile.community,
          ),
          manglikOptions: _profileFilterOptions(
            profiles,
            (profile) => profile.manglikLabel,
          ),
          initialSelection: initialSelection,
        );
      },
    );
  }

  void _showAddProfilesSheet(String displayName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) {
        var searchQuery = '';
        var filters = const _AddProfileFilterSelection();

        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Material(
              color: AppColors.transparent,
              child: SafeArea(
                top: false,
                child: FractionallySizedBox(
                  heightFactor: 0.9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28.r),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 10.h),
                            child: Container(
                              width: 46.w,
                              height: 5.h,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE7DAD0),
                                borderRadius: BorderRadius.circular(999.r),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(18.w, 16.h, 12.w, 8.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Add $_candidateProfileLabel Profiles',
                                      style: GoogleFonts.inter(
                                        color: AppColors.rmHeading,
                                        fontSize: 22.sp,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      'Select a profile to add directly into $displayName\'s shortlist.',
                                      style: GoogleFonts.inter(
                                        color: AppColors.rmBodyText,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w500,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    Navigator.of(modalContext).pop(),
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: AppColors.rmMutedText,
                                  size: 20.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(18.w, 6.h, 18.w, 8.h),
                          child: Container(
                            height: 46.h,
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBF8),
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: const Color(0xFFE7DAD0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  color: AppColors.rmMutedText,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: TextField(
                                    onChanged: (value) => setModalState(
                                      () => searchQuery = value,
                                    ),
                                    style: GoogleFonts.inter(
                                      color: AppColors.rmHeading,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search ${_candidateProfileLabel.toLowerCase()} profiles...',
                                      hintStyle: GoogleFonts.inter(
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
                        ),
                        Consumer<RegistryProfilesProvider>(
                          builder: (context, profilesProvider, _) {
                            final baseProfiles = _candidateBaseProfiles(
                              profilesProvider.profiles,
                            );
                            final filteredCount = _filteredCandidateProfiles(
                              profilesProvider.profiles,
                              searchQuery,
                              filters,
                            ).length;

                            return Padding(
                              padding: EdgeInsets.fromLTRB(
                                18.w,
                                2.h,
                                18.w,
                                12.h,
                              ),
                              child: _AddProfileFilterBar(
                                activeCount: filters.activeCount,
                                resultCount: filteredCount,
                                onFilterPressed: () async {
                                  final result =
                                      await _showAddProfileFiltersSheet(
                                        modalContext,
                                        profiles: baseProfiles,
                                        initialSelection: filters,
                                      );

                                  if (result == null) {
                                    return;
                                  }

                                  setModalState(() => filters = result);
                                },
                                onClearPressed: filters.hasActiveFilters
                                    ? () => setModalState(
                                        () => filters =
                                            const _AddProfileFilterSelection(),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 14.h),
                            child: Consumer<RegistryProfilesProvider>(
                              builder: (context, profilesProvider, _) {
                                return _buildGroomProfilesSheetList(
                                  profilesProvider,
                                  searchQuery,
                                  filters,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGroomProfileSheetCard(RegistryProfileItem profile) {
    final isAdding = _addingShortlistProfileIds.contains(profile.originalId);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFE7DAD0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
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
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.rmHeading,
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
                              Icon(
                                Icons.visibility_outlined,
                                color: AppColors.rmPrimary,
                                size: 16.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'View',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: AppColors.rmPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'ID: #${profile.id}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: AppColors.rmMutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${profile.age} Yrs • ${profile.height} • ${profile.city}',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: AppColors.rmBodyText,
                        fontWeight: FontWeight.w600,
                      ),
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
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    minimumSize: Size(0, 40.h),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        color: AppColors.rmPrimary,
                        size: 16.sp,
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          'View',
                          style: GoogleFonts.inter(
                            color: AppColors.rmPrimary,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
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
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    minimumSize: Size(0, 40.h),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: AppColors.white,
                        size: 16.sp,
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          isAdding ? 'Adding...' : 'Add to Shortlist',
                          style: GoogleFonts.inter(
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
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.profileDetail, arguments: profile);
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
            style: GoogleFonts.inter(fontWeight: FontWeight.w800),
          ),
          content: Text(
            '${profile.name} added to shortlist.',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close bottom sheet
              },
              child: Text(
                'OK',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
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

  bool _shouldRetryShortlistAddWithCandidateProfileId(http.Response response) {
    if (response.statusCode != 400 &&
        response.statusCode != 422 &&
        response.statusCode != 500) {
      return false;
    }

    final message = (_extractApiErrorMessage(response.body) ?? '')
        .toLowerCase();
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

  List<_ShortlistedProfile> _visibleShortlistedProfiles(int tabIndex) {
    if (tabIndex == 2) {
      return const [];
    }

    final query = _shortlistSearchQuery.trim().toLowerCase();
    final filtered = _shortlistedProfiles.where((profile) {
      if (query.isEmpty) {
        return true;
      }

      return profile.name.toLowerCase().contains(query) ||
          profile.shortCode.toLowerCase().contains(query) ||
          profile.city.toLowerCase().contains(query) ||
          profile.work.toLowerCase().contains(query) ||
          profile.company.toLowerCase().contains(query) ||
          profile.religion.toLowerCase().contains(query) ||
          profile.manglik.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      final left = a.shortlistedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.shortlistedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return _sortNewestFirst ? right.compareTo(left) : left.compareTo(right);
    });

    return filtered;
  }

  Widget _buildList({required int tabIndex}) {
    if (_isLoadingShortlist) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_shortlistError != null) {
      return Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: _ShortlistMessage(
          message: _shortlistError!,
          actionLabel: 'Retry',
          onActionPressed: _retryShortlist,
        ),
      );
    }

    if (tabIndex == 2) {
      return Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: const _ShortlistMessage(
          message: 'No AI shortlists available yet.',
        ),
      );
    }

    final profiles = _visibleShortlistedProfiles(tabIndex);
    if (profiles.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: const _ShortlistMessage(
          message: 'No shortlisted profiles match your current filters.',
        ),
      );
    }

    if (_shortlistGridView) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 16.h),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 0.66,
        ),
        itemCount: profiles.length,
        itemBuilder: (context, index) =>
            _buildCompactProfileCard(context, profiles[index]),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: 16.h),
      itemCount: profiles.length,
      separatorBuilder: (context, index) => SizedBox(height: 14.h),
      itemBuilder: (context, index) =>
          _buildProfileCard(context, profiles[index]),
    );
  }

  Widget _buildProfileCard(BuildContext context, _ShortlistedProfile profile) {
    final isSending = _sendingShortlistCandidateIds.contains(
      profile.shortlistCandidateId,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFEEDFD5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12B25C18),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14.r),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 112.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      _ShortlistProfileImage(
                        image: profile.image,
                        width: 112.w,
                        height: 142.h,
                      ),
                      Positioned(
                        left: 10.w,
                        bottom: 10.h,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.rmPrimary,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            '${profile.matchScore}% Match',
                            style: GoogleFonts.inter(
                              color: AppColors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: GoogleFonts.inter(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.rmPrimary,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '#${profile.shortCode}',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: const Color(0xFF4B4747),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9F8ED),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              profile.statusLabel.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: const Color(0xFF149647),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Wrap(
                        spacing: 7.w,
                        runSpacing: 4.h,
                        children: [
                          Text(
                            '${profile.age} Yrs',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: const Color(0xFF3A3434),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '•',
                            style: GoogleFonts.inter(
                              color: AppColors.rmMutedText,
                              fontSize: 13.sp,
                            ),
                          ),
                          Text(
                            profile.city,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: const Color(0xFF3A3434),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '•',
                            style: GoogleFonts.inter(
                              color: AppColors.rmMutedText,
                              fontSize: 13.sp,
                            ),
                          ),
                          Text(
                            profile.height,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: const Color(0xFF3A3434),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      _buildProfileDetailLine(
                        Icons.work_outline_rounded,
                        profile.work,
                      ),
                      SizedBox(height: 6.h),
                      _buildProfileDetailLine(
                        Icons.school_outlined,
                        profile.company,
                      ),
                      SizedBox(height: 6.h),
                      _buildProfileDetailLine(
                        Icons.people_outline_rounded,
                        profile.religion,
                      ),
                      SizedBox(height: 6.h),
                      _buildProfileDetailLine(
                        Icons.star_border_rounded,
                        profile.manglik,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => _openCompareProfile(profile),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rmPrimary,
                minimumSize: Size(double.infinity, 46.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.compare_arrows_rounded, size: 17.sp),
                  SizedBox(width: 6.w),
                  Text(
                    'Compare Profile',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isSending
                        ? null
                        : () => _sendShortlistedProfile(profile),
                    icon: Icon(
                      Icons.forum_outlined,
                      size: 17.sp,
                      color: AppColors.rmPrimary,
                    ),
                    label: Text(
                      isSending ? 'Sending...' : 'Send Profile',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.rmPrimary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(0, 44.h),
                      side: const BorderSide(color: Color(0xFFFFA27A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showRemoveFromShortlistSheet(context, profile),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 17.sp,
                      color: AppColors.danger,
                    ),
                    label: Text(
                      'Remove',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(0, 44.h),
                      side: const BorderSide(color: Color(0xFFFFB4B4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                'Shortlisted on ${_formatShortlistedOn(profile.shortlistedAt)} by ${profile.shortlistedBy}',
                style: GoogleFonts.inter(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF463F3F),
                  fontStyle: FontStyle.italic,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactProfileCard(
    BuildContext context,
    _ShortlistedProfile profile,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEEDFD5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            child: _ShortlistProfileImage(
              image: profile.image,
              width: double.infinity,
              height: 126.h,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.rmPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '#${profile.shortCode}',
                  style: GoogleFonts.inter(
                    color: AppColors.rmMutedText,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                ElevatedButton(
                  onPressed: () => _openCompareProfile(profile),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rmPrimary,
                    minimumSize: Size(double.infinity, 34.h),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    'Compare',
                    style: GoogleFonts.inter(
                      color: AppColors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                                style: GoogleFonts.inter(
                                  color: titleColor,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Are you sure you want to remove this\nprofile from the shortlist?',
                                style: GoogleFonts.inter(
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
                                  style: GoogleFonts.inter(
                                    color: titleColor,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  '#${profile.shortCode}',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
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
                              style: GoogleFonts.inter(
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
                              style: GoogleFonts.inter(
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
                              style: GoogleFonts.inter(
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
                                    style: GoogleFonts.inter(
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

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 10.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: const Color(0xFF232323),
              size: 22.sp,
            ),
          ),
          Expanded(
            child: Text(
              'shortlist',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF2C2626),
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: () =>
                _showSnackBar(context, 'More options coming soon.'),
            icon: Icon(
              Icons.more_vert_rounded,
              color: const Color(0xFF232323),
              size: 22.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(RegistryProfileItem? profile) {
    final items = [
      _buildInfoItem(
        Icons.person_outline_rounded,
        profile?.age ?? '27 Yrs',
        'Age',
      ),
      _buildInfoItem(
        Icons.height_rounded,
        profile?.height ?? '5\'6"',
        'Height',
      ),
      _buildInfoItem(
        Icons.location_on_outlined,
        profile?.city ?? 'Mumbai',
        'Resident',
      ),
      _buildInfoItem(
        Icons.work_outline_rounded,
        profile?.profession ?? 'Actress',
        'Profession',
      ),
      _buildInfoItem(
        Icons.church_outlined,
        profile?.religion ?? 'Sikh',
        'Religion',
      ),
      _buildInfoItem(
        Icons.star_border_rounded,
        profile?.manglikLabel ?? 'Non-Manglik',
        'Manglik',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) => items[index],
    );
  }

  Widget _buildHeaderImage(String image) {
    if (image.startsWith('http')) {
      return Image.network(
        image,
        height: 142.h,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackHeaderImage(),
      );
    }
    return Image.asset(
      image,
      height: 142.h,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallbackHeaderImage(),
    );
  }

  Widget _fallbackHeaderImage() {
    return Image.asset(
      'assets/wedding_hero 1.png',
      height: 142.h,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String value,
    String label, {
    bool fullWidth = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16.sp, color: AppColors.rmPrimary),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                value,
                maxLines: fullWidth ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: fullWidth ? 14.sp : 15.sp,
                  color: const Color(0xFF2F2B2B),
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: AppColors.rmMutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetailLine(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15.sp, color: AppColors.rmMutedText),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12.8.sp,
              color: const Color(0xFF2F2B2B),
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLayoutToggle({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: onTap,
      child: Container(
        width: 34.w,
        height: 32.h,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF1E7) : AppColors.white,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(
          icon,
          size: 18.sp,
          color: selected ? AppColors.rmPrimary : AppColors.rmMutedText,
        ),
      ),
    );
  }

  String _formatShortlistedOn(DateTime? value) {
    if (value == null) {
      return 'recently';
    }

    return DateFormat('d MMM yyyy, hh:mm a').format(value).toLowerCase();
  }
}

enum _AddProfileAgeFilter {
  all('All ages'),
  below25('Below 25'),
  twentyFiveToThirty('25 - 30'),
  thirtyOneToThirtyFive('31 - 35'),
  above35('36+');

  const _AddProfileAgeFilter(this.label);

  final String label;
}

enum _AddProfileTierFilter {
  all('All profiles'),
  premium('Premium'),
  standard('Standard');

  const _AddProfileTierFilter(this.label);

  final String label;
}

class _AddProfileFilterSelection {
  const _AddProfileFilterSelection({
    this.ageFilter = _AddProfileAgeFilter.all,
    this.city,
    this.occupation,
    this.community,
    this.manglik,
    this.tierFilter = _AddProfileTierFilter.all,
  });

  final _AddProfileAgeFilter ageFilter;
  final String? city;
  final String? occupation;
  final String? community;
  final String? manglik;
  final _AddProfileTierFilter tierFilter;

  bool get hasActiveFilters => activeCount > 0;

  int get activeCount {
    var count = 0;
    if (ageFilter != _AddProfileAgeFilter.all) count++;
    if (city != null) count++;
    if (occupation != null) count++;
    if (community != null) count++;
    if (manglik != null) count++;
    if (tierFilter != _AddProfileTierFilter.all) count++;
    return count;
  }
}

class _AddProfileFilterBar extends StatelessWidget {
  const _AddProfileFilterBar({
    required this.activeCount,
    required this.resultCount,
    required this.onFilterPressed,
    required this.onClearPressed,
  });

  final int activeCount;
  final int resultCount;
  final VoidCallback onFilterPressed;
  final VoidCallback? onClearPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: onFilterPressed,
          icon: Icon(Icons.tune_rounded, size: 16.sp),
          label: Text(activeCount == 0 ? 'Filters' : 'Filters ($activeCount)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.rmPrimary,
            side: const BorderSide(color: AppColors.rmPaleRoseBorder),
            backgroundColor: AppColors.white,
            minimumSize: Size(0, 36.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999.r),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (onClearPressed != null) ...[
          SizedBox(width: 8.w),
          TextButton(
            onPressed: onClearPressed,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.rmMutedText,
              minimumSize: Size(0, 34.h),
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Clear',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
        const Spacer(),
        Flexible(
          child: Text(
            '$resultCount matches',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              color: AppColors.rmMutedText,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _AddProfileFiltersSheet extends StatefulWidget {
  const _AddProfileFiltersSheet({
    required this.cityOptions,
    required this.occupationOptions,
    required this.communityOptions,
    required this.manglikOptions,
    required this.initialSelection,
  });

  final List<String> cityOptions;
  final List<String> occupationOptions;
  final List<String> communityOptions;
  final List<String> manglikOptions;
  final _AddProfileFilterSelection initialSelection;

  @override
  State<_AddProfileFiltersSheet> createState() =>
      _AddProfileFiltersSheetState();
}

class _AddProfileFiltersSheetState extends State<_AddProfileFiltersSheet> {
  late _AddProfileAgeFilter _ageFilter;
  String? _city;
  String? _occupation;
  String? _community;
  String? _manglik;
  late _AddProfileTierFilter _tierFilter;

  @override
  void initState() {
    super.initState();
    final selection = widget.initialSelection;
    _ageFilter = selection.ageFilter;
    _city = selection.city;
    _occupation = selection.occupation;
    _community = selection.community;
    _manglik = selection.manglik;
    _tierFilter = selection.tierFilter;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: 0.82.sh),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 10.h),
              child: Container(
                width: 46.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7DAD0),
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 16.h, 12.w, 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter Profiles',
                      style: GoogleFonts.inter(
                        color: AppColors.rmHeading,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.rmMutedText,
                      size: 20.sp,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(18.w, 2.h, 18.w, 18.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _AddProfileFilterSectionTitle(
                      icon: Icons.cake_outlined,
                      label: 'Age',
                    ),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: _AddProfileAgeFilter.values.map((filter) {
                        return _AddProfileFilterChip(
                          label: filter.label,
                          selected: _ageFilter == filter,
                          onTap: () => setState(() => _ageFilter = filter),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 18.h),
                    const _AddProfileFilterSectionTitle(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Profile Tier',
                    ),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: _AddProfileTierFilter.values.map((filter) {
                        return _AddProfileFilterChip(
                          label: filter.label,
                          selected: _tierFilter == filter,
                          onTap: () => setState(() => _tierFilter = filter),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 18.h),
                    const _AddProfileFilterSectionTitle(
                      icon: Icons.location_on_outlined,
                      label: 'City',
                    ),
                    _AddProfileFilterDropdown(
                      value: _city,
                      hintText: 'All cities',
                      options: widget.cityOptions,
                      onChanged: (value) => setState(() => _city = value),
                    ),
                    SizedBox(height: 14.h),
                    const _AddProfileFilterSectionTitle(
                      icon: Icons.work_outline_rounded,
                      label: 'Occupation',
                    ),
                    _AddProfileFilterDropdown(
                      value: _occupation,
                      hintText: 'All occupations',
                      options: widget.occupationOptions,
                      onChanged: (value) => setState(() => _occupation = value),
                    ),
                    SizedBox(height: 14.h),
                    const _AddProfileFilterSectionTitle(
                      icon: Icons.groups_2_outlined,
                      label: 'Community',
                    ),
                    _AddProfileFilterDropdown(
                      value: _community,
                      hintText: 'All communities',
                      options: widget.communityOptions,
                      onChanged: (value) => setState(() => _community = value),
                    ),
                    SizedBox(height: 14.h),
                    const _AddProfileFilterSectionTitle(
                      icon: Icons.auto_awesome_outlined,
                      label: 'Manglik',
                    ),
                    _AddProfileFilterDropdown(
                      value: _manglik,
                      hintText: 'Any manglik status',
                      options: widget.manglikOptions,
                      onChanged: (value) => setState(() => _manglik = value),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 16.h),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFBF8),
                border: Border(top: BorderSide(color: Color(0xFFEFE2D9))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearFilters,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.rmPrimary,
                        side: const BorderSide(
                          color: AppColors.rmPaleRoseBorder,
                        ),
                        minimumSize: Size(double.infinity, 44.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        'Clear',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.rmPrimary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        minimumSize: Size(double.infinity, 44.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        'Apply',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900),
                      ),
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

  void _clearFilters() {
    Navigator.of(context).pop(const _AddProfileFilterSelection());
  }

  void _applyFilters() {
    Navigator.of(context).pop(
      _AddProfileFilterSelection(
        ageFilter: _ageFilter,
        city: _city,
        occupation: _occupation,
        community: _community,
        manglik: _manglik,
        tierFilter: _tierFilter,
      ),
    );
  }
}

class _AddProfileFilterSectionTitle extends StatelessWidget {
  const _AddProfileFilterSectionTitle({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 9.h),
      child: Row(
        children: [
          Icon(icon, color: AppColors.rmPrimary, size: 17.sp),
          SizedBox(width: 7.w),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.rmHeading,
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddProfileFilterChip extends StatelessWidget {
  const _AddProfileFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.rmPrimary : AppColors.white,
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(
            color: selected ? AppColors.rmPrimary : AppColors.rmPaleRoseBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? AppColors.white : AppColors.rmBodyText,
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _AddProfileFilterDropdown extends StatelessWidget {
  const _AddProfileFilterDropdown({
    required this.value,
    required this.hintText,
    required this.options,
    required this.onChanged,
  });

  final String? value;
  final String hintText;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final currentValue = options.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      isExpanded: true,
      dropdownColor: AppColors.white,
      borderRadius: BorderRadius.circular(14.r),
      style: GoogleFonts.inter(
        color: AppColors.rmHeading,
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
      ),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.rmMutedText,
        size: 22.sp,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFFFFBF8),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: Color(0xFFE7DAD0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: AppColors.rmPrimary),
        ),
      ),
      hint: Text(
        hintText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: AppColors.rmMutedText,
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
      items: [
        DropdownMenuItem<String>(
          value: '',
          child: Text(hintText, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        ...options.map(
          (option) => DropdownMenuItem<String>(
            value: option,
            child: Text(option, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (value) =>
          onChanged(value == null || value.isEmpty ? null : value),
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
    required this.religion,
    required this.manglik,
    required this.image,
    required this.matchScore,
    required this.shortlistedAt,
    required this.shortlistedBy,
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
  final String religion;
  final String manglik;
  final String image;
  final int matchScore;
  final DateTime? shortlistedAt;
  final String shortlistedBy;

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
      religion: _firstText([
        profile['religion'],
        json['religion'],
      ], fallback: 'OTHER'),
      manglik: _manglikLabel(
        _firstValue([profile['manglik'], json['manglik']]),
      ),
      image: _readImage(
        _firstValue([profile['image'], json['image']]),
        _firstValue([profile['photoUrls'], json['photoUrls']]),
      ),
      matchScore: _readMatchScore(
        _firstValue([json['matchScore'], json['score'], profile['matchScore']]),
      ),
      shortlistedAt: _readDate(
        _firstValue([
          json['createdAt'],
          json['shortlistedAt'],
          json['updatedAt'],
        ]),
      ),
      shortlistedBy: _firstText([
        _readNestedText(json['createdBy'], 'name'),
        _readNestedText(json['assignedTo'], 'name'),
        json['assignedToName'],
        json['createdByName'],
      ], fallback: 'RM team'),
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

  static String _readNestedText(dynamic value, String key) {
    if (value is Map<String, dynamic>) {
      return _readText(value[key]);
    }
    return '';
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

  static int _readMatchScore(dynamic value) {
    if (value is num) {
      return value.round().clamp(0, 100);
    }

    final numeric = int.tryParse(
      _readText(value).replaceAll(RegExp(r'[^0-9]'), ''),
    );
    return (numeric ?? 96).clamp(0, 100);
  }

  static DateTime? _readDate(dynamic value) {
    final text = _readText(value);
    if (text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text)?.toLocal();
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
            style: GoogleFonts.inter(
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
                style: GoogleFonts.inter(fontWeight: FontWeight.w800),
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
