import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/languages.dart';
import '../../core/mastery.dart';
import '../../core/models/user_word.dart';
import 'vocabulary_controller.dart';

final _wordDetailProvider =
    FutureProvider.family.autoDispose<UserWordDetail, String>((ref, uuid) {
  return ref.watch(vocabularyRepositoryProvider).detail(uuid);
});

class WordDetailScreen extends ConsumerWidget {
  const WordDetailScreen({super.key, required this.uuid});
  final String uuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(_wordDetailProvider(uuid));

    return Scaffold(
      appBar: AppBar(title: Text(t('words.field_word'))),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(t('words.detail_fail')),
          ),
        ),
        data: (w) => _Detail(word: w),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.word});
  final UserWordDetail word;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(word.lemma, style: text.headlineMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Chip(languageName(word.language)),
            if (word.partOfSpeech != null)
              _Chip(word.partOfSpeech!.toLowerCase()),
            _Chip(masteryLabel(word.masteryLevel),
                color: Mastery.color(word.masteryLevel)),
          ],
        ),
        const SizedBox(height: 24),
        if (word.translation != null && word.translation!.isNotEmpty) ...[
          Text(t('words.translation'), style: text.labelLarge),
          const SizedBox(height: 4),
          Text(word.translation!, style: text.titleMedium),
          const SizedBox(height: 24),
        ] else ...[
          Text(t('words.translating'),
              style: text.bodyMedium
                  ?.copyWith(color: Theme.of(context).disabledColor)),
          const SizedBox(height: 24),
        ],
        Text(t('words.sentences_count', {'count': word.contexts.length}),
            style: text.labelLarge),
        const SizedBox(height: 8),
        if (word.contexts.isEmpty)
          Text(t('words.no_sentences'),
              style: text.bodyMedium
                  ?.copyWith(color: Theme.of(context).disabledColor))
        else
          for (final c in word.contexts)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _highlighted(
                  context,
                  c.sentence,
                  c.surfaceForm ?? word.lemma,
                ),
              ),
            ),
      ],
    );
  }

  /// Bold every occurrence of [term] in [sentence], case-insensitive — mirrors
  /// the web cabinet's `boldWordInto`.
  Widget _highlighted(BuildContext context, String sentence, String term) {
    final base = Theme.of(context).textTheme.bodyLarge;
    if (term.isEmpty) return Text(sentence, style: base);

    final spans = <TextSpan>[];
    final lower = sentence.toLowerCase();
    final needle = term.toLowerCase();
    var from = 0;
    var at = lower.indexOf(needle);
    while (at != -1) {
      if (at > from) {
        spans.add(TextSpan(text: sentence.substring(from, at)));
      }
      spans.add(TextSpan(
        text: sentence.substring(at, at + term.length),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      from = at + term.length;
      at = lower.indexOf(needle, from);
    }
    if (from < sentence.length) {
      spans.add(TextSpan(text: sentence.substring(from)));
    }
    return Text.rich(TextSpan(style: base, children: spans));
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
