import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';

/// The voice roster — matches `VoicesOut`.
class Voices {
  const Voices({
    required this.voices,
    required this.selected,
    required this.defaults,
  });

  /// Every voice the learner may pick from (e.g. "M1", "F2").
  final List<String> voices;

  /// Their chosen voice PER LANGUAGE — one voice per language being learned,
  /// not one for the whole account.
  final Map<String, String> selected;

  /// What each language falls back to when nothing is chosen for it.
  final Map<String, String> defaults;

  const Voices.empty()
      : voices = const [],
        selected = const {},
        defaults = const {};

  factory Voices.fromJson(Map<String, dynamic> json) => Voices(
        voices: [for (final v in (json['voices'] as List? ?? [])) v.toString()],
        selected: {
          for (final e in (json['selected'] as Map? ?? {}).entries)
            e.key.toString(): e.value.toString(),
        },
        defaults: {
          for (final e in (json['defaults'] as Map? ?? {}).entries)
            e.key.toString(): e.value.toString(),
        },
      );
}

class VoicesRepository {
  VoicesRepository(this._api);

  final ApiClient _api;
  Dio get _dio => _api.dio;

  /// Null when audio is disabled or unreachable — the picker then stays hidden.
  Future<Voices?> load() async {
    try {
      final resp = await _dio.get('/audio/voices');
      if ((resp.statusCode ?? 0) != 200) return null;
      return Voices.fromJson((resp.data as Map).cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  /// Voices live in `User.preferences` under `tts_voices` as a language -> voice
  /// map, PATCHed on their own key (the server merges the blob).
  Future<bool> save(int userId, Map<String, String> selected) async {
    try {
      final resp = await _dio.patch('/users/$userId', data: {
        'preferences': {'tts_voices': selected},
      });
      final code = resp.statusCode ?? 0;
      return code >= 200 && code < 300;
    } catch (_) {
      return false;
    }
  }
}

final voicesRepositoryProvider = Provider<VoicesRepository>((ref) {
  return VoicesRepository(ref.watch(apiClientProvider));
});
