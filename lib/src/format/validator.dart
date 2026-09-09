/// Cross-locale key validation for the Sway format.
library;

import 'dart:io';

import 'exceptions.dart';
import 'locale_file.dart';
import 'plural_rules.dart';

/// Validates a set of parsed locale files against the Sway format rules.
class SwayValidator {
  /// Validates locale files and returns a [ValidationResult].
  ///
  /// [baseLocale] is the schema of truth. Extra keys in non-base locales
  /// are errors. Missing keys in non-base locales are warnings.
  static ValidationResult validate(
    List<ParsedLocaleFile> localeFiles, {
    String? baseLocale,
  }) {
    if (localeFiles.isEmpty) {
      return const ValidationResult(
        isValid: false,
        errors: ['No locale files provided'],
        warnings: [],
      );
    }

    final base = baseLocale ?? localeFiles.first.languageCode;
    final baseFile = localeFiles.firstWhere(
      (f) => f.languageCode == base,
      orElse: () => throw SwayValidationException(
        'Base locale "$base" not found among provided locale files',
        errors: ['Base locale file missing'],
      ),
    );

    final errors = <String>[];
    final warnings = <String>[];
    final baseKeys = _flattenKeys(baseFile.data);

    // Validate base locale file key names
    _validateKeyNames(baseFile, errors);

    // Validate base locale has no duplicate keys
    _validateNoDuplicateKeys(baseFile, errors);

    // Validate each non-base locale
    for (final file in localeFiles) {
      if (file.languageCode == base) continue;

      _validateKeyNames(file, errors);
      _validateNoDuplicateKeys(file, errors);

      final localeKeys = _flattenKeys(file.data);

      // Check for extra keys (error — base is schema of truth)
      for (final key in localeKeys) {
        if (!baseKeys.contains(key)) {
          errors.add(
            '${file.languageCode}: has extra key "$key" not in base locale',
          );
        }
      }

      // Check for missing keys (warning)
      final missingKeys = <String>[];
      for (final key in baseKeys) {
        if (!localeKeys.contains(key)) {
          missingKeys.add(key);
        }
      }
      if (missingKeys.isNotEmpty) {
        warnings.add(
          '${file.languageCode}: missing keys: ${missingKeys.join(', ')}',
        );
      }
    }

    // Validate placeholders across locales
    _validatePlaceholders(localeFiles, baseFile, errors);

    // Validate plural categories across locales
    _validatePluralCategories(localeFiles, errors);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validates that all keys are valid Dart identifiers.
  static void _validateKeyNames(ParsedLocaleFile file, List<String> errors) {
    final invalidKeys = _findInvalidKeys(file.data, '');
    for (final key in invalidKeys) {
      errors.add(
        '${file.languageCode}: invalid key "$key" — must match ^[a-zA-Z][a-zA-Z0-9_]*\$',
      );
    }
  }

  /// Validates no duplicate keys exist in the same file.
  static void _validateNoDuplicateKeys(
    ParsedLocaleFile file,
    List<String> errors,
  ) {
    try {
      final content = File(file.filePath).readAsStringSync();
      final duplicates = ParsedLocaleFile.detectDuplicateKeys(content);
      for (final key in duplicates) {
        errors.add(
          '${file.languageCode}: duplicate key "$key" defined multiple times',
        );
      }
    } catch (_) {
      // File already parsed successfully, skip re-read errors
    }
  }

  /// Validates that placeholders exist in every locale's translation of a key.
  static void _validatePlaceholders(
    List<ParsedLocaleFile> localeFiles,
    ParsedLocaleFile baseFile,
    List<String> errors,
  ) {
    final baseKeys = _flattenKeys(baseFile.data);

    for (final key in baseKeys) {
      final baseValue = _resolveValue(baseFile.data, key);
      if (baseValue is! String) continue;

      final basePlaceholders = _extractPlaceholders(baseValue);
      if (basePlaceholders.isEmpty) continue;

      for (final file in localeFiles) {
        final value = _resolveValue(file.data, key);
        if (value is! String) continue;

        final localePlaceholders = _extractPlaceholders(value);
        for (final placeholder in basePlaceholders) {
          if (!localePlaceholders.contains(placeholder)) {
            errors.add(
              '${file.languageCode}: key "$key" is missing placeholder '
              '{$placeholder} (present in base locale)',
            );
          }
        }
      }
    }
  }

  /// Validates plural categories are valid for each locale.
  static void _validatePluralCategories(
    List<ParsedLocaleFile> localeFiles,
    List<String> errors,
  ) {
    for (final file in localeFiles) {
      final allKeys = _flattenKeys(file.data);
      for (final key in allKeys) {
        final value = _resolveValue(file.data, key);
        if (value is! Map<String, dynamic>) continue;

        // Check if this is a plural object
        final isPlural = value.keys.every(
          (k) => k == 'zero' ||
              k == 'one' ||
              k == 'two' ||
              k == 'few' ||
              k == 'many' ||
              k == 'other',
        );
        if (!isPlural) continue;

        // Validate 'other' is always present
        if (!value.containsKey('other')) {
          errors.add(
            '${file.languageCode}: plural key "$key" is missing mandatory "other" category',
          );
          continue;
        }

        // Warn about categories this locale doesn't support
        final supported = supportedCategories(file.languageCode);
        for (final category in value.keys) {
          final categoryEnum = PluralCategory.values.firstWhere(
            (c) => c.name == category,
            orElse: () => PluralCategory.other,
          );
          if (!supported.contains(categoryEnum)) {
            errors.add(
              '${file.languageCode}: plural key "$key" has category "$category" '
              'which is not supported by this locale\'s CLDR rules',
            );
          }
        }
      }
    }
  }

  /// Finds keys that don't match the valid Dart identifier pattern.
  static List<String> _findInvalidKeys(
    Map<String, dynamic> data,
    String prefix,
  ) {
    final invalid = <String>[];
    final validPattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');

    for (final entry in data.entries) {
      final fullPath = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      if (!validPattern.hasMatch(entry.key)) {
        invalid.add(fullPath);
      }
      if (entry.value is Map<String, dynamic>) {
        invalid.addAll(_findInvalidKeys(entry.value as Map<String, dynamic>, fullPath));
      }
    }
    return invalid;
  }

  /// Flattens nested map keys into dot-separated paths.
  /// Includes both leaf keys and intermediate map keys.
  static Set<String> _flattenKeys(Map<String, dynamic> data, [String prefix = '']) {
    final keys = <String>{};
    for (final entry in data.entries) {
      final fullPath = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      if (entry.value is Map<String, dynamic>) {
        keys.add(fullPath);
        keys.addAll(_flattenKeys(entry.value as Map<String, dynamic>, fullPath));
      } else {
        keys.add(fullPath);
      }
    }
    return keys;
  }

  /// Resolves a dot-separated key path to its value.
  static dynamic _resolveValue(Map<String, dynamic> data, String keyPath) {
    final parts = keyPath.split('.');
    dynamic current = data;
    for (final part in parts) {
      if (current is! Map<String, dynamic>) return null;
      current = current[part];
    }
    return current;
  }

  /// Extracts `{placeholder}` names from a string.
  static Set<String> _extractPlaceholders(String value) {
    return RegExp(r'\{(\w+)\}')
        .allMatches(value)
        .map((m) => m.group(1)!)
        .toSet();
  }
}

/// Result of validation.
class ValidationResult {
  /// Whether validation passed (no errors).
  final bool isValid;

  /// Hard errors that must be fixed.
  final List<String> errors;

  /// Soft warnings about coverage or style.
  final List<String> warnings;

  /// Creates a [ValidationResult].
  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
}
