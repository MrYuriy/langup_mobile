import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/languages.dart';
import '../../core/providers.dart';
import '../vocabulary/vocabulary_controller.dart';
import 'audio_service.dart';
import 'voices_repository.dart';

/// Voice picker: one voice per language being learned, each previewable before
/// it is saved. Mirrors the web cabinet's voice block.
class VoiceSettings extends ConsumerStatefulWidget {
  const VoiceSettings({super.key});

  @override
  ConsumerState<VoiceSettings> createState() => _VoiceSettingsState();
}

class _VoiceSettingsState extends ConsumerState<VoiceSettings> {
  Voices? _voices;
  List<String> _languages = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final voices = await ref.read(voicesRepositoryProvider).load();
    // Offer a row per language actually being studied: the vocabulary's
    // languages, plus the profile's "I'm learning" so a brand-new account with
    // no words yet still gets one.
    final codes = <String>[];
    try {
      for (final l in await ref.read(vocabularyRepositoryProvider).languages()) {
        codes.add(l.language);
      }
    } catch (_) {
      // Fall back to just the target language below.
    }
    final target = ref.read(authControllerProvider).user?.targetLanguage;
    if (target != null && target.isNotEmpty && !codes.contains(target)) {
      codes.add(target);
    }
    if (!mounted) return;
    setState(() {
      _voices = voices;
      _languages = codes;
      _loading = false;
    });
  }

  /// "M1" -> "Male 1" — M/F plus a number is all the engine gives us.
  String _label(String voice) {
    final kind =
        voice.startsWith('M') ? t('settings.voice_male') : t('settings.voice_female');
    return '$kind ${voice.substring(1)}';
  }

  String _autoLabel(String language) {
    final fallback = _voices?.defaults[language];
    return fallback != null
        ? '${t('settings.voice_auto')} (${_label(fallback)})'
        : t('settings.voice_auto');
  }

  Future<void> _save(String language, String? voice) async {
    final current = Map<String, String>.from(_voices!.selected);
    if (voice == null || voice.isEmpty) {
      current.remove(language);
    } else {
      current[language] = voice;
    }
    setState(() => _voices = Voices(
          voices: _voices!.voices,
          selected: current,
          defaults: _voices!.defaults,
        ));

    final userId = ref.read(authControllerProvider).user?.id;
    if (userId == null) return;
    final ok = await ref.read(voicesRepositoryProvider).save(userId, current);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? t('toast.saved') : t('toast.save_fail'))),
    );
  }

  /// The demo must be spoken IN the language being previewed, so it is read from
  /// that language's own locale file rather than the interface language.
  Future<void> _preview(String language) async {
    final phrase = await I18n.instance.phraseIn(language, 'settings.voice_demo');
    final voice = _voices!.selected[language];
    await ref.read(audioServiceProvider).speak(phrase, language, voice: voice);
  }

  @override
  Widget build(BuildContext context) {
    final v = _voices;
    // Hidden while loading, when audio is unavailable, or when nothing is being
    // learned yet — there would be nothing to voice.
    if (_loading || v == null || v.voices.isEmpty || _languages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('settings.voice'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(t('settings.voice_hint'),
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        for (final language in _languages)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: v.selected[language] ?? '',
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: languageName(language),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      DropdownMenuItem(value: '', child: Text(_autoLabel(language))),
                      for (final voice in v.voices)
                        DropdownMenuItem(value: voice, child: Text(_label(voice))),
                    ],
                    onChanged: (value) => _save(language, value),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _preview(language),
                  child: Text(t('settings.voice_preview')),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
