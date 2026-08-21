import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/user_word.dart';
import '../../core/providers.dart';
import 'vocabulary_repository.dart';

class VocabularyState {
  const VocabularyState({
    this.words = const [],
    this.languages = const [],
    this.selectedLanguage,
    this.query = '',
    this.page = 1,
    this.total = 0,
    this.hasMore = false,
    this.loading = true,
    this.loadingMore = false,
    this.error,
  });

  final List<UserWord> words;
  final List<LanguageCount> languages;
  final String? selectedLanguage; // null = all languages
  final String query;
  final int page;
  final int total;
  final bool hasMore;
  final bool loading;
  final bool loadingMore;
  final String? error;

  VocabularyState copyWith({
    List<UserWord>? words,
    List<LanguageCount>? languages,
    Object? selectedLanguage = _sentinel,
    String? query,
    int? page,
    int? total,
    bool? hasMore,
    bool? loading,
    bool? loadingMore,
    Object? error = _sentinel,
  }) {
    return VocabularyState(
      words: words ?? this.words,
      languages: languages ?? this.languages,
      selectedLanguage: selectedLanguage == _sentinel
          ? this.selectedLanguage
          : selectedLanguage as String?,
      query: query ?? this.query,
      page: page ?? this.page,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error == _sentinel ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

class VocabularyController extends StateNotifier<VocabularyState> {
  VocabularyController(this._repo) : super(const VocabularyState()) {
    load();
  }

  final VocabularyRepository _repo;
  static const _limit = 20;

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final results = await Future.wait([
        _repo.list(
          page: 1,
          limit: _limit,
          query: state.query,
          language: state.selectedLanguage,
        ),
        _repo.languages(),
      ]);
      final page = results[0] as dynamic;
      final langs = results[1] as List<LanguageCount>;
      state = state.copyWith(
        words: List<UserWord>.from(page.items),
        languages: langs,
        page: 1,
        total: page.total,
        hasMore: page.items.length >= _limit,
        loading: false,
      );
    } on VocabularyException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
          loading: false, error: 'Could not load your words. Pull to retry.');
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final next = state.page + 1;
      final page = await _repo.list(
        page: next,
        limit: _limit,
        query: state.query,
        language: state.selectedLanguage,
      );
      state = state.copyWith(
        words: [...state.words, ...page.items],
        page: next,
        total: page.total,
        hasMore: page.items.length >= _limit,
        loadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(loadingMore: false);
    }
  }

  Future<void> search(String query) async {
    if (query == state.query) return;
    state = state.copyWith(query: query);
    await load();
  }

  Future<void> selectLanguage(String? language) async {
    state = state.copyWith(selectedLanguage: language);
    await load();
  }

  Future<void> refresh() => load();

  Future<bool> remove(String uuid) async {
    final previous = state.words;
    // Optimistic removal.
    state = state.copyWith(
      words: previous.where((w) => w.uuid != uuid).toList(),
      total: (state.total - 1).clamp(0, 1 << 31),
    );
    try {
      await _repo.remove(uuid);
      return true;
    } catch (_) {
      state = state.copyWith(words: previous); // roll back
      return false;
    }
  }
}

final vocabularyRepositoryProvider = Provider<VocabularyRepository>((ref) {
  return VocabularyRepository(ref.watch(apiClientProvider));
});

final vocabularyControllerProvider =
    StateNotifierProvider<VocabularyController, VocabularyState>((ref) {
  return VocabularyController(ref.watch(vocabularyRepositoryProvider));
});
