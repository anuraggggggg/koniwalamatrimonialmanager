import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:koniwalamatrimonial/rm/models/whatsapp_models.dart';
import 'package:koniwalamatrimonial/services/whatsapp_service.dart';

typedef ChatUpdatesSourceFactory = ChatUpdatesSource Function();

abstract class ChatUpdatesSource {
  Stream<List<WhatsappMessage>> get updates;
  Stream<Object> get errors;

  Future<void> start({
    required String accessToken,
    required String leadId,
    List<WhatsappMessage> seedMessages = const [],
  });

  void setActive(bool active);
  void pause();
  void resume();
  Future<void> stop();
  Future<void> dispose();
}

class PollingChatUpdatesSource implements ChatUpdatesSource {
  PollingChatUpdatesSource(this._service);

  final WhatsappService _service;
  final StreamController<List<WhatsappMessage>> _updatesController =
      StreamController<List<WhatsappMessage>>.broadcast();
  final StreamController<Object> _errorsController =
      StreamController<Object>.broadcast();
  final Set<String> _seenMessageKeys = <String>{};

  Timer? _timer;
  String? _accessToken;
  String? _leadId;
  bool _active = true;
  bool _paused = false;
  bool _disposed = false;
  bool _inFlight = false;
  int _failureCount = 0;

  static const Duration _activeInterval = Duration(seconds: 4);
  static const Duration _idleInterval = Duration(seconds: 20);
  static const Duration _maxBackoff = Duration(seconds: 60);

  @override
  Stream<List<WhatsappMessage>> get updates => _updatesController.stream;

  @override
  Stream<Object> get errors => _errorsController.stream;

  @override
  Future<void> start({
    required String accessToken,
    required String leadId,
    List<WhatsappMessage> seedMessages = const [],
  }) async {
    _accessToken = accessToken;
    _leadId = leadId;
    _paused = false;
    _disposed = false;
    _seed(seedMessages);
    await _pollOnce();
    _scheduleNext();
  }

  @override
  void setActive(bool active) {
    if (_active == active) {
      return;
    }
    _active = active;
    _scheduleNext();
  }

  @override
  void pause() {
    _paused = true;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void resume() {
    if (_disposed) {
      return;
    }
    _paused = false;
    _scheduleNext(immediate: true);
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _paused = true;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await _updatesController.close();
    await _errorsController.close();
  }

  void _seed(List<WhatsappMessage> messages) {
    for (final message in messages) {
      _seenMessageKeys.add(_messageKey(message));
    }
  }

  void _scheduleNext({bool immediate = false}) {
    _timer?.cancel();
    if (_disposed || _paused || _leadId == null || _accessToken == null) {
      return;
    }

    final interval = immediate ? Duration.zero : _currentInterval();
    _timer = Timer(interval, () async {
      await _pollOnce();
      _scheduleNext();
    });
  }

  Duration _currentInterval() {
    if (_failureCount > 0) {
      final seconds = 4 * (1 << (_failureCount - 1));
      return Duration(seconds: seconds.clamp(4, _maxBackoff.inSeconds).toInt());
    }
    return _active ? _activeInterval : _idleInterval;
  }

  Future<void> _pollOnce() async {
    final accessToken = _accessToken;
    final leadId = _leadId;
    if (_inFlight ||
        _disposed ||
        _paused ||
        accessToken == null ||
        accessToken.trim().isEmpty ||
        leadId == null ||
        leadId.isEmpty) {
      return;
    }

    _inFlight = true;
    try {
      final payload = await _service.fetchMessages(
        accessToken: accessToken,
        leadId: leadId,
        limit: 30,
      );
      final result = parseWhatsappMessages(payload);
      final fresh = _newMessages(result.items);
      _failureCount = 0;
      if (fresh.isNotEmpty && !_updatesController.isClosed) {
        _updatesController.add(fresh);
      }
    } catch (error) {
      _failureCount++;
      if (kDebugMode) {
        debugPrint('[WhatsApp Updates] poll failed: $error');
      }
      if (!_errorsController.isClosed) {
        _errorsController.add(error);
      }
    } finally {
      _inFlight = false;
    }
  }

  List<WhatsappMessage> _newMessages(List<WhatsappMessage> messages) {
    final fresh = <WhatsappMessage>[];
    for (final message in messages) {
      final key = _messageKey(message);
      if (_seenMessageKeys.add(key)) {
        fresh.add(message);
      }
    }
    fresh.sort((a, b) {
      final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return left.compareTo(right);
    });
    return fresh;
  }

  String _messageKey(WhatsappMessage message) {
    if (message.wamId.isNotEmpty) {
      return 'wam:${message.wamId}';
    }
    if (message.id.isNotEmpty) {
      return 'id:${message.id}';
    }
    final createdAt = message.createdAt?.toIso8601String() ?? '';
    return 'fallback:${message.direction}:${message.content}:$createdAt';
  }
}
