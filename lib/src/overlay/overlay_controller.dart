/// Controller for the Sway overlay's locale-switching state.
library;

import 'package:flutter/widgets.dart';

import 'locale_adapter.dart';

/// Manages the overlay's state: current locale, force RTL/LTR flags,
/// expanded/collapsed state, and bubble position.
class OverlayController extends ChangeNotifier {
  final SwayLocaleAdapter _adapter;

  Locale _forcedLocale;
  bool _forceRtl;
  bool _forceLtr;
  bool _isExpanded;

  /// Creates an [OverlayController].
  OverlayController({
    required SwayLocaleAdapter adapter,
    Locale? initialLocale,
    bool forceRtl = false,
    bool forceLtr = false,
  })  : _adapter = adapter,
        _forcedLocale = initialLocale ?? adapter.currentLocale,
        _forceRtl = forceRtl,
        _forceLtr = forceLtr,
        _isExpanded = false;

  /// The currently selected locale (may differ from adapter's actual locale
  /// if the overlay is forcing a different one).
  Locale get currentLocale => _forcedLocale;

  /// Whether RTL is being forced.
  bool get forceRtl => _forceRtl;

  /// Whether LTR is being forced.
  bool get forceLtr => _forceLtr;

  /// Whether the overlay panel is expanded.
  bool get isExpanded => _isExpanded;

  /// The adapter providing locale support.
  SwayLocaleAdapter get adapter => _adapter;

  /// All locales supported by the adapter.
  List<Locale> get supportedLocales => _adapter.supportedLocales;

  /// Switches to a different locale.
  void setLocale(Locale locale) {
    if (_forcedLocale == locale) return;
    _forcedLocale = locale;
    _adapter.setLocale(locale);
    notifyListeners();
  }

  /// Toggles the expanded/collapsed state of the overlay panel.
  void toggleExpanded() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }

  /// Collapses the overlay panel.
  void collapse() {
    if (!_isExpanded) return;
    _isExpanded = false;
    notifyListeners();
  }

  /// Forces RTL directionality preview.
  void setForceRtl(bool value) {
    _forceRtl = value;
    if (value) _forceLtr = false;
    notifyListeners();
  }

  /// Forces LTR directionality preview.
  void setForceLtr(bool value) {
    _forceLtr = value;
    if (value) _forceRtl = false;
    notifyListeners();
  }

  /// Clears any forced directionality, reverting to locale-based direction.
  void clearForceDirection() {
    _forceRtl = false;
    _forceLtr = false;
    notifyListeners();
  }
}
