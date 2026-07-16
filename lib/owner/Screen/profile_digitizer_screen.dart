import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/owner/providers/customer_registry_provider.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'admin_drawer_screen.dart';
import '../models/customer_registry_item.dart';
import '../providers/dashboard_provider.dart';

class ProfileDigitizerScreen extends StatefulWidget {
  const ProfileDigitizerScreen({super.key, this.embeddedInDashboard = false});

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
    final dropdownValue =
        customers.any((customer) => customer.id == _selectedCustomerId)
        ? _selectedCustomerId
        : null;

    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      drawerScrimColor: Colors.black.withValues(alpha: 0.1),
      drawer: Drawer(
        width: MediaQuery.sizeOf(context).width * 0.68,
        backgroundColor: AppColors.rmSoftPink,
        child: AdminDrawerContent(
          onClose: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ColoredBox(
        color: const Color(0xFFFFF7F5),
        child: SafeArea(
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
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 360.w),
        child: SizedBox(
          height: 44.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 32.w,
                height: 44.h,
                child: Builder(
                  builder: (scaffoldContext) {
                    return IconButton(
                      tooltip: 'Menu',
                      onPressed: () =>
                          Scaffold.of(scaffoldContext).openDrawer(),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints.tightFor(
                        width: 32.w,
                        height: 44.h,
                      ),
                      icon: Icon(
                        Icons.menu_rounded,
                        color: const Color(0xFF1F2023),
                        size: 24.sp,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Digital Atelier',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1F2023),
                    fontSize: 21.sp,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(
                width: 32.w,
                height: 44.h,
                child: PopupMenuButton<_DigitizerMenuAction>(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 190.w, maxWidth: 230.w),
                  color: AppColors.white,
                  surfaceTintColor: AppColors.white,
                  splashRadius: 20.r,
                  child: SizedBox.expand(
                    child: Center(
                      child: Icon(
                        Icons.more_vert_rounded,
                        color: const Color(0xFF594247),
                        size: 22.sp,
                      ),
                    ),
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
                        style: GoogleFonts.inter(
                          color: AppColors.titleColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: _DigitizerMenuAction.dashboard,
                      child: Text(
                        'Back to Dashboard',
                        style: GoogleFonts.inter(
                          color: AppColors.titleColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          Container(
            width: 64.r,
            height: 64.r,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFE5D8),
            ),
            child: Icon(
              Icons.lock_person_outlined,
              color: AppColors.rmPrimary,
              size: 32.sp,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Select Client to Start',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF1F2023),
              fontSize: 27.sp,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          SizedBox(height: 14.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              'Profile digitization requires an active client link. Please select a converted client from the list below.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF2E3033),
                fontSize: 16.sp,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 34.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'AVAILABLE CONVERTED CLIENTS',
              style: GoogleFonts.inter(
                color: const Color(0xFF24262A),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          DropdownButtonFormField<String>(
            initialValue: dropdownValue,
            isExpanded: true,
            dropdownColor: AppColors.white,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: const Color(0xFF1F2023),
              size: 22.sp,
            ),
            menuMaxHeight: 320.h,
            hint: Text(
              registry.isLoading ? 'Loading clients...' : 'Choose a client...',
              style: GoogleFonts.inter(
                color: const Color(0xFF2E3033),
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 15.w,
                vertical: 14.h,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7.r),
                borderSide: const BorderSide(color: Color(0xFFD1C9C7)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7.r),
                borderSide: const BorderSide(color: AppColors.rmPrimary),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7.r),
                borderSide: const BorderSide(color: Color(0xFFD1C9C7)),
              ),
            ),
            style: GoogleFonts.inter(
              color: AppColors.titleColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            selectedItemBuilder: (context) {
              return customers
                  .map(
                    (customer) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        customer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppColors.titleColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList();
            },
            items: customers
                .map(
                  (customer) => DropdownMenuItem<String>(
                    value: customer.id,
                    child: Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.titleColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
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
          SizedBox(height: 36.h),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: const Color(0xFFF2D7CB),
                  thickness: 1,
                  endIndent: 14.w,
                ),
              ),
              Text(
                'OR RETURN TO TASKS',
                style: GoogleFonts.inter(
                  color: const Color(0xFF3D3F43),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.7,
                ),
              ),
              Expanded(
                child: Divider(
                  color: const Color(0xFFF2D7CB),
                  thickness: 1,
                  indent: 14.w,
                ),
              ),
            ],
          ),
          SizedBox(height: 32.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: OutlinedButton.icon(
              onPressed: () => _returnToDashboard(context),
              icon: Icon(Icons.arrow_back_rounded, size: 18.sp),
              label: Text(
                'Back to Dashboard',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rmPrimary,
                backgroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.rmPrimary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 48.h),
          Text(
            'SECURITY PROTOCOL | CRM CORE',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF3D3F43),
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.6,
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
                style: GoogleFonts.inter(
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
                style: GoogleFonts.inter(
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
                style: GoogleFonts.inter(
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
            style: GoogleFonts.inter(
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
      (route) =>
          route.settings.name == AppRoutes.ownerDashboard || route.isFirst,
    );
  }
}

enum _DigitizerMenuAction { refresh, dashboard }
