import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:koniwalamatrimonial/constants/api_constants.dart';

class TasksProvider extends ChangeNotifier {
  bool _isCreating = false;
  String? _error;
  final Set<String> _completingTaskIds = {};

  bool get isCreating => _isCreating;
  String? get error => _error;
  bool isCompleting(String taskId) => _completingTaskIds.contains(taskId);

  Future<bool> createTask({
    required String? accessToken,
    required String title,
    required String description,
    required String type,
    required String priority,
    required DateTime dueAt,
    required String assignedToId,
    required String subjectId,
    required String notes,
    String subjectType = 'CUSTOMER',
  }) async {
    final token = accessToken?.trim() ?? '';
    if (token.isEmpty) {
      _error = 'Login required to create task.';
      notifyListeners();
      return false;
    }

    _isCreating = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tasks}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title.trim(),
          'description': description.trim(),
          'type': type,
          'priority': priority,
          'dueAt': dueAt.toUtc().toIso8601String(),
          'assignedToId': assignedToId,
          'subjectId': subjectId,
          'subjectType': subjectType,
          'notes': notes.trim(),
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _extractError(response.body) ??
              'Task API failed with ${response.statusCode}',
        );
      }

      return true;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<bool> markTaskDone({
    required String? accessToken,
    required String taskId,
  }) async {
    final token = accessToken?.trim() ?? '';
    final id = taskId.trim();
    if (token.isEmpty || id.isEmpty) {
      _error = token.isEmpty
          ? 'Login required to update task.'
          : 'Task ID is required.';
      notifyListeners();
      return false;
    }

    _completingTaskIds.add(id);
    _error = null;
    notifyListeners();

    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.task(id)}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': 'COMPLETED',
          'workflowStatus': 'COMPLETED',
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _extractError(response.body) ??
              'Task update API failed with ${response.statusCode}',
        );
      }

      return true;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _completingTaskIds.remove(id);
      notifyListeners();
    }
  }

  static String? _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final value = decoded['message'] ?? decoded['error'];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
    } catch (_) {}
    return null;
  }
}
