import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/owner/models/registry_profile_item.dart';
import 'package:koniwalamatrimonial/owner/providers/registry_profiles_provider.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:koniwalamatrimonial/widgets/filter_bottom_sheet.dart';
import 'package:provider/provider.dart';

class RegistryScreen extends StatelessWidget {
  const RegistryScreen({
    super.key,
    required this.onMenuPressed,
    this.showScaffold = true,
    this.showEmbeddedAppBar = true,
  });

  final VoidCallback onMenuPressed;
  final bool showScaffold;
  final bool showEmbeddedAppBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final widgetBody = const RegistryBody();
    final fab = FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.transparent,
          builder: (context) => const FilterBottomSheet(),
        );
      },
      backgroundColor: AppColors.primary,
      shape: const CircleBorder(),
      child: const Icon(Icons.filter_list, color: AppColors.white),
    );

    return Theme(
      data: theme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(theme.textTheme),
        primaryTextTheme: GoogleFonts.poppinsTextTheme(theme.primaryTextTheme),
      ),
      child: DefaultTabController(
        length: 3,
        child: !showScaffold
            ? Stack(
                children: [
                  Column(
                    children: [
                      if (showEmbeddedAppBar)
                        SizedBox(
                          height:
                              kToolbarHeight +
                              MediaQuery.of(context).padding.top,
                          child: RegistryAppBar(onMenuPressed: onMenuPressed),
                        ),
                      Expanded(child: widgetBody),
                    ],
                  ),
                  Positioned(right: 16.w, bottom: 16.h, child: fab),
                ],
              )
            : Scaffold(
                backgroundColor: AppColors.white,
                appBar: RegistryAppBar(onMenuPressed: onMenuPressed),
                body: widgetBody,
                floatingActionButton: fab,
              ),
      ),
    );
  }
}

class _RegistryProfilesContent extends StatelessWidget {
  const _RegistryProfilesContent({
    required this.isLoading,
    required this.error,
    required this.profiles,
    required this.onRetry,
    required this.buildProfileCard,
  });

  final bool isLoading;
  final String? error;
  final List<RegistryProfileItem> profiles;
  final VoidCallback onRetry;
  final Widget Function(RegistryProfileItem profile) buildProfileCard;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 28.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return _RegistryProfilesMessage(
        message: error!,
        actionLabel: 'Retry',
        onActionPressed: onRetry,
      );
    }

    if (profiles.isEmpty) {
      return const _RegistryProfilesMessage(message: 'No profiles found.');
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: profiles.length,
      separatorBuilder: (context, index) => SizedBox(height: 16.h),
      itemBuilder: (context, index) => buildProfileCard(profiles[index]),
    );
  }
}

class _RegistryProfilesMessage extends StatelessWidget {
  const _RegistryProfilesMessage({
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
        border: Border.all(color: AppColors.black),
        boxShadow: const [
          BoxShadow(
            color: AppColors.rmCardShadow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileCardImage extends StatelessWidget {
  const _ProfileCardImage({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    final visibleImages = images.isEmpty
        ? const ['assets/wedding_hero 1.png']
        : images;

    return Material(
      color: AppColors.transparent,
      child: Stack(
        children: [
          SizedBox(
            height: 160.h,
            child: PageView.builder(
              itemCount: visibleImages.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () => _showFullImage(context, index, visibleImages),
                  child: _ProfileImageView(
                    image: visibleImages[index],
                    height: 160.h,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                );
              },
            ),
          ),
          if (visibleImages.length > 1)
            Positioned(
              left: 10.w,
              bottom: 10.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Text(
                  '${visibleImages.length} Photos',
                  style: GoogleFonts.poppins(
                    color: AppColors.rmBodyText,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          Positioned(
            right: 10.w,
            bottom: 10.h,
            child: Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: Icon(
                Icons.open_in_full_rounded,
                color: AppColors.white,
                size: 16.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(
    BuildContext context,
    int initialIndex,
    List<String> visibleImages,
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
                    itemCount: visibleImages.length,
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: _ProfileImageView(
                          image: visibleImages[index],
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

class RegistryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const RegistryAppBar({super.key, required this.onMenuPressed});

  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.menu, color: AppColors.primary),
        onPressed: onMenuPressed,
      ),
      title: Text(
        'Profile',
        style: GoogleFonts.manrope(
          color: AppColors.black,
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        // Padding(
        //   padding: EdgeInsets.only(right: 16.w),
        //   child: CircleAvatar(
        //     radius: 15.r,
        //     backgroundImage: const AssetImage('assets/wedding_hero 1.png'),
        //   ),
        // ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class RegistryBody extends StatefulWidget {
  const RegistryBody({super.key});

  @override
  State<RegistryBody> createState() => _RegistryBodyState();
}

class _RegistryBodyState extends State<RegistryBody> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedTab = 0;
  bool _hasRequestedProfiles = false;
  String? _requestedAccessToken;

  List<RegistryProfileItem> _filteredProfiles(
    List<RegistryProfileItem> profiles,
  ) {
    var visibleProfiles = profiles;

    if (_selectedTab == 1) {
      visibleProfiles = profiles
          .where((profile) => profile.type == 'Bride')
          .toList();
    } else if (_selectedTab == 2) {
      visibleProfiles = profiles
          .where((profile) => profile.type == 'Groom')
          .toList();
    }

    if (_searchQuery.isEmpty) return visibleProfiles;
    return visibleProfiles.where((profile) {
      final query = _searchQuery.toLowerCase();
      return profile.name.toLowerCase().contains(query) ||
          profile.id.toLowerCase().contains(query) ||
          profile.city.toLowerCase().contains(query) ||
          profile.work.toLowerCase().contains(query) ||
          profile.profession.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authProvider = Provider.of<AuthProvider>(context);
    final accessToken = authProvider.userModel?.accessToken;

    if (!authProvider.isInitialized ||
        (_hasRequestedProfiles && accessToken == _requestedAccessToken)) {
      return;
    }

    _hasRequestedProfiles = true;
    _requestedAccessToken = accessToken;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<RegistryProfilesProvider>().fetchProfiles(accessToken);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profilesProvider = context.watch<RegistryProfilesProvider>();
    final allProfiles = profilesProvider.profiles;
    final filtered = _filteredProfiles(allProfiles);
    final listTitle = switch (_selectedTab) {
      1 => 'Brides',
      2 => 'Grooms',
      _ => 'All Profiles',
    };

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Profiles',
            style: GoogleFonts.poppins(
              color: AppColors.titleColor,
              fontSize: 27.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Manage and organize all your client profiles in one place.',
            style: GoogleFonts.poppins(
              color: AppColors.rmBodyText,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12.h),
          // Tab Bar
          TabBar(
            onTap: (index) => setState(() => _selectedTab = index),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.inactiveNavItemColor,
            indicatorColor: AppColors.accent,
            indicatorSize: TabBarIndicatorSize.label,
            labelPadding: EdgeInsets.only(right: 24.w),
            dividerColor: AppColors.transparent,
            labelStyle: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'All Profiles'),
              Tab(text: 'Brides'),
              Tab(text: 'Grooms'),
            ],
          ),
          SizedBox(height: 12.h),
          // Search Bar
          Container(
            height: 48.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.inactiveNavItemColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.rmBodyText),
                SizedBox(width: 12.w),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.poppins(fontSize: 14.sp),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by name, ID, city, or work...',
                      hintStyle: GoogleFonts.poppins(
                        color: AppColors.rmBodyText,
                        fontSize: 14.sp,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          // List Header
          Row(
            children: [
              Expanded(
                child: Text(
                  listTitle,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: AppColors.rmPrimary,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // IconButton(
                    //   icon: Icon(Icons.bookmark, color: AppColors.rmPrimary),
                    //   onPressed: () {
                    //     ScaffoldMessenger.of(context).showSnackBar(
                    //       const SnackBar(
                    //         content: Text(
                    //           'Select a profile card to open its shortlist.',
                    //         ),
                    //       ),
                    //     );
                    //   },
                    // ),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        'Showing ${filtered.length} of ${allProfiles.length} profiles',
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.poppins(
                          color: AppColors.rmBodyText,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2EB),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.grid_view,
                            size: 16.sp,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4.w),
                          Icon(Icons.list, size: 16.sp, color: AppColors.black),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 32.h),
          // Profile List
          _RegistryProfilesContent(
            isLoading: profilesProvider.isLoading,
            error: profilesProvider.error,
            profiles: filtered,
            onRetry: () => context.read<RegistryProfilesProvider>().retry(),
            buildProfileCard: _buildProfileCard,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(RegistryProfileItem profile) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.rmCardShadow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                child: _ProfileCardImage(images: profile.photoUrls),
              ),
              if (profile.isPremium)
                Positioned(
                  top: 10.h,
                  left: 10.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: AppColors.white, size: 12.sp),
                        SizedBox(width: 4.w),
                        Text(
                          'PREMIUM',
                          style: GoogleFonts.poppins(
                            color: AppColors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        profile.name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '#${profile.id}',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: AppColors.rmBodyText,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  '${profile.age} yrs - ${profile.height} - ${profile.city}',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  profile.profession.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  profile.work.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.poppins(
                    color: AppColors.rmBodyText,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '${profile.community} - ${profile.manglikLabel}',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.profileDetail,
                            arguments: profile,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.visibility_outlined, size: 16.sp),
                            SizedBox(width: 8.w),
                            Flexible(
                              child: Text(
                                'View',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: AppColors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.shortlist,
                            arguments: profile,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bookmark_outline, size: 16.sp),
                            SizedBox(width: 8.w),
                            Flexible(
                              child: Text(
                                'Shortlist',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: AppColors.primary,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                ),
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
        ],
      ),
    );
  }
}
