# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-09-09

### Added

- **Format module**: JSON-based locale file parser with validation, CLDR plural rules, RTL table, and comprehensive error types.
- **Codegen CLI**: `dart run sway:codegen` — generates type-safe Dart classes from `.sway.json` files with namespace support, placeholder parameters, and RTL flags.
- **Overlay module**: Floating draggable debug widget for instant locale switching and RTL/LTR force-preview, gated to debug/profile builds only.
- **Migration CLI**: `dart run sway:migrate` for converting ARB, easy_localization, and slang formats to Sway's format.
- **Shared module**: Locale metadata with auto-RTL detection.
- Example app with English + Arabic locale files demonstrating all features.
- 53 unit tests covering format, codegen, overlay, and shared modules.
