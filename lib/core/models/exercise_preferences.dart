/// Matches the backend `ExercisePreferences` schema
/// (`GET`/`PUT /exercises/preferences`).
class ExercisePreferences {
  const ExercisePreferences({
    required this.exerciseTypes,
    required this.matchPairsFillers,
  });

  /// Enabled exercise-type names (e.g. "FILL_IN_BLANKS"). Required, non-empty —
  /// a PUT must echo them back, so we keep them even though the UI only toggles
  /// the filler flag today.
  final List<String> exerciseTypes;

  /// Top a match-pairs round up with random shared-dictionary words when the
  /// learner's own vocabulary can't fill the board.
  final bool matchPairsFillers;

  ExercisePreferences copyWith({bool? matchPairsFillers}) => ExercisePreferences(
        exerciseTypes: exerciseTypes,
        matchPairsFillers: matchPairsFillers ?? this.matchPairsFillers,
      );

  factory ExercisePreferences.fromJson(Map<String, dynamic> json) =>
      ExercisePreferences(
        exerciseTypes: [
          for (final t in (json['exercise_types'] as List? ?? [])) t.toString(),
        ],
        matchPairsFillers: json['match_pairs_fillers'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'exercise_types': exerciseTypes,
        'match_pairs_fillers': matchPairsFillers,
      };
}
