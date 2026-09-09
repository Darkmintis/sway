/// Schema coverage helpers for codegen.
library;

import '../format/locale_file.dart';
import '../format/validator.dart';

/// Thin wrapper around [SwayValidator] for codegen callers.
class SchemaDiff {
  /// Validates [localeFiles] with [baseLocale] as schema of truth.
  static ValidationResult compare(
    List<ParsedLocaleFile> localeFiles, {
    required String baseLocale,
  }) {
    return SwayValidator.validate(localeFiles, baseLocale: baseLocale);
  }
}
