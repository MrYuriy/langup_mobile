/// Supported exercise types (backend `SUPPORTED_EXERCISE_TYPES`) with the short
/// labels the web practice UI uses.
class ExerciseTypes {
  static const labels = <String, String>{
    'FILL_IN_BLANKS': 'Blanks',
    'MULTIPLE_CHOICE': 'Meaning',
    'FLASHCARD': 'Flashcards',
    'MATCH_PAIRS': 'Pairs',
    'TYPING': 'Type',
  };

  /// The instruction shown above each exercise (mirrors web `promptText`).
  static String prompt(String type) {
    switch (type) {
      case 'FILL_IN_BLANKS':
        return 'Fill in the blanks with the correct word.';
      case 'MULTIPLE_CHOICE':
        return 'Choose the correct meaning of the word.';
      case 'FLASHCARD':
        return 'Do you remember this word?';
      case 'MATCH_PAIRS':
        return 'Match the word with its translation.';
      case 'TYPING':
        return 'Type the missing word.';
      default:
        return '';
    }
  }
}

/// One exercise served from the pool — matches `ExerciseOut`. The answer key is
/// never included; `payload` shape depends on `exerciseType`.
class Exercise {
  const Exercise({
    required this.uuid,
    required this.exerciseType,
    required this.prompt,
    required this.difficulty,
    required this.payload,
    required this.language,
  });

  final String uuid;
  final String exerciseType;
  final String? prompt;
  final double? difficulty;
  final Map<String, dynamic> payload;

  /// The language being practised — needed to speak the exercise aloud. The
  /// client's own language filter can be unset (the server then picks), so the
  /// exercise carries its own.
  final String? language;

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        uuid: json['uuid'] as String,
        exerciseType: json['exercise_type'] as String,
        prompt: json['prompt'] as String?,
        difficulty: (json['difficulty'] as num?)?.toDouble(),
        payload: (json['payload'] as Map).cast<String, dynamic>(),
        language: json['language'] as String?,
      );
}

/// The answer a widget submits for grading.
class ExerciseAnswer {
  const ExerciseAnswer(this.answers, {this.mistakes, this.timedOut = false});
  final Map<String, String> answers;
  final int? mistakes; // match-pairs only
  final bool timedOut; // match-pairs only
}

/// Result of grading an attempt — matches `AttemptResultOut`.
class AttemptResult {
  const AttemptResult({
    required this.isCorrect,
    required this.correctAnswers,
    required this.masteryLevel,
  });

  final bool isCorrect;
  final Map<String, String> correctAnswers;
  final String? masteryLevel;

  factory AttemptResult.fromJson(Map<String, dynamic> json) => AttemptResult(
        isCorrect: json['is_correct'] as bool,
        correctAnswers: {
          for (final e in (json['correct_answers'] as Map? ?? {}).entries)
            e.key.toString(): e.value.toString(),
        },
        masteryLevel: json['mastery_level'] as String?,
      );
}

/// Daily AI-generation quota — matches `GenerationQuotaOut`.
class GenerationQuota {
  const GenerationQuota({
    required this.unlimited,
    required this.used,
    required this.limit,
    required this.remaining,
  });

  final bool unlimited;
  final int used;
  final int? limit;
  final int? remaining;

  factory GenerationQuota.fromJson(Map<String, dynamic> json) =>
      GenerationQuota(
        unlimited: json['unlimited'] as bool,
        used: json['used'] as int? ?? 0,
        limit: json['limit'] as int?,
        remaining: json['remaining'] as int?,
      );
}
