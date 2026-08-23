import 'package:flutter/material.dart';

import '../../../core/i18n.dart';
import '../../../core/models/exercise.dart';

class FlashcardView extends StatefulWidget {
  const FlashcardView({
    super.key,
    required this.exercise,
    required this.onSubmit,
    required this.submitting,
  });

  final Exercise exercise;
  final void Function(ExerciseAnswer) onSubmit;
  final bool submitting;

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.exercise.payload;
    final sentence = p['sentence'] as String? ?? '';
    final term = _term(sentence, p['surface_form'] as String?, p['word'] as String?);
    final translation = p['translation'] as String? ?? '';
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(t('prompt.${widget.exercise.exerciseType.toLowerCase()}'),
              style: text.titleMedium),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: sentence.isEmpty
                    ? Text(term ?? '',
                        style: text.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold))
                    : _highlighted(context, sentence, term ?? ''),
              ),
            ),
          ),
        ),
        if (!_revealed)
          FilledButton(
            onPressed: () => setState(() => _revealed = true),
            child: Text(t('practice.show_translation')),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(translation,
                textAlign: TextAlign.center,
                style: text.titleLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.primary)),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.submitting
                      ? null
                      : () => widget.onSubmit(
                          const ExerciseAnswer({'1': 'dont_know'})),
                  child: Text(t('practice.didnt_know')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: widget.submitting
                      ? null
                      : () =>
                          widget.onSubmit(const ExerciseAnswer({'1': 'know'})),
                  child: Text(t('practice.knew_it')),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Prefer whichever candidate actually appears in the sentence (surface form
  /// beats lemma) — mirrors the web `highlightTerm`.
  String? _term(String sentence, String? surface, String? word) {
    final lower = sentence.toLowerCase();
    for (final c in [surface, word]) {
      if (c != null && c.isNotEmpty && lower.contains(c.toLowerCase())) return c;
    }
    return surface?.isNotEmpty == true ? surface : word;
  }

  Widget _highlighted(BuildContext context, String sentence, String term) {
    final base = Theme.of(context).textTheme.titleMedium;
    if (term.isEmpty) return Text(sentence, style: base);
    // Bold + accent colour so the word under review is unmistakable.
    final hl = (base ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w800,
      color: Theme.of(context).colorScheme.primary,
    );
    final spans = <TextSpan>[];
    final lower = sentence.toLowerCase();
    final needle = term.toLowerCase();
    var from = 0;
    var at = lower.indexOf(needle);
    while (at != -1) {
      if (at > from) spans.add(TextSpan(text: sentence.substring(from, at)));
      spans.add(TextSpan(text: sentence.substring(at, at + term.length), style: hl));
      from = at + term.length;
      at = lower.indexOf(needle, from);
    }
    if (from < sentence.length) spans.add(TextSpan(text: sentence.substring(from)));
    return Text.rich(TextSpan(style: base, children: spans));
  }
}
