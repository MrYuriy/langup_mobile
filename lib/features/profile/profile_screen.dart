import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n.dart';
import '../../core/languages.dart';
import '../../core/models/exercise_preferences.dart';
import '../../core/models/subscription.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../audio/voice_settings.dart';
import '../dashboard/dashboard_controller.dart' show paymentsRepositoryProvider;
import '../practice/practice_controller.dart' show exercisesRepositoryProvider;

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
      _snack(t('toast.saved'));
    } catch (_) {
      _snack(t('toast.save_fail'));
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
        title: Text(t('nav.profile')),
        actions: [
          IconButton(
            tooltip: t('common.retry'),
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
                Text(t('settings.your_details'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: t('settings.name'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                _langDropdown(t('settings.i_speak'), _native,
                    (v) => setState(() => _native = v)),
                const SizedBox(height: 12),
                _langDropdown(t('settings.im_learning'), _target,
                    (v) => setState(() => _target = v)),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(t('common.save')),
                ),

                const SizedBox(height: 24),
                const VoiceSettings(),

                const SizedBox(height: 24),
                const _InterfaceLanguage(),

                const SizedBox(height: 24),
                const _AppearanceSetting(),

                const SizedBox(height: 24),
                const _PracticeSettings(),

                const SizedBox(height: 24),
                _PlanSection(),

                const SizedBox(height: 24),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(t('account.signout')),
                  onTap: auth.logout,
                ),
                ListTile(
                  leading: const Icon(Icons.logout_outlined),
                  title: Text(t('account.signout_all')),
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
        DropdownMenuItem(value: null, child: Text(t('common.not_set'))),
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
            .showSnackBar(SnackBar(content: Text(t('auth.could_not_open'))));
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
        final active = s?.isActive ?? false;
        final label = !active
            ? t('plan.free')
            : ((s?.isTrial ?? false) ? t('plan.premium_trial') : t('plan.premium'));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('plan.subscription'),
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
                            child: Text(t('plan.manage')))
                        : FilledButton(
                            onPressed: () => _open(
                                context, ref, repo.checkoutUrl('premium_monthly')),
                            child: Text(t('plan.upgrade')))),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Interface language — the language the app's own text is shown in
/// (independent of which languages the user is learning).
class _InterfaceLanguage extends ConsumerWidget {
  const _InterfaceLanguage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('settings.ui_language'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: lang,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: [
            for (final code in kUiSupported)
              DropdownMenuItem(value: code, child: Text(languageName(code))),
          ],
          onChanged: (v) {
            if (v != null) ref.read(localeProvider.notifier).setLang(v);
          },
        ),
      ],
    );
  }
}

/// Theme choice: follow the system, or force light / dark.
class _AppearanceSetting extends ConsumerWidget {
  const _AppearanceSetting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('appearance.title'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: [
            ButtonSegment(
                value: ThemeMode.system,
                label: Text(t('appearance.system')),
                icon: const Icon(Icons.brightness_auto)),
            ButtonSegment(
                value: ThemeMode.light,
                label: Text(t('appearance.light')),
                icon: const Icon(Icons.light_mode)),
            ButtonSegment(
                value: ThemeMode.dark,
                label: Text(t('appearance.dark')),
                icon: const Icon(Icons.dark_mode)),
          ],
          selected: {mode},
          showSelectedIcon: false,
          onSelectionChanged: (s) =>
              ref.read(themeModeProvider.notifier).setMode(s.first),
        ),
      ],
    );
  }
}

/// Practice preferences. Currently just the match-pairs filler toggle — whether
/// a matching round may be topped up with random shared-dictionary words when
/// the user's own vocabulary can't fill the board.
class _PracticeSettings extends ConsumerStatefulWidget {
  const _PracticeSettings();

  @override
  ConsumerState<_PracticeSettings> createState() => _PracticeSettingsState();
}

class _PracticeSettingsState extends ConsumerState<_PracticeSettings> {
  ExercisePreferences? _prefs;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await ref.read(exercisesRepositoryProvider).preferences();
      if (mounted) setState(() => _prefs = prefs);
    } catch (_) {
      // Leave the section hidden if preferences can't be loaded.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(bool value) async {
    final current = _prefs;
    if (current == null || _saving) return;
    setState(() {
      _saving = true;
      _prefs = current.copyWith(matchPairsFillers: value); // optimistic
    });
    try {
      final saved = await ref
          .read(exercisesRepositoryProvider)
          .setPreferences(current.copyWith(matchPairsFillers: value));
      if (mounted) setState(() => _prefs = saved);
    } catch (_) {
      if (mounted) {
        setState(() => _prefs = current); // roll back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('settings.could_not_save'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _prefs == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('nav.practice'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t('practice.fillers_toggle')),
          subtitle: Text(t('practice.fillers_subtitle')),
          value: _prefs!.matchPairsFillers,
          onChanged: _saving ? null : _toggle,
        ),
      ],
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
      message = sent ? t('verify.sent') : t('toast.already_verified');
    } catch (_) {
      message = t('toast.verify_send_fail');
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
          Expanded(child: Text(t('verify.unlock'))),
          TextButton(
            onPressed: _busy ? null : _resend,
            child: _busy
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(t('verify.resend_short')),
          ),
        ],
      ),
    );
  }
}
