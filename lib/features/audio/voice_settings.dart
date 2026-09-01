import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/languages.dart';
import 'audio_service.dart';
import 'voice_controller.dart';

/// Voice picker: one voice per language being learned, each previewable before
/// it is committed. Choices are staged — the profile's Save button writes them,
/// so changing a voice lights up the same button as the rest of the form.
class VoiceSettings extends ConsumerWidget {
  const VoiceSettings({super.key});

  /// "M1" -> "Male 1" — M/F plus a number is all the engine gives us.
  String _label(String voice) {
    final kind =
        voice.startsWith('M') ? t('settings.voice_male') : t('settings.voice_female');
    return '$kind ${voice.substring(1)}';
  }

  String _autoLabel(VoiceState s, String language) {
    final fallback = s.voices?.defaults[language];
    return fallback != null
        ? '${t('settings.voice_auto')} (${_label(fallback)})'
        : t('settings.voice_auto');
  }

  /// The demo is spoken IN the language being previewed, read from that
  /// language's own locale — sending Ukrainian text to be read as English would
  /// just garble it. Previews the staged voice, before it is saved.
  Future<void> _preview(WidgetRef ref, VoiceState s, String language) async {
    final phrase = await I18n.instance.phraseIn(language, 'settings.voice_demo');
    await ref
        .read(audioServiceProvider)
        .speak(phrase, language, voice: s.selected[language]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(voiceControllerProvider);
    // Hidden while loading, when audio is unavailable, or when nothing is being
    // learned yet — there would be nothing to voice.
    if (!s.visible) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('settings.voice'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(t('settings.voice_hint'),
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        for (final language in s.languages)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('voice-$language-${s.selected[language] ?? ''}'),
                    initialValue: s.selected[language] ?? '',
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: languageName(language),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      DropdownMenuItem(value: '', child: Text(_autoLabel(s, language))),
                      for (final voice in s.voices!.voices)
                        DropdownMenuItem(value: voice, child: Text(_label(voice))),
                    ],
                    onChanged: (value) =>
                        ref.read(voiceControllerProvider.notifier).select(language, value),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _preview(ref, s, language),
                  child: Text(t('settings.voice_preview')),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
