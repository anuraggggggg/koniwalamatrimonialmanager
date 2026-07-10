import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koniwalamatrimonial/constants/api_constants.dart';
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
  int _selectedStage = 0;
  _LeadsView _selectedView = _LeadsView.registry;
  bool _hasRequestedLeads = false;
  String? _requestedAccessToken;

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
  Widget build(BuildContext context) {
    final leadsProvider = context.watch<LeadsProvider>();
    final authProvider = context.watch<AuthProvider>();
    final leads = leadsProvider.leads;
    final stageFilters = _stageFilters(leads);
    final visibleLeads = _visibleLeads(leads, stageFilters);
    final canEditLeads = _canEditLeads(authProvider.userModel?.user?.role);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
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
              SizedBox(height: 12.h),
              _LeadsViewTabs(
                selectedView: _selectedView,
                onSelected: (view) => setState(() => _selectedView = view),
              ),
              SizedBox(height: 18.h),
              if (_selectedView == _LeadsView.registry) ...[
                _FilterHeader(onFilterPressed: () {}),
                SizedBox(height: 8.h),
                _StageFilterList(
                  filters: stageFilters,
                  selectedIndex: _selectedStage,
                  onSelected: (index) =>
                      setState(() => _selectedStage = index),
                ),
                SizedBox(height: 14.h),
                _LeadsContent(
                  isLoading: leadsProvider.isLoading,
                  error: leadsProvider.error,
                  leads: visibleLeads,
                  onRetry: () => context.read<LeadsProvider>().retry(),
                  isRemovingLead: leadsProvider.isRemovingLead,
                  canEditLead: canEditLeads,
                  onEditLead: (lead) => _showEditLeadDialog(context, lead),
                  onDeleteLead: (lead) => _handleDeleteLead(
                    context,
                    lead,
                    authProvider.userModel?.accessToken,
                  ),
                ),
                SizedBox(height: 22.h),
                _LeadsPagination(
                  visibleCount: visibleLeads.length,
                  totalCount: leads.length,
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
    final message = await context
        .read<LeadsProvider>()
        .deleteLead(lead, accessToken);

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
    var selectedManagerId = managers.any(
      (manager) => manager.id == lead.assignedToId,
    )
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
              return AlertDialog(
                title: Text(
                  'Edit Lead',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _EditLeadField(label: 'Name', controller: nameController),
                      SizedBox(height: 10.h),
                      _EditLeadField(
                        label: 'Phone',
                        controller: phoneController,
                      ),
                      SizedBox(height: 10.h),
                      _EditLeadField(
                        label: 'Email',
                        controller: emailController,
                      ),
                      SizedBox(height: 10.h),
                      _EditLeadField(
                        label: 'Stage',
                        controller: stageController,
                      ),
                      SizedBox(height: 10.h),
                      _EditLeadField(label: 'City', controller: cityController),
                      SizedBox(height: 10.h),
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
                      SizedBox(height: 10.h),
                      _EditLeadField(
                        label: 'Source',
                        controller: sourceController,
                      ),
                      SizedBox(height: 10.h),
                      _EditLeadField(
                        label: 'Lead For',
                        controller: leadForController,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF6F5F64),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(
                      _EditLeadResult(
                        name: nameController.text,
                        phone: phoneController.text,
                        email: emailController.text,
                        stage: stageController.text,
                        city: cityController.text,
                        source: sourceController.text,
                        leadFor: leadForController.text,
                        assignedToId: selectedManagerId ?? lead.assignedToId,
                        assignedToName: selectedManagerName,
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.manrope(
                        color: AppColors.rmPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result == null || !context.mounted) {
        return;
      }

      final currentAccessToken =
          context.read<AuthProvider>().userModel?.accessToken;
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
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(lead.id.isNotEmpty),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD1213E),
                foregroundColor: Colors.white,
              ),
              child: Text(
                lead.id.isNotEmpty ? 'Yes, Delete' : 'Close',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                ),
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
    required this.onRetry,
    required this.isRemovingLead,
    required this.canEditLead,
    required this.onEditLead,
    required this.onDeleteLead,
  });

  final bool isLoading;
  final String? error;
  final List<LeadRegistryItem> leads;
  final VoidCallback onRetry;
  final bool Function(LeadRegistryItem lead) isRemovingLead;
  final bool canEditLead;
  final ValueChanged<LeadRegistryItem> onEditLead;
  final ValueChanged<LeadRegistryItem> onDeleteLead;

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
      return const _LeadsMessage(message: 'No leads found.');
    }

    return ListView.separated(
      itemCount: leads.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => SizedBox(height: 16.h),
      itemBuilder: (context, index) => _LeadCard(
        lead: leads[index],
        isDeleting: isRemovingLead(leads[index]),
        canEdit: canEditLead,
        onEdit: () => onEditLead(leads[index]),
        onDelete: () => onDeleteLead(leads[index]),
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
  const _EditLeadField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GoogleFonts.manrope(
        color: AppColors.rmHeading,
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.manrope(
          color: const Color(0xFF6F5F64),
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFFEECAD4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.rmPrimary),
        ),
      ),
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
        decoration: _decoration('Assigned To'),
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
      value: selectedManagerId,
      isExpanded: true,
      decoration: _decoration('Assigned To'),
      hint: Text(
        fallbackLabel.isEmpty ? 'Select relationship manager' : fallbackLabel,
        overflow: TextOverflow.ellipsis,
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

  static InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.manrope(
        color: const Color(0xFF6F5F64),
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: Color(0xFFEECAD4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: AppColors.rmPrimary),
      ),
    );
  }
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onMenuPressed != null) ...[
          // IconButton(
          //   tooltip: 'Menu',
          //   onPressed: onMenuPressed,
          //   icon: Icon(Icons.menu, color: AppColors.rmPrimary, size: 26.sp),
          // ),
          SizedBox(width: 6.w),
        ],
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leads Registry',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.deepBurgundy,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Curating matrimonial connections with archival precision.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  color: const Color(0xFF6F5F64),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        // _LeadFollowUpsButton(
        //   onPressed: () {
        //     Navigator.of(context).pushNamed(AppRoutes.leadFollowUps);
        //   },
        // ),
        SizedBox(width: 8.w),
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
    return Material(
      color: AppColors.deepBurgundy,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          height: 42.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 1.4),
                ),
                child: Icon(Icons.add, color: AppColors.white, size: 13.sp),
              ),
              SizedBox(width: 8.w),
              Text(
                'New Inquiry',
                style: GoogleFonts.manrope(
                  color: AppColors.white,
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

class _LeadsViewTabs extends StatelessWidget {
  const _LeadsViewTabs({
    required this.selectedView,
    required this.onSelected,
  });

  final _LeadsView selectedView;
  final ValueChanged<_LeadsView> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52.h,
      padding: EdgeInsets.all(5.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(9.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _LeadsTab(
              label: 'Registry View',
              icon: Icons.table_rows_outlined,
              selected: selectedView == _LeadsView.registry,
              onTap: () => onSelected(_LeadsView.registry),
            ),
          ),
          Expanded(
            child: _LeadsTab(
              label: 'Pipeline',
              icon: Icons.view_week_outlined,
              selected: selectedView == _LeadsView.pipeline,
              onTap: () => onSelected(_LeadsView.pipeline),
            ),
          ),
          Expanded(
            child: _LeadsTab(
              label: 'Hub',
              icon: Icons.forum_outlined,
              selected: selectedView == _LeadsView.hub,
              onTap: () => onSelected(_LeadsView.hub),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadsTab extends StatelessWidget {
  const _LeadsTab({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? AppColors.deepBurgundy
        : AppColors.standardDarkTextColor;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7.r),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF5F8) : AppColors.transparent,
            borderRadius: BorderRadius.circular(7.r),
            border: selected
                ? Border.all(color: const Color(0xFFFBE0E9), width: 1)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22.sp, color: foreground),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: foreground,
                    fontSize: 10.sp,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
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
  const _PipelineStageCard({
    required this.filter,
    required this.progress,
  });

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
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
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
              color: AppColors.darkGray,
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: .6,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onFilterPressed,
          icon: const Icon(Icons.tune, size: 20),
          label: Text(
            'Filters',
            style: GoogleFonts.manrope(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.deepBurgundy,
            side: const BorderSide(color: AppColors.deepBurgundy),
            minimumSize: Size(86.w, 38.h),
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
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
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          height: 30.h,
          constraints: BoxConstraints(minWidth: selected ? 120.w : 74.w),
          padding: EdgeInsets.symmetric(horizontal: 13.w),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : const Color(0xFFFFFCFD),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: selected ? AppColors.deepBurgundy : const Color(0xFFE9D8DE),
              width: selected ? 1.1 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (filter.dotColor != null) ...[
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
                  color: selected
                      ? AppColors.rmPrimary
                      : const Color(0xFF62565B),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (filter.count != null) ...[
                SizedBox(width: 8.w),
                Text(
                  '${filter.count}',
                  style: GoogleFonts.manrope(
                    color: selected
                        ? AppColors.rmPrimary
                        : const Color(0xFF62565B),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
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
    final imageProvider = _leadImageProvider(lead.image);

    return Container(
      padding: EdgeInsets.fromLTRB(13.w, 12.h, 13.w, 10.h),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 32.r,
                backgroundColor: const Color(0xFFF7D9E3),
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? Text(
                        lead.initials,
                        style: GoogleFonts.manrope(
                          color: AppColors.rmPrimary,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: AppColors.deepBurgundy,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      lead.phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF564146),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      lead.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF727785),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              _LeadActions(
                isDeleting: isDeleting,
                canEdit: canEdit,
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              _StatusPill(
                style: _LeadStageStyle.fromStage(lead.stage),
                label: lead.stage,
              ),
              SizedBox(width: 8.w),
              _LocationPill(label: lead.city),
            ],
          ),
          SizedBox(height: 8.h),
          _LeadMetaBox(lead: lead),
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
        SizedBox(width: 11.w),
        if (canEdit) ...[
          _ActionIcon(icon: Icons.edit, color: AppColors.black, onTap: onEdit),
          SizedBox(width: 11.w),
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

ImageProvider? _leadImageProvider(String image) {
  final text = image.trim();
  if (text.isEmpty) {
    return null;
  }

  if (text.startsWith('http')) {
    return NetworkImage(text);
  }

  if (text.startsWith('assets/')) {
    return AssetImage(text);
  }

  final file = File(text);
  if (file.existsSync()) {
    return FileImage(file);
  }

  if (text.startsWith('/')) {
    final apiOrigin = ApiConstants.baseUrl.replaceFirst('/api/v1', '');
    return NetworkImage('$apiOrigin$text');
  }

  return null;
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
        width: 20.w,
        height: 24.h,
        child: isLoading
            ? Padding(
                padding: EdgeInsets.all(2.r),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            : Icon(icon, size: 20.sp, color: color),
      ),
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
      height: 24.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: colors.dot,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 5.w),
          Text(
            label,
            style: GoogleFonts.manrope(
              color: colors.text,
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0F1),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.manrope(
            color: const Color(0xFF5F5358),
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LeadMetaBox extends StatelessWidget {
  const _LeadMetaBox({required this.lead});

  final LeadRegistryItem lead;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFF3E5EA)),
      ),
      child: Column(
        children: [
          _LeadMetaRow(label: 'Assigned To:', value: lead.assignedTo),
          SizedBox(height: 4.h),
          _LeadMetaRow(label: 'Lead For:', value: lead.leadFor),
          SizedBox(height: 4.h),
          _LeadMetaRow(label: 'Source:', value: lead.source),
          SizedBox(height: 4.h),
          _LeadMetaRow(label: 'Created On:', value: lead.createdOn),
        ],
      ),
    );
  }
}

class _LeadMetaRow extends StatelessWidget {
  const _LeadMetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              color: const Color(0xFF727785),
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: GoogleFonts.manrope(
              color: const Color(0xFF181C1F),
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
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

class _LeadsPagination extends StatelessWidget {
  const _LeadsPagination({
    required this.visibleCount,
    required this.totalCount,
  });

  final int visibleCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final displayEnd = visibleCount == 0 ? 0 : visibleCount;

    return Column(
      children: [
        Center(
          child: Text(
            'Displaying queue ${visibleCount == 0 ? 0 : 1}-$displayEnd of $totalCount assigned leads',
            style: GoogleFonts.manrope(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6F5F64),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.deepBurgundy,
                  side: const BorderSide(color: AppColors.deepBurgundy),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
                onPressed: () {},
                child: Text(
                  'Previous\nSequence',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w900,
                    fontSize: 15.sp,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepBurgundy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  elevation: 0,
                ),
                onPressed: () {},
                child: Text(
                  'Next Segment',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w900,
                    fontSize: 18.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
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
