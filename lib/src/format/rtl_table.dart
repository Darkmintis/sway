/// Static table of RTL language codes per the Sway format specification.
library;

/// Known RTL language codes.
///
/// These drive codegen's `bool get isRtl` per generated locale class,
/// the overlay's automatic `Directionality` selection, and per-project
/// overrides via `sway.config.json`.
const Set<String> kRtlLanguageCodes = {
  'ar', // Arabic
  'he', // Hebrew
  'fa', // Persian (Farsi)
  'ur', // Urdu
  'ps', // Pashto
  'sd', // Sindhi
  'yi', // Yiddish
  'dv', // Divehi
  'ckb', // Kurdish (Sorani)
};

/// Returns `true` if [languageCode] is a known RTL language.
bool isRtlLanguage(String languageCode) {
  return kRtlLanguageCodes.contains(languageCode.toLowerCase());
}
