import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/models/workflow_task.dart';

class LeadFollowUpProvider extends ChangeNotifier {
  List<WorkflowTask> _followUps = [];
  bool _isLoading = false;
  String? _error;

  List<WorkflowTask> get followUps => _followUps;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchFollowUps(String? accessToken) async {
    if (accessToken == null || accessToken.isEmpty) {
      _error = 'Authorization required';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.leadFollowUps}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _followUps = data.map((json) => WorkflowTask.fromJson(json)).toList();
        _error = null;
      } else {
        _error = 'Failed to load follow-ups: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
