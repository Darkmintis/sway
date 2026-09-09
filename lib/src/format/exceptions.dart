/// Exception types for Sway format parsing and validation errors.
library;

/// Base exception for all Sway format-related errors.
abstract class SwayFormatException implements Exception {
  /// Human-readable error message.
  final String message;

  /// Path to the file that caused the error, if applicable.
  final String? filePath;

  /// Creates a [SwayFormatException].
  const SwayFormatException(this.message, {this.filePath});

  @override
  String toString() {
    final buffer = StringBuffer('SwayFormatException: ');
    buffer.write(message);
    if (filePath != null) buffer.write(' (in $filePath)');
    return buffer.toString();
  }
}

/// Thrown when a locale file contains invalid JSON syntax.
class SwayJsonParseException extends SwayFormatException {
  /// Line number where the parse error occurred (1-indexed).
  final int? line;

  /// Column number where the parse error occurred (1-indexed).
  final int? column;

  /// Creates a [SwayJsonParseException].
  const SwayJsonParseException(
    super.message, {
    super.filePath,
    this.line,
    this.column,
  });

  @override
  String toString() {
    final buffer = StringBuffer('SwayJsonParseException: $message');
    if (filePath != null) buffer.write(' (in $filePath)');
    if (line != null) {
      buffer.write(' at line $line');
      if (column != null) buffer.write(', column $column');
    }
    return buffer.toString();
  }
}

/// Thrown when a locale file has non-UTF8 encoding.
class SwayEncodingException extends SwayFormatException {
  /// Creates a [SwayEncodingException].
  const SwayEncodingException(
    super.message, {super.filePath});
}

/// Thrown when validation detects a schema violation.
class SwayValidationException extends SwayFormatException {
  /// List of individual validation errors found.
  final List<String> errors;

  /// Creates a [SwayValidationException].
  const SwayValidationException(
    super.message, {
    super.filePath,
    required this.errors,
  });

  @override
  String toString() {
    final buffer = StringBuffer('SwayValidationException: $message');
    if (filePath != null) buffer.write(' (in $filePath)');
    buffer.writeln();
    for (final error in errors) {
      buffer.writeln('  - $error');
    }
    return buffer.toString();
  }
}

/// Thrown when codegen encounters an unrecoverable error.
class SwayCodegenException extends SwayFormatException {
  /// Creates a [SwayCodegenException].
  const SwayCodegenException(
    super.message, {super.filePath});
}
