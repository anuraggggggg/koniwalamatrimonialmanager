import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/owner/providers/leads_provider.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class NewInquiryScreen extends StatefulWidget {
  const NewInquiryScreen({super.key});

  @override
  State<NewInquiryScreen> createState() => _NewInquiryScreenState();
}

class _NewInquiryScreenState extends State<NewInquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();
  String _source = 'Website';
  String _leadFor = 'Select designated principal';
  String? _assignedManagerId;
  bool _hasFetchedManagers = false;

  static const List<String> _sources = [
    'Website',
    'Referral',
    'Walk In',
    'Instagram',
    'Facebook',
    'Phone Call',
    'Event',
  ];

  static const List<String> _leadForOptions = [
    'Select designated principal',
    'Bride',
    'Groom',
    'Family',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasFetchedManagers) {
      _hasFetchedManagers = true;
      final accessToken = context.read<AuthProvider>().userModel?.accessToken;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<LeadsProvider>().fetchManagers(accessToken);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final managers = context.watch<LeadsProvider>().managers;

    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 430.w,
              maxHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.vertical -
                  20.h,
            ),
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 22.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _InquiryHeader(),
                            SizedBox(height: 28.h),
                            _InquirySection(
                              title: 'Lead Identity & Contact',
                              children: [
                                _InquiryTextField(
                                  label: 'Full Name',
                                  isRequired: true,
                                  hintText: 'e.g. Aditi Sharma',
                                  icon: Icons.person_outline,
                                  controller: _nameController,
                                  validator: _requiredValidator,
                                  textInputAction: TextInputAction.next,
                                ),
                                _InquiryTextField(
                                  label: 'Mobile Number',
                                  isRequired: true,
                                  hintText: '+1 (555) 000-0000',
                                  icon: Icons.phone_iphone,
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9+\-() ]'),
                                    ),
                                  ],
                                  validator: _phoneValidator,
                                  textInputAction: TextInputAction.next,
                                ),
                                _InquiryTextField(
                                  label: 'Email Address',
                                  hintText: 'contact@example.com',
                                  icon: Icons.email_outlined,
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _emailValidator,
                                  textInputAction: TextInputAction.next,
                                ),
                              ],
                            ),
                            SizedBox(height: 26.h),
                            _InquirySection(
                              title: 'Lead Metadata',
                              children: [
                                _InquiryDropdownField(
                                  label: 'Source',
                                  isRequired: true,
                                  value: _source,
                                  items: _sources,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _source = value);
                                    }
                                  },
                                ),
                                _InquiryTextField(
                                  label: 'City',
                                  hintText: 'Current primary residence',
                                  icon: Icons.location_city_outlined,
                                  controller: _cityController,
                                  textInputAction: TextInputAction.next,
                                ),
                              ],
                            ),
                            SizedBox(height: 22.h),
                            _InquiryDropdownField(
                              label: 'Lead For',
                              isRequired: true,
                              value: _leadFor,
                              items: _leadForOptions,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _leadFor = value);
                                }
                              },
                            ),
                            SizedBox(height: 18.h),
                            _InquiryDropdownField(
                              label: 'Assign To Relationship Manager',
                              value: _assignedManagerId,
                              hintText: 'Select relationship manager',
                              dropdownItems: managers
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m.id,
                                      child: Text(
                                        m.displayLabel,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() => _assignedManagerId = value);
                              },
                            ),
                            SizedBox(height: 18.h),
                            _InquiryTextField(
                              label: 'Lead Notes',
                              hintText:
                                  'Add context, preferences, or the inquiry summary...',
                              icon: Icons.notes_outlined,
                              controller: _notesController,
                              minLines: 4,
                              maxLines: 4,
                              textInputAction: TextInputAction.newline,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _InquiryFooter(
                      onCancel: () => Navigator.of(context).maybePop(),
                      onSubmit: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_leadFor == _leadForOptions.first) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select lead for.')));
      return;
    }

    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    final message = await context.read<LeadsProvider>().createLead(
      accessToken: accessToken,
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      source: _source,
      leadFor: _leadFor,
      city: _cityController.text,
    );

    if (!mounted) {
      return;
    }

    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inquiry registered successfully.')),
    );
    Navigator.of(context).pop(true);
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Required';
    }
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return 'Enter a valid number';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'Enter a valid email';
    }
    return null;
  }
}

class _InquiryHeader extends StatelessWidget {
  const _InquiryHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44.w,
          height: 44.w,
          child: IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.rmPrimary,
              size: 24.sp,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INSTITUTIONAL ONBOARDING',
                style: GoogleFonts.inter(
                  color: AppColors.rmPrimary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .6,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'Register New\nInquiry',
                style: GoogleFonts.inter(
                  color: const Color(0xFF202024),
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'Record a new lead into the matrimonial registry for curation and departmental assignment.',
                style: GoogleFonts.inter(
                  color: const Color(0xFF4D4548),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.close, color: const Color(0xFF8F8489), size: 22.sp),
        ),
      ],
    );
  }
}

class _InquirySection extends StatelessWidget {
  const _InquirySection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: AppColors.rmPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 9.h),
        const Divider(height: 1, color: Color(0xFFF1E8EC)),
        SizedBox(height: 18.h),
        for (final child in children) ...[
          child,
          if (child != children.last) SizedBox(height: 18.h),
        ],
      ],
    );
  }
}

class _InquiryTextField extends StatelessWidget {
  const _InquiryTextField({
    required this.label,
    required this.hintText,
    required this.icon,
    required this.controller,
    this.isRequired = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.textInputAction,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final String label;
  final String hintText;
  final IconData icon;
  final TextEditingController controller;
  final bool isRequired;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label, isRequired: isRequired),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          textInputAction: textInputAction,
          minLines: minLines,
          maxLines: maxLines,
          style: GoogleFonts.inter(
            color: const Color(0xFF2F292C),
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
          decoration: _fieldDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: const Color(0xFF9C8F95), size: 18.sp),
          ),
        ),
      ],
    );
  }
}

class _InquiryDropdownField extends StatelessWidget {
  const _InquiryDropdownField({
    required this.label,
    required this.onChanged,
    this.value,
    this.items,
    this.dropdownItems,
    this.isRequired = false,
    this.hintText,
  });

  final String label;
  final String? value;
  final List<String>? items;
  final List<DropdownMenuItem<String>>? dropdownItems;
  final ValueChanged<String?> onChanged;
  final bool isRequired;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label, isRequired: isRequired),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String?>(
          initialValue: value,
          isExpanded: true,
          hint: hintText != null
              ? Text(
                  hintText!,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFC1B8BD),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: const Color(0xFF9C8F95),
            size: 20.sp,
          ),
          decoration: _fieldDecoration(),
          style: GoogleFonts.inter(
            color: const Color(0xFF2F292C),
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
          items:
              dropdownItems ??
              items
                  ?.map(
                    (item) => DropdownMenuItem<String?>(
                      value: item,
                      child: Text(item, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.isRequired});

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: GoogleFonts.inter(
          color: const Color(0xFF302A2D),
          fontSize: 14.sp,
          fontWeight: FontWeight.w800,
        ),
        children: [
          if (isRequired)
            TextSpan(
              text: ' *',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}

class _InquiryFooter extends StatelessWidget {
  const _InquiryFooter({required this.onCancel, required this.onSubmit});

  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<LeadsProvider>().isCreatingLead;

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: Color(0xFFEFE5EA))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: SizedBox(
              height: 48.h,
              child: OutlinedButton(
                onPressed: isLoading ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.rmPrimary,
                  side: const BorderSide(color: AppColors.rmPrimary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 7,
            child: SizedBox(
              height: 48.h,
              child: ElevatedButton(
                onPressed: isLoading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rmPrimary,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.rmPrimary.withValues(
                    alpha: .55,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Register New Inquiry',
                              maxLines: 1,
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w900,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 5.w),
                          Icon(Icons.arrow_forward, size: 15.sp),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration({String? hintText, Widget? prefixIcon}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: GoogleFonts.inter(
      color: const Color(0xFFC1B8BD),
      fontSize: 16.sp,
      fontWeight: FontWeight.w700,
    ),
    prefixIcon: prefixIcon,
    prefixIconConstraints: BoxConstraints(minWidth: 40.w),
    filled: true,
    fillColor: AppColors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
    errorStyle: GoogleFonts.inter(
      color: AppColors.error,
      fontSize: 13.sp,
      fontWeight: FontWeight.w700,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7.r),
      borderSide: const BorderSide(color: Color(0xFFEFDDE4)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7.r),
      borderSide: const BorderSide(color: AppColors.rmPrimary, width: 1.2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7.r),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7.r),
      borderSide: const BorderSide(color: AppColors.error, width: 1.2),
    ),
  );
}
