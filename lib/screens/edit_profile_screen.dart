import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/owner/models/registry_profile_item.dart';
import 'package:koniwalamatrimonial/owner/providers/customer_registry_provider.dart';
import 'package:koniwalamatrimonial/owner/providers/registry_profiles_provider.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.profile});

  final RegistryProfileItem? profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _bioController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _religionController;
  late final TextEditingController _budgetController;
  late final TextEditingController _dobController;
  late final TextEditingController _birthTimeController;
  late final TextEditingController _birthPlaceController;
  late final TextEditingController _residenceController;
  late final TextEditingController _countryController;
  late final TextEditingController _stateController;
  late final TextEditingController _heightController;
  late final TextEditingController _gotraController;
  late final TextEditingController _educationController;
  late final TextEditingController _collegeController;
  late final TextEditingController _occupationController;
  late final TextEditingController _fatherNameController;
  late final TextEditingController _motherNameController;
  late final TextEditingController _paternalController;
  late final TextEditingController _maternalController;
  int _selectedTab = 0;
  String _profileCategory = 'Elite Global';
  String _gender = 'Female';
  String _maritalStatus = 'Never Married';
  String _complexion = 'Fair';
  bool _isManglik = false;
  String _dietaryHabit = 'Vegetarian';
  String _drinking = 'Non Consumer';
  String _smoking = 'Non Smoker';
  final ImagePicker _imagePicker = ImagePicker();
  final List<String> _pickedPhotoPaths = <String>[];
  String? _primaryPhotoPath;
  bool _hasRequestedCustomers = false;
  bool _isUpdating = false;

  static const List<String> _tabs = [
    'Personal',
    'Astro',
    'Education',
    'Family',
  ];

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(
      text: _profile.aboutMe == '-' || _profile.aboutMe.trim().isEmpty
          ? 'Aaryan is social and fun loving. He gives lot of value to relationships with family and friends.'
          : _profile.aboutMe,
    );
    _fullNameController = TextEditingController(text: _profile.name);
    _religionController = TextEditingController(
      text: _profile.religion == '-' ? 'Hindu' : _profile.religion,
    );
    _budgetController = TextEditingController(text: '15-20 LPA');
    _dobController = TextEditingController(
      text: _profile.dateOfBirth == '-' ? '08/24/1995' : _profile.dateOfBirth,
    );
    _birthTimeController = TextEditingController(
      text: _profile.birthTime == '-' ? '02:30 PM' : _profile.birthTime,
    );
    _birthPlaceController = TextEditingController(
      text: _profile.birthPlace == '-'
          ? 'Pune, Maharashtra'
          : _profile.birthPlace,
    );
    _residenceController = TextEditingController(
      text: _profile.residential == '-'
          ? 'Andheri West, Mumbai'
          : _profile.residential,
    );
    _countryController = TextEditingController(
      text: _profile.country == '-' ? 'India' : _profile.country,
    );
    _stateController = TextEditingController(text: 'Maharashtra');
    _heightController = TextEditingController(text: '165');
    _gotraController = TextEditingController(
      text: _profile.gotra == '-' ? 'Kashyap' : _profile.gotra,
    );
    _educationController = TextEditingController(
      text: _profile.profession == '-'
          ? 'B.Tech Computer Science'
          : _profile.profession,
    );
    _collegeController = TextEditingController(text: 'IIT Bombay');
    _occupationController = TextEditingController(
      text: _profile.work == '-' ? 'Software Engineer' : _profile.work,
    );
    _fatherNameController = TextEditingController(
      text: _profile.fatherName == '-' ? 'Rajesh Yadav' : _profile.fatherName,
    );
    _motherNameController = TextEditingController(
      text: _profile.motherName == '-' ? 'Sushma Yadav' : _profile.motherName,
    );
    _paternalController = TextEditingController(
      text: _profile.paternalDetails == '-'
          ? 'Business Owner'
          : _profile.paternalDetails,
    );
    _maternalController = TextEditingController(
      text: _profile.maternalDetails == '-'
          ? 'Homemaker'
          : _profile.maternalDetails,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasRequestedCustomers) {
      return;
    }

    _hasRequestedCustomers = true;
    final token = context.read<AuthProvider>().userModel?.accessToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<CustomerRegistryProvider>().fetchCustomers(
        token,
        forceRefresh: true,
      );
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    _fullNameController.dispose();
    _religionController.dispose();
    _budgetController.dispose();
    _dobController.dispose();
    _birthTimeController.dispose();
    _birthPlaceController.dispose();
    _residenceController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _heightController.dispose();
    _gotraController.dispose();
    _educationController.dispose();
    _collegeController.dispose();
    _occupationController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _paternalController.dispose();
    _maternalController.dispose();
    super.dispose();
  }

  RegistryProfileItem get _profile {
    return widget.profile ??
        const RegistryProfileItem(
          id: 'C-19564215470',
          originalId: 'C-19564215470',
          name: 'Meena yadav',
          age: '29',
          height: '5\'6"',
          city: 'Mumbai',
          work: 'Premium',
          profession: 'Profile',
          community: 'Verified',
          type: 'Bride',
          isPremium: true,
          image: 'assets/wedding_hero 1.png',
          photoUrls: ['assets/wedding_hero 1.png'],
          dateOfBirth: '-',
          birthTime: '-',
          birthPlace: '-',
          gotra: '-',
          residential: 'Mumbai',
          aboutMe:
              'Aaryan is social and fun loving. He gives lot of value to relationships with family and friends.',
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

  Future<void> _pickPhotoFromGallery() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
      );
      if (image == null || !mounted) {
        return;
      }

      setState(() {
        _pickedPhotoPaths.add(image.path);
        _primaryPhotoPath = image.path;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open gallery.')));
    }
  }

  void _setBestPhoto() {
    final photos = _currentPhotos;
    if (photos.isEmpty) {
      return;
    }

    setState(
      () => _primaryPhotoPath = _pickedPhotoPaths.isEmpty
          ? photos.first
          : _pickedPhotoPaths.last,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Best photo selected.')));
  }

  List<String> get _currentPhotos {
    final profile = _profile;
    final profilePhotos = profile.photoUrls.isEmpty
        ? [profile.image]
        : profile.photoUrls;
    return [...profilePhotos, ..._pickedPhotoPaths];
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final photos = _currentPhotos;
    final primaryPhoto = _primaryPhotoPath ?? photos.first;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(12.w, 16.h, 12.w, 110.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EditProfileHeader(profile: profile),
                    SizedBox(height: 20.h),
                    _EditProfileTabs(
                      tabs: _tabs,
                      selectedIndex: _selectedTab,
                      onSelected: (index) {
                        setState(() => _selectedTab = index);
                      },
                    ),
                    SizedBox(height: 18.h),
                    if (_selectedTab == 1)
                      _AstroEditTab(
                        isManglik: _isManglik,
                        dietaryHabit: _dietaryHabit,
                        drinking: _drinking,
                        smoking: _smoking,
                        onManglikChanged: (value) {
                          setState(() => _isManglik = value);
                        },
                        onDietaryHabitChanged: (value) {
                          setState(() => _dietaryHabit = value);
                        },
                        onDrinkingChanged: (value) {
                          setState(() => _drinking = value);
                        },
                        onSmokingChanged: (value) {
                          setState(() => _smoking = value);
                        },
                      )
                    else if (_selectedTab == 2)
                      _EducationEditTab(
                        educationController: _educationController,
                        collegeController: _collegeController,
                        occupationController: _occupationController,
                        incomeController: _budgetController,
                      )
                    else if (_selectedTab == 3)
                      _FamilyEditTab(
                        fatherNameController: _fatherNameController,
                        motherNameController: _motherNameController,
                        paternalController: _paternalController,
                        maternalController: _maternalController,
                      )
                    else
                      _PersonalEditTab(
                        profile: profile,
                        photos: photos,
                        primaryPhoto: primaryPhoto,
                        bioController: _bioController,
                        profileCategory: _profileCategory,
                        gender: _gender,
                        maritalStatus: _maritalStatus,
                        complexion: _complexion,
                        fullNameController: _fullNameController,
                        religionController: _religionController,
                        budgetController: _budgetController,
                        dobController: _dobController,
                        birthTimeController: _birthTimeController,
                        birthPlaceController: _birthPlaceController,
                        residenceController: _residenceController,
                        countryController: _countryController,
                        stateController: _stateController,
                        heightController: _heightController,
                        gotraController: _gotraController,
                        onProfileCategoryChanged: (value) {
                          setState(() => _profileCategory = value);
                        },
                        onGenderChanged: (value) {
                          setState(() => _gender = value);
                        },
                        onMaritalStatusChanged: (value) {
                          setState(() => _maritalStatus = value);
                        },
                        onComplexionChanged: (value) {
                          setState(() => _complexion = value);
                        },
                        onAddPhoto: _pickPhotoFromGallery,
                        onSetBestPhoto: _setBestPhoto,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _EditProfileFooter(
        isUpdating: _isUpdating,
        onDiscard: () => Navigator.of(context).maybePop(),
        onUpdate: _updateProfile,
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (_isUpdating) {
      return;
    }

    if (widget.profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Open a registry profile before updating it.'),
        ),
      );
      return;
    }

    final profile = _profile;
    final profileId = profile.originalId.trim();
    if (profileId.isEmpty || profileId == '-') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile id is missing.')));
      return;
    }

    setState(() => _isUpdating = true);
    final token = context.read<AuthProvider>().userModel?.accessToken;
    await context.read<CustomerRegistryProvider>().fetchCustomers(token);
    if (!mounted) {
      return;
    }
    final payload = _buildUpdateProfilePayload();
    final updated = await context
        .read<RegistryProfilesProvider>()
        .updateProfile(
          accessToken: token,
          profileId: profileId,
          payload: payload,
        );

    if (!mounted) {
      return;
    }

    setState(() => _isUpdating = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated
              ? 'Profile updated successfully.'
              : (context.read<RegistryProfilesProvider>().createError ??
                    'Unable to update profile.'),
        ),
      ),
    );

    if (updated) {
      Navigator.of(context).maybePop();
    }
  }

  Map<String, dynamic> _buildUpdateProfilePayload() {
    final linkedCustomerId = _linkedCustomerId();
    return _withoutEmptyValues({
      if (linkedCustomerId != null) 'customerId': linkedCustomerId,
      'name': _fullNameController.text.trim(),
      'gender': _enumValue(_gender),
      'category': _profileCategoryValue(_profileCategory),
      'maritalStatus': _enumValue(_maritalStatus),
      'religion': _religionController.text.trim(),
      'dateOfBirth': _dateOfBirthValue(),
      'birthTime': _birthTimeController.text.trim(),
      'currentResidential': _residenceController.text.trim(),
      'state': _stateController.text.trim(),
      'country': _countryController.text.trim(),
      'height': int.tryParse(_heightController.text.trim()),
      'gotra': _gotraController.text.trim(),
      'complexion': _enumValue(_complexion),
      'expectedBudget': _budgetValue(_budgetController.text.trim()),
      'aboutMe': _bioController.text.trim(),
      'education': _educationController.text.trim(),
      'occupation': _occupationController.text.trim(),
      'fatherName': _fatherNameController.text.trim(),
      'motherName': _motherNameController.text.trim(),
      'paternalDetails': _paternalController.text.trim(),
      'maternalDetails': _maternalController.text.trim(),
      'diet': _enumValue(_dietaryHabit),
      'manglik': _isManglik,
      'status': 'ACTIVE',
    });
  }

  String? _linkedCustomerId() {
    final profileId = _profile.originalId.trim();
    if (profileId.isEmpty) {
      return null;
    }

    final customers = context.read<CustomerRegistryProvider>().customers;
    for (final customer in customers) {
      final hasProfile = customer.profiles.any(
        (profile) => profile.id == profileId,
      );
      if (hasProfile && customer.id.trim().isNotEmpty) {
        return customer.id.trim();
      }
    }

    return null;
  }

  Map<String, dynamic> _withoutEmptyValues(Map<String, dynamic> values) {
    return Map.fromEntries(
      values.entries.where((entry) {
        final value = entry.value;
        if (value == null) {
          return false;
        }
        if (value is String) {
          final trimmed = value.trim();
          return trimmed.isNotEmpty && trimmed != '-';
        }
        return true;
      }),
    );
  }

  String _enumValue(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), '_');
  }

  String _profileCategoryValue(String value) {
    switch (value.trim().toLowerCase()) {
      case 'elite global':
      case 'elite':
        return 'ELITE';
      case 'direct':
        return 'DIRECT';
      case 'premium':
      case 'classic':
      case 'other':
        return 'OTHER';
      default:
        return 'OTHER';
    }
  }

  String? _budgetValue(String value) {
    switch (value) {
      case '0 - 5 Lakh':
        return '0_5_LAKH';
      case '5 - 10 Lakh':
        return '5_10_LAKH';
      case '10 - 20 Lakh':
      case '15-20 LPA':
        return '10_20_LAKH';
      case '20+ Lakh':
        return '20_LAKH_PLUS';
      default:
        return value.trim().isEmpty ? null : value.trim();
    }
  }

  String? _dateOfBirthValue() {
    final text = _dobController.text.trim();
    if (text.isEmpty || text == '-') {
      return null;
    }

    final slashParts = text.split('/');
    if (slashParts.length == 3) {
      final month = int.tryParse(slashParts[0]);
      final day = int.tryParse(slashParts[1]);
      final year = int.tryParse(slashParts[2]);
      if (month != null && day != null && year != null) {
        return '${year.toString().padLeft(4, '0')}-'
            '${month.toString().padLeft(2, '0')}-'
            '${day.toString().padLeft(2, '0')}';
      }
    }

    final displayParts = text.split(RegExp(r'\s+'));
    if (displayParts.length == 3) {
      final day = int.tryParse(displayParts[0]);
      final month = _monthNumber(displayParts[1]);
      final year = int.tryParse(displayParts[2]);
      if (day != null && month != null && year != null) {
        return '${year.toString().padLeft(4, '0')}-'
            '${month.toString().padLeft(2, '0')}-'
            '${day.toString().padLeft(2, '0')}';
      }
    }

    return text;
  }

  int? _monthNumber(String month) {
    final normalized = month.trim().toLowerCase();
    if (normalized.length < 3) {
      return null;
    }

    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    return months[normalized.substring(0, 3)];
  }
}

class _EditProfileHeader extends StatelessWidget {
  const _EditProfileHeader({required this.profile});

  final RegistryProfileItem profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROFILE DIGITIZATION > DATA ENTRY CORE',
          style: GoogleFonts.inter(
            color: const Color(0xFF7E737A),
            fontSize: 11.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: .5,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Editing Profile for ${profile.name}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: AppColors.rmPrimary,
            fontSize: 25.sp,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _StatusChip(
              icon: Icons.link,
              label: 'Linking to Client: ${profile.name}',
              background: const Color(0xFFDDF8E7),
              foreground: const Color(0xFF116B36),
            ),
            const _StatusChip(label: 'Manual Entry Mode'),
            const _StatusChip(label: 'Status: Editing'),
          ],
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    this.icon,
    this.background = const Color(0xFFEDEDEF),
    this.foreground = const Color(0xFF5B5358),
  });

  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11.sp, color: foreground),
            SizedBox(width: 5.w),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              color: foreground,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileTabs extends StatelessWidget {
  const _EditProfileTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < tabs.length; index++)
            InkWell(
              onTap: () => onSelected(index),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selectedIndex == index
                          ? AppColors.rmPrimary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tabs[index],
                  style: GoogleFonts.inter(
                    color: selectedIndex == index
                        ? AppColors.rmPrimary
                        : const Color(0xFF625C61),
                    fontSize: 14.sp,
                    fontWeight: selectedIndex == index
                        ? FontWeight.w900
                        : FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroPhotoCard extends StatelessWidget {
  const _HeroPhotoCard({
    required this.image,
    required this.onAddPhoto,
    required this.onSetBestPhoto,
  });

  final String image;
  final VoidCallback onAddPhoto;
  final VoidCallback onSetBestPhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18.w, 24.h, 18.w, 18.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 116.w,
            height: 116.w,
            padding: EdgeInsets.all(5.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE6CDD6), width: 2),
            ),
            child: ClipOval(child: _ProfileImage(path: image)),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _OutlinedEditButton(
                  icon: Icons.add_a_photo_outlined,
                  label: 'Add Photo',
                  onPressed: onAddPhoto,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _OutlinedEditButton(
                  icon: Icons.star,
                  label: 'Set Best Photo',
                  onPressed: onSetBestPhoto,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceDocumentCard extends StatelessWidget {
  const _SourceDocumentCard({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 12.h),
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  color: AppColors.rmPrimary,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Source Document',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF343039),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  'Reference Only',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF7E737A),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.r)),
            child: Image.asset(path, width: double.infinity, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }
}

class _PersonalEditTab extends StatelessWidget {
  const _PersonalEditTab({
    required this.profile,
    required this.photos,
    required this.primaryPhoto,
    required this.bioController,
    required this.profileCategory,
    required this.gender,
    required this.maritalStatus,
    required this.complexion,
    required this.fullNameController,
    required this.religionController,
    required this.budgetController,
    required this.dobController,
    required this.birthTimeController,
    required this.birthPlaceController,
    required this.residenceController,
    required this.countryController,
    required this.stateController,
    required this.heightController,
    required this.gotraController,
    required this.onProfileCategoryChanged,
    required this.onGenderChanged,
    required this.onMaritalStatusChanged,
    required this.onComplexionChanged,
    required this.onAddPhoto,
    required this.onSetBestPhoto,
  });

  final RegistryProfileItem profile;
  final List<String> photos;
  final String primaryPhoto;
  final TextEditingController bioController;
  final String profileCategory;
  final String gender;
  final String maritalStatus;
  final String complexion;
  final TextEditingController fullNameController;
  final TextEditingController religionController;
  final TextEditingController budgetController;
  final TextEditingController dobController;
  final TextEditingController birthTimeController;
  final TextEditingController birthPlaceController;
  final TextEditingController residenceController;
  final TextEditingController countryController;
  final TextEditingController stateController;
  final TextEditingController heightController;
  final TextEditingController gotraController;
  final ValueChanged<String> onProfileCategoryChanged;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<String> onMaritalStatusChanged;
  final ValueChanged<String> onComplexionChanged;
  final VoidCallback onAddPhoto;
  final VoidCallback onSetBestPhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HeroPhotoCard(
          image: primaryPhoto,
          onAddPhoto: onAddPhoto,
          onSetBestPhoto: onSetBestPhoto,
        ),
        SizedBox(height: 20.h),
        _PortfolioPhotos(photos: photos, onAddPhoto: onAddPhoto),
        SizedBox(height: 18.h),
        _LinkedClientCard(profile: profile),
        SizedBox(height: 22.h),
        _BiographyCard(controller: bioController),
        SizedBox(height: 24.h),
        _ProfileEditForm(
          profileCategory: profileCategory,
          gender: gender,
          maritalStatus: maritalStatus,
          complexion: complexion,
          fullNameController: fullNameController,
          religionController: religionController,
          budgetController: budgetController,
          dobController: dobController,
          birthTimeController: birthTimeController,
          birthPlaceController: birthPlaceController,
          residenceController: residenceController,
          countryController: countryController,
          stateController: stateController,
          heightController: heightController,
          gotraController: gotraController,
          onProfileCategoryChanged: onProfileCategoryChanged,
          onGenderChanged: onGenderChanged,
          onMaritalStatusChanged: onMaritalStatusChanged,
          onComplexionChanged: onComplexionChanged,
        ),
      ],
    );
  }
}

class _EducationEditTab extends StatelessWidget {
  const _EducationEditTab({
    required this.educationController,
    required this.collegeController,
    required this.occupationController,
    required this.incomeController,
  });

  final TextEditingController educationController;
  final TextEditingController collegeController;
  final TextEditingController occupationController;
  final TextEditingController incomeController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SourceDocumentCard(
          path: 'assets/Screenshot 2026-06-01 145240.png',
        ),
        SizedBox(height: 24.h),
        _EditTextField(
          label: 'HIGHEST EDUCATION',
          controller: educationController,
        ),
        SizedBox(height: 14.h),
        _EditTextField(
          label: 'COLLEGE / UNIVERSITY',
          controller: collegeController,
        ),
        SizedBox(height: 14.h),
        _EditTextField(
          label: 'PROFESSION / OCCUPATION',
          controller: occupationController,
        ),
        SizedBox(height: 14.h),
        _EditTextField(label: 'ANNUAL INCOME', controller: incomeController),
      ],
    );
  }
}

class _FamilyEditTab extends StatelessWidget {
  const _FamilyEditTab({
    required this.fatherNameController,
    required this.motherNameController,
    required this.paternalController,
    required this.maternalController,
  });

  final TextEditingController fatherNameController;
  final TextEditingController motherNameController;
  final TextEditingController paternalController;
  final TextEditingController maternalController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SourceDocumentCard(
          path: 'assets/Screenshot 2026-06-01 150615.png',
        ),
        SizedBox(height: 24.h),
        _EditTextField(
          label: 'FATHER\'S NAME',
          controller: fatherNameController,
        ),
        SizedBox(height: 14.h),
        _EditTextField(
          label: 'MOTHER\'S NAME',
          controller: motherNameController,
        ),
        SizedBox(height: 14.h),
        _EditTextField(
          label: 'PATERNAL DETAILS',
          controller: paternalController,
        ),
        SizedBox(height: 14.h),
        _EditTextField(
          label: 'MATERNAL DETAILS',
          controller: maternalController,
        ),
      ],
    );
  }
}

class _AstroEditTab extends StatelessWidget {
  const _AstroEditTab({
    required this.isManglik,
    required this.dietaryHabit,
    required this.drinking,
    required this.smoking,
    required this.onManglikChanged,
    required this.onDietaryHabitChanged,
    required this.onDrinkingChanged,
    required this.onSmokingChanged,
  });

  final bool isManglik;
  final String dietaryHabit;
  final String drinking;
  final String smoking;
  final ValueChanged<bool> onManglikChanged;
  final ValueChanged<String> onDietaryHabitChanged;
  final ValueChanged<String> onDrinkingChanged;
  final ValueChanged<String> onSmokingChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MANGLIK STATUS',
            style: GoogleFonts.inter(
              color: AppColors.rmPrimary,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _ManglikChoice(
                  label: 'Yes',
                  selected: isManglik,
                  onTap: () => onManglikChanged(true),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _ManglikChoice(
                  label: 'No',
                  selected: !isManglik,
                  onTap: () => onManglikChanged(false),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          _EditDropdownField(
            label: 'DIETARY HABIT',
            value: dietaryHabit,
            items: const [
              'Vegetarian',
              'Non Vegetarian',
              'Eggetarian',
              'Vegan',
            ],
            onChanged: onDietaryHabitChanged,
          ),
          SizedBox(height: 18.h),
          _EditDropdownField(
            label: 'DRINKING',
            value: drinking,
            items: const ['Non Consumer', 'Occasionally', 'Regular'],
            onChanged: onDrinkingChanged,
          ),
          SizedBox(height: 18.h),
          _EditDropdownField(
            label: 'SMOKING',
            value: smoking,
            items: const ['Non Smoker', 'Occasionally', 'Regular'],
            onChanged: onSmokingChanged,
          ),
        ],
      ),
    );
  }
}

class _ManglikChoice extends StatelessWidget {
  const _ManglikChoice({
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(9.r),
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFDDE9) : const Color(0xFFF6F7F9),
          borderRadius: BorderRadius.circular(9.r),
          border: Border.all(
            color: selected ? AppColors.rmPrimary : const Color(0xFFC7CDD6),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18.sp,
              color: selected ? AppColors.rmPrimary : const Color(0xFFD8C5CE),
            ),
            SizedBox(width: 10.w),
            Text(
              label,
              style: GoogleFonts.inter(
                color: selected ? AppColors.rmPrimary : const Color(0xFF343039),
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioPhotos extends StatelessWidget {
  const _PortfolioPhotos({required this.photos, required this.onAddPhoto});

  final List<String> photos;
  final VoidCallback onAddPhoto;

  @override
  Widget build(BuildContext context) {
    final visiblePhotos = photos.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Portfolio Photos',
                style: GoogleFonts.inter(
                  color: AppColors.rmPrimary,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onAddPhoto,
              icon: Icon(Icons.add, size: 14.sp),
              label: Text(
                'Add Photo',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.rmPrimary,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            for (final photo in visiblePhotos) ...[
              _PortfolioPhoto(path: photo),
              SizedBox(width: 10.w),
            ],
            _AddPortfolioSlot(onTap: onAddPhoto),
          ],
        ),
      ],
    );
  }
}

class _LinkedClientCard extends StatelessWidget {
  const _LinkedClientCard({required this.profile});

  final RegistryProfileItem profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18.w, 16.h, 12.w, 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF9F0),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFC5ECD3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF178347),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF123C22),
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                      child: Text(
                        'VERIFIED',
                        style: GoogleFonts.inter(
                          color: AppColors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  '+91 9564215470 - PREMIUM Plan',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF237A49),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: const Color(0xFF237A49),
                      size: 13.sp,
                    ),
                    SizedBox(width: 3.w),
                    Text(profile.city, style: _linkedMetaStyle()),
                    SizedBox(width: 10.w),
                    Icon(
                      Icons.calendar_today_outlined,
                      color: const Color(0xFF237A49),
                      size: 12.sp,
                    ),
                    SizedBox(width: 3.w),
                    Text('Linked 18 May 2026', style: _linkedMetaStyle()),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              'Change',
              style: GoogleFonts.inter(
                color: AppColors.rmPrimary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w900,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _linkedMetaStyle() {
    return GoogleFonts.inter(
      color: const Color(0xFF237A49),
      fontSize: 12.sp,
      fontWeight: FontWeight.w700,
    );
  }
}

class _BiographyCard extends StatelessWidget {
  const _BiographyCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Biography / About Me',
                style: GoogleFonts.inter(
                  color: AppColors.rmPrimary,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: const Color(0xFFEDEBFF),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Text(
                'AI Enhanced',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6356CE),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        TextField(
          controller: controller,
          minLines: 5,
          maxLines: 6,
          style: GoogleFonts.inter(
            color: const Color(0xFF443D42),
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.white,
            contentPadding: EdgeInsets.all(18.r),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _OutlinedEditButton extends StatelessWidget {
  const _OutlinedEditButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14.sp),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.rmPrimary,
        side: const BorderSide(color: AppColors.rmPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9.r)),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
        textStyle: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ProfileEditForm extends StatelessWidget {
  const _ProfileEditForm({
    required this.profileCategory,
    required this.gender,
    required this.maritalStatus,
    required this.complexion,
    required this.fullNameController,
    required this.religionController,
    required this.budgetController,
    required this.dobController,
    required this.birthTimeController,
    required this.birthPlaceController,
    required this.residenceController,
    required this.countryController,
    required this.stateController,
    required this.heightController,
    required this.gotraController,
    required this.onProfileCategoryChanged,
    required this.onGenderChanged,
    required this.onMaritalStatusChanged,
    required this.onComplexionChanged,
  });

  final String profileCategory;
  final String gender;
  final String maritalStatus;
  final String complexion;
  final TextEditingController fullNameController;
  final TextEditingController religionController;
  final TextEditingController budgetController;
  final TextEditingController dobController;
  final TextEditingController birthTimeController;
  final TextEditingController birthPlaceController;
  final TextEditingController residenceController;
  final TextEditingController countryController;
  final TextEditingController stateController;
  final TextEditingController heightController;
  final TextEditingController gotraController;
  final ValueChanged<String> onProfileCategoryChanged;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<String> onMaritalStatusChanged;
  final ValueChanged<String> onComplexionChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _EditDropdownField(
          label: 'PROFILE CATEGORY',
          value: profileCategory,
          items: const ['Elite Global', 'Premium', 'Classic'],
          onChanged: onProfileCategoryChanged,
        ),
        SizedBox(height: 14.h),
        _EditTextField(label: 'FULL NAME', controller: fullNameController),
        SizedBox(height: 14.h),
        _TwoColumnFields(
          left: _EditDropdownField(
            label: 'GENDER',
            value: gender,
            items: const ['Female', 'Male', 'Other'],
            onChanged: onGenderChanged,
          ),
          right: _EditDropdownField(
            label: 'MARITAL STATUS',
            value: maritalStatus,
            items: const ['Never Married', 'Divorced', 'Widowed'],
            onChanged: onMaritalStatusChanged,
          ),
        ),
        SizedBox(height: 14.h),
        _EditTextField(label: 'RELIGION', controller: religionController),
        SizedBox(height: 14.h),
        _EditTextField(
          label: 'BUDGET PREFERENCE',
          controller: budgetController,
        ),
        SizedBox(height: 24.h),
        const _EditSectionTitle('Birth & Location'),
        SizedBox(height: 12.h),
        _EditTextField(label: 'DATE OF BIRTH', controller: dobController),
        SizedBox(height: 14.h),
        _TwoColumnFields(
          left: _EditTextField(
            label: 'TIME OF BIRTH',
            controller: birthTimeController,
          ),
          right: _EditTextField(
            label: 'PLACE OF BIRTH',
            controller: birthPlaceController,
          ),
        ),
        SizedBox(height: 14.h),
        _EditTextField(
          label: 'CURRENT RESIDENCE',
          controller: residenceController,
        ),
        SizedBox(height: 14.h),
        _TwoColumnFields(
          left: _EditTextField(label: 'COUNTRY', controller: countryController),
          right: _EditTextField(label: 'STATE', controller: stateController),
        ),
        SizedBox(height: 24.h),
        const _EditSectionTitle('Physical & Ancestry'),
        SizedBox(height: 12.h),
        _TwoColumnFields(
          left: _EditTextField(
            label: 'HEIGHT (CM)',
            controller: heightController,
          ),
          right: _EditDropdownField(
            label: 'COMPLEXION',
            value: complexion,
            items: const ['Fair', 'Wheatish', 'Dusky'],
            onChanged: onComplexionChanged,
          ),
        ),
        SizedBox(height: 14.h),
        _EditTextField(label: 'GOTRA', controller: gotraController),
      ],
    );
  }
}

class _TwoColumnFields extends StatelessWidget {
  const _TwoColumnFields({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        SizedBox(width: 14.w),
        Expanded(child: right),
      ],
    );
  }
}

class _EditSectionTitle extends StatelessWidget {
  const _EditSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: AppColors.rmPrimary,
            fontSize: 15.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(width: 10.w),
        const Expanded(child: Divider(color: Color(0xFFD8DCE4), height: 1)),
      ],
    );
  }
}

class _EditTextField extends StatelessWidget {
  const _EditTextField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _EditFieldFrame(
      label: label,
      child: TextField(
        controller: controller,
        style: _fieldTextStyle(),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _EditDropdownField extends StatelessWidget {
  const _EditDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _EditFieldFrame(
      label: label,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: const Color(0xFF77727A),
            size: 20.sp,
          ),
          style: _fieldTextStyle(),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (selected) {
            if (selected != null) {
              onChanged(selected);
            }
          },
        ),
      ),
    );
  }
}

class _EditFieldFrame extends StatelessWidget {
  const _EditFieldFrame({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF6B6470),
            fontSize: 10.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 7.h),
        Container(
          height: 43.h,
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _EditProfileFooter extends StatelessWidget {
  const _EditProfileFooter({
    required this.isUpdating,
    required this.onDiscard,
    required this.onUpdate,
  });

  final bool isUpdating;
  final VoidCallback onDiscard;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 10.h),
        decoration: const BoxDecoration(color: Color(0xFFF7F8FC)),
        child: Row(
          children: [
            SizedBox(
              width: 122.w,
              height: 48.h,
              child: OutlinedButton(
                onPressed: isUpdating ? null : onDiscard,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE11D2E),
                  side: const BorderSide(color: Color(0xFFE11D2E)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Discard',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: SizedBox(
                height: 48.h,
                child: ElevatedButton(
                  onPressed: isUpdating ? null : onUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rmPrimary,
                    foregroundColor: AppColors.white,
                    elevation: 8,
                    shadowColor: AppColors.rmPrimary.withValues(alpha: .28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: isUpdating
                      ? SizedBox(
                          width: 20.sp,
                          height: 20.sp,
                          child: const CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Update Profile',
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle _fieldTextStyle() {
  return GoogleFonts.inter(
    color: const Color(0xFF343039),
    fontSize: 15.sp,
    fontWeight: FontWeight.w700,
  );
}

class _PortfolioPhoto extends StatelessWidget {
  const _PortfolioPhoto({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: SizedBox(
        width: 73.w,
        height: 73.w,
        child: _ProfileImage(path: path),
      ),
    );
  }
}

class _AddPortfolioSlot extends StatelessWidget {
  const _AddPortfolioSlot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        width: 73.w,
        height: 73.w,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: const Color(0xFFE5B8C8),
            style: BorderStyle.solid,
          ),
        ),
        child: Icon(Icons.add, color: const Color(0xFFB78B9B), size: 20.sp),
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final ImageProvider provider;
    if (path.startsWith('http')) {
      provider = NetworkImage(path);
    } else if (path.startsWith('assets/')) {
      provider = AssetImage(path);
    } else {
      provider = FileImage(File(path));
    }

    return Image(
      image: provider,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) {
        return Container(
          color: const Color(0xFFF6EDF1),
          child: Icon(Icons.person, color: AppColors.rmPrimary, size: 32.sp),
        );
      },
    );
  }
}
