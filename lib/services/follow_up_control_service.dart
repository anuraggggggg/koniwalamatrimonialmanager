import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:koniwalamatrimonial/constants/api_constants.dart';

class FollowUpControlService {
  Future<void> sendMessage({
    required String accessToken,
    required String teamMemberId,
    required String message,
  }) {
    return _postFollowUpAction(
      url: ApiConstants.followUpControlMessageUrl,
      accessToken: accessToken,
      teamMemberId: teamMemberId,
      message: message,
    );
  }

  Future<void> sendVoiceNote({
    required String accessToken,
    required String teamMemberId,
    required String audioPath,
    required int durationSeconds,
  }) {
    return _postVoiceNote(
      accessToken: accessToken,
      teamMemberId: teamMemberId,
      audioPath: audioPath,
      durationSeconds: durationSeconds,
    );
  }

  Future<void> _postFollowUpAction({
    required String url,
    required String accessToken,
    required String teamMemberId,
    required String message,
  }) async {
    final payload = {
      'teamMemberId': teamMemberId.trim(),
      'message': message.trim(),
    };
    if (kDebugMode) {
      debugPrint('Follow-up control POST -> $url');
      debugPrint('Follow-up control payload -> ${jsonEncode(payload)}');
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${accessToken.trim()}',
      },
      body: jsonEncode(payload),
    );

    if (kDebugMode) {
      debugPrint('Follow-up control response -> status=${response.statusCode}');
      debugPrint('Follow-up control body -> ${response.body}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractApiError(response.body) ??
            'Follow-up control API failed with ${response.statusCode}',
      );
    }
  }

  Future<void> _postVoiceNote({
    required String accessToken,
    required String teamMemberId,
    required String audioPath,
    required int durationSeconds,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.followUpControlVoiceNoteUrl),
    );
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer ${accessToken.trim()}',
    });
    request.fields['teamMemberId'] = teamMemberId.trim();
    request.fields['durationSeconds'] = '$durationSeconds';
    request.files.add(
      await http.MultipartFile.fromPath(
        'audio',
        audioPath,
        contentType: MediaType('audio', 'wav'),
      ),
    );

    if (kDebugMode) {
      debugPrint(
        'Follow-up voice-note POST -> ${ApiConstants.followUpControlVoiceNoteUrl}',
      );
      debugPrint(
        'Follow-up voice-note fields -> teamMemberId=${request.fields['teamMemberId']} durationSeconds=${request.fields['durationSeconds']} audio=$audioPath',
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (kDebugMode) {
      debugPrint(
        'Follow-up voice-note response -> status=${response.statusCode}',
      );
      debugPrint('Follow-up voice-note body -> ${response.body}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractApiError(response.body) ??
            'Follow-up voice-note API failed with ${response.statusCode}',
      );
    }
  }

  String? _extractApiError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final message = decoded['message'] ?? decoded['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {}

    return null;
  }
}
