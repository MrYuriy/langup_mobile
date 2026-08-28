import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/models/playlist.dart';

/// Outcome of analysing a song's lyrics.
class AnalyzeResult {
  const AnalyzeResult({this.lyrics, this.error});
  final AnalyzedLyrics? lyrics;

  /// One of: lyrics_not_found | language_unknown | generic.
  final String? error;
}

/// Playlist / song endpoints (`/playlists`, from `routers/playlists.py`).
class PlaylistsRepository {
  PlaylistsRepository(this._api);

  final ApiClient _api;
  Dio get _dio => _api.dio;

  Future<List<Playlist>> list() async {
    final resp = await _dio.get('/playlists');
    _ok(resp);
    return [
      for (final p in (resp.data as List))
        Playlist.fromJson((p as Map).cast<String, dynamic>()),
    ];
  }

  /// Starts an import. Returns the task id to poll (null = ran inline).
  Future<String?> import(String url) async {
    final resp = await _dio.post('/playlists', data: {'url': url});
    _ok(resp);
    return (resp.data as Map)['task_id'] as String?;
  }

  Future<ImportStatus> importStatus(String taskId) async {
    final resp = await _dio.get('/playlists/import/$taskId');
    _ok(resp);
    return ImportStatus.fromJson(_map(resp.data));
  }

  Future<PlaylistDetail> detail(String uuid) async {
    final resp = await _dio.get('/playlists/$uuid');
    _ok(resp);
    return PlaylistDetail.fromJson(_map(resp.data));
  }

  Future<void> delete(String uuid) async {
    final resp = await _dio.delete('/playlists/$uuid');
    _ok(resp);
  }

  Future<AnalyzeResult> analyze(String title, String artist) async {
    final resp = await _dio.post('/playlists/song/analyze',
        data: {'title': title, 'artist': artist});
    final code = resp.statusCode ?? 0;
    if (code == 200) {
      return AnalyzeResult(lyrics: AnalyzedLyrics.fromJson(_map(resp.data)));
    }
    if (code == 400) {
      final detail = (resp.data is Map ? resp.data['detail'] : null)?.toString();
      return AnalyzeResult(
        error: (detail == 'lyrics_not_found' || detail == 'language_unknown')
            ? detail
            : 'generic',
      );
    }
    return const AnalyzeResult(error: 'generic');
  }

  /// Translates one word in the context of its line. May return null.
  Future<String?> translate({
    required String word,
    required String line,
    required String language,
  }) async {
    final resp = await _dio.post('/playlists/song/translate',
        data: {'word': word, 'line': line, 'language': language});
    _ok(resp);
    return (resp.data as Map)['translation'] as String?;
  }

  /// Adds a word. `known` true = mastered (no exercises), false = to learn.
  /// Returns whether it was newly added (false = already in the dictionary).
  Future<bool> addWord({
    required String lemma,
    required String language,
    required bool known,
  }) async {
    final resp = await _dio.post('/playlists/song/word',
        data: {'lemma': lemma, 'language': language, 'known': known});
    _ok(resp);
    return (resp.data as Map)['added'] as bool? ?? true;
  }

  Map<String, dynamic> _map(Object? data) =>
      (data as Map).cast<String, dynamic>();

  void _ok(Response resp) {
    final code = resp.statusCode ?? 0;
    if (code >= 200 && code < 300) return;
    final body = resp.data;
    final detail =
        body is Map && body['detail'] is String ? body['detail'] as String : null;
    throw PlaylistException(detail ?? 'Request failed ($code)');
  }
}

class PlaylistException implements Exception {
  PlaylistException(this.message);
  final String message;
  @override
  String toString() => message;
}
