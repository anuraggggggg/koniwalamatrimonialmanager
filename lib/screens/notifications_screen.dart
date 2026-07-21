import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/constants/app_colors.dart';
import 'package:koniwalamatrimonial/models/app_notification.dart';
import 'package:koniwalamatrimonial/providers/auth_provider.dart';
import 'package:koniwalamatrimonial/providers/notifications_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final accessToken = context.read<AuthProvider>().userModel?.accessToken;
      context.read<NotificationsProvider>().fetchNotifications(
        accessToken,
        forceRefresh: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final notificationsProvider = context.watch<NotificationsProvider>();
    final user = authProvider.userModel?.user;
    final notifications = notificationsProvider.notifications;

    return Scaffold(
      backgroundColor: AppColors.rmSoftPink,
      appBar: AppBar(
        backgroundColor: AppColors.rmPrimary,
        foregroundColor: AppColors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.inter(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              _roleLabel(user?.role ?? 'User'),
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.white.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: notificationsProvider.isLoading
                ? null
                : notificationsProvider.retry,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: notificationsProvider.retry,
          child: Builder(
            builder: (context) {
              if (notificationsProvider.isLoading && notifications.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (notificationsProvider.error != null &&
                  notifications.isEmpty) {
                return ListView(
                  padding: EdgeInsets.all(24.w),
                  children: [
                    SizedBox(height: 120.h),
                    Icon(
                      Icons.notifications_off_outlined,
                      color: AppColors.rmPrimary.withValues(alpha: 0.55),
                      size: 48.sp,
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      notificationsProvider.error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.rmPrimary,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Center(
                      child: ElevatedButton(
                        onPressed: notificationsProvider.retry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.rmPrimary,
                          foregroundColor: AppColors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
                );
              }

              if (notifications.isEmpty) {
                return ListView(
                  padding: EdgeInsets.all(24.w),
                  children: [
                    SizedBox(height: 120.h),
                    Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.rmPrimary.withValues(alpha: 0.55),
                      size: 48.sp,
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'No notifications available.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.rmPrimary,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16.w),
                itemCount: notifications.length,
                separatorBuilder: (_, index) => SizedBox(height: 10.h),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  return _NotificationCard(item: item);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    return role
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(item.priority, item.isRead);
    final accessToken = context.read<AuthProvider>().userModel?.accessToken;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: item.isRead
              ? AppColors.rmPaleRoseBorder
              : accent.withValues(alpha: 0.32),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.rmCardShadow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconForType(item.type), color: accent, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.inter(
                          color: AppColors.rmHeading,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    _PriorityChip(
                      label: item.priority.isEmpty ? 'normal' : item.priority,
                      color: accent,
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  item.message.isEmpty ? 'No details available.' : item.message,
                  style: GoogleFonts.inter(
                    color: AppColors.rmBodyText,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                if (item.hasAudio) ...[
                  SizedBox(height: 12.h),
                  _NotificationAudioPlayer(
                    audioUrl: _resolveAssetUrl(item.audioUrl),
                    accessToken: accessToken,
                    mimeType: item.audioMimeType,
                    fileName: item.audioFileName,
                    accent: accent,
                  ),
                ],
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14.sp,
                      color: AppColors.rmMutedText,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        _formatDate(item.createdAt),
                        style: GoogleFonts.inter(
                          color: AppColors.rmMutedText,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!item.isRead)
                      Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'follow_up':
      case 'follow-up':
        return Icons.event_available_outlined;
      case 'lead':
      case 'lead_assigned':
        return Icons.person_search_outlined;
      case 'payment':
        return Icons.payments_outlined;
      case 'profile':
        return Icons.account_circle_outlined;
      case 'attendance':
        return Icons.fingerprint_outlined;
      case 'audio':
      case 'voice':
      case 'voice_note':
      case 'voice-note':
        return Icons.graphic_eq_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  static Color _accentColor(String priority, bool isRead) {
    if (isRead) {
      return AppColors.rmPrimary;
    }

    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return const Color(0xFFB91C1C);
      case 'medium':
        return const Color(0xFFD97706);
      case 'low':
        return const Color(0xFF15803D);
      default:
        return AppColors.rmPrimary;
    }
  }

  static String _formatDate(String value) {
    if (value.trim().isEmpty) {
      return 'Recent';
    }

    final date = DateTime.tryParse(value);
    if (date == null) {
      return value;
    }

    return DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal());
  }
}

class _NotificationAudioPlayer extends StatefulWidget {
  const _NotificationAudioPlayer({
    required this.audioUrl,
    required this.accessToken,
    required this.mimeType,
    required this.fileName,
    required this.accent,
  });

  final String audioUrl;
  final String? accessToken;
  final String mimeType;
  final String fileName;
  final Color accent;

  @override
  State<_NotificationAudioPlayer> createState() =>
      _NotificationAudioPlayerState();
}

class _NotificationAudioPlayerState extends State<_NotificationAudioPlayer> {
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
  void didUpdateWidget(covariant _NotificationAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl) {
      _player.stop();
      _localPath = null;
      _isPlaying = false;
      _error = null;
    }
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

    if (widget.audioUrl.trim().isEmpty) {
      setState(() => _error = 'Voice note is not available.');
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
          mimeType: _playbackMimeType(path, widget.mimeType),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'Unable to play voice note.');
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

    final url = widget.audioUrl.trim();
    final dataBytes = _bytesFromDataUrl(url);
    if (dataBytes != null) {
      final file = await _writeTempAudio(dataBytes, url);
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

    final file = await _writeTempAudio(response.bodyBytes, url);
    _localPath = file.path;
    return file.path;
  }

  Future<File> _writeTempAudio(List<int> bytes, String url) async {
    final directory = await getTemporaryDirectory();
    final extension = _audioExtension(widget.mimeType, widget.fileName, url);
    final file = File(
      '${directory.path}/notification_audio_${url.hashCode.abs()}$extension',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: widget.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: widget.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _isLoading ? null : _togglePlayback,
            borderRadius: BorderRadius.circular(999.r),
            child: Container(
              width: 36.r,
              height: 36.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.accent,
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow,
                      color: Colors.white,
                      size: 22.sp,
                    ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice note',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.rmHeading,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _error ?? (_isPlaying ? 'Playing' : 'Tap to play'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _error == null
                        ? AppColors.rmBodyText
                        : AppColors.danger,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.graphic_eq_rounded,
            color: widget.accent.withValues(alpha: 0.78),
            size: 20.sp,
          ),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final normalized = label.trim().isEmpty ? 'normal' : label;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalized.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
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

List<int>? _bytesFromDataUrl(String value) {
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

String _audioExtension(String mimeType, String fileName, String url) {
  final normalized = mimeType.toLowerCase();
  final path = '${Uri.tryParse(url)?.path ?? ''} $fileName'.toLowerCase();
  for (final extension in ['.ogg', '.opus', '.mp3', '.m4a', '.wav', '.amr']) {
    if (path.contains(extension)) {
      return extension;
    }
  }

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

  if (normalized.contains('webm')) {
    return '.webm';
  }
  return '.ogg';
}

String? _playbackMimeType(String path, String mimeType) {
  final lowerPath = path.toLowerCase();
  if (lowerPath.endsWith('.wav')) {
    return 'audio/wav';
  }
  if (lowerPath.endsWith('.m4a')) {
    return 'audio/mp4';
  }
  if (lowerPath.endsWith('.mp3')) {
    return 'audio/mpeg';
  }
  if (lowerPath.endsWith('.ogg') || lowerPath.endsWith('.opus')) {
    return 'audio/ogg';
  }
  if (lowerPath.endsWith('.webm')) {
    return null;
  }

  final normalized = mimeType.trim().toLowerCase();
  if (normalized.isEmpty || normalized.contains('webm')) {
    return null;
  }
  return mimeType;
}
