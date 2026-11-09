import 'package:flutter/material.dart';

import '../../core/i18n.dart';

/// How much of a song — or a whole playlist — the learner already has words for.
///
/// The number that makes this app's progress feel like progress: it is built
/// from their own vocabulary against the music they chose, and it climbs on its
/// own whenever they save a word that happens to appear here. So it is shown
/// wherever a song is listed, not hidden on a statistics screen.
class ComprehensionBar extends StatelessWidget {
  const ComprehensionBar({super.key, required this.percent, this.prominent = false});

  final int percent;

  /// A playlist's own figure, shown once at the top, earns more weight than the
  /// per-song bars repeated down the list.
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Red-to-green would read as "bad at 20%", which is wrong: 20% of a song
    // you have never studied is a start. One colour, filling up.
    final label = Text(
      t('playlist.understood', {'n': percent}),
      style: (prominent
              ? Theme.of(context).textTheme.labelLarge
              : Theme.of(context).textTheme.labelSmall)
          ?.copyWith(
        color: prominent ? scheme.primary : null,
        fontWeight: prominent ? FontWeight.w600 : null,
      ),
    );

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: prominent ? 8 : 4,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(width: 8),
        label,
      ],
    );
  }
}
