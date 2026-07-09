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
  final Map<String, dynamic> raw;

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
