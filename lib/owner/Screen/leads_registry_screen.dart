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
  });

  final bool showScaffold;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final body = _LeadsRegistryBody(onMenuPressed: onMenuPressed);

    if (!showScaffold) {
      return ColoredBox(color: AppColors.rmSoftPink, child: body);
    }

    return Scaffold(backgroundColor: AppColors.rmSoftPink, body: body);
  }
}

class _LeadsRegistryBody extends StatefulWidget {
  const _LeadsRegistryBody({this.onMenuPressed});

  final VoidCallback? onMenuPressed;

  @override
  State<_LeadsRegistryBody> createState() => _LeadsRegistryBodyState();
}

class _LeadsRegistryBodyState extends State<_LeadsRegistryBody> {
  static const List<String> _leadForOptions = ['Groom', 'Bride'];
  int _selectedStage = 0;
  _LeadsView _selectedView = _LeadsView.registry;
  bool _hasRequestedLeads = false;
  String? _requestedAccessToken;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showAllRegistryLeads = false;

  List<_StageFilter> _stageFilters(List<LeadRegistryItem> leads) => [
    _StageFilter(label: 'All Registry', count: leads.length),
    _StageFilter(
      label: 'New',
      count: _countLeadsForStage(leads, 'NEW'),
      dotColor: const Color(0xFFB6BEC8),
    ),
    _StageFilter(
      label: 'Contacted',
      count: _countLeadsForStage(leads, 'CONTACTED'),
      dotColor: const Color(0xFFFFA000),
    ),
    _StageFilter(
      label: 'Interested',
      count: _countLeadsForStage(leads, 'INTERESTED'),
      dotColor: const Color(0xFF338AF3),
    ),
    _StageFilter(
      label: 'Converted',
      count: _countLeadsForStage(leads, 'CONVERTED'),
      dotColor: const Color(0xFF22B883),
    ),
  ];

  List<LeadRegistryItem> _visibleLeads(
    List<LeadRegistryItem> leads,
    List<_StageFilter> stageFilters,
  ) {
    if (_selectedStage == 0) {
      return leads;
    }

    final selectedStage = _stageKey(stageFilters[_selectedStage].label);
    return leads
        .where((lead) => _stageKey(lead.stage) == selectedStage)
        .toList();
  }

  int _countLeadsForStage(List<LeadRegistryItem> leads, String stage) {
    return leads.where((lead) => _stageKey(lead.stage) == stage).length;
  }

  bool _matchesSearch(LeadRegistryItem lead, String query) {
    if (query.trim().isEmpty) {
      return true;
    }

    final normalized = query.trim().toLowerCase();
    final haystack = <String>[
      lead.name,
      lead.phone,
      lead.email,
      lead.city,
      lead.assignedTo,
      lead.source,
      lead.stage,
      lead.leadFor,
    ].join(' ').toLowerCase();

    return haystack.contains(normalized);
  }

  String _stageKey(String stage) {
    return stage.toUpperCase().replaceAll(' ', '_');
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leadsProvider = context.watch<LeadsProvider>();
    final authProvider = context.watch<AuthProvider>();
    final leads = leadsProvider.leads;
    final stageFilters = _stageFilters(leads);
    final stageScopedLeads = _visibleLeads(leads, stageFilters);
    final visibleLeads = stageScopedLeads
        .where((lead) => _matchesSearch(lead, _searchQuery))
        .toList();
    final canEditLeads = _canEditLeads(authProvider.userModel?.user?.role);
    final convertedCount = _countLeadsForStage(leads, 'CONVERTED');
    final registryPreviewLeads = _showAllRegistryLeads
        ? visibleLeads
        : visibleLeads.take(3).toList();

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
                        setState(() {
                          _searchQuery = value;
                          _showAllRegistryLeads = false;
                        });
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
                      _FilterHeader(onFilterPressed: () {}),
                      SizedBox(height: 10.h),
                      _StageFilterList(
                        filters: stageFilters,
                        selectedIndex: _selectedStage,
                        onSelected: (index) {
                          setState(() {
                            _selectedStage = index;
                            _showAllRegistryLeads = false;
                          });
                        },
                      ),
                      SizedBox(height: 18.h),
                      _LeadsContent(
                        isLoading: leadsProvider.isLoading,
                        error: leadsProvider.error,
                        leads: registryPreviewLeads,
                        totalLeadCount: visibleLeads.length,
                        isExpanded: _showAllRegistryLeads,
                        onToggleExpanded: visibleLeads.length > 3
                            ? () => setState(
                                () => _showAllRegistryLeads =
                                    !_showAllRegistryLeads,
                              )
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
                        leads: leads,
                        filters: stageFilters,
                        onRetry: () => context.read<LeadsProvider>().retry(),
                      )
                    else
                      _LeadsHubContent(
                        isLoading: leadsProvider.isLoading,
                        error: leadsProvider.error,
                        leads: leads,
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
                                    style: GoogleFonts.manrope(
                                      color: const Color(0xFF1F1C19),
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Update the lead details and assignment information.',
                                    style: GoogleFonts.manrope(
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
                                  style: GoogleFonts.manrope(
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
                                  style: GoogleFonts.manrope(
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
            style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
          ),
          content: Text(
            lead.id.isNotEmpty
                ? 'Are you sure you want to delete ${lead.name}? This action cannot be undone.'
                : 'This lead does not include a lead id yet, so the delete API cannot be called.',
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
                  Navigator.of(dialogContext).pop(lead.id.isNotEmpty),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD1213E),
                foregroundColor: Colors.white,
              ),
              child: Text(
                lead.id.isNotEmpty ? 'Yes, Delete' : 'Close',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
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
                  isExpanded ? 'Show Less' : 'View All Leads ->',
                  style: GoogleFonts.manrope(
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
                  style: GoogleFonts.manrope(
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
      style: GoogleFonts.manrope(
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
              style: GoogleFonts.manrope(
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
                style: GoogleFonts.manrope(
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
          style: GoogleFonts.manrope(
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
      decoration: _editLeadDecoration('Assigned To'),
      hint: Text(
        fallbackLabel.isEmpty ? 'Select relationship manager' : fallbackLabel,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.manrope(
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
                style: GoogleFonts.manrope(
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
    labelStyle: GoogleFonts.manrope(
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
            style: GoogleFonts.manrope(
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
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
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
                  style: GoogleFonts.playfairDisplay(
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
                style: GoogleFonts.manrope(
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
          style: GoogleFonts.manrope(
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
        style: GoogleFonts.manrope(
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
          hintStyle: GoogleFonts.manrope(
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
            label: 'Communication',
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
            style: GoogleFonts.manrope(
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
    required this.filters,
    required this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final List<LeadRegistryItem> leads;
  final List<_StageFilter> filters;
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
      return const _LeadsMessage(message: 'No pipeline leads found.');
    }

    final activeFilters = filters.skip(1).toList();
    final maxCount = activeFilters.fold<int>(
      1,
      (max, filter) => (filter.count ?? 0) > max ? filter.count! : max,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LEAD PIPELINE',
          style: GoogleFonts.manrope(
            color: const Color(0xFF706368),
            fontSize: 14.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: .6,
          ),
        ),
        SizedBox(height: 10.h),
        for (final filter in activeFilters) ...[
          _PipelineStageCard(
            filter: filter,
            progress: (filter.count ?? 0) / maxCount,
          ),
          SizedBox(height: 12.h),
        ],
      ],
    );
  }
}

class _PipelineStageCard extends StatelessWidget {
  const _PipelineStageCard({required this.filter, required this.progress});

  final _StageFilter filter;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final count = filter.count ?? 0;
    final accent = filter.dotColor ?? AppColors.rmPrimary;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  filter.label,
                  style: GoogleFonts.manrope(
                    color: AppColors.rmHeading,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$count leads',
                style: GoogleFonts.manrope(
                  color: AppColors.rmPrimary,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1).toDouble(),
              minHeight: 8.h,
              backgroundColor: const Color(0xFFF4E6EB),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadsHubContent extends StatelessWidget {
  const _LeadsHubContent({
    required this.isLoading,
    required this.error,
    required this.leads,
    required this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final List<LeadRegistryItem> leads;
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
      return const _LeadsMessage(message: 'No lead hub activity found.');
    }

    final groups = <String, List<LeadRegistryItem>>{};
    for (final lead in leads) {
      final owner = lead.assignedTo == '-' ? 'Unassigned' : lead.assignedTo;
      groups.putIfAbsent(owner, () => <LeadRegistryItem>[]).add(lead);
    }
    final entries = groups.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LEAD HUB',
          style: GoogleFonts.manrope(
            color: const Color(0xFF706368),
            fontSize: 14.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: .6,
          ),
        ),
        SizedBox(height: 10.h),
        for (final entry in entries) ...[
          _LeadHubCard(owner: entry.key, leads: entry.value),
          SizedBox(height: 12.h),
        ],
      ],
    );
  }
}

class _LeadHubCard extends StatelessWidget {
  const _LeadHubCard({required this.owner, required this.leads});

  final String owner;
  final List<LeadRegistryItem> leads;

  @override
  Widget build(BuildContext context) {
    final latestLead = leads.first;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: const Color(0xFFF7D9E3),
            child: Icon(
              Icons.support_agent_rounded,
              color: AppColors.rmPrimary,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  owner,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: AppColors.rmHeading,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Latest: ${latestLead.name} - ${latestLead.stage}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF6F5F64),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            '${leads.length}',
            style: GoogleFonts.manrope(
              color: AppColors.rmPrimary,
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterHeader extends StatelessWidget {
  const _FilterHeader({required this.onFilterPressed});

  final VoidCallback onFilterPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'FILTER BY STAGE',
            style: GoogleFonts.manrope(
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
            'Filters',
            style: GoogleFonts.manrope(
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
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: filter.dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              Text(
                filter.label,
                style: GoogleFonts.manrope(
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
                    style: GoogleFonts.manrope(
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
                  style: GoogleFonts.manrope(
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
                  style: GoogleFonts.manrope(
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
          style: GoogleFonts.manrope(
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
          style: GoogleFonts.manrope(
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
          style: GoogleFonts.manrope(
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
            style: GoogleFonts.manrope(
              color: const Color(0xFF22201D),
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Lead Distribution Snapshot',
            style: GoogleFonts.manrope(
              color: const Color(0xFF272420),
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'The registry now reflects actual lead records from the backend. Showing $filteredLeads curated lead${filteredLeads == 1 ? '' : 's'} from a live archive of $totalLeads records.',
            style: GoogleFonts.manrope(
              color: const Color(0xFF5C5753),
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'View Analysis ->',
            style: GoogleFonts.manrope(
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
                  style: GoogleFonts.playfairDisplay(
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
            style: GoogleFonts.manrope(
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
                  style: GoogleFonts.manrope(
                    color: AppColors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: GoogleFonts.manrope(
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
  const _StageFilter({required this.label, this.count, this.dotColor});

  final String label;
  final int? count;
  final Color? dotColor;
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
