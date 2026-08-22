import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/models/exercise.dart';
import '../../core/models/exercise_preferences.dart';

/// Outcome of asking for the next exercise.
enum NextStatus { ok, empty, notVerified, error }

class NextExercise {
  const NextExercise(this.status, [this.exercise]);
  final NextStatus status;
  final Exercise? exercise;
}

/// Exercise pool endpoints (`/exercises`, from `routers/exercises.py`).
class ExercisesRepository {
  ExercisesRepository(this._api);

  final ApiClient _api;
  Dio get _dio => _api.dio;

  Future<NextExercise> next({String? type, String? language}) async {
    final resp = await _dio.get('/exercises/next', queryParameters: {
      'exercise_type': ?type,
      'language': ?language,
    });
    final code = resp.statusCode ?? 0;
    if (code == 200) {
      return NextExercise(
          NextStatus.ok, Exercise.fromJson(_map(resp.data)));
    }
    if (code == 403) return const NextExercise(NextStatus.notVerified);
    if (code == 404) return const NextExercise(NextStatus.empty);
    return const NextExercise(NextStatus.error);
  }

  Future<AttemptResult> attempt(String uuid, ExerciseAnswer answer) async {
    final resp = await _dio.post('/exercises/$uuid/attempt', data: {
      'answers': answer.answers,
      if (answer.mistakes != null) 'mistakes': answer.mistakes,
      'timed_out': answer.timedOut,
    });
    _ok(resp);
    return AttemptResult.fromJson(_map(resp.data));
  }

  Future<ExercisePreferences> preferences() async {
    final resp = await _dio.get('/exercises/preferences');
    _ok(resp);
    return ExercisePreferences.fromJson(_map(resp.data));
  }

  /// PUT the full preferences object (the API requires `exercise_types`), so
  /// callers read the current prefs first, then send them back with the change.
  Future<ExercisePreferences> setPreferences(ExercisePreferences prefs) async {
    final resp = await _dio.put('/exercises/preferences', data: prefs.toJson());
    _ok(resp);
    return ExercisePreferences.fromJson(_map(resp.data));
  }

  Future<GenerationQuota?> quota() async {
    final resp = await _dio.get('/exercises/quota');
    if ((resp.statusCode ?? 0) != 200) return null;
    return GenerationQuota.fromJson(_map(resp.data));
  }

  /// Kicks off generation. Returns a task id to poll (worker) or the created
  /// count (inline). One of the two is always set.
  Future<({String? taskId, int? created})> refill(
      {String? type, String? language}) async {
    final resp = await _dio.post('/exercises/refill', queryParameters: {
      'exercise_type': ?type,
      'language': ?language,
    });
    _ok(resp);
    final data = _map(resp.data);
    return (taskId: data['task_id'] as String?, created: data['created'] as int?);
  }

  /// One poll of a queued refill. Returns (done, created) — done=false means
  /// still running; created=null on failure.
  Future<({bool done, int? created, bool failed})> refillStatus(
      String taskId) async {
    final resp = await _dio.get('/exercises/refill/$taskId');
    if ((resp.statusCode ?? 0) != 200) {
      return (done: false, created: null, failed: true);
    }
    final data = _map(resp.data);
    final status = data['status'] as String?;
    if (status == 'done') {
      return (done: true, created: data['created'] as int? ?? 0, failed: false);
    }
    if (status == 'failed') return (done: false, created: null, failed: true);
    return (done: false, created: null, failed: false);
  }

  Map<String, dynamic> _map(Object? data) =>
      (data as Map).cast<String, dynamic>();

  void _ok(Response resp) {
    final code = resp.statusCode ?? 0;
    if (code >= 200 && code < 300) return;
    final body = resp.data;
    final detail =
        body is Map && body['detail'] is String ? body['detail'] as String : null;
    throw ExerciseException(detail ?? 'Request failed ($code)');
  }
}

class ExerciseException implements Exception {
  ExerciseException(this.message);
  final String message;
  @override
  String toString() => message;
}
