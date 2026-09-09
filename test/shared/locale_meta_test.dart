import 'package:flutter_test/flutter_test.dart';
import 'package:sway/src/shared/locale_meta.dart';

void main() {
  group('SwayLocaleMeta', () {
    test('creates from language code with auto-detection', () {
      final meta = SwayLocaleMeta.fromLanguageCode('en');
      expect(meta.languageCode, 'en');
      expect(meta.isRtl, isFalse);
      expect(meta.displayName, 'English');
    });

    test('detects RTL languages', () {
      final meta = SwayLocaleMeta.fromLanguageCode('ar');
      expect(meta.isRtl, isTrue);
      expect(meta.displayName, 'العربية');
    });

    test('handles unknown languages gracefully', () {
      final meta = SwayLocaleMeta.fromLanguageCode('xyz');
      expect(meta.isRtl, isFalse);
      expect(meta.displayName, 'xyz');
    });

    test('accepts custom display name', () {
      final meta = SwayLocaleMeta.fromLanguageCode('en', displayName: 'Custom');
      expect(meta.displayName, 'Custom');
    });

    test('equality is based on language code', () {
      final a = SwayLocaleMeta.fromLanguageCode('en');
      final b = SwayLocaleMeta.fromLanguageCode('en');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different language codes are not equal', () {
      final a = SwayLocaleMeta.fromLanguageCode('en');
      final b = SwayLocaleMeta.fromLanguageCode('fr');
      expect(a, isNot(equals(b)));
    });
  });
}
