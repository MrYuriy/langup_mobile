import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models/exercise.dart';
import '../match_pairs_round.dart';

/// Match-pairs round UI. All game logic lives in [MatchPairsRound] (unit-tested):
/// solving a pair removes it, but new pairs are dealt only every second solve,
/// so the board never collapses to one obvious choice — a faithful port of the
/// web `practice.js`. The round ends on a full clear, too many mistakes, or the
/// clock running out.
class MatchPairsView extends StatefulWidget {
  const MatchPairsView({
    super.key,
    required this.exercise,
    required this.onSubmit,
    required this.submitting,
  });

  final Exercise exercise;
  final void Function(ExerciseAnswer) onSubmit;
  final bool submitting;

  @override
  State<MatchPairsView> createState() => _MatchPairsViewState();
}

class _MatchPairsViewState extends State<MatchPairsView> {
  late final MatchPairsRound _round;
  int _secondsLeft = 60;
  Timer? _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    final p = widget.exercise.payload;
    _round = MatchPairsRound(
      pairs: [
        for (final e in (p['pairs'] as List? ?? []))
          (
            id: (e as Map)['id'].toString(),
            word: e['word'].toString(),
            translation: e['translation'].toString(),
          ),
      ],
      visible: (p['visible'] as num?)?.toInt() ?? 4,
      maxMistakes: (p['max_mistakes'] as num?)?.toInt() ?? 3,
    );
    _secondsLeft = (p['time_limit'] as num?)?.toInt() ?? 60;
    _startClock();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft -= 1);
      if (_secondsLeft <= 0) _finish(timedOut: true);
    });
  }

  void _pick(String side, String id) {
    if (_finished) return;
    final result = _round.pick(side, id);
    setState(() {});
    switch (result) {
      case MatchTap.solved:
        if (_round.isComplete) _finish(timedOut: false);
      case MatchTap.missed:
        Timer(const Duration(milliseconds: 550), () {
          if (!mounted) return;
          setState(_round.clearWrong);
          if (_round.isFailed) _finish(timedOut: false);
        });
      case MatchTap.selected:
        break;
    }
  }

  void _finish({required bool timedOut}) {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    widget.onSubmit(ExerciseAnswer(
      Map.of(_round.solved),
      mistakes: _round.mistakes,
      timedOut: timedOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final low = _secondsLeft <= 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                for (var i = 0; i < _round.maxMistakes; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      i < _round.maxMistakes - _round.mistakes
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                  ),
              ],
            ),
            Text('${_secondsLeft.clamp(0, 999)}s',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: low ? Colors.redAccent : null,
                )),
          ],
        ),
        const SizedBox(height: 8),
        Text('${_round.solved.length} of ${_round.all.length}',
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _column('left', _round.left,
                        (id) => _round.all[id]!.word)),
                const SizedBox(width: 12),
                Expanded(
                    child: _column('right', _round.right,
                        (id) => _round.all[id]!.translation)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _column(String side, List<String> ids, String Function(String) text) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final id in ids)
          Padding(
            key: ValueKey('$side:$id'),
            padding: const EdgeInsets.only(bottom: 10),
            child: _card(side, id, text(id), scheme),
          ),
      ],
    );
  }

  Widget _card(String side, String id, String label, ColorScheme scheme) {
    final picked = _round.picked;
    final isPicked = picked?.side == side && picked?.id == id;
    final isWrong = _round.wrong.contains('$side:$id');
    Color bg = scheme.surfaceContainerHighest;
    if (isWrong) {
      bg = scheme.errorContainer;
    } else if (isPicked) {
      bg = scheme.primaryContainer;
    }
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pick(side, id),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          alignment: Alignment.center,
          child: Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
