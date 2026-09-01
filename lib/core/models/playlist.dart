/// A saved playlist row — matches `PlaylistOut`.
class Playlist {
  const Playlist({
    required this.uuid,
    required this.name,
    required this.status,
    required this.songCount,
  });

  final String uuid;
  final String? name;
  final String status; // pending | parsing | ready | failed
  final int songCount;

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        uuid: json['uuid'] as String,
        name: json['name'] as String?,
        status: json['status'] as String,
        songCount: json['song_count'] as int? ?? 0,
      );
}

/// One song within a playlist — matches `PlaylistSongOut`.
class PlaylistSong {
  const PlaylistSong({
    required this.songUuid,
    required this.title,
    required this.artist,
    required this.language,
    required this.unknownCount,
    required this.inLearnedLanguage,
  });

  final String songUuid;
  final String title;
  final String artist;
  final String? language;
  final int? unknownCount;
  final bool inLearnedLanguage;

  factory PlaylistSong.fromJson(Map<String, dynamic> json) => PlaylistSong(
        songUuid: json['song_uuid'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String? ?? '',
        language: json['language'] as String?,
        unknownCount: json['unknown_count'] as int?,
        inLearnedLanguage: json['in_learned_language'] as bool? ?? false,
      );
}

/// A playlist with its songs — matches `PlaylistDetailOut`.
class PlaylistDetail {
  const PlaylistDetail({
    required this.uuid,
    required this.name,
    required this.status,
    required this.songs,
  });

  final String uuid;
  final String? name;
  final String status;
  final List<PlaylistSong> songs;

  factory PlaylistDetail.fromJson(Map<String, dynamic> json) => PlaylistDetail(
        uuid: json['uuid'] as String,
        name: json['name'] as String?,
        status: json['status'] as String,
        songs: [
          for (final s in (json['songs'] as List? ?? []))
            PlaylistSong.fromJson((s as Map).cast<String, dynamic>()),
        ],
      );
}

/// Progress of a running import — matches `PlaylistImportStatus`.
class ImportStatus {
  const ImportStatus({
    required this.status,
    required this.done,
    required this.total,
    required this.playlistUuid,
  });

  final String status; // pending | running | done | failed
  final int? done;
  final int? total;
  final String? playlistUuid;

  factory ImportStatus.fromJson(Map<String, dynamic> json) => ImportStatus(
        status: json['status'] as String,
        done: json['done'] as int?,
        total: json['total'] as int?,
        playlistUuid: json['playlist_uuid'] as String?,
      );
}

/// One chunk of a lyric line — matches `AnalyzedToken`.
///
/// status:
///   known    -> mastered (green)
///   learning -> in the vocabulary, not mastered yet (amber)
///   unknown  -> a word they don't have yet (red)
///   common   -> too frequent to flag, but still a word: drawn plain so the page
///               is not a wall of red, yet offered like an unknown one
///   skip     -> punctuation, whitespace, interjections, articles — inert
class LyricToken {
  LyricToken({required this.surface, required this.lemma, required this.status});

  final String surface;
  final String? lemma;
  String status; // mutable: recoloured after a word is added

  /// Everything except punctuation responds to a tap, so the interaction is the
  /// same everywhere rather than only red words answering.
  bool get isTappable => status != 'skip';

  /// Words not yet in the dictionary open translate-then-keep-or-learn; the ones
  /// already saved only offer playback.
  bool get offersTranslation => status == 'unknown' || status == 'common';

  factory LyricToken.fromJson(Map<String, dynamic> json) => LyricToken(
        surface: json['surface'] as String? ?? '',
        lemma: json['lemma'] as String?,
        status: json['status'] as String? ?? 'skip',
      );
}

class LyricLine {
  LyricLine(this.tokens);
  final List<LyricToken> tokens;

  /// The original line text, tokens concatenated (used as translation context).
  String get text => tokens.map((t) => t.surface).join();

  factory LyricLine.fromJson(Map<String, dynamic> json) => LyricLine([
        for (final t in (json['tokens'] as List? ?? []))
          LyricToken.fromJson((t as Map).cast<String, dynamic>()),
      ]);
}

/// Analysed lyrics — matches `AnalyzedLyrics`.
class AnalyzedLyrics {
  AnalyzedLyrics({required this.language, required this.lines});

  final String language;
  final List<LyricLine> lines;

  factory AnalyzedLyrics.fromJson(Map<String, dynamic> json) => AnalyzedLyrics(
        language: json['language'] as String,
        lines: [
          for (final l in (json['lines'] as List? ?? []))
            LyricLine.fromJson((l as Map).cast<String, dynamic>()),
        ],
      );
}
