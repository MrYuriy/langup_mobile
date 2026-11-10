import 'package:flutter_test/flutter_test.dart';
import 'package:langup_mobile/core/models/subscription.dart';

/// The "Manage" button opens Stripe's billing portal, and that portal can only
/// exist for a subscription Stripe knows about. The trial we grant on sign-up
/// is active but entirely ours — it has no provider subscription behind it, so
/// the server answers the portal request with a 400. The profile screen used to
/// show Manage for any active subscription, so every trialist got a button that
/// could only fail.
void main() {
  Subscription parse(Map<String, dynamic> json) => Subscription.fromJson(json);

  test('a self-granted trial is active but not managed', () {
    final sub = parse({'status': 'TRIALING', 'is_active': true, 'is_managed': false});

    expect(sub.isActive, isTrue);
    expect(sub.isTrial, isTrue);
    expect(sub.isManaged, isFalse, reason: 'no Stripe subscription to open a portal for');
  });

  test('a paid subscription is managed', () {
    final sub = parse({'status': 'ACTIVE', 'is_active': true, 'is_managed': true});

    expect(sub.isManaged, isTrue);
  });

  test('an older server, which never sends the field, hides Manage', () {
    // A missing button is a smaller harm than one that dies on a 400.
    expect(parse({'status': 'ACTIVE', 'is_active': true}).isManaged, isFalse);
  });

  test('nothing at all is neither active nor managed', () {
    final sub = parse({'status': 'EXPIRED', 'is_active': false});

    expect(sub.isActive, isFalse);
    expect(sub.isManaged, isFalse);
  });
}
