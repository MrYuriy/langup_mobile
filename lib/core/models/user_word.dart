/// One entry of the user's personal vocabulary — matches `UserWordOut`.
class UserWord {
  const UserWord({
    required this.uuid,
    required this.wordUuid,
    required this.lemma,
    required this.language,
    required this.partOfSpeech,
    required this.masteryLevel,
    required this.createdAt,
  });

  final String uuid;
  final String wordUuid;
  final String lemma;
  final String language;
  final String? partOfSpeech;
  final String masteryLevel; // NEW | LEARNING | REVIEW | MASTERED
  final DateTime createdAt;

  factory UserWord.fromJson(Map<String, dynamic> json) => UserWord(
        uuid: json['uuid'] as String,
        wordUuid: json['word_uuid'] as String,
        lemma: json['lemma'] as String,
        language: json['language'] as String,
        partOfSpeech: json['part_of_speech'] as String?,
        masteryLevel: json['mastery_level'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// One sentence the word was captured in — matches `WordContextOut`.
class WordContext {
  const WordContext({
    required this.sentence,
    required this.surfaceForm,
    required this.createdAt,
  });

  final String sentence;
  final String? surfaceForm;
  final DateTime createdAt;

  factory WordContext.fromJson(Map<String, dynamic> json) => WordContext(
        sentence: json['sentence'] as String,
        surfaceForm: json['surface_form'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// Full detail of a personal vocabulary entry — matches `UserWordDetailOut`.
class UserWordDetail {
  const UserWordDetail({
    required this.uuid,
    required this.lemma,
    required this.language,
    required this.partOfSpeech,
    required this.masteryLevel,
    required this.translation,
    required this.contexts,
  });

  final String uuid;
  final String lemma;
  final String language;
  final String? partOfSpeech;
  final String masteryLevel;
  final String? translation;
  final List<WordContext> contexts;

  factory UserWordDetail.fromJson(Map<String, dynamic> json) => UserWordDetail(
        uuid: json['uuid'] as String,
        lemma: json['lemma'] as String,
        language: json['language'] as String,
        partOfSpeech: json['part_of_speech'] as String?,
        masteryLevel: json['mastery_level'] as String,
        translation: json['translation'] as String?,
        contexts: [
          for (final c in (json['contexts'] as List? ?? []))
            WordContext.fromJson((c as Map).cast<String, dynamic>()),
        ],
      );
}

/// One language the user is learning, with its word count — `LanguageCountOut`.
class LanguageCount {
  const LanguageCount({required this.language, required this.count});
  final String language;
  final int count;

  factory LanguageCount.fromJson(Map<String, dynamic> json) => LanguageCount(
        language: json['language'] as String,
        count: json['count'] as int,
      );
}
