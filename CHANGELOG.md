# Changelog

All notable changes to this project will be documented in this file.

## [0.3.1] - 2026-09-29

### Changed

- Release builds (`enableInRelease: true`) mark the bubble with a red ring
  instead of the `SWAY ACTIVE` text tag, plus a
  "Sway active in release build" screen-reader label. The locale badge
  (EN, AR, …) is drawn above the ring so it stays readable.
- Bubble keeps a 12px gap from every edge inside the safe area (status bar,
  navigation bar, notches). Dragging is
  limited to that area too.
- Example app enables Sway in release builds to show the red ring.

### Fixed

- Bubble sometimes started in the top-left corner when the first frame
  reported a 0×0 screen; it now waits for the real size.

## [0.3.0] - 2026-09-28

### Added

- `enabled` and `enableInRelease` on `SwayOverlay` and `Sway.debugOverlay`,
  matching Mole and Ferret so one app flag can drive all three packages.
- Release builds can now run the overlay when `enableInRelease: true`. A red
  `SWAY ACTIVE` tag sits above the bubble and a console banner prints once.

### Changed

- The floating button now parks in the lower-middle band by default.

### Deprecated

- `disabled` on `SwayOverlay` / `Sway.debugOverlay`. Use `enabled: false`.
  `SwayOverlay.disabled(...)` is still supported.

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
