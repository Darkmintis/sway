/// Sway Migration CLI — converts ARB, easy_localization, or slang formats
/// into Sway's `.sway.json` format.
///
/// Usage: `dart run sway:migrate --from arb --input dir --output dir`
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Exit code for success.
const _exitSuccess = 0;

/// Exit code for unrecoverable error.
const _exitError = 1;

void main(List<String> arguments) {
  final args = _parseArgs(arguments);

  if (args == null) {
    _printUsage();
    exit(_exitError);
  }

  try {
    final result = _migrate(args);
    _printReport(result);

    if (result.errorCount > 0) {
      exit(_exitError);
    }
    exit(_exitSuccess);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(_exitError);
  }
}

/// Parses command-line arguments.
_MigrateArgs? _parseArgs(List<String> arguments) {
  String? from;
  String? input;
  String? output;
  bool dryRun = false;
  bool force = false;
  bool nestOnPrefix = false;

  for (var i = 0; i < arguments.length; i++) {
    switch (arguments[i]) {
      case '--from':
        if (i + 1 < arguments.length) from = arguments[++i];
      case '--input':
        if (i + 1 < arguments.length) input = arguments[++i];
      case '--output':
        if (i + 1 < arguments.length) output = arguments[++i];
      case '--dry-run':
        dryRun = true;
      case '--force':
        force = true;
      case '--nest-on-prefix':
        nestOnPrefix = true;
      case '--help':
      case '-h':
        return null;
    }
  }

  if (from == null || input == null) {
    stderr.writeln('Error: --from and --input are required');
    return null;
  }

  if (!['arb', 'easy_localization', 'slang'].contains(from)) {
    stderr.writeln('Error: --from must be one of: arb, easy_localization, slang');
    return null;
  }

  final inputDir = Directory(input);
  if (!inputDir.existsSync()) {
    stderr.writeln('Error: input directory does not exist: $input');
    return null;
  }

  return _MigrateArgs(
    from: from,
    inputDir: inputDir,
    outputDir: Directory(output ?? p.join(inputDir.path, '..', 'lib', 'i18n_migrated')),
    dryRun: dryRun,
    force: force,
    nestOnPrefix: nestOnPrefix,
  );
}

void _printUsage() {
  stdout.writeln('Sway Migration CLI');
  stdout.writeln();
  stdout.writeln('Usage:');
  stdout.writeln('  dart run sway:migrate --from <format> --input <dir> [options]');
  stdout.writeln();
  stdout.writeln('Options:');
  stdout.writeln('  --from <format>        Source format: arb, easy_localization, slang');
  stdout.writeln('  --input <dir>          Directory containing source locale files');
  stdout.writeln('  --output <dir>         Output directory (default: lib/i18n_migrated)');
  stdout.writeln('  --dry-run              Print summary without writing files');
  stdout.writeln('  --force                Write into non-empty output directory');
  stdout.writeln('  --nest-on-prefix       Split underscore-separated ARB keys into nesting');
  stdout.writeln('  -h, --help             Show this help');
}

/// Performs the migration and returns a result.
_MigrateResult _migrate(_MigrateArgs args) {
  final warnings = <String>[];
  final errors = <String>[];
  final migratedKeys = <String, int>{};

  // Find locale files in input directory
  final sourceFiles = args.inputDir
      .listSync()
      .whereType<File>()
      .where((f) => _isLocaleFile(f.path, args.from))
      .toList();

  if (sourceFiles.isEmpty) {
    return _MigrateResult(
      migratedKeys: {},
      warnings: ['No locale files found in ${args.inputDir.path}'],
      errors: ['No locale files found for format: ${args.from}'],
    );
  }

  // Create output directory if needed
  if (!args.dryRun) {
    args.outputDir.createSync(recursive: true);
  }

  for (final file in sourceFiles) {
    final languageCode = _extractLanguageCode(file.path, args.from);
    if (languageCode == null) {
      warnings.add('Could not extract language code from: ${file.path}');
      continue;
    }

    try {
      final content = file.readAsStringSync();
      final sourceData = json.decode(content) as Map<String, dynamic>;
      Map<String, dynamic> converted;

      switch (args.from) {
        case 'arb':
          converted = _convertArb(sourceData, args.nestOnPrefix, warnings);
        case 'easy_localization':
          converted = _convertEasyLocalization(sourceData, warnings);
        case 'slang':
          converted = _convertSlang(sourceData, warnings);
        default:
          throw UnsupportedError('Format not implemented: ${args.from}');
      }

      final keyCount = _countKeys(converted);
      migratedKeys[languageCode] = keyCount;

      final outputPath = p.join(args.outputDir.path, '$languageCode.sway.json');

      if (!args.dryRun) {
        final outputFile = File(outputPath);
        if (outputFile.existsSync() && !args.force) {
          errors.add('Output file exists but --force not specified: $outputPath');
          continue;
        }
        outputFile.writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(converted),
        );
      }
    } catch (e) {
      errors.add('Failed to migrate ${file.path}: $e');
    }
  }

  return _MigrateResult(
    migratedKeys: migratedKeys,
    warnings: warnings,
    errors: errors,
  );
}

bool _isLocaleFile(String path, String format) {
  final basename = p.basename(path).toLowerCase();
  switch (format) {
    case 'arb':
      return basename.endsWith('.arb');
    case 'easy_localization':
      return basename.endsWith('.json') ||
          basename.endsWith('.yaml') ||
          basename.endsWith('.csv');
    case 'slang':
      return basename.endsWith('.i18n.json') || basename.endsWith('.i18n.yaml');
    default:
      return false;
  }
}

String? _extractLanguageCode(String path, String format) {
  final basename = p.basenameWithoutExtension(path);
  switch (format) {
    case 'arb':
      // app_en.arb → en
      final parts = basename.split('_');
      if (parts.length >= 2) return parts.last;
    case 'easy_localization':
      return basename;
    case 'slang':
      // en.i18n.json → en
      return basename.split('.').first;
  }
  return null;
}

/// Converts ARB format to Sway format.
Map<String, dynamic> _convertArb(
  Map<String, dynamic> source,
  bool nestOnPrefix,
  List<String> warnings,
) {
  final result = <String, dynamic>{};

  for (final entry in source.entries) {
    // Skip metadata keys
    if (entry.key.startsWith('@@') || entry.key.startsWith('@')) continue;

    if (entry.value is String) {
      final value = entry.value as String;
      final converted = _convertIcuPlurals(value, warnings);
      final key = nestOnPrefix ? _nestKey(entry.key) : entry.key;
      _setNested(result, key, converted);
    }
  }

  return result;
}

/// Converts easy_localization format to Sway format.
Map<String, dynamic> _convertEasyLocalization(
  Map<String, dynamic> source,
  List<String> warnings,
) {
  final result = <String, dynamic>{};

  for (final entry in source.entries) {
    if (entry.value is String) {
      // Convert positional placeholders {0}, {1} to named
      var value = entry.value as String;
      var argIndex = 0;
      value = value.replaceAllMapped(
        RegExp(r'\{\}'),
        (match) {
          argIndex++;
          warnings.add(
            'Converted positional placeholder {} to {arg$argIndex} — '
            'rename for clarity',
          );
          return '{arg$argIndex}';
        },
      );
      result[entry.key] = value;
    } else if (entry.value is Map<String, dynamic>) {
      result[entry.key] = _convertEasyLocalization(
        entry.value as Map<String, dynamic>,
        warnings,
      );
    }
  }

  return result;
}

/// Converts slang format to Sway format.
Map<String, dynamic> _convertSlang(
  Map<String, dynamic> source,
  List<String> warnings,
) {
  final result = <String, dynamic>{};

  for (final entry in source.entries) {
    if (entry.value is String) {
      // Convert $variable to {variable}
      var value = entry.value as String;
      value = value.replaceAllMapped(
        RegExp(r'\$(\w+)'),
        (match) => '{${match.group(1)}}',
      );
      result[entry.key] = value;
    } else if (entry.value is Map<String, dynamic>) {
      result[entry.key] = _convertSlang(
        entry.value as Map<String, dynamic>,
        warnings,
      );
    }
  }

  return result;
}

/// Converts ICU plural syntax `{count, plural, one{...} other{...}}`
/// to Sway's plural object form.
///
/// Returns the original value if the syntax is too complex to auto-convert,
/// with a warning added.
String _convertIcuPlurals(String value, List<String> warnings) {
  // Find ICU plural patterns: {var, plural, cat{body} cat{body} ...}
  final pluralRegex = RegExp(r'\{(\w+),\s*plural,');
  final match = pluralRegex.firstMatch(value);
  if (match == null) return value;

  final varName = match.group(1)!;
  final startIdx = match.end; // position after "plural,"

  // Parse categories by tracking brace depth
  final categories = <String, String>{};
  var pos = startIdx;
  final raw = value;

  while (pos < raw.length) {
    // Skip whitespace
    while (pos < raw.length && raw[pos] == ' ') {
      pos++;
    }
    if (pos >= raw.length || raw[pos] == '}') break;

    // Read category name (e.g., "one", "other", "few")
    final catStart = pos;
    while (pos < raw.length && raw[pos] != '{' && raw[pos] != ' ') {
      pos++;
    }
    final category = raw.substring(catStart, pos).trim();
    if (category.isEmpty) break;

    // Skip whitespace
    while (pos < raw.length && raw[pos] == ' ') {
      pos++;
    }
    if (pos >= raw.length || raw[pos] != '{') break;
    pos++; // skip opening {

    // Read body with brace depth tracking
    var depth = 1;
    final bodyStart = pos;
    while (pos < raw.length && depth > 0) {
      if (raw[pos] == '{') {
        depth++;
      } else if (raw[pos] == '}') {
        depth--;
      }
      if (depth > 0) pos++;
    }
    final body = raw.substring(bodyStart, pos);
    if (pos < raw.length) pos++; // skip closing }

    categories[category] = body;
  }

  if (categories.isEmpty) {
    warnings.add(
      'ICU plural syntax detected but no categories found in "$value" — needs manual conversion',
    );
    return value;
  }

  // Check that 'other' exists
  if (!categories.containsKey('other')) {
    warnings.add(
      'ICU plural in "$value" missing "other" category — needs manual conversion',
    );
    return value;
  }

  // Check for select blocks or other complex patterns that we can't convert
  final hasComplexPatterns = categories.values.any(
    (body) => body.contains('select') || body.contains('plural'),
  );
  if (hasComplexPatterns) {
    warnings.add(
      'ICU plural in "$value" contains nested select/plural — needs manual conversion',
    );
    return value;
  }

  // Build the converted value: replace the ICU pattern with {varName}
  // and return the categories as a map-like structure
  // Since we can't return a Map from a String converter,
  // we return a JSON-like string that the caller can parse
  final resultBuffer = StringBuffer();
  resultBuffer.write('{');
  var first = true;
  for (final entry in categories.entries) {
    if (!first) resultBuffer.write(', ');
    first = false;
    // Replace # with the count variable reference
    final body = entry.value.replaceAll('#', '{$varName}');
    resultBuffer.write('"${entry.key}": "$body"');
  }
  resultBuffer.write('}');

  warnings.add(
    'Converted ICU plural in "$value" to Sway format',
  );
  return resultBuffer.toString();
}

/// Nests an underscore-separated key: `home_title` → `home.title`.
String _nestKey(String key) {
  return key.replaceAll('_', '.');
}

/// Sets a value at a dot-separated path in a nested map.
void _setNested(Map<String, dynamic> map, String path, dynamic value) {
  final parts = path.split('.');
  var current = map;

  for (var i = 0; i < parts.length - 1; i++) {
    current = current.putIfAbsent(parts[i], () => <String, dynamic>{})
        as Map<String, dynamic>;
  }

  current[parts.last] = value;
}

/// Counts all leaf keys in a nested map.
int _countKeys(Map<String, dynamic> map) {
  var count = 0;
  for (final value in map.values) {
    if (value is Map<String, dynamic>) {
      count += _countKeys(value);
    } else {
      count++;
    }
  }
  return count;
}

void _printReport(_MigrateResult result) {
  stdout.writeln();
  stdout.writeln('=== Sway Migration Report ===');
  stdout.writeln();

  if (result.migratedKeys.isNotEmpty) {
    stdout.writeln('Migrated:');
    for (final entry in result.migratedKeys.entries) {
      stdout.writeln('  ${entry.key}: ${entry.value} keys');
    }
    stdout.writeln('  Total: ${result.migratedKeys.values.fold(0, (a, b) => a + b)} keys');
  }

  if (result.warnings.isNotEmpty) {
    stdout.writeln();
    stdout.writeln('Warnings (${result.warnings.length}):');
    for (final warning in result.warnings) {
      stdout.writeln('  ⚠ $warning');
    }
  }

  if (result.errors.isNotEmpty) {
    stdout.writeln();
    stdout.writeln('Errors (${result.errors.length}):');
    for (final error in result.errors) {
      stdout.writeln('  ✗ $error');
    }
  }

  stdout.writeln();
}

class _MigrateArgs {
  final String from;
  final Directory inputDir;
  final Directory outputDir;
  final bool dryRun;
  final bool force;
  final bool nestOnPrefix;

  const _MigrateArgs({
    required this.from,
    required this.inputDir,
    required this.outputDir,
    required this.dryRun,
    required this.force,
    required this.nestOnPrefix,
  });
}

class _MigrateResult {
  final Map<String, int> migratedKeys;
  final List<String> warnings;
  final List<String> errors;

  const _MigrateResult({
    required this.migratedKeys,
    required this.warnings,
    required this.errors,
  });

  int get errorCount => errors.length;
}
