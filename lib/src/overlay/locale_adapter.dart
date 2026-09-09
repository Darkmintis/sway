/// Abstraction interface for the Overlay to read/write the current locale.
///
/// This allows the Overlay to work regardless of what localization system
/// actually powers the app (Sway format, ARB/intl, easy_localization,
/// slang, or manual setup).
library;

import 'package:flutter/widgets.dart';

/// Interface that the Sway overlay uses to interact with the host app's
/// localization system.
///
/// Adapters are [Listenable] so the overlay can auto-detect locale changes
/// made elsewhere in the app (settings screen, system, etc.).
abstract class SwayLocaleAdapter extends ChangeNotifier {
  /// Creates a [SwayLocaleAdapter].
  SwayLocaleAdapter();

  /// Returns the list of locales the app supports.
  List<Locale> get supportedLocales;

  /// Returns the currently active locale.
  Locale get currentLocale;

  /// Sets the active locale, triggering a rebuild if necessary.
  void setLocale(Locale locale);
}

/// Adapter for apps using Sway's own generated format.
class SwayFormatAdapter extends SwayLocaleAdapter {
  /// Callback invoked when the locale changes.
  final void Function(Locale locale) onLocaleChange;

  final List<Locale> _supportedLocales;
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
    notifyListeners();
  }
}

/// Adapter for apps using `easy_localization`.
class EasyLocalizationAdapter extends SwayLocaleAdapter {
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
    notifyListeners();
  }
}

/// Adapter for apps using Flutter gen-l10n / `intl` (ARB).
class IntlAdapter extends SwayLocaleAdapter {
  @override
  final List<Locale> supportedLocales;

  /// Callback to set the locale.
  final void Function(Locale locale) onLocaleChange;

  Locale _currentLocale;

  /// Creates an [IntlAdapter].
  IntlAdapter({
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
    notifyListeners();
  }
}

/// Adapter for apps using a custom localization setup.
class ManualAdapter extends SwayLocaleAdapter {
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
    notifyListeners();
  }
}
