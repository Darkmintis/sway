import 'package:flutter_test/flutter_test.dart';
import 'package:sway/src/format/rtl_table.dart';

void main() {
  group('RTL table', () {
    test('contains expected RTL languages', () {
      expect(kRtlLanguageCodes, contains('ar'));
      expect(kRtlLanguageCodes, contains('he'));
      expect(kRtlLanguageCodes, contains('fa'));
      expect(kRtlLanguageCodes, contains('ur'));
      expect(kRtlLanguageCodes, contains('ps'));
      expect(kRtlLanguageCodes, contains('sd'));
      expect(kRtlLanguageCodes, contains('yi'));
      expect(kRtlLanguageCodes, contains('dv'));
      expect(kRtlLanguageCodes, contains('ckb'));
    });

    test('does not contain LTR languages', () {
      expect(kRtlLanguageCodes, isNot(contains('en')));
      expect(kRtlLanguageCodes, isNot(contains('fr')));
      expect(kRtlLanguageCodes, isNot(contains('de')));
    });

    test('isRtlLanguage returns true for RTL codes', () {
      expect(isRtlLanguage('ar'), isTrue);
      expect(isRtlLanguage('AR'), isTrue);
      expect(isRtlLanguage('he'), isTrue);
    });

    test('isRtlLanguage returns false for LTR codes', () {
      expect(isRtlLanguage('en'), isFalse);
      expect(isRtlLanguage('fr'), isFalse);
      expect(isRtlLanguage('zh'), isFalse);
    });
  });
}
