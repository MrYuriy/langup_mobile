import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The 8 interface languages (same set the web cabinet ships). English is the
/// fallback for any missing key, so a half-translated locale degrades to English
/// instead of showing raw keys.
const kUiSupported = ['uk', 'pl', 'en', 'de', 'es', 'fr', 'it', 'pt'];
const kUiFallback = 'en';
const _kUiLangKey = 'langup_ui_lang';

/// Flat-map i18n, mirroring the web `i18n.js`: `assets/i18n/<lang>.json` holds
/// `{ key: "text" }` with `{name}` placeholders.
class I18n {
  I18n._();
  static final I18n instance = I18n._();

  Map<String, String> _active = {};
  Map<String, String> _fallback = {};
  String lang = kUiFallback;

  Future<Map<String, String>> _read(String l) async {
    try {
      final raw = await rootBundle.loadString('assets/i18n/$l.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> load(String l) async {
    _fallback = await _read(kUiFallback);
    _active = l == kUiFallback ? _fallback : await _read(l);
    lang = l;
  }

  String t(String key, [Map<String, Object?>? params]) {
    var s = _active[key] ?? _fallback[key] ?? key;
    if (params != null) {
      params.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    }
    return s;
  }

  /// Which language to start in: a saved choice, else the device language if we
  /// support it, else English.
  static String resolveInitial(String? saved) {
    if (saved != null && kUiSupported.contains(saved)) return saved;
    final device = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return kUiSupported.contains(device) ? device : kUiFallback;
  }
}

/// Global shorthand — usable from any widget, Consumer or not. The whole tree
/// rebuilds on a language change because MaterialApp watches [localeProvider].
String t(String key, [Map<String, Object?>? params]) =>
    I18n.instance.t(key, params);

/// Localised mastery label ("NEW" -> t("mastery.new")).
String masteryLabel(String level) => t('mastery.${level.toLowerCase()}');

class LocaleController extends StateNotifier<String> {
  LocaleController([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage(),
        super(I18n.instance.lang);

  final FlutterSecureStorage _storage;

  Future<void> setLang(String l) async {
    if (!kUiSupported.contains(l) || l == state) return;
    await I18n.instance.load(l);
    await _storage.write(key: _kUiLangKey, value: l);
    state = l;
  }

  /// Align the UI language with the account's native language — but only if the
  /// user has never picked one manually (that choice always wins). Mirrors the
  /// web `syncUiLangToNative`.
  Future<void> syncToNative(String? nativeLanguage) async {
    final saved = await _storage.read(key: _kUiLangKey);
    if (saved != null) return;
    if (nativeLanguage != null && kUiSupported.contains(nativeLanguage)) {
      await setLang(nativeLanguage);
    }
  }
}

final localeProvider =
    StateNotifierProvider<LocaleController, String>((ref) => LocaleController());
