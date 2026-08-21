import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/models/exercise.dart';

/// Match-pairs round. Solving a pair removes it but new pairs are dealt only
/// every second solve, so the board never collapses to one obvious choice —
/// a faithful port of the web `practice.js` round logic. The round ends on a
/// full clear, too many mistakes, or the clock running out.
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

class _PairsData {
  final String word;
  final String translation;
  const _PairsData(this.word, this.translation);
}

class _MatchPairsViewState extends State<MatchPairsView> {
  static const _pairsPerRefill = 2;
  final _rng = Random();

  final _all = <String, _PairsData>{};
  late List<String> _queue;
  late List<String> _left;
  late List<String> _right;

  ({String side, String id})? _picked;
  final _solved = <String, String>{};
  final _wrong = <String>{};
  int _mistakes = 0;
  int _maxMistakes = 3;
  int _sinceRefill = 0;

  int _secondsLeft = 60;
  Timer? _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    final p = widget.exercise.payload;
    for (final e in (p['pairs'] as List? ?? [])) {
      final m = (e as Map).cast<String, dynamic>();
      _all[m['id'].toString()] =
          _PairsData(m['word'].toString(), m['translation'].toString());
    }
    final ids = _all.keys.toList();
    final visible = (p['visible'] as num?)?.toInt() ?? 4;
    _maxMistakes = (p['max_mistakes'] as num?)?.toInt() ?? 3;
    _secondsLeft = (p['time_limit'] as num?)?.toInt() ?? 60;

    _queue = ids.skip(visible).toList();
    _left = (ids.take(visible).toList()..shuffle(_rng));
    _right = (ids.take(visible).toList()..shuffle(_rng));
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
    final picked = _picked;
    if (picked == null) {
      setState(() => _picked = (side: side, id: id));
      return;
    }
    if (picked.side == side) {
      setState(() => _picked = (side: side, id: id)); // move selection
      return;
    }
    _picked = null;
    if (picked.id == id) {
      _solve(id);
    } else {
      _miss(picked, (side: side, id: id));
    }
  }

  void _solve(String id) {
    _solved[id] = _all[id]!.translation;
    _left.remove(id);
    _right.remove(id);
    _sinceRefill += 1;
    if (_sinceRefill >= _pairsPerRefill) {
      _sinceRefill = 0;
      for (var i = 0; i < _pairsPerRefill && _queue.isNotEmpty; i++) {
        final next = _queue.removeAt(0);
        _left.insert(_rng.nextInt(_left.length + 1), next);
        _right.insert(_rng.nextInt(_right.length + 1), next);
      }
    }
    setState(() {});
    if (_left.isEmpty) _finish(timedOut: false);
  }

  void _miss(({String side, String id}) a, ({String side, String id}) b) {
    setState(() {
      _mistakes += 1;
      _wrong
        ..add('${a.side}:${a.id}')
        ..add('${b.side}:${b.id}');
    });
    Future.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      setState(() => _wrong.clear());
      if (_mistakes >= _maxMistakes) _finish(timedOut: false);
    });
  }

  void _finish({required bool timedOut}) {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    widget.onSubmit(ExerciseAnswer(
      Map.of(_solved),
      mistakes: _mistakes,
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
                for (var i = 0; i < _maxMistakes; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      i < _maxMistakes - _mistakes
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
        Text('${_solved.length} of ${_all.length}',
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _column('left', _left, (id) => _all[id]!.word)),
                const SizedBox(width: 12),
                Expanded(
                    child: _column(
                        'right', _right, (id) => _all[id]!.translation)),
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
            padding: const EdgeInsets.only(bottom: 10),
            child: _card(side, id, text(id), scheme),
          ),
      ],
    );
  }

  Widget _card(String side, String id, String label, ColorScheme scheme) {
    final key = '$side:$id';
    final isPicked = _picked?.side == side && _picked?.id == id;
    final isWrong = _wrong.contains(key);
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
