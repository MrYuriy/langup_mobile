import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/exercise.dart';
import '../../core/models/user_word.dart';
import '../../core/providers.dart';
import '../vocabulary/vocabulary_controller.dart';
import 'exercises_repository.dart';

enum PracticePhase { loading, exercise, result, empty, error }

enum EmptyReason { notVerified, dailyLimit, noExercises }

class PracticeState {
  const PracticeState({
    this.phase = PracticePhase.loading,
    this.exercise,
    this.result,
    this.lastAnswer,
    this.languages = const [],
    this.activeLanguage,
    this.activeType,
    this.emptyReason,
    this.quota,
    this.submitting = false,
    this.generating = false,
    this.generateStatus,
  });

  final PracticePhase phase;
  final Exercise? exercise;
  final AttemptResult? result;
  final ExerciseAnswer? lastAnswer;
  final List<LanguageCount> languages;
  final String? activeLanguage;
  final String? activeType; // null = Any
  final EmptyReason? emptyReason;
  final GenerationQuota? quota;
  final bool submitting;
  final bool generating;
  final String? generateStatus;

  PracticeState copyWith({
    PracticePhase? phase,
    Object? exercise = _s,
    Object? result = _s,
    Object? lastAnswer = _s,
    List<LanguageCount>? languages,
    Object? activeLanguage = _s,
    Object? activeType = _s,
    Object? emptyReason = _s,
    Object? quota = _s,
    bool? submitting,
    bool? generating,
    Object? generateStatus = _s,
  }) {
    return PracticeState(
      phase: phase ?? this.phase,
      exercise: exercise == _s ? this.exercise : exercise as Exercise?,
      result: result == _s ? this.result : result as AttemptResult?,
      lastAnswer: lastAnswer == _s ? this.lastAnswer : lastAnswer as ExerciseAnswer?,
      languages: languages ?? this.languages,
      activeLanguage:
          activeLanguage == _s ? this.activeLanguage : activeLanguage as String?,
      activeType: activeType == _s ? this.activeType : activeType as String?,
      emptyReason:
          emptyReason == _s ? this.emptyReason : emptyReason as EmptyReason?,
      quota: quota == _s ? this.quota : quota as GenerationQuota?,
      submitting: submitting ?? this.submitting,
      generating: generating ?? this.generating,
      generateStatus:
          generateStatus == _s ? this.generateStatus : generateStatus as String?,
    );
  }

  static const _s = Object();
}

class PracticeController extends StateNotifier<PracticeState> {
  PracticeController(this._repo, this._languages) : super(const PracticeState()) {
    _init();
  }

  final ExercisesRepository _repo;
  final Future<List<LanguageCount>> Function() _languages;

  Future<void> _init() async {
    try {
      final langs = await _languages();
      final codes = langs.map((l) => l.language).toList();
      state = state.copyWith(
        languages: langs,
        activeLanguage: codes.isNotEmpty ? codes.first : null,
      );
    } catch (_) {
      // Practice can still run on the server's default language.
    }
    await loadNext();
  }

  Future<void> loadNext() async {
    state = state.copyWith(phase: PracticePhase.loading, result: null);
    try {
      final next =
          await _repo.next(type: state.activeType, language: state.activeLanguage);
      switch (next.status) {
        case NextStatus.ok:
          state = state.copyWith(
              phase: PracticePhase.exercise, exercise: next.exercise);
        case NextStatus.notVerified:
          state = state.copyWith(
              phase: PracticePhase.empty, emptyReason: EmptyReason.notVerified);
        case NextStatus.empty:
          final quota = await _repo.quota();
          final limited = quota != null &&
              !quota.unlimited &&
              (quota.remaining ?? 0) == 0;
          state = state.copyWith(
            phase: PracticePhase.empty,
            quota: quota,
            emptyReason:
                limited ? EmptyReason.dailyLimit : EmptyReason.noExercises,
          );
        case NextStatus.error:
          state = state.copyWith(phase: PracticePhase.error);
      }
    } catch (_) {
      state = state.copyWith(phase: PracticePhase.error);
    }
  }

  Future<void> submit(ExerciseAnswer answer) async {
    final ex = state.exercise;
    if (ex == null || state.submitting) return;
    state = state.copyWith(submitting: true);
    try {
      final result = await _repo.attempt(ex.uuid, answer);
      state = state.copyWith(
          phase: PracticePhase.result,
          result: result,
          lastAnswer: answer,
          submitting: false);
    } catch (_) {
      state = state.copyWith(submitting: false);
      rethrow;
    }
  }

  void selectType(String? type) {
    state = state.copyWith(activeType: type);
    loadNext();
  }

  void selectLanguage(String? language) {
    state = state.copyWith(activeLanguage: language);
    loadNext();
  }

  /// Generate more exercises on demand, polling a queued job. Returns how many
  /// were created (0 = none, null = didn't finish).
  Future<int?> generateMore() async {
    state = state.copyWith(generating: true, generateStatus: 'Generating…');
    try {
      final r = await _repo.refill(
          type: state.activeType, language: state.activeLanguage);
      int? created = r.created;
      if (r.taskId != null) {
        created = await _poll(r.taskId!);
      }
      state = state.copyWith(generating: false, generateStatus: null);
      if (created != null && created > 0) {
        await loadNext();
      }
      return created;
    } catch (_) {
      state = state.copyWith(generating: false, generateStatus: null);
      return null;
    }
  }

  static const _pollLimit = Duration(milliseconds: 180000);

  Future<int?> _poll(String taskId) async {
    final until = DateTime.now().add(_pollLimit);
    while (DateTime.now().isBefore(until)) {
      await Future.delayed(const Duration(seconds: 2));
      final s = await _repo.refillStatus(taskId);
      if (s.done) return s.created ?? 0;
      if (s.failed) return null;
    }
    return null;
  }
}

final exercisesRepositoryProvider = Provider<ExercisesRepository>((ref) {
  return ExercisesRepository(ref.watch(apiClientProvider));
});

final practiceControllerProvider =
    StateNotifierProvider<PracticeController, PracticeState>((ref) {
  final repo = ref.watch(exercisesRepositoryProvider);
  final vocab = ref.watch(vocabularyRepositoryProvider);
  return PracticeController(repo, vocab.languages);
});
