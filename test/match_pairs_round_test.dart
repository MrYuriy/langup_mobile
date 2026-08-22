import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:langup_mobile/features/practice/match_pairs_round.dart';

MatchPairsRound _round({int total = 10, int visible = 4}) {
  return MatchPairsRound(
    pairs: [
      for (var i = 1; i <= total; i++)
        (id: '$i', word: 'w$i', translation: 't$i'),
    ],
    visible: visible,
    maxMistakes: 3,
    rng: Random(42), // deterministic
  );
}

/// Solve one currently-visible pair correctly (pick its word then its match).
void _solveOne(MatchPairsRound r) {
  final id = r.left.first;
  expect(r.pick('left', id), MatchTap.selected);
  expect(r.pick('right', id), MatchTap.solved);
}

void main() {
  test('deals new pairs every second correct solve', () {
    final r = _round(); // 10 pairs, 4 visible, 6 queued
    expect(r.left.length, 4);
    expect(r.queue.length, 6);

    _solveOne(r); // solve #1 — no deal yet
    expect(r.solved.length, 1);
    expect(r.left.length, 3, reason: 'board shrinks by one after first solve');
    expect(r.queue.length, 6, reason: 'no deal until the second solve');

    _solveOne(r); // solve #2 — deals 2 new pairs
    expect(r.solved.length, 2);
    expect(r.queue.length, 4, reason: 'two pairs dealt from the queue');
    expect(r.left.length, 4, reason: 'board refilled back to visible size');
    expect(r.right.length, 4);
  });

  test('every pair can be solved and the queue fully drains', () {
    final r = _round();
    var guard = 0;
    while (!r.isComplete && guard++ < 100) {
      _solveOne(r);
    }
    expect(r.isComplete, isTrue);
    expect(r.solved.length, 10, reason: 'all ten pairs solved');
    expect(r.queue, isEmpty, reason: 'queue fully drained');
  });

  test('a wrong match costs a life but removes nothing', () {
    final r = _round();
    final a = r.left.first;
    final b = r.right.firstWhere((x) => x != a); // a different pair's translation
    expect(r.pick('left', a), MatchTap.selected);
    expect(r.pick('right', b), MatchTap.missed);
    expect(r.mistakes, 1);
    expect(r.solved, isEmpty);
    expect(r.left.length, 4, reason: 'nothing removed on a miss');
  });
}
