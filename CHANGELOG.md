# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-09-09

### Added

- Format module: JSON locale parser, cross-locale validator, CLDR plural rules, RTL table.
- Codegen CLI (`dart run sway:codegen`): nested type-safe Dart, `resolvePlural`, multi-file output (`sway.g.dart` + `sway_<locale>.g.dart`).
- `SwayScope` + `context.t` / `context.sway` / `SwayTranslations.of(context)` / `forLocale`.
- `sway.config.json` for `baseLocale`, `localeDir`, `outputFile`, `fallbackStrategy`.
- Overlay: edge-snapping bubble, Force RTL/LTR, locale search when >8 locales, adapter sync, release gating.
- Adapters: `SwayFormatAdapter`, `IntlAdapter`, `EasyLocalizationAdapter`, `ManualAdapter`.
- Migration CLI (`dart run sway:migrate`) for ARB, easy_localization (JSON), and slang.
- Example app with six locales and docs under `doc/`.
- Overlay-only path documented for ARB / easy_localization / slang (`doc/OVERLAY_ONLY.md`).

### Fixed

- ARB migrate maps ICU exact plurals `=0` / `=1` / `=2` → `zero` / `one` / `two` so codegen accepts the output.

### Known limitations

- No `build_runner` Builder yet (CLI codegen only).
- easy_localization YAML/CSV migrate requires JSON first (no extra deps in 0.1.0).
- Filesystem tooling lives in `package:sway/codegen.dart` (CLI / VM); app import is `package:sway/sway.dart`.
