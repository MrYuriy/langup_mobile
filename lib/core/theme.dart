import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _seed = Color(0xFF6C5CFF); // LangUp purple (matches the app icon)

ThemeData buildTheme(Brightness brightness) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: brightness),
    useMaterial3: true,
    // Bundled font — consistent typography (and typing-blank width) on any device.
    fontFamily: 'Poppins',
    // Six destinations share the width: on a 360dp phone — the narrowest common
    // one, and what a browser reports even on a wider device, since Chrome
    // quantises the pixel ratio — that leaves about 52dp per label.
    //
    // Measured against that, the default 12dp overflows eight of the 48 labels
    // across our languages; 10dp overflows three, which are then shortened in
    // the locale files. Below 10dp the bar reads as fine print for the sake of
    // one French phrase.
    //
    // The bar's own height is deliberately left alone: Material sized it for
    // two lines, so a label that still wraps wraps cleanly instead of clipping.
    navigationBarTheme: NavigationBarThemeData(
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 10,
          height: 1.2,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    ),
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
