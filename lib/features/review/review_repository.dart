import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/models/due_word.dart';

/// Spaced-repetition endpoints (`/review`, from `routers/learning.py`).
class ReviewRepository {
  ReviewRepository(this._api);

  final ApiClient _api;
  Dio get _dio => _api.dio;

  Future<List<DueWord>> next({int limit = 20}) async {
    final resp = await _dio.get('/review/next', queryParameters: {'limit': limit});
    _ok(resp);
    return [
      for (final e in (resp.data as List))
        DueWord.fromJson((e as Map).cast<String, dynamic>()),
    ];
  }

  /// Grade a review (SM-2 quality 0-5). Returns the new mastery level.
  Future<String?> grade(String uuid, int quality) async {
    final resp = await _dio.post('/review/$uuid', data: {'quality': quality});
    _ok(resp);
    final data = resp.data;
    return data is Map ? data['mastery_level'] as String? : null;
  }

  void _ok(Response resp) {
    final code = resp.statusCode ?? 0;
    if (code >= 200 && code < 300) return;
    throw ReviewException('Request failed ($code)');
  }
}

class ReviewException implements Exception {
  ReviewException(this.message);
  final String message;
  @override
  String toString() => message;
}
