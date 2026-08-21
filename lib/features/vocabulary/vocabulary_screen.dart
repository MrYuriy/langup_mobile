import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/languages.dart';
import '../../core/mastery.dart';
import '../../core/models/user_word.dart';
import 'add_word_sheet.dart';
import 'vocabulary_controller.dart';

class VocabularyScreen extends ConsumerStatefulWidget {
  const VocabularyScreen({super.key});

  @override
  ConsumerState<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends ConsumerState<VocabularyScreen> {
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      ref.read(vocabularyControllerProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(vocabularyControllerProvider.notifier).search(value.trim());
    });
  }

  Future<void> _openAdd() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddWordSheet(),
    );
    if (added == true) {
      ref.read(vocabularyControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vocabularyControllerProvider);
    final ctrl = ref.read(vocabularyControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My words'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search words…',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: state.query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              ctrl.search('');
                            },
                          ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (state.languages.length > 1)
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _LangChip(
                        label: 'All',
                        selected: state.selectedLanguage == null,
                        onTap: () => ctrl.selectLanguage(null),
                      ),
                      for (final l in state.languages)
                        _LangChip(
                          label: '${languageName(l.language)} (${l.count})',
                          selected: state.selectedLanguage == l.language,
                          onTap: () => ctrl.selectLanguage(l.language),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add word'),
      ),
      body: RefreshIndicator(
        onRefresh: ctrl.refresh,
        child: _body(state, ctrl),
      ),
    );
  }

  Widget _body(VocabularyState state, VocabularyController ctrl) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return _Message(icon: Icons.error_outline, text: state.error!);
    }
    if (state.words.isEmpty) {
      return _Message(
        icon: Icons.menu_book_outlined,
        text: state.query.isNotEmpty
            ? 'No words match "${state.query}".'
            : 'No words yet. Tap “Add word”, or save words from the browser extension.',
      );
    }

    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: state.words.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        if (i >= state.words.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _WordTile(
          word: state.words[i],
          onDelete: () => _confirmDelete(state.words[i], ctrl),
          onTap: () => context.push('/vocabulary/${state.words[i].uuid}'),
        );
      },
    );
  }

  Future<void> _confirmDelete(UserWord word, VocabularyController ctrl) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove “${word.lemma}”?'),
        content: const Text(
            'It leaves your dictionary. The shared entry stays for other users.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    final removed = await ctrl.remove(word.uuid);
    if (!removed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove the word.')),
      );
    }
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({required this.word, required this.onTap, required this.onDelete});
  final UserWord word;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = Mastery.color(word.masteryLevel);
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Text(word.language.toUpperCase(),
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
      ),
      title: Text(word.lemma, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text([
        if (word.partOfSpeech != null) word.partOfSpeech!.toLowerCase(),
        Mastery.label(word.masteryLevel),
      ].join(' · ')),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    // Wrapped in a scroll view so RefreshIndicator still works when empty.
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 48, color: Theme.of(context).disabledColor),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(text, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
