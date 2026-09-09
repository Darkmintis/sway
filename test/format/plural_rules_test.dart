import 'package:flutter_test/flutter_test.dart';
import 'package:sway/src/format/plural_rules.dart';

void main() {
  group('Plural rules', () {
    group('supportedCategories', () {
      test('English supports one and other', () {
        final categories = supportedCategories('en');
        expect(categories, contains(PluralCategory.one));
        expect(categories, contains(PluralCategory.other));
        expect(categories.length, 2);
      });

      test('Arabic supports all six categories', () {
        final categories = supportedCategories('ar');
        expect(categories, contains(PluralCategory.zero));
        expect(categories, contains(PluralCategory.one));
        expect(categories, contains(PluralCategory.two));
        expect(categories, contains(PluralCategory.few));
        expect(categories, contains(PluralCategory.many));
        expect(categories, contains(PluralCategory.other));
        expect(categories.length, 6);
      });

      test('Chinese supports only other', () {
        final categories = supportedCategories('zh');
        expect(categories, contains(PluralCategory.other));
        expect(categories.length, 1);
      });

      test('Unknown language defaults to one and other', () {
        final categories = supportedCategories('xyz');
        expect(categories, contains(PluralCategory.one));
        expect(categories, contains(PluralCategory.other));
      });
    });

    group('resolvePlural', () {
      test('English: 1 is one, everything else is other', () {
        expect(resolvePlural('en', 1), PluralCategory.one);
        expect(resolvePlural('en', 0), PluralCategory.other);
        expect(resolvePlural('en', 2), PluralCategory.other);
        expect(resolvePlural('en', 100), PluralCategory.other);
      });

      test('Arabic: full range of categories', () {
        expect(supportedCategories('ar'), contains(PluralCategory.many));
        expect(resolvePlural('ar', 0), PluralCategory.zero);
        expect(resolvePlural('ar', 1), PluralCategory.one);
        expect(resolvePlural('ar', 2), PluralCategory.two);
        expect(resolvePlural('ar', 3), PluralCategory.few);
        expect(resolvePlural('ar', 11), PluralCategory.many);
        expect(resolvePlural('ar', 100), PluralCategory.many);
      });

      test('Russian: slavic plural rules', () {
        expect(resolvePlural('ru', 1), PluralCategory.one);
        expect(resolvePlural('ru', 2), PluralCategory.few);
        expect(resolvePlural('ru', 5), PluralCategory.many);
        expect(resolvePlural('ru', 11), PluralCategory.many);
        expect(resolvePlural('ru', 21), PluralCategory.one);
      });

      test('Fractional values resolve correctly', () {
        expect(resolvePlural('en', 1.5), PluralCategory.other);
        expect(resolvePlural('en', 2.5), PluralCategory.other);
      });
    });
  });
}
