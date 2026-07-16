import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/rm/models/rm_lead_item.dart';

class WhatsappConversationScreen extends StatefulWidget {
  const WhatsappConversationScreen({super.key, this.lead});

  final RmLeadItem? lead;

  @override
  State<WhatsappConversationScreen> createState() =>
      _WhatsappConversationScreenState();
}

class _WhatsappConversationScreenState
    extends State<WhatsappConversationScreen> {
  final List<RmCommunicationLog> _localMessages = [];

  void _addMessage(String text, {String? imageUrl}) {
    final newMessage = RmCommunicationLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      channel: 'WHATSAPP',
      direction: 'OUTBOUND',
      content: text,
      subject: '',
      templateName: '',
      whatsappStatus: 'SENT',
      createdAt: DateTime.now(),
      imageUrl: imageUrl,
    );
    setState(() {
      _localMessages.add(newMessage);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lead == null) {
      return Scaffold(
        backgroundColor: AppColors.rmSoftPink,
        body: SafeArea(
          child: Column(
            children: [
              const _WhatsappChatHeader(),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Text(
                      'Open a manager lead from the chat hub to view the WhatsApp conversation.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.rmBodyText,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final allMessages = [...widget.lead!.communicationLogs, ..._localMessages];
    final sortedMessages = allMessages
      ..sort((a, b) {
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return left.compareTo(right);
      });

    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      body: SafeArea(
        child: Column(
          children: [
            _WhatsappChatHeader(lead: widget.lead),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
                children: [
                  _MetaInfoCard(lead: widget.lead!),
                  if (sortedMessages.isNotEmpty) const _EncryptionNotice(),
                  if (sortedMessages.isEmpty)
                    _EmptyConversationCard(lead: widget.lead!)
                  else
                    ..._buildTimeline(sortedMessages),
                  SizedBox(height: 12.h),
                  _TaskSummaryCard(lead: widget.lead!),
                ],
              ),
            ),
            _MessageComposer(
              onSend: (text, imagePath) {
                _addMessage(text, imageUrl: imagePath);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsappChatHeader extends StatelessWidget {
  const _WhatsappChatHeader({this.lead});

  final RmLeadItem? lead;

  @override
  Widget build(BuildContext context) {
    final title = lead?.name ?? 'WhatsApp Chat';
    final initials = lead?.initials ?? 'W';
    final subtitle = lead == null
        ? 'Lead conversation'
        : 'Last activity ${_formatDateTime(lead!.latestActivityAt, fallback: 'Not available')}';

    return Container(
      height: 64.h,
      color: AppColors.white,
      padding: EdgeInsets.only(right: 8.w),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: AppColors.rmPrimary,
              size: 24.sp,
            ),
          ),
          CircleAvatar(
            radius: 20.r,
            backgroundColor: AppColors.rmPrimary,
            child: Text(
              initials,
              style: GoogleFonts.inter(
                color: AppColors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppColors.rmPrimary,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.whatsappGreen,
                      size: 14.sp,
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.rmMutedText,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search, color: AppColors.rmPrimary, size: 23.sp),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.call, color: AppColors.rmPrimary, size: 22.sp),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.more_vert,
              color: AppColors.rmPrimary,
              size: 22.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaInfoCard extends StatelessWidget {
  const _MetaInfoCard({required this.lead});

  final RmLeadItem lead;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 18.h),
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: AppColors.whatsappGreen, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WhatsApp for Koniwala',
                  style: GoogleFonts.inter(
                    color: AppColors.whatsappGreen,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Assigned to ${lead.assignedToName} - ${lead.city}\n${lead.stageLabel} lead - ${lead.sourceLabel} source',
                  style: GoogleFonts.inter(
                    color: AppColors.rmMutedText,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EncryptionNotice extends StatelessWidget {
  const _EncryptionNotice();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.only(bottom: 18.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
        constraints: BoxConstraints(maxWidth: 250.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6E7),
          borderRadius: BorderRadius.circular(7.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 13.sp, color: AppColors.rmBodyText),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                'Messages are end-to-end encrypted. No one\noutside of this chat, not even Koniwala, can read\nor listen to them.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.rmBodyText,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatDatePill extends StatelessWidget {
  const _ChatDatePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.only(bottom: 18.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF8E6E7),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: AppColors.rmPrimary,
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ConversationBubble extends StatelessWidget {
  const _ConversationBubble({required this.message});

  final RmCommunicationLog message;

  @override
  Widget build(BuildContext context) {
    final isIncoming = message.isIncoming;
    final hasImage = message.imageUrl != null && message.imageUrl!.isNotEmpty;

    return Align(
      alignment: isIncoming ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: 252.w),
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: isIncoming ? AppColors.white : const Color(0xFFE1F3EA),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
                child: message.imageUrl!.startsWith('http')
                    ? Image.network(
                        message.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(message.imageUrl!),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 10.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.previewText.isNotEmpty)
                    Text(
                      message.previewText,
                      style: GoogleFonts.inter(
                        color: AppColors.rmHeading,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.directionLabel,
                        style: GoogleFonts.inter(
                          color: AppColors.rmMutedText,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        _formatTime(message.createdAt),
                        style: GoogleFonts.inter(
                          color: AppColors.rmMutedText,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!isIncoming) ...[
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.done_all,
                          color: Colors.blueAccent,
                          size: 14.sp,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyConversationCard extends StatelessWidget {
  const _EmptyConversationCard({required this.lead});

  final RmLeadItem lead;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No WhatsApp messages synced yet.',
            style: GoogleFonts.inter(
              color: AppColors.rmPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            lead.notes.isEmpty ? lead.latestMessagePreview : lead.notes,
            style: GoogleFonts.inter(
              color: AppColors.rmBodyText,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskSummaryCard extends StatelessWidget {
  const _TaskSummaryCard({required this.lead});

  final RmLeadItem lead;

  @override
  Widget build(BuildContext context) {
    final profileTask = lead.profileCreationTask;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lead Context',
            style: GoogleFonts.inter(
              color: AppColors.rmPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10.h),
          _SummaryRow(label: 'Open Tasks', value: '${lead.openTasksCount}'),
          SizedBox(height: 6.h),
          _SummaryRow(label: 'Intent Score', value: '${lead.intentScore}%'),
          SizedBox(height: 6.h),
          _SummaryRow(
            label: 'Profile Creation',
            value: profileTask == null
                ? 'No task linked'
                : '${profileTask.title} - ${profileTask.statusLabel}',
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.rmMutedText,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              color: AppColors.rmHeading,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageComposer extends StatefulWidget {
  const _MessageComposer({required this.onSend});
  final void Function(String text, String? imagePath) onSend;

  @override
  State<_MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<_MessageComposer> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _handleSend() {
    if (_controller.text.trim().isEmpty && _selectedImage == null) return;

    widget.onSend(_controller.text.trim(), _selectedImage?.path);
    _controller.clear();
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selectedImage != null)
          Container(
            padding: EdgeInsets.all(8.w),
            color: const Color(0xFFF7F4F1),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Image.file(
                    File(_selectedImage!.path),
                    height: 150.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImage = null),
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          color: const Color(0xFFF7F4F1),
          padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 8.h),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.photo_camera),
                            title: const Text('Camera'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Gallery'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.add, color: AppColors.rmPrimary, size: 26.sp),
              ),
              Expanded(
                child: Container(
                  constraints: BoxConstraints(maxHeight: 100.h),
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: const Color(0xFFE6DDDD)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sentiment_satisfied_alt,
                        color: AppColors.rmBodyText,
                        size: 22.sp,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onChanged: (val) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Type a message',
                            hintStyle: GoogleFonts.inter(
                              color: AppColors.rmMutedText,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: GoogleFonts.inter(
                            color: AppColors.rmHeading,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_controller.text.isEmpty &&
                          _selectedImage == null) ...[
                        IconButton(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: Icon(
                            Icons.attach_file,
                            color: AppColors.rmBodyText,
                            size: 21.sp,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        SizedBox(width: 10.w),
                        IconButton(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: Icon(
                            Icons.photo_camera_outlined,
                            color: AppColors.rmBodyText,
                            size: 21.sp,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: _handleSend,
                child: Container(
                  width: 46.r,
                  height: 46.r,
                  decoration: const BoxDecoration(
                    color: AppColors.rmPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    (_controller.text.isNotEmpty || _selectedImage != null)
                        ? Icons.send
                        : Icons.mic,
                    color: AppColors.white,
                    size: 22.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

List<Widget> _buildTimeline(List<RmCommunicationLog> messages) {
  final widgets = <Widget>[];
  DateTime? currentDate;

  for (final message in messages) {
    final messageDate = message.createdAt;
    final shouldShowDatePill =
        messageDate != null &&
        (currentDate == null ||
            currentDate.year != messageDate.year ||
            currentDate.month != messageDate.month ||
            currentDate.day != messageDate.day);

    if (shouldShowDatePill) {
      currentDate = messageDate;
      widgets.add(
        _ChatDatePill(text: _formatDateTime(messageDate, fallback: '-')),
      );
    }

    widgets.add(_ConversationBubble(message: message));
  }

  return widgets;
}

String _formatDateTime(DateTime? value, {String fallback = '-'}) {
  if (value == null) {
    return fallback;
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

  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final meridiem = value.hour >= 12 ? 'PM' : 'AM';
  return '${value.day} ${months[value.month - 1]} ${value.year} - $hour:$minute $meridiem';
}

String _formatTime(DateTime? value) {
  if (value == null) {
    return '--:--';
  }

  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final meridiem = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $meridiem';
}
