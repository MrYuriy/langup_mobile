import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/exercise.dart';
import '../../core/models/subscription.dart';
import '../../core/providers.dart';
import '../payments/payments_repository.dart';
import '../practice/practice_controller.dart';
import '../review/review_repository.dart';
import '../vocabulary/vocabulary_controller.dart';

/// Read-only progress overview, computed from existing endpoints (no dedicated
/// stats API) — mirrors the web `dashboard.js`.
class DashboardState {
  const DashboardState({
    this.loading = true,
    this.total = 0,
    this.mastery = const {'NEW': 0, 'LEARNING': 0, 'REVIEW': 0, 'MASTERED': 0},
    this.dueCount = 0,
    this.dueCapped = false,
    this.quota,
    this.subscription,
  });

  final bool loading;
  final int total;
  final Map<String, int> mastery;
  final int dueCount;
  final bool dueCapped;
  final GenerationQuota? quota;
  final Subscription? subscription;

  DashboardState copyWith({
    bool? loading,
    int? total,
    Map<String, int>? mastery,
    int? dueCount,
    bool? dueCapped,
    GenerationQuota? quota,
    Subscription? subscription,
  }) {
    return DashboardState(
      loading: loading ?? this.loading,
      total: total ?? this.total,
      mastery: mastery ?? this.mastery,
      dueCount: dueCount ?? this.dueCount,
      dueCapped: dueCapped ?? this.dueCapped,
      quota: quota ?? this.quota,
      subscription: subscription ?? this.subscription,
    );
  }
}

class DashboardController extends StateNotifier<DashboardState> {
  DashboardController(this._ref) : super(const DashboardState()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(loading: true);

    final vocabF = _ref.read(vocabularyRepositoryProvider).list(limit: 1000);
    final dueF = _ref.read(reviewRepositoryProvider).next(limit: 100);
    final quotaF = _ref.read(exercisesRepositoryProvider).quota();
    final subF = _ref.read(paymentsRepositoryProvider).subscription();

    var next = state.copyWith(loading: false);

    // Each tile degrades independently on its own failure.
    try {
      final page = await vocabF;
      final counts = {'NEW': 0, 'LEARNING': 0, 'REVIEW': 0, 'MASTERED': 0};
      for (final w in page.items) {
        counts[w.masteryLevel] = (counts[w.masteryLevel] ?? 0) + 1;
      }
      next = next.copyWith(total: page.total, mastery: counts);
    } catch (_) {}

    try {
      final due = await dueF;
      next = next.copyWith(dueCount: due.length, dueCapped: due.length >= 100);
    } catch (_) {}

    try {
      next = next.copyWith(quota: await quotaF);
    } catch (_) {}

    try {
      final sub = await subF;
      if (sub != null) next = next.copyWith(subscription: sub);
    } catch (_) {}

    state = next;
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(apiClientProvider));
});

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository(ref.watch(apiClientProvider));
});

final dashboardControllerProvider =
    StateNotifierProvider.autoDispose<DashboardController, DashboardState>((ref) {
  return DashboardController(ref);
});
