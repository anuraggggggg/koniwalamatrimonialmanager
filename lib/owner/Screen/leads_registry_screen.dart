import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/owner/models/lead_registry_item.dart';
import 'package:koniwalamatrimonial/owner/providers/leads_provider.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:provider/provider.dart';

class LeadsRegistryScreen extends StatelessWidget {
  const LeadsRegistryScreen({
    super.key,
    this.showScaffold = false,
    this.onMenuPressed,
    this.initialStage,
  });

  final bool showScaffold;
  final VoidCallback? onMenuPressed;
  final String? initialStage;

  @override
  Widget build(BuildContext context) {
    final body = _LeadsRegistryBody(
      onMenuPressed: onMenuPressed,
      initialStage: initialStage,
    );

    if (!showScaffold) {
      return ColoredBox(color: AppColors.rmSoftPink, child: body);
    }

    return Scaffold(backgroundColor: AppColors.rmSoftPink, body: body);
  }
}

class _LeadsRegistryBody extends StatefulWidget {
  const _LeadsRegistryBody({this.onMenuPressed, this.initialStage});

  final VoidCallback? onMenuPressed;
  final String? initialStage;

  @override
  State<_LeadsRegistryBody> createState() => _LeadsRegistryBodyState();
}

class _LeadsRegistryBodyState extends State<_LeadsRegistryBody> {
  static const List<String> _leadForOptions = ['Groom', 'Bride'];
  static const int _registryPreviewCount = 3;
  static const int _registryPageSize = 15;
  int _selectedStage = 0;
  String? _selectedSource;
  String? _selectedCity;
  final Set<String> _selectedAssignees = <String>{};
  bool _showExecutiveDropdown = false;
  _LeadDateRange _selectedDateRange = _LeadDateRange.any;
  DateTime? _customDateFrom;
  DateTime? _customDateTo;
  bool _hasRequestedLeads = false;
  String? _requestedAccessToken;
  int _registryLeadLimit = _registryPreviewCount;

  @override
  void initState() {
    super.initState();
    _selectedStage = _initialStageIndex(widget.initialStage);
  }

  int _initialStageIndex(String? stage) {
    switch (stage?.trim().toLowerCase()) {
      case 'new':
        return 1;
      case 'converted':
        return 4;
      default:
        return 0;
    }
  }

  List<_StageFilter> _stageFilters(List<LeadRegistryItem> leads) {
    final counts = _stageCounts(leads);
    return [
      _StageFilter(label: 'All', count: leads.length),
      _StageFilter(
        label: 'New',
        count: counts['NEW'] ?? 0,
        dotColor: const Color(0xFFB6BEC8),
      ),
      _StageFilter(
        label: 'Contacted',
        count: counts['CONTACTED'] ?? 0,
        dotColor: const Color(0xFFFFA000),
      ),
      _StageFilter(
        label: 'Interested',
        count: counts['INTERESTED'] ?? 0,
        dotColor: const Color(0xFF338AF3),
      ),
      _StageFilter(
        label: 'Converted',
        count: counts['CONVERTED'] ?? 0,
        dotColor: const Color(0xFF22B883),
      ),
      _StageFilter(
        label: 'Closed',
        count: counts['CLOSED'] ?? 0,
        dotColor: const Color(0xFF77716C),
      ),
      _StageFilter(
        label: 'Starred',
        count: counts['STARRED'] ?? 0,
        dotColor: const Color(0xFFE2B714),
        icon: Icons.star_border_rounded,
      ),
    ];
  }

  Map<String, int> _stageCounts(List<LeadRegistryItem> leads) {
    final counts = <String, int>{};
    for (final lead in leads) {
      final key = _stageKey(lead.stage);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  List<LeadRegistryItem> _visibleLeads(
    List<LeadRegistryItem> leads,
    List<_StageFilter> stageFilters,
  ) {
    return leads.where((lead) {
      if (_selectedStage != 0) {
        final selectedStage = _stageKey(stageFilters[_selectedStage].label);
        if (_stageKey(lead.stage) != selectedStage) {
          return false;
        }
      }

      if (!_matchesOptionalFilter(lead.source, _selectedSource)) {
        return false;
      }

      if (!_matchesOptionalFilter(lead.city, _selectedCity)) {
        return false;
      }

      if (!_matchesAssigneeFilters(lead.assignedTo)) {
        return false;
      }

      return _matchesDateRange(lead.createdOn);
    }).toList();
  }

  String _stageKey(String stage) {
    return stage.toUpperCase().replaceAll(' ', '_');
  }

  bool _matchesOptionalFilter(String value, String? selectedValue) {
    return selectedValue == null || value.trim() == selectedValue.trim();
  }

  bool _matchesAssigneeFilters(String value) {
    return _selectedAssignees.isEmpty ||
        _selectedAssignees.contains(value.trim());
  }

  bool _matchesDateRange(String createdOn) {
    if (_selectedDateRange == _LeadDateRange.any) {
      return true;
    }

    final createdDate = _parseLeadDate(createdOn);
    if (createdDate == null) {
      return false;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final leadDate = DateTime(
      createdDate.year,
      createdDate.month,
      createdDate.day,
    );

    switch (_selectedDateRange) {
      case _LeadDateRange.any:
        return true;
      case _LeadDateRange.today:
        return leadDate == today;
      case _LeadDateRange.last7Days:
        return !leadDate.isBefore(today.subtract(const Duration(days: 6))) &&
            !leadDate.isAfter(today);
      case _LeadDateRange.last30Days:
        return !leadDate.isBefore(today.subtract(const Duration(days: 29))) &&
            !leadDate.isAfter(today);
      case _LeadDateRange.custom:
        final from = _customDateFrom;
        final to = _customDateTo;
        if (from == null && to == null) {
          return true;
        }

        final start = from == null
            ? null
            : DateTime(from.year, from.month, from.day);
        final end = to == null ? null : DateTime(to.year, to.month, to.day);

        if (start != null && leadDate.isBefore(start)) {
          return false;
        }

        if (end != null && leadDate.isAfter(end)) {
          return false;
        }

        return true;
    }
  }

  DateTime? _parseLeadDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '-') {
      return null;
    }

    final parsedDate = DateTime.tryParse(trimmed);
    if (parsedDate != null) {
      return parsedDate;
    }

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = _monthNumber(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  int? _monthNumber(String label) {
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

    return months[label.trim().toLowerCase()];
  }

  List<String> _filterOptions(
    List<LeadRegistryItem> leads,
    String Function(LeadRegistryItem lead) valueForLead,
  ) {
    final values = leads
        .map(valueForLead)
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && value != '-')
        .toSet()
        .toList();
    values.sort(
      (first, second) => first.toLowerCase().compareTo(second.toLowerCase()),
    );
    return values;
  }

  int get _activeFilterCount {
    var count = 0;
    if (_selectedSource != null) count++;
    if (_selectedCity != null) count++;
    if (_selectedDateRange != _LeadDateRange.any) count++;
    return count;
  }

  int _visibleLeadLimitFor(int totalLeadCount) {
    return _boundedRegistryLeadLimit(_registryLeadLimit, totalLeadCount);
  }

  int _boundedRegistryLeadLimit(int requestedLimit, int totalLeadCount) {
    if (totalLeadCount <= 0) {
      return 0;
    }

    if (requestedLimit < _registryPreviewCount) {
      return totalLeadCount < _registryPreviewCount
          ? totalLeadCount
          : _registryPreviewCount;
    }

    if (requestedLimit > totalLeadCount) {
      return totalLeadCount;
    }

    return requestedLimit;
  }

  Future<void> _showLeadFiltersSheet(List<LeadRegistryItem> leads) async {
    final result = await showModalBottomSheet<_LeadFilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) {
        return _LeadFiltersBottomSheet(
          sourceOptions: _filterOptions(leads, (lead) => lead.source),
          cityOptions: _filterOptions(leads, (lead) => lead.city),
          initialSelection: _LeadFilterSelection(
            selectedStage: _selectedStage,
            source: _selectedSource,
            city: _selectedCity,
            dateRange: _selectedDateRange,
            customDateFrom: _customDateFrom,
            customDateTo: _customDateTo,
          ),
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedSource = result.source;
      _selectedCity = result.city;
      _selectedDateRange = result.dateRange;
      _customDateFrom = result.customDateFrom;
      _customDateTo = result.customDateTo;
      _registryLeadLimit = _registryPreviewCount;
    });
  }

  bool _canEditLeads(String? role) {
    final normalizedRole = role?.trim().toUpperCase();
    return normalizedRole == 'ADMIN' || normalizedRole == 'OWNER';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authProvider = Provider.of<AuthProvider>(context);
    final accessToken = authProvider.userModel?.accessToken;

    if (!authProvider.isInitialized ||
        (_hasRequestedLeads && accessToken == _requestedAccessToken)) {
      return;
    }

    _hasRequestedLeads = true;
    _requestedAccessToken = accessToken;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<LeadsProvider>().fetchLeads(accessToken);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leadsProvider = context.watch<LeadsProvider>();
    final authProvider = context.watch<AuthProvider>();
    final leads = leadsProvider.leads;
    final stageFilters = _stageFilters(leads);
    final assigneeOptions = _filterOptions(leads, (lead) => lead.assignedTo);
    final visibleLeads = _visibleLeads(leads, stageFilters);
    final canEditLeads = _canEditLeads(authProvider.userModel?.user?.role);
    final convertedCount =
        stageFilters
            .firstWhere((filter) => filter.label == 'Converted')
            .count ??
        0;
    final registryVisibleLimit = _visibleLeadLimitFor(visibleLeads.length);
    final registryPreviewLeads = visibleLeads
        .take(registryVisibleLimit)
        .toList(growable: false);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LeadsHeader(
                onMenuPressed: widget.onMenuPressed,
                onNewInquiryCreated: () {
                  context.read<LeadsProvider>().fetchLeads(
                    authProvider.userModel?.accessToken,
                    forceRefresh: true,
                  );
                },
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StageFilterChips(
                      filters: stageFilters,
                      selectedIndex: _selectedStage,
                      onSelected: (index) {
                        setState(() {
                          _selectedStage = index;
                          _registryLeadLimit = _registryPreviewCount;
                        });
                      },
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TapRegion(
                            enabled: _showExecutiveDropdown,
                            onTapOutside: (_) {
                              if (!_showExecutiveDropdown) {
                                return;
                              }

                              setState(() {
                                _showExecutiveDropdown = false;
                              });
                            },
                            child: _ExecutiveMultiSelectDropdown(
                              options: assigneeOptions,
                              selectedValues: _selectedAssignees,
                              isExpanded: _showExecutiveDropdown,
                              onHeaderTap: () => setState(() {
                                _showExecutiveDropdown =
                                    !_showExecutiveDropdown;
                              }),
                              onSelectionChanged: (name, selected) =>
                                  setState(() {
                                    if (selected) {
                                      _selectedAssignees.add(name);
                                    } else {
                                      _selectedAssignees.remove(name);
                                    }
                                    _registryLeadLimit = _registryPreviewCount;
                                  }),
                              onClear: _selectedAssignees.isEmpty
                                  ? null
                                  : () => setState(() {
                                      _selectedAssignees.clear();
                                      _registryLeadLimit =
                                          _registryPreviewCount;
                                    }),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        _CompactFilterButton(
                          activeFilterCount: _activeFilterCount,
                          onPressed: () => _showLeadFiltersSheet(leads),
                        ),
                      ],
                    ),
                    SizedBox(height: 22.h),
                    _LeadsContent(
                      isLoading: leadsProvider.isLoading,
                      error: leadsProvider.error,
                      leads: registryPreviewLeads,
                      totalLeadCount: visibleLeads.length,
                      isExpanded: registryVisibleLimit >= visibleLeads.length,
                      onToggleExpanded:
                          visibleLeads.length > _registryPreviewCount
                          ? () => setState(() {
                              if (registryVisibleLimit >= visibleLeads.length) {
                                _registryLeadLimit = _registryPreviewCount;
                                return;
                              }

                              _registryLeadLimit = _boundedRegistryLeadLimit(
                                _registryLeadLimit + _registryPageSize,
                                visibleLeads.length,
                              );
                            })
                          : null,
                      onRetry: () => context.read<LeadsProvider>().retry(),
                      canEditLead: canEditLeads,
                      onEditLead: (lead) => _showEditLeadDialog(context, lead),
                      onUpdateStageLead: (lead) =>
                          _showUpdateStageDialog(context, lead),
                    ),
                    SizedBox(height: 18.h),
                    _ArchiveInsightCard(
                      totalLeads: leads.length,
                      filteredLeads: visibleLeads.length,
                    ),
                    SizedBox(height: 16.h),
                    _CuratorMilestoneCard(
                      totalLeads: leads.length,
                      convertedCount: convertedCount,
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showUpdateStageDialog(
    BuildContext context,
    LeadRegistryItem lead,
  ) async {
    final nextStage = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _UpdateLeadStageDialog(lead: lead),
    );

    if (nextStage == null || !context.mounted) {
      return;
    }

    final message = await context.read<LeadsProvider>().updateLeadStage(
      lead: lead,
      accessToken: context.read<AuthProvider>().userModel?.accessToken,
      stage: nextStage,
    );

    if (!context.mounted) {
      return;
    }

    _showSnackBar(
      context,
      message ?? 'Lead status updated successfully.',
      isError: message != null,
    );
  }

  Future<void> _showEditLeadDialog(
    BuildContext context,
    LeadRegistryItem lead,
  ) async {
    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    final leadsProvider = context.read<LeadsProvider>();
    final managers = await leadsProvider.fetchRelationshipManagers(accessToken);
    if (!context.mounted) {
      return;
    }

    final nameController = TextEditingController(text: lead.name);
    final phoneController = TextEditingController(text: lead.phone);
    final emailController = TextEditingController(text: lead.email);
    final stageController = TextEditingController(text: lead.stage);
    final cityController = TextEditingController(text: lead.city);
    final sourceController = TextEditingController(text: lead.source);
    final leadForController = TextEditingController(text: lead.leadFor);
    var selectedLeadFor = _leadForOptions.contains(lead.leadFor)
        ? lead.leadFor
        : null;
    var selectedManagerId =
        managers.any((manager) => manager.id == lead.assignedToId)
        ? lead.assignedToId
        : null;
    var selectedManagerName = selectedManagerId == null
        ? lead.assignedTo
        : managers
              .firstWhere((manager) => manager.id == selectedManagerId)
              .name;

    try {
      final result = await showDialog<_EditLeadResult>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (stateContext, setDialogState) {
              return Dialog(
                insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
                backgroundColor: AppColors.transparent,
                child: Container(
                  padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 18.h),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(22.r),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 28,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edit Lead',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF1F1C19),
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Update the lead details and assignment information.',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF6F6661),
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w500,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8.w),
                            InkWell(
                              onTap: () => Navigator.of(dialogContext).pop(),
                              borderRadius: BorderRadius.circular(16.r),
                              child: Container(
                                width: 34.w,
                                height: 34.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9F2EE),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18.sp,
                                  color: const Color(0xFF625B56),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 18.h),
                        _EditLeadField(
                          label: 'Name',
                          controller: nameController,
                        ),
                        SizedBox(height: 12.h),
                        _EditLeadField(
                          label: 'Phone',
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: 12.h),
                        _EditLeadField(
                          label: 'Email',
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 12.h),
                        _EditLeadField(
                          label: 'Stage',
                          controller: stageController,
                        ),
                        SizedBox(height: 12.h),
                        _EditLeadField(
                          label: 'City',
                          controller: cityController,
                        ),
                        SizedBox(height: 12.h),
                        _RelationshipManagerField(
                          managers: managers,
                          selectedManagerId: selectedManagerId,
                          fallbackLabel: selectedManagerName,
                          onChanged: (managerId) {
                            final matches = managers.where(
                              (manager) => manager.id == managerId,
                            );
                            setDialogState(() {
                              selectedManagerId = managerId;
                              selectedManagerName = matches.isEmpty
                                  ? selectedManagerName
                                  : matches.first.name;
                            });
                          },
                        ),
                        SizedBox(height: 12.h),
                        _EditLeadField(
                          label: 'Source',
                          controller: sourceController,
                        ),
                        SizedBox(height: 12.h),
                        _EditLeadDropdownField(
                          label: 'Lead For',
                          value: selectedLeadFor,
                          hintText: 'Select profile type',
                          items: _leadForOptions,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedLeadFor = value;
                              leadForController.text = value ?? '';
                            });
                          },
                        ),
                        SizedBox(height: 18.h),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6F5F64),
                                  side: const BorderSide(
                                    color: Color(0xFFE5D3C8),
                                  ),
                                  minimumSize: Size.fromHeight(46.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(
                                      _EditLeadResult(
                                        name: nameController.text,
                                        phone: phoneController.text,
                                        email: emailController.text,
                                        stage: stageController.text,
                                        city: cityController.text,
                                        source: sourceController.text,
                                        leadFor:
                                            selectedLeadFor ??
                                            leadForController.text,
                                        assignedToId:
                                            selectedManagerId ??
                                            lead.assignedToId,
                                        assignedToName: selectedManagerName,
                                      ),
                                    ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  elevation: 0,
                                  minimumSize: Size.fromHeight(46.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                ),
                                child: Text(
                                  'Save',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      if (result == null || !context.mounted) {
        return;
      }

      final currentAccessToken = context
          .read<AuthProvider>()
          .userModel
          ?.accessToken;
      final message = await leadsProvider.updateLead(
        lead: lead,
        accessToken: currentAccessToken,
        name: result.name,
        phone: result.phone,
        email: result.email,
        stage: result.stage,
        city: result.city,
        source: result.source,
        leadFor: result.leadFor,
        assignedToId: result.assignedToId,
        assignedToName: result.assignedToName,
      );

      if (!context.mounted) {
        return;
      }

      _showSnackBar(
        context,
        message ?? 'Lead updated successfully.',
        isError: message != null,
      );
    } finally {
      nameController.dispose();
      phoneController.dispose();
      emailController.dispose();
      stageController.dispose();
      cityController.dispose();
      sourceController.dispose();
      leadForController.dispose();
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Colors.red.shade600
              : Colors.green.shade600,
        ),
      );
  }
}

class _LeadsContent extends StatelessWidget {
  const _LeadsContent({
    required this.isLoading,
    required this.error,
    required this.leads,
    required this.totalLeadCount,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onRetry,
    required this.canEditLead,
    required this.onEditLead,
    required this.onUpdateStageLead,
  });

  final bool isLoading;
  final String? error;
  final List<LeadRegistryItem> leads;
  final int totalLeadCount;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;
  final VoidCallback onRetry;
  final bool canEditLead;
  final ValueChanged<LeadRegistryItem> onEditLead;
  final ValueChanged<LeadRegistryItem> onUpdateStageLead;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 32.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: const Color(0xFFF0DFD4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12C67A42),
              blurRadius: 26,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: const Color(0xFFF0DFD4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12C67A42),
              blurRadius: 26,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: _LeadsMessage(
          message: error!,
          actionLabel: 'Retry',
          onActionPressed: onRetry,
        ),
      );
    }

    if (leads.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: const Color(0xFFF0DFD4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12C67A42),
              blurRadius: 26,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: const _LeadsMessage(message: 'No leads found.'),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFF0DFD4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12C67A42),
            blurRadius: 26,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          ListView.separated(
            itemCount: leads.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) => _LeadCard(
              lead: leads[index],
              canEdit: canEditLead,
              onUpdateStage: () => onUpdateStageLead(leads[index]),
              onEdit: () => onEditLead(leads[index]),
            ),
          ),
          if (onToggleExpanded != null) ...[
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onToggleExpanded,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: Size.fromHeight(48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  isExpanded ? 'Show Less' : 'Show More Leads ->',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ] else if (totalLeadCount > 0) ...[
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  disabledForegroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: Size.fromHeight(48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  'View All Leads ->',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UpdateLeadStageDialog extends StatelessWidget {
  const _UpdateLeadStageDialog({required this.lead});

  static const List<String> _stages = [
    'New',
    'Contacted',
    'Interested',
    'Converted',
    'Closed',
  ];

  final LeadRegistryItem lead;

  String _stageKey(String stage) {
    return stage.toUpperCase().replaceAll(' ', '_');
  }

  @override
  Widget build(BuildContext context) {
    final currentStageKey = _stageKey(lead.stage);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
      backgroundColor: AppColors.transparent,
      child: Container(
        padding: EdgeInsets.fromLTRB(22.w, 18.h, 22.w, 22.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Icon(
                    Icons.fact_check_outlined,
                    color: AppColors.black,
                    size: 22.sp,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: const Color(0xFF6F6A66),
                    size: 22.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Text(
              'Update Status',
              style: GoogleFonts.inter(
                color: AppColors.black,
                fontSize: 26.sp,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Select the new stage for ${lead.name}.',
              style: GoogleFonts.inter(
                color: const Color(0xFF6D6764),
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
            SizedBox(height: 26.h),
            ..._stages.map((stage) {
              final isCurrent = _stageKey(stage) == currentStageKey;
              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _UpdateLeadStageOption(
                  stage: stage,
                  isCurrent: isCurrent,
                  onTap: isCurrent
                      ? null
                      : () => Navigator.of(context).pop(stage),
                ),
              );
            }),
            SizedBox(height: 8.h),
            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.black,
                  side: const BorderSide(color: Color(0xFFE2E2E2)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
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

class _UpdateLeadStageOption extends StatelessWidget {
  const _UpdateLeadStageOption({
    required this.stage,
    required this.isCurrent,
    required this.onTap,
  });

  final String stage;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = _LeadStageStyle.fromStage(stage);
    final colors = stage == 'Closed'
        ? const _StageColors(
            background: Color(0xFFF3F5F7),
            border: Color(0xFFD8DEE6),
            dot: Color(0xFF6E7F94),
            text: Color(0xFF26384F),
          )
        : style.colors;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.r),
        child: Container(
          constraints: BoxConstraints(minHeight: 62.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isCurrent ? const Color(0xFFF7F7F7) : AppColors.white,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8.r,
                      height: 8.r,
                      decoration: BoxDecoration(
                        color: colors.dot,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      stage,
                      style: GoogleFonts.inter(
                        color: colors.text,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (isCurrent)
                Text(
                  'Current',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9B9895),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditLeadResult {
  const _EditLeadResult({
    required this.name,
    required this.phone,
    required this.email,
    required this.stage,
    required this.city,
    required this.source,
    required this.leadFor,
    required this.assignedToId,
    required this.assignedToName,
  });

  final String name;
  final String phone;
  final String email;
  final String stage;
  final String city;
  final String source;
  final String leadFor;
  final String assignedToId;
  final String assignedToName;
}

class _EditLeadField extends StatelessWidget {
  const _EditLeadField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
        color: AppColors.rmHeading,
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
      ),
      decoration: _editLeadDecoration(label),
    );
  }
}

class _EditLeadDropdownField extends StatelessWidget {
  const _EditLeadDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: AppColors.white,
      style: GoogleFonts.inter(
        color: AppColors.rmHeading,
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
      ),
      decoration: _editLeadDecoration(label),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: const Color(0xFF6F5F64),
        size: 22.sp,
      ),
      hint: hintText == null
          ? null
          : Text(
              hintText!,
              style: GoogleFonts.inter(
                color: const Color(0xFF8C817D),
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.inter(
                  color: AppColors.rmHeading,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _RelationshipManagerField extends StatelessWidget {
  const _RelationshipManagerField({
    required this.managers,
    required this.selectedManagerId,
    required this.fallbackLabel,
    required this.onChanged,
  });

  final List<RelationshipManagerOption> managers;
  final String? selectedManagerId;
  final String fallbackLabel;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (managers.isEmpty) {
      return InputDecorator(
        decoration: _editLeadDecoration('Assigned To'),
        child: Text(
          fallbackLabel.isEmpty ? '-' : fallbackLabel,
          style: GoogleFonts.inter(
            color: AppColors.rmHeading,
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: selectedManagerId,
      isExpanded: true,
      dropdownColor: AppColors.white,
      style: GoogleFonts.inter(
        color: AppColors.rmHeading,
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
      ),
      decoration: _editLeadDecoration('Assigned To'),
      hint: Text(
        fallbackLabel.isEmpty ? 'Select relationship manager' : fallbackLabel,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: const Color(0xFF8C817D),
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: const Color(0xFF6F5F64),
        size: 22.sp,
      ),
      items: managers
          .map(
            (manager) => DropdownMenuItem<String>(
              value: manager.id,
              child: Text(
                manager.displayLabel,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.rmHeading,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

InputDecoration _editLeadDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.inter(
      color: const Color(0xFF6F5F64),
      fontSize: 13.sp,
      fontWeight: FontWeight.w700,
    ),
    filled: true,
    fillColor: const Color(0xFFFFFBF9),
    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: Color(0xFFE7D7CF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: AppColors.rmPrimary),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: const BorderSide(color: Color(0xFFE7D7CF)),
    ),
  );
}

class _LeadsMessage extends StatelessWidget {
  const _LeadsMessage({
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
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFEECAD4)),
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
            style: GoogleFonts.inter(
              color: const Color(0xFF6F5F64),
              fontSize: 15.sp,
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

class _LeadsHeader extends StatelessWidget {
  const _LeadsHeader({this.onMenuPressed, this.onNewInquiryCreated});

  final VoidCallback? onMenuPressed;
  final VoidCallback? onNewInquiryCreated;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 12.h),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFF2DED1))),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40.w,
                height: 40.w,
                child: IconButton(
                  tooltip: onMenuPressed == null ? 'Back' : 'Menu',
                  padding: EdgeInsets.zero,
                  onPressed:
                      onMenuPressed ?? () => Navigator.of(context).maybePop(),
                  icon: Icon(
                    onMenuPressed == null
                        ? Icons.arrow_back_rounded
                        : Icons.menu_rounded,
                    color: const Color(0xFF1F1A17),
                    size: 23.sp,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Leads Registration',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1F1A17),
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 40.w),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Curating matrimonial connections with archival precision.',
                style: GoogleFonts.inter(
                  color: const Color(0xFF2A2927),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.55,
                ),
              ),
              SizedBox(height: 16.h),
              _NewInquiryButton(
                onPressed: () async {
                  final created = await Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.newInquiry);
                  if (created == true) {
                    onNewInquiryCreated?.call();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// class _LeadFollowUpsButton extends StatelessWidget {
//   const _LeadFollowUpsButton({required this.onPressed});
//
//   final VoidCallback onPressed;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 42.h,
//       height: 42.h,
//       decoration: BoxDecoration(
//         color: AppColors.white,
//         borderRadius: BorderRadius.circular(8.r),
//         border: Border.all(color: AppColors.rmPrimary, width: 1.2),
//       ),
//       child: IconButton(
//         tooltip: 'Lead Follow-ups',
//         padding: EdgeInsets.zero,
//         onPressed: onPressed,
//         icon: Icon(
//           Icons.event_available_outlined,
//           color: AppColors.rmPrimary,
//           size: 22.sp,
//         ),
//       ),
//     );
//   }
// }

class _NewInquiryButton extends StatelessWidget {
  const _NewInquiryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: Size.fromHeight(46.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          '+ New Lead',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StageFilterChips extends StatelessWidget {
  const _StageFilterChips({
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_StageFilter> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < filters.length; index++) ...[
            _StageFilterChip(
              filter: filters[index],
              selected: selectedIndex == index,
              onTap: () => onSelected(index),
            ),
            if (index != filters.length - 1) SizedBox(width: 8.w),
          ],
        ],
      ),
    );
  }
}

class _StageFilterChip extends StatelessWidget {
  const _StageFilterChip({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final _StageFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          height: 36.h,
          padding: EdgeInsets.symmetric(horizontal: 11.w),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFEEDFD5),
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (filter.icon != null) ...[
                Icon(
                  filter.icon,
                  size: 13.sp,
                  color: selected ? AppColors.white : filter.dotColor,
                ),
                SizedBox(width: 5.w),
              ] else if (filter.dotColor != null) ...[
                Container(
                  width: 6.r,
                  height: 6.r,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.white : filter.dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6.w),
              ],
              Text(
                '${filter.label} ${filter.count ?? 0}',
                style: GoogleFonts.inter(
                  color: selected ? AppColors.white : const Color(0xFF282623),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExecutiveMultiSelectDropdown extends StatelessWidget {
  const _ExecutiveMultiSelectDropdown({
    required this.options,
    required this.selectedValues,
    required this.isExpanded,
    required this.onHeaderTap,
    required this.onSelectionChanged,
    required this.onClear,
  });

  final List<String> options;
  final Set<String> selectedValues;
  final bool isExpanded;
  final VoidCallback onHeaderTap;
  final ValueChangedSelection onSelectionChanged;
  final VoidCallback? onClear;

  String get _summaryText {
    if (selectedValues.isEmpty) {
      return 'All RM';
    }
    if (selectedValues.length == 1) {
      return selectedValues.first;
    }
    return '${selectedValues.length} RM selected';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: options.isEmpty ? null : onHeaderTap,
            borderRadius: BorderRadius.circular(14.r),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(12.w, 11.h, 12.w, 11.h),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: const Color(0xFFE2E2E2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(11.r),
                      border: Border.all(color: const Color(0xFFE2E2E2)),
                    ),
                    child: Icon(
                      Icons.manage_accounts_outlined,
                      color: AppColors.black,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 11.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Executive / RM',
                          style: GoogleFonts.inter(
                            color: AppColors.black,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          options.isEmpty ? 'No RM available' : _summaryText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppColors.black,
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onClear != null) ...[
                    SizedBox(width: 6.w),
                    InkWell(
                      borderRadius: BorderRadius.circular(16.r),
                      onTap: onClear,
                      child: Padding(
                        padding: EdgeInsets.all(4.r),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.black,
                          size: 18.sp,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(width: 6.w),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.black,
                    size: 24.sp,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded && options.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: 230.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFFE2E2E2)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(vertical: 6.h),
              itemCount: options.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: const Color(0xFFE2E2E2)),
              itemBuilder: (context, index) {
                final option = options[index];
                final selected = selectedValues.contains(option);
                return CheckboxListTile(
                  dense: true,
                  value: selected,
                  onChanged: (value) =>
                      onSelectionChanged(option, value ?? false),
                  activeColor: AppColors.black,
                  checkColor: AppColors.white,
                  side: const BorderSide(color: AppColors.black),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                  title: Text(
                    option,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.black,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

typedef ValueChangedSelection = void Function(String value, bool selected);

class _CompactFilterButton extends StatelessWidget {
  const _CompactFilterButton({
    required this.activeFilterCount,
    required this.onPressed,
  });

  final int activeFilterCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onPressed,
        child: Container(
          width: 58.w,
          height: 62.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: const Color(0xFFEEDFD5)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Icon(
                  Icons.tune_rounded,
                  color: AppColors.primary,
                  size: 24.sp,
                ),
              ),
              if (activeFilterCount > 0)
                Positioned(
                  right: -5.w,
                  top: -5.h,
                  child: Container(
                    height: 20.r,
                    constraints: BoxConstraints(minWidth: 20.r),
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: 5.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '$activeFilterCount',
                      style: GoogleFonts.inter(
                        color: AppColors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
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
}

enum _LeadDateRange { any, today, last7Days, last30Days, custom }

class _LeadFilterSelection {
  const _LeadFilterSelection({
    required this.selectedStage,
    required this.source,
    required this.city,
    required this.dateRange,
    required this.customDateFrom,
    required this.customDateTo,
  });

  final int selectedStage;
  final String? source;
  final String? city;
  final _LeadDateRange dateRange;
  final DateTime? customDateFrom;
  final DateTime? customDateTo;
}

class _LeadFiltersBottomSheet extends StatefulWidget {
  const _LeadFiltersBottomSheet({
    this.sourceOptions = const [],
    this.cityOptions = const [],
    this.initialSelection = const _LeadFilterSelection(
      selectedStage: 0,
      source: null,
      city: null,
      dateRange: _LeadDateRange.any,
      customDateFrom: null,
      customDateTo: null,
    ),
  });

  final List<String> sourceOptions;
  final List<String> cityOptions;
  final _LeadFilterSelection initialSelection;

  @override
  State<_LeadFiltersBottomSheet> createState() =>
      _LeadFiltersBottomSheetState();
}

class _LeadFiltersBottomSheetState extends State<_LeadFiltersBottomSheet> {
  late int _currentStage;
  String? _selectedSource;
  String? _selectedCity;
  late _LeadDateRange _selectedDateRange;
  DateTime? _customDateFrom;
  DateTime? _customDateTo;

  @override
  void initState() {
    super.initState();
    final selection = widget.initialSelection;
    _currentStage = selection.selectedStage;
    _selectedSource = selection.source;
    _selectedCity = selection.city;
    _selectedDateRange = selection.dateRange;
    _customDateFrom = selection.customDateFrom;
    _customDateTo = selection.customDateTo;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x24000000),
                blurRadius: 26,
                offset: Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(22.w, 18.h, 22.w, 18.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Filter',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF1F1C19),
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(
                                Icons.close_rounded,
                                color: const Color(0xFF5F5753),
                                size: 24.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 26.h),
                        _FilterSectionTitle(
                          icon: Icons.source_outlined,
                          label: 'Source',
                        ),
                        SizedBox(height: 12.h),
                        _FilterDropdown(
                          value: _selectedSource,
                          hintText: 'All Sources',
                          options: widget.sourceOptions,
                          onChanged: (value) =>
                              setState(() => _selectedSource = value),
                        ),
                        SizedBox(height: 28.h),
                        _FilterSectionTitle(
                          icon: Icons.location_on_outlined,
                          label: 'City',
                        ),
                        SizedBox(height: 12.h),
                        _FilterDropdown(
                          value: _selectedCity,
                          hintText: 'Any City',
                          options: widget.cityOptions,
                          onChanged: (value) =>
                              setState(() => _selectedCity = value),
                        ),
                        SizedBox(height: 30.h),
                        _FilterSectionTitle(
                          icon: Icons.calendar_month_outlined,
                          label: 'Date Range',
                        ),
                        SizedBox(height: 14.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 10.h,
                          children: [
                            _DateRangeChip(
                              label: 'Today',
                              range: _LeadDateRange.today,
                              selectedRange: _selectedDateRange,
                              onSelected: _selectDateRange,
                            ),
                            _DateRangeChip(
                              label: 'Last 7 Days',
                              range: _LeadDateRange.last7Days,
                              selectedRange: _selectedDateRange,
                              onSelected: _selectDateRange,
                            ),
                            _DateRangeChip(
                              label: 'Last 30 Days',
                              range: _LeadDateRange.last30Days,
                              selectedRange: _selectedDateRange,
                              onSelected: _selectDateRange,
                            ),
                            _FilterChoiceChip(
                              label: 'Custom',
                              trailingIcon: Icons.chevron_right_rounded,
                              selected:
                                  _selectedDateRange == _LeadDateRange.custom,
                              onTap: () => _pickCustomDateRange(context),
                            ),
                          ],
                        ),
                        if (_selectedDateRange == _LeadDateRange.custom) ...[
                          SizedBox(height: 12.h),
                          Text(
                            _customRangeLabel,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF6F6661),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(22.w, 14.h, 22.w, 16.h),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    border: Border(top: BorderSide(color: Color(0xFFF0E2DA))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearFilters,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            minimumSize: Size.fromHeight(54.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'Clear All',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            minimumSize: Size.fromHeight(54.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'Apply Filters',
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String get _customRangeLabel {
    if (_customDateFrom == null && _customDateTo == null) {
      return 'Select custom dates';
    }

    return '${_formatFilterDate(_customDateFrom) ?? 'Any'} - ${_formatFilterDate(_customDateTo) ?? 'Any'}';
  }

  void _selectDateRange(_LeadDateRange range) {
    setState(() {
      _selectedDateRange = range;
      if (range != _LeadDateRange.custom) {
        _customDateFrom = null;
        _customDateTo = null;
      }
    });
  }

  Future<void> _pickCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final initialRange = _customDateFrom == null || _customDateTo == null
        ? null
        : DateTimeRange(start: _customDateFrom!, end: _customDateTo!);
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (pickedRange == null) {
      setState(() => _selectedDateRange = _LeadDateRange.custom);
      return;
    }

    setState(() {
      _selectedDateRange = _LeadDateRange.custom;
      _customDateFrom = pickedRange.start;
      _customDateTo = pickedRange.end;
    });
  }

  void _clearFilters() {
    Navigator.of(context).pop(
      _LeadFilterSelection(
        selectedStage: _currentStage,
        source: null,
        city: null,
        dateRange: _LeadDateRange.any,
        customDateFrom: null,
        customDateTo: null,
      ),
    );
  }

  void _applyFilters() {
    Navigator.of(context).pop(
      _LeadFilterSelection(
        selectedStage: _currentStage,
        source: _selectedSource,
        city: _selectedCity,
        dateRange: _selectedDateRange,
        customDateFrom: _customDateFrom,
        customDateTo: _customDateTo,
      ),
    );
  }

  String? _formatFilterDate(DateTime? date) {
    if (date == null) {
      return null;
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _FilterSectionTitle extends StatelessWidget {
  const _FilterSectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: const Color(0xFF1F1C19)),
        SizedBox(width: 8.w),
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF1F1C19),
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FilterChoiceChip extends StatelessWidget {
  const _FilterChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          height: 38.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFD95F26),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: selected ? AppColors.white : const Color(0xFF1F1C19),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (trailingIcon != null) ...[
                SizedBox(width: 4.w),
                Icon(
                  trailingIcon,
                  size: 18.sp,
                  color: selected ? AppColors.white : const Color(0xFF1F1C19),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DateRangeChip extends StatelessWidget {
  const _DateRangeChip({
    required this.label,
    required this.range,
    required this.selectedRange,
    required this.onSelected,
  });

  final String label;
  final _LeadDateRange range;
  final _LeadDateRange selectedRange;
  final ValueChanged<_LeadDateRange> onSelected;

  @override
  Widget build(BuildContext context) {
    return _FilterChoiceChip(
      label: label,
      selected: range == selectedRange,
      onTap: () => onSelected(range),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.hintText,
    required this.options,
    required this.onChanged,
  });

  final String? value;
  final String hintText;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final currentValue = options.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      isExpanded: true,
      dropdownColor: AppColors.white,
      style: GoogleFonts.inter(
        color: const Color(0xFF1F1C19),
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: const Color(0xFF71757F),
        size: 24.sp,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFFD3D3D3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      hint: Text(
        hintText,
        style: GoogleFonts.inter(
          color: const Color(0xFF1F1C19),
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      items: [
        DropdownMenuItem<String>(
          value: '',
          child: Text(
            hintText,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF1F1C19),
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...options.map(
          (option) => DropdownMenuItem<String>(
            value: option,
            child: Text(
              option,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFF1F1C19),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) =>
          onChanged(value == null || value.isEmpty ? null : value),
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({
    required this.lead,
    required this.canEdit,
    required this.onUpdateStage,
    required this.onEdit,
  });

  final LeadRegistryItem lead;
  final bool canEdit;
  final VoidCallback onUpdateStage;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final assignedTo = lead.assignedTo.trim();
    final hasAssignedName = assignedTo.isNotEmpty && assignedTo != '-';
    final isAssigned = hasAssignedName || lead.assignedToId.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE7DBD5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  lead.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF201D1A),
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusPill(
                    style: _LeadStageStyle.fromStage(lead.stage),
                    label: lead.stage,
                  ),
                  SizedBox(height: 8.h),
                  _AssignmentPill(
                    isAssigned: isAssigned,
                    label: isAssigned ? 'Assigned' : 'Unassigned',
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 13.h),
          _LeadDetailsGrid(
            items: [
              _LeadDetailItem(
                icon: Icons.call_outlined,
                label: 'Phone',
                value: lead.phone,
              ),
              _LeadDetailItem(
                icon: Icons.location_on_outlined,
                label: 'City',
                value: lead.city,
              ),
              _LeadDetailItem(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: lead.email,
              ),
              _LeadDetailItem(
                icon: Icons.source_outlined,
                label: 'Source',
                value: lead.source,
              ),
              _LeadDetailItem(
                icon: Icons.support_agent_rounded,
                label: 'RM',
                value: hasAssignedName ? assignedTo : 'Not assigned',
              ),
              _LeadDetailItem(
                icon: Icons.favorite_border_rounded,
                label: 'Lead For',
                value: lead.leadFor,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(color: const Color(0xFFF0E3DB), height: 1.h),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14.sp,
                color: const Color(0xFF7B736D),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  lead.createdOn == '-'
                      ? 'Created date unavailable'
                      : lead.createdOn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF5E5752),
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              if (!isAssigned && canEdit) ...[
                _AssignLeadButton(onTap: onEdit),
                SizedBox(width: 8.w),
              ],
              _LeadActions(
                canEdit: canEdit,
                onUpdateStage: onUpdateStage,
                onEdit: onEdit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeadActions extends StatelessWidget {
  const _LeadActions({
    required this.canEdit,
    required this.onUpdateStage,
    required this.onEdit,
  });

  final bool canEdit;
  final VoidCallback onUpdateStage;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(
          icon: Icons.fact_check_outlined,
          color: AppColors.black,
          onTap: onUpdateStage,
        ),
        if (canEdit) ...[
          SizedBox(width: 10.w),
          _ActionIcon(
            icon: Icons.edit_outlined,
            color: AppColors.black,
            onTap: onEdit,
          ),
        ],
      ],
    );
  }
}

class _AssignmentPill extends StatelessWidget {
  const _AssignmentPill({required this.isAssigned, required this.label});

  final bool isAssigned;
  final String label;

  @override
  Widget build(BuildContext context) {
    final background = isAssigned
        ? const Color(0xFFEFFAF5)
        : const Color(0xFFFFF5F0);
    final border = isAssigned
        ? const Color(0xFFBEEAD5)
        : const Color(0xFFFFD8C8);
    final foreground = isAssigned
        ? const Color(0xFF157A4B)
        : const Color(0xFFB24D23);

    return Container(
      height: 28.h,
      padding: EdgeInsets.symmetric(horizontal: 9.w),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9.r),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAssigned ? Icons.check_circle_outline : Icons.person_off_outlined,
            size: 13.sp,
            color: foreground,
          ),
          SizedBox(width: 5.w),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: foreground,
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignLeadButton extends StatelessWidget {
  const _AssignLeadButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9.r),
        child: Container(
          height: 28.h,
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(color: AppColors.primary),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_add_alt_1_outlined,
                size: 13.sp,
                color: AppColors.white,
              ),
              SizedBox(width: 5.w),
              Text(
                'Assign',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.color, this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: SizedBox(
        width: 24.w,
        height: 24.h,
        child: Icon(icon, size: 22.sp, color: color),
      ),
    );
  }
}

class _LeadDetailsGrid extends StatelessWidget {
  const _LeadDetailsGrid({required this.items});

  final List<_LeadDetailItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF8),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFF0E3DB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columnWidth = (constraints.maxWidth - 10.w) / 2;

          return Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: items
                .map(
                  (item) => SizedBox(
                    width: columnWidth,
                    child: _LeadDetailBlock(item: item),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _LeadDetailItem {
  const _LeadDetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _LeadDetailBlock extends StatelessWidget {
  const _LeadDetailBlock({required this.item});

  final _LeadDetailItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24.r,
          height: 24.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: const Color(0xFFE8DCD5)),
          ),
          child: Icon(item.icon, size: 13.sp, color: AppColors.primary),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF736A64),
                  fontSize: 10.8.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                item.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF1F1C19),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.style, required this.label});

  final _LeadStageStyle style;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = style.colors;

    return Container(
      height: 30.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(9.r),
        border: Border.all(color: colors.border),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: colors.text,
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ArchiveInsightCard extends StatelessWidget {
  const _ArchiveInsightCard({
    required this.totalLeads,
    required this.filteredLeads,
  });

  final int totalLeads;
  final int filteredLeads;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEEDFD5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Archive Insight',
            style: GoogleFonts.inter(
              color: const Color(0xFF22201D),
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Lead Distribution Snapshot',
            style: GoogleFonts.inter(
              color: const Color(0xFF272420),
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'The registry now reflects actual lead records from the backend. Showing $filteredLeads curated lead${filteredLeads == 1 ? '' : 's'} from a live archive of $totalLeads records.',
            style: GoogleFonts.inter(
              color: const Color(0xFF5C5753),
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'View Analysis ->',
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CuratorMilestoneCard extends StatelessWidget {
  const _CuratorMilestoneCard({
    required this.totalLeads,
    required this.convertedCount,
  });

  final int totalLeads;
  final int convertedCount;

  @override
  Widget build(BuildContext context) {
    final progress = totalLeads == 0 ? 0.0 : convertedCount / totalLeads;
    final percentage = (progress * 100).round().clamp(0, 100);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 18.h),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Curator's Milestone",
                  style: GoogleFonts.inter(
                    color: AppColors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.workspace_premium_outlined,
                color: AppColors.white,
                size: 20.sp,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Lead intake is now mapped directly to the registry schema, ensuring archival fidelity across active branches.',
            style: GoogleFonts.inter(
              color: AppColors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Archive Goal',
                  style: GoogleFonts.inter(
                    color: AppColors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: GoogleFonts.inter(
                  color: AppColors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(99.r),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 8.h,
              backgroundColor: const Color(0xFFA94F11),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageFilter {
  const _StageFilter({
    required this.label,
    this.count,
    this.dotColor,
    this.icon,
  });

  final String label;
  final int? count;
  final Color? dotColor;
  final IconData? icon;
}

enum _LeadStageStyle {
  newLead(
    _StageColors(
      background: Color(0xFFF3F5F7),
      border: Color(0xFFD8DEE6),
      dot: Color(0xFFB6BEC8),
      text: Color(0xFF5E6670),
    ),
  ),
  contacted(
    _StageColors(
      background: Color(0xFFFFF7DE),
      border: Color(0xFFFFCD55),
      dot: Color(0xFFFFA000),
      text: Color(0xFF8B6200),
    ),
  ),
  interested(
    _StageColors(
      background: Color(0xFFEAF4FF),
      border: Color(0xFFBEDCFF),
      dot: Color(0xFF338AF3),
      text: Color(0xFF1E63B6),
    ),
  ),
  converted(
    _StageColors(
      background: Color(0xFFEAFBF4),
      border: Color(0xFFBCECD7),
      dot: Color(0xFF22B883),
      text: Color(0xFF13795A),
    ),
  );

  const _LeadStageStyle(this.colors);

  final _StageColors colors;

  static _LeadStageStyle fromStage(dynamic stage) {
    final normalized = stage?.toString().toUpperCase().replaceAll(' ', '_');

    switch (normalized) {
      case 'CONVERTED':
        return _LeadStageStyle.converted;
      case 'INTERESTED':
        return _LeadStageStyle.interested;
      case 'CONTACTED':
      case 'FOLLOW_UP_DUE':
        return _LeadStageStyle.contacted;
      case 'NEW':
      default:
        return _LeadStageStyle.newLead;
    }
  }
}

class _StageColors {
  const _StageColors({
    required this.background,
    required this.border,
    required this.dot,
    required this.text,
  });

  final Color background;
  final Color border;
  final Color dot;
  final Color text;
}
