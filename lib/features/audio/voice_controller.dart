import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../vocabulary/vocabulary_controller.dart';
import 'audio_service.dart';
import 'voices_repository.dart';

class VoiceState {
  const VoiceState({
    this.voices,
    this.languages = const [],
    this.selected = const {},
    this.saved = const {},
    this.loading = true,
  });

  /// The roster, or null when audio is unavailable (the picker stays hidden).
  final Voices? voices;

  /// Languages to offer a row for — the ones actually being studied.
  final List<String> languages;

  /// What the pickers currently show (may differ from [saved] until saved).
  final Map<String, String> selected;

  /// What the account holds, so edits can be told apart from the stored state.
  final Map<String, String> saved;

  final bool loading;

  bool get dirty {
    if (selected.length != saved.length) return true;
    for (final e in selected.entries) {
      if (saved[e.key] != e.value) return true;
    }
    return false;
  }

  bool get visible =>
      !loading && voices != null && voices!.voices.isNotEmpty && languages.isNotEmpty;

  VoiceState copyWith({
    Voices? voices,
    List<String>? languages,
    Map<String, String>? selected,
    Map<String, String>? saved,
    bool? loading,
  }) {
    return VoiceState(
      voices: voices ?? this.voices,
      languages: languages ?? this.languages,
      selected: selected ?? this.selected,
      saved: saved ?? this.saved,
      loading: loading ?? this.loading,
    );
  }
}

/// Voice choices, one per language being learned. Edits are held until the
/// profile's Save button commits them, so the whole screen saves as one action
/// rather than some settings applying instantly and others not.
class VoiceController extends StateNotifier<VoiceState> {
  VoiceController(this._ref) : super(const VoiceState()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final voices = await _ref.read(voicesRepositoryProvider).load();
    // A row per language actually studied: the vocabulary's languages, plus the
    // profile's "I'm learning" so a new account with no words yet still gets one.
    final codes = <String>[];
    try {
      for (final l in await _ref.read(vocabularyRepositoryProvider).languages()) {
        codes.add(l.language);
      }
    } catch (_) {
      // Fall back to just the target language below.
    }
    final target = _ref.read(authControllerProvider).user?.targetLanguage;
    if (target != null && target.isNotEmpty && !codes.contains(target)) {
      codes.add(target);
    }
    if (!mounted) return;
    final stored = Map<String, String>.from(voices?.selected ?? const {});
    state = VoiceState(
      voices: voices,
      languages: codes,
      selected: stored,
      saved: Map<String, String>.from(stored),
      loading: false,
    );
  }

  /// Stage a choice; nothing leaves the device until [save].
  void select(String language, String? voice) {
    final next = Map<String, String>.from(state.selected);
    if (voice == null || voice.isEmpty) {
      next.remove(language);
    } else {
      next[language] = voice;
    }
    state = state.copyWith(selected: next);
  }

  Future<bool> save() async {
    if (!state.dirty) return true;
    final userId = _ref.read(authControllerProvider).user?.id;
    if (userId == null) return false;
    final ok = await _ref
        .read(voicesRepositoryProvider)
        .save(userId, state.selected);
    if (!ok) return false;
    // Clips already resolved were URLs for the previous voice; keeping them
    // would replay a word in the voice just replaced.
    _ref.read(audioServiceProvider).clearCache();
    state = state.copyWith(saved: Map<String, String>.from(state.selected));
    return true;
  }
}

final voiceControllerProvider =
    StateNotifierProvider<VoiceController, VoiceState>((ref) {
  return VoiceController(ref);
});
