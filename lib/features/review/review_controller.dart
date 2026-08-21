import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/due_word.dart';
import '../../core/providers.dart';
import 'review_repository.dart';

enum ReviewPhase { loading, card, done, error }

class ReviewState {
  const ReviewState({
    this.phase = ReviewPhase.loading,
    this.queue = const [],
    this.index = 0,
    this.reviewed = 0,
    this.grading = false,
  });

  final ReviewPhase phase;
  final List<DueWord> queue;
  final int index;
  final int reviewed;
  final bool grading;

  DueWord? get current =>
      index < queue.length ? queue[index] : null;

  ReviewState copyWith({
    ReviewPhase? phase,
    List<DueWord>? queue,
    int? index,
    int? reviewed,
    bool? grading,
  }) {
    return ReviewState(
      phase: phase ?? this.phase,
      queue: queue ?? this.queue,
      index: index ?? this.index,
      reviewed: reviewed ?? this.reviewed,
      grading: grading ?? this.grading,
    );
  }
}

class ReviewController extends StateNotifier<ReviewState> {
  ReviewController(this._repo) : super(const ReviewState()) {
    loadQueue();
  }

  final ReviewRepository _repo;

  Future<void> loadQueue() async {
    state = state.copyWith(phase: ReviewPhase.loading);
    try {
      final items = await _repo.next(limit: 20);
      if (items.isEmpty) {
        state = state.copyWith(phase: ReviewPhase.done);
        return;
      }
      state = state.copyWith(phase: ReviewPhase.card, queue: items, index: 0);
    } catch (_) {
      state = state.copyWith(phase: ReviewPhase.error);
    }
  }

  Future<void> grade(int quality) async {
    final item = state.current;
    if (item == null || state.grading) return;
    state = state.copyWith(grading: true);
    try {
      await _repo.grade(item.uuid, quality);
    } catch (_) {
      state = state.copyWith(grading: false);
      rethrow;
    }
    final nextIndex = state.index + 1;
    final reviewed = state.reviewed + 1;
    if (nextIndex < state.queue.length) {
      state = state.copyWith(index: nextIndex, reviewed: reviewed, grading: false);
    } else {
      // Batch done; the queue was capped, so there may be more still due.
      state = state.copyWith(reviewed: reviewed, grading: false);
      await loadQueue();
    }
  }

  /// After finishing, let the user pull a fresh queue.
  Future<void> restart() async {
    state = const ReviewState();
    await loadQueue();
  }
}

final reviewControllerProvider =
    StateNotifierProvider.autoDispose<ReviewController, ReviewState>((ref) {
  return ReviewController(ReviewRepository(ref.watch(apiClientProvider)));
});
