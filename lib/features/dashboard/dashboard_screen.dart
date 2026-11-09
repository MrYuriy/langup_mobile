import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/mastery.dart';
import '../../core/models/streak.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);
    final ctrl = ref.read(dashboardControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(t('title.dashboard'))),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: ctrl.load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (state.streak != null) ...[
                    _StreakCard(streak: state.streak!),
                    const SizedBox(height: 16),
                  ],
                  _statGrid(context, state),
                  const SizedBox(height: 24),
                  _MasterySection(state: state),
                  const SizedBox(height: 24),
                  _PlanCard(state: state),
                ],
              ),
            ),
    );
  }

  Widget _statGrid(BuildContext context, DashboardState s) {
    final gen = s.quota == null
        ? '—'
        : s.quota!.unlimited
            ? '${s.quota!.used} · ∞'
            : '${s.quota!.used} / ${s.quota!.limit}';
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatTile(
            label: t('dash.total_words'),
            value: '${s.total}',
            icon: Icons.menu_book),
        _StatTile(
            label: t('dash.due_now'),
            value: s.dueCapped ? '100+' : '${s.dueCount}',
            icon: Icons.schedule),
        _StatTile(
            label: t('dash.mastered'),
            value: '${s.mastery['MASTERED'] ?? 0}',
            icon: Icons.workspace_premium),
        _StatTile(
            label: t('dash.generated_today'), value: gen, icon: Icons.auto_awesome),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: scheme.primary),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MasterySection extends StatelessWidget {
  const _MasterySection({required this.state});
  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final total = state.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('dash.mastery'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (total == 0)
          Text(t('dash.save_words_hint'),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).disabledColor))
        else ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  for (final level in Mastery.order)
                    Expanded(
                      flex: (state.mastery[level] ?? 0),
                      child: Container(color: Mastery.color(level)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final level in Mastery.order)
                _legend(context, level, state.mastery[level] ?? 0),
            ],
          ),
        ],
      ],
    );
  }

  Widget _legend(BuildContext context, String level, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Mastery.color(level),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text('${masteryLabel(level)} · $count',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.state});
  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final sub = state.subscription;
    final label = sub == null || !sub.isActive
        ? t('plan.free')
        : (sub.isTrial ? t('plan.premium_trial') : t('plan.premium'));
    String? renew;
    if (sub != null && sub.currentPeriodEnd != null) {
      final p = {'date': _date(sub.currentPeriodEnd!)};
      if (sub.isTrial) {
        renew = t('plan.trial_ends', p);
      } else if (sub.isActive) {
        renew = sub.cancelAtPeriodEnd ? t('plan.ends_on', p) : t('plan.renews_on', p);
      }
    }
    return Card(
      child: ListTile(
        leading: const Icon(Icons.card_membership),
        title: Text(t('dash.plan', {'plan': label})),
        subtitle: renew != null ? Text(renew) : null,
      ),
    );
  }

  String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}


/// The practice run, given the top of the screen because it is the one number
/// a learner checks daily.
///
/// Forgiving on purpose — "skip a day, but not two" — so the card never says
/// the run is over while there is still time today. The longest run sits beside
/// the current one: what was earned stays earned, which is what makes a lapse
/// survivable rather than a reason to stop.
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final Streak streak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final urgent = streak.atRisk && streak.current > 0;
    final note = streak.current == 0
        ? t('dash.streak_none')
        : streak.practisedToday
            ? t('dash.streak_today_done')
            : urgent
                ? t('dash.streak_last_chance')
                : t('dash.streak_keep_going');

    return Card(
      margin: EdgeInsets.zero,
      color: urgent ? scheme.errorContainer : scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              streak.practisedToday ? Icons.local_fire_department : Icons.local_fire_department_outlined,
              size: 40,
              color: urgent ? scheme.onErrorContainer : scheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('${streak.current}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              )),
                      const SizedBox(width: 8),
                      // The label carries the word, so the number never has to
                      // agree with it — Ukrainian and Polish would need three
                      // plural forms the translation files cannot express.
                      Text(t('dash.streak'),
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(note, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (streak.longest > 0)
              Column(
                children: [
                  Text('${streak.longest}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                  Text(t('dash.streak_best'),
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
