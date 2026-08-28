import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/languages.dart';
import '../../core/models/playlist.dart';
import 'playlists_controller.dart';

final _detailProvider =
    FutureProvider.family.autoDispose<PlaylistDetail, String>((ref, uuid) {
  return ref.watch(playlistsRepositoryProvider).detail(uuid);
});

/// Screen 2 — the songs of one playlist, searchable by title.
class PlaylistSongsScreen extends ConsumerStatefulWidget {
  const PlaylistSongsScreen({super.key, required this.uuid, required this.name});

  final String uuid;
  final String name;

  @override
  ConsumerState<PlaylistSongsScreen> createState() =>
      _PlaylistSongsScreenState();
}

class _PlaylistSongsScreenState extends ConsumerState<PlaylistSongsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(_detailProvider(widget.uuid));

    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(t('playlist.fetch_fail')),
          ),
        ),
        data: (d) {
          final songs = _query.isEmpty
              ? d.songs
              : d.songs
                  .where((s) => s.title.toLowerCase().contains(_query.toLowerCase()))
                  .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: t('playlist.song_search_ph'),
                    isDense: true,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              Expanded(
                child: songs.isEmpty
                    ? Center(
                        child: Text(t('playlist.no_songs'),
                            style:
                                TextStyle(color: Theme.of(context).disabledColor)))
                    : ListView.separated(
                        itemCount: songs.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) => _SongTile(song: songs[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  const _SongTile({required this.song});
  final PlaylistSong song;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Row(
        children: [
          Flexible(
            child: Text(song.artist,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (song.language != null) ...[
            const SizedBox(width: 8),
            _Badge(languageName(song.language)),
          ],
        ],
      ),
      trailing: song.unknownCount != null
          ? Text(t('playlist.new_words', {'n': song.unknownCount}),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600))
          : null,
      onTap: () => context.push('/lyrics',
          extra: {'title': song.title, 'artist': song.artist}),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
