import 'dart:async';

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
  _LeadsView _selectedView = _LeadsView.registry;
  String? _selectedSource;
  String? _selectedCity;
  String? _selectedAssignee;
  _LeadDateRange _selectedDateRange = _LeadDateRange.any;
  DateTime? _customDateFrom;
  DateTime? _customDateTo;
  bool _hasRequestedLeads = false;
  String? _requestedAccessToken;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;
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
      _StageFilter(label: 'All Registry', count: leads.length),
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

      if (!_matchesOptionalFilter(lead.assignedTo, _selectedAssignee)) {
        return false;
      }

      return _matchesDateRange(lead.createdOn);
    }).toList();
  }

  bool _matchesSearch(LeadRegistryItem lead, String query) {
    if (query.trim().isEmpty) {
      return true;
    }

    final normalized = query.trim().toLowerCase();
    return lead.searchIndex.contains(normalized);
  }

  String _stageKey(String stage) {
    return stage.toUpperCase().replaceAll(' ', '_');
  }

  bool _matchesOptionalFilter(String value, String? selectedValue) {
    return selectedValue == null || value.trim() == selectedValue.trim();
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
    if (_selectedAssignee != null) count++;
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

  Future<void> _showLeadFiltersSheet(
    List<LeadRegistryItem> leads,
    List<_StageFilter> stageFilters,
  ) async {
    final result = await showModalBottomSheet<_LeadFilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) {
        return _LeadFiltersBottomSheet(
          stageFilters: stageFilters,
          sourceOptions: _filterOptions(leads, (lead) => lead.source),
          cityOptions: _filterOptions(leads, (lead) => lead.city),
          assigneeOptions: _filterOptions(leads, (lead) => lead.assignedTo),
          initialSelection: _LeadFilterSelection(
            selectedStage: _selectedStage,
            source: _selectedSource,
            city: _selectedCity,
            assignee: _selectedAssignee,
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
      _selectedStage = result.selectedStage;
      _selectedSource = result.source;
      _selectedCity = result.city;
      _selectedAssignee = result.assignee;
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
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leadsProvider = context.watch<LeadsProvider>();
    final authProvider = context.watch<AuthProvider>();
    final leads = leadsProvider.leads;
    final stageFilters = _stageFilters(leads);
    final sourceOptions = _filterOptions(leads, (lead) => lead.source);
    final cityOptions = _filterOptions(leads, (lead) => lead.city);
    final assigneeOptions = _filterOptions(leads, (lead) => lead.assignedTo);
    final stageScopedLeads = _visibleLeads(leads, stageFilters);
    final visibleLeads = stageScopedLeads
        .where((lead) => _matchesSearch(lead, _searchQuery))
        .toList();
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
                    _LeadsSearchField(
                      controller: _searchController,
                      onChanged: (value) {
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(
                          const Duration(milliseconds: 220),
                          () {
                            if (!mounted) {
                              return;
                            }

                            setState(() {
                              _searchQuery = value;
                              _registryLeadLimit = _registryPreviewCount;
                            });
                          },
                        );
                      },
                    ),
                    SizedBox(height: 16.h),
                    _LeadsViewTabs(
                      selectedView: _selectedView,
                      onSelected: (view) =>
                          setState(() => _selectedView = view),
                    ),
                    SizedBox(height: 22.h),
                    if (_selectedView == _LeadsView.registry) ...[
                      _FilterHeader(
                        activeFilterCount: _activeFilterCount,
                        onFilterPressed: () =>
                            _showLeadFiltersSheet(leads, stageFilters),
                      ),
                      SizedBox(height: 10.h),
                      _StageFilterList(
                        filters: stageFilters,
                        selectedIndex: _selectedStage,
                        onSelected: (index) {
                          setState(() {
                            _selectedStage = index;
                            _registryLeadLimit = _registryPreviewCount;
                          });
                        },
                      ),
                      SizedBox(height: 18.h),
                      _LeadsInlineFilters(
                        sourceOptions: sourceOptions,
                        cityOptions: cityOptions,
                        assigneeOptions: assigneeOptions,
                        selectedSource: _selectedSource,
                        selectedCity: _selectedCity,
                        selectedAssignee: _selectedAssignee,
                        onSourceChanged: (value) {
                          setState(() {
                            _selectedSource = value;
                            _registryLeadLimit = _registryPreviewCount;
                          });
                        },
                        onCityChanged: (value) {
                          setState(() {
                            _selectedCity = value;
                            _registryLeadLimit = _registryPreviewCount;
                          });
                        },
                        onAssigneeChanged: (value) {
                          setState(() {
                            _selectedAssignee = value;
                            _registryLeadLimit = _registryPreviewCount;
                          });
                        },
                      ),
                      SizedBox(height: 18.h),
                      _LeadsContent(
                        isLoading: leadsProvider.isLoading,
                        error: leadsProvider.error,
                        leads: registryPreviewLeads,
                        totalLeadCount: visibleLeads.length,
                        isExpanded: registryVisibleLimit >= visibleLeads.length,
                        onToggleExpanded:
                            visibleLeads.length > _registryPreviewCount
                            ? () => setState(() {
                                if (registryVisibleLimit >=
                                    visibleLeads.length) {
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
                        isRemovingLead: leadsProvider.isRemovingLead,
                        canEditLead: canEditLeads,
                        onEditLead: (lead) =>
                            _showEditLeadDialog(context, lead),
                        onDeleteLead: (lead) => _handleDeleteLead(
                          context,
                          lead,
                          authProvider.userModel?.accessToken,
                        ),
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
                    ] else if (_selectedView == _LeadsView.pipeline)
                      _LeadsPipelineContent(
                        isLoading: leadsProvider.isLoading,
                        error: leadsProvider.error,
                        leads: visibleLeads,
                        onFiltersPressed: () =>
                            _showLeadFiltersSheet(leads, stageFilters),
                        onViewAllPressed: () {
                          setState(() => _selectedView = _LeadsView.registry);
                        },
                        onRetry: () => context.read<LeadsProvider>().retry(),
                      )
                    else
                      _LeadsHubContent(
                        isLoading: leadsProvider.isLoading,
                        error: leadsProvider.error,
                        leads: visibleLeads,
                        onFiltersPressed: () =>
                            _showLeadFiltersSheet(leads, stageFilters),
                        onViewAllPressed: () {
                          setState(() => _selectedView = _LeadsView.registry);
                        },
                        onRetry: () => context.read<LeadsProvider>().retry(),
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

  Future<void> _handleDeleteLead(
    BuildContext context,
    LeadRegistryItem lead,
    String? accessToken,
  ) async {
    final confirmed = await _confirmDelete(context, lead);
    if (confirmed != true || !context.mounted) {
      return;
    }

    debugPrint('Delete confirmed for lead id=${lead.id}');
    final message = await context.read<LeadsProvider>().deleteLead(
      lead,
      accessToken,
    );

    if (!context.mounted) {
      return;
    }

    _showSnackBar(
      context,
      message ?? 'Lead deleted successfully.',
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

  Future<bool?> _confirmDelete(BuildContext context, LeadRegistryItem lead) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Delete Lead',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800),
          ),
          content: Text(
            lead.id.isNotEmpty
                ? 'Are you sure you want to delete ${lead.name}? This action cannot be undone.'
                : 'This lead does not include a lead id yet, so the delete API cannot be called.',
            style: GoogleFonts.inter(height: 1.45),
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
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(lead.id.isNotEmpty),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD1213E),
                foregroundColor: Colors.white,
              ),
              child: Text(
                lead.id.isNotEmpty ? 'Yes, Delete' : 'Close',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
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
    required this.isRemovingLead,
    required this.canEditLead,
    required this.onEditLead,
    required this.onDeleteLead,
  });

  final bool isLoading;
  final String? error;
  final List<LeadRegistryItem> leads;
  final int totalLeadCount;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;
  final VoidCallback onRetry;
  final bool Function(LeadRegistryItem lead) isRemovingLead;
  final bool canEditLead;
  final ValueChanged<LeadRegistryItem> onEditLead;
  final ValueChanged<LeadRegistryItem> onDeleteLead;

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
              isDeleting: isRemovingLead(leads[index]),
              canEdit: canEditLead,
              onEdit: () => onEditLead(leads[index]),
              onDelete: () => onDeleteLead(leads[index]),
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
          '+ New Inquiry',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LeadsSearchField extends StatelessWidget {
  const _LeadsSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFEEDFD5)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          color: const Color(0xFF1B1B1B),
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: const Color(0xFF7A7370),
            size: 23.sp,
          ),
          hintText: 'Search by name, phone, email, city, note, or executive',
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFF8B8684),
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 14.h),
        ),
      ),
    );
  }
}

class _LeadsViewTabs extends StatelessWidget {
  const _LeadsViewTabs({required this.selectedView, required this.onSelected});

  final _LeadsView selectedView;
  final ValueChanged<_LeadsView> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _LeadsTab(
            label: 'Registry View',
            selected: selectedView == _LeadsView.registry,
            onTap: () => onSelected(_LeadsView.registry),
          ),
          SizedBox(width: 10.w),
          _LeadsTab(
            label: 'Pipeline Board',
            selected: selectedView == _LeadsView.pipeline,
            onTap: () => onSelected(_LeadsView.pipeline),
          ),
          SizedBox(width: 10.w),
          _LeadsTab(
            label: 'Communication Hub',
            selected: selectedView == _LeadsView.hub,
            onTap: () => onSelected(_LeadsView.hub),
          ),
        ],
      ),
    );
  }
}

class _LeadsTab extends StatelessWidget {
  const _LeadsTab({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          height: 34.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : AppColors.transparent,
            borderRadius: BorderRadius.circular(18.r),
            border: selected
                ? Border.all(color: AppColors.primary, width: 1)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF282623),
              fontSize: 13.sp,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

enum _LeadsView { registry, pipeline, hub }

class _LeadsPipelineContent extends StatelessWidget {
  const _LeadsPipelineContent({
    required this.isLoading,
    required this.error,
    required this.leads,
    required this.onFiltersPressed,
    required this.onViewAllPressed,
    required this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final List<LeadRegistryItem> leads;
  final VoidCallback onFiltersPressed;
  final VoidCallback onViewAllPressed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _LeadQueuePreviewSection(
      isLoading: isLoading,
      error: error,
      emptyMessage: 'No pipeline leads found.',
      leads: leads,
      onFiltersPressed: onFiltersPressed,
      onViewAllPressed: onViewAllPressed,
      onRetry: onRetry,
    );
  }
}

class _LeadsHubContent extends StatelessWidget {
  const _LeadsHubContent({
    required this.isLoading,
    required this.error,
    required this.leads,
    required this.onFiltersPressed,
    required this.onViewAllPressed,
    required this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final List<LeadRegistryItem> leads;
  final VoidCallback onFiltersPressed;
  final VoidCallback onViewAllPressed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _LeadQueuePreviewSection(
      isLoading: isLoading,
      error: error,
      emptyMessage: 'No communication leads found.',
      leads: leads,
      onFiltersPressed: onFiltersPressed,
      onViewAllPressed: onViewAllPressed,
      onRetry: onRetry,
    );
  }
}

class _LeadQueuePreviewSection extends StatelessWidget {
  const _LeadQueuePreviewSection({
    required this.isLoading,
    required this.error,
    required this.emptyMessage,
    required this.leads,
    required this.onFiltersPressed,
    required this.onViewAllPressed,
    required this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final String emptyMessage;
  final List<LeadRegistryItem> leads;
  final VoidCallback onFiltersPressed;
  final VoidCallback onViewAllPressed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 28.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return _LeadsMessage(
        message: error!,
        actionLabel: 'Retry',
        onActionPressed: onRetry,
      );
    }

    if (leads.isEmpty) {
      return _LeadsMessage(message: emptyMessage);
    }

    final previewLeads = leads.take(2).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'FILTER BY STAGE',
                style: GoogleFonts.inter(
                  color: AppColors.titleColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
            ),
            SizedBox(
              height: 34.h,
              child: OutlinedButton.icon(
                onPressed: onFiltersPressed,
                icon: Icon(
                  Icons.tune_rounded,
                  size: 17.sp,
                  color: AppColors.titleColor,
                ),
                label: Text(
                  'Filters',
                  style: GoogleFonts.inter(
                    color: AppColors.titleColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        for (var index = 0; index < previewLeads.length; index++) ...[
          _LeadQueuePreviewCard(lead: previewLeads[index]),
          if (index != previewLeads.length - 1) SizedBox(height: 14.h),
        ],
        if (leads.length > previewLeads.length) ...[
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            height: 46.h,
            child: OutlinedButton(
              onPressed: onViewAllPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Text(
                'View All Leads ->',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LeadQueuePreviewCard extends StatelessWidget {
  const _LeadQueuePreviewCard({required this.lead});

  final LeadRegistryItem lead;

  @override
  Widget build(BuildContext context) {
    final initial = lead.initials.isEmpty ? 'M' : lead.initials[0];
    final reason = lead.reason.trim();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 10.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5DAD3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7EFE8),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE8DDD4)),
                ),
                child: Text(
                  initial,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF8A4A1C),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  lead.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1F1E1D),
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              _StatusPill(
                style: _LeadStageStyle.fromStage(lead.stage),
                label: lead.stage.toUpperCase(),
              ),
            ],
          ),
          SizedBox(height: 13.h),
          Row(
            children: [
              Icon(
                Icons.phone_outlined,
                color: const Color(0xFF1F1E1D),
                size: 13.sp,
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  lead.phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1F1E1D),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LeadQueueInfo(label: 'Source', value: lead.source),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _LeadQueueInfo(label: 'City', value: lead.city),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _LeadQueueInfo(label: 'Email', value: lead.email),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LeadQueueInfo(
                  label: 'Assigned To',
                  value: lead.assignedTo,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _LeadQueueInfo(label: 'Created', value: lead.createdOn),
              ),
            ],
          ),
          if (reason.isNotEmpty && reason != '-') ...[
            SizedBox(height: 13.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2ED),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Reason: $reason',
                style: GoogleFonts.inter(
                  color: const Color(0xFF3A3330),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LeadQueueInfo extends StatelessWidget {
  const _LeadQueueInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF6C6460),
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            height: 1.1,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: const Color(0xFF1F1E1D),
            fontSize: 13.sp,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _FilterHeader extends StatelessWidget {
  const _FilterHeader({
    required this.activeFilterCount,
    required this.onFilterPressed,
  });

  final int activeFilterCount;
  final VoidCallback onFilterPressed;

  @override
  Widget build(BuildContext context) {
    final filterLabel = activeFilterCount == 0
        ? 'Filters'
        : 'Filters ($activeFilterCount)';

    return Row(
      children: [
        Expanded(
          child: Text(
            'FILTER BY STAGE',
            style: GoogleFonts.inter(
              color: const Color(0xFF2F2C29),
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onFilterPressed,
          icon: Icon(Icons.tune_rounded, size: 18.sp),
          label: Text(
            filterLabel,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            minimumSize: Size(86.w, 36.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeadsInlineFilters extends StatelessWidget {
  const _LeadsInlineFilters({
    required this.sourceOptions,
    required this.cityOptions,
    required this.assigneeOptions,
    required this.selectedSource,
    required this.selectedCity,
    required this.selectedAssignee,
    required this.onSourceChanged,
    required this.onCityChanged,
    required this.onAssigneeChanged,
  });

  final List<String> sourceOptions;
  final List<String> cityOptions;
  final List<String> assigneeOptions;
  final String? selectedSource;
  final String? selectedCity;
  final String? selectedAssignee;
  final ValueChanged<String?> onSourceChanged;
  final ValueChanged<String?> onCityChanged;
  final ValueChanged<String?> onAssigneeChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 680.w;
        final itemWidth = isWide
            ? (constraints.maxWidth - 24.w) / 3
            : constraints.maxWidth;

        return Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: [
            SizedBox(
              width: itemWidth,
              child: _LeadInlineDropdown(
                label: 'Source',
                hintText: 'All Sources',
                value: selectedSource,
                options: sourceOptions,
                onChanged: onSourceChanged,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _LeadInlineDropdown(
                label: 'City',
                hintText: 'Any City',
                value: selectedCity,
                options: cityOptions,
                onChanged: onCityChanged,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _LeadInlineDropdown(
                label: 'Executive',
                hintText: 'All Executives',
                value: selectedAssignee,
                options: assigneeOptions,
                onChanged: onAssigneeChanged,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LeadInlineDropdown extends StatelessWidget {
  const _LeadInlineDropdown({
    required this.label,
    required this.hintText,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String hintText;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final currentValue = options.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF1F1C19),
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 7.h),
        DropdownButtonFormField<String>(
          initialValue: currentValue,
          isExpanded: true,
          dropdownColor: AppColors.white,
          style: GoogleFonts.inter(
            color: const Color(0xFF1F1C19),
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: const Color(0xFF8B8784),
            size: 18.sp,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.white,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 13.w,
              vertical: 12.h,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFFEEDFD5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFFEEDFD5)),
            ),
          ),
          hint: Text(
            hintText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF77716C),
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          items: [
            DropdownMenuItem<String>(
              value: '',
              child: Text(
                hintText,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF77716C),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
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
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
          onChanged: (value) =>
              onChanged(value == null || value.isEmpty ? null : value),
        ),
      ],
    );
  }
}

enum _LeadDateRange { any, today, last7Days, last30Days, custom }

class _LeadFilterSelection {
  const _LeadFilterSelection({
    required this.selectedStage,
    required this.source,
    required this.city,
    required this.assignee,
    required this.dateRange,
    required this.customDateFrom,
    required this.customDateTo,
  });

  final int selectedStage;
  final String? source;
  final String? city;
  final String? assignee;
  final _LeadDateRange dateRange;
  final DateTime? customDateFrom;
  final DateTime? customDateTo;
}

class _LeadFiltersBottomSheet extends StatefulWidget {
  const _LeadFiltersBottomSheet({
    required this.stageFilters,
    required this.sourceOptions,
    required this.cityOptions,
    required this.assigneeOptions,
    required this.initialSelection,
  });

  final List<_StageFilter> stageFilters;
  final List<String> sourceOptions;
  final List<String> cityOptions;
  final List<String> assigneeOptions;
  final _LeadFilterSelection initialSelection;

  @override
  State<_LeadFiltersBottomSheet> createState() =>
      _LeadFiltersBottomSheetState();
}

class _LeadFiltersBottomSheetState extends State<_LeadFiltersBottomSheet> {
  late int _selectedStage;
  String? _selectedSource;
  String? _selectedCity;
  String? _selectedAssignee;
  late _LeadDateRange _selectedDateRange;
  DateTime? _customDateFrom;
  DateTime? _customDateTo;

  @override
  void initState() {
    super.initState();
    final selection = widget.initialSelection;
    _selectedStage = selection.selectedStage;
    _selectedSource = selection.source;
    _selectedCity = selection.city;
    _selectedAssignee = selection.assignee;
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
                          icon: Icons.flag_outlined,
                          label: 'Stage',
                        ),
                        SizedBox(height: 14.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 10.h,
                          children: [
                            for (
                              int index = 0;
                              index < widget.stageFilters.length;
                              index++
                            )
                              _FilterChoiceChip(
                                label: index == 0
                                    ? 'All'
                                    : widget.stageFilters[index].label,
                                selected: _selectedStage == index,
                                onTap: () =>
                                    setState(() => _selectedStage = index),
                              ),
                          ],
                        ),
                        SizedBox(height: 30.h),
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
                        SizedBox(height: 28.h),
                        _FilterSectionTitle(
                          icon: Icons.manage_accounts_outlined,
                          label: 'Assigned To',
                        ),
                        SizedBox(height: 12.h),
                        _FilterDropdown(
                          value: _selectedAssignee,
                          hintText: 'All Executives',
                          options: widget.assigneeOptions,
                          onChanged: (value) =>
                              setState(() => _selectedAssignee = value),
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
                              fontSize: 14.sp,
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
      const _LeadFilterSelection(
        selectedStage: 0,
        source: null,
        city: null,
        assignee: null,
        dateRange: _LeadDateRange.any,
        customDateFrom: null,
        customDateTo: null,
      ),
    );
  }

  void _applyFilters() {
    Navigator.of(context).pop(
      _LeadFilterSelection(
        selectedStage: _selectedStage,
        source: _selectedSource,
        city: _selectedCity,
        assignee: _selectedAssignee,
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

class _StageFilterList extends StatelessWidget {
  const _StageFilterList({
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
          for (int index = 0; index < filters.length; index++) ...[
            _StageChip(
              filter: filters[index],
              selected: index == selectedIndex,
              onTap: () => onSelected(index),
            ),
            if (index != filters.length - 1) SizedBox(width: 10.w),
          ],
        ],
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final _StageFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDot = filter.dotColor != null;
    final icon = filter.icon;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          height: 30.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE5CFC0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!selected && hasDot) ...[
                if (icon == null)
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: filter.dotColor,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  Icon(icon, color: filter.dotColor, size: 13.sp),
                SizedBox(width: 8.w),
              ],
              Text(
                filter.label,
                style: GoogleFonts.inter(
                  color: selected ? AppColors.white : const Color(0xFF4C4744),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (filter.count != null) ...[
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.white : const Color(0xFFFFF6F1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    '${filter.count}',
                    style: GoogleFonts.inter(
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFF6B6662),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({
    required this.lead,
    required this.isDeleting,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  final LeadRegistryItem lead;
  final bool isDeleting;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
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
              _StatusPill(
                style: _LeadStageStyle.fromStage(lead.stage),
                label: lead.stage,
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LeadDetailBlock(label: 'Phone', value: lead.phone),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _LeadDetailBlock(label: 'City', value: lead.city),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _LeadDetailBlock(label: 'Email', value: lead.email),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LeadDetailBlock(
                  label: 'Assigned To',
                  value: lead.assignedTo,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _LeadDetailBlock(label: 'Source', value: lead.source),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Divider(color: const Color(0xFFF0E3DB), height: 1.h),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Created: ${lead.createdOn}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF2A2825),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _LeadActions(
                isDeleting: isDeleting,
                canEdit: canEdit,
                onEdit: onEdit,
                onDelete: onDelete,
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
    required this.isDeleting,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  final bool isDeleting;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(icon: Icons.swap_horiz_rounded, color: AppColors.black),
        SizedBox(width: 12.w),
        if (canEdit) ...[
          _ActionIcon(icon: Icons.edit, color: AppColors.black, onTap: onEdit),
          SizedBox(width: 12.w),
        ],
        _ActionIcon(
          icon: Icons.delete_outline,
          color: const Color(0xFFD1213E),
          onTap: isDeleting ? null : onDelete,
          isLoading: isDeleting,
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.color,
    this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: SizedBox(
        width: 24.w,
        height: 24.h,
        child: isLoading
            ? Padding(
                padding: EdgeInsets.all(2.r),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            : Icon(icon, size: 22.sp, color: color),
      ),
    );
  }
}

class _LeadDetailBlock extends StatelessWidget {
  const _LeadDetailBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF66615D),
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: const Color(0xFF1D1B18),
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            height: 1.25,
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
