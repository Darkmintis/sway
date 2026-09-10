import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sway/sway.dart';

class _LocaleService extends ChangeNotifier {
  Locale locale;
  _LocaleService(this.locale);

  void setLocale(Locale next) {
    if (locale == next) return;
    locale = next;
    notifyListeners();
  }
}

void main() {
  testWidgets('Sway.debugOverlay under MaterialApp.builder shows bubble',
      (tester) async {
    final service = _LocaleService(const Locale('en'));

    await tester.pumpWidget(
      MaterialApp(
        locale: service.locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        builder: (context, child) => Sway.debugOverlay(
          localeListenable: service,
          getLocale: () => service.locale,
          setLocale: service.setLocale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          child: child!,
        ),
        home: const Scaffold(body: Text('home')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.byIcon(Icons.translate_rounded), findsOneWidget);
  });

  testWidgets('ListenableLocaleAdapter syncs badge when service notifies',
      (tester) async {
    final service = _LocaleService(const Locale('en'));
    final adapter = ListenableLocaleAdapter(
      localeListenable: service,
      getLocale: () => service.locale,
      setLocale: service.setLocale,
      supportedLocales: const [Locale('en'), Locale('ar')],
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

    service.setLocale(const Locale('ar'));
    await tester.pumpAndSettle();
    expect(find.text('AR'), findsOneWidget);
    expect(find.text('EN'), findsNothing);

    adapter.dispose();
  });

  testWidgets('long-press hides the floating button', (tester) async {
    final adapter = ManualAdapter(
      supportedLocales: const [Locale('en')],
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
    expect(find.byIcon(Icons.translate_rounded), findsOneWidget);

    // Hold still past the long-press timer (pan distance stays under slop).
    final button = find.byIcon(Icons.translate_rounded);
    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.translate_rounded), findsNothing);
  });

  testWidgets('debugOnly still shows bubble in debug test environment',
      (tester) async {
    final adapter = ManualAdapter(
      supportedLocales: const [Locale('en')],
      currentLocale: const Locale('en'),
      onLocaleChange: (_) {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SwayOverlay(
          adapter: adapter,
          debugOnly: true,
          child: const Scaffold(body: Text('x')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.translate_rounded), findsOneWidget);
  });

  test('SwayOverlay.debugOnly defaults to false', () {
    const w = SwayOverlay.disabled(child: SizedBox());
    expect(w.debugOnly, isFalse);
    expect(w.disabled, isTrue);
  });
}
