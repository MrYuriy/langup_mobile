/// The user's subscription — matches `SubscriptionOut`.
class Subscription {
  const Subscription({
    required this.status,
    required this.planCode,
    required this.isActive,
    required this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
  });

  final String status; // e.g. TRIALING, ACTIVE, NONE
  final String? planCode;
  final bool isActive;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;

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
      );
}
