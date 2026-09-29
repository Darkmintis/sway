import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sway/src/overlay/sway_activation.dart';
import 'package:sway/sway.dart';

SwayActivation _resolve({
  bool enabled = true,
  bool enableInRelease = false,
  bool debugOnly = false,
  required bool release,
  bool debug = false,
}) =>
    SwayActivation.resolve(
      enabled: enabled,
      enableInRelease: enableInRelease,
      debugOnly: debugOnly,
      isReleaseMode: release,
      isDebugMode: debug,
    );

void main() {
  tearDown(SwayActivation.resetForTest);

  group('SwayActivation.resolve', () {
    test('debug: on by default, off when disabled', () {
      expect(_resolve(release: false, debug: true).active, isTrue);
      expect(
        _resolve(enabled: false, release: false, debug: true).active,
        isFalse,
      );
    });

    test('profile: on by default, off with debugOnly', () {
      expect(_resolve(release: false).active, isTrue);
      expect(_resolve(debugOnly: true, release: false).active, isFalse);
    });

    test('release: off unless enableInRelease, then warns', () {
      final off = _resolve(release: true);
      expect(off.active, isFalse);
      expect(off.showReleaseWarning, isFalse);

      final on = _resolve(enableInRelease: true, release: true);
      expect(on.active, isTrue);
      expect(on.showReleaseWarning, isTrue);
    });

    test('release: enabled=false and debugOnly both win over opt-in', () {
      expect(
        _resolve(enabled: false, enableInRelease: true, release: true).active,
        isFalse,
      );
      expect(
        _resolve(debugOnly: true, enableInRelease: true, release: true).active,
        isFalse,
      );
    });
  });

  group('release builds', () {
    final adapter = ManualAdapter(
      supportedLocales: const [Locale('en')],
      currentLocale: const Locale('en'),
      onLocaleChange: (_) {},
    );

    Future<void> pump(WidgetTester tester, {required bool optIn}) async {
      SwayActivation.debugReleaseModeOverride = true;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => Sway.debugOverlay(
            adapter: adapter,
            enableInRelease: optIn,
            child: child!,
          ),
          home: const Scaffold(body: Text('home')),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('no bubble without enableInRelease', (tester) async {
      await pump(tester, optIn: false);
      expect(find.text('home'), findsOneWidget);
      expect(find.byIcon(Icons.translate_rounded), findsNothing);
    });

    testWidgets('enableInRelease shows bubble with red border', (
      tester,
    ) async {
      await pump(tester, optIn: true);
      expect(find.byIcon(Icons.translate_rounded), findsOneWidget);
      expect(_redBorder, findsOneWidget);
      expect(find.text('SWAY ACTIVE'), findsNothing);
    });
  });

  testWidgets('no release border in debug builds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SwayOverlay(
          adapter: ManualAdapter(
            supportedLocales: const [Locale('en')],
            currentLocale: const Locale('en'),
            onLocaleChange: (_) {},
          ),
          enableInRelease: true,
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.translate_rounded), findsOneWidget);
    expect(_redBorder, findsNothing);
  });
}

final _redBorder = find.byWidgetPredicate(
  (w) =>
      w is Material &&
      w.shape is CircleBorder &&
      (w.shape! as CircleBorder).side.color == const Color(0xFFB3261E),
);
