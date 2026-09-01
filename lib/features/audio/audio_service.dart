import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/providers.dart';

/// Speech playback, a port of the web cabinet's `audio.js`.
///
/// Guarantees the same two things:
///  * only ONE clip plays at a time — starting a second stops the first;
///  * a clip's URL is asked for once per (text, language, voice). The backend
///    serves the file immutable under a content hash, so the player's own HTTP
///    cache does the rest.
///
/// Failure is deliberately quiet: audio is an enhancement, and a learner should
/// never get an error dialog because the TTS box is busy.
class AudioService {
  AudioService(this._api);

  final ApiClient _api;
  final _player = AudioPlayer();
  final _urls = <String, String>{};

  /// Incremented per request: a slow resolve must not hijack playback started
  /// by a newer tap.
  int _token = 0;

  /// Which text is currently playing (so a button can show its state), or null.
  String? _playingKey;
  String? get playingKey => _playingKey;

  final _listeners = <void Function()>{};
  void addListener(void Function() l) => _listeners.add(l);
  void removeListener(void Function() l) => _listeners.remove(l);
  void _notify() {
    for (final l in _listeners.toList()) {
      l();
    }
  }

  static String keyFor(String text, String language, [String? voice]) =>
      '$text|$language|${voice ?? ''}';

  Future<String> _resolveUrl(String text, String language, String? voice) async {
    final key = keyFor(text, language, voice);
    final cached = _urls[key];
    if (cached != null) return cached;

    final resp = await _api.dio.post('/audio', data: {
      'text': text,
      'language': language,
      'voice': voice,
    });
    if ((resp.statusCode ?? 0) != 200) {
      throw Exception('audio ${resp.statusCode}');
    }
    // The API returns a relative url like /api/audio/<hash>.mp3; make it
    // absolute against the host the API itself lives on.
    final path = (resp.data as Map)['url'] as String;
    final origin = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final url = '$origin$path';
    _urls[key] = url;
    return url;
  }

  /// Speak [text]. Tapping the same text again while it plays stops it.
  Future<void> speak(String text, String language, {String? voice}) async {
    if (text.isEmpty || language.isEmpty) return;
    final key = keyFor(text, language, voice);

    // A second tap on what is already playing means "stop".
    if (_playingKey == key && _player.playing) {
      await _player.stop();
      _playingKey = null;
      _notify();
      return;
    }

    await _player.stop();
    _playingKey = key;
    _notify();
    final token = ++_token;
    try {
      final url = await _resolveUrl(text, language, voice);
      if (token != _token) return; // a newer tap won the race
      await _player.setUrl(url);
      if (token != _token) return;
      await _player.play(); // completes when playback finishes
      if (token != _token) return;
      _playingKey = null;
      _notify();
    } catch (_) {
      if (token == _token) {
        _playingKey = null;
        _notify(); // never interrupt the learner with a dialog
      }
    }
  }

  /// Forget every resolved URL.
  ///
  /// Most clips are requested with `voice: null`, meaning "whatever the learner
  /// has chosen for this language" — so the cache key does not change when that
  /// choice does, and a word played before the switch would keep coming back in
  /// the old voice. The web never noticed: its cache is per page load, and the
  /// picker lives on a different page. Here the service outlives the screen, so
  /// the picker has to tell it the answer changed.
  void clearCache() => _urls.clear();

  void dispose() => _player.dispose();
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService(ref.watch(apiClientProvider));
  ref.onDispose(service.dispose);
  return service;
});
