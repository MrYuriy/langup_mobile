import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import 'audio_service.dart';

/// A 🔊 button that speaks [text] in [language]. Shows a playing state while it
/// is the clip being heard, and renders nothing when there is no language to
/// speak the text in (mirrors the web's `maybeSpeaker`).
class SpeakButton extends ConsumerStatefulWidget {
  const SpeakButton({
    super.key,
    required this.text,
    required this.language,
    this.voice,
    this.size = 20,
  });

  final String? text;
  final String? language;
  final String? voice;
  final double size;

  @override
  ConsumerState<SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends ConsumerState<SpeakButton> {
  late final AudioService _audio;

  @override
  void initState() {
    super.initState();
    _audio = ref.read(audioServiceProvider);
    _audio.addListener(_onChange);
  }

  @override
  void dispose() {
    _audio.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    final language = widget.language;
    if (text == null || text.isEmpty || language == null || language.isEmpty) {
      return const SizedBox.shrink();
    }
    final playing = _audio.playingKey ==
        AudioService.keyFor(text, language, widget.voice);
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: t('audio.listen'),
      visualDensity: VisualDensity.compact,
      iconSize: widget.size,
      icon: Icon(
        playing ? Icons.volume_up : Icons.volume_up_outlined,
        color: playing ? scheme.primary : null,
      ),
      onPressed: () =>
          _audio.speak(text, language, voice: widget.voice),
    );
  }
}
