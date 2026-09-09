# Overlay only (ARB / easy_localization / slang)

Use Sway’s floating locale switcher **without** adopting Sway JSON or codegen.

This is the zero-commitment entry point: keep `AppLocalizations`, `easy_localization`, or slang, and add a debug bubble for instant locale + RTL preview.

## Install

```bash
dart pub add sway
```

You only need the overlay + an adapter. You do **not** run `sway:codegen` unless you later migrate.

## ARB / gen-l10n

```dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // or your gen path
import 'package:sway/sway.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');

  late final adapter = IntlAdapter(
    supportedLocales: AppLocalizations.supportedLocales,
    currentLocale: _locale,
    onLocaleChange: (locale) => setState(() => _locale = locale),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: SwayOverlay(
        adapter: adapter,
        // Place under a route that has an Overlay (e.g. MaterialApp.home).
        child: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(l10n.helloWorld); // unchanged
  }
}
```

The overlay calls `adapter.setLocale`, which updates `_locale` and rebuilds `MaterialApp` — your existing gen-l10n strings update as usual.

## easy_localization

```dart
late final adapter = EasyLocalizationAdapter(
  supportedLocales: context.supportedLocales, // or your list
  currentLocale: context.locale,
  onLocaleChange: (locale) => context.setLocale(locale),
);
```

Wire `SwayOverlay(adapter: adapter, child: …)` the same way. Prefer creating the adapter where you already own locale state so the bubble stays in sync.

## Custom / slang / anything else

```dart
late final adapter = ManualAdapter(
  supportedLocales: const [Locale('en'), Locale('ar')],
  currentLocale: _locale,
  onLocaleChange: (locale) => setState(() => _locale = locale),
);
```

## Behavior notes

- Overlay is **debug/profile only** (`kReleaseMode` → no bubble). Use `SwayOverlay.disabled` to hard-off.
- Drag snaps to the nearest left/right edge.
- Force RTL / Force LTR preview layout with English (or any) text.
- Use **one shared adapter** instance for app + overlay so the language badge updates when Settings change locale.

## Later: adopt the full format

When you want nested JSON + `context.t`:

1. [MIGRATION.md](MIGRATION.md)
2. [INTEGRATION.md](INTEGRATION.md)
