import 'package:flutter/material.dart';

import '../../../core/i18n.dart';
import '../../../core/models/exercise.dart';

/// Shared chrome for an exercise: the instruction prompt at the top and an
/// optional primary submit button at the bottom.
class ExerciseScaffold extends StatelessWidget {
  const ExerciseScaffold({
    super.key,
    required this.exercise,
    required this.child,
    this.onSubmit,
    this.submitEnabled = true,
    this.submitting = false,
    this.submitLabel,
  });

  final Exercise exercise;
  final Widget child;
  final VoidCallback? onSubmit;
  final bool submitEnabled;
  final bool submitting;
  final String? submitLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            t('prompt.${exercise.exerciseType.toLowerCase()}'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(child: SingleChildScrollView(child: child)),
        if (onSubmit != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: FilledButton(
              onPressed: (submitEnabled && !submitting) ? onSubmit : null,
              child: submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(submitLabel ?? t('common.check')),
            ),
          ),
      ],
    );
  }
}

/// A selectable option button used by several exercise types.
class OptionButton extends StatelessWidget {
  const OptionButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? scheme.onPrimaryContainer : null,
              )),
        ),
      ),
    );
  }
}

/// Splits `text` on `___N___` markers, yielding (literal, blankIndex?) pieces.
/// blankIndex is null for literal text.
List<(String, String?)> splitBlanks(String text) {
  final re = RegExp(r'___(\d+)___');
  final out = <(String, String?)>[];
  var last = 0;
  for (final m in re.allMatches(text)) {
    if (m.start > last) out.add((text.substring(last, m.start), null));
    out.add(('', m.group(1)));
    last = m.end;
  }
  if (last < text.length) out.add((text.substring(last), null));
  return out;
}
