import 'dart:math';

/// Pure (Flutter-free) state machine for a match-pairs round, so the dealing
/// logic can be unit-tested. Faithful port of the web `practice.js`:
/// solving a pair removes it, but new pairs are dealt only every second solve,
/// so the board never collapses to one obvious choice.
class MatchPairsRound {
  MatchPairsRound({
    required List<({String id, String word, String translation})> pairs,
    required this.visible,
    required this.maxMistakes,
    Random? rng,
  }) : _rng = rng ?? Random() {
    for (final p in pairs) {
      all[p.id] = (word: p.word, translation: p.translation);
    }
    final ids = all.keys.toList();
    queue = ids.skip(visible).toList();
    left = ids.take(visible).toList()..shuffle(_rng);
    right = ids.take(visible).toList()..shuffle(_rng);
  }

  static const pairsPerRefill = 2;
  final Random _rng;
  final int visible;
  final int maxMistakes;

  final all = <String, ({String word, String translation})>{};
  late List<String> queue;
  late List<String> left;
  late List<String> right;

  ({String side, String id})? picked;
  final solved = <String, String>{};
  final wrong = <String>{};
  int mistakes = 0;
  int _sinceRefill = 0;

  bool get isComplete => left.isEmpty;
  bool get isFailed => mistakes >= maxMistakes;

  /// Outcome of a tap.
  MatchTap pick(String side, String id) {
    final current = picked;
    if (current == null) {
      picked = (side: side, id: id);
      return MatchTap.selected;
    }
    if (current.side == side) {
      picked = (side: side, id: id); // move selection within a column
      return MatchTap.selected;
    }
    picked = null;
    if (current.id == id) {
      _solve(id);
      return MatchTap.solved;
    }
    _miss(current, (side: side, id: id));
    return MatchTap.missed;
  }

  void _solve(String id) {
    solved[id] = all[id]!.translation;
    left.remove(id);
    right.remove(id);
    _sinceRefill += 1;
    // Deal new pairs only every other solve (see class doc).
    if (_sinceRefill >= pairsPerRefill) {
      _sinceRefill = 0;
      for (var i = 0; i < pairsPerRefill && queue.isNotEmpty; i++) {
        final next = queue.removeAt(0);
        left.insert(_rng.nextInt(left.length + 1), next);
        right.insert(_rng.nextInt(right.length + 1), next);
      }
    }
  }

  void _miss(({String side, String id}) a, ({String side, String id}) b) {
    mistakes += 1;
    wrong
      ..add('${a.side}:${a.id}')
      ..add('${b.side}:${b.id}');
  }

  /// Clears the transient wrong-flash markers (called after the flash delay).
  void clearWrong() => wrong.clear();
}

enum MatchTap { selected, solved, missed }
