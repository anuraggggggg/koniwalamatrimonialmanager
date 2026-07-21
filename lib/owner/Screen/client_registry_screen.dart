import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/owner/models/customer_registry_item.dart';
import 'package:koniwalamatrimonial/owner/providers/customer_registry_provider.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:provider/provider.dart';

enum ClientRegistryInitialFilter { all, standard, vip }

enum _ClientDateFilter {
  all('All Dates'),
  today('Today'),
  sevenDays('7 Days'),
  month('Month'),
  custom('Custom');

  const _ClientDateFilter(this.label);

  final String label;
}

class ClientRegistryScreen extends StatefulWidget {
  const ClientRegistryScreen({
    super.key,
    this.onMenuPressed,
    this.initialFilter = ClientRegistryInitialFilter.all,
  });

  final VoidCallback? onMenuPressed;
  final ClientRegistryInitialFilter initialFilter;

  @override
  State<ClientRegistryScreen> createState() => _ClientRegistryScreenState();
}

class _ClientRegistryScreenState extends State<ClientRegistryScreen> {
  int _selectedFilter = 0;
  final Set<String> _selectedRmNames = <String>{};
  _ClientDateFilter _selectedDateFilter = _ClientDateFilter.all;
  DateTimeRange? _customDateRange;
  bool _hasRequestedCustomers = false;
  String? _requestedAccessToken;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter.index;
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
      label: 'VIP Registry',
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
      filtered = filtered.where(_isVipCustomer).toList();
    }

    if (_selectedRmNames.isNotEmpty) {
      filtered = filtered
          .where(
            (customer) => _selectedRmNames.contains(customer.assignedRmName),
          )
          .toList();
    }

    final dateRange = _activeDateRange();
    if (dateRange != null) {
      filtered = filtered.where((customer) {
        final createdAt = customer.createdAt;
        if (createdAt == null) {
          return false;
        }

        return !createdAt.isBefore(dateRange.start) &&
            createdAt.isBefore(dateRange.end);
      }).toList();
    }

    filtered.
    
    
    
    
    
    
    
    
    sort((left, right) {
      final leftCreatedAt = left.createdAt;
      final rightCreatedAt = right.createdAt;
      if (leftCreatedAt == null && rightCreatedAt == null) {
        return 0;
      }
      if (leftCreatedAt == null) {
        return 1;
      }
      if (rightCreatedAt == null) {
        return -1;
      }
      return rightCreatedAt.compareTo(leftCreatedAt);
    });

    return filtered;
  }

  List<String> _rmOptions(List<CustomerRegistryItem> customers) {
    final options = customers
        .map((customer) => customer.assignedRmName.trim())
        .where((name) => name.isNotEmpty && name != '-')
        .toSet()
        .toList();
    options.sort(
      (left, right) => left.toLowerCase().compareTo(right.toLowerCase()),
    );
    return options;
  }

  DateTimeRange? _activeDateRange() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return switch (_selectedDateFilter) {
      _ClientDateFilter.all => null,
      _ClientDateFilter.today => DateTimeRange(
        start: todayStart,
        end: todayStart.add(const Duration(days: 1)),
      ),
      _ClientDateFilter.sevenDays => DateTimeRange(
        start: todayStart.subtract(const Duration(days: 6)),
        end: todayStart.add(const Duration(days: 1)),
      ),
      _ClientDateFilter.month => DateTimeRange(
        start: DateTime(now.year, now.month),
        end: DateTime(now.year, now.month + 1),
      ),
      _ClientDateFilter.custom =>
        _customDateRange == null
            ? null
            : DateTimeRange(
                start: DateTime(
                  _customDateRange!.start.year,
                  _customDateRange!.start.month,
                  _customDateRange!.start.day,
                ),
                end: DateTime(
                  _customDateRange!.end.year,
                  _customDateRange!.end.month,
                  _customDateRange!.end.day,
                ).add(const Duration(days: 1)),
              ),
    };
  }

  void _toggleRmFilter(String rmName) {
    setState(() {
      if (_selectedRmNames.contains(rmName)) {
        _selectedRmNames.remove(rmName);
      } else {
        _selectedRmNames.add(rmName);
      }
    });
  }

  void _clearRmFilter() {
    if (_selectedRmNames.isEmpty) {
      return;
    }
    setState(_selectedRmNames.clear);
  }

  Future<void> _selectDateFilter(_ClientDateFilter filter) async {
    if (filter == _ClientDateFilter.custom) {
      final now = DateTime.now();
      final initialRange =
          _customDateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
      final pickedRange = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 5),
        lastDate: DateTime(now.year + 1),
        initialDateRange: initialRange,
        helpText: 'Select client date range',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.black,
                onPrimary: AppColors.white,
                surface: AppColors.white,
                onSurface: AppColors.black,
              ),
              dialogTheme: const DialogThemeData(
                backgroundColor: AppColors.white,
              ),
              datePickerTheme: DatePickerThemeData(
                backgroundColor: AppColors.white,
                surfaceTintColor: AppColors.white,
                headerBackgroundColor: AppColors.white,
                headerForegroundColor: AppColors.black,
                rangePickerBackgroundColor: AppColors.white,
                rangePickerHeaderBackgroundColor: AppColors.white,
                rangePickerHeaderForegroundColor: AppColors.black,
                dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.white;
                  }
                  return AppColors.black;
                }),
                dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.black;
                  }
                  return AppColors.transparent;
                }),
                todayForegroundColor: const WidgetStatePropertyAll(
                  AppColors.black,
                ),
                todayBorder: const BorderSide(color: AppColors.black),
                rangeSelectionBackgroundColor: Color(0xFFEDEDED),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.black,
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      );
      if (!mounted || pickedRange == null) {
        return;
      }

      setState(() {
        _selectedDateFilter = filter;
        _customDateRange = pickedRange;
      });
      return;
    }

    setState(() {
      _selectedDateFilter = filter;
      if (filter != _ClientDateFilter.custom) {
        _customDateRange = null;
      }
    });
  }

  int _activeProfilesCount(List<CustomerRegistryItem> customers) {
    return customers.fold(
      0,
      (total, customer) => total + customer.activeProfilesCount,
    );
  }

  int _premiumCustomersCount(List<CustomerRegistryItem> customers) {
    return customers.where(_isVipCustomer).length;
  }

  bool _isVipCustomer(CustomerRegistryItem customer) {
    final packageType = customer.packageType.trim().toUpperCase();
    return packageType == 'PREMIUM' ||
        packageType == 'ELITE' ||
        packageType == 'VIP';
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
    final customers = context
        .select<CustomerRegistryProvider, List<CustomerRegistryItem>>(
          (provider) => provider.customers,
        );
    final isLoading = context.select<CustomerRegistryProvider, bool>(
      (provider) => provider.isLoading,
    );
    final error = context.select<CustomerRegistryProvider, String?>(
      (provider) => provider.error,
    );
    final metrics = _metrics(customers);
    final filters = _registryFilters(customers);
    final rmOptions = _rmOptions(customers);
    final visibleCustomers = _visibleCustomers(customers);

    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.rmPrimary,
          onRefresh: () => context.read<CustomerRegistryProvider>().retry(),
          child: CustomScrollView(
            cacheExtent: 700.h,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                sliver: SliverToBoxAdapter(
                  child: _ClientRegistryHeader(
                    onMenuPressed: widget.onMenuPressed,
                    onRefresh: () =>
                        context.read<CustomerRegistryProvider>().retry(),
                    isLoading: isLoading,
                  ),
                ),
              ),
              if (isLoading && customers.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                  sliver: const SliverToBoxAdapter(
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    const crossAxisCount = 2;
                    return SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _MetricCard(metric: metrics[index]),
                        childCount: metrics.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 8.w,
                        mainAxisSpacing: 8.h,
                        childAspectRatio: crossAxisCount == 4 ? 1.55 : 1.28,
                      ),
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                sliver: SliverToBoxAdapter(
                  child: _RegistryFilterRow(
                    filters: filters,
                    onSelected: (index) =>
                        setState(() => _selectedFilter = index),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                sliver: SliverToBoxAdapter(
                  child: _RegistryToolsRow(
                    rmOptions: rmOptions,
                    selectedRmNames: _selectedRmNames,
                    selectedDateFilter: _selectedDateFilter,
                    customDateRange: _customDateRange,
                    onRmSelected: _toggleRmFilter,
                    onClearRmFilter: _clearRmFilter,
                    onDateFilterSelected: _selectDateFilter,
                  ),
                ),
              ),
              _RegistryListSliver(
                isLoading: isLoading,
                error: error,
                customers: visibleCustomers,
                onRetry: () => context.read<CustomerRegistryProvider>().retry(),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientRegistryHeader extends StatelessWidget {
  const _ClientRegistryHeader({
    required this.onRefresh,
    required this.isLoading,
    this.onMenuPressed,
  });

  final VoidCallback? onMenuPressed;
  final VoidCallback onRefresh;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34.r,
          height: 34.r,
          child: IconButton(
            tooltip: onMenuPressed == null ? 'Back' : 'Menu',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            onPressed: onMenuPressed ?? () => Navigator.of(context).maybePop(),
            icon: Icon(
              onMenuPressed == null
                  ? Icons.arrow_back_rounded
                  : Icons.menu_rounded,
              color: AppColors.rmPrimary,
              size: 23.sp,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Client Registry',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.black,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                'Track converted clients, RM ownership, and registry status.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF6F6267),
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.28,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        _RefreshRegistryButton(onPressed: isLoading ? null : onRefresh),
      ],
    );
  }
}

class _RefreshRegistryButton extends StatelessWidget {
  const _RefreshRegistryButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.rmPrimary,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: Size(38.w, 34.h),
          padding: EdgeInsets.symmetric(horizontal: 11.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7.r),
          ),
        ),
        child: Icon(Icons.refresh_rounded, size: 17.sp),
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
      padding: EdgeInsets.fromLTRB(10.w, 9.h, 10.w, 9.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: metric.accent.withValues(alpha: 0.28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12323247),
            blurRadius: 8,
            offset: Offset(0, 2),
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
                  style: GoogleFonts.inter(
                    color: const Color(0xFF70656A),
                    fontSize: 10.8.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                  ),
                ),
              ),
              Icon(metric.icon, color: metric.accent, size: 17.sp),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF24191D),
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const Spacer(),
          Text(
            metric.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: metric.accent,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w600,
              height: 1.2,
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
    final foreground = AppColors.black;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          height: 36.h,
          padding: EdgeInsets.symmetric(horizontal: 11.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: filter.selected
                  ? AppColors.black
                  : const Color(0xFFE2E2E2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                filter.label,
                style: GoogleFonts.inter(
                  color: foreground,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                height: 20.h,
                constraints: BoxConstraints(minWidth: 20.w),
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFFE2E2E2)),
                ),
                child: Text(
                  '${filter.count}',
                  style: GoogleFonts.inter(
                    color: foreground,
                    fontSize: 10.5.sp,
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
    required this.rmOptions,
    required this.selectedRmNames,
    required this.selectedDateFilter,
    required this.customDateRange,
    required this.onRmSelected,
    required this.onClearRmFilter,
    required this.onDateFilterSelected,
  });

  final List<String> rmOptions;
  final Set<String> selectedRmNames;
  final _ClientDateFilter selectedDateFilter;
  final DateTimeRange? customDateRange;
  final ValueChanged<String> onRmSelected;
  final VoidCallback onClearRmFilter;
  final ValueChanged<_ClientDateFilter> onDateFilterSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RmFilterButton(
            rmOptions: rmOptions,
            selectedRmNames: selectedRmNames,
            onRmSelected: onRmSelected,
            onClear: onClearRmFilter,
          ),
        ),
        SizedBox(width: 8.w),
        _DateFilterButton(
          selectedDateFilter: selectedDateFilter,
          customDateRange: customDateRange,
          onSelected: onDateFilterSelected,
        ),
      ],
    );
  }
}

class _RmFilterButton extends StatelessWidget {
  const _RmFilterButton({
    required this.rmOptions,
    required this.selectedRmNames,
    required this.onRmSelected,
    required this.onClear,
  });

  final List<String> rmOptions;
  final Set<String> selectedRmNames;
  final ValueChanged<String> onRmSelected;
  final VoidCallback onClear;

  String get _label {
    if (selectedRmNames.isEmpty) {
      return 'All RM';
    }
    if (selectedRmNames.length == 1) {
      return selectedRmNames.first;
    }
    return '${selectedRmNames.length} RM selected';
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      enabled: rmOptions.isNotEmpty,
      tooltip: 'Filter by RM',
      color: AppColors.white,
      surfaceTintColor: AppColors.white,
      onSelected: (value) {
        if (value == '__clear__') {
          onClear();
          return;
        }
        onRmSelected(value);
      },
      itemBuilder: (context) => [
        if (selectedRmNames.isNotEmpty)
          PopupMenuItem<String>(
            value: '__clear__',
            child: Text(
              'Clear RM filter',
              style: GoogleFonts.inter(
                color: AppColors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ...rmOptions.map(
          (rmName) => PopupMenuItem<String>(
            value: rmName,
            child: Row(
              children: [
                IgnorePointer(
                  child: Checkbox(
                    value: selectedRmNames.contains(rmName),
                    onChanged: (_) {},
                    activeColor: AppColors.black,
                    checkColor: AppColors.white,
                    side: const BorderSide(color: AppColors.black),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    rmName,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      child: Container(
        height: 40.h,
        padding: EdgeInsets.symmetric(horizontal: 11.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(9.r),
          border: Border.all(color: const Color(0xFFE2E2E2)),
        ),
        child: Row(
          children: [
            Icon(Icons.badge_outlined, size: 17.sp, color: AppColors.black),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                rmOptions.isEmpty ? 'No RM assigned' : _label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.black,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 17.sp,
              color: AppColors.black,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({
    required this.selectedDateFilter,
    required this.customDateRange,
    required this.onSelected,
  });

  final _ClientDateFilter selectedDateFilter;
  final DateTimeRange? customDateRange;
  final ValueChanged<_ClientDateFilter> onSelected;

  String get _label {
    if (selectedDateFilter != _ClientDateFilter.custom ||
        customDateRange == null) {
      return selectedDateFilter.label;
    }

    return '${_shortDate(customDateRange!.start)} - ${_shortDate(customDateRange!.end)}';
  }

  static String _shortDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.white,
          surfaceTintColor: AppColors.white,
          textStyle: GoogleFonts.inter(
            color: AppColors.black,
            fontWeight: FontWeight.w800,
          ),
          labelTextStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(
              color: AppColors.black,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      child: PopupMenuButton<_ClientDateFilter>(
        tooltip: 'Filter by date',
        color: AppColors.white,
        surfaceTintColor: AppColors.white,
        onSelected: onSelected,
        itemBuilder: (context) => _ClientDateFilter.values.map((filter) {
          final selected = selectedDateFilter == filter;
          return PopupMenuItem<_ClientDateFilter>(
            value: filter,
            child: Row(
              children: [
                SizedBox(
                  width: 22.w,
                  child: selected
                      ? Icon(
                          Icons.check_rounded,
                          color: AppColors.black,
                          size: 18.sp,
                        )
                      : null,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    filter.label,
                    style: GoogleFonts.inter(
                      color: AppColors.black,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        child: Container(
          height: 40.h,
          constraints: BoxConstraints(maxWidth: 142.w),
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(color: const Color(0xFFE2E2E2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 15.sp,
                color: AppColors.black,
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  _label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.black,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 17.sp,
                color: AppColors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegistryListSliver extends StatelessWidget {
  const _RegistryListSliver({
    required this.isLoading,
    required this.error,
    required this.customers,
    required this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final List<CustomerRegistryItem> customers;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading && customers.isEmpty) {
      return SliverPadding(
        padding: EdgeInsets.symmetric(vertical: 34.h),
        sliver: const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (error != null) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
        sliver: SliverToBoxAdapter(
          child: _RegistryMessage(
            message: error!,
            actionLabel: 'Retry',
            onActionPressed: onRetry,
          ),
        ),
      );
    }

    if (customers.isEmpty) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
        sliver: const SliverToBoxAdapter(
          child: _RegistryMessage(message: 'No clients found.'),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      sliver: SliverList.separated(
        itemCount: customers.length,
        separatorBuilder: (context, index) => SizedBox(height: 8.h),
        itemBuilder: (context, index) {
          final customer = customers[index];
          return _ClientRegistryCard(customer: customer);
        },
      ),
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
            style: GoogleFonts.inter(
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
                style: GoogleFonts.inter(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClientRegistryCard extends StatelessWidget {
  const _ClientRegistryCard({required this.customer});

  final CustomerRegistryItem customer;

  @override
  Widget build(BuildContext context) {
    final packageType = customer.packageType.trim().toUpperCase();
    final isPriorityPackage =
        packageType == 'PREMIUM' ||
        packageType == 'ELITE' ||
        packageType == 'VIP';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(10.w, 10.h, 8.w, 10.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFEECFD9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10323247),
            blurRadius: 8,
            offset: Offset(0, 2),
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
                radius: 20.r,
                backgroundColor: const Color(0xFFFFDDE8),
                child: Text(
                  customer.initials,
                  style: GoogleFonts.inter(
                    color: AppColors.rmPrimary,
                    fontSize: 16.sp,
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
                      style: GoogleFonts.inter(
                        color: const Color(0xFF272429),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          size: 12.sp,
                          color: const Color(0xFF777077),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            customer.phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF6F6870),
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
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
          SizedBox(height: 10.h),
          Row(
            children: [
              Flexible(
                child: _PackageBadge(
                  label: customer.packageLabel,
                  isPremium: isPriorityPackage,
                ),
              ),
              SizedBox(width: 7.w),
              Expanded(
                child: _AssignedChip(assignedTo: customer.assignedRmName),
              ),
            ],
          ),
          SizedBox(height: 9.h),
          _ProfileStatusBox(customer: customer),
        ],
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
      height: 26.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: isPremium ? const Color(0xFFFFF6CE) : const Color(0xFFF6EEF2),
        borderRadius: BorderRadius.circular(10.r),
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
          style: GoogleFonts.inter(
            color: isPremium ? const Color(0xFF9B6B00) : AppColors.rmPrimary,
            fontSize: 10.5.sp,
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
      height: 26.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE2D9DE)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline_rounded,
            size: 12.sp,
            color: const Color(0xFF6D646A),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              'Assigned to $assignedTo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFF4A4449),
                fontSize: 10.5.sp,
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
      padding: EdgeInsets.fromLTRB(9.w, 8.h, 9.w, 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8FB),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFF0DDE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.hourglass_top_rounded,
                size: 12.sp,
                color: const Color(0xFFD1213E),
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  profileLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF2F2930),
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 11.sp,
                color: const Color(0xFF81777E),
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  'Added on ${customer.createdOn} by ${customer.assignedRmName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6E656B),
                    fontSize: 10.5.sp,
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
