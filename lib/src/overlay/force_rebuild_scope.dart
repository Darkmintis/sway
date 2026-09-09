/// Widget that forces a full rebuild of its subtree when locale changes.
///
/// This guarantees every descendant re-reads the new locale and direction
/// with no stale cache possible — more aggressive than typical rebuilds,
/// but correctness in a testing tool matters more than rebuild efficiency.
library;

import 'package:flutter/widgets.dart';

/// Wraps the app's `MaterialApp`/`WidgetsApp` to guarantee a full
/// `Localizations` + `Directionality` remount on locale change.
///
/// Use a [ValueKey] derived from `(locale, forcedDirection)` — updating
/// that key destroys and remounts the entire subtree.
class ForceRebuildScope extends StatefulWidget {
  /// The child widget tree to wrap.
  final Widget child;

  /// The current locale — changing this triggers a full remount.
  final Locale locale;

  /// Whether to force RTL directionality regardless of locale.
  final bool forceRtl;

  /// Whether to force LTR directionality regardless of locale.
  final bool forceLtr;

  /// Creates a [ForceRebuildScope].
  const ForceRebuildScope({
    super.key,
    required this.child,
    required this.locale,
    this.forceRtl = false,
    this.forceLtr = false,
  });

  @override
  State<ForceRebuildScope> createState() => _ForceRebuildScopeState();
}

class _ForceRebuildScopeState extends State<ForceRebuildScope> {
  @override
  Widget build(BuildContext context) {
    final direction = widget.forceRtl
        ? TextDirection.rtl
        : widget.forceLtr
            ? TextDirection.ltr
            : _directionForLocale(widget.locale);

    // Key forces full remount on any locale/direction change
    return KeyedSubtree(
      key: ValueKey('sway-${widget.locale}-${widget.forceRtl}-${widget.forceLtr}'),
      child: Directionality(
        textDirection: direction,
        child: widget.child,
      ),
    );
  }

  TextDirection _directionForLocale(Locale locale) {
    const rtlCodes = {'ar', 'he', 'fa', 'ur', 'ps', 'sd', 'yi', 'dv', 'ckb'};
    return rtlCodes.contains(locale.languageCode.toLowerCase())
        ? TextDirection.rtl
        : TextDirection.ltr;
  }
}
