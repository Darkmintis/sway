import 'package:flutter/material.dart';
import 'package:sway/sway.dart';

import 'i18n/sway.g.dart';
import 'screens/home_screen.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => ExampleAppState();
}

class ExampleAppState extends State<ExampleApp> {
  late final SwayFormatAdapter adapter;
  Locale _locale = SwayTranslations.supportedLocales.first;

  Locale get locale => _locale;

  dynamic get t => _locale.languageCode == 'ar'
      ? SwayTranslations.ar
      : SwayTranslations.en;

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
      title: 'Sway Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: SwayOverlay(
        adapter: adapter,
        child: HomeScreen(t: t, locale: _locale),
      ),
    );
  }
}
