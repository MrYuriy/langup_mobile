/// A word due for spaced-repetition review — matches `DueWordOut`.
class DueWord {
  const DueWord({
    required this.uuid,
    required this.lemma,
    required this.language,
    required this.masteryLevel,
    required this.translation,
  });

  final String uuid;
  final String lemma;
  final String language;
  final String masteryLevel;
  final String? translation;

  factory DueWord.fromJson(Map<String, dynamic> json) => DueWord(
        uuid: json['uuid'] as String,
        lemma: json['lemma'] as String,
        language: json['language'] as String,
        masteryLevel: json['mastery_level'] as String,
        translation: json['translation'] as String?,
      );
}
