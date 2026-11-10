/// The user's subscription — matches `SubscriptionOut`.
class Subscription {
  const Subscription({
    required this.status,
    required this.planCode,
    required this.isActive,
    required this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    required this.isManaged,
  });

  final String status; // e.g. TRIALING, ACTIVE, NONE
  final String? planCode;
  final bool isActive;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;

  /// Whether Stripe has anything to manage. The free trial we grant on sign-up
  /// is active but has no Stripe subscription behind it, so opening the billing
  /// portal for it can only fail — offer an upgrade instead.
  final bool isManaged;

  bool get isTrial => status == 'TRIALING' && isActive;

  /// Human label used by the dashboard and profile.
  String get label {
    if (isTrial) return 'Premium trial';
    if (isActive) return 'Premium';
    return 'Free';
  }

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        status: json['status'] as String,
        planCode: json['plan_code'] as String?,
        isActive: json['is_active'] as bool? ?? false,
        currentPeriodEnd: json['current_period_end'] != null
            ? DateTime.tryParse(json['current_period_end'] as String)
            : null,
        cancelAtPeriodEnd: json['cancel_at_period_end'] as bool? ?? false,
        // Defaults to false against an older server: a missing Manage button
        // is a smaller harm than one that dies on a 400.
        isManaged: json['is_managed'] as bool? ?? false,
      );
}
