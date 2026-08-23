import 'package:flutter/material.dart';

import '../../../core/models/exercise.dart';
import 'exercise_scaffold.dart';

class TypingView extends StatefulWidget {
  const TypingView({
    super.key,
    required this.exercise,
    required this.onSubmit,
    required this.submitting,
  });

  final Exercise exercise;
  final void Function(ExerciseAnswer) onSubmit;
  final bool submitting;

  @override
  State<TypingView> createState() => _TypingViewState();
}

class _TypingViewState extends State<TypingView> {
  final _ctrl = TextEditingController();
  late final List<(String, String?)> _parts;
  int? _length;
  String? _hint;

  @override
  void initState() {
    super.initState();
    final p = widget.exercise.payload;
    _parts = splitBlanks(p['text'] as String? ?? '');
    _length = (p['length'] as num?)?.toInt();
    _hint = p['hint'] as String?;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _ctrl.text.trim();
    if (value.isEmpty) return;
    widget.onSubmit(ExerciseAnswer({'1': value}));
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge!;
    // Width sized to the word's length in the sentence's own font (a length
    // hint), so the blank stays proportional to the surrounding text rather than
    // ballooning like a monospace box.
    final n = (_length != null && _length! > 0) ? _length! : 6;
    final probe = TextPainter(
      text: TextSpan(text: 'o' * n, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final fieldWidth = probe.width + 6;

    return ExerciseScaffold(
      exercise: widget.exercise,
      submitting: widget.submitting,
      onSubmit: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The field flows inline with the sentence (a WidgetSpan), so lines
          // break naturally around it instead of the field jumping to its own row.
          Text.rich(
            TextSpan(
              style: style,
              children: [
                for (final (literal, index) in _parts)
                  if (index == null)
                    TextSpan(text: literal)
                  else
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: SizedBox(
                        width: fieldWidth,
                        child: TextField(
                          controller: _ctrl,
                          autofocus: true,
                          maxLength: _length,
                          textAlign: TextAlign.left,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            counterText: '',
                            isDense: true,
                            contentPadding: EdgeInsets.only(bottom: 2),
                          ),
                          style: style,
                        ),
                      ),
                    ),
              ],
            ),
          ),
          if (_hint != null && _hint!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(_hint!,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.primary)),
          ],
        ],
      ),
    );
  }
}
