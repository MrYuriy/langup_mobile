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
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).refreshUser(),
          ),
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
                if (!(user?.isEmailVerified ?? true))
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: _VerifyBanner(),
                  ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Prompts an unverified account to confirm its email. Practice is gated behind
/// verification on the backend (403 from `/exercises/next`), so surfacing this
/// early matters.
class _VerifyBanner extends ConsumerStatefulWidget {
  const _VerifyBanner();

  @override
  ConsumerState<_VerifyBanner> createState() => _VerifyBannerState();
}

class _VerifyBannerState extends ConsumerState<_VerifyBanner> {
  bool _busy = false;

  Future<void> _resend() async {
    setState(() => _busy = true);
    String message;
    try {
      final sent = await ref.read(authControllerProvider.notifier).resendVerification();
      message = sent ? 'Verification email sent.' : 'Already verified.';
    } catch (_) {
      message = 'Could not send the email. Try again.';
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text('Confirm your email to unlock practice.'),
          ),
          TextButton(
            onPressed: _busy ? null : _resend,
            child: _busy
                ? const SizedBox(
                    height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Resend'),
          ),
        ],
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
