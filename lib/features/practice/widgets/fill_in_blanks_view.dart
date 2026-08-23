import 'package:flutter/material.dart';

import '../../../core/i18n.dart';
import '../../../core/models/exercise.dart';
import 'exercise_scaffold.dart';

class FillInBlanksView extends StatefulWidget {
  const FillInBlanksView({
    super.key,
    required this.exercise,
    required this.onSubmit,
    required this.submitting,
  });

  final Exercise exercise;
  final void Function(ExerciseAnswer) onSubmit;
  final bool submitting;

  @override
  State<FillInBlanksView> createState() => _FillInBlanksViewState();
}

class _FillInBlanksViewState extends State<FillInBlanksView> {
  final _chosen = <String, String>{};
  late final List<(String, String?)> _parts;
  late final List<Map<String, dynamic>> _blanks;
  // Options shuffled ONCE per blank index. The backend does not shuffle
  // fill-in-blanks options (unlike multiple-choice), so without this the correct
  // answer would sit in a fixed position — the web shuffles them too. Shuffled in
  // initState (not build) so they don't jump around on every tap.
  final _options = <String, List<String>>{};

  @override
  void initState() {
    super.initState();
    _parts = splitBlanks(widget.exercise.payload['text'] as String? ?? '');
    _blanks = [
      for (final b in (widget.exercise.payload['blanks'] as List? ?? []))
        (b as Map).cast<String, dynamic>(),
    ];
    for (final blank in _blanks) {
      final index = blank['index'].toString();
      _options[index] = [for (final o in (blank['options'] as List)) o.toString()]
        ..shuffle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final complete = _chosen.length >= _blanks.length;
    return ExerciseScaffold(
      exercise: widget.exercise,
      submitEnabled: complete,
      submitting: widget.submitting,
      onSubmit: () => widget.onSubmit(ExerciseAnswer(Map.of(_chosen))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sentence(context),
          const SizedBox(height: 24),
          for (final blank in _blanks) _blankRow(context, blank),
        ],
      ),
    );
  }

  Widget _sentence(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge;
    final scheme = Theme.of(context).colorScheme;
    final spans = <InlineSpan>[];
    for (final (literal, index) in _parts) {
      if (index == null) {
        spans.add(TextSpan(text: literal));
      } else {
        final chosen = _chosen[index];
        spans.add(TextSpan(
          text: ' ${chosen ?? '_____'} ',
          style: TextStyle(
            color: chosen != null ? scheme.primary : scheme.outline,
            fontWeight: FontWeight.bold,
            decoration:
                chosen == null ? TextDecoration.underline : TextDecoration.none,
          ),
        ));
      }
    }
    return Text.rich(TextSpan(style: style, children: spans));
  }

  Widget _blankRow(BuildContext context, Map<String, dynamic> blank) {
    final index = blank['index'].toString();
    final options = _options[index]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_blanks.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(t('practice.blank', {'n': index}),
                  style: Theme.of(context).textTheme.labelMedium),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in options)
                SizedBox(
                  width: double.infinity,
                  child: OptionButton(
                    label: o,
                    selected: _chosen[index] == o,
                    onTap: () => setState(() => _chosen[index] = o),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
