/// Sway codegen CLI — generates type-safe Dart from `.sway.json` files.
///
/// Usage: `dart run sway:codegen [--input <dir>] [--output <file>] [--config <file>]`
///
/// Writes a main library plus one part file per locale (ARB / gen-l10n style).
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sway/src/codegen/config.dart';
import 'package:sway/src/codegen/emitter.dart';
import 'package:sway/src/codegen/schema_diff.dart';
import 'package:sway/src/format/locale_file.dart';

void main(List<String> arguments) {
  var configPath = 'lib/i18n/sway.config.json';
  String? inputOverride;
  String? outputOverride;

  for (var i = 0; i < arguments.length; i++) {
    switch (arguments[i]) {
      case '--input':
        if (i + 1 < arguments.length) inputOverride = arguments[++i];
      case '--output':
        if (i + 1 < arguments.length) outputOverride = arguments[++i];
      case '--config':
        if (i + 1 < arguments.length) configPath = arguments[++i];
      case '--help':
      case '-h':
        _printUsage();
        return;
    }
  }

  final configFile = File(configPath);
  var config = configFile.existsSync()
      ? SwayConfig.load(configPath)
      : SwayConfig.defaults;

  // When --config points at example/lib/i18n/sway.config.json, localeDir in
  // that file is still "lib/i18n" (app-relative). Prefer the config's folder
  // as the locale dir when overrides aren't set and config lives next to JSON.
  if (inputOverride == null &&
      configFile.existsSync() &&
      config.localeDir == SwayConfig.defaults.localeDir) {
    final configDir = p.dirname(configPath);
    final siblingJson = Directory(configDir)
        .listSync()
        .whereType<File>()
        .any((f) => f.path.endsWith('.sway.json'));
    if (siblingJson) {
      config = SwayConfig(
        baseLocale: config.baseLocale,
        localeDir: configDir,
        outputFile: p.join(configDir, p.basename(config.outputFile)),
        fallbackStrategy: config.fallbackStrategy,
      );
    }
  }

  final inputDir = inputOverride ?? config.localeDir;
  final outputFile = outputOverride ?? config.outputFile;
  final effectiveConfig = SwayConfig(
    baseLocale: config.baseLocale,
    localeDir: inputDir,
    outputFile: outputFile,
    fallbackStrategy: config.fallbackStrategy,
  );

  final dir = Directory(inputDir);
  if (!dir.existsSync()) {
    stderr.writeln('Error: input directory does not exist: $inputDir');
    exit(1);
  }

  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.sway.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (files.isEmpty) {
    stderr.writeln(
      'Error: No .sway.json files found in ${dir.path}\n'
      'Create locale files like en.sway.json, ar.sway.json first.',
    );
    exit(1);
  }

  final parsed = <ParsedLocaleFile>[];
  for (final file in files) {
    try {
      parsed.add(ParsedLocaleFile.load(file.path));
    } catch (e) {
      stderr.writeln('Error parsing ${file.path}: $e');
      exit(1);
    }
  }

  final result = SchemaDiff.compare(
    parsed,
    baseLocale: effectiveConfig.baseLocale,
  );
  for (final w in result.warnings) {
    stdout.writeln('Warning: $w');
  }
  if (!result.isValid) {
    for (final e in result.errors) {
      stderr.writeln('Error: $e');
    }
    exit(1);
  }

  final emitted = SwayEmitter.emit(parsed, config: effectiveConfig);
  final outDir = Directory(p.dirname(outputFile))..createSync(recursive: true);
  final mainBase = p.basename(outputFile);
  final stem = mainBase.endsWith('.g.dart')
      ? mainBase.substring(0, mainBase.length - '.g.dart'.length)
      : p.basenameWithoutExtension(mainBase);

  // Remove stale per-locale parts from previous runs.
  for (final file in outDir.listSync().whereType<File>()) {
    final name = p.basename(file.path);
    if (name.startsWith('${stem}_') &&
        name.endsWith('.g.dart') &&
        !emitted.files.containsKey(name)) {
      file.deleteSync();
    }
  }

  for (final entry in emitted.files.entries) {
    File(p.join(outDir.path, entry.key)).writeAsStringSync(entry.value);
  }

  stdout.writeln('Generated: $outputFile');
  for (final name in emitted.files.keys.where((k) => k != mainBase)) {
    stdout.writeln('  + $name');
  }
  stdout.writeln(
    'Locales: ${parsed.map((f) => f.languageCode).join(', ')}',
  );
}

void _printUsage() {
  stdout.writeln('Sway Codegen CLI');
  stdout.writeln();
  stdout.writeln('Usage:');
  stdout.writeln('  dart run sway:codegen [options]');
  stdout.writeln();
  stdout.writeln('Options:');
  stdout.writeln(
    '  --config <file>   sway.config.json path (default: lib/i18n/sway.config.json)',
  );
  stdout.writeln(
    '  --input <dir>     Directory with .sway.json files (default: from config)',
  );
  stdout.writeln(
    '  --output <file>   Main output Dart file (default: from config)',
  );
  stdout.writeln('  -h, --help        Show this help');
  stdout.writeln();
  stdout.writeln(
    'Also writes sway_<locale>.g.dart part files next to the main output.',
  );
}
