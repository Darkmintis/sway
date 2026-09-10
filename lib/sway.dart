/// Sway — The localization layer for Flutter.
///
/// # Features
///
/// - **Format + codegen** — author nested JSON per locale, generate type-safe
///   Dart (`context.t.home.welcome(name: …)`). Run `dart run sway:codegen`.
/// - **Overlay** - debug floating bubble to switch locale / force RTL without
///   changing device settings. Prefer `Sway.debugOverlay` under
///   `MaterialApp.builder` for production shells; works with ARB /
///   easy_localization / slang via adapters.
/// - **Migrate CLI** — convert ARB, easy_localization, or slang into Sway JSON.
///
/// # Quick links
///
/// - Full integration: see the package README and `doc/INTEGRATION.md`
/// - Overlay-only (keep ARB): see `doc/OVERLAY_ONLY.md`
/// - Migration: see `doc/MIGRATION.md`
///
/// Tooling APIs that touch the filesystem live in `package:sway/codegen.dart`
/// (CLI / VM only — not needed in your Flutter app import).
library;

// Runtime-safe format helpers (no dart:io)
export 'src/format/exceptions.dart';
export 'src/format/plural_rules.dart';
export 'src/format/rtl_table.dart';

// Shared module
export 'src/shared/locale_meta.dart';

// Overlay module (depends on Flutter)
export 'src/overlay/sway_overlay.dart';
export 'src/overlay/debug_overlay.dart';
export 'src/overlay/locale_adapter.dart';
export 'src/overlay/overlay_controller.dart';
export 'src/overlay/force_rebuild_scope.dart';
