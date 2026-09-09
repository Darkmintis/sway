import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sway/src/codegen/config.dart';
import 'package:sway/src/codegen/emitter.dart';
import 'package:sway/src/format/locale_file.dart';

void main() {
  group('SwayEmitter', () {
    late List<ParsedLocaleFile> fixtures;
    const config = SwayConfig(
      baseLocale: 'en',
      outputFile: 'lib/i18n/sway.g.dart',
    );

    setUp(() {
      fixtures = [
        ParsedLocaleFile.load('test/codegen/fixtures/en.sway.json'),
        ParsedLocaleFile.load('test/codegen/fixtures/ar.sway.json'),
      ];
    });

    test('emits main library + per-locale parts', () {
      final result = SwayEmitter.emit(fixtures, config: config);

      expect(result.files.keys, containsAll(['sway.g.dart', 'sway_en.g.dart', 'sway_ar.g.dart']));

      final main = result.files['sway.g.dart']!;
      expect(main, contains("part 'sway_en.g.dart';"));
      expect(main, contains("part 'sway_ar.g.dart';"));
      expect(main, contains('abstract class SwayTranslations'));
      expect(main, contains('abstract class SwayHomeTranslations'));
      expect(main, contains('static SwayTranslations of(Locale locale)'));
      expect(main, isNot(contains('class SwayTranslationsEn')));

      final en = result.files['sway_en.g.dart']!;
      expect(en, contains("part of 'sway.g.dart';"));
      expect(en, contains('class SwayTranslationsEn extends SwayTranslations'));
      expect(en, contains('String welcome({required String name})'));
      expect(en, contains("resolvePlural('en', count)"));

      final ar = result.files['sway_ar.g.dart']!;
      expect(ar, contains('class SwayTranslationsAr extends SwayTranslations'));
      expect(ar, contains("resolvePlural('ar', count)"));
    });

    test('is deterministic across two runs', () {
      final a = SwayEmitter.emit(fixtures, config: config);
      final b = SwayEmitter.emit(fixtures, config: config);
      expect(a.files, equals(b.files));
    });

    test('golden files match emitted output', () {
      final result = SwayEmitter.emit(fixtures, config: config);
      final dir = Directory('test/codegen/fixtures');
      for (final entry in result.files.entries) {
        final golden = File('${dir.path}/${entry.key}.golden');
        if (!golden.existsSync()) {
          golden.writeAsStringSync(entry.value);
        }
        expect(
          entry.value,
          equals(golden.readAsStringSync()),
          reason: entry.key,
        );
      }
    });
  });
}
