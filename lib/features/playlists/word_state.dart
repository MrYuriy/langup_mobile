import 'package:flutter/material.dart';

/// Colours for lyric word states, matching the web reader.
class WordState {
  static const known = Color(0xFF2F9E44); // green
  static const learning = Color(0xFFF59F00); // amber
  static const unknown = Color(0xFFE8590C); // orange-red

  static Color? forStatus(String status, Color bodyColor) {
    switch (status) {
      case 'known':
        return known;
      case 'learning':
        return learning;
      case 'unknown':
        return unknown;
      default:
        return bodyColor; // skip — plain body colour
    }
  }
}
