import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final root = Directory.current.path;
  final migrateBin = p.join(root, 'bin', 'migrate.dart');

  Future<ProcessResult> runMigrate(List<String> args) {
    return Process.run('dart', ['run', migrateBin, ...args]);
  }

  group('migrate CLI', () {
    test('ARB converts ICU plurals to objects and flags select', () async {
      final out = Directory(
        p.join(root, 'test', 'migrate',
            'out_arb_${DateTime.now().microsecondsSinceEpoch}'),
      )..createSync();
      addTearDown(() {
        if (out.existsSync()) out.deleteSync(recursive: true);
      });

      final result = await runMigrate([
        '--from',
        'arb',
        '--input',
        p.join(root, 'test', 'migrate', 'fixtures', 'arb'),
        '--output',
        out.path,
      ]);

      expect(result.exitCode, 0, reason: result.stderr.toString());
      final en = File(p.join(out.path, 'en.sway.json'));
      expect(en.existsSync(), isTrue);
      final data = json.decode(en.readAsStringSync()) as Map<String, dynamic>;
      expect(data['homeTitle'], 'Home');
      expect(data['welcome'], 'Hello, {name}!');
      expect(data['itemCount'], isA<Map>());
      final itemCount = data['itemCount'] as Map<String, dynamic>;
      expect(itemCount['zero'], 'no items');
      expect(itemCount['one'], '{count} item');
      expect(itemCount['other'], '{count} items');
      expect(itemCount.containsKey('=0'), isFalse);
      expect(data['gender'], contains('select'));
      expect(result.stdout.toString(), contains('Needs manual conversion'));
      expect(result.stdout.toString(), contains('"=0" mapped to "zero"'));
    });

    test('easy_localization converts positional placeholders', () async {
      final out = Directory(
        p.join(root, 'test', 'migrate',
            'out_easy_${DateTime.now().microsecondsSinceEpoch}'),
      )..createSync();
      addTearDown(() {
        if (out.existsSync()) out.deleteSync(recursive: true);
      });

      final result = await runMigrate([
        '--from',
        'easy_localization',
        '--input',
        p.join(root, 'test', 'migrate', 'fixtures', 'easy'),
        '--output',
        out.path,
      ]);

      expect(result.exitCode, 0, reason: result.stderr.toString());
      final data = json.decode(
        File(p.join(out.path, 'en.sway.json')).readAsStringSync(),
      ) as Map<String, dynamic>;
      final home = data['home'] as Map<String, dynamic>;
      final items = data['items'] as Map<String, dynamic>;
      expect(home['welcome'], 'Hello, {arg1}!');
      expect(items['one'], '{count} item');
    });

    test('slang converts \$name to {name}', () async {
      final out = Directory(
        p.join(root, 'test', 'migrate',
            'out_slang_${DateTime.now().microsecondsSinceEpoch}'),
      )..createSync();
      addTearDown(() {
        if (out.existsSync()) out.deleteSync(recursive: true);
      });

      final result = await runMigrate([
        '--from',
        'slang',
        '--input',
        p.join(root, 'test', 'migrate', 'fixtures', 'slang'),
        '--output',
        out.path,
      ]);

      expect(result.exitCode, 0, reason: result.stderr.toString());
      final data = json.decode(
        File(p.join(out.path, 'en.sway.json')).readAsStringSync(),
      ) as Map<String, dynamic>;
      final home = data['home'] as Map<String, dynamic>;
      final items = data['items'] as Map<String, dynamic>;
      expect(home['welcome'], 'Hello, {name}!');
      expect(items['one'], '{count} item');
    });

    test('dry-run does not write files', () async {
      final out = Directory(
        p.join(root, 'test', 'migrate',
            'out_dry_${DateTime.now().microsecondsSinceEpoch}'),
      );

      final result = await runMigrate([
        '--from',
        'arb',
        '--input',
        p.join(root, 'test', 'migrate', 'fixtures', 'arb'),
        '--output',
        out.path,
        '--dry-run',
      ]);

      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(out.existsSync(), isFalse);
    });

    test('refuses non-empty output without --force', () async {
      final out = Directory(
        p.join(root, 'test', 'migrate',
            'out_force_${DateTime.now().microsecondsSinceEpoch}'),
      )..createSync();
      addTearDown(() {
        if (out.existsSync()) out.deleteSync(recursive: true);
      });
      File(p.join(out.path, 'en.sway.json')).writeAsStringSync('{}');

      final result = await runMigrate([
        '--from',
        'arb',
        '--input',
        p.join(root, 'test', 'migrate', 'fixtures', 'arb'),
        '--output',
        out.path,
      ]);

      expect(result.exitCode, isNot(0));
      expect(result.stdout.toString() + result.stderr.toString(),
          contains('--force'));
    });
  });
}
