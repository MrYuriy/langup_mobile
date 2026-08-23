import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/languages.dart';
import '../../core/models/due_word.dart';
import 'review_controller.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reviewControllerProvider);
    final ctrl = ref.read(reviewControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(t('nav.review'))),
      body: SafeArea(child: _body(context, state, ctrl)),
    );
  }

  Widget _body(BuildContext context, ReviewState state, ReviewController ctrl) {
    switch (state.phase) {
      case ReviewPhase.loading:
        return const Center(child: CircularProgressIndicator());
      case ReviewPhase.error:
        return _Message(
          icon: Icons.error_outline,
          text: t('review.load_fail'),
          actionLabel: t('common.retry'),
          onAction: ctrl.loadQueue,
        );
      case ReviewPhase.done:
        return _Message(
          icon: Icons.task_alt,
          text: state.reviewed > 0
              ? t('review.done_count', {'count': state.reviewed})
              : t('review.done_default'),
          actionLabel: t('review.check_again'),
          onAction: ctrl.restart,
        );
      case ReviewPhase.card:
        return _Card(
          key: ValueKey(state.current!.uuid),
          word: state.current!,
          progress: '${state.index + 1} / ${state.queue.length}',
          grading: state.grading,
          onGrade: ctrl.grade,
        );
    }
  }
}

class _Card extends StatefulWidget {
  const _Card({
    super.key,
    required this.word,
    required this.progress,
    required this.grading,
    required this.onGrade,
  });

  final DueWord word;
  final String progress;
  final bool grading;
  final void Function(int quality) onGrade;

  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final w = widget.word;
    final hasTranslation = w.translation != null && w.translation!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(widget.progress, style: text.labelLarge),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(languageName(w.language).toUpperCase(),
                      style: text.labelMedium
                          ?.copyWith(color: Theme.of(context).disabledColor)),
                  const SizedBox(height: 12),
                  Text(w.lemma,
                      textAlign: TextAlign.center,
                      style: text.displaySmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  if (_revealed)
                    Text(
                      hasTranslation ? w.translation! : t('review.no_translation'),
                      textAlign: TextAlign.center,
                      style: hasTranslation
                          ? text.titleLarge
                              ?.copyWith(color: Theme.of(context).colorScheme.primary)
                          : text.bodyMedium
                              ?.copyWith(color: Theme.of(context).disabledColor),
                    ),
                ],
              ),
            ),
          ),
          if (!_revealed)
            FilledButton(
              onPressed: () => setState(() => _revealed = true),
              child: Text(t('review.show_translation')),
            )
          else
            Row(
              children: [
                _grade(context, t('review.grade_again'), 1, const Color(0xFFE03131)),
                _grade(context, t('grade.hard'), 3, const Color(0xFFF08C00)),
                _grade(context, t('grade.good'), 4, const Color(0xFF1971C2)),
                _grade(context, t('grade.easy'), 5, const Color(0xFF2F9E44)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _grade(BuildContext context, String label, int quality, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: widget.grading ? null : () => widget.onGrade(quality),
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
