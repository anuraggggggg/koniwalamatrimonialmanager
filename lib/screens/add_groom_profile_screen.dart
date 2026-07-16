import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';

class AddGroomProfileScreen extends StatefulWidget {
  const AddGroomProfileScreen({super.key});

  @override
  State<AddGroomProfileScreen> createState() => _AddGroomProfileScreenState();
}

class _AddGroomProfileScreenState extends State<AddGroomProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      appBar: AppBar(
        title: Text(
          'Add Groom Profile',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.rmPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New Profile',
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.rmPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Enter the details of the groom below.',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppColors.rmBodyText,
                ),
              ),
              SizedBox(height: 30.h),
              _buildTextField('Full Name', Icons.person_outline),
              _buildTextField(
                'Age',
                Icons.calendar_today_outlined,
                keyboardType: TextInputType.number,
              ),
              _buildTextField('Height', Icons.height),
              _buildTextField('City', Icons.location_city_outlined),
              _buildTextField('Profession', Icons.work_outline),
              _buildTextField('Community', Icons.people_outline),
              SizedBox(height: 40.h),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile Added Successfully'),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rmPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Save Profile',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: TextFormField(
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.rmHeading),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.rmMutedText),
          prefixIcon: Icon(icon, color: AppColors.rmPrimary),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: AppColors.rmBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: AppColors.rmPrimary),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}
