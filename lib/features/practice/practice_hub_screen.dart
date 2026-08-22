import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/languages.dart';
import '../../core/models/exercise.dart';
import 'practice_controller.dart';

/// Practice hub: pick a language and an exercise type, then start a focused
/// full-screen session. Tapping a type card starts immediately.
class PracticeHubScreen extends ConsumerWidget {
  const PracticeHubScreen({super.key});

  // Type key (null = mixed) -> icon + one-line description.
  static const _meta = <String?, (IconData, String)>{
    null: (Icons.shuffle, 'A bit of everything'),
    'FILL_IN_BLANKS': (Icons.short_text, 'Fill the gap in a sentence'),
    'MULTIPLE_CHOICE': (Icons.checklist, 'Pick the correct meaning'),
    'FLASHCARD': (Icons.style, 'Recall, then reveal'),
    'MATCH_PAIRS': (Icons.grid_view, 'Match words to translations'),
    'TYPING': (Icons.keyboard, 'Type the missing word'),
  };

  static String _label(String? type) =>
      type == null ? 'Mixed' : (ExerciseTypes.labels[type] ?? type);

  void _start(BuildContext context, WidgetRef ref, String? type) {
    ref.read(practiceControllerProvider.notifier).startWith(type);
    context.push('/practice/session');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(practiceControllerProvider);
    final ctrl = ref.read(practiceControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.languages.length > 1) ...[
            Text('Language', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final l in state.languages)
                  ChoiceChip(
                    label: Text(languageName(l.language)),
                    selected: state.activeLanguage == l.language,
                    onSelected: (_) => ctrl.selectLanguage(l.language),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          Text('Choose an exercise',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          for (final entry in _meta.entries)
            _TypeCard(
              icon: entry.value.$1,
              title: _label(entry.key),
              subtitle: entry.value.$2,
              onTap: () => _start(context, ref, entry.key),
            ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(icon, color: scheme.onPrimaryContainer),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
