import 'package:flutter/material.dart';

/// Presentation for the backend `MasteryLevel` enum
/// (NEW | LEARNING | REVIEW | MASTERED).
class Mastery {
  static const order = ['NEW', 'LEARNING', 'REVIEW', 'MASTERED'];

  static String label(String level) {
    switch (level) {
      case 'NEW':
        return 'New';
      case 'LEARNING':
        return 'Learning';
      case 'REVIEW':
        return 'Review';
      case 'MASTERED':
        return 'Mastered';
      default:
        return level;
    }
  }

  static Color color(String level) {
    switch (level) {
      case 'NEW':
        return const Color(0xFF868E96);
      case 'LEARNING':
        return const Color(0xFFF08C00);
      case 'REVIEW':
        return const Color(0xFF1971C2);
      case 'MASTERED':
        return const Color(0xFF2F9E44);
      default:
        return const Color(0xFF868E96);
    }
  }
}
