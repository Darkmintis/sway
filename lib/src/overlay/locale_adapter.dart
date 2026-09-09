/// Abstraction interface for the Overlay to read/write the current locale.
///
/// This allows the Overlay to work regardless of what localization system
/// actually powers the app (Sway format, ARB/intl, easy_localization,
/// slang, or manual setup).
library;

import 'package:flutter/widgets.dart';

/// Interface that the Sway overlay uses to interact with the host app's
/// localization system.
abstract class SwayLocaleAdapter {
  /// Returns the list of locales the app supports.
  List<Locale> get supportedLocales;

  /// Returns the currently active locale.
  Locale get currentLocale;

  /// Sets the active locale, triggering a rebuild if necessary.
  void setLocale(Locale locale);
}

/// Adapter for apps using Sway's own generated format.
///
/// Auto-wired when `SwayTranslations` codegen output is present.
class SwayFormatAdapter implements SwayLocaleAdapter {
  /// Callback invoked when the locale changes.
  final void Function(Locale locale) onLocaleChange;

  /// The list of supported locales.
  final List<Locale> _supportedLocales;

  /// The current locale.
  Locale _currentLocale;

  /// Creates a [SwayFormatAdapter].
  SwayFormatAdapter({
    required List<Locale> supportedLocales,
    required Locale currentLocale,
    required this.onLocaleChange,
  })  : _supportedLocales = supportedLocales,
        _currentLocale = currentLocale;

  @override
  List<Locale> get supportedLocales => List.unmodifiable(_supportedLocales);

  @override
  Locale get currentLocale => _currentLocale;

  @override
  void setLocale(Locale locale) {
    if (_currentLocale == locale) return;
    _currentLocale = locale;
    onLocaleChange(locale);
  }
}

/// Adapter for apps using `easy_localization`.
///
/// Dev supplies the supported locales and a callback to set the locale.
class EasyLocalizationAdapter implements SwayLocaleAdapter {
  @override
  final List<Locale> supportedLocales;

  /// Callback to set the locale via easy_localization's context.
  final void Function(Locale locale) onLocaleChange;

  Locale _currentLocale;

  /// Creates an [EasyLocalizationAdapter].
  EasyLocalizationAdapter({
    required this.supportedLocales,
    required Locale currentLocale,
    required this.onLocaleChange,
  }) : _currentLocale = currentLocale;

  @override
  Locale get currentLocale => _currentLocale;

  @override
  void setLocale(Locale locale) {
    if (_currentLocale == locale) return;
    _currentLocale = locale;
    onLocaleChange(locale);
  }
}

/// Adapter for apps using a custom localization setup.
///
/// Dev supplies plain callbacks — covers any setup not handled by
/// the built-in adapters.
class ManualAdapter implements SwayLocaleAdapter {
  @override
  final List<Locale> supportedLocales;

  /// Callback to set the locale.
  final void Function(Locale locale) onLocaleChange;

  Locale _currentLocale;

  /// Creates a [ManualAdapter].
  ManualAdapter({
    required this.supportedLocales,
    required Locale currentLocale,
    required this.onLocaleChange,
  }) : _currentLocale = currentLocale;

  @override
  Locale get currentLocale => _currentLocale;

  @override
  void setLocale(Locale locale) {
    if (_currentLocale == locale) return;
    _currentLocale = locale;
    onLocaleChange(locale);
  }
}
