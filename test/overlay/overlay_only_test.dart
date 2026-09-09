import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sway/sway.dart';

/// Proves overlay-only usage: keep ARB/gen-l10n (or any system) and only
/// wire [IntlAdapter] + [SwayOverlay] — no Sway JSON / codegen required.
void main() {
  testWidgets('overlay-only with IntlAdapter switches app locale',
      (tester) async {
    var locale = const Locale('en');
    final adapter = IntlAdapter(
      supportedLocales: const [Locale('en'), Locale('ar')],
      currentLocale: locale,
      onLocaleChange: (next) => locale = next,
    );

    Widget app() {
      return MaterialApp(
        locale: locale,
        supportedLocales: adapter.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: SwayOverlay(
          adapter: adapter,
          child: Scaffold(
            body: Center(
              child: Text(locale.languageCode, key: const Key('lang')),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('EN'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('lang'))).data, 'en');

    final button = find.byIcon(Icons.translate_rounded);
    await tester.timedDrag(
      button,
      const Offset(2, 0),
      const Duration(milliseconds: 50),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(adapter.currentLocale, const Locale('ar'));
    expect(locale, const Locale('ar'));
    expect(find.text('AR'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('lang'))).data, 'ar');
  });

  testWidgets('ManualAdapter works without Sway format', (tester) async {
    var locale = const Locale('en');
    final adapter = ManualAdapter(
      supportedLocales: const [Locale('en'), Locale('de')],
      currentLocale: locale,
      onLocaleChange: (next) => locale = next,
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

    adapter.setLocale(const Locale('de'));
    await tester.pumpAndSettle();
    expect(find.text('DE'), findsOneWidget);
  });
}
