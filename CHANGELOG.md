# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - 2026-09-10

### Added

- `Sway.debugOverlay` - nested Overlay host for `MaterialApp.builder` (no app-owned host).
- `ListenableLocaleAdapter` - bridge GetIt / ChangeNotifier / ValueNotifier locale owners.
- `debugOnly` on `SwayOverlay` / `Sway.debugOverlay` - gate on `kDebugMode` (profile can hide the bubble).
- Long-press the floating button to hide it until hot reload / hot restart.
- Tap opens the locale panel immediately (no double-tap delay).
- Bubble edge position remembered across hot reload (process-local).
- Overlay-only docs rewritten for Stateless + builder as the production default.

### Changed

- Overlay-only is the supported production path in 0.2.x; full ARB → Sway JSON remains early.

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
- easy_localization YAML/CSV migrate requires JSON first (no extra deps).
- Filesystem tooling lives in `package:sway/codegen.dart` (CLI / VM); app import is `package:sway/sway.dart`.
