# Overlay only (ARB / easy_localization / slang)

Use Sway's floating locale switcher **without** adopting Sway JSON or codegen.

This is the zero-commitment entry point: keep `AppLocalizations`, `easy_localization`, or slang, and add a debug bubble for instant locale + RTL preview.

**Stability (0.2.x):** overlay-only is the supported production path. Full ARB → Sway JSON remains early - evaluate separately.

## Install

```bash
dart pub add sway
```

You only need the overlay. You do **not** run `sway:codegen` unless you later migrate.

## Recommended: Stateless app + `MaterialApp.builder`

Most production apps use `onGenerateRoute` / Stacked / GetIt and put chrome in `MaterialApp.builder`. Use `Sway.debugOverlay` - it owns a nested `Overlay` and bridges your locale service:

```dart
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeService = locator<AppLocaleService>(); // ChangeNotifier / Listenable
    return MaterialApp(
      locale: localeService.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      onGenerateRoute: /* your router */,
      builder: (context, child) => Sway.debugOverlay(
        localeListenable: localeService,
        getLocale: () => localeService.locale,
        setLocale: localeService.setLocale,
        supportedLocales: AppLocalizations.supportedLocales,
        debugOnly: true, // hide in profile builds
        child: child!,
      ),
    );
  }
}
```

No custom adapter class. No `DebugSwayOverlayHost`. `MainApp` stays Stateless.

### Provider

```dart
builder: (context, child) {
  final locale = context.watch<LocaleProvider>();
  return Sway.debugOverlay(
    localeListenable: locale,
    getLocale: () => locale.locale,
    setLocale: locale.setLocale,
    supportedLocales: AppLocalizations.supportedLocales,
    child: child!,
  );
},
```

### Riverpod (`ValueNotifier` / `Notifier`)

Expose a `Listenable` (e.g. `ValueNotifier<Locale>`) from your provider, then:

```dart
builder: (context, child) {
  final listenable = ref.watch(localeListenableProvider);
  return Sway.debugOverlay(
    localeListenable: listenable,
    getLocale: () => listenable.value,
    setLocale: (l) => listenable.value = l,
    supportedLocales: AppLocalizations.supportedLocales,
    child: child!,
  );
},
```

### Already have a custom adapter?

```dart
builder: (context, child) => Sway.debugOverlay(
  adapter: myAdapter,
  child: child!,
),
```

## Minimal tutorial: StatefulWidget + `home:`

Fine for demos. Prefer the builder path above for production.

```dart
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
        child: const HomePage(),
      ),
    );
  }
}
```

`IntlAdapter` keeps its own copy of the locale - it does **not** attach to GetIt by itself. Use `ListenableLocaleAdapter` / `Sway.debugOverlay` for service-owned locale.

## Overlay controls

| Gesture | Effect |
|---------|--------|
| Drag | Move bubble; snaps to left/right edge |
| Tap | Open locale + Force RTL/LTR panel |
| Long-press | Hide bubble until hot reload / hot restart |

| Flag | Meaning |
|------|---------|
| `debugOnly: true` | Show only in debug (`kDebugMode`) |
| default | Show in debug + profile (`!kReleaseMode`) |
| `disabled: true` / release | No bubble |

Bubble edge position is remembered across hot reload in-process (not across a full process kill).

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| No bubble under `builder` | Use `Sway.debugOverlay`, not bare `SwayOverlay` (needs nested Overlay) |
| Badge stale after Settings change | Share one listenable owner via `Sway.debugOverlay` / `ListenableLocaleAdapter` |
| Bubble in profile builds | Pass `debugOnly: true` |
| "Sway broke my strings" | Remount does not fix `static final` baked translations or forced `textDirection` - fix those in app code |

## easy_localization / slang

Same `Sway.debugOverlay` pattern: point `getLocale` / `setLocale` / `localeListenable` at whatever owns the active locale. Or pass `EasyLocalizationAdapter` / `ManualAdapter` via `adapter:`.
