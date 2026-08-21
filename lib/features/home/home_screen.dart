import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/languages.dart';
import '../../core/providers.dart';

/// Phase 0 placeholder: proves the authenticated session works by showing the
/// signed-in user (from `GET /auth/me`). Real tabs (Practice, Vocabulary,
/// Review, Dashboard, Profile) land in later phases.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final initial =
        (user?.fullName?.trim().isNotEmpty ?? false) ? user!.fullName!.trim()[0] : (user?.email ?? '?')[0];

    return Scaffold(
      appBar: AppBar(
        title: const Text('LangUp'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  child: Text(initial.toUpperCase(),
                      style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(height: 16),
                Text(user?.fullName ?? 'No name',
                    style: Theme.of(context).textTheme.titleLarge),
                Text(user?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                _InfoTile(label: 'Role', value: user?.role ?? '—'),
                _InfoTile(
                  label: 'Email verified',
                  value: (user?.isEmailVerified ?? false) ? 'Yes' : 'No',
                ),
                _InfoTile(
                    label: 'Native language',
                    value: languageName(user?.nativeLanguage)),
                _InfoTile(
                    label: 'Target language',
                    value: languageName(user?.targetLanguage)),
                const SizedBox(height: 24),
                Text(
                  'Phase 0 shell — auth + session working. '
                  'Vocabulary, Practice, Review and Dashboard come next.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
