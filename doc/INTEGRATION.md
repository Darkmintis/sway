# Integrating Sway

This guide covers the **full** Sway path: JSON locales → codegen → `context.t` → optional overlay.

If you only want the floating locale switcher on top of ARB / easy_localization / slang, read [OVERLAY_ONLY.md](OVERLAY_ONLY.md) instead.

## 1. Add the package

```bash
dart pub add sway
```

## 2. Author locale files

Create one file per language under `lib/i18n/` (default):

```
lib/i18n/
  en.sway.json      # base locale
  ar.sway.json
  sway.config.json  # optional
```

Example `en.sway.json`:

```json
{
  "home": {
    "welcome": "Welcome, {name}!",
    "itemCount": {
      "one": "{count} item",
      "other": "{count} items"
    }
  },
  "settings": {
    "title": "Settings",
    "language": "Language"
  }
}
```

Rules:

- Keys must be valid Dart identifiers (`^[a-zA-Z][a-zA-Z0-9_]*$`).
- Nesting matches the generated API (`home.welcome` → `t.home.welcome`).
- Plural objects use CLDR categories; `other` is required.
- Placeholders use `{name}` syntax.

## 3. Optional config

`lib/i18n/sway.config.json`:

```json
{
  "baseLocale": "en",
  "localeDir": "lib/i18n",
  "outputFile": "lib/i18n/sway.g.dart",
  "fallbackStrategy": "baseLocale"
}
```

## 4. Generate code

```bash
dart run sway:codegen
```

Output (gen-l10n style):

```
lib/i18n/sway.g.dart       # import this
lib/i18n/sway_en.g.dart
lib/i18n/sway_ar.g.dart
```

Re-run after every locale edit. Commit generated files **or** regenerate in CI — pick one team convention.

## 5. Wire `MaterialApp`

```dart
final translations = SwayTranslations.forLocale(_locale);

return MaterialApp(
  locale: _locale,
  supportedLocales: SwayTranslations.supportedLocales,
  home: SwayScope(
    translations: translations,
    child: SwayOverlay(
      adapter: adapter, // SwayFormatAdapter
      child: const HomePage(),
    ),
  ),
);
```

## 6. Use strings

```dart
final t = context.t;

Text(t.home.welcome(name: 'Dipesh'));
Text(t.home.itemCount(count: items.length));
Text(t.settings.title);
```

Equivalents:

- `SwayTranslations.of(context)`
- `context.sway`
- `SwayTranslations.forLocale(locale)` (no `BuildContext`)

## 7. Adapter for the overlay

```dart
late final adapter = SwayFormatAdapter(
  supportedLocales: SwayTranslations.supportedLocales,
  currentLocale: _locale,
  onLocaleChange: (locale) => setState(() => _locale = locale),
);
```

Use **one** adapter instance for both the app and `SwayOverlay` so the bubble badge stays in sync.

## 8. Coming from ARB / another library

1. Migrate with `dart run sway:migrate` — see [MIGRATION.md](MIGRATION.md).
2. Run codegen.
3. Replace `AppLocalizations.of(context)!.…` with `context.t.…` gradually.

Or keep your existing system and only add the overlay — [OVERLAY_ONLY.md](OVERLAY_ONLY.md).
