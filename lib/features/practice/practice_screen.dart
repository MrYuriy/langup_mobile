import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/languages.dart';
import '../../core/models/exercise.dart';
import 'practice_controller.dart';
import 'widgets/fill_in_blanks_view.dart';
import 'widgets/flashcard_view.dart';
import 'widgets/match_pairs_view.dart';
import 'widgets/multiple_choice_view.dart';
import 'widgets/typing_view.dart';

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(practiceControllerProvider);
    final ctrl = ref.read(practiceControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(state.languages.length > 1 ? 100 : 52),
          child: Column(
            children: [
              _chipsRow([
                _Chip('Any', state.activeType == null, () => ctrl.selectType(null)),
                for (final e in ExerciseTypes.labels.entries)
                  _Chip(e.value, state.activeType == e.key,
                      () => ctrl.selectType(e.key)),
              ]),
              if (state.languages.length > 1)
                _chipsRow([
                  for (final l in state.languages)
                    _Chip(languageName(l.language),
                        state.activeLanguage == l.language,
                        () => ctrl.selectLanguage(l.language)),
                ]),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _body(context, ref, state, ctrl),
        ),
      ),
    );
  }

  Widget _chipsRow(List<Widget> chips) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: chips,
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, PracticeState state,
      PracticeController ctrl) {
    switch (state.phase) {
      case PracticePhase.loading:
        return const Center(child: CircularProgressIndicator());
      case PracticePhase.error:
        return _Centered(
          icon: Icons.error_outline,
          text: 'Could not load the exercise.',
          actionLabel: 'Retry',
          onAction: ctrl.loadNext,
        );
      case PracticePhase.empty:
        return _EmptyView(state: state, ctrl: ctrl);
      case PracticePhase.result:
        return _ResultView(state: state, ctrl: ctrl);
      case PracticePhase.exercise:
        return _exerciseView(context, state, ctrl);
    }
  }

  Widget _exerciseView(
      BuildContext context, PracticeState state, PracticeController ctrl) {
    final ex = state.exercise!;
    void submit(ExerciseAnswer a) => ctrl.submit(a);
    // A key per exercise resets each view's internal state on advance.
    final key = ValueKey(ex.uuid);
    switch (ex.exerciseType) {
      case 'MULTIPLE_CHOICE':
        return MultipleChoiceView(
            key: key, exercise: ex, onSubmit: submit, submitting: state.submitting);
      case 'FLASHCARD':
        return FlashcardView(
            key: key, exercise: ex, onSubmit: submit, submitting: state.submitting);
      case 'MATCH_PAIRS':
        return MatchPairsView(
            key: key, exercise: ex, onSubmit: submit, submitting: state.submitting);
      case 'TYPING':
        return TypingView(
            key: key, exercise: ex, onSubmit: submit, submitting: state.submitting);
      default:
        return FillInBlanksView(
            key: key, exercise: ex, onSubmit: submit, submitting: state.submitting);
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.selected, this.onTap);
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
          label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.state, required this.ctrl});
  final PracticeState state;
  final PracticeController ctrl;

  @override
  Widget build(BuildContext context) {
    final result = state.result!;
    final ex = state.exercise!;
    final ok = result.isCorrect;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(ok ? Icons.check_circle : Icons.cancel,
                    size: 72, color: ok ? Colors.green : scheme.error),
                const SizedBox(height: 16),
                Text(_message(ex, result),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge),
                if (result.masteryLevel != null) ...[
                  const SizedBox(height: 8),
                  Text('Mastery: ${result.masteryLevel!.toLowerCase()}',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
                if (state.generating) ...[
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(state.generateStatus ?? 'Generating…'),
                ],
              ],
            ),
          ),
        ),
        FilledButton(
          onPressed: ctrl.loadNext,
          child: const Text('Next'),
        ),
      ],
    );
  }

  String _message(Exercise ex, AttemptResult result) {
    switch (ex.exerciseType) {
      case 'MATCH_PAIRS':
        final total = result.correctAnswers.length;
        final solved = state.lastAnswer?.answers.length ?? 0;
        if (result.isCorrect) return 'Round complete — $solved of $total pairs!';
        if (state.lastAnswer?.timedOut ?? false) {
          return "Time's up: $solved of $total pairs.";
        }
        return 'Round over: $solved of $total pairs.';
      case 'FLASHCARD':
        return result.isCorrect
            ? "Great, you're learning this word!"
            : "No worries — we'll review it later.";
      default:
        if (result.isCorrect) return 'Correct!';
        final answers = result.correctAnswers.values.join(', ');
        return 'Incorrect. Correct answer: $answers';
    }
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.state, required this.ctrl});
  final PracticeState state;
  final PracticeController ctrl;

  @override
  Widget build(BuildContext context) {
    switch (state.emptyReason) {
      case EmptyReason.notVerified:
        return const _Centered(
          icon: Icons.mark_email_unread_outlined,
          text:
              'Confirm your email to start practising. Check your inbox, or resend the link from your profile.',
        );
      case EmptyReason.dailyLimit:
        return const _Centered(
          icon: Icons.lock_clock,
          text:
              "You've reached today's free limit of AI-generated exercises. Upgrade to Premium for unlimited practice, or come back tomorrow.",
        );
      case EmptyReason.noExercises:
      case null:
        return _Centered(
          icon: Icons.auto_awesome,
          text: state.activeType != null
              ? 'No "${ExerciseTypes.labels[state.activeType]}" exercises right now. They appear as you save new words — or pick "Any".'
              : 'No exercises ready yet. They are generated after you save new words — this usually takes up to a minute.',
          actionLabel: state.generating ? null : 'Generate now',
          onAction: state.generating
              ? null
              : () async {
                  final created = await ctrl.generateMore();
                  if (created == 0 && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('No new exercises — save a few more words.')));
                  }
                },
          busy: state.generating,
          busyText: state.generateStatus,
        );
    }
  }
}

class _Centered extends StatelessWidget {
  const _Centered({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
    this.busy = false,
    this.busyText,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool busy;
  final String? busyText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center),
          if (busy) ...[
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            if (busyText != null) ...[
              const SizedBox(height: 8),
              Text(busyText!),
            ],
          ] else if (actionLabel != null) ...[
            const SizedBox(height: 24),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
