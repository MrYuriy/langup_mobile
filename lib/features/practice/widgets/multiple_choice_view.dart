import 'package:flutter/material.dart';

import '../../../core/models/exercise.dart';
import '../../audio/speak_button.dart';
import 'exercise_scaffold.dart';

class MultipleChoiceView extends StatefulWidget {
  const MultipleChoiceView({
    super.key,
    required this.exercise,
    required this.onSubmit,
    required this.submitting,
  });

  final Exercise exercise;
  final void Function(ExerciseAnswer) onSubmit;
  final bool submitting;

  @override
  State<MultipleChoiceView> createState() => _MultipleChoiceViewState();
}

class _MultipleChoiceViewState extends State<MultipleChoiceView> {
  String? _chosen;

  @override
  Widget build(BuildContext context) {
    final word = widget.exercise.payload['word'] as String? ?? '';
    final options = [
      for (final o in (widget.exercise.payload['options'] as List? ?? []))
        o.toString(),
    ];

    return ExerciseScaffold(
      exercise: widget.exercise,
      submitEnabled: _chosen != null,
      submitting: widget.submitting,
      onSubmit: () => widget.onSubmit(ExerciseAnswer({'1': _chosen!})),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(word,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                SpeakButton(
                    text: word, language: widget.exercise.language, size: 26),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final o in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OptionButton(
                label: o,
                selected: _chosen == o,
                onTap: () => setState(() => _chosen = o),
              ),
            ),
        ],
      ),
    );
  }
}
