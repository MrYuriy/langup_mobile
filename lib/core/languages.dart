/// One curated language list, shared by every picker — mirrors `LANGUAGES` in
/// the web cabinet's `api.js`. These are the languages the AI model handles
/// well (Russian intentionally excluded).
class Language {
  const Language(this.code, this.name);
  final String code;
  final String name;
}

const kLanguages = <Language>[
  Language('uk', 'Ukrainian'),
  Language('pl', 'Polish'),
  Language('en', 'English'),
  Language('de', 'German'),
  Language('es', 'Spanish'),
  Language('fr', 'French'),
  Language('it', 'Italian'),
  Language('pt', 'Portuguese'),
];

String languageName(String? code) {
  if (code == null || code.isEmpty) return '—';
  for (final l in kLanguages) {
    if (l.code == code) return l.name;
  }
  return code;
}
