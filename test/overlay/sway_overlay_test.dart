import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sway/src/overlay/force_rebuild_scope.dart';
import 'package:sway/src/overlay/locale_adapter.dart';
import 'package:sway/src/overlay/sway_overlay.dart';

void main() {
  testWidgets('disabled overlay renders no floating button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SwayOverlay.disabled(child: Scaffold(body: Text('hello'))),
      ),
    );
    expect(find.byIcon(Icons.translate_rounded), findsNothing);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('enabled overlay shows floating button', (tester) async {
    late Locale locale;
    locale = const Locale('en');
    final adapter = SwayFormatAdapter(
      supportedLocales: const [Locale('en'), Locale('ar')],
      currentLocale: locale,
      onLocaleChange: (l) => locale = l,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SwayOverlay(
          adapter: adapter,
          child: const Scaffold(body: Text('body')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.translate_rounded), findsOneWidget);
  });

  testWidgets('drag updates bubble position then snaps to edge', (
    tester,
  ) async {
    final adapter = SwayFormatAdapter(
      supportedLocales: const [Locale('en'), Locale('ar')],
      currentLocale: const Locale('en'),
      onLocaleChange: (_) {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SwayOverlay(
          adapter: adapter,
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.byIcon(Icons.translate_rounded);
    expect(button, findsOneWidget);

    final before = tester.getCenter(button);
    // Drag past horizontal midpoint so snap lands on the opposite edge.
    await tester.drag(button, const Offset(-500, -120));
    await tester.pumpAndSettle();

    final after = tester.getCenter(button);
    expect(after.dx, lessThan(before.dx - 50));
    expect(after.dy, isNot(closeTo(before.dy, 1)));
  });

  testWidgets('keeps 12px clear of status bar and navigation bar', (
    tester,
  ) async {
    SwayOverlay.clearPersistedPositionForTest();
    addTearDown(SwayOverlay.clearPersistedPositionForTest);
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 40, bottom: 30);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: SwayOverlay(
          adapter: SwayFormatAdapter(
            supportedLocales: const [Locale('en'), Locale('ar')],
            currentLocale: const Locale('en'),
            onLocaleChange: (_) {},
          ),
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byIcon(Icons.translate_rounded);
    expect(tester.getCenter(button).dx, closeTo(400 - 12 - 24, 1));

    await tester.drag(button, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.getCenter(button).dy, closeTo(40 + 12 + 24, 1));

    await tester.drag(button, const Offset(0, 4000));
    await tester.pumpAndSettle();
    expect(tester.getCenter(button).dy, closeTo(800 - 30 - 12 - 24, 1));
  });

  testWidgets('0×0 first frame does not pin the bubble top-left', (
    tester,
  ) async {
    SwayOverlay.clearPersistedPositionForTest();
    tester.view.physicalSize = Size.zero;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final adapter = SwayFormatAdapter(
      supportedLocales: const [Locale('en'), Locale('ar')],
      currentLocale: const Locale('en'),
      onLocaleChange: (_) {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SwayOverlay(
          adapter: adapter,
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );
    await tester.pump();
    tester.view.physicalSize = const Size(400, 800);
    await tester.pumpAndSettle();

    final center = tester.getCenter(find.byIcon(Icons.translate_rounded));
    expect(center.dx, greaterThan(300)); // right side
    expect(center.dy, greaterThan(400)); // lower half
  });

  testWidgets('ForceRebuildScope remounts on forceRtl', (tester) async {
    var builds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ForceRebuildScope(
          locale: const Locale('en'),
          forceRtl: false,
          child: Builder(
            builder: (context) {
              builds++;
              return Text(Directionality.of(context).name);
            },
          ),
        ),
      ),
    );
    expect(find.text('ltr'), findsOneWidget);
    final firstBuilds = builds;

    await tester.pumpWidget(
      MaterialApp(
        home: ForceRebuildScope(
          locale: const Locale('en'),
          forceRtl: true,
          child: Builder(
            builder: (context) {
              builds++;
              return Text(Directionality.of(context).name);
            },
          ),
        ),
      ),
    );
    expect(find.text('rtl'), findsOneWidget);
    expect(builds, greaterThan(firstBuilds));
  });

  testWidgets('tap opens panel with Force RTL chip', (tester) async {
    final adapter = SwayFormatAdapter(
      supportedLocales: const [Locale('en'), Locale('ar')],
      currentLocale: const Locale('en'),
      onLocaleChange: (_) {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SwayOverlay(
          adapter: adapter,
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Simulate a tap via tiny pan (below slop) ending.
    final button = find.byIcon(Icons.translate_rounded);
    await tester.timedDrag(
      button,
      const Offset(2, 0),
      const Duration(milliseconds: 50),
    );
    await tester.pumpAndSettle();

    expect(find.text('Force RTL'), findsOneWidget);
    expect(find.text('Force LTR'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('bubble badge follows app locale changes via adapter', (
    tester,
  ) async {
    final adapter = SwayFormatAdapter(
      supportedLocales: const [Locale('en'), Locale('ar')],
      currentLocale: const Locale('en'),
      onLocaleChange: (_) {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SwayOverlay(
          adapter: adapter,
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('EN'), findsOneWidget);

    adapter.setLocale(const Locale('ar'));
    await tester.pumpAndSettle();

    expect(find.text('AR'), findsOneWidget);
    expect(find.text('EN'), findsNothing);
  });

  test('debugDisabled skips overlay when disabled flag set', () {
    // Compile-time sanity: disabled constructor sets adapter null.
    const w = SwayOverlay.disabled(child: SizedBox());
    expect(w.enabled, isFalse);
    expect(w.adapter, isNull);
  });

  test('kReleaseMode constant is boolean', () {
    expect(kReleaseMode, isA<bool>());
  });
}
