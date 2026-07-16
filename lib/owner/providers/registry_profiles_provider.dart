import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:koniwalamatrimonial/constants/api_constants.dart';
import 'package:koniwalamatrimonial/owner/models/registry_profile_item.dart';

List<RegistryProfileItem> _parseRegistryProfilesResponse(String body) {
  final decoded = jsonDecode(body);
  final profileRows = _extractRegistryProfileRows(decoded);

  return profileRows
      .whereType<Map<String, dynamic>>()
      .map(RegistryProfileItem.fromJson)
      .toList();
}

List<dynamic> _extractRegistryProfileRows(dynamic payload) {
  if (payload is List) {
    return payload;
  }

  if (payload is Map<String, dynamic>) {
    for (final key in const ['data', 'profiles', 'items', 'results']) {
      final value = payload[key];

      if (value is List) {
        return value;
      }

      final nestedRows = _extractRegistryProfileRows(value);
      if (nestedRows.isNotEmpty) {
        return nestedRows;
      }
    }
  }

  return const [];
}

void _debugPrintCompact(String label, String value) {
  if (!kDebugMode) {
    return;
  }

  const maxChars = 1200;
  final compactValue = value.length > maxChars
      ? '${value.substring(0, maxChars)}... [truncated ${value.length} chars]'
      : value;
  debugPrint('$label$compactValue');
}

class RegistryProfilesProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isCreating = false;
  String? _error;
  String? _createError;
  String? _requestedAccessToken;
  String? _requestedOppositeGenderOf;
  String? _requestedProfileType;
  bool _hasRequestedProfiles = false;
  List<RegistryProfileItem> _profiles = const [];

  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String? get error => _error;
  String? get createError => _createError;
  List<RegistryProfileItem> get profiles => _profiles;

  Future<void> fetchProfiles(
    String? accessToken, {
    bool forceRefresh = false,
    String? oppositeGenderOf,
    String? profileType,
  }) async {
    if (!forceRefresh &&
        _hasRequestedProfiles &&
        accessToken == _requestedAccessToken &&
        oppositeGenderOf == _requestedOppositeGenderOf &&
        profileType == _requestedProfileType) {
      return;
    }

    _hasRequestedProfiles = true;
    _requestedAccessToken = accessToken;
    _requestedOppositeGenderOf = oppositeGenderOf;
    _requestedProfileType = profileType;

    if (accessToken == null || accessToken.isEmpty) {
      _isLoading = false;
      _error = 'Login required to load profiles.';
      _profiles = const [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParameters = <String, String>{};
      if (oppositeGenderOf != null && oppositeGenderOf.trim().isNotEmpty) {
        queryParameters['oppositeGenderOf'] = oppositeGenderOf.trim();
      }
      if (profileType != null && profileType.trim().isNotEmpty) {
        queryParameters['profileType'] = profileType.trim();
      }
      if (queryParameters.isEmpty) {
        queryParameters['limit'] = '100';
      }

      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.profiles}',
        ).replace(queryParameters: queryParameters),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Profiles API failed with ${response.statusCode}');
      }

      // PERF: JSON decoding and RegistryProfileItem mapping can be expensive
      // for large profile lists. Run it on a background isolate to avoid ANR.
      _profiles = await compute(_parseRegistryProfilesResponse, response.body);
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      _error = 'Unable to load profiles.';
      notifyListeners();
    }
  }

  Future<void> retry() {
    return fetchProfiles(
      _requestedAccessToken,
      forceRefresh: true,
      oppositeGenderOf: _requestedOppositeGenderOf,
      profileType: _requestedProfileType,
    );
  }

  Future<bool> filterProfiles({
    required String? accessToken,
    required Map<String, String> filters,
  }) async {
    final token = accessToken?.trim() ?? '';
    if (token.isEmpty) {
      _isLoading = false;
      _error = 'Login required to filter profiles.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.profiles}',
      ).replace(queryParameters: filters);
      if (kDebugMode) {
        debugPrint('Filter profiles API: GET $uri');
      }

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (kDebugMode) {
        debugPrint('Filter profiles API response: ${response.statusCode}');
      }
      _debugPrintCompact('Filter profiles API body: ', response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Filter profiles API failed with ${response.statusCode}',
        );
      }

      // PERF: Keep large filter response parsing off the UI isolate too.
      _profiles = await compute(_parseRegistryProfilesResponse, response.body);
      _isLoading = false;
      _error = null;
      _hasRequestedProfiles = true;
      _requestedAccessToken = token;
      notifyListeners();
      return true;
    } catch (_) {
      _isLoading = false;
      _error = 'Unable to filter profiles.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> createProfile({
    required String? accessToken,
    required Map<String, dynamic> payload,
    File? resumePdf,
    List<File> photos = const [],
  }) async {
    final token = accessToken?.trim() ?? '';
    if (token.isEmpty) {
      _createError = 'Login required to add profile.';
      notifyListeners();
      return false;
    }

    _isCreating = true;
    _createError = null;
    notifyListeners();

    try {
      final response = resumePdf == null && photos.isEmpty
          ? await http.post(
              Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profiles}'),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(payload),
            )
          : await _createProfileMultipart(
              accessToken: token,
              payload: payload,
              resumePdf: resumePdf,
              photos: photos,
            );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Create profile API failed with ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      final profileJson = _extractCreatedProfile(decoded);
      if (profileJson != null) {
        final createdProfile = RegistryProfileItem.fromJson(profileJson);
        _profiles = [
          createdProfile,
          ..._profiles.where(
            (profile) => profile.originalId != createdProfile.originalId,
          ),
        ];
      } else {
        _hasRequestedProfiles = false;
      }

      _isCreating = false;
      _createError = null;
      notifyListeners();
      return true;
    } catch (_) {
      _isCreating = false;
      _createError = 'Unable to add profile.';
      notifyListeners();
      return false;
    }
  }

  Future<http.Response> _createProfileMultipart({
    required String accessToken,
    required Map<String, dynamic> payload,
    File? resumePdf,
    required List<File> photos,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profiles}'),
    );
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });

    payload.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    if (resumePdf != null) {
      request.files.add(
        await http.MultipartFile.fromPath('resume', resumePdf.path),
      );
    }

    for (final photo in photos) {
      request.files.add(
        await http.MultipartFile.fromPath('images', photo.path),
      );
    }

    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }

  Future<bool> updateProfile({
    required String? accessToken,
    required String profileId,
    required Map<String, dynamic> payload,
  }) async {
    final token = accessToken?.trim() ?? '';
    final id = profileId.trim();
    if (token.isEmpty) {
      _createError = 'Login required to update profile.';
      notifyListeners();
      return false;
    }
    if (id.isEmpty || id == '-') {
      _createError = 'Profile id is missing.';
      notifyListeners();
      return false;
    }

    _isCreating = true;
    _createError = null;
    notifyListeners();

    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.profiles}/${Uri.encodeComponent(id)}',
      );
      debugPrint('Update profile API: PATCH $uri');
      debugPrint('Update profile API payload: ${jsonEncode(payload)}');

      final response = await http.patch(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );
      debugPrint('Update profile API response: ${response.statusCode}');
      debugPrint('Update profile API body: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _isCreating = false;
        _createError =
            _extractErrorMessage(response.body) ??
            'Update profile API failed with ${response.statusCode}.';
        notifyListeners();
        return false;
      }

      final decoded = jsonDecode(response.body);
      final profileJson = _extractCreatedProfile(decoded);
      if (profileJson != null) {
        final updatedProfile = RegistryProfileItem.fromJson(profileJson);
        _profiles = _profiles
            .map(
              (profile) =>
                  (profile.originalId == updatedProfile.originalId ||
                      profile.originalId == id)
                  ? updatedProfile
                  : profile,
            )
            .toList();
      } else {
        _hasRequestedProfiles = false;
      }

      _isCreating = false;
      _createError = null;
      notifyListeners();
      return true;
    } catch (error) {
      _isCreating = false;
      _createError = 'Unable to update profile. ${error.toString()}';
      notifyListeners();
      return false;
    }
  }

  Map<String, dynamic>? _extractCreatedProfile(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      for (final key in const ['data', 'profile', 'item', 'result']) {
        final value = payload[key];
        if (value is Map<String, dynamic>) {
          return value;
        }
      }

      if (payload['id'] != null || payload['name'] != null) {
        return payload;
      }
    }

    return null;
  }

  String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
        if (message is List && message.isNotEmpty) {
          return message.join(', ');
        }
      }
    } catch (_) {
      final trimmed = body.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    return null;
  }
}
