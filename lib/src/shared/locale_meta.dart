/// Locale metadata for Sway's internal use.
library;

/// Metadata about a locale used by the overlay and codegen.
class SwayLocaleMeta {
  /// The language code (e.g. `en`, `ar`, `pt_BR`).
  final String languageCode;

  /// Whether this locale is RTL.
  final bool isRtl;

  /// Human-readable display name for the locale.
  final String displayName;

  /// Creates a [SwayLocaleMeta].
  const SwayLocaleMeta({
    required this.languageCode,
    required this.isRtl,
    required this.displayName,
  });

  /// Creates metadata from a language code, auto-detecting RTL.
  factory SwayLocaleMeta.fromLanguageCode(
    String languageCode, {
    String? displayName,
  }) {
    return SwayLocaleMeta(
      languageCode: languageCode,
      isRtl: _isRtl(languageCode),
      displayName: displayName ?? _defaultDisplayName(languageCode),
    );
  }

  static bool _isRtl(String code) {
    const rtlCodes = {'ar', 'he', 'fa', 'ur', 'ps', 'sd', 'yi', 'dv', 'ckb'};
    return rtlCodes.contains(code.toLowerCase());
  }

  static String _defaultDisplayName(String code) {
    const names = {
      'en': 'English',
      'ar': 'العربية',
      'fr': 'Français',
      'de': 'Deutsch',
      'es': 'Español',
      'it': 'Italiano',
      'pt': 'Português',
      'pt_BR': 'Português (Brasil)',
      'ru': 'Русский',
      'zh': '中文',
      'ja': '日本語',
      'ko': '한국어',
      'hi': 'हिन्दी',
      'tr': 'Türkçe',
      'nl': 'Nederlands',
      'pl': 'Polski',
      'sv': 'Svenska',
      'da': 'Dansk',
      'no': 'Norsk',
      'fi': 'Suomi',
      'el': 'Ελληνικά',
      'he': 'עברית',
      'fa': 'فارسی',
      'ur': 'اردو',
      'th': 'ไทย',
      'vi': 'Tiếng Việt',
      'id': 'Bahasa Indonesia',
    };
    return names[code] ?? code;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwayLocaleMeta &&
          runtimeType == other.runtimeType &&
          languageCode == other.languageCode;

  @override
  int get hashCode => languageCode.hashCode;

  @override
  String toString() => 'SwayLocaleMeta($languageCode, $displayName)';
}
