/// VM-only codegen and format tooling.
///
/// Apps should import `package:sway/sway.dart` (overlay + plurals).
/// The `dart run sway:codegen` / `sway:migrate` CLIs use these APIs via
/// `package:sway/src/...` or this library. Not WASM-safe (`dart:io`).
library;

export 'src/format/locale_file.dart';
export 'src/format/exceptions.dart';
export 'src/format/validator.dart';
export 'src/format/plural_rules.dart';
export 'src/format/rtl_table.dart';

export 'src/codegen/config.dart';
export 'src/codegen/emitter.dart';
export 'src/codegen/schema_diff.dart';
