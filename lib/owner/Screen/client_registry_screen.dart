import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/owner/models/customer_registry_item.dart';
import 'package:koniwalamatrimonial/owner/providers/customer_registry_provider.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:provider/provider.dart';

enum _ClientRegistryAction { viewLedger, delete }

class ClientRegistryScreen extends StatefulWidget {
  const ClientRegistryScreen({super.key, this.onMenuPressed});

  final VoidCallback? onMenuPressed;

  @override
  State<ClientRegistryScreen> createState() => _ClientRegistryScreenState();
}

class _ClientRegistryScreenState extends State<ClientRegistryScreen> {
  int _selectedFilter = 0;
  String _searchQuery = '';
  bool _hasRequestedCustomers = false;
  String? _requestedAccessToken;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_RegistryMetric> _metrics(List<CustomerRegistryItem> customers) => [
    _RegistryMetric(
      label: 'Total Clients',
      value: '${customers.length}',
      caption: 'Converted customer\nrecords',
      icon: Icons.group_outlined,
      accent: const Color(0xFF8A003C),
    ),
    _RegistryMetric(
      label: 'Active Profiles',
      value: '${_activeProfilesCount(customers)}',
      caption: 'Digitized matrimonial\nentries',
      icon: Icons.group_add_outlined,
      accent: const Color(0xFF338AF3),
    ),
    _RegistryMetric(
      label: 'Assigned RM',
      value: '${_assignedRmCount(customers)}',
      caption: 'Clients with active\nownership',
      icon: Icons.badge_outlined,
      accent: const Color(0xFF18A957),
    ),
    _RegistryMetric(
      label: 'Priority Registry',
      value: '${_premiumCustomersCount(customers)}',
      caption: 'Premium and elite\nentries',
      icon: Icons.star_border_rounded,
      accent: const Color(0xFFE3A300),
    ),
  ];

  List<_RegistryFilter> _registryFilters(
    List<CustomerRegistryItem> customers,
  ) => [
    _RegistryFilter(
      label: 'All Clients',
      count: customers.length,
      selected: _selectedFilter == 0,
    ),
    _RegistryFilter(
      label: 'Standard Registry',
      count: customers
          .where((customer) => customer.packageType.toUpperCase() == 'STANDARD')
          .length,
      selected: _selectedFilter == 1,
    ),
    _RegistryFilter(
      label: 'Priority Registry',
      count: _premiumCustomersCount(customers),
      selected: _selectedFilter == 2,
    ),
  ];

  List<CustomerRegistryItem> _visibleCustomers(
    List<CustomerRegistryItem> customers,
  ) {
    var filtered = customers;

    if (_selectedFilter == 1) {
      filtered = filtered
          .where((customer) => customer.packageType.toUpperCase() == 'STANDARD')
          .toList();
    } else if (_selectedFilter == 2) {
      filtered = filtered.where((customer) => customer.isPremium).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((customer) =>
          customer.name.toLowerCase().contains(query) ||
          customer.phone.contains(query) ||
          customer.email.toLowerCase().contains(query)).toList();
    }

    return filtered;
  }

  int _activeProfilesCount(List<CustomerRegistryItem> customers) {
    return customers.fold(
      0,
      (total, customer) => total + customer.activeProfilesCount,
    );
  }

  int _assignedRmCount(List<CustomerRegistryItem> customers) {
    return customers.where((customer) => customer.assignedRmName != '-').length;
  }

  int _premiumCustomersCount(List<CustomerRegistryItem> customers) {
    return customers.where((customer) => customer.isPremium).length;
  }

  Future<void> _showClientActions(CustomerRegistryItem customer) async {
    final action = await showModalBottomSheet<_ClientRegistryAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ClientActionSheet(
          customer: customer,
          onSelected: (selectedAction) {
            Navigator.of(sheetContext).pop(selectedAction);
          },
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _ClientRegistryAction.viewLedger:
        _showClientDetailsDialog(customer);
        break;
      case _ClientRegistryAction.delete:
        await _handleDeleteClient(customer);
        break;
    }
  }

  void _showClientDetailsDialog(CustomerRegistryItem customer) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Client Details',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Name', value: customer.name),
                _DetailRow(label: 'Phone', value: customer.phone),
                _DetailRow(label: 'Email', value: customer.email),
                _DetailRow(label: 'Package', value: customer.packageType),
                _DetailRow(label: 'Assigned RM', value: customer.assignedRmName),
                _DetailRow(label: 'Created', value: customer.createdOn),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Close', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDeleteClient(CustomerRegistryItem customer) async {
    final confirmed = await _confirmDeleteClient(customer);
    if (confirmed != true || !mounted) {
      return;
    }

    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    final message = await context
        .read<CustomerRegistryProvider>()
        .deleteCustomer(customer, accessToken);

    if (!mounted) {
      return;
    }

    _showMessage(message ?? 'Client deleted successfully.');
  }

  Future<bool?> _confirmDeleteClient(CustomerRegistryItem customer) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Delete Client',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
          ),
          content: Text(
            customer.id.isNotEmpty
                ? 'Are you sure you want to delete ${customer.name}? This action cannot be undone.'
                : 'This client does not include an id yet, so the delete API cannot be called.',
            style: GoogleFonts.manrope(height: 1.45),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6F5F64),
                side: const BorderSide(color: Color(0xFFEECAD4)),
              ),
              child: Text(
                'No, Cancel',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(customer.id.isNotEmpty),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD1213E),
                foregroundColor: Colors.white,
              ),
              child: Text(
                customer.id.isNotEmpty ? 'Yes, Delete' : 'Close',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

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
    final registryProvider = context.watch<CustomerRegistryProvider>();
    final customers = registryProvider.customers;
    final metrics = _metrics(customers);
    final filters = _registryFilters(customers);
    final visibleCustomers = _visibleCustomers(customers);

    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.onMenuPressed != null) ...[
                    IconButton(
                      onPressed: widget.onMenuPressed,
                      icon: Icon(
                        Icons.menu,
                        color: AppColors.rmPrimary,
                        size: 28.sp,
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Expanded(
                    child: Text(
                      'Client Registry',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: AppColors.rmPrimary,
                        fontSize: 40.sp,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                'Track converted clients and inherited RM\nownership from a single registry.',
                style: GoogleFonts.manrope(
                  color: const Color(0xFF6F6267),
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.28,
                ),
              ),
              SizedBox(height: 14.h),
              _RefreshRegistryButton(
                onPressed: () =>
                    context.read<CustomerRegistryProvider>().retry(),
              ),
              SizedBox(height: 18.h),
              GridView.builder(
                itemCount: metrics.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 1.14,
                ),
                itemBuilder: (context, index) =>
                    _MetricCard(metric: metrics[index]),
              ),
              SizedBox(height: 18.h),
              _RegistryFilterRow(
                filters: filters,
                onSelected: (index) => setState(() => _selectedFilter = index),
              ),
              SizedBox(height: 14.h),
              _RegistryToolsRow(
                controller: _searchController,
                onSearchChanged: (value) => setState(() => _searchQuery = value),
              ),
              SizedBox(height: 10.h),
              _RegistryListContent(
                isLoading: registryProvider.isLoading,
                error: registryProvider.error,
                customers: visibleCustomers,
                onRetry: () => context.read<CustomerRegistryProvider>().retry(),
                onClientActionsPressed: _showClientActions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RefreshRegistryButton extends StatelessWidget {
  const _RefreshRegistryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(Icons.refresh_rounded, size: 20.sp),
        label: Text(
          'Refresh Registry',
          style: GoogleFonts.manrope(
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.rmPrimary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7.r),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _RegistryMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: metric.accent.withValues(alpha: 0.28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C323247),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
              child: Text(
                metric.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  color: const Color(0xFF70656A),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              ),
              Icon(metric.icon, color: metric.accent, size: 24.sp),
              ],
              ),
              SizedBox(height: 10.h),
              Text(
              metric.value,
              style: GoogleFonts.manrope(
              color: const Color(0xFF24191D),
              fontSize: 34.sp,
              fontWeight: FontWeight.w900,
              height: 1,
              ),
              ),
          const Spacer(),
          Text(
            metric.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: metric.accent,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              height: 1.24,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistryFilterRow extends StatelessWidget {
  const _RegistryFilterRow({required this.filters, required this.onSelected});

  final List<_RegistryFilter> filters;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int index = 0; index < filters.length; index++) ...[
            _RegistryFilterChip(
              filter: filters[index],
              onTap: () => onSelected(index),
            ),
            if (index != filters.length - 1) SizedBox(width: 8.w),
          ],
        ],
      ),
    );
  }
}

class _RegistryFilterChip extends StatelessWidget {
  const _RegistryFilterChip({required this.filter, required this.onTap});

  final _RegistryFilter filter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = filter.selected
        ? AppColors.rmPrimary
        : const Color(0xFF62565B);

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          height: 44.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: filter.selected
                  ? const Color(0xFFE4AFC3)
                  : const Color(0xFFEADCE1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                filter.label,
                style: GoogleFonts.manrope(
                  color: foreground,
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                height: 24.h,
                constraints: BoxConstraints(minWidth: 24.w),
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6EEF2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '${filter.count}',
                  style: GoogleFonts.manrope(
                    color: foreground,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegistryToolsRow extends StatelessWidget {
  const _RegistryToolsRow({
    required this.controller,
    required this.onSearchChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46.h,
            padding: EdgeInsets.symmetric(horizontal: 11.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(9.r),
              border: Border.all(color: const Color(0xFFE9D9DE)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 20.sp,
                  color: const Color(0xFF797178),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search registry...',
                      hintStyle: GoogleFonts.manrope(
                        color: const Color(0xFF7A7379),
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: GoogleFonts.manrope(
                      color: const Color(0xFF272429),
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          height: 46.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(color: const Color(0xFFE9D9DE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Newest',
                style: GoogleFonts.manrope(
                  color: const Color(0xFF6E6369),
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20.sp,
                color: const Color(0xFF6E6369),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RegistryListContent extends StatelessWidget {
  const _RegistryListContent({
    required this.isLoading,
    required this.error,
    required this.customers,
    required this.onRetry,
    required this.onClientActionsPressed,
  });

  final bool isLoading;
  final String? error;
  final List<CustomerRegistryItem> customers;
  final VoidCallback onRetry;
  final ValueChanged<CustomerRegistryItem> onClientActionsPressed;

  @override
  Widget build(BuildContext context) {
    final registryProvider = context.watch<CustomerRegistryProvider>();

    if (isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 28.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return _RegistryMessage(
        message: error!,
        actionLabel: 'Retry',
        onActionPressed: onRetry,
      );
    }

    if (customers.isEmpty) {
      return const _RegistryMessage(message: 'No clients found.');
    }

    return ListView.separated(
      itemCount: customers.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final customer = customers[index];
        return _ClientRegistryCard(
          customer: customer,
          isDeleting: registryProvider.isRemovingCustomer(customer.id),
          onActionsPressed: () => onClientActionsPressed(customer),
        );
      },
    );
  }
}

class _RegistryMessage extends StatelessWidget {
  const _RegistryMessage({
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
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: const Color(0xFFEECFD9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F323247),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: const Color(0xFF6F6267),
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (actionLabel != null && onActionPressed != null) ...[
            SizedBox(height: 12.h),
            OutlinedButton(
              onPressed: onActionPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rmPrimary,
                side: const BorderSide(color: AppColors.rmPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
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

class _ClientRegistryCard extends StatelessWidget {
  const _ClientRegistryCard({
    required this.customer,
    required this.isDeleting,
    required this.onActionsPressed,
  });

  final CustomerRegistryItem customer;
  final bool isDeleting;
  final VoidCallback onActionsPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 11.h, 8.w, 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: const Color(0xFFEECFD9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F323247),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 23.r,
                backgroundColor: const Color(0xFFFFDDE8),
                child: Text(
                  customer.initials,
                  style: GoogleFonts.manrope(
                    color: AppColors.rmPrimary,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF272429),
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          size: 15.sp,
                          color: const Color(0xFF777077),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            customer.phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF6F6870),
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                constraints: BoxConstraints.tight(Size(30.w, 30.h)),
                padding: EdgeInsets.zero,
                onPressed: isDeleting ? null : onActionsPressed,
                icon: isDeleting
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.more_vert_rounded,
                        color: const Color(0xFF6E656B),
                        size: 22.sp,
                      ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _PackageBadge(
            label: customer.packageLabel,
            isPremium: customer.isPremium,
          ),
          SizedBox(height: 8.h),
          _AssignedChip(assignedTo: customer.assignedRmName),
          SizedBox(height: 12.h),
          _ProfileStatusBox(customer: customer),
        ],
      ),
    );
  }
}

class _ClientActionSheet extends StatelessWidget {
  const _ClientActionSheet({required this.customer, required this.onSelected});

  final CustomerRegistryItem customer;
  final ValueChanged<_ClientRegistryAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 18.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9C8CF),
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                customer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  color: AppColors.rmHeading,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 14.h),
              _ClientActionTile(
                icon: Icons.info_outline,
                label: 'View Ledger',
                color: AppColors.rmPrimary,
                onTap: () => onSelected(_ClientRegistryAction.viewLedger),
              ),
              SizedBox(height: 10.h),
              _ClientActionTile(
                icon: Icons.delete_outline,
                label: 'Delete Client',
                color: const Color(0xFFD1213E),
                onTap: () => onSelected(_ClientRegistryAction.delete),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF6E656B),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientActionTile extends StatelessWidget {
  const _ClientActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9FB),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFEECFD9)),
        ),
        child: Row(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.manrope(
                  color: AppColors.rmHeading,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFF8B7D84),
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageBadge extends StatelessWidget {
  const _PackageBadge({required this.label, required this.isPremium});

  final String label;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28.h,
      padding: EdgeInsets.symmetric(horizontal: 9.w),
      decoration: BoxDecoration(
        color: isPremium ? const Color(0xFFFFF6CE) : const Color(0xFFF6EEF2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isPremium ? const Color(0xFFFFE69B) : const Color(0xFFE5D8DE),
        ),
      ),
      child: Align(
        alignment: Alignment.center,
        widthFactor: 1,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            color: isPremium ? const Color(0xFF9B6B00) : AppColors.rmPrimary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AssignedChip extends StatelessWidget {
  const _AssignedChip({required this.assignedTo});

  final String assignedTo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 30.h,
      padding: EdgeInsets.symmetric(horizontal: 9.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(13.r),
        border: Border.all(color: const Color(0xFFE2D9DE)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline_rounded,
            size: 14.sp,
            color: const Color(0xFF6D646A),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              'Assigned to $assignedTo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: const Color(0xFF4A4449),
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatusBox extends StatelessWidget {
  const _ProfileStatusBox({required this.customer});

  final CustomerRegistryItem customer;

  @override
  Widget build(BuildContext context) {
    final profileLabel = customer.profilesCount == 0
        ? '0 Profiles (Pending digitization)'
        : '${customer.profilesCount} Profiles (${customer.activeProfilesCount} Active)';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 9.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8FB),
        borderRadius: BorderRadius.circular(9.r),
        border: Border.all(color: const Color(0xFFF0DDE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.hourglass_top_rounded,
                size: 15.sp,
                color: const Color(0xFFD1213E),
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  profileLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF2F2930),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14.sp,
                color: const Color(0xFF81777E),
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  'Added on ${customer.createdOn} by ${customer.assignedRmName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF6E656B),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RegistryMetric {
  const _RegistryMetric({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color accent;
}

class _RegistryFilter {
  const _RegistryFilter({
    required this.label,
    required this.count,
    this.selected = false,
  });

  final String label;
  final int count;
  final bool selected;
}
