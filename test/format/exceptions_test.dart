import 'package:flutter_test/flutter_test.dart';
import 'package:sway/src/format/exceptions.dart';

void main() {
  group('SwayFormatException', () {
    test('stores message and optional filePath', () {
      const ex = SwayJsonParseException('bad json', filePath: 'test.json');
      expect(ex.message, 'bad json');
      expect(ex.filePath, 'test.json');
    });

    test('toString includes filePath when present', () {
      const ex = SwayJsonParseException('bad json', filePath: 'test.json');
      expect(ex.toString(), contains('test.json'));
    });

    test('toString omits filePath when null', () {
      const ex = SwayJsonParseException('bad json');
      expect(ex.toString(), isNot(contains('null')));
    });
  });

  group('SwayJsonParseException', () {
    test('stores line and column', () {
      const ex = SwayJsonParseException(
        'trailing comma',
        filePath: 'en.sway.json',
        line: 5,
        column: 12,
      );
      expect(ex.line, 5);
      expect(ex.column, 12);
    });

    test('toString includes line and column', () {
      const ex = SwayJsonParseException(
        'trailing comma',
        line: 5,
        column: 12,
      );
      expect(ex.toString(), contains('line 5'));
      expect(ex.toString(), contains('column 12'));
    });
  });

  group('SwayValidationException', () {
    test('stores error list', () {
      const ex = SwayValidationException(
        'validation failed',
        errors: ['missing key x', 'invalid key y'],
      );
      expect(ex.errors.length, 2);
      expect(ex.errors, contains('missing key x'));
    });

    test('toString includes all errors', () {
      const ex = SwayValidationException(
        'validation failed',
        errors: ['error 1', 'error 2'],
      );
      expect(ex.toString(), contains('error 1'));
      expect(ex.toString(), contains('error 2'));
    });
  });

  group('SwayEncodingException', () {
    test('stores encoding error message', () {
      const ex = SwayEncodingException('non-UTF8 file', filePath: 'bad.bin');
      expect(ex.message, 'non-UTF8 file');
      expect(ex.filePath, 'bad.bin');
    });
  });

  group('SwayCodegenException', () {
    test('stores codegen error', () {
      const ex = SwayCodegenException('build failed', filePath: 'out.g.dart');
      expect(ex.message, 'build failed');
    });
  });
}
