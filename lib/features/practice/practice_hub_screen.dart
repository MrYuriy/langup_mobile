import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/languages.dart';
import 'practice_controller.dart';

/// Practice hub: pick a language and an exercise type, then start a focused
/// full-screen session. Tapping a type card starts immediately.
class PracticeHubScreen extends ConsumerWidget {
  const PracticeHubScreen({super.key});

  // Type key (null = mixed) -> icon. Labels and descriptions are localised.
  static const _icons = <String?, IconData>{
    null: Icons.shuffle,
    'FILL_IN_BLANKS': Icons.short_text,
    'MULTIPLE_CHOICE': Icons.checklist,
    'FLASHCARD': Icons.style,
    'MATCH_PAIRS': Icons.grid_view,
    'TYPING': Icons.keyboard,
  };

  static String _label(String? type) =>
      type == null ? t('practice.mixed') : t('type.${type.toLowerCase()}');

  static String _desc(String? type) => type == null
      ? t('practice.mixed_desc')
      : t('practice.desc_${type.toLowerCase()}');

  void _start(BuildContext context, WidgetRef ref, String? type) {
    ref.read(practiceControllerProvider.notifier).startWith(type);
    context.push('/practice/session');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(practiceControllerProvider);
    final ctrl = ref.read(practiceControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(t('nav.practice'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.languages.length > 1) ...[
            Text(t('practice.language'),
                style: Theme.of(context).textTheme.labelLarge),
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
          Text(t('practice.choose'),
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          for (final entry in _icons.entries)
            _TypeCard(
              icon: entry.value,
              title: _label(entry.key),
              subtitle: _desc(entry.key),
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
