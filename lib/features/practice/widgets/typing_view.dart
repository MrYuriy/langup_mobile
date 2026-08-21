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
    final style = Theme.of(context).textTheme.titleLarge;
    return ExerciseScaffold(
      exercise: widget.exercise,
      submitting: widget.submitting,
      onSubmit: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The sentence with an inline field replacing the ___1___ gap.
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final (literal, index) in _parts)
                if (index == null)
                  Text(literal, style: style)
                else
                  SizedBox(
                    width: ((_length ?? 8) * 14.0).clamp(60, 220),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        maxLength: _length,
                        textAlign: TextAlign.center,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          counterText: '',
                          isDense: true,
                        ),
                        style: style,
                      ),
                    ),
                  ),
            ],
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
