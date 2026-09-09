/// Loads and parses a single locale JSON file for the Sway format.
library;

import 'dart:convert';
import 'dart:io';

import 'exceptions.dart';

/// Represents a parsed Sway locale file.
class ParsedLocaleFile {
  /// The language code (e.g. `en`, `ar`).
  final String languageCode;

  /// The parsed key-value map from the JSON file.
  final Map<String, dynamic> data;

  /// The source file path.
  final String filePath;

  /// Creates a [ParsedLocaleFile].
  const ParsedLocaleFile({
    required this.languageCode,
    required this.data,
    required this.filePath,
  });

  /// Loads and parses a `.sway.json` file from disk.
  ///
  /// Throws [SwayJsonParseException] for malformed JSON,
  /// [SwayEncodingException] for non-UTF8 files.
  factory ParsedLocaleFile.load(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw SwayJsonParseException(
        'Locale file not found',
        filePath: path,
      );
    }

    String content;
    try {
      content = file.readAsStringSync(encoding: utf8);
    } on FileSystemException {
      throw SwayEncodingException(
        'Non-UTF8 encoding detected in file',
        filePath: path,
      );
    }

    final parsed = _parseJson(content, path);
    final languageCode = _extractLanguageCode(path);

    return ParsedLocaleFile(
      languageCode: languageCode,
      data: parsed,
      filePath: path,
    );
  }

  /// Parses JSON content with detailed error reporting.
  static Map<String, dynamic> _parseJson(String content, String filePath) {
    try {
      final decoded = json.decode(content);
      if (decoded is! Map<String, dynamic>) {
        throw SwayJsonParseException(
          'Root value must be a JSON object, got ${decoded.runtimeType}',
          filePath: filePath,
        );
      }
      return decoded;
    } on FormatException catch (e) {
      throw SwayJsonParseException(
        e.message,
        filePath: filePath,
      );
    }
  }

  /// Extracts the language code from a `.sway.json` filename.
  ///
  /// `en.sway.json` → `en`, `ar.sway.json` → `ar`.
  static String _extractLanguageCode(String path) {
    final basename = path.split(Platform.pathSeparator).last;
    final parts = basename.split('.');
    if (parts.length < 3 ||
        parts.last != 'json' ||
        parts[parts.length - 2] != 'sway') {
      throw SwayJsonParseException(
        'Invalid Sway locale filename format. Expected <locale>.sway.json, got: $basename',
        filePath: path,
      );
    }
    // Handle multi-part language codes like `pt_BR.sway.json`
    final codeParts = parts.sublist(0, parts.length - 2);
    return codeParts.join('.');
  }

  /// Detects duplicate keys in raw JSON string content.
  ///
  /// Returns a list of duplicate key paths found.
  static List<String> detectDuplicateKeys(String content) {
    final duplicates = <String>[];
    final lines = content.split('\n');
    final keyStack = <String>[];
    final keyCounts = <String, int>{};

    for (final line in lines) {
      final trimmed = line.trim();
      final keyMatch = RegExp(r'^"([^"]+)"\s*:').firstMatch(trimmed);
      if (keyMatch != null) {
        final key = keyMatch.group(1)!;
        keyStack.add(key);
        final fullPath = keyStack.join('.');
        keyCounts[fullPath] = (keyCounts[fullPath] ?? 0) + 1;
      }
      if (trimmed == '}' || trimmed.endsWith('},')) {
        if (keyStack.isNotEmpty) keyStack.removeLast();
      }
    }

    for (final entry in keyCounts.entries) {
      if (entry.value > 1) {
        duplicates.add(entry.key);
      }
    }
    return duplicates;
  }
}
