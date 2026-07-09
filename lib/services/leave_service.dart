import 'package:dio/dio.dart';
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/models/leave_model.dart';

class LeaveService {
  final Dio _dio = Dio();
  String? _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  Future<List<LeaveModel>> getAllLeaves() async {
    return _getLeavesFromUrls(const [
      '/hr/leaves/all',
      '/hr/leaves/admin',
      '/hr/leaves/requests',
      '/hr/leaves',
    ]);
  }

  Future<List<LeaveModel>> getMyLeaves() async {
    return _getLeavesFromUrls(const [
      '/hr/leaves',
      '/hr/leaves/my',
      '/hr/leaves/history',
      '/hr/leaves/me',
    ]);
  }

  Future<List<LeaveModel>> _getLeavesFromUrls(List<String> paths) async {
    for (final path in paths) {
      final url = '${ApiConstants.baseUrl}$path';
      try {
        final response = await _dio.get(
          url,
          options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
        );
        if (response.statusCode == 200) {
          final data = _extractLeaveList(response.data);
          if (data.isNotEmpty) {
            return data.map((json) => LeaveModel.fromJson(json)).toList();
          }
        }
      } on DioException catch (error) {
        final statusCode = error.response?.statusCode ?? 0;
        if (statusCode == 404 || statusCode == 405) {
          continue;
        }
        print('Get leaves error for $path: $error');
      } catch (error) {
        print('Get leaves error for $path: $error');
      }
    }

    return [];
  }

  Future<LeaveModel?> createLeave({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    final url = '${ApiConstants.baseUrl}/hr/leaves';
    try {
      final data = <String, dynamic>{
        'type': type,
        'startDate': _formatApiDate(startDate),
        'endDate': _formatApiDate(endDate),
      };

      final trimmedReason = reason?.trim();
      if (trimmedReason != null && trimmedReason.isNotEmpty) {
        data['reason'] = trimmedReason;
      }

      final response = await _dio.post(
        url,
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to submit leave request.');
      }

      final leaveJson = _extractLeaveObject(response.data);
      if (leaveJson == null) {
        return null;
      }
      return LeaveModel.fromJson(leaveJson);
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = _extractErrorMessage(responseData);
      print('Create leave error: $e');
      throw Exception(message ?? 'Failed to submit leave request.');
    } catch (e) {
      print('Create leave error: $e');
      rethrow;
    }
  }

  Future<void> updateLeaveStatus({
    required String leaveId,
    required String status,
  }) async {
    final url =
        '${ApiConstants.baseUrl}${ApiConstants.hrLeaveStatus(leaveId)}';
    final data = {'status': status};
    try {
      final response = await _postLeaveStatus(url: url, data: data);

      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 204) {
        throw Exception('Failed to update leave status.');
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 404 || statusCode == 405) {
        try {
          final fallbackResponse = await _patchLeaveStatus(url: url, data: data);
          if (fallbackResponse.statusCode == 200 ||
              fallbackResponse.statusCode == 201 ||
              fallbackResponse.statusCode == 204) {
            return;
          }
        } on DioException catch (fallbackError) {
          final fallbackData = fallbackError.response?.data;
          final fallbackMessage = _extractErrorMessage(fallbackData);
          print('Update leave status fallback error: $fallbackError');
          throw Exception(fallbackMessage ?? 'Failed to update leave status.');
        }
      }

      final responseData = e.response?.data;
      final message = _extractErrorMessage(responseData);
      print('Update leave status error: $e');
      throw Exception(message ?? 'Failed to update leave status.');
    } catch (e) {
      print('Update leave status error: $e');
      rethrow;
    }
  }

  Future<Response<dynamic>> _postLeaveStatus({
    required String url,
    required Map<String, dynamic> data,
  }) {
    return _dio.post(
      url,
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
    );
  }

  Future<Response<dynamic>> _patchLeaveStatus({
    required String url,
    required Map<String, dynamic> data,
  }) {
    return _dio.patch(
      url,
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
    );
  }

  String _formatApiDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day).toIso8601String();
  }

  List<Map<String, dynamic>> _extractLeaveList(dynamic payload) {
    if (payload is List) {
      final extracted = <Map<String, dynamic>>[];
      for (final item in payload) {
        extracted.addAll(_extractLeaveList(item));
      }
      return extracted;
    }

    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      if (_looksLikeLeave(map)) {
        return [map];
      }

      for (final key in const ['data', 'leaves', 'items', 'results']) {
        final value = map[key];
        final nestedLeaves = _extractLeaveList(value);
        if (nestedLeaves.isNotEmpty) {
          return nestedLeaves;
        }
      }

      final groupedLeaves = <Map<String, dynamic>>[];
      for (final key in const [
        'pending',
        'pendingLeaves',
        'approved',
        'approvedLeaves',
        'rejected',
        'rejectedLeaves',
        'denied',
        'deniedLeaves',
        'queued',
        'queuedLeaves',
        'history',
        'leaveHistory',
        'myLeaves',
        'requests',
        'leaveRequests',
        'adminApprovedLeaves',
        'managerApprovedLeaves',
        'managerPendingLeaves',
        'approvalQueue',
        'leaveRecords',
      ]) {
        groupedLeaves.addAll(_extractLeaveList(map[key]));
      }
      if (groupedLeaves.isNotEmpty) {
        return groupedLeaves;
      }

      final discoveredLeaves = <Map<String, dynamic>>[];
      for (final entry in map.entries) {
        final normalizedKey = entry.key.trim().toLowerCase();
        if (normalizedKey.contains('leave') ||
            normalizedKey.contains('history') ||
            normalizedKey.contains('request') ||
            normalizedKey.contains('approval') ||
            normalizedKey.contains('pending') ||
            normalizedKey.contains('approved') ||
            normalizedKey.contains('reject') ||
            normalizedKey.contains('denied') ||
            normalizedKey.contains('manager') ||
            normalizedKey.contains('admin')) {
          discoveredLeaves.addAll(_extractLeaveList(entry.value));
        }
      }
      if (discoveredLeaves.isNotEmpty) {
        return discoveredLeaves;
      }
    }

    return const [];
  }

  bool _looksLikeLeave(Map<String, dynamic> map) {
    final hasType = map['type'] != null || map['leaveType'] != null;
    final hasStartDate = map['startDate'] != null || map['fromDate'] != null;
    final hasEndDate = map['endDate'] != null || map['toDate'] != null;
    final hasStatus = map['status'] != null;
    return (hasType && hasStartDate && hasEndDate) ||
        (hasStartDate && hasEndDate && hasStatus);
  }

  Map<String, dynamic>? _extractLeaveObject(dynamic payload) {
    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      for (final key in const ['data', 'leave', 'request', 'item']) {
        final value = map[key];
        if (value is Map) {
          return Map<String, dynamic>.from(value);
        }
      }
      if (map.containsKey('startDate') || map.containsKey('type')) {
        return map;
      }
    }

    return null;
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
      final error = data['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error;
      }
    }
    return null;
  }
}
