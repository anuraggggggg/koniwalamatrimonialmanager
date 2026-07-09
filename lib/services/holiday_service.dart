import 'package:dio/dio.dart';
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/models/holiday_model.dart';

class HolidayService {
  final Dio _dio = Dio();
  String? _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  Future<List<HolidayModel>> getHolidays(int year) async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.hrHolidays}?year=$year';
    try {
      final response = await _dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => HolidayModel.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<HolidayModel?> createHoliday({
    required String name,
    required DateTime date,
    required String type,
    required bool isHalfDay,
    String? description,
  }) async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.hrHolidays}';
    final data = <String, dynamic>{
      'name': name.trim(),
      'date': DateTime.utc(date.year, date.month, date.day).toIso8601String(),
      'type': _normalizeHolidayType(type),
      'isHalfDay': isHalfDay,
      'description': description?.trim() ?? '',
    };

    try {
      final response = await _dio.post(
        url,
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create holiday.');
      }

      final holidayJson = _extractHolidayObject(response.data);
      if (holidayJson == null) {
        return null;
      }
      return HolidayModel.fromJson(holidayJson);
    } on DioException catch (e) {
      final message = _extractErrorMessage(e.response?.data);
      throw Exception(message ?? 'Failed to create holiday.');
    } catch (e) {
      rethrow;
    }
  }

  String _normalizeHolidayType(String type) {
    final normalized = type.trim().toUpperCase().replaceAll(' ', '_');
    if (normalized == 'MANDATORY' ||
        normalized == 'OPTIONAL' ||
        normalized == 'FLOATING') {
      return normalized;
    }
    return 'MANDATORY';
  }

  Map<String, dynamic>? _extractHolidayObject(dynamic payload) {
    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      for (final key in const ['data', 'holiday', 'item']) {
        final value = map[key];
        if (value is Map) {
          return Map<String, dynamic>.from(value);
        }
      }
      if (map.containsKey('name') || map.containsKey('date')) {
        return map;
      }
    }
    return null;
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final message = map['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
      if (message is List && message.isNotEmpty) {
        return message.join(', ');
      }
      final error = map['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error;
      }
    }
    return null;
  }
}
