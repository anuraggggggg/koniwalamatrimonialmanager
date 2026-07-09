import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/owner/providers/customer_registry_provider.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:provider/provider.dart';
import '../models/customer_registry_item.dart';
import '../providers/dashboard_provider.dart';

class ProfileDigitizerScreen extends StatefulWidget {
  const ProfileDigitizerScreen({
    super.key,
    this.embeddedInDashboard = false,
  });

  final bool embeddedInDashboard;

  @override
  State<ProfileDigitizerScreen> createState() => _ProfileDigitizerScreenState();
}

class _ProfileDigitizerScreenState extends State<ProfileDigitizerScreen> {
  bool _hasRequestedCustomers = false;
  String? _requestedAccessToken;
  String? _selectedCustomerId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authProvider = Provider.of<AuthProvider>(context);
    final accessToken = authProvider.userModel?.accessToken;

    if (!authProvider.isInitialized ||
        (_hasRequestedCustomers && accessToken == _requestedAccessToken)) {
      return;
    }

    _hasRequestedCustomers = true;
    _requestedAccessToken = accessToken;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<CustomerRegistryProvider>().fetchCustomers(accessToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    final customerRegistry = context.watch<CustomerRegistryProvider>();
    final customers = customerRegistry.customers;
    final dropdownValue = customers.any(
      (customer) => customer.id == _selectedCustomerId,
    )
        ? _selectedCustomerId
        : null;

    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.rmSoftPink,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -40.h,
              left: -30.w,
              child: Container(
                width: 160.w,
                height: 160.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
            Positioned(
              right: -56.w,
              bottom: 70.h,
              child: Container(
                width: 170.w,
                height: 170.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFE7EE).withValues(alpha: 0.8),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
                child: Column(
                  children: [
                    _buildTopBar(context),
                    SizedBox(height: 56.h),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 360.w),
                        child: _buildDigitizerCard(
                          context,
                          customers: customers,
                          dropdownValue: dropdownValue,
                          registry: customerRegistry,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34.r,
          height: 34.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.rmPaleRoseBorder),
          ),
          child: Icon(
            Icons.lock_outline_rounded,
            color: AppColors.rmPrimary,
            size: 18.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            'Digital Atelier',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: AppColors.rmPrimary,
              fontSize: 25.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        PopupMenuButton<_DigitizerMenuAction>(
          icon: Icon(
            Icons.more_vert_rounded,
            color: AppColors.rmHeading,
            size: 22.sp,
          ),
          onSelected: (action) {
            if (action == _DigitizerMenuAction.refresh) {
              context.read<CustomerRegistryProvider>().retry();
              return;
            }

            _returnToDashboard(context);
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _DigitizerMenuAction.refresh,
              child: Text(
                'Refresh Clients',
                style: GoogleFonts.manrope(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            PopupMenuItem(
              value: _DigitizerMenuAction.dashboard,
              child: Text(
                'Back to Dashboard',
                style: GoogleFonts.manrope(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDigitizerCard(
    BuildContext context, {
    required List<CustomerRegistryItem> customers,
    required String? dropdownValue,
    required CustomerRegistryProvider registry,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 18.h),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F323247),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 68.r,
            height: 68.r,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFF1F4),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              color: AppColors.rmPrimary,
              size: 30.sp,
            ),
          ),
          SizedBox(height: 22.h),
          Text(
            'Select a Client to Start',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: AppColors.rmPrimary,
              fontSize: 23.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Profile digitization requires an active client link. Please select a converted client from the list below.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: AppColors.rmBodyText,
              fontSize: 15.sp,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 26.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'AVAILABLE CONVERTED CLIENTS',
              style: GoogleFonts.manrope(
                color: AppColors.rmBodyText,
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          DropdownButtonFormField<String>(
            value: dropdownValue,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.rmPrimary,
              size: 22.sp,
            ),
            menuMaxHeight: 320.h,
            hint: Text(
              registry.isLoading ? 'Loading clients...' : 'Choose a client...',
              style: GoogleFonts.manrope(
                color: AppColors.rmMutedText,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 16.h,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.rmPinkBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.rmPrimary),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.rmPinkBorder),
              ),
            ),
            style: GoogleFonts.manrope(
              color: AppColors.rmHeading,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
            items: customers
                .map(
                  (customer) => DropdownMenuItem<String>(
                    value: customer.id,
                    child: Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: registry.isLoading || customers.isEmpty
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }

                    final selectedCustomer = customers.firstWhere(
                      (customer) => customer.id == value,
                    );

                    setState(() => _selectedCustomerId = value);
                    Navigator.of(context).pushNamed(
                      AppRoutes.newProfileDigitization,
                      arguments: selectedCustomer,
                    );
                  },
          ),
          _buildRegistryFeedback(registry, customers),
          SizedBox(height: 22.h),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: AppColors.rmPaleRoseBorder,
                  thickness: 1,
                  endIndent: 10.w,
                ),
              ),
              Text(
                'OR RETURN TO TASKS',
                style: GoogleFonts.manrope(
                  color: AppColors.rmHintText,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              Expanded(
                child: Divider(
                  color: AppColors.rmPaleRoseBorder,
                  thickness: 1,
                  indent: 10.w,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: OutlinedButton.icon(
              onPressed: () => _returnToDashboard(context),
              icon: Icon(Icons.arrow_back_rounded, size: 18.sp),
              label: Text(
                'Back to Dashboard',
                style: GoogleFonts.manrope(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rmPrimary,
                backgroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.rmPrimary, width: 1.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'SECURITY PROTOCOL | CRM CORE',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: const Color(0xFFCCB2BC),
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistryFeedback(
    CustomerRegistryProvider registry,
    List<CustomerRegistryItem> customers,
  ) {
    if (registry.isLoading) {
      return Padding(
        padding: EdgeInsets.only(top: 12.h),
        child: Row(
          children: [
            SizedBox(
              width: 16.r,
              height: 16.r,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Loading converted clients for digitization.',
                style: GoogleFonts.manrope(
                  color: AppColors.rmMutedText,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (registry.error != null) {
      return Padding(
        padding: EdgeInsets.only(top: 12.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                registry.error!,
                style: GoogleFonts.manrope(
                  color: AppColors.error,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                registry.retry();
              },
              child: Text(
                'Retry',
                style: GoogleFonts.manrope(
                  color: AppColors.rmPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (customers.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 12.h),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
                'No converted clients available yet.',
                style: GoogleFonts.manrope(
                  color: AppColors.rmMutedText,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _returnToDashboard(BuildContext context) {
    context.read<DashboardProvider>().reset();

    if (widget.embeddedInDashboard) {
      return;
    }

    Navigator.of(context).popUntil(
      (route) => route.settings.name == AppRoutes.ownerDashboard || route.isFirst,
    );
  }
}

enum _DigitizerMenuAction { refresh, dashboard }
