import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/mastery.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);
    final ctrl = ref.read(dashboardControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: ctrl.load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
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
        _StatTile(label: 'Total words', value: '${s.total}', icon: Icons.menu_book),
        _StatTile(
            label: 'Due now',
            value: s.dueCapped ? '100+' : '${s.dueCount}',
            icon: Icons.schedule),
        _StatTile(
            label: 'Mastered',
            value: '${s.mastery['MASTERED'] ?? 0}',
            icon: Icons.workspace_premium),
        _StatTile(label: 'Generated today', value: gen, icon: Icons.auto_awesome),
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
        Text('Mastery', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (total == 0)
          Text('Save words to see your progress here.',
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
        Text('${Mastery.label(level)} · $count',
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
    final label = sub?.label ?? 'Free';
    String? renew;
    if (sub != null && sub.currentPeriodEnd != null) {
      final when = _date(sub.currentPeriodEnd!);
      if (sub.isTrial) {
        renew = 'Trial ends on $when';
      } else if (sub.isActive) {
        renew = sub.cancelAtPeriodEnd ? 'Ends on $when' : 'Renews on $when';
      }
    }
    return Card(
      child: ListTile(
        leading: const Icon(Icons.card_membership),
        title: Text('Plan: $label'),
        subtitle: renew != null ? Text(renew) : null,
      ),
    );
  }

  String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
