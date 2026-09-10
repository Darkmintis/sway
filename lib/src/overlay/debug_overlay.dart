/// Production-friendly debug overlay for [MaterialApp.builder].
///
/// Owns a nested [Overlay] so the floating bubble works above the navigator
/// (where `MaterialApp.builder` sits outside the navigator's Overlay).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'locale_adapter.dart';
import 'sway_overlay.dart';

/// Namespace for Sway convenience APIs.
class Sway {
  Sway._();

  /// One-liner for production shells: nest an [Overlay], bridge a listenable
  /// locale owner, and show the debug bubble.
  ///
  /// Typical use under [MaterialApp.builder]:
  /// ```dart
  /// builder: (context, child) => Sway.debugOverlay(
  ///   localeListenable: locator<AppLocaleService>(),
  ///   getLocale: () => locator<AppLocaleService>().locale,
  ///   setLocale: locator<AppLocaleService>().setLocale,
  ///   supportedLocales: AppLocalizations.supportedLocales,
  ///   child: child!,
  /// ),
  /// ```
  ///
  /// Pass [adapter] to use a custom [SwayLocaleAdapter] instead of building a
  /// [ListenableLocaleAdapter] from the get/set/listenable args.
  static Widget debugOverlay({
    Key? key,
    required Widget child,
    Listenable? localeListenable,
    Locale Function()? getLocale,
    void Function(Locale locale)? setLocale,
    List<Locale>? supportedLocales,
    SwayLocaleAdapter? adapter,
    bool debugOnly = false,
    bool disabled = false,
  }) {
    assert(
      adapter != null ||
          (localeListenable != null &&
              getLocale != null &&
              setLocale != null &&
              supportedLocales != null),
      'Sway.debugOverlay requires either an adapter, or '
      'localeListenable + getLocale + setLocale + supportedLocales.',
    );

    if (kReleaseMode || disabled) return child;
    if (debugOnly && !kDebugMode) return child;

    return _SwayDebugOverlayHost(
      key: key,
      localeListenable: localeListenable,
      getLocale: getLocale,
      setLocale: setLocale,
      supportedLocales: supportedLocales,
      adapter: adapter,
      debugOnly: debugOnly,
      disabled: disabled,
      child: child,
    );
  }
}

class _SwayDebugOverlayHost extends StatefulWidget {
  final Widget child;
  final Listenable? localeListenable;
  final Locale Function()? getLocale;
  final void Function(Locale locale)? setLocale;
  final List<Locale>? supportedLocales;
  final SwayLocaleAdapter? adapter;
  final bool debugOnly;
  final bool disabled;

  const _SwayDebugOverlayHost({
    super.key,
    required this.child,
    this.localeListenable,
    this.getLocale,
    this.setLocale,
    this.supportedLocales,
    this.adapter,
    required this.debugOnly,
    required this.disabled,
  });

  @override
  State<_SwayDebugOverlayHost> createState() => _SwayDebugOverlayHostState();
}

class _SwayDebugOverlayHostState extends State<_SwayDebugOverlayHost> {
  SwayLocaleAdapter? _ownedAdapter;
  late SwayLocaleAdapter _adapter;
  late final OverlayEntry _entry;

  @override
  void initState() {
    super.initState();
    _bindAdapter();
    _entry = OverlayEntry(builder: _buildEntry);
  }

  @override
  void didUpdateWidget(_SwayDebugOverlayHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldRebind = widget.adapter != oldWidget.adapter ||
        widget.localeListenable != oldWidget.localeListenable ||
        widget.getLocale != oldWidget.getLocale ||
        widget.setLocale != oldWidget.setLocale ||
        !listEquals(widget.supportedLocales, oldWidget.supportedLocales);
    if (shouldRebind) {
      _ownedAdapter?.dispose();
      _ownedAdapter = null;
      _bindAdapter();
    }
    _entry.markNeedsBuild();
  }

  void _bindAdapter() {
    if (widget.adapter != null) {
      _adapter = widget.adapter!;
      return;
    }
    _ownedAdapter = ListenableLocaleAdapter(
      localeListenable: widget.localeListenable!,
      getLocale: widget.getLocale!,
      setLocale: widget.setLocale!,
      supportedLocales: widget.supportedLocales!,
    );
    _adapter = _ownedAdapter!;
  }

  Widget _buildEntry(BuildContext context) {
    return SwayOverlay(
      adapter: _adapter,
      debugOnly: widget.debugOnly,
      disabled: widget.disabled,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _ownedAdapter?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Nested Overlay so SwayOverlay can insert entries under MaterialApp.builder.
    return Overlay(initialEntries: [_entry]);
  }
}
