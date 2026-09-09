# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-09-09

### Added

- **Format module**: JSON locale parser, cross-locale validator, CLDR plural rules, RTL table.
- **Codegen CLI**: `dart run sway:codegen` emits nested type-safe Dart (`t.home.welcome`, `t.home.itemCount(count:)`) with `resolvePlural`, `SwayTranslations.of`, and `supportedLocales`.
- **Multi-file output**: main `sway.g.dart` + per-locale `sway_<lang>.g.dart` parts (ARB / gen-l10n style).
- **`sway.config.json`**: `baseLocale`, `localeDir`, `outputFile`, `fallbackStrategy`.
- **Overlay**: draggable edge-snapping bubble, Force RTL/LTR preview, locale search when >8 locales, release-mode gating, loud misconfiguration errors.
- **Adapters**: `SwayFormatAdapter`, `ManualAdapter`, `EasyLocalizationAdapter`, `IntlAdapter`.
- **Migration CLI**: `dart run sway:migrate` for ARB (ICU plurals → objects), easy_localization (JSON), and slang; flags unconvertible ICU/`select`.
- **Example app**: en, ar, es, de, ja, he with interactive plural demo and overlay.

### Known limitations (tracked for 0.1.1)

- No `build_runner` Builder yet (CLI codegen only).
- easy_localization YAML/CSV migrate requires converting to JSON first (no extra deps).
- Not every master-plan edge-case row has a dedicated named test yet.
- Format module still ships under the Flutter package (not a pure-Dart split).

## Test floor

Unit/widget/CLI coverage for format, nested codegen (incl. golden), overlay drag/Force RTL, and migrate fixtures.
