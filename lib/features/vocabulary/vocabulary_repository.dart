import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/models/page.dart';
import '../../core/models/user_word.dart';

/// Personal vocabulary endpoints (`/vocabulary`, from `routers/capture.py`).
class VocabularyRepository {
  VocabularyRepository(this._api);

  final ApiClient _api;
  Dio get _dio => _api.dio;

  Future<Page<UserWord>> list({
    int page = 1,
    int limit = 20,
    String? query,
    String? language,
  }) async {
    final resp = await _dio.get('/vocabulary', queryParameters: {
      'page': page,
      'limit': limit,
      if (query != null && query.isNotEmpty) 'query': query,
      if (language != null && language.isNotEmpty) 'language': language,
    });
    _ok(resp);
    return Page.fromJson(_map(resp.data), UserWord.fromJson);
  }

  Future<List<LanguageCount>> languages() async {
    final resp = await _dio.get('/vocabulary/languages');
    _ok(resp);
    return [
      for (final e in (resp.data as List))
        LanguageCount.fromJson((e as Map).cast<String, dynamic>()),
    ];
  }

  Future<UserWordDetail> detail(String uuid) async {
    final resp = await _dio.get('/vocabulary/$uuid');
    _ok(resp);
    return UserWordDetail.fromJson(_map(resp.data));
  }

  Future<UserWord> capture({
    required String word,
    required String language,
    String? sentence,
  }) async {
    final resp = await _dio.post('/vocabulary', data: {
      'word': word,
      'language': language,
      if (sentence != null && sentence.isNotEmpty) 'sentence': sentence,
      'source_title': 'Mobile app',
    });
    _ok(resp);
    return UserWord.fromJson(_map(resp.data));
  }

  Future<void> remove(String uuid) async {
    final resp = await _dio.delete('/vocabulary/$uuid');
    _ok(resp);
  }

  Map<String, dynamic> _map(Object? data) =>
      (data as Map).cast<String, dynamic>();

  void _ok(Response resp) {
    final code = resp.statusCode ?? 0;
    if (code >= 200 && code < 300) return;
    final body = resp.data;
    final detail =
        body is Map && body['detail'] is String ? body['detail'] as String : null;
    throw VocabularyException(detail ?? 'Request failed ($code)');
  }
}

class VocabularyException implements Exception {
  VocabularyException(this.message);
  final String message;
  @override
  String toString() => message;
}
