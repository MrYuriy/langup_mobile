import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/languages.dart';
import '../../core/models/subscription.dart';
import '../../core/providers.dart';
import '../dashboard/dashboard_controller.dart' show paymentsRepositoryProvider;

final _subscriptionProvider =
    FutureProvider.autoDispose<Subscription?>((ref) {
  return ref.watch(paymentsRepositoryProvider).subscription();
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  String? _native;
  String? _target;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _seed() {
    if (_initialized) return;
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;
    _name.text = user.fullName ?? '';
    _native = _valid(user.nativeLanguage);
    _target = _valid(user.targetLanguage);
    _initialized = true;
  }

  String? _valid(String? code) =>
      (code != null && kLanguages.any((l) => l.code == code)) ? code : null;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            fullName: _name.text.trim().isEmpty ? null : _name.text.trim(),
            nativeLanguage: _native,
            targetLanguage: _target,
          );
      _snack('Saved');
    } catch (_) {
      _snack('Could not save');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    _seed();
    final user = ref.watch(authControllerProvider).user;
    final auth = ref.read(authControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: auth.refreshUser,
          ),
        ],
      ),
      body: user == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (!user.isEmailVerified)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: _VerifyBanner(),
                  ),
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        child: Text(
                          (user.fullName?.trim().isNotEmpty ?? false
                                  ? user.fullName!.trim()[0]
                                  : user.email[0])
                              .toUpperCase(),
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(user.email,
                          style: Theme.of(context).textTheme.bodyMedium),
                      Text(user.role,
                          style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- Editable profile ---
                Text('Your details',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                _langDropdown('Native language', _native,
                    (v) => setState(() => _native = v)),
                const SizedBox(height: 12),
                _langDropdown('Target language', _target,
                    (v) => setState(() => _target = v)),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),

                const SizedBox(height: 24),
                _PlanSection(),

                const SizedBox(height: 24),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  onTap: auth.logout,
                ),
                ListTile(
                  leading: const Icon(Icons.logout_outlined),
                  title: const Text('Sign out on all devices'),
                  onTap: auth.logoutEverywhere,
                ),
              ],
            ),
    );
  }

  Widget _langDropdown(
      String label, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('— not set —')),
        for (final l in kLanguages)
          DropdownMenuItem(value: l.code, child: Text(l.name)),
      ],
      onChanged: onChanged,
    );
  }
}

/// Subscription status + upgrade/manage. On iOS the hosted-Stripe buttons are
/// hidden — Apple requires in-app purchase for digital subscriptions, so linking
/// out to Stripe there would fail review.
class _PlanSection extends ConsumerWidget {
  bool get _hidePayments =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _open(BuildContext context, WidgetRef ref, Future<String> url) async {
    try {
      final target = await url;
      await launchUrl(Uri.parse(target), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not open the page.')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(_subscriptionProvider);
    final repo = ref.read(paymentsRepositoryProvider);

    return sub.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (s) {
        final label = s?.label ?? 'Free';
        final active = s?.isActive ?? false;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subscription',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.card_membership),
                title: Text(label),
                trailing: _hidePayments
                    ? null
                    : (active
                        ? TextButton(
                            onPressed: () =>
                                _open(context, ref, repo.portalUrl()),
                            child: const Text('Manage'))
                        : FilledButton(
                            onPressed: () => _open(
                                context, ref, repo.checkoutUrl('premium_monthly')),
                            child: const Text('Upgrade'))),
              ),
            ),
          ],
        );
      },
    );
  }
}

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
      final sent =
          await ref.read(authControllerProvider.notifier).resendVerification();
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
          const Expanded(child: Text('Confirm your email to unlock practice.')),
          TextButton(
            onPressed: _busy ? null : _resend,
            child: _busy
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Resend'),
          ),
        ],
      ),
    );
  }
}
