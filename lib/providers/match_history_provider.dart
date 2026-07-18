import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:koniwalamatrimonial/constants/api_constants.dart';

class MatchHistoryProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _timeline = [];
  Map<String, dynamic> _summary = {};
  String? _profileId;
  int _page = 1;
  int _limit = 20;
  int _total = 0;
  int _totalPages = 1;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get timeline => _timeline;
  Map<String, dynamic> get summary => _summary;
  String? get profileId => _profileId;
  int get page => _page;
  int get limit => _limit;
  int get total => _total;
  int get totalPages => _totalPages;

  Future<void> fetchMatchHistory({
    required String profileId,
    required String? accessToken,
    int page = 1,
    int limit = 20,
  }) async {
    final token = accessToken?.trim() ?? '';
    final id = profileId.trim();

    _profileId = id;

    if (token.isEmpty) {
      _timeline = [];
      _summary = {};
      _error = 'Access token is required.';
      notifyListeners();
      return;
    }

    if (id.isEmpty) {
      _timeline = [];
      _summary = {};
      _error = 'Profile ID is required.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _timeline = [];
    _summary = {};
    notifyListeners();

    try {
      final firstPage = await _requestPage(
        profileId: id,
        token: token,
        page: page,
        limit: limit,
      );
      final allItems = <dynamic>[...firstPage.items];

      for (
        var nextPage = page + 1;
        nextPage <= firstPage.totalPages;
        nextPage++
      ) {
        final result = await _requestPage(
          profileId: id,
          token: token,
          page: nextPage,
          limit: limit,
        );
        allItems.addAll(result.items);
      }

      _timeline = allItems;
      _summary = firstPage.summary;
      _page = firstPage.page;
      _limit = firstPage.limit;
      _total = firstPage.total;
      _totalPages = firstPage.totalPages;
    } catch (e) {
      _timeline = [];
      _summary = {};
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<_MatchHistoryPage> _requestPage({
    required String profileId,
    required String token,
    required int page,
    required int limit,
  }) async {
    final url =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.profileMatchHistory(profileId)}',
        ).replace(
          queryParameters: {'page': page.toString(), 'limit': limit.toString()},
        );
    final response = await http.get(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractError(response.body) ??
            'Failed to load match history: ${response.statusCode}',
      );
    }

    final decoded = json.decode(response.body);
    final root = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};
    final responseData = root['data'];
    final data = responseData is Map<String, dynamic> ? responseData : root;
    final items = responseData is List
        ? responseData
        : data['timeline'] ??
              data['history'] ??
              data['items'] ??
              data['results'] ??
              data['matchHistory'] ??
              const [];
    final paginationSource =
        root['meta'] ??
        data['meta'] ??
        data['pagination'] ??
        root['pagination'];
    final pagination = paginationSource is Map
        ? Map<String, dynamic>.from(paginationSource)
        : const <String, dynamic>{};
    final parsedSummary = root['summary'] is Map
        ? Map<String, dynamic>.from(root['summary'] as Map)
        : data['summary'] is Map
        ? Map<String, dynamic>.from(data['summary'] as Map)
        : <String, dynamic>{};
    final parsedItems = items is List ? items : const <dynamic>[];
    final parsedTotal = _asInt(
      pagination['total'] ?? data['total'] ?? root['total'],
      parsedItems.length,
    );
    final parsedLimit = _asInt(pagination['limit'] ?? data['limit'], limit);

    return _MatchHistoryPage(
      items: parsedItems,
      summary: parsedSummary,
      page: _asInt(pagination['page'] ?? data['page'], page),
      limit: parsedLimit,
      total: parsedTotal,
      totalPages: _asInt(
        pagination['totalPages'] ?? data['totalPages'],
        parsedLimit == 0 ? 1 : (parsedTotal / parsedLimit).ceil(),
      ),
    );
  }

  static int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    return int.tryParse('$value') ?? fallback;
  }

  static String? _extractError(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map) {
        return '${decoded['message'] ?? decoded['error'] ?? ''}'.trim().isEmpty
            ? null
            : '${decoded['message'] ?? decoded['error']}';
      }
    } catch (_) {}
    return null;
  }
}

class _MatchHistoryPage {
  const _MatchHistoryPage({
    required this.items,
    required this.summary,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<dynamic> items;
  final Map<String, dynamic> summary;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
}
