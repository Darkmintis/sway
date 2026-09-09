import 'package:flutter_test/flutter_test.dart';
import 'package:sway/src/format/validator.dart';
import 'package:sway/src/format/locale_file.dart';

void main() {
  group('SwayValidator', () {
    test('fails with empty locale files', () {
      final result = SwayValidator.validate([]);
      expect(result.isValid, isFalse);
      expect(result.errors, contains('No locale files provided'));
    });

    test('passes with valid single locale', () {
      final files = [
        const ParsedLocaleFile(
          languageCode: 'en',
          data: {
            'home': {'title': 'Home'},
          },
          filePath: 'en.sway.json',
        ),
      ];
      final result = SwayValidator.validate(files);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('reports missing keys in non-base locale', () {
      final files = [
        const ParsedLocaleFile(
          languageCode: 'en',
          data: {
            'home': {'title': 'Home', 'welcome': 'Welcome'},
          },
          filePath: 'en.sway.json',
        ),
        const ParsedLocaleFile(
          languageCode: 'fr',
          data: {
            'home': {'title': 'Accueil'},
          },
          filePath: 'fr.sway.json',
        ),
      ];
      final result = SwayValidator.validate(files);
      // Missing keys are warnings, not errors
      expect(result.isValid, isTrue);
      expect(result.warnings.length, greaterThanOrEqualTo(1));
      expect(result.warnings.first, contains('missing keys'));
    });

    test('reports extra keys in non-base locale as error', () {
      final files = [
        const ParsedLocaleFile(
          languageCode: 'en',
          data: {
            'home': {'title': 'Home'},
          },
          filePath: 'en.sway.json',
        ),
        const ParsedLocaleFile(
          languageCode: 'fr',
          data: {
            'home': {'title': 'Accueil', 'extra': 'Extra'},
          },
          filePath: 'fr.sway.json',
        ),
      ];
      final result = SwayValidator.validate(files);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('extra key')), isTrue);
    });

    test('reports invalid key names', () {
      final files = [
        const ParsedLocaleFile(
          languageCode: 'en',
          data: {
            '123invalid': 'value',
            'valid-key': 'value',
          },
          filePath: 'en.sway.json',
        ),
      ];
      final result = SwayValidator.validate(files);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('invalid key')), isTrue);
    });

    test('reports missing plural other category', () {
      final files = [
        const ParsedLocaleFile(
          languageCode: 'en',
          data: {
            'items': {
              'one': '{count} item',
              // missing 'other'
            },
          },
          filePath: 'en.sway.json',
        ),
      ];
      final result = SwayValidator.validate(files);
      expect(result.isValid, isFalse);
      expect(
        result.errors.any((e) => e.contains('missing mandatory "other"')),
        isTrue,
      );
    });

    test('passes with valid plural categories', () {
      final files = [
        const ParsedLocaleFile(
          languageCode: 'en',
          data: {
            'items': {
              'one': '{count} item',
              'other': '{count} items',
            },
          },
          filePath: 'en.sway.json',
        ),
      ];
      final result = SwayValidator.validate(files);
      expect(result.isValid, isTrue);
    });

    test('reports mismatched placeholders', () {
      final files = [
        const ParsedLocaleFile(
          languageCode: 'en',
          data: {
            'greeting': 'Hello, {name}!',
          },
          filePath: 'en.sway.json',
        ),
        const ParsedLocaleFile(
          languageCode: 'fr',
          data: {
            'greeting': 'Bonjour!',
          },
          filePath: 'fr.sway.json',
        ),
      ];
      final result = SwayValidator.validate(files);
      expect(result.isValid, isFalse);
      expect(
        result.errors.any((e) => e.contains('missing placeholder')),
        isTrue,
      );
    });
  });
}
