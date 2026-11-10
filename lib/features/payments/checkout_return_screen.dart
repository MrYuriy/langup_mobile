import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../dashboard/dashboard_controller.dart' show paymentsRepositoryProvider;

/// Where a finished Stripe checkout lands.
///
/// Reached by deep link: Stripe redirects to our own /app/checkout/... which
/// Android hands straight to the app, so the customer is back inside LangUp
/// rather than stranded on a web page.
///
/// It waits for the subscription rather than trusting the redirect. Stripe
/// sends the browser back the moment the card clears, but the account only
/// becomes premium when the `invoice.paid` webhook reaches our server — a
/// second or two later, sometimes more. Navigating straight to the profile
/// would show "Free" right after a successful payment, which reads as a
/// failure. So this polls until the subscription says otherwise.
class CheckoutReturnScreen extends ConsumerStatefulWidget {
  const CheckoutReturnScreen({super.key, required this.outcome});

  /// success | cancel | portal
  final String outcome;

  @override
  ConsumerState<CheckoutReturnScreen> createState() => _CheckoutReturnScreenState();
}

class _CheckoutReturnScreenState extends ConsumerState<CheckoutReturnScreen> {
  /// Long enough for a webhook that is merely slow, short enough that nobody
  /// watches a spinner wondering whether it is stuck.
  static const _patience = Duration(seconds: 20);
  static const _between = Duration(seconds: 2);

  bool _settled = false;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    if (widget.outcome == 'cancel') {
      _settled = true; // nothing was charged; nothing to wait for
    } else {
      _awaitSubscription();
    }
  }

  Future<void> _awaitSubscription() async {
    final deadline = DateTime.now().add(_patience);
    while (mounted && DateTime.now().isBefore(deadline)) {
      try {
        final sub = await ref.read(paymentsRepositoryProvider).subscription();
        if (sub != null && sub.isActive) {
          if (mounted) setState(() => _settled = true);
          return;
        }
      } catch (_) {
        // Offline or a hiccup — keep trying until the deadline rather than
        // telling somebody who has just paid that something went wrong.
      }
      await Future.delayed(_between);
    }
    if (mounted) setState(() => _settled = _timedOut = true);
  }

  void _leave() => context.go('/profile');

  @override
  Widget build(BuildContext context) {
    final cancelled = widget.outcome == 'cancel';
    final scheme = Theme.of(context).colorScheme;

    final (icon, title, note) = switch ((cancelled, _settled, _timedOut)) {
      (true, _, _) => (Icons.info_outline, t('checkout.cancelled'), t('checkout.cancelled_note')),
      (_, false, _) => (Icons.hourglass_top, t('checkout.confirming'), t('checkout.confirming_note')),
      (_, true, true) => (Icons.schedule, t('checkout.slow'), t('checkout.slow_note')),
      _ => (Icons.check_circle_outline, t('checkout.done'), t('checkout.done_note')),
    };

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_settled)
                const CircularProgressIndicator()
              else
                Icon(icon, size: 56, color: cancelled || _timedOut ? null : scheme.primary),
              const SizedBox(height: 24),
              Text(title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(note,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 32),
              // Always offered, even while waiting: nobody should be held on
              // this screen by a webhook that may never arrive.
              FilledButton(onPressed: _leave, child: Text(t('checkout.continue'))),
            ],
          ),
        ),
      ),
    );
  }
}
