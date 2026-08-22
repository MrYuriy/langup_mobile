import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _seed = Color(0xFF6C5CFF); // LangUp purple (matches the app icon)

ThemeData buildTheme(Brightness brightness) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: brightness),
    useMaterial3: true,
  );
}

/// The user's theme choice, persisted across launches. Defaults to following the
/// system until the user picks Light or Dark explicitly.
class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage(),
        super(ThemeMode.system) {
    _load();
  }

  final FlutterSecureStorage _storage;
  static const _key = 'langup_theme_mode';

  Future<void> _load() async {
    final saved = await _storage.read(key: _key);
    if (saved != null) state = _parse(saved);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _storage.write(key: _key, value: mode.name);
  }

  static ThemeMode _parse(String s) => ThemeMode.values.firstWhere(
        (m) => m.name == s,
        orElse: () => ThemeMode.system,
      );
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController();
});
