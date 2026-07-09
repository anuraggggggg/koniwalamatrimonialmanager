import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/owner/models/lead_follow_up_item.dart';
import 'package:koniwalamatrimonial/owner/providers/lead_follow_ups_provider.dart';
import 'package:koniwalamatrimonial/owner/providers/leads_provider.dart';
import 'package:koniwalamatrimonial/owner/providers/tasks_provider.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class CreateNewTaskScreen extends StatefulWidget {
  const CreateNewTaskScreen({super.key, this.lead});

  final LeadFollowUpItem? lead;

  @override
  State<CreateNewTaskScreen> createState() => _CreateNewTaskScreenState();
}

class _CreateNewTaskScreenState extends State<CreateNewTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  String _taskType = 'CALL';
  String _priority = 'MEDIUM';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _dueTime = const TimeOfDay(hour: 10, minute: 0);

  LeadFollowUpItem? _selectedLead;
  RelationshipManagerOption? _selectedManager;

  @override
  void initState() {
    super.initState();
    _selectedLead = widget.lead;
    if (_selectedLead != null) {
      _titleController.text = 'Follow up with ${_selectedLead!.name}';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<LeadsProvider>().fetchManagers(auth.userModel?.accessToken);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.rmPrimary,
              onPrimary: AppColors.white,
              onSurface: AppColors.rmHeading,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dueDate) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.rmPrimary,
              onPrimary: AppColors.white,
              onSurface: AppColors.rmHeading,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dueTime) {
      setState(() => _dueTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final leads = context.watch<LeadFollowUpsProvider>().leads;
    final managers = context.watch<LeadsProvider>().managers;
    final isCreating = context.watch<TasksProvider>().isCreating;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCFC),
      body: SafeArea(
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.30)),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 24.h),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        SizedBox(height: 26.h),
                        _buildSectionCard(
                          title: 'Task Identity & Lead',
                          children: [
                            _buildLabel('SELECT LEAD *'),
                            SizedBox(height: 8.h),
                            _buildLeadDropdown(leads),
                            SizedBox(height: 17.h),
                            _buildLabel('TASK TITLE *'),
                            SizedBox(height: 8.h),
                            _buildTextField(
                              controller: _titleController,
                              hint: 'Enter task title',
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Required' : null,
                            ),
                            SizedBox(height: 17.h),
                            _buildLabel('DESCRIPTION'),
                            SizedBox(height: 8.h),
                            _buildTextField(
                              controller: _descriptionController,
                              hint: 'Enter task description...',
                              maxLines: 3,
                            ),
                          ],
                        ),
                        SizedBox(height: 18.h),
                        _buildSectionCard(
                          title: 'Task Metadata',
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('TASK TYPE'),
                                      SizedBox(height: 8.h),
                                      _buildDropdown<String>(
                                        value: _taskType,
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'CALL',
                                            child: Text('Call'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'FOLLOW_UP',
                                            child: Text('Follow Up'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'MESSAGE',
                                            child: Text('Message'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'MEETING',
                                            child: Text('Meeting'),
                                          ),
                                        ],
                                        onChanged: (v) =>
                                            setState(() => _taskType = v!),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('PRIORITY'),
                                      SizedBox(height: 8.h),
                                      _buildDropdown<String>(
                                        value: _priority,
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'LOW',
                                            child: Text('Low'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'MEDIUM',
                                            child: Text('Medium'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'HIGH',
                                            child: Text('High'),
                                          ),
                                        ],
                                        onChanged: (v) =>
                                            setState(() => _priority = v!),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 17.h),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('DUE DATE'),
                                      SizedBox(height: 8.h),
                                      _buildPickerField(
                                        text: DateFormat(
                                          'dd MMM yyyy',
                                        ).format(_dueDate),
                                        icon: Icons.calendar_today_outlined,
                                        onTap: _selectDate,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('DUE TIME'),
                                      SizedBox(height: 8.h),
                                      _buildPickerField(
                                        text: _dueTime.format(context),
                                        icon: Icons.access_time_outlined,
                                        onTap: _selectTime,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 18.h),
                        _buildSectionCard(
                          title: 'Assignment & Notes',
                          children: [
                            _buildLabel('ASSIGN TO RELATIONSHIP MANAGER'),
                            SizedBox(height: 8.h),
                            _buildManagerDropdown(managers),
                            SizedBox(height: 17.h),
                            _buildLabel('TASK NOTES'),
                            SizedBox(height: 8.h),
                            _buildTextField(
                              controller: _notesController,
                              hint:
                                  'Add context, instructions, or task summary...',
                              maxLines: 5,
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ),
              ),
              _buildBottomActionBar(isCreating),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38.r,
              height: 38.r,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF1F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_task_rounded,
                size: 19.sp,
                color: AppColors.rmPrimary,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WORKFLOW MANAGEMENT',
                    style: GoogleFonts.manrope(
                      color: AppColors.rmPrimary,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Create New\nTask',
                    style: GoogleFonts.manrope(
                      color: AppColors.rmHeading,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.close_rounded,
                size: 20.sp,
                color: AppColors.rmModalClose,
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        Text(
          'Create and assign a task for lead follow-up and workflow tracking.',
          style: GoogleFonts.manrope(
            color: AppColors.rmBodyText,
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: const [
          BoxShadow(
            color: AppColors.rmStatShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              color: AppColors.rmPrimary,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          const Divider(height: 1, color: AppColors.rmDivider),
          SizedBox(height: 14.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        color: AppColors.rmHeading,
        fontSize: 9.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.manrope(
        color: AppColors.rmHeading,
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.manrope(
          color: AppColors.rmHintText,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 11.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.r),
          borderSide: const BorderSide(color: AppColors.rmPaleRoseBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.r),
          borderSide: const BorderSide(color: AppColors.rmPaleRoseBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.r),
          borderSide: BorderSide(color: AppColors.rmPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.r),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.rmMutedText,
          ),
          style: GoogleFonts.manrope(
            color: AppColors.rmHeading,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLeadDropdown(List<LeadFollowUpItem> leads) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LeadFollowUpItem>(
          value: _selectedLead,
          hint: Text(
            'Select Lead',
            style: GoogleFonts.manrope(
              color: AppColors.rmHintText,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          items: leads.map((lead) {
            return DropdownMenuItem(value: lead, child: Text(lead.name));
          }).toList(),
          onChanged: (v) {
            setState(() {
              _selectedLead = v;
              if (_titleController.text.isEmpty ||
                  _titleController.text.startsWith('Follow up with')) {
                _titleController.text = 'Follow up with ${v!.name}';
              }
            });
          },
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.rmMutedText,
          ),
          style: GoogleFonts.manrope(
            color: AppColors.rmHeading,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildManagerDropdown(List<RelationshipManagerOption> managers) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: AppColors.rmPaleRoseBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RelationshipManagerOption>(
          value: _selectedManager,
          hint: Text(
            'Select relationship manager',
            style: GoogleFonts.manrope(
              color: AppColors.rmHintText,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          items: managers.map((manager) {
            return DropdownMenuItem(value: manager, child: Text(manager.name));
          }).toList(),
          onChanged: (v) => setState(() => _selectedManager = v),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.rmMutedText,
          ),
          style: GoogleFonts.manrope(
            color: AppColors.rmHeading,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPickerField({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: AppColors.rmPaleRoseBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14.sp, color: AppColors.rmMutedText),
            SizedBox(width: 7.w),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  color: AppColors.rmHeading,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(bool isCreating) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(top: BorderSide(color: AppColors.rmDivider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 82.w,
            height: 42.h,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rmPrimary,
                side: const BorderSide(color: AppColors.rmPrimary),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9.r),
                ),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.manrope(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(width: 22.w),
          Expanded(
            child: SizedBox(
              height: 42.h,
              child: ElevatedButton(
                onPressed: isCreating ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rmPrimary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isCreating)
                      SizedBox(
                        width: 16.r,
                        height: 16.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    else ...[
                      Text(
                        'Create Task',
                        style: GoogleFonts.manrope(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 7.w),
                      Icon(Icons.arrow_forward_rounded, size: 15.sp),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final lead = _selectedLead;
    if (lead == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a lead')));
      return;
    }

    final manager = _selectedManager;
    if (manager == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a relationship manager')),
      );
      return;
    }

    final dueAt = DateTime(
      _dueDate.year,
      _dueDate.month,
      _dueDate.day,
      _dueTime.hour,
      _dueTime.minute,
    );
    final subjectId = lead.customerId.isNotEmpty ? lead.customerId : lead.id;
    final token = context.read<AuthProvider>().userModel?.accessToken;
    final tasksProvider = context.read<TasksProvider>();
    final success = await tasksProvider.createTask(
      accessToken: token,
      title: _titleController.text,
      description: _descriptionController.text,
      type: _taskType,
      priority: _priority,
      dueAt: dueAt,
      assignedToId: manager.id,
      subjectId: subjectId,
      notes: _notesController.text,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tasksProvider.error ?? 'Unable to create task')),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task created successfully')));
    Navigator.pop(context, true);
  }
}
