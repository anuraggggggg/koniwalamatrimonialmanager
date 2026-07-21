class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.createdAt,
    required this.isRead,
    required this.targetRoute,
    required this.audioUrl,
    required this.audioMimeType,
    required this.audioFileName,
    required this.raw,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final String priority;
  final String createdAt;
  final bool isRead;
  final String targetRoute;
  final String audioUrl;
  final String audioMimeType;
  final String audioFileName;
  final Map<String, dynamic> raw;

  bool get hasAudio => audioUrl.trim().isNotEmpty;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final id = _readText(
      json['id'],
      fallback: _readText(
        json['_id'],
        fallback: DateTime.now().toIso8601String(),
      ),
    );
    final title = _readText(
      json['title'],
      fallback: _readText(
        json['subject'],
        fallback: _readText(
          json['heading'],
          fallback: _titleFromType(_readText(json['type'])),
        ),
      ),
    );
    final message = _readText(
      json['message'],
      fallback: _readText(
        json['description'],
        fallback: _readText(
          json['body'],
          fallback: _readText(
            json['content'],
            fallback: 'No details available.',
          ),
        ),
      ),
    );

    return AppNotification(
      id: id,
      title: title.isEmpty ? 'Notification' : title,
      message: message,
      type: _readText(json['type'], fallback: 'general'),
      priority: _readText(json['priority'], fallback: 'normal'),
      createdAt: _readText(
        json['createdAt'],
        fallback: _readText(
          json['timestamp'],
          fallback: _readText(json['date']),
        ),
      ),
      isRead: _readBool(
        json['isRead'],
        fallback: _readText(json['status']).toLowerCase() == 'read',
      ),
      targetRoute: _readText(
        json['targetRoute'],
        fallback: _readText(
          json['route'],
          fallback: _readText(json['actionUrl']),
        ),
      ),
      audioUrl: _audioUrlFromJson(json),
      audioMimeType: _audioMimeTypeFromJson(json),
      audioFileName: _firstDeepText(json, const [
        'audioFileName',
        'fileName',
        'mediaFileName',
        'originalName',
        'name',
      ]),
      raw: json,
    );
  }

  static List<AppNotification> listFromAny(dynamic payload) {
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map(
            (item) => AppNotification.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }

    if (payload is! Map<String, dynamic>) {
      return const [];
    }

    return listFromPayload(payload);
  }

  static List<AppNotification> listFromPayload(Map<String, dynamic> json) {
    final payload = _unwrapPayload(json);

    for (final key in const [
      'notifications',
      'items',
      'results',
      'rows',
      'data',
    ]) {
      final value = payload[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map(
              (item) =>
                  AppNotification.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
    }

    if (payload.isNotEmpty &&
        (payload.containsKey('title') || payload.containsKey('message'))) {
      return [AppNotification.fromJson(payload)];
    }

    return const [];
  }

  static Map<String, dynamic> _unwrapPayload(Map<String, dynamic> json) {
    for (final key in const ['data', 'payload']) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
    }
    return json;
  }

  static String _readText(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static bool _readBool(dynamic value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().trim().toLowerCase();
    if (text == 'true' || text == '1' || text == 'yes') {
      return true;
    }
    if (text == 'false' || text == '0' || text == 'no') {
      return false;
    }
    return fallback;
  }

  static String _firstDeepText(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    final direct = _firstTextFromMap(json, keys);
    if (direct.isNotEmpty) {
      return direct;
    }

    for (final nestedKey in const [
      'audio',
      'voiceNote',
      'voice_note',
      'media',
      'attachment',
      'file',
      'metadata',
      'payload',
      'data',
    ]) {
      final nested = _readMap(json[nestedKey]);
      if (nested == null) {
        continue;
      }

      final nestedValue = _firstDeepText(nested, keys);
      if (nestedValue.isNotEmpty) {
        return nestedValue;
      }
    }

    return fallback;
  }

  static String _audioUrlFromJson(Map<String, dynamic> json) {
    final directAudio = _firstDeepText(json, const [
      'audioUrl',
      'voiceNoteUrl',
      'voiceUrl',
      'voice_note_url',
      'recordingUrl',
      'recording_url',
    ]);
    if (directAudio.isNotEmpty) {
      return directAudio;
    }

    for (final nestedKey in const [
      'audio',
      'voiceNote',
      'voice_note',
      'recording',
    ]) {
      final nested = _readMap(json[nestedKey]);
      if (nested == null) {
        continue;
      }

      final nestedAudio = _firstDeepText(nested, const [
        'url',
        'path',
        'mediaUrl',
        'fileUrl',
        'audioUrl',
        'voiceNoteUrl',
      ]);
      if (nestedAudio.isNotEmpty) {
        return nestedAudio;
      }
    }

    if (!_looksLikeAudioNotification(json)) {
      return '';
    }

    return _firstDeepText(json, const ['mediaUrl', 'fileUrl', 'url', 'path']);
  }

  static String _audioMimeTypeFromJson(Map<String, dynamic> json) {
    final mimeType = _firstDeepText(json, const [
      'audioMimeType',
      'mimeType',
      'mediaMimeType',
      'contentType',
    ]);
    return mimeType.isEmpty ? 'audio/ogg' : mimeType;
  }

  static bool _looksLikeAudioNotification(Map<String, dynamic> json) {
    final text = [
      json['type'],
      json['title'],
      json['subject'],
      json['heading'],
      json['message'],
      json['description'],
      json['body'],
      json['content'],
      _audioMimeTypeFromJson(json),
    ].map((value) => value?.toString().toLowerCase() ?? '').join(' ');

    return text.contains('voice') ||
        text.contains('audio') ||
        text.contains('recording') ||
        text.contains('audio/');
  }

  static String _firstTextFromMap(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map || value is List) {
        continue;
      }

      final text = _readText(value);
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static String _titleFromType(String type) {
    if (type.trim().isEmpty) {
      return 'Notification';
    }

    return type
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }
}
