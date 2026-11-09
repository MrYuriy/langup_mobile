import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/models/due_word.dart';
import '../../core/models/streak.dart';

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

  /// The practice run, counted in the learner's own days.
  ///
  /// The offset goes with the request because which day an attempt belongs to
  /// is decided at the learner's midnight, not the server's: practising just
  /// after midnight here is the previous day in UTC, and counting that way
  /// would break a streak they had in fact kept.
  Future<Streak> streak() async {
    final resp = await _dio.get('/review/streak', queryParameters: {
      'tz_offset_minutes': DateTime.now().timeZoneOffset.inMinutes,
    });
    _ok(resp);
    return Streak.fromJson((resp.data as Map).cast<String, dynamic>());
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
