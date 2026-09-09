/// Sway Migration CLI — converts ARB, easy_localization, or slang formats
/// into Sway's `.sway.json` format.
///
/// Usage: `dart run sway:migrate --from arb --input dir --output dir`
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const _exitSuccess = 0;
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

_MigrateArgs? _parseArgs(List<String> arguments) {
  String? from;
  String? input;
  String? output;
  var dryRun = false;
  var force = false;
  var nestOnPrefix = false;

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
    stderr.writeln(
      'Error: --from must be one of: arb, easy_localization, slang',
    );
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
    outputDir: Directory(
      output ?? p.join(inputDir.path, '..', 'i18n_migrated'),
    ),
    dryRun: dryRun,
    force: force,
    nestOnPrefix: nestOnPrefix,
  );
}

void _printUsage() {
  stdout.writeln('Sway Migration CLI');
  stdout.writeln();
  stdout.writeln('Usage:');
  stdout.writeln(
    '  dart run sway:migrate --from <format> --input <dir> [options]',
  );
  stdout.writeln();
  stdout.writeln('Options:');
  stdout.writeln(
    '  --from <format>        Source format: arb, easy_localization, slang',
  );
  stdout.writeln(
      '  --input <dir>          Directory containing source locale files');
  stdout.writeln(
    '  --output <dir>         Output directory (default: ../i18n_migrated)',
  );
  stdout
      .writeln('  --dry-run              Print summary without writing files');
  stdout.writeln(
      '  --force                Write into non-empty output directory');
  stdout.writeln(
    '  --nest-on-prefix       Split underscore-separated ARB keys into nesting',
  );
  stdout.writeln('  -h, --help             Show this help');
}

_MigrateResult _migrate(_MigrateArgs args) {
  final warnings = <String>[];
  final errors = <String>[];
  final migratedKeys = <String, int>{};
  final manualKeys = <String>[];

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
      manualKeys: const [],
    );
  }

  if (!args.dryRun) {
    if (args.outputDir.existsSync()) {
      final existing = args.outputDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.sway.json'))
          .toList();
      if (existing.isNotEmpty && !args.force) {
        return _MigrateResult(
          migratedKeys: {},
          warnings: const [],
          errors: [
            'Output directory is not empty: ${args.outputDir.path}. '
                'Pass --force to overwrite.',
          ],
          manualKeys: const [],
        );
      }
    }
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
      final lower = file.path.toLowerCase();
      if (lower.endsWith('.yaml') ||
          lower.endsWith('.yml') ||
          lower.endsWith('.csv')) {
        errors.add(
          '${file.path}: YAML/CSV migrate requires a JSON source in 0.1.0 '
          '(no extra deps). Convert to JSON first, then re-run.',
        );
        continue;
      }

      final sourceData = json.decode(content) as Map<String, dynamic>;
      late Map<String, dynamic> converted;

      switch (args.from) {
        case 'arb':
          converted = _convertArb(
            sourceData,
            args.nestOnPrefix,
            warnings,
            manualKeys,
          );
        case 'easy_localization':
          converted = _convertEasyLocalization(sourceData, warnings);
        case 'slang':
          converted = _convertSlang(sourceData, warnings, manualKeys);
        default:
          throw UnsupportedError('Format not implemented: ${args.from}');
      }

      if (converted.isEmpty) {
        warnings.add('Skipped empty locale file: ${file.path}');
        continue;
      }

      migratedKeys[languageCode] = _countKeys(converted);

      final outputPath = p.join(args.outputDir.path, '$languageCode.sway.json');

      if (!args.dryRun) {
        File(outputPath).writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert(converted)}\n',
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
    manualKeys: manualKeys,
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
          basename.endsWith('.yml') ||
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
      final parts = basename.split('_');
      if (parts.length >= 2) return parts.last;
    case 'easy_localization':
      return basename;
    case 'slang':
      return basename.split('.').first;
  }
  return null;
}

Map<String, dynamic> _convertArb(
  Map<String, dynamic> source,
  bool nestOnPrefix,
  List<String> warnings,
  List<String> manualKeys,
) {
  final result = <String, dynamic>{};

  for (final entry in source.entries) {
    if (entry.key.startsWith('@@') || entry.key.startsWith('@')) continue;
    if (entry.value is! String) continue;

    final value = entry.value as String;
    final converted = _convertIcuValue(value, entry.key, warnings, manualKeys);
    final key = nestOnPrefix ? _nestKey(entry.key) : entry.key;
    _setNested(result, key, converted);
  }

  return result;
}

Map<String, dynamic> _convertEasyLocalization(
  Map<String, dynamic> source,
  List<String> warnings,
) {
  final result = <String, dynamic>{};

  for (final entry in source.entries) {
    if (entry.value is String) {
      var value = entry.value as String;
      var argIndex = 0;
      value = value.replaceAllMapped(RegExp(r'\{\}'), (match) {
        argIndex++;
        warnings.add(
          'Converted positional placeholder {} to {arg$argIndex} — '
          'rename for clarity',
        );
        return '{arg$argIndex}';
      });
      // Also {0}, {1} style
      value = value.replaceAllMapped(RegExp(r'\{(\d+)\}'), (match) {
        final n = int.parse(match.group(1)!) + 1;
        warnings.add(
          'Converted positional placeholder {${match.group(1)}} to {arg$n}',
        );
        return '{arg$n}';
      });
      result[entry.key] = value;
    } else if (entry.value is Map<String, dynamic>) {
      final sub = entry.value as Map<String, dynamic>;
      if (_looksLikePlural(sub)) {
        result[entry.key] = Map<String, dynamic>.from(sub);
      } else {
        result[entry.key] = _convertEasyLocalization(sub, warnings);
      }
    }
  }

  return result;
}

Map<String, dynamic> _convertSlang(
  Map<String, dynamic> source,
  List<String> warnings,
  List<String> manualKeys,
) {
  final result = <String, dynamic>{};

  for (final entry in source.entries) {
    if (entry.value is String) {
      var value = entry.value as String;
      value = value.replaceAllMapped(
        RegExp(r'\$(\w+)'),
        (match) => '{${match.group(1)}}',
      );
      result[entry.key] = value;
    } else if (entry.value is Map<String, dynamic>) {
      final sub = entry.value as Map<String, dynamic>;
      if (_looksLikePlural(sub)) {
        final converted = <String, dynamic>{};
        for (final e in sub.entries) {
          if (e.value is String) {
            converted[e.key] = (e.value as String).replaceAllMapped(
              RegExp(r'\$(\w+)'),
              (m) => '{${m.group(1)}}',
            );
          } else {
            converted[e.key] = e.value;
          }
        }
        result[entry.key] = converted;
      } else if (sub.containsKey('(context)') ||
          sub.keys.any((k) => k.startsWith('('))) {
        manualKeys.add(entry.key);
        warnings.add(
          'slang context/enum variant at "${entry.key}" is unsupported — '
          'kept as nested object for manual cleanup',
        );
        result[entry.key] = _convertSlang(sub, warnings, manualKeys);
      } else {
        result[entry.key] = _convertSlang(sub, warnings, manualKeys);
      }
    }
  }

  return result;
}

/// Converts a string that may contain ICU plural/select syntax.
///
/// Returns a [String] or a plural [Map]. Unconvertible ICU is left as the
/// original string and recorded in [manualKeys].
dynamic _convertIcuValue(
  String value,
  String key,
  List<String> warnings,
  List<String> manualKeys,
) {
  if (value.contains(', select,')) {
    manualKeys.add(key);
    warnings.add(
      'Key "$key": ICU select is unsupported — left as original string for manual conversion',
    );
    return value;
  }

  final pluralRegex = RegExp(r'\{(\w+),\s*plural,');
  final match = pluralRegex.firstMatch(value);
  if (match == null) return value;

  // Only convert when the entire value is a single plural expression.
  if (!value.trimLeft().startsWith('{') || match.start != value.indexOf('{')) {
    manualKeys.add(key);
    warnings.add(
      'Key "$key": ICU plural is mixed with surrounding text — needs manual conversion',
    );
    return value;
  }

  final varName = match.group(1)!;
  var pos = match.end;
  final categories = <String, String>{};

  while (pos < value.length) {
    while (pos < value.length && (value[pos] == ' ' || value[pos] == '\n')) {
      pos++;
    }
    if (pos >= value.length || value[pos] == '}') break;

    final catStart = pos;
    while (pos < value.length && value[pos] != '{' && value[pos] != ' ') {
      pos++;
    }
    final category = value.substring(catStart, pos).trim();
    if (category.isEmpty) break;

    while (pos < value.length && value[pos] == ' ') {
      pos++;
    }
    if (pos >= value.length || value[pos] != '{') break;
    pos++;

    var depth = 1;
    final bodyStart = pos;
    while (pos < value.length && depth > 0) {
      if (value[pos] == '{') {
        depth++;
      } else if (value[pos] == '}') {
        depth--;
      }
      if (depth > 0) pos++;
    }
    final body = value.substring(bodyStart, pos);
    if (pos < value.length) pos++;

    if (body.contains('select') || body.contains('plural')) {
      manualKeys.add(key);
      warnings.add(
        'Key "$key": nested ICU select/plural — needs manual conversion',
      );
      return value;
    }

    // `#` → `{count}` (Sway reserved). Also rewrite `{varName}` → `{count}`.
    var normalized = body.replaceAll('#', '{count}');
    if (varName != 'count') {
      normalized = normalized.replaceAll('{$varName}', '{count}');
    }
    categories[category] = normalized;
  }

  if (categories.isEmpty || !categories.containsKey('other')) {
    manualKeys.add(key);
    warnings.add(
      'Key "$key": ICU plural missing categories/other — needs manual conversion',
    );
    return value;
  }

  final mapped = _mapIcuExactPluralKeys(categories, key, warnings, manualKeys);
  if (mapped == null) return value;

  if (varName != 'count') {
    warnings.add(
      'Key "$key": ICU plural variable "$varName" mapped to {count}',
    );
  }

  return mapped;
}

/// Maps ICU exact forms (`=0`, `=1`, `=2`) to CLDR categories Sway accepts.
///
/// Returns `null` when an exact form cannot be mapped (caller keeps original).
Map<String, String>? _mapIcuExactPluralKeys(
  Map<String, String> categories,
  String key,
  List<String> warnings,
  List<String> manualKeys,
) {
  const exactToCldr = {'=0': 'zero', '=1': 'one', '=2': 'two'};
  final out = <String, String>{};

  for (final entry in categories.entries) {
    final cat = entry.key;
    final mapped = exactToCldr[cat];
    if (mapped != null) {
      if (out.containsKey(mapped) && out[mapped] != entry.value) {
        warnings.add(
          'Key "$key": ICU "$cat" maps to "$mapped" which already exists — keeping existing "$mapped"',
        );
        continue;
      }
      out[mapped] = entry.value;
      if (cat != mapped) {
        warnings.add('Key "$key": ICU plural "$cat" mapped to "$mapped"');
      }
      continue;
    }
    if (cat.startsWith('=')) {
      manualKeys.add(key);
      warnings.add(
        'Key "$key": ICU exact plural "$cat" is unsupported — left as original string for manual conversion',
      );
      return null;
    }
    out[cat] = entry.value;
  }

  return out;
}

bool _looksLikePlural(Map<String, dynamic> map) {
  if (map.isEmpty) return false;
  const cats = {'zero', 'one', 'two', 'few', 'many', 'other'};
  return map.keys.every(cats.contains);
}

String _nestKey(String key) => key.replaceAll('_', '.');

void _setNested(Map<String, dynamic> map, String path, dynamic value) {
  final parts = path.split('.');
  var current = map;

  for (var i = 0; i < parts.length - 1; i++) {
    final next = current.putIfAbsent(parts[i], () => <String, dynamic>{});
    if (next is! Map<String, dynamic>) {
      throw StateError('Key collision while nesting at "${parts[i]}"');
    }
    current = next;
  }

  if (current.containsKey(parts.last) && current[parts.last] is Map) {
    throw StateError('Key collision at "$path"');
  }
  current[parts.last] = value;
}

int _countKeys(Map<String, dynamic> map) {
  var count = 0;
  for (final value in map.values) {
    if (value is Map<String, dynamic>) {
      if (_looksLikePlural(value)) {
        count++;
      } else {
        count += _countKeys(value);
      }
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
    stdout.writeln(
      '  Total: ${result.migratedKeys.values.fold(0, (a, b) => a + b)} keys',
    );
  }

  if (result.manualKeys.isNotEmpty) {
    stdout.writeln();
    stdout.writeln('Needs manual conversion (${result.manualKeys.length}):');
    for (final key in result.manualKeys) {
      stdout.writeln('  • $key');
    }
  }

  if (result.warnings.isNotEmpty) {
    stdout.writeln();
    stdout.writeln('Warnings (${result.warnings.length}):');
    for (final warning in result.warnings) {
      stdout.writeln('  ! $warning');
    }
  }

  if (result.errors.isNotEmpty) {
    stdout.writeln();
    stdout.writeln('Errors (${result.errors.length}):');
    for (final error in result.errors) {
      stdout.writeln('  x $error');
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
  final List<String> manualKeys;

  const _MigrateResult({
    required this.migratedKeys,
    required this.warnings,
    required this.errors,
    required this.manualKeys,
  });

  int get errorCount => errors.length;
}
