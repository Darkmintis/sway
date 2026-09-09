# Sway example

Demo app for the [sway](https://pub.dev/packages/sway) localization package.

Shows nested type-safe translations, CLDR plurals, RTL (Arabic + Hebrew), and the
draggable debug overlay.

## Run

```bash
# From the package root — regenerate if you edit *.sway.json
# Writes sway.g.dart + sway_en.g.dart, sway_ar.g.dart, …
dart run sway:codegen --config example/lib/i18n/sway.config.json

cd example
flutter run
```

## Locales

`en`, `ar`, `es`, `de`, `ja`, `he`

Use the floating button to switch locales or force RTL/LTR preview.
