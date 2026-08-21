import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/languages.dart';
import '../../core/providers.dart';
import 'vocabulary_controller.dart';
import 'vocabulary_repository.dart';

/// Manual word capture — the mobile counterpart of the browser extension's "+".
class AddWordSheet extends ConsumerStatefulWidget {
  const AddWordSheet({super.key});

  @override
  ConsumerState<AddWordSheet> createState() => _AddWordSheetState();
}

class _AddWordSheetState extends ConsumerState<AddWordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _word = TextEditingController();
  final _sentence = TextEditingController();
  String? _language;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Default to the language the user is studying, when known.
    final user = ref.read(authControllerProvider).user;
    _language = user?.targetLanguage ?? user?.nativeLanguage;
    if (_language != null && !kLanguages.any((l) => l.code == _language)) {
      _language = null;
    }
  }

  @override
  void dispose() {
    _word.dispose();
    _sentence.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _language == null) {
      if (_language == null) setState(() => _error = 'Pick a language.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(vocabularyRepositoryProvider).capture(
            word: _word.text.trim(),
            language: _language!,
            sentence: _sentence.text.trim(),
          );
      if (mounted) Navigator.pop(context, true);
    } on VocabularyException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not add the word. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add a word', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _word,
              autofocus: true,
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(
                labelText: 'Word',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a word' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _language,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final l in kLanguages)
                  DropdownMenuItem(value: l.code, child: Text(l.name)),
              ],
              onChanged: _busy ? null : (v) => setState(() => _language = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sentence,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Sentence (optional)',
                helperText: 'Context helps generate better exercises.',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save word'),
            ),
          ],
        ),
      ),
    );
  }
}
