import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/models/playlist.dart';
import '../audio/speak_button.dart';
import 'playlists_controller.dart';
import 'word_state.dart';

/// Screen 3 — the song's lyrics, every word coloured by the learner's state.
/// Tapping an unknown (red) word translates it in context and offers to add it.
class LyricsReaderScreen extends ConsumerStatefulWidget {
  const LyricsReaderScreen({super.key, required this.title, required this.artist});

  final String title;
  final String artist;

  @override
  ConsumerState<LyricsReaderScreen> createState() => _LyricsReaderScreenState();
}

class _LyricsReaderScreenState extends ConsumerState<LyricsReaderScreen> {
  AnalyzedLyrics? _lyrics;
  String? _error; // lyrics_not_found | language_unknown | generic
  bool _loading = true;
  final _recognizers = <LyricToken, TapGestureRecognizer>{};

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  @override
  void dispose() {
    for (final r in _recognizers.values) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _analyze() async {
    final res = await ref
        .read(playlistsRepositoryProvider)
        .analyze(widget.title, widget.artist);
    if (!mounted) return;
    if (res.lyrics != null) {
      // A recognizer per initially-unknown token — the only tappable ones.
      for (final line in res.lyrics!.lines) {
        for (final tok in line.tokens) {
          if (tok.status == 'unknown') {
            _recognizers[tok] =
                TapGestureRecognizer()..onTap = () => _onTapWord(tok, line);
          }
        }
      }
      setState(() {
        _lyrics = res.lyrics;
        _loading = false;
      });
    } else {
      setState(() {
        _error = res.error ?? 'generic';
        _loading = false;
      });
    }
  }

  void _onTapWord(LyricToken token, LyricLine line) {
    if (!token.isTappable) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => _TranslateSheet(
        surface: token.surface,
        line: line.text,
        language: _lyrics!.language,
        translate: (w, l, lang) => ref
            .read(playlistsRepositoryProvider)
            .translate(word: w, line: l, language: lang),
        onAdd: (known) => _addWord(token, known),
      ),
    );
  }

  Future<void> _addWord(LyricToken token, bool known) async {
    try {
      await ref.read(playlistsRepositoryProvider).addWord(
            lemma: token.surface,
            language: _lyrics!.language,
            known: known,
          );
    } catch (_) {
      // Even on failure the sheet closes; surfaces below via the toast path.
    }
    // Recolour every token with the same lemma (a chorus repeat included).
    final newStatus = known ? 'known' : 'learning';
    final lemma = token.lemma;
    setState(() {
      for (final line in _lyrics!.lines) {
        for (final tok in line.tokens) {
          if (tok == token || (lemma != null && tok.lemma == lemma)) {
            tok.status = newStatus;
          }
        }
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              known ? t('playlist.added_known') : t('playlist.added_learn'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(t('playlist.loading_lyrics')),
          ],
        ),
      );
    }
    if (_error != null) {
      final msg = _error == 'lyrics_not_found'
          ? t('playlist.lyrics_not_found')
          : _error == 'language_unknown'
              ? t('playlist.language_unknown')
              : t('playlist.fetch_fail');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(msg, textAlign: TextAlign.center),
        ),
      );
    }

    final bodyColor = Theme.of(context).textTheme.bodyLarge?.color ??
        Theme.of(context).colorScheme.onSurface;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(widget.artist, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        _Legend(),
        const SizedBox(height: 20),
        for (final line in _lyrics!.lines)
          if (line.tokens.isEmpty)
            const SizedBox(height: 20) // blank line keeps its space
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text.rich(
                TextSpan(children: [
                  for (final tok in line.tokens)
                    TextSpan(
                      text: tok.surface,
                      style: TextStyle(
                        color: WordState.forStatus(tok.status, bodyColor),
                        fontWeight:
                            tok.status == 'skip' ? FontWeight.normal : FontWeight.w600,
                        decoration: tok.status == 'unknown'
                            ? TextDecoration.underline
                            : null,
                        decorationStyle: TextDecorationStyle.dotted,
                      ),
                      recognizer: tok.isTappable ? _recognizers[tok] : null,
                    ),
                ]),
                style: const TextStyle(fontSize: 17, height: 2.0),
              ),
            ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        _dot(WordState.known, t('playlist.legend_known')),
        _dot(WordState.learning, t('playlist.legend_learning')),
        _dot(WordState.unknown, t('playlist.legend_unknown')),
      ],
    );
  }

  Widget _dot(Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: c, fontSize: 12)),
        ],
      );
}

/// Bottom-sheet popover: translate a tapped word, then add it as known/learning.
class _TranslateSheet extends StatefulWidget {
  const _TranslateSheet({
    required this.surface,
    required this.line,
    required this.language,
    required this.translate,
    required this.onAdd,
  });

  final String surface;
  final String line;
  final String language;
  final Future<String?> Function(String word, String line, String language) translate;
  final Future<void> Function(bool known) onAdd;

  @override
  State<_TranslateSheet> createState() => _TranslateSheetState();
}

class _TranslateSheetState extends State<_TranslateSheet> {
  String? _translation;
  bool _loading = true;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final tr = await widget.translate(widget.surface, widget.line, widget.language);
      if (mounted) {
        setState(() {
          _translation = tr;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add(bool known) async {
    setState(() => _adding = true);
    await widget.onAdd(known);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 4, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading)
            Row(children: [
              const SizedBox(
                  height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 12),
              Text(t('playlist.translating')),
            ])
          else
            Row(
              children: [
                Flexible(
                  child: Text.rich(TextSpan(children: [
                    TextSpan(
                        text: widget.surface,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: '  —  '),
                    TextSpan(text: _translation ?? '—'),
                  ], style: Theme.of(context).textTheme.titleMedium)),
                ),
                SpeakButton(text: widget.surface, language: widget.language),
              ],
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (_loading || _adding) ? null : () => _add(true),
                  child: Text(t('playlist.add_known')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: (_loading || _adding) ? null : () => _add(false),
                  child: Text(t('playlist.add_learn')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
