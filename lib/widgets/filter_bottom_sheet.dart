import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/owner/providers/registry_profiles_provider.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String _selectedCategory = 'All';
  RangeValues _ageRange = const RangeValues(25, 35);
  String _selectedCommunity = 'Any Community';
  final List<String> _selectedLocations = ['Mumbai', 'London'];
  int _selectedSkinToneIndex = 0;
  String _selectedGotra = 'All Gotras';
  String _selectedProfession = 'All Professions';
  String _selectedStatus = 'All Status';
  bool _isApplying = false;

  final Color _primaryColor = AppColors.primary;
  final Color _backgroundColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final bottomSystemInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 8.h,
        left: 20.w,
        right: 20.w,
        bottom: 24.h + bottomSystemInset,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFCAC4D0),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: GoogleFonts.inter(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: _primaryColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'All';
                    _ageRange = const RangeValues(25, 35);
                    _selectedCommunity = 'Any Community';
                    _selectedLocations
                      ..clear()
                      ..addAll(['Mumbai', 'London']);
                    _selectedSkinToneIndex = 0;
                    _selectedGotra = 'All Gotras';
                    _selectedProfession = 'All Professions';
                    _selectedStatus = 'All Status';
                  });
                },
                child: Text(
                  'RESET',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF727782),
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
          SizedBox(height: 16.h),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  // Category
                  _buildSectionTitle('CATEGORY'),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      _buildCategoryChip('All'),
                      SizedBox(width: 8.w),
                      _buildCategoryChip('Premium'),
                      SizedBox(width: 8.w),
                      _buildEliteChip(),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // Age Range
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('AGE RANGE'),
                      Text(
                        '${_ageRange.start.round()} - ${_ageRange.end.round()} Yrs',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _ageRange,
                    min: 18,
                    max: 60,
                    divisions: 42,
                    activeColor: _primaryColor,
                    inactiveColor: const Color(0xFFE7EAF0),
                    onChanged: (values) {
                      setState(() {
                        _ageRange = values;
                      });
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '18',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Color(0xFF1E1F1F),
                          ),
                        ),
                        Text(
                          '60+',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Color(0xFF1E1F1F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Communities
                  _buildSectionTitle('COMMUNITIES'),
                  SizedBox(height: 12.h),
                  _buildDropdown(
                    _selectedCommunity,
                    (val) {
                      setState(() => _selectedCommunity = val!);
                    },
                    [
                      'Any Community',
                      'Agrawal',
                      'Hindu',
                      'Muslim',
                      'Sikh',
                      'Christian',
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // City / Location
                  _buildSectionTitle('CITY / LOCATION'),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFCAC4D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF727782),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search cities...',
                              hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF727782),
                                fontSize: 14.sp,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 8.w,
                    children: _selectedLocations
                        .map(
                          (loc) => Chip(
                            label: Text(loc, style: TextStyle(fontSize: 12.sp)),
                            deleteIcon: Icon(Icons.close, size: 14.sp),
                            onDeleted: () {
                              setState(() {
                                _selectedLocations.remove(loc);
                              });
                            },
                            backgroundColor: const Color(0xFFFDECF3),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 24.h),

                  // Skin Tone
                  _buildSectionTitle('SKIN TONE'),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 12.h,
                    children: [
                      _buildSkinToneItem(0, const Color(0xFFF5D5E6), 'Fair'),
                      _buildSkinToneItem(
                        1,
                        const Color(0xFFF3D2B5),
                        'Wheatish',
                      ),
                      _buildSkinToneItem(2, const Color(0xFFD09C77), 'Brown'),
                      _buildSkinToneItem(3, const Color(0xFF9B6D4A), 'Dark'),
                      _buildSkinToneItem(4, Colors.white, 'Any', isAny: true),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // Gotra
                  _buildSectionTitle('GOTRA'),
                  SizedBox(height: 12.h),
                  _buildDropdown(
                    _selectedGotra,
                    (val) {
                      setState(() => _selectedGotra = val!);
                    },
                    ['All Gotras', 'Mittal', 'Kashyap', 'Bhardwaj', 'Vats'],
                  ),
                  SizedBox(height: 24.h),

                  // Profession
                  _buildSectionTitle('PROFESSION'),
                  SizedBox(height: 12.h),
                  _buildDropdown(
                    _selectedProfession,
                    (val) {
                      setState(() => _selectedProfession = val!);
                    },
                    ['All Professions', 'Engineer', 'Doctor', 'Teacher'],
                  ),
                  SizedBox(height: 24.h),

                  // Status
                  _buildSectionTitle('STATUS'),
                  SizedBox(height: 12.h),
                  _buildDropdown(_selectedStatus, (val) {
                    setState(() => _selectedStatus = val!);
                  }, ['All Status', 'Active', 'Inactive']),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),

          // Apply Filters Button
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: () async {
                if (_isApplying) {
                  return;
                }

                final token = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).userModel?.accessToken;
                if (token == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Login required to filter profiles.'),
                    ),
                  );
                  return;
                }

                setState(() => _isApplying = true);

                final category = _enumFilterValue(
                  _selectedCategory,
                  allValue: 'All',
                );
                final community = _enumFilterValue(
                  _selectedCommunity,
                  allValue: 'Any Community',
                );
                final gotra = _textFilterValue(
                  _selectedGotra,
                  allValue: 'All Gotras',
                );
                final profession = _textFilterValue(
                  _selectedProfession,
                  allValue: 'All Professions',
                );
                final status =
                    _enumFilterValue(_selectedStatus, allValue: 'All Status') ??
                    'ACTIVE';

                final filters = {
                  if (category != null) 'category': category,
                  'ageRange':
                      '${_ageRange.start.round()}-${_ageRange.end.round()}',
                  if (community != null) 'community': community,
                  if (_selectedLocations.isNotEmpty)
                    'currentResidential': _selectedLocations.join(','),
                  'birthPlace': 'Indore',
                  if (gotra != null) 'gotra': gotra,
                  if (profession != null) 'profession': profession,
                  'status': status,
                  'budget': '10',
                };
                final filterUri = Uri.parse(
                  '${ApiConstants.baseUrl}${ApiConstants.profiles}',
                ).replace(queryParameters: filters);
                debugPrint('Filters API: GET $filterUri');

                final applied = await context
                    .read<RegistryProfilesProvider>()
                    .filterProfiles(accessToken: token, filters: filters);

                if (!mounted) {
                  return;
                }

                setState(() => _isApplying = false);

                if (applied) {
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unable to apply filters.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isApplying)
                    SizedBox(
                      width: 20.sp,
                      height: 20.sp,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  else ...[
                    Text(
                      'Apply Filters',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.tune, color: Colors.white, size: 20.sp),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF49454F),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final bool isSelected = _selectedCategory == label;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        height: 40.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? _primaryColor : const Color(0xFFCAC4D0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF49454F),
          ),
        ),
      ),
    );
  }

  Widget _buildEliteChip() {
    bool isSelected = _selectedCategory == 'Elite';
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = 'Elite'),
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? _primaryColor : const Color(0xFFCAC4D0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle,
              color: isSelected ? Colors.white : const Color(0xFFB8860B),
              size: 16.sp,
            ),
            SizedBox(width: 4.w),
            Text(
              'Elite',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFFB8860B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkinToneItem(
    int index,
    Color color,
    String label, {
    bool isAny = false,
  }) {
    bool isSelected = _selectedSkinToneIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedSkinToneIndex = index),
      child: Column(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? _primaryColor : const Color(0xFFCAC4D0),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    size: 22.sp,
                    color: isAny ? _primaryColor : Colors.white,
                  )
                : null,
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? _primaryColor : const Color(0xFF49454F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String value,
    ValueChanged<String?> onChanged,
    List<String> items,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFCAC4D0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: GoogleFonts.inter(fontSize: 14.sp)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  String? _enumFilterValue(String value, {required String allValue}) {
    final textValue = _textFilterValue(value, allValue: allValue);
    return textValue?.toUpperCase();
  }

  String? _textFilterValue(String value, {required String allValue}) {
    if (value == allValue) {
      return null;
    }

    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}
