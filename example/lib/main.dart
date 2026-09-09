import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sway/sway.dart';

import 'i18n/sway.g.dart';
import 'screens/home_screen.dart';

void main() => runApp(const ExampleApp());

/// Brand charcoal — matches Darkmintis mark energy without default M3 blue.
const _brandSeed = Color(0xFF1C1C1C);

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => ExampleAppState();
}

class ExampleAppState extends State<ExampleApp> {
  late final SwayFormatAdapter adapter;
  Locale _locale = const Locale('en');
  /// Kept above [ForceRebuildScope] so locale switches don't reset the tab.
  int tabIndex = 0;

  Locale get locale => _locale;

  SwayTranslations get t => SwayTranslations.of(_locale);

  @override
  void initState() {
    super.initState();
    adapter = SwayFormatAdapter(
      supportedLocales: SwayTranslations.supportedLocales,
      currentLocale: _locale,
      onLocaleChange: (locale) => setState(() => _locale = locale),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: t.app.title,
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: SwayTranslations.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorSchemeSeed: _brandSeed,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: SwayOverlay(
        adapter: adapter,
        child: HomeScreen(
          t: t,
          locale: _locale,
          tabIndex: tabIndex,
          onTabChanged: (i) => setState(() => tabIndex = i),
        ),
      ),
    );
  }
}
