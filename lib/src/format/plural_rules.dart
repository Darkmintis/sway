/// CLDR plural category resolution per locale.
///
/// Reference: https://www.unicode.org/cldr/charts/latest/supplemental/language_plural_rules.html
library;

/// CLDR plural categories.
enum PluralCategory {
  /// Zero items.
  zero,

  /// One item.
  one,

  /// Two items.
  two,

  /// Few items (3-10 in some languages).
  few,

  /// Many items (11-99 in some languages).
  many,

  /// Default/other category (mandatory for all plural keys).
  other,
}

/// Returns the plural categories supported by [languageCode].
///
/// For example, English (`en`) supports `one` and `other`.
/// Arabic (`ar`) supports all six categories.
Set<PluralCategory> supportedCategories(String languageCode) {
  return _categories[languageCode.toLowerCase()] ?? {PluralCategory.one, PluralCategory.other};
}

/// Resolves which plural category applies for a given [count] in [languageCode].
PluralCategory resolvePlural(String languageCode, num count) {
  final categories = supportedCategories(languageCode);
  final rules = _getRuleFunction(languageCode);
  final resolved = rules(count);

  // Return the resolved category if it's supported, otherwise fall back to other.
  if (categories.contains(resolved)) return resolved;
  return PluralCategory.other;
}

/// Returns the set of CLDR plural categories defined for each language.
const Map<String, Set<PluralCategory>> _categories = {
  'en': {PluralCategory.one, PluralCategory.other},
  'fr': {PluralCategory.one, PluralCategory.other},
  'de': {PluralCategory.one, PluralCategory.other},
  'es': {PluralCategory.one, PluralCategory.other},
  'it': {PluralCategory.one, PluralCategory.other},
  'pt': {PluralCategory.one, PluralCategory.other},
  'ru': {PluralCategory.one, PluralCategory.few, PluralCategory.many, PluralCategory.other},
  'pl': {PluralCategory.one, PluralCategory.few, PluralCategory.many, PluralCategory.other},
  'ar': {
    PluralCategory.zero,
    PluralCategory.one,
    PluralCategory.two,
    PluralCategory.few,
    PluralCategory.many,
    PluralCategory.other,
  },
  'he': {PluralCategory.one, PluralCategory.two, PluralCategory.other},
  'fa': {PluralCategory.one, PluralCategory.other},
  'ur': {PluralCategory.one, PluralCategory.other},
  'zh': {PluralCategory.other},
  'ja': {PluralCategory.other},
  'ko': {PluralCategory.other},
  'hi': {PluralCategory.one, PluralCategory.other},
  'tr': {PluralCategory.one, PluralCategory.other},
  'nl': {PluralCategory.one, PluralCategory.other},
  'sv': {PluralCategory.one, PluralCategory.other},
  'da': {PluralCategory.one, PluralCategory.other},
  'no': {PluralCategory.one, PluralCategory.other},
  'fi': {PluralCategory.one, PluralCategory.other},
  'el': {PluralCategory.one, PluralCategory.other},
  'th': {PluralCategory.other},
  'vi': {PluralCategory.other},
  'id': {PluralCategory.other},
};

/// Returns a function that resolves a [num] to a [PluralCategory] based on
/// locale-specific CLDR rules.
PluralCategory Function(num) _getRuleFunction(String languageCode) {
  final code = languageCode.toLowerCase();
  if (code == 'ar') return _arabicPluralRule;
  if (code == 'he') return _hebrewPluralRule;
  if (code == 'ru' || code == 'uk' || code == 'be' || code == 'hr' || code == 'sr' || code == 'bs') {
    return _slavicPluralRule;
  }
  if (code == 'pl') return _polishPluralRule;
  return _defaultPluralRule;
}

PluralCategory _defaultPluralRule(num count) {
  if (count == 1) return PluralCategory.one;
  return PluralCategory.other;
}

PluralCategory _arabicPluralRule(num count) {
  if (count == 0) return PluralCategory.zero;
  if (count == 1) return PluralCategory.one;
  if (count == 2) return PluralCategory.two;
  final int mod100 = count.toInt() % 100;
  if (mod100 >= 3 && mod100 <= 10) return PluralCategory.few;
  // CLDR: many for 11-99 OR exact multiples of 100 (100, 200, ...)
  if (mod100 >= 11 || (mod100 == 0 && count >= 100)) return PluralCategory.many;
  return PluralCategory.other;
}

PluralCategory _hebrewPluralRule(num count) {
  if (count == 1) return PluralCategory.one;
  if (count == 2) return PluralCategory.two;
  return PluralCategory.other;
}

PluralCategory _slavicPluralRule(num count) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod10 == 1 && mod100 != 11) return PluralCategory.one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return PluralCategory.few;
  }
  if (mod10 == 0 || (mod10 >= 5 && mod10 <= 9) || (mod100 >= 11 && mod100 <= 14)) {
    return PluralCategory.many;
  }
  return PluralCategory.other;
}

PluralCategory _polishPluralRule(num count) {
  if (count == 1) return PluralCategory.one;
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return PluralCategory.few;
  }
  if (mod10 >= 0 && mod10 <= 1 || (mod10 >= 5 && mod10 <= 9) || (mod100 >= 12 && mod100 <= 14)) {
    return PluralCategory.many;
  }
  return PluralCategory.other;
}
