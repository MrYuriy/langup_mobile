import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/languages.dart';
import '../../core/providers.dart';

/// A brand-new account must pick a native language before entering the cabinet
/// (mirrors the web `showLangGate`). The extension then never needs to ask.
class LanguageGateScreen extends ConsumerStatefulWidget {
  const LanguageGateScreen({super.key});

  @override
  ConsumerState<LanguageGateScreen> createState() => _LanguageGateScreenState();
}

class _LanguageGateScreenState extends ConsumerState<LanguageGateScreen> {
  String? _selected;
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    if (_selected == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).setNativeLanguage(_selected!);
    } catch (_) {
      setState(() => _error = t('toast.lang_save_fail'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('native.title'))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t('native.which'),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(t('native.subtitle')),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  initialValue: _selected,
                  decoration: InputDecoration(
                    labelText: t('settings.i_speak'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final l in kLanguages)
                      DropdownMenuItem(value: l.code, child: Text(l.name)),
                  ],
                  onChanged: _busy ? null : (v) => setState(() => _selected = v),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(_error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: (_busy || _selected == null) ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(t('common.continue')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
