import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/rm/chat_updates/chat_updates_source.dart';
import 'package:koniwalamatrimonial/rm/models/rm_lead_item.dart';
import 'package:koniwalamatrimonial/rm/models/whatsapp_models.dart';
import 'package:koniwalamatrimonial/rm/providers/whatsapp_provider.dart';
import 'package:koniwalamatrimonial/routes/app_route_observer.dart';
import 'package:koniwalamatrimonial/routes/app_routes.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsappConversationScreen extends StatefulWidget {
  const WhatsappConversationScreen({
    super.key,
    this.lead,
    this.conversation,
    this.openAttachmentOnStart = false,
  });

  final RmLeadItem? lead;
  final WhatsappConversation? conversation;
  final bool openAttachmentOnStart;

  @override
  State<WhatsappConversationScreen> createState() =>
      _WhatsappConversationScreenState();
}

class _WhatsappConversationScreenState extends State<WhatsappConversationScreen>
    with WidgetsBindingObserver, RouteAware {
  final ScrollController _scrollController = ScrollController();
  ChatUpdatesSource? _updatesSource;
  StreamSubscription<List<WhatsappMessage>>? _updatesSubscription;
  StreamSubscription<Object>? _errorSubscription;
  final AudioRecorder _audioRecorder = AudioRecorder();
  late final WhatsappConversation? _conversation =
      widget.conversation ??
      (widget.lead == null
          ? null
          : WhatsappConversation.fromLead(widget.lead!));
  bool _requestedMessages = false;
  String? _requestedAccessToken;
  bool _routeSubscribed = false;
  bool _handledInitialAttachment = false;
  bool _isRecordingVoice = false;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_handleScroll);
    if (widget.openAttachmentOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _handledInitialAttachment) {
          return;
        }
        _handledInitialAttachment = true;
        _pickAttachment();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!_routeSubscribed && route is PageRoute<dynamic>) {
      appRouteObserver.subscribe(this, route);
      _routeSubscribed = true;
    }
    final accessToken = context.watch<AuthProvider>().userModel?.accessToken;
    final leadId = _conversation?.leadId;
    if (leadId == null ||
        leadId.isEmpty ||
        accessToken == null ||
        accessToken.trim().isEmpty ||
        (_requestedMessages && accessToken == _requestedAccessToken)) {
      return;
    }

    _requestedMessages = true;
    _requestedAccessToken = accessToken;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _conversation == null) {
        return;
      }
      final conversation = _conversation;
      final provider = context.read<WhatsappProvider>();
      await provider.fetchLeadDetail(
        accessToken: accessToken,
        conversation: conversation,
      );
      await provider.fetchTemplates(accessToken);
      await provider.fetchMessages(
        accessToken: accessToken,
        leadId: conversation.leadId,
        forceRefresh: true,
      );
      await provider.markConversationRead(
        accessToken: accessToken,
        conversation: conversation,
      );
      _scrollToBottom();
      await _startUpdatesSource(
        accessToken: accessToken,
        conversation: conversation,
        provider: provider,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    _updatesSubscription?.cancel();
    _errorSubscription?.cancel();
    _updatesSource?.dispose();
    _audioRecorder.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updatesSource?.setActive(true);
      _updatesSource?.resume();
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _updatesSource?.setActive(false);
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _updatesSource?.pause();
    }
  }

  @override
  void didPush() {
    _updatesSource?.setActive(true);
  }

  @override
  void didPopNext() {
    _updatesSource?.setActive(true);
    _updatesSource?.resume();
  }

  @override
  void didPushNext() {
    _updatesSource?.setActive(false);
  }

  Future<void> _startUpdatesSource({
    required String accessToken,
    required WhatsappConversation conversation,
    required WhatsappProvider provider,
  }) async {
    if (_updatesSource != null) {
      return;
    }

    final factory = context.read<ChatUpdatesSourceFactory>();
    final source = factory();
    _updatesSource = source;
    _updatesSubscription = source.updates.listen((messages) {
      final inserted = provider.appendMessages(conversation.leadId, messages);
      if (inserted > 0) {
        _scrollToBottom();
      }
    });
    _errorSubscription = source.errors.listen((error) {
      // The source retries with backoff. Keep the visible chat stable.
    });

    await source.start(
      accessToken: accessToken,
      leadId: conversation.leadId,
      seedMessages: provider.messagesFor(conversation.leadId),
    );
  }

  void _handleScroll() {
    final conversation = _conversation;
    if (conversation == null ||
        !_scrollController.hasClients ||
        _scrollController.position.pixels > 80) {
      return;
    }
    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }
    context.read<WhatsappProvider>().loadMoreMessages(
      accessToken: accessToken,
      leadId: conversation.leadId,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendText(String text) async {
    final conversation = _conversation;
    if (conversation == null) {
      return;
    }
    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    final message = await context.read<WhatsappProvider>().sendText(
      accessToken: accessToken,
      conversation: conversation,
      content: text,
    );
    if (!mounted) {
      return;
    }
    if (message != null) {
      _showSnack(message);
      return;
    }
    _scrollToBottom();
  }

  Future<void> _sendTemplate(WhatsappTemplate template) async {
    final conversation = _conversation;
    if (conversation == null) {
      return;
    }
    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    final message = await context.read<WhatsappProvider>().sendTemplate(
      accessToken: accessToken,
      conversation: conversation,
      template: template,
    );
    if (!mounted) {
      return;
    }
    if (message != null) {
      _showSnack(message);
      return;
    }
    Navigator.of(context).maybePop();
    _scrollToBottom();
  }

  Future<void> _sendMediaAttachment(_PendingWhatsappMedia media) async {
    final conversation = _conversation;
    if (conversation == null) {
      return;
    }
    if (!conversation.canInferFreeformWindow) {
      _showSnack(
        'Send an approved template first. Attachments unlock after the customer responds.',
      );
      return;
    }

    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    final message = await context.read<WhatsappProvider>().sendMedia(
      accessToken: accessToken,
      conversation: conversation,
      mediaDataUrl: media.dataUrl,
      mediaType: media.messageType,
      mediaFileName: media.fileName,
      mediaMimeType: media.mimeType,
      mediaSize: media.size,
    );
    if (!mounted) {
      return;
    }
    if (message != null) {
      _showSnack(message);
      return;
    }
    _scrollToBottom();
  }

  Future<void> _pickAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      final file = result?.files.single;
      if (file == null) {
        return;
      }
      final bytes =
          file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null || bytes.isEmpty) {
        _showSnack('Unable to read the selected file.');
        return;
      }
      await _sendMediaAttachment(
        _PendingWhatsappMedia.fromBytes(
          bytes: bytes,
          fileName: file.name,
          mimeType: _mimeTypeForFile(file.name),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack('Unable to attach this file.');
    }
  }

  Future<void> _toggleVoiceRecording() async {
    if (!(_conversation?.canInferFreeformWindow ?? false)) {
      _showSnack(
        'Send an approved template first. Voice messages unlock after the customer responds.',
      );
      return;
    }

    if (_isRecordingVoice) {
      await _stopAndSendVoiceRecording();
      return;
    }

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        _showSnack('Microphone permission is required to send voice messages.');
        return;
      }

      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/whatsapp_voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1),
        path: path,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isRecordingVoice = true;
        _recordingPath = path;
      });
      _showSnack('Recording voice note. Tap the mic again to send.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack('Failed to access microphone.');
    }
  }

  Future<void> _stopAndSendVoiceRecording() async {
    try {
      final stoppedPath = await _audioRecorder.stop();
      final path = stoppedPath ?? _recordingPath;
      if (mounted) {
        setState(() {
          _isRecordingVoice = false;
          _recordingPath = null;
        });
      }
      if (path == null || path.isEmpty) {
        _showSnack('Unable to save the voice note.');
        return;
      }

      final file = File(path);
      if (!file.existsSync()) {
        _showSnack('Unable to find the recorded voice note.');
        return;
      }

      final bytes = await file.readAsBytes();
      await _sendMediaAttachment(
        _PendingWhatsappMedia.fromBytes(
          bytes: bytes,
          fileName: 'voice-note.m4a',
          mimeType: 'audio/mp4',
          messageType: 'audio',
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isRecordingVoice = false;
          _recordingPath = null;
        });
      }
      _showSnack('Unable to send the voice note.');
    }
  }

  void _showTemplateSheet() {
    final conversation = _conversation;
    if (conversation == null) {
      return;
    }
    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    if (accessToken != null && accessToken.trim().isNotEmpty) {
      context.read<WhatsappProvider>().fetchTemplates(
        accessToken,
        status: 'APPROVED',
      );
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (context) => Consumer<WhatsappProvider>(
        builder: (context, provider, _) => _TemplateSheet(
          templates: provider.templates,
          isLoading: provider.isLoadingTemplates,
          onTemplateSelected: _sendTemplate,
          contactName: conversation.name,
          contactFallback: conversation.phone,
          onRefresh: accessToken == null || accessToken.trim().isEmpty
              ? null
              : () => provider.fetchTemplates(accessToken, status: 'APPROVED'),
        ),
      ),
    );
  }

  Future<void> _refreshConversation() async {
    final conversation = _conversation;
    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    if (conversation == null || accessToken == null || accessToken.isEmpty) {
      _showSnack('Login required to refresh this conversation.');
      return;
    }

    await context.read<WhatsappProvider>().fetchMessages(
      accessToken: accessToken,
      leadId: conversation.leadId,
      forceRefresh: true,
    );
    if (!mounted) {
      return;
    }
    _showSnack('Conversation refreshed.');
    _scrollToBottom();
  }

  Future<void> _confirmClearConversation() async {
    final conversation = _conversation;
    if (conversation == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Clear conversation?',
          style: GoogleFonts.inter(
            color: AppColors.rmHeading,
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'This will clear the WhatsApp conversation history for ${conversation.name}.',
          style: GoogleFonts.inter(
            color: AppColors.rmBodyText,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rmPrimary,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              'Clear',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    final message = await context.read<WhatsappProvider>().clearConversation(
      accessToken: accessToken,
      conversation: conversation,
    );
    if (!mounted) {
      return;
    }
    _showSnack(message ?? 'Conversation cleared.');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final conversation = _conversation;
    if (conversation == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFF9F5),
          foregroundColor: AppColors.rmHeading,
          title: const Text('WhatsApp'),
        ),
        body: const Center(
          child: Text('Open a WhatsApp conversation from the inbox.'),
        ),
      );
    }

    final provider = context.read<WhatsappProvider>();
    final providerState = context.watch<WhatsappProvider>();
    final accessToken = context.watch<AuthProvider>().userModel?.accessToken;
    final leadDetail = providerState.leadDetailFor(conversation.leadId);
    final messagesListenable = provider.messagesListenableFor(
      conversation.leadId,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(
              conversation: conversation,
              lead: leadDetail,
              onRefresh: _refreshConversation,
              onClear: _confirmClearConversation,
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.rmPrimary,
                onRefresh: () => context.read<WhatsappProvider>().fetchMessages(
                  accessToken: accessToken,
                  leadId: conversation.leadId,
                  forceRefresh: true,
                ),
                child: _ChatMessageList(
                  controller: _scrollController,
                  conversation: conversation,
                  messagesListenable: messagesListenable,
                  isLoading: providerState.isLoadingMessages,
                  error: providerState.messageError,
                  hasMore: providerState.hasMoreMessagesFor(
                    conversation.leadId,
                  ),
                  onRetry: () => context.read<WhatsappProvider>().fetchMessages(
                    accessToken: accessToken,
                    leadId: conversation.leadId,
                    forceRefresh: true,
                  ),
                ),
              ),
            ),
            if (!conversation.canInferFreeformWindow)
              const _TemplateRequiredNotice(),
            _MessageComposer(
              isSending: providerState.isSending,
              requireTemplate: !conversation.canInferFreeformWindow,
              isRecordingVoice: _isRecordingVoice,
              onSend: _sendText,
              onTemplateTap: _showTemplateSheet,
              onAttachmentTap: _pickAttachment,
              onVoiceTap: _toggleVoiceRecording,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.conversation,
    required this.onRefresh,
    required this.onClear,
    this.lead,
  });

  final WhatsappConversation conversation;
  final RmLeadItem? lead;
  final VoidCallback onRefresh;
  final VoidCallback onClear;

  void _openLeadDetails(BuildContext context) {
    if (conversation.leadId.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Lead details are unavailable for this conversation.',
            ),
          ),
        );
      return;
    }

    Navigator.of(
      context,
    ).pushNamed(AppRoutes.whatsappLeadDetails, arguments: conversation);
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _displayLeadValue(lead?.name, conversation.name);
    final avatarUrl = _displayLeadValue(
      lead?.avatarUrl,
      conversation.avatarUrl,
    );

    return Container(
      height: 72.h,
      padding: EdgeInsets.only(right: 8.w),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF9F5),
        border: Border(bottom: BorderSide(color: Color(0xFFF1E5DC))),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.rmHeading),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _openLeadDetails(context),
              borderRadius: BorderRadius.circular(8.r),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 2.w),
                child: Row(
                  children: [
                    _HeaderAvatar(
                      conversation: conversation,
                      avatarUrl: avatarUrl,
                    ),
                    SizedBox(width: 9.w),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.playfairDisplay(
                              color: AppColors.rmHeading,
                              fontSize: 21.sp,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Last replied ${_relativeDate(conversation.lastUserReplyAt ?? conversation.lastMessageAt)}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: AppColors.rmBodyText,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              height: 1.05,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: onRefresh,
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.rmHeading,
              size: 21.sp,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Conversation actions',
            color: AppColors.white,
            surfaceTintColor: AppColors.white,
            icon: Icon(
              Icons.more_vert_rounded,
              color: AppColors.rmHeading,
              size: 21.sp,
            ),
            onSelected: (value) {
              if (value == 'clear') {
                onClear();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(
                      Icons.cleaning_services_outlined,
                      color: AppColors.rmPrimary,
                      size: 18.sp,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'Clear conversation',
                      style: GoogleFonts.inter(
                        color: AppColors.rmHeading,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.conversation, required this.avatarUrl});

  final WhatsappConversation conversation;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    final resolvedAvatarUrl = _resolveAssetUrl(avatarUrl);
    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    if (resolvedAvatarUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Image.network(
          resolvedAvatarUrl,
          headers: _authHeadersForUrl(resolvedAvatarUrl, accessToken),
          width: 38.r,
          height: 38.r,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              _InitialsAvatar(conversation: conversation),
        ),
      );
    }
    return _InitialsAvatar(conversation: conversation);
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.conversation});

  final WhatsappConversation conversation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38.r,
      height: 38.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFEFDCD4)),
      ),
      child: Text(
        conversation.initials,
        style: GoogleFonts.playfairDisplay(
          color: AppColors.rmPrimary,
          fontSize: 15.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChatMessageList extends StatelessWidget {
  const _ChatMessageList({
    required this.controller,
    required this.conversation,
    required this.messagesListenable,
    required this.isLoading,
    required this.error,
    required this.hasMore,
    required this.onRetry,
  });

  final ScrollController controller;
  final WhatsappConversation conversation;
  final ValueListenable<List<WhatsappMessage>> messagesListenable;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<WhatsappMessage>>(
      valueListenable: messagesListenable,
      builder: (context, messages, _) {
        if (isLoading && messages.isEmpty) {
          return const _CenteredChatState(
            message: 'Loading conversation...',
            showLoader: true,
          );
        }

        if (error != null && messages.isEmpty) {
          return _CenteredChatState(
            message: error!,
            actionLabel: 'Retry',
            onActionPressed: onRetry,
          );
        }

        if (messages.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: 120.h),
              const _CenteredChatState(message: 'No WhatsApp messages found.'),
            ],
          );
        }

        final entries = _buildTimelineEntries(messages);
        final loaderCount = hasMore ? 1 : 0;

        return ListView.builder(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 18.h),
          itemCount: entries.length + loaderCount,
          itemBuilder: (context, index) {
            if (hasMore && index == 0) {
              return Padding(
                padding: EdgeInsets.only(top: 14.h, bottom: 8.h),
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.rmPrimary,
                    ),
                  ),
                ),
              );
            }

            final entry = entries[index - loaderCount];
            if (entry.isDate) {
              return _DatePill(key: ValueKey(entry.key), label: entry.label!);
            }

            return _AnimatedMessageEntry(
              key: ValueKey(entry.key),
              child: _MessageBubble(message: entry.message!),
            );
          },
        );
      },
    );
  }
}

class _TimelineEntry {
  const _TimelineEntry.date(this.label) : message = null;
  const _TimelineEntry.message(this.message) : label = null;

  final String? label;
  final WhatsappMessage? message;

  bool get isDate => label != null;

  String get key {
    if (isDate) {
      return 'date:$label';
    }
    return 'message:${_stableMessageKey(message!)}';
  }
}

class _AnimatedMessageEntry extends StatelessWidget {
  const _AnimatedMessageEntry({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _CenteredChatState extends StatelessWidget {
  const _CenteredChatState({
    required this.message,
    this.showLoader = false,
    this.actionLabel,
    this.onActionPressed,
  });

  final String message;
  final bool showLoader;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.rmBodyText,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showLoader) ...[
              SizedBox(height: 16.h),
              const CircularProgressIndicator(color: AppColors.rmPrimary),
            ],
            if (actionLabel != null && onActionPressed != null) ...[
              SizedBox(height: 16.h),
              OutlinedButton(
                onPressed: onActionPressed,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.only(bottom: 32.h),
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(color: const Color(0xFFDADDE2)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.rmHeading,
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final WhatsappMessage message;

  @override
  Widget build(BuildContext context) {
    final isInbound = message.isInbound;
    final visibleText = _visibleMessageText(message);
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final maxBubbleWidth = (availableWidth * 0.76).clamp(180.0, 300.0);

        return Align(
          alignment: isInbound ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            margin: EdgeInsets.only(bottom: 16.h),
            child: Column(
              crossAxisAlignment: isInbound
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(10.w, 9.h, 10.w, 9.h),
                  decoration: BoxDecoration(
                    color: isInbound ? Colors.white : const Color(0xFFFFF4EA),
                    borderRadius: BorderRadius.circular(7.r),
                    border: isInbound
                        ? Border.all(color: const Color(0xFFF5D7C6))
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (visibleText.isNotEmpty)
                        Text(
                          visibleText,
                          style: GoogleFonts.playfairDisplay(
                            color: AppColors.rmHeading,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.38,
                          ),
                        ),
                      if (message.hasMedia) ...[
                        if (visibleText.isNotEmpty) SizedBox(height: 10.h),
                        _MediaPreview(message: message),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 3.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: GoogleFonts.inter(
                        color: AppColors.rmBodyText.withValues(alpha: 0.70),
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!isInbound) ...[
                      SizedBox(width: 4.w),
                      _StatusIcon(status: message.status),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.message});

  final WhatsappMessage message;

  @override
  Widget build(BuildContext context) {
    final accessToken = context.read<AuthProvider>().userModel?.accessToken;
    final mediaUrl = message.mediaUrl.isNotEmpty
        ? message.mediaUrl
        : message.mediaId.isNotEmpty
        ? '${ApiConstants.baseUrl}${ApiConstants.whatsappMedia(message.mediaId)}'
        : '';
    final resolvedMediaUrl = _resolveAssetUrl(mediaUrl);

    if (message.isAudio && resolvedMediaUrl.isNotEmpty) {
      return _AudioPreview(
        mediaUrl: resolvedMediaUrl,
        accessToken: accessToken,
        mimeType: message.mediaMimeType,
      );
    }

    if (!message.isDocument && resolvedMediaUrl.isNotEmpty) {
      final dataBytes = _bytesFromDataUrl(resolvedMediaUrl);
      if (dataBytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6.r),
          child: Image.memory(
            dataBytes,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _DocumentPreview(
              message: message,
              mediaUrl: resolvedMediaUrl,
              accessToken: accessToken,
            ),
          ),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(6.r),
        child: Image.network(
          resolvedMediaUrl,
          headers: _authHeadersForUrl(resolvedMediaUrl, accessToken),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _DocumentPreview(
            message: message,
            mediaUrl: resolvedMediaUrl,
            accessToken: accessToken,
          ),
        ),
      );
    }

    return _DocumentPreview(
      message: message,
      mediaUrl: resolvedMediaUrl,
      accessToken: accessToken,
    );
  }
}

class _AudioPreview extends StatefulWidget {
  const _AudioPreview({
    required this.mediaUrl,
    required this.accessToken,
    required this.mimeType,
  });

  final String mediaUrl;
  final String? accessToken;
  final String mimeType;

  @override
  State<_AudioPreview> createState() => _AudioPreviewState();
}

class _AudioPreviewState extends State<_AudioPreview> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<void>? _completeSubscription;
  String? _localPath;
  bool _isLoading = false;
  bool _isPlaying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) {
        return;
      }
      setState(() => _isPlaying = state == PlayerState.playing);
    });
    _completeSubscription = _player.onPlayerComplete.listen((_) {
      if (!mounted) {
        return;
      }
      setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _completeSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final path = await _loadAudioFile();
      await _player.play(
        DeviceFileSource(
          path,
          mimeType: widget.mimeType.isEmpty ? null : widget.mimeType,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'Unable to play audio.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String> _loadAudioFile() async {
    final existingPath = _localPath;
    if (existingPath != null && File(existingPath).existsSync()) {
      return existingPath;
    }

    final url = _resolveAssetUrl(widget.mediaUrl);
    final dataBytes = _bytesFromDataUrl(url);
    if (dataBytes != null) {
      final directory = await getTemporaryDirectory();
      final extension = _audioExtension(widget.mimeType, url);
      final file = File(
        '${directory.path}/whatsapp_audio_${url.hashCode.abs()}$extension',
      );
      await file.writeAsBytes(dataBytes, flush: true);
      _localPath = file.path;
      return file.path;
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _authHeadersForUrl(url, widget.accessToken),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Audio download failed with ${response.statusCode}');
    }

    final directory = await getTemporaryDirectory();
    final extension = _audioExtension(widget.mimeType, url);
    final file = File(
      '${directory.path}/whatsapp_audio_${url.hashCode.abs()}$extension',
    );
    await file.writeAsBytes(response.bodyBytes, flush: true);
    _localPath = file.path;
    return file.path;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 210.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _isLoading ? null : _togglePlayback,
            borderRadius: BorderRadius.circular(999.r),
            child: Container(
              width: 34.r,
              height: 34.r,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.rmPrimary,
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 20.sp,
                    ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice message',
                  style: GoogleFonts.inter(
                    color: AppColors.rmHeading,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _error ?? 'Tap to play',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _error == null
                        ? AppColors.rmBodyText
                        : AppColors.danger,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
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

class _DocumentPreview extends StatefulWidget {
  const _DocumentPreview({
    required this.message,
    required this.mediaUrl,
    required this.accessToken,
  });

  final WhatsappMessage message;
  final String mediaUrl;
  final String? accessToken;

  @override
  State<_DocumentPreview> createState() => _DocumentPreviewState();
}

class _DocumentPreviewState extends State<_DocumentPreview> {
  bool _isOpening = false;

  Future<void> _openDocument() async {
    if (_isOpening || widget.mediaUrl.isEmpty) {
      return;
    }

    setState(() => _isOpening = true);
    try {
      final file = await _downloadDocument();
      final opened = await launchUrl(
        Uri.file(file.path),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        throw Exception('Unable to open downloaded document.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Unable to open WhatsApp media.')),
        );
    } finally {
      if (mounted) {
        setState(() => _isOpening = false);
      }
    }
  }

  Future<File> _downloadDocument() async {
    final dataBytes = _bytesFromDataUrl(widget.mediaUrl);
    if (dataBytes != null) {
      return _writeDocumentBytes(dataBytes);
    }

    final response = await http.get(
      Uri.parse(widget.mediaUrl),
      headers: _authHeadersForUrl(widget.mediaUrl, widget.accessToken),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Media download failed with ${response.statusCode}');
    }

    return _writeDocumentBytes(response.bodyBytes);
  }

  Future<File> _writeDocumentBytes(List<int> bytes) async {
    final directory = await getTemporaryDirectory();
    final mediaDirectory = Directory('${directory.path}/whatsapp_media');
    if (!mediaDirectory.existsSync()) {
      await mediaDirectory.create(recursive: true);
    }

    final fileName = _safeMediaFileName(
      widget.message.mediaFileName,
      widget.message.mediaMimeType,
      widget.mediaUrl,
    );
    final file = File(
      '${mediaDirectory.path}${Platform.pathSeparator}$fileName',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.message.mediaFileName.isEmpty
        ? 'Attachment'
        : widget.message.mediaFileName;
    return InkWell(
      onTap: widget.mediaUrl.isEmpty ? null : _openDocument,
      borderRadius: BorderRadius.circular(5.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: Row(
          children: [
            Icon(_mediaIcon(widget.message), color: Colors.red, size: 22.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.rmHeading,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    widget.mediaUrl.isEmpty
                        ? 'Media URL unavailable'
                        : widget.message.mediaMimeType.isEmpty
                        ? 'Tap to open'
                        : widget.message.mediaMimeType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.rmBodyText,
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (_isOpening)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.rmPrimary,
                ),
              )
            else
              Icon(Icons.download, color: AppColors.rmPrimary, size: 18.sp),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    if (normalized == 'SENDING' || normalized == 'PENDING') {
      return SizedBox(
        width: 13.sp,
        height: 13.sp,
        child: CircularProgressIndicator(
          strokeWidth: 1.6,
          color: AppColors.rmBodyText.withValues(alpha: 0.65),
        ),
      );
    }
    if (normalized == 'FAILED') {
      return Icon(Icons.error_outline, color: AppColors.danger, size: 13.sp);
    }
    if (normalized == 'READ') {
      return Icon(Icons.done_all, color: Colors.blue, size: 13.sp);
    }
    if (normalized == 'DELIVERED') {
      return Icon(Icons.done_all, color: AppColors.rmBodyText, size: 13.sp);
    }
    return Icon(Icons.done, color: AppColors.rmBodyText, size: 13.sp);
  }
}

class _TemplateRequiredNotice extends StatelessWidget {
  const _TemplateRequiredNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(28.w, 10.h, 18.w, 10.h),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBF1),
        border: Border(top: BorderSide(color: Color(0xFFF5E5C3))),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.accent,
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Send an approved template first. Free-form replies unlock for 24 hours after the customer responds.',
              style: GoogleFonts.inter(
                color: AppColors.rmBodyText,
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageComposer extends StatefulWidget {
  const _MessageComposer({
    required this.isSending,
    required this.requireTemplate,
    required this.isRecordingVoice,
    required this.onSend,
    required this.onTemplateTap,
    required this.onAttachmentTap,
    required this.onVoiceTap,
  });

  final bool isSending;
  final bool requireTemplate;
  final bool isRecordingVoice;
  final Future<void> Function(String text) onSend;
  final VoidCallback onTemplateTap;
  final VoidCallback onAttachmentTap;
  final VoidCallback onVoiceTap;

  @override
  State<_MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<_MessageComposer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSending || widget.requireTemplate) {
      return;
    }
    await widget.onSend(text);
    if (!mounted) {
      return;
    }
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final canSend =
        _controller.text.trim().isNotEmpty &&
        !widget.isSending &&
        !widget.requireTemplate;
    final trailingIcon = canSend
        ? Icons.send
        : widget.requireTemplate
        ? Icons.assignment_outlined
        : widget.isRecordingVoice
        ? Icons.stop
        : Icons.mic;
    final trailingTap = canSend
        ? _submit
        : widget.requireTemplate
        ? widget.onTemplateTap
        : widget.onVoiceTap;

    return Container(
      padding: EdgeInsets.fromLTRB(10.w, 7.h, 10.w, 8.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE9E5E2))),
      ),
      child: Row(
        children: [
          _RoundIconButton(
            icon: Icons.assignment_outlined,
            onTap: widget.onTemplateTap,
            filled: true,
            tooltip: 'Quick Templates',
          ),
          SizedBox(width: 8.w),
          _RoundIconButton(
            icon: Icons.add,
            onTap: widget.onAttachmentTap,
            outlined: true,
            tooltip: 'Attach Document',
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: InkWell(
              onTap: widget.requireTemplate ? widget.onTemplateTap : null,
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                height: 40.h,
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: const Color(0xFF8C8C8C)),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.requireTemplate
                          ? Icons.assignment_outlined
                          : Icons.message_outlined,
                      color: AppColors.rmBodyText,
                      size: 17.sp,
                    ),
                    SizedBox(width: 7.w),
                    Expanded(
                      child: widget.requireTemplate
                          ? Text(
                              'Choose an approved template first',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: AppColors.rmBodyText,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : TextField(
                              controller: _controller,
                              enabled: !widget.isSending,
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                hintText: 'Type a message',
                                border: InputBorder.none,
                                isDense: true,
                                hintStyle: GoogleFonts.inter(
                                  color: AppColors.rmBodyText.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontSize: 12.5.sp,
                                ),
                              ),
                              style: GoogleFonts.inter(
                                color: AppColors.rmHeading,
                                fontSize: 13.sp,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          _RoundIconButton(
            icon: trailingIcon,
            onTap: trailingTap,
            filled: true,
            loading: widget.isSending,
            tooltip: canSend
                ? 'Send'
                : widget.requireTemplate
                ? 'Quick Templates'
                : widget.isRecordingVoice
                ? 'Stop and Send'
                : 'Voice Note',
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.outlined = false,
    this.loading = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final bool outlined;
  final bool loading;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(999.r),
      child: Container(
        width: 34.r,
        height: 34.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.rmPrimary : Colors.white,
          shape: BoxShape.circle,
          border: outlined ? Border.all(color: AppColors.rmPrimary) : null,
        ),
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                icon,
                color: filled ? Colors.white : AppColors.rmPrimary,
                size: 19.sp,
              ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class _TemplateSheet extends StatelessWidget {
  const _TemplateSheet({
    required this.templates,
    required this.isLoading,
    required this.onTemplateSelected,
    required this.contactName,
    required this.contactFallback,
    this.onRefresh,
  });

  final List<WhatsappTemplate> templates;
  final bool isLoading;
  final ValueChanged<WhatsappTemplate> onTemplateSelected;
  final String contactName;
  final String contactFallback;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 18.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Quick Templates',
                  style: GoogleFonts.inter(
                    color: AppColors.rmHeading,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.rmPrimary),
                ),
              )
            else if (templates.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 28.h),
                child: Column(
                  children: [
                    Text(
                      'No approved templates returned by the backend.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.rmBodyText,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (onRefresh != null) ...[
                      SizedBox(height: 14.h),
                      OutlinedButton.icon(
                        onPressed: onRefresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    final preview = template.previewForContact(
                      contactName,
                      fallback: contactFallback,
                    );
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.description_outlined,
                        color: AppColors.rmPrimary,
                      ),
                      title: Text(
                        template.title,
                        style: GoogleFonts.inter(
                          color: AppColors.rmHeading,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        preview.isEmpty
                            ? '${template.language} ${template.status}'
                            : preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => onTemplateSelected(template),
                    );
                  },
                  separatorBuilder: (_, _) =>
                      const Divider(color: Color(0xFFEFEAE7)),
                  itemCount: templates.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PendingWhatsappMedia {
  const _PendingWhatsappMedia({
    required this.dataUrl,
    required this.fileName,
    required this.mimeType,
    required this.size,
    required this.messageType,
  });

  final String dataUrl;
  final String fileName;
  final String mimeType;
  final int size;
  final String messageType;

  factory _PendingWhatsappMedia.fromBytes({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    String? messageType,
  }) {
    final resolvedMimeType = mimeType.trim().isEmpty
        ? 'application/octet-stream'
        : mimeType.trim();
    return _PendingWhatsappMedia(
      dataUrl: 'data:$resolvedMimeType;base64,${base64Encode(bytes)}',
      fileName: fileName.trim().isEmpty ? 'attachment' : fileName.trim(),
      mimeType: resolvedMimeType,
      size: bytes.length,
      messageType: messageType ?? _messageTypeForMime(resolvedMimeType),
    );
  }
}

String _resolveAssetUrl(String value) {
  final raw = value.trim();
  if (raw.isEmpty) {
    return '';
  }
  if (raw.startsWith('//')) {
    return 'https:$raw';
  }
  final uri = Uri.tryParse(raw);
  if (uri != null && uri.hasScheme) {
    return raw;
  }

  final base = Uri.parse(ApiConstants.baseUrl);
  final origin = '${base.scheme}://${base.authority}';
  if (raw.startsWith('/')) {
    return '$origin$raw';
  }
  return '${ApiConstants.baseUrl}/$raw';
}

String _displayLeadValue(String? value, String fallback) {
  final text = value?.trim() ?? '';
  if (text.isEmpty ||
      text == '-' ||
      text.toLowerCase() == 'unnamed lead' ||
      text.toLowerCase() == 'unknown contact') {
    return fallback;
  }
  return text;
}

String _visibleMessageText(WhatsappMessage message) {
  final text = message.content.trim();
  if (text.isEmpty || _isMediaPlaceholderText(text)) {
    if (message.hasMedia) {
      return '';
    }
    return message.displayText;
  }
  return message.displayText;
}

bool _isMediaPlaceholderText(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll('{', '')
      .replaceAll('}', '')
      .replaceAll(RegExp(r'\s+'), ' ');
  return normalized == 'media message' ||
      normalized == 'image message' ||
      normalized == 'document message' ||
      normalized == 'audio message' ||
      normalized == 'video message';
}

Map<String, String>? _authHeadersForUrl(String url, String? accessToken) {
  if (accessToken == null || accessToken.trim().isEmpty) {
    return null;
  }
  final base = Uri.parse(ApiConstants.baseUrl);
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host != base.host) {
    return null;
  }
  return {'Authorization': 'Bearer $accessToken'};
}

Uint8List? _bytesFromDataUrl(String value) {
  final match = RegExp(r'^data:[^,]*;base64,(.+)$').firstMatch(value.trim());
  if (match == null) {
    return null;
  }
  try {
    return base64Decode(match.group(1)!);
  } catch (_) {
    return null;
  }
}

String _mimeTypeForFile(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  if (lower.endsWith('.gif')) {
    return 'image/gif';
  }
  if (lower.endsWith('.mp4')) {
    return 'video/mp4';
  }
  if (lower.endsWith('.pdf')) {
    return 'application/pdf';
  }
  if (lower.endsWith('.doc')) {
    return 'application/msword';
  }
  if (lower.endsWith('.docx')) {
    return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  }
  if (lower.endsWith('.xls')) {
    return 'application/vnd.ms-excel';
  }
  if (lower.endsWith('.xlsx')) {
    return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  }
  if (lower.endsWith('.txt')) {
    return 'text/plain';
  }
  if (lower.endsWith('.mp3')) {
    return 'audio/mpeg';
  }
  if (lower.endsWith('.m4a')) {
    return 'audio/mp4';
  }
  if (lower.endsWith('.ogg') || lower.endsWith('.opus')) {
    return 'audio/ogg';
  }
  if (lower.endsWith('.wav')) {
    return 'audio/wav';
  }
  return 'application/octet-stream';
}

String _messageTypeForMime(String mimeType) {
  final lower = mimeType.toLowerCase();
  if (lower.startsWith('image/')) {
    return 'image';
  }
  if (lower.startsWith('audio/')) {
    return 'audio';
  }
  if (lower.startsWith('video/')) {
    return 'video';
  }
  return 'document';
}

String _audioExtension(String mimeType, String url) {
  final normalized = mimeType.toLowerCase();
  if (normalized.contains('ogg')) {
    return '.ogg';
  }
  if (normalized.contains('mpeg') || normalized.contains('mp3')) {
    return '.mp3';
  }
  if (normalized.contains('mp4') || normalized.contains('m4a')) {
    return '.m4a';
  }
  if (normalized.contains('wav')) {
    return '.wav';
  }
  if (normalized.contains('amr')) {
    return '.amr';
  }

  final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
  for (final extension in ['.ogg', '.opus', '.mp3', '.m4a', '.wav', '.amr']) {
    if (path.endsWith(extension)) {
      return extension;
    }
  }
  return '.ogg';
}

IconData _mediaIcon(WhatsappMessage message) {
  final type = message.type.toLowerCase();
  final mime = message.mediaMimeType.toLowerCase();
  final fileName = message.mediaFileName.toLowerCase();
  if (type == 'image' || mime.startsWith('image/')) {
    return Icons.image_outlined;
  }
  if (type == 'video' || mime.startsWith('video/')) {
    return Icons.videocam_outlined;
  }
  if (fileName.endsWith('.pdf') || mime.contains('pdf')) {
    return Icons.picture_as_pdf;
  }
  return Icons.insert_drive_file_outlined;
}

String _safeMediaFileName(String fileName, String mimeType, String url) {
  final cleaned = fileName
      .trim()
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ');
  if (cleaned.isNotEmpty && cleaned.contains('.')) {
    return cleaned;
  }

  final extension = _documentExtension(mimeType, url);
  final baseName = cleaned.isEmpty
      ? 'whatsapp_media_${url.hashCode.abs()}'
      : cleaned;
  return '$baseName$extension';
}

String _documentExtension(String mimeType, String url) {
  final normalized = mimeType.toLowerCase();
  if (normalized.contains('pdf')) {
    return '.pdf';
  }
  if (normalized.contains('jpeg') || normalized.contains('jpg')) {
    return '.jpg';
  }
  if (normalized.contains('png')) {
    return '.png';
  }
  if (normalized.contains('mp4')) {
    return '.mp4';
  }
  if (normalized.contains('mpeg') || normalized.contains('mp3')) {
    return '.mp3';
  }

  final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
  final extensionMatch = RegExp(r'\.[a-z0-9]{2,5}$').firstMatch(path);
  return extensionMatch?.group(0) ?? '.bin';
}

List<_TimelineEntry> _buildTimelineEntries(List<WhatsappMessage> messages) {
  final entries = <_TimelineEntry>[];
  DateTime? previousDate;

  for (final message in messages) {
    final current = message.createdAt;
    if (_shouldShowDate(previousDate, current)) {
      entries.add(_TimelineEntry.date(_datePillLabel(current)));
    }
    entries.add(_TimelineEntry.message(message));
    previousDate = current ?? previousDate;
  }

  return entries;
}

String _stableMessageKey(WhatsappMessage message) {
  if (message.wamId.isNotEmpty) {
    return message.wamId;
  }
  if (message.id.isNotEmpty) {
    return message.id;
  }
  final createdAt = message.createdAt?.toIso8601String() ?? '';
  return '${message.direction}:${message.content}:$createdAt';
}

bool _shouldShowDate(DateTime? previous, DateTime? current) {
  if (current == null) {
    return previous == null;
  }
  if (previous == null) {
    return true;
  }
  return previous.year != current.year ||
      previous.month != current.month ||
      previous.day != current.day;
}

String _datePillLabel(DateTime? value) {
  if (value == null) {
    return 'Earlier';
  }
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(value.year, value.month, value.day);
  final days = today.difference(date).inDays;
  if (days == 0) {
    return 'Today';
  }
  if (days == 1) {
    return 'Yesterday';
  }
  return 'Earlier';
}

String _formatTime(DateTime? value) {
  if (value == null) {
    return '';
  }
  return DateFormat('hh:mm a').format(value);
}

String _relativeDate(DateTime? value) {
  if (value == null) {
    return 'not available';
  }
  final difference = DateTime.now().difference(value);
  if (difference.inDays <= 0) {
    return 'today';
  }
  if (difference.inDays == 1) {
    return 'yesterday';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  }
  return DateFormat('dd MMM yyyy').format(value);
}
