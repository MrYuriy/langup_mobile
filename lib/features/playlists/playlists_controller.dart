import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/models/playlist.dart';
import '../../core/providers.dart';
import 'playlists_repository.dart';

enum ImportPhase { none, starting, importing, failed }

class PlaylistsState {
  const PlaylistsState({
    this.playlists = const [],
    this.loading = true,
    this.phase = ImportPhase.none,
    this.done,
    this.total,
  });

  final List<Playlist> playlists;
  final bool loading;
  final ImportPhase phase;
  final int? done;
  final int? total;

  /// Determinate progress (0..1) while importing with a known total; null =
  /// indeterminate (starting) or no bar.
  double? get progress =>
      (phase == ImportPhase.importing && (total ?? 0) > 0) ? (done ?? 0) / total! : null;

  bool get barVisible =>
      phase == ImportPhase.starting || phase == ImportPhase.importing;

  PlaylistsState copyWith({
    List<Playlist>? playlists,
    bool? loading,
    ImportPhase? phase,
    Object? done = _s,
    Object? total = _s,
  }) {
    return PlaylistsState(
      playlists: playlists ?? this.playlists,
      loading: loading ?? this.loading,
      phase: phase ?? this.phase,
      done: done == _s ? this.done : done as int?,
      total: total == _s ? this.total : total as int?,
    );
  }

  static const _s = Object();
}

class PlaylistsController extends StateNotifier<PlaylistsState> {
  PlaylistsController(this._repo, this._storage) : super(const PlaylistsState()) {
    _init();
  }

  final PlaylistsRepository _repo;
  final FlutterSecureStorage _storage;
  static const _kTask = 'langup_playlist_import';
  static const _pollEvery = Duration(seconds: 2);
  static const _pollLimit = Duration(minutes: 30);

  Future<void> _init() async {
    await load();
    // Resume a poll that was running when the app was last closed.
    final saved = await _storage.read(key: _kTask);
    if (saved != null && saved.isNotEmpty) {
      state = state.copyWith(phase: ImportPhase.importing);
      _poll(saved);
    }
  }

  Future<void> load() async {
    try {
      final items = await _repo.list();
      state = state.copyWith(playlists: items, loading: false);
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  /// Returns false if the url was empty. Errors surface via [onImportError].
  Future<void> import(String url) async {
    if (url.trim().isEmpty) return;
    state = state.copyWith(phase: ImportPhase.starting);
    try {
      final taskId = await _repo.import(url.trim());
      if (taskId != null && taskId.isNotEmpty) {
        await _storage.write(key: _kTask, value: taskId);
        state = state.copyWith(phase: ImportPhase.importing);
        _poll(taskId);
      } else {
        // Ran inline — nothing to poll.
        state = state.copyWith(phase: ImportPhase.none);
        await load();
      }
    } catch (_) {
      state = state.copyWith(phase: ImportPhase.failed);
    }
  }

  Future<void> _poll(String taskId) async {
    final until = DateTime.now().add(_pollLimit);
    while (mounted && DateTime.now().isBefore(until)) {
      await Future.delayed(_pollEvery);
      if (!mounted) return;
      final ImportStatus s;
      try {
        s = await _repo.importStatus(taskId);
      } catch (_) {
        // A 401 or network drop — stop polling rather than spin for 30 minutes.
        state = state.copyWith(phase: ImportPhase.none);
        return;
      }
      if (s.status == 'running' || s.status == 'pending') {
        state = state.copyWith(
            phase: ImportPhase.importing, done: s.done, total: s.total);
      } else if (s.status == 'done') {
        await _storage.delete(key: _kTask);
        state = state.copyWith(phase: ImportPhase.none, done: null, total: null);
        await load();
        return;
      } else if (s.status == 'failed') {
        await _storage.delete(key: _kTask);
        state = state.copyWith(phase: ImportPhase.failed);
        return;
      }
    }
    // Timed out — hide the bar.
    if (mounted) state = state.copyWith(phase: ImportPhase.none);
  }

  Future<bool> delete(String uuid) async {
    try {
      await _repo.delete(uuid);
      state = state.copyWith(
          playlists: state.playlists.where((p) => p.uuid != uuid).toList());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> refresh() => load();
}

final playlistsRepositoryProvider = Provider<PlaylistsRepository>((ref) {
  return PlaylistsRepository(ref.watch(apiClientProvider));
});

final playlistsControllerProvider =
    StateNotifierProvider<PlaylistsController, PlaylistsState>((ref) {
  return PlaylistsController(
      ref.watch(playlistsRepositoryProvider), const FlutterSecureStorage());
});
