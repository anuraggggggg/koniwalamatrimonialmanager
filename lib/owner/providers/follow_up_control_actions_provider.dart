import 'package:koniwalamatrimonial/providers/base_api_provider.dart';
import 'package:koniwalamatrimonial/services/follow_up_control_service.dart';

class FollowUpControlActionsProvider extends BaseApiProvider {
  FollowUpControlActionsProvider(this._service);

  final FollowUpControlService _service;
  final Set<String> _messageRequestIds = {};
  final Set<String> _voiceNoteRequestIds = {};

  bool isSendingMessage(String teamMemberId) {
    return _messageRequestIds.contains(teamMemberId.trim());
  }

  bool isSendingVoiceNote(String teamMemberId) {
    return _voiceNoteRequestIds.contains(teamMemberId.trim());
  }

  Future<bool> sendMessage({
    required String? accessToken,
    required String teamMemberId,
    required String message,
  }) {
    return _runAction(
      accessToken: accessToken,
      teamMemberId: teamMemberId,
      message: message,
      activeRequests: _messageRequestIds,
      request: (token, id, text) => _service.sendMessage(
        accessToken: token,
        teamMemberId: id,
        message: text,
      ),
      emptyIdMessage: 'Team member id is missing.',
      emptyPayloadMessage: 'Follow-up message is required.',
      fallbackMessage: 'Unable to send follow-up message.',
    );
  }

  Future<bool> sendVoiceNote({
    required String? accessToken,
    required String teamMemberId,
    required String audioPath,
    required int durationSeconds,
  }) {
    return _runAction(
      accessToken: accessToken,
      teamMemberId: teamMemberId,
      message: audioPath,
      activeRequests: _voiceNoteRequestIds,
      request: (token, id, path) => _service.sendVoiceNote(
        accessToken: token,
        teamMemberId: id,
        audioPath: path,
        durationSeconds: durationSeconds,
      ),
      emptyIdMessage: 'Team member id is missing.',
      emptyPayloadMessage: 'Voice note audio file is required.',
      fallbackMessage: 'Unable to send follow-up voice note.',
    );
  }

  Future<bool> _runAction({
    required String? accessToken,
    required String teamMemberId,
    required String message,
    required Set<String> activeRequests,
    required Future<void> Function(String token, String id, String message)
    request,
    required String emptyIdMessage,
    required String emptyPayloadMessage,
    required String fallbackMessage,
  }) async {
    final token = accessToken?.trim() ?? '';
    final id = teamMemberId.trim();
    final text = message.trim();

    if (token.isEmpty) {
      setError('Login required to update follow-up control.');
      return false;
    }

    if (id.isEmpty) {
      setError(emptyIdMessage);
      return false;
    }

    if (text.isEmpty) {
      setError(emptyPayloadMessage);
      return false;
    }

    if (activeRequests.contains(id)) {
      return false;
    }

    activeRequests.add(id);
    clearError();
    notifyListeners();

    try {
      await request(token, id, text);
      return true;
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '').trim();
      setError(message.isEmpty ? fallbackMessage : message, notify: false);
      return false;
    } finally {
      activeRequests.remove(id);
      notifyListeners();
    }
  }
}
