import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/owner/providers/registry_profiles_provider.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:provider/provider.dart';

import '../models/customer_registry_item.dart';

class NewProfileDigitizationScreen extends StatefulWidget {
  const NewProfileDigitizationScreen({super.key, this.customer});

  final CustomerRegistryItem? customer;

  @override
  State<NewProfileDigitizationScreen> createState() =>
      _NewProfileDigitizationScreenState();
}

class _NewProfileDigitizationScreenState
    extends State<NewProfileDigitizationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _biographyController;
  late final TextEditingController _religionController;
  late final TextEditingController _dateOfBirthController;
  late final TextEditingController _timeOfBirthController;
  late final TextEditingController _birthPlaceController;
  late final TextEditingController _currentResidentialController;
  late final TextEditingController _heightController;
  String? _selectedPackageType;
  String? _selectedProfileCategory;
  String? _selectedGender;
  String? _selectedMaritalStatus;
  String? _selectedBudgetRange;
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedGotra;
  String? _selectedComplexion;
  bool _isManualEntryEnabled = false;
  int _selectedProfileTab = 0;
  final ImagePicker _imagePicker = ImagePicker();
  String? _resumePdfPath;
  String? _resumePdfName;
  final List<String> _photoPaths = <String>[];

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.customer?.name ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.customer?.phone == '-' ? '' : widget.customer?.phone ?? '',
    );
    _biographyController = TextEditingController();
    _religionController = TextEditingController();
    _dateOfBirthController = TextEditingController();
    _timeOfBirthController = TextEditingController();
    _birthPlaceController = TextEditingController();
    _currentResidentialController = TextEditingController();
    _heightController = TextEditingController(text: '0');
    _selectedPackageType = _normalizePackageType(widget.customer?.packageType);
    _selectedProfileCategory = 'Other';
    _selectedMaritalStatus = 'Never Married';
    _selectedCountry = 'India';
    _selectedComplexion = 'Fair';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _biographyController.dispose();
    _religionController.dispose();
    _dateOfBirthController.dispose();
    _timeOfBirthController.dispose();
    _birthPlaceController.dispose();
    _currentResidentialController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  String get _linkedClientName {
    final customerName = widget.customer?.name.trim() ?? '';
    if (customerName.isNotEmpty) {
      return customerName;
    }

    final typedName = _fullNameController.text.trim();
    if (typedName.isNotEmpty) {
      return typedName;
    }

    return 'Selected Client';
  }

  String get _linkedClientPhone {
    final typedPhone = _phoneController.text.trim();
    if (typedPhone.isNotEmpty) {
      return typedPhone;
    }

    return '9000000003';
  }

  String get _linkedClientPlan {
    final packageType =
        _selectedPackageType ??
        _normalizePackageType(widget.customer?.packageType) ??
        'Standard';
    return '$packageType Plan';
  }

  String get _linkedClientDate {
    final createdOn = widget.customer?.createdOn.trim() ?? '';
    if (createdOn.isNotEmpty && createdOn != '-') {
      return 'Linked $createdOn';
    }

    return 'Linked 12 May 2026';
  }

  String get _linkedClientLocation => 'Udaipur';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      bottomNavigationBar: _buildBottomActionBar(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 28.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(context),
                SizedBox(height: 18.h),
                _buildStatusPill(),
                SizedBox(height: 18.h),
                _buildResumeUploadCard(),
                SizedBox(height: 16.h),
                Text(
                  'PROFILE DIGITIZATION | DATA ENTRY CORE',
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF8C7F84),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Digitizing Profile for $_linkedClientName',
                  style: GoogleFonts.manrope(
                    color: AppColors.rmPrimary,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.08,
                  ),
                ),
                SizedBox(height: 14.h),
                _buildInfoChip(
                  label: 'Status: Direct profile creation',
                  backgroundColor: AppColors.white,
                  borderColor: const Color(0xFFE5B8C6),
                  textColor: const Color(0xFF7B5A64),
                ),
                SizedBox(height: 10.h),
                _buildInfoChip(
                  label: 'Linking to Client: $_linkedClientName',
                  icon: Icons.link_rounded,
                  backgroundColor: const Color(0xFF08A66C),
                  borderColor: const Color(0xFF08A66C),
                  textColor: AppColors.white,
                ),
                SizedBox(height: 26.h),
                _buildPhotoUploadCard(),
                SizedBox(height: 24.h),
                _buildProfileWorkspaceSection(),
                if (_isManualEntryEnabled || widget.customer == null) ...[
                  SizedBox(height: 24.h),
                  _buildManualEntrySection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final isCreating = context.watch<RegistryProfilesProvider>().isCreating;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: Color(0xFFF0DDE4))),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildBottomActionButton(
                label: 'Discard',
                icon: Icons.delete_outline_rounded,
                onTap: isCreating ? null : _handleDiscard,
                foregroundColor: const Color(0xFFD04C66),
                backgroundColor: AppColors.white,
                borderColor: const Color(0xFFEBC6D1),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildBottomActionButton(
                label: 'Save Draft',
                icon: Icons.description_outlined,
                onTap: isCreating ? null : _handleSaveDraft,
                foregroundColor: const Color(0xFF7A6C72),
                backgroundColor: AppColors.white,
                borderColor: const Color(0xFFEBC6D1),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildBottomActionButton(
                label: isCreating ? 'Creating...' : 'Create Profile',
                icon: isCreating
                    ? Icons.hourglass_top_rounded
                    : Icons.person_add_alt_1_rounded,
                onTap: isCreating ? null : _handleCommit,
                foregroundColor: AppColors.white,
                backgroundColor: AppColors.rmPrimary,
                borderColor: AppColors.rmPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final isCreating = context.watch<RegistryProfilesProvider>().isCreating;

    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(8.r),
            child: Icon(
              Icons.close_rounded,
              color: const Color(0xFF9E5D75),
              size: 20.sp,
            ),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: isCreating ? null : _handleCommit,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.rmPrimary,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          ),
          child: Text(
            isCreating ? 'Saving...' : 'Commit',
            style: GoogleFonts.manrope(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE7CCD5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.toggle_on_rounded,
            color: const Color(0xFF4F4A4C),
            size: 16.sp,
          ),
          SizedBox(width: 6.w),
          Text(
            'Resume Upload On',
            style: GoogleFonts.manrope(
              color: const Color(0xFF4F4A4C),
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeUploadCard() {
    return _buildDashedCard(
      onTap: _pickResumePdf,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isManualEntryEnabled = !_isManualEntryEnabled;
                });
              },
              icon: Icon(Icons.edit_note_outlined, size: 16.sp),
              label: Text(
                'Manual Entry',
                style: GoogleFonts.manrope(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6A5A60),
                side: const BorderSide(color: Color(0xFFE7D7DD)),
                backgroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            width: 64.r,
            height: 64.r,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1F4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_upload_outlined,
              color: AppColors.rmPrimary,
              size: 30.sp,
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            'Upload Resume PDF',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: const Color(0xFF3D3035),
              fontSize: 25.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Drag and drop a PDF here, or click to browse files.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: const Color(0xFF7A6D72),
              fontSize: 16.sp,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 20.h),
          if (_resumePdfName != null) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8FA),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFE8D7DD)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf_outlined,
                    color: AppColors.rmPrimary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _resumePdfName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF3D3035),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove resume',
                    onPressed: () {
                      setState(() {
                        _resumePdfPath = null;
                        _resumePdfName = null;
                      });
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: const Color(0xFF7A6D72),
                      size: 18.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
          ],
          OutlinedButton.icon(
            onPressed: _pickResumePdf,
            icon: Icon(Icons.upload_file_rounded, size: 16.sp),
            label: Text(
              _resumePdfName == null ? 'Browse PDF' : 'Change PDF',
              style: GoogleFonts.manrope(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7B666E),
              side: const BorderSide(color: Color(0xFFE8D7DD)),
              backgroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUploadCard() {
    return _buildDashedCard(
      child: Column(
        children: [
          Container(
            width: 62.r,
            height: 62.r,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1F4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_a_photo_outlined,
              color: const Color(0xFF6A545E),
              size: 28.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            _photoPaths.isEmpty ? 'Upload Profile Picture' : 'Profile Photos',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: const Color(0xFF55484D),
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'JPEG, PNG visual assets supported.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: const Color(0xFF8C8084),
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 18.h),
          if (_photoPaths.isNotEmpty) ...[
            SizedBox(
              height: 84.w,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photoPaths.length,
                separatorBuilder: (_, _) => SizedBox(width: 10.w),
                itemBuilder: (context, index) {
                  return _PickedProfilePhoto(
                    path: _photoPaths[index],
                    onRemove: () => _removePhoto(index),
                  );
                },
              ),
            ),
            SizedBox(height: 18.h),
          ],
          OutlinedButton(
            onPressed: _pickPhotoFromGallery,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6C4D5A),
              side: const BorderSide(color: Color(0xFFE5CBD5)),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              _photoPaths.isEmpty ? '+ Add First Photo' : '+ Add More Photos',
              style: GoogleFonts.manrope(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileWorkspaceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileTabBar(),
        SizedBox(height: 14.h),
        if (_selectedProfileTab == 0) ...[
          _buildPersonalDetailsCard(),
          SizedBox(height: 16.h),
          _buildPortfolioPhotosCard(),
          SizedBox(height: 16.h),
          _buildBiographyCard(),
          SizedBox(height: 18.h),
          _buildPersonalFormSection(),
        ] else
          _buildComingSoonCard(
            title: _selectedProfileTab == 1
                ? 'Astro Details'
                : 'Education Details',
            description: _selectedProfileTab == 1
                ? 'Match kundali, birth information, and related astro details here.'
                : 'Add academic background and qualification details here.',
          ),
      ],
    );
  }

  Widget _buildProfileTabBar() {
    const tabs = <String>['Personal', 'Astro', 'Education'];
    const icons = <IconData>[
      Icons.person_outline_rounded,
      Icons.auto_awesome_outlined,
      Icons.school_outlined,
    ];

    return Row(
      children: List.generate(tabs.length, (index) {
        final isSelected = _selectedProfileTab == index;

        return Expanded(
          child: InkWell(
            onTap: () => setState(() => _selectedProfileTab = index),
            child: Container(
              padding: EdgeInsets.only(bottom: 10.h),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? AppColors.rmPrimary
                        : const Color(0xFFECDDE3),
                    width: isSelected ? 2.4 : 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icons[index],
                    size: 15.sp,
                    color: isSelected
                        ? AppColors.rmPrimary
                        : const Color(0xFF6E646A),
                  ),
                  SizedBox(width: 5.w),
                  Flexible(
                    child: Text(
                      tabs[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: isSelected
                            ? AppColors.rmPrimary
                            : const Color(0xFF6E646A),
                        fontSize: 16.sp,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPersonalDetailsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFBFEBD9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34.r,
                height: 34.r,
                decoration: const BoxDecoration(
                  color: Color(0xFF11A66B),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_border_rounded,
                  color: AppColors.white,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _linkedClientName,
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF3E5A4E),
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 6.h,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildMiniBadge(
                          label: 'VERIFIED CLIENT',
                          backgroundColor: const Color(0xFFDFF4E8),
                          textColor: const Color(0xFF5F9C78),
                        ),
                        Text(
                          'Change',
                          style: GoogleFonts.manrope(
                            color: AppColors.rmPrimary,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Wrap(
            runSpacing: 10.h,
            spacing: 16.w,
            children: [
              _buildClientMetaItem(
                icon: Icons.phone_rounded,
                label: _linkedClientPhone,
              ),
              _buildClientMetaItem(
                icon: Icons.location_on_outlined,
                label: _linkedClientLocation,
              ),
              _buildClientMetaItem(
                icon: Icons.credit_card_outlined,
                label: _linkedClientPlan,
              ),
              _buildClientMetaItem(
                icon: Icons.calendar_today_outlined,
                label: _linkedClientDate,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioPhotosCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF0DDE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portfolio Photos',
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF4D4347),
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Add more bride/groom photos to the portfolio gallery.',
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF7E7479),
                        fontSize: 14.sp,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              OutlinedButton.icon(
                onPressed: _pickPhotoFromGallery,
                icon: Icon(Icons.add_photo_alternate_outlined, size: 16.sp),
                label: Text(
                  'Add Photo',
                  style: GoogleFonts.manrope(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.rmPrimary,
                  side: const BorderSide(color: Color(0xFFE4B3C4)),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ],
          ),
          if (_photoPaths.isNotEmpty) ...[
            SizedBox(height: 14.h),
            SizedBox(
              height: 76.w,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photoPaths.length,
                separatorBuilder: (_, _) => SizedBox(width: 10.w),
                itemBuilder: (context, index) {
                  return _PickedProfilePhoto(
                    path: _photoPaths[index],
                    size: 76.w,
                    onRemove: () => _removePhoto(index),
                  );
                },
              ),
            ),
          ] else ...[
            SizedBox(height: 12.h),
            Text(
              'No gallery photos added yet.',
              style: GoogleFonts.manrope(
                color: const Color(0xFF9B8E94),
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBiographyCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Biography / About Me',
          style: GoogleFonts.manrope(
            color: const Color(0xFF4D4347),
            fontSize: 19.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF5EBFF),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: const Color(0xFF9C5BE6),
                size: 12.sp,
              ),
              SizedBox(width: 4.w),
              Text(
                'GENERATED BY AI',
                style: GoogleFonts.manrope(
                  color: const Color(0xFF9C5BE6),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        TextFormField(
          controller: _biographyController,
          minLines: 4,
          maxLines: 6,
          decoration: InputDecoration(
            hintText:
                'Write a short biography about the bride/groom, their personality, and life goals...',
            hintStyle: GoogleFonts.manrope(
              color: const Color(0xFF7F7277),
              fontSize: 16.sp,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: EdgeInsets.all(14.r),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: Color(0xFFF0DDE4)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: Color(0xFFF0DDE4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: AppColors.rmPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalFormSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 12.w;
        final fieldWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: 14.h,
          children: [
            SizedBox(
              width: fieldWidth,
              child: _buildProfileDropdownField(
                label: 'Profile Category',
                required: true,
                value: _selectedProfileCategory,
                hint: 'Select category',
                items: const ['Other', 'Bride', 'Groom'],
                onChanged: (value) {
                  setState(() => _selectedProfileCategory = value);
                },
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _buildProfileTextField(
                controller: _fullNameController,
                label: 'Full Name',
                required: true,
                hint: 'Enter full name',
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _buildProfileDropdownField(
                label: 'Gender',
                required: true,
                value: _selectedGender,
                hint: 'Select Gender',
                items: const ['Female', 'Male', 'Other'],
                onChanged: (value) {
                  setState(() => _selectedGender = value);
                },
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _buildProfileDropdownField(
                label: 'Marital Status',
                required: true,
                value: _selectedMaritalStatus,
                hint: 'Select marital status',
                items: const [
                  'Never Married',
                  'Divorced',
                  'Widowed',
                  'Awaiting Divorce',
                ],
                onChanged: (value) {
                  setState(() => _selectedMaritalStatus = value);
                },
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _buildProfileTextField(
                controller: _religionController,
                label: 'Religion',
                hint: 'e.g. Hindu, Jain, Sikh',
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _buildProfileDropdownField(
                label: 'Expected Budget\nRange',
                value: _selectedBudgetRange,
                hint: 'Select Expected Budget',
                items: const [
                  '0 - 5 Lakh',
                  '5 - 10 Lakh',
                  '10 - 20 Lakh',
                  '20+ Lakh',
                ],
                onChanged: (value) {
                  setState(() => _selectedBudgetRange = value);
                },
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _buildProfileTextField(
                controller: _dateOfBirthController,
                label: 'Date Of Birth',
                required: true,
                hint: 'mm/dd/yyyy',
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _buildProfileTextField(
                controller: _timeOfBirthController,
                label: 'Time of Birth',
                hint: '--:--',
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _buildProfileTextField(
                controller: _birthPlaceController,
                label: 'Birth Place',
                hint: 'Enter birth place / native',
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _buildProfileTextField(
                controller: _currentResidentialController,
                label: 'Current Residential',
                hint: 'Enter current city',
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _buildProfileDropdownField(
                label: 'Country',
                value: _selectedCountry,
                hint: 'Select Country',
                items: const ['India', 'UAE', 'USA', 'Canada'],
                onChanged: (value) {
                  setState(() => _selectedCountry = value);
                },
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _buildProfileDropdownField(
                label: 'State',
                value: _selectedState,
                hint: 'Select State',
                items: const ['Rajasthan', 'Gujarat', 'Maharashtra', 'Delhi'],
                onChanged: (value) {
                  setState(() => _selectedState = value);
                },
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _buildProfileTextField(
                controller: _heightController,
                label: 'Height (Cms)',
                required: true,
                hint: '0',
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _buildProfileDropdownField(
                label: 'Gotra',
                value: _selectedGotra,
                hint: 'Select or type Gotra',
                items: const ['Bharadwaj', 'Garg', 'Kaushik', 'Vashishtha'],
                onChanged: (value) {
                  setState(() => _selectedGotra = value);
                },
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _buildProfileDropdownField(
                label: 'Complexion',
                value: _selectedComplexion,
                hint: 'Select complexion',
                items: const ['Fair', 'Wheatish', 'Dusky'],
                onChanged: (value) {
                  setState(() => _selectedComplexion = value);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildComingSoonCard({
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF0DDE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              color: AppColors.rmPrimary,
              fontSize: 23.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            style: GoogleFonts.manrope(
              color: const Color(0xFF7E7479),
              fontSize: 15.sp,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required Color foregroundColor,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return SizedBox(
      height: 44.h,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15.sp),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDropdownField({
    required String label,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? value,
    String? hint,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileFieldLabel(label, required: required),
        SizedBox(height: 6.h),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: const Color(0xFF8E7E84),
            size: 20.sp,
          ),
          decoration: _profileFieldDecoration(hint: hint),
          style: GoogleFonts.manrope(
            color: const Color(0xFF5B5054),
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
          hint: hint == null
              ? null
              : Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF9A8C91),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildProfileTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileFieldLabel(label, required: required),
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: _profileFieldDecoration(hint: hint),
          style: GoogleFonts.manrope(
            color: const Color(0xFF5B5054),
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileFieldLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: GoogleFonts.manrope(
          color: const Color(0xFF40373B),
          fontSize: 15.sp,
          fontWeight: FontWeight.w700,
        ),
        children: required
            ? [
                TextSpan(
                  text: ' *',
                  style: GoogleFonts.manrope(
                    color: const Color(0xFFD54C66),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ]
            : const [],
      ),
    );
  }

  InputDecoration _profileFieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.manrope(
        color: const Color(0xFF9A8C91),
        fontSize: 15.sp,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: AppColors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: Color(0xFFE9D3DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: Color(0xFFE9D3DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: AppColors.rmPrimary),
      ),
    );
  }

  Widget _buildMiniBadge({
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          color: textColor,
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildClientMetaItem({required IconData icon, required String label}) {
    return SizedBox(
      width: 122.w,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF5F8D77), size: 14.sp),
          SizedBox(width: 5.w),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: const Color(0xFF5F6E66),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntrySection() {
    final isCreating = context.watch<RegistryProfilesProvider>().isCreating;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFF0DDE4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D323247),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manual Profile Details',
            style: GoogleFonts.manrope(
              color: AppColors.rmPrimary,
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Use this when you want to digitize the profile directly without importing a resume PDF.',
            style: GoogleFonts.manrope(
              color: const Color(0xFF7D7075),
              fontSize: 15.sp,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 18.h),
          _buildTextField(controller: _fullNameController, label: 'Full Name'),
          SizedBox(height: 12.h),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 12.h),
          _buildDropdown(
            label: 'Package Type',
            options: const ['Standard', 'Premium', 'Elite'],
          ),
          SizedBox(height: 18.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: isCreating ? null : _handleCommit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rmPrimary,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                isCreating ? 'Creating...' : 'Commit Digitization',
                style: GoogleFonts.manrope(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required String label,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
    IconData? icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: borderColor),
      ),
      child: Wrap(
        spacing: 6.w,
        runSpacing: 4.h,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (icon != null) Icon(icon, color: textColor, size: 16.sp),
          Text(
            label,
            style: GoogleFonts.manrope(
              color: textColor,
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) {
        if (!_isManualEntryEnabled && widget.customer != null) {
          return null;
        }

        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }

        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.manrope(
          color: AppColors.rmMutedText,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: const Color(0xFFFFFCFD),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.rmPaleRoseBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.rmPaleRoseBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.rmPrimary),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<String> options,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedPackageType,
      validator: (value) {
        if (!_isManualEntryEnabled && widget.customer != null) {
          return null;
        }

        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }

        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.manrope(
          color: AppColors.rmMutedText,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: const Color(0xFFFFFCFD),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.rmPaleRoseBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.rmPaleRoseBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.rmPrimary),
        ),
      ),
      items: options
          .map(
            (option) =>
                DropdownMenuItem<String>(value: option, child: Text(option)),
          )
          .toList(),
      onChanged: (value) => setState(() => _selectedPackageType = value),
    );
  }

  Widget _buildDashedCard({required Widget child, VoidCallback? onTap}) {
    final radius = 18.r;

    return CustomPaint(
      painter: _DashedCardPainter(
        color: const Color(0xFFE9C7D2),
        strokeWidth: 1.2,
        radius: radius,
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.transparent,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  void _handleDiscard() {
    setState(() {
      _fullNameController.text = widget.customer?.name ?? '';
      _phoneController.text = widget.customer?.phone == '-'
          ? ''
          : widget.customer?.phone ?? '';
      _biographyController.clear();
      _religionController.clear();
      _dateOfBirthController.clear();
      _timeOfBirthController.clear();
      _birthPlaceController.clear();
      _currentResidentialController.clear();
      _heightController.text = '0';
      _selectedPackageType = _normalizePackageType(
        widget.customer?.packageType,
      );
      _selectedProfileCategory = 'Other';
      _selectedGender = null;
      _selectedMaritalStatus = 'Never Married';
      _selectedBudgetRange = null;
      _selectedCountry = 'India';
      _selectedState = null;
      _selectedGotra = null;
      _selectedComplexion = 'Fair';
      _resumePdfPath = null;
      _resumePdfName = null;
      _photoPaths.clear();
    });

    _showNotice('Unsaved profile changes discarded.');
  }

  void _handleSaveDraft() {
    _showNotice('Profile draft saved locally.');
  }

  Future<void> _handleCommit() async {
    final hasLinkedClient = widget.customer != null;

    if (!hasLinkedClient && !_isManualEntryEnabled) {
      _showNotice('Select a client or use manual entry first.');
      return;
    }

    if ((_isManualEntryEnabled || !hasLinkedClient) &&
        !_formKey.currentState!.validate()) {
      return;
    }

    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    final registryProvider = context.read<RegistryProfilesProvider>();
    final success = await registryProvider.createProfile(
      accessToken: accessToken,
      payload: _buildCreateProfilePayload(),
      resumePdf: _resumePdfPath == null ? null : File(_resumePdfPath!),
      photos: _photoPaths.map(File.new).toList(),
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showNotice(registryProvider.createError ?? 'Unable to add profile.');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile added for $_linkedClientName.',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.rmPrimary,
      ),
    );

    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) {
        return;
      }

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return;
      }

      Navigator.of(context).pushReplacementNamed(AppRoutes.profileDigitizer);
    });
  }

  Map<String, dynamic> _buildCreateProfilePayload() {
    return _withoutEmptyValues({
      'customerId': widget.customer?.id,
      'name': _fullNameController.text.trim(),
      'gender': _enumValue(_selectedGender),
      'category': _enumValue(_selectedProfileCategory),
      'maritalStatus': _enumValue(_selectedMaritalStatus),
      'religion': _religionController.text.trim(),
      'dateOfBirth': _dateOfBirthValue(),
      'birthTime': _timeOfBirthController.text.trim(),
      'birthPlace': _birthPlaceController.text.trim(),
      'currentResidential': _currentResidentialController.text.trim(),
      'state': _selectedState,
      'country': _selectedCountry,
      'height': int.tryParse(_heightController.text.trim()),
      'gotra': _selectedGotra,
      'complexion': _enumValue(_selectedComplexion),
      'expectedBudget': _budgetValue(_selectedBudgetRange),
      'aboutMe': _biographyController.text.trim(),
      'status': 'ACTIVE',
    });
  }

  Map<String, dynamic> _withoutEmptyValues(Map<String, dynamic> values) {
    return Map.fromEntries(
      values.entries.where((entry) {
        final value = entry.value;
        if (value == null) {
          return false;
        }
        if (value is String) {
          return value.trim().isNotEmpty;
        }
        return true;
      }),
    );
  }

  String? _enumValue(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return null;
    }

    return text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), '_');
  }

  String? _budgetValue(String? value) {
    switch (value) {
      case '0 - 5 Lakh':
        return '0_5_LAKH';
      case '5 - 10 Lakh':
        return '5_10_LAKH';
      case '10 - 20 Lakh':
        return '10_20_LAKH';
      case '20+ Lakh':
        return '20_LAKH_PLUS';
      default:
        return null;
    }
  }

  String? _dateOfBirthValue() {
    final text = _dateOfBirthController.text.trim();
    if (text.isEmpty) {
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

    return text;
  }

  Future<void> _pickResumePdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        allowMultiple: false,
        withData: false,
      );
      if (result == null || result.files.isEmpty || !mounted) {
        return;
      }

      final file = result.files.single;
      final path = file.path;
      if (path == null || path.isEmpty) {
        _showNotice('Unable to read selected PDF path.');
        return;
      }

      setState(() {
        _resumePdfPath = path;
        _resumePdfName = file.name;
        _isManualEntryEnabled = true;
      });
      _showNotice('Resume PDF selected.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showNotice('Unable to open PDF picker.');
    }
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

      setState(() => _photoPaths.add(image.path));
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showNotice('Unable to open gallery.');
    }
  }

  void _removePhoto(int index) {
    if (index < 0 || index >= _photoPaths.length) {
      return;
    }
    setState(() => _photoPaths.removeAt(index));
  }

  void _showNotice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  String? _normalizePackageType(String? packageType) {
    if (packageType == null ||
        packageType.trim().isEmpty ||
        packageType == '-') {
      return null;
    }

    final normalized = packageType.trim().toLowerCase();

    switch (normalized) {
      case 'standard':
        return 'Standard';
      case 'premium':
        return 'Premium';
      case 'elite':
        return 'Elite';
      default:
        return null;
    }
  }
}

class _PickedProfilePhoto extends StatelessWidget {
  const _PickedProfilePhoto({
    required this.path,
    required this.onRemove,
    this.size,
  });

  final String path;
  final VoidCallback onRemove;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? 84.w;

    return SizedBox(
      width: dimension,
      height: dimension,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return Container(
                    color: const Color(0xFFF6EDF1),
                    child: Icon(
                      Icons.person,
                      color: AppColors.rmPrimary,
                      size: 28.sp,
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 4.r,
            right: 4.r,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(999.r),
              child: Container(
                width: 22.r,
                height: 22.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.rmPrimary,
                  size: 14.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedCardPainter extends CustomPainter {
  const _DashedCardPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    const dashWidth = 7.0;
    const dashSpace = 5.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, nextDistance), paint);
        distance = nextDistance + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCardPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}
