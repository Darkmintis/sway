/// Sway — The localization layer for Flutter.
///
/// Simple to author, instant to test, painless to migrate into.
library;

// Format module (pure Dart, no Flutter dependency)
export 'src/format/locale_file.dart';
export 'src/format/exceptions.dart';
export 'src/format/validator.dart';
export 'src/format/plural_rules.dart';
export 'src/format/rtl_table.dart';

// Shared module
export 'src/shared/locale_meta.dart';

// Overlay module (depends on Flutter)
export 'src/overlay/sway_overlay.dart';
export 'src/overlay/locale_adapter.dart';
export 'src/overlay/overlay_controller.dart';
export 'src/overlay/force_rebuild_scope.dart';
