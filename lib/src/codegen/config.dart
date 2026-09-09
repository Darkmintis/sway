/// Project config loaded from `sway.config.json`.
library;

import 'dart:convert';
import 'dart:io';

/// Sway project configuration.
class SwayConfig {
  /// Schema-of-truth locale code.
  final String baseLocale;

  /// Directory containing `.sway.json` files.
  final String localeDir;

  /// Generated Dart output path.
  final String outputFile;

  /// `baseLocale` or `key`.
  final String fallbackStrategy;

  /// Creates a [SwayConfig].
  const SwayConfig({
    this.baseLocale = 'en',
    this.localeDir = 'lib/i18n',
    this.outputFile = 'lib/i18n/sway.g.dart',
    this.fallbackStrategy = 'baseLocale',
  });

  /// Default config used when no file is present.
  static const SwayConfig defaults = SwayConfig();

  /// Loads config from [path], or returns [defaults] if missing.
  factory SwayConfig.load([String path = 'lib/i18n/sway.config.json']) {
    final file = File(path);
    if (!file.existsSync()) return defaults;

    final raw = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    final strategy = raw['fallbackStrategy'] as String? ?? 'baseLocale';
    if (strategy != 'baseLocale' && strategy != 'key') {
      throw FormatException(
        'fallbackStrategy must be "baseLocale" or "key", got "$strategy"',
      );
    }
    return SwayConfig(
      baseLocale: raw['baseLocale'] as String? ?? defaults.baseLocale,
      localeDir: raw['localeDir'] as String? ?? defaults.localeDir,
      outputFile: raw['outputFile'] as String? ?? defaults.outputFile,
      fallbackStrategy: strategy,
    );
  }
}
