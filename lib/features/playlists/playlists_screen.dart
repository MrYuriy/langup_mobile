import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/models/playlist.dart';
import 'playlists_controller.dart';

/// Screen 1 — import a Spotify playlist link, watch progress, browse saved ones.
class PlaylistsScreen extends ConsumerStatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  ConsumerState<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends ConsumerState<PlaylistsScreen> {
  final _url = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final url = _url.text.trim();
    if (url.isEmpty) return;
    FocusScope.of(context).unfocus();
    await ref.read(playlistsControllerProvider.notifier).import(url);
    _url.clear();
  }

  String _statusLine(PlaylistsState s) {
    switch (s.phase) {
      case ImportPhase.starting:
        return t('playlist.importing_start');
      case ImportPhase.importing:
        return t('playlist.importing',
            {'done': s.done ?? 0, 'total': s.total ?? '…'});
      case ImportPhase.failed:
        return t('playlist.import_failed');
      case ImportPhase.none:
        return '';
    }
  }

  Future<void> _confirmDelete(Playlist p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(t('playlist.delete_confirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t('common.cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t('common.remove'))),
        ],
      ),
    );
    if (ok != true) return;
    final done = await ref.read(playlistsControllerProvider.notifier).delete(p.uuid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(done ? t('playlist.deleted') : t('playlist.fetch_fail'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playlistsControllerProvider);
    final ctrl = ref.read(playlistsControllerProvider.notifier);
    final importing = state.phase == ImportPhase.starting ||
        state.phase == ImportPhase.importing;

    return Scaffold(
      appBar: AppBar(title: Text(t('nav.songs'))),
      body: RefreshIndicator(
        onRefresh: ctrl.refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(t('playlist.title'),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(t('playlist.subtitle'),
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _url,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: t('playlist.url_ph'),
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _import(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: importing ? null : _import,
                  child: Text(t('playlist.import')),
                ),
              ],
            ),
            if (state.barVisible) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: state.progress),
            ],
            if (_statusLine(state).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_statusLine(state),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 24),
            Text(t('playlist.my_playlists'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (state.loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.playlists.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(t('playlist.empty_playlists'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).disabledColor)),
              )
            else
              for (final p in state.playlists)
                _PlaylistTile(
                  playlist: p,
                  onTap: () => context.push('/playlists/${p.uuid}',
                      extra: p.name ?? t('nav.songs')),
                  onDelete: () => _confirmDelete(p),
                ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile(
      {required this.playlist, required this.onTap, required this.onDelete});
  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = t('playlist.status_${playlist.status}');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.queue_music),
        title: Text(playlist.name ?? '—',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${playlist.songCount} · $status'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
