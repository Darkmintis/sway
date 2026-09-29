library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../shared/locale_meta.dart';
import 'force_rebuild_scope.dart';
import 'locale_adapter.dart';
import 'overlay_controller.dart';
import 'sway_activation.dart';

const double _kBubbleSize = 48;
const double _kEdgeMargin = 12;
const double _kPanelWidth = 200;
const double _kDragTapSlop = 8;
const Duration _kLongPressHide = Duration(milliseconds: 450);

/// Default Y: fraction from vertical-center toward the bottom safe edge.
/// Keeps the bubble in the lower-middle band (below Ferret, above the lip).
const double _kDefaultLowerBand = 0.55;

/// ponytail: process-local only (survives hot reload, not process kill).
/// Upgrade: shared_preferences if QA needs cross-process restore.
Offset? _persistedBubblePosition;

/// A floating, draggable locale-switching overlay for development.
///
/// Shows a persistent floating button. Tap to open a language picker
/// panel anchored near the button. Drag snaps to the nearest screen edge.
/// Long-press hides the bubble until hot reload / hot restart.
/// Includes Force RTL / Force LTR preview toggles.
///
/// Active in debug and profile by default. Off in release builds unless
/// [enableInRelease] is `true`, in which case a red border on the bubble and a
/// console banner make it obvious. [enabled] is the master switch.
/// Pass [debugOnly] to also hide the bubble in profile builds.
class SwayOverlay extends StatefulWidget {
  /// The child widget tree. Typically wraps content under a [MaterialApp]
  /// route so an [Overlay] ancestor exists, or use `Sway.debugOverlay` under
  /// [MaterialApp.builder] (nested Overlay host).
  final Widget child;

  /// The adapter providing locale support.
  ///
  /// Required when the overlay is enabled. Omitting it in debug throws
  /// a clear [FlutterError] instead of rendering a silent no-op.
  final SwayLocaleAdapter? adapter;

  /// Master switch. `false` renders no button in any build mode.
  final bool enabled;

  /// Opt in to release builds. Draws a red border around the bubble and prints a
  /// console banner so it can't ship to users by accident.
  final bool enableInRelease;

  /// Whether the overlay is completely disabled (no button rendered).
  @Deprecated('Use enabled: false. Will be removed in 1.0.0.')
  final bool disabled;

  /// When true, show only in debug builds (`kDebugMode`), hiding the bubble
  /// in profile (and release) builds.
  final bool debugOnly;

  /// Creates a [SwayOverlay].
  const SwayOverlay({
    super.key,
    required this.child,
    this.adapter,
    this.enabled = true,
    this.enableInRelease = false,
    @Deprecated('Use enabled: false. Will be removed in 1.0.0.')
    this.disabled = false,
    this.debugOnly = false,
  });

  /// Creates a disabled [SwayOverlay] (no button rendered).
  const SwayOverlay.disabled({super.key, required this.child})
      : adapter = null,
        enabled = false,
        enableInRelease = false,
        disabled = true,
        debugOnly = false;

  @override
  State<SwayOverlay> createState() => _SwayOverlayState();

  /// Forgets the remembered bubble position (tests only).
  @visibleForTesting
  static void clearPersistedPositionForTest() =>
      _persistedBubblePosition = null;
}

class _SwayOverlayState extends State<SwayOverlay> {
  OverlayController? _controller;
  OverlayEntry? _buttonEntry;
  OverlayEntry? _listEntry;
  Offset? _position;
  double _dragDistance = 0;
  String _searchQuery = '';
  bool _missingAdapterReported = false;
  bool _userHidden = false;
  Timer? _longPressTimer;

  SwayActivation get _activation => SwayActivation.resolve(
        // ignore: deprecated_member_use_from_same_package
        enabled: widget.enabled && !widget.disabled,
        enableInRelease: widget.enableInRelease,
        debugOnly: widget.debugOnly,
      );

  bool get _modeAllowsOverlay => _activation.active;

  bool get _active =>
      _modeAllowsOverlay && widget.adapter != null && !_userHidden;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload restores a long-press-hidden bubble.
    if (_userHidden) {
      _userHidden = false;
      _teardownOverlay();
      _initController();
    }
  }

  @override
  void didUpdateWidget(SwayOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.adapter != oldWidget.adapter ||
        widget.enabled != oldWidget.enabled ||
        widget.enableInRelease != oldWidget.enableInRelease ||
        // ignore: deprecated_member_use_from_same_package
        widget.disabled != oldWidget.disabled ||
        widget.debugOnly != oldWidget.debugOnly) {
      _teardownOverlay();
      _initController();
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _teardownOverlay();
    super.dispose();
  }

  void _teardownOverlay() {
    _removeList();
    _buttonEntry?.remove();
    _buttonEntry = null;
    _controller?.removeListener(_onChanged);
    _controller?.dispose();
    _controller = null;
  }

  void _initController() {
    if (!_modeAllowsOverlay || _userHidden) return;
    if (_activation.showReleaseWarning) {
      SwayActivation.printReleaseWarningOnce();
    }

    if (widget.adapter == null) {
      if (!_missingAdapterReported) {
        _missingAdapterReported = true;
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: FlutterError(
              'SwayOverlay requires an adapter when enabled.\n'
              'Pass SwayFormatAdapter, ListenableLocaleAdapter, ManualAdapter, '
              'EasyLocalizationAdapter, or IntlAdapter — or use '
              'Sway.debugOverlay / SwayOverlay.disabled.',
            ),
            library: 'sway',
            context: ErrorDescription('while initializing SwayOverlay'),
          ),
        );
      }
      return;
    }

    _controller = OverlayController(adapter: widget.adapter!);
    _controller!.addListener(_onChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_active || _buttonEntry != null) return;
      final overlay = Overlay.maybeOf(context);
      if (overlay == null) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: FlutterError(
              'SwayOverlay could not find an Overlay ancestor.\n'
              'Place it under MaterialApp (e.g. as home), or use '
              'Sway.debugOverlay under MaterialApp.builder.',
            ),
            library: 'sway',
          ),
        );
        return;
      }
      _ensurePosition(MediaQuery.of(context));
      _buttonEntry = OverlayEntry(builder: _buildButton);
      overlay.insert(_buttonEntry!);
    });
  }

  /// Top-left bounds: [_kEdgeMargin] from every edge, inside the safe area
  /// (status bar, navigation bar, notches) — same rule as Mole and Ferret.
  Rect _bounds(MediaQueryData media) {
    final pad = media.padding;
    return Rect.fromLTRB(
      pad.left + _kEdgeMargin,
      pad.top + _kEdgeMargin,
      media.size.width - pad.right - _kBubbleSize - _kEdgeMargin,
      media.size.height - pad.bottom - _kBubbleSize - _kEdgeMargin,
    );
  }

  Offset _clampToBounds(Offset offset, MediaQueryData media) {
    final b = _bounds(media);
    return Offset(
      offset.dx.clamp(b.left, b.right),
      offset.dy.clamp(b.top, b.bottom),
    );
  }

  void _ensurePosition(MediaQueryData media) {
    // The first frame can report a 0×0 screen; a default computed from it
    // would pin the bubble top-left forever. Wait for a real size.
    if (_position != null || media.size.isEmpty) return;
    final saved = _persistedBubblePosition;
    if (saved != null) {
      _position = _clampToBounds(saved, media);
      return;
    }
    final b = _bounds(media);
    final center = (b.top + b.bottom) / 2;
    _position = Offset(
      b.right,
      center + (b.bottom - center) * _kDefaultLowerBand,
    );
  }

  void _persistPosition() {
    if (_position != null) {
      _persistedBubblePosition = _position;
    }
  }

  void _hideBubble() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _removeList();
    _userHidden = true;
    _teardownOverlay();
    if (mounted) setState(() {});
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    _buttonEntry?.markNeedsBuild();
    _listEntry?.markNeedsBuild();
  }

  void _markOverlayDirty() {
    _buttonEntry?.markNeedsBuild();
    _listEntry?.markNeedsBuild();
  }

  void _toggleList() {
    if (_listEntry != null) {
      _removeList();
      return;
    }
    _searchQuery = '';
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    _listEntry = OverlayEntry(builder: _buildList);
    overlay.insert(_listEntry!);
  }

  void _removeList() {
    _listEntry?.remove();
    _listEntry = null;
  }

  void _onPanStart(DragStartDetails details) {
    _dragDistance = 0;
    _longPressTimer?.cancel();
    _longPressTimer = Timer(_kLongPressHide, () {
      if (_dragDistance < _kDragTapSlop && mounted && !_userHidden) {
        _hideBubble();
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final media = MediaQuery.of(context);
    _ensurePosition(media);
    if (_position == null) return;
    _dragDistance += details.delta.distance;
    if (_dragDistance >= _kDragTapSlop) {
      _longPressTimer?.cancel();
      _longPressTimer = null;
    }
    _position = _clampToBounds(_position! + details.delta, media);
    _markOverlayDirty();
  }

  void _onPanEnd(DragEndDetails details) {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    if (!mounted || _userHidden || !_active) return;

    final media = MediaQuery.of(context);
    _ensurePosition(media);
    if (_position == null) return;
    final b = _bounds(media);
    final snapLeft = _position!.dx + _kBubbleSize / 2 < media.size.width / 2;
    _position = _clampToBounds(
      Offset(snapLeft ? b.left : b.right, _position!.dy),
      media,
    );
    _persistPosition();
    _markOverlayDirty();

    if (_dragDistance < _kDragTapSlop) {
      _toggleList();
    }
  }

  Widget _buildButton(BuildContext context) {
    final media = MediaQuery.of(context);
    _ensurePosition(media);
    if (_position == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final locale = _controller?.currentLocale;
    final code = (locale?.languageCode ?? '?').toUpperCase();
    final bubble = _buildBubble(theme, code, _activation.showReleaseWarning);
    final at = _clampToBounds(_position!, media);

    return Positioned(
      left: at.dx,
      top: at.dy,
      child: _activation.showReleaseWarning
          ? Semantics(label: 'Sway active in release build', child: bubble)
          : bubble,
    );
  }

  Widget _buildBubble(ThemeData theme, String code, bool releaseBorder) {
    // The locale badge sits outside the Material so the release border
    // (painted on the Material's foreground) never covers it.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          elevation: 6,
          shadowColor: Colors.black54,
          shape: CircleBorder(
            side: releaseBorder
                ? const BorderSide(color: Color(0xFFB3261E), width: 3)
                : BorderSide.none,
          ),
          color: theme.colorScheme.primary,
          child: SizedBox(
            width: _kBubbleSize,
            height: _kBubbleSize,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Center(
                child: Icon(
                  Icons.translate_rounded,
                  size: 22,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 4,
          bottom: 4,
          child: IgnorePointer(
            child: Container(
              key: const ValueKey('sway-locale-badge'),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                code.length > 2 ? code.substring(0, 2) : code,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    if (_controller == null) return const SizedBox.shrink();
    final controller = _controller!;
    final locales = controller.supportedLocales;
    final filtered = _searchQuery.isEmpty
        ? locales
        : locales.where((l) {
            final name = SwayLocaleMeta.fromLanguageCode(
              l.languageCode,
            ).displayName.toLowerCase();
            final q = _searchQuery.toLowerCase();
            return name.contains(q) || l.languageCode.contains(q);
          }).toList();
    final screen = MediaQuery.sizeOf(context);
    final showSearch = locales.length > 8;
    final panelHeight = (showSearch ? 56.0 : 0) +
        52 + // force toggles
        (filtered.length * 48.0).clamp(48.0, screen.height * 0.35) +
        8;

    final listLeft = (_position!.dx).clamp(
      _kEdgeMargin,
      screen.width - _kPanelWidth - _kEdgeMargin,
    );
    final preferAbove = _position!.dy > panelHeight + 16;
    final listTop = preferAbove
        ? (_position!.dy - 8 - panelHeight).clamp(
            _kEdgeMargin,
            screen.height - panelHeight - _kEdgeMargin,
          )
        : (_position!.dy + _kBubbleSize + 8).clamp(
            _kEdgeMargin,
            screen.height - panelHeight - _kEdgeMargin,
          );

    final theme = Theme.of(context);

    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _removeList,
          child: const SizedBox.expand(),
        ),
        Positioned(
          left: listLeft,
          top: listTop,
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            color: theme.colorScheme.surface,
            child: SizedBox(
              width: _kPanelWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showSearch)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                      child: TextField(
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Filter locales',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (v) {
                          _searchQuery = v;
                          _listEntry?.markNeedsBuild();
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ForceChip(
                            label: 'Force RTL',
                            selected: controller.forceRtl,
                            onSelected: (v) {
                              if (v) {
                                controller.setForceRtl(true);
                              } else {
                                controller.clearForceDirection();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _ForceChip(
                            label: 'Force LTR',
                            selected: controller.forceLtr,
                            onSelected: (v) {
                              if (v) {
                                controller.setForceLtr(true);
                              } else {
                                controller.clearForceDirection();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: screen.height * 0.35,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final locale = filtered[index];
                        final isActive = locale == controller.currentLocale;
                        final meta = SwayLocaleMeta.fromLanguageCode(
                          locale.languageCode,
                        );
                        return ListTile(
                          dense: true,
                          title: Text(meta.displayName),
                          subtitle: Text(
                            locale.languageCode,
                            style: theme.textTheme.labelSmall,
                          ),
                          trailing: isActive
                              ? Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.primary,
                                  size: 18,
                                )
                              : null,
                          onTap: () {
                            controller.setLocale(locale);
                            _removeList();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_modeAllowsOverlay || _userHidden) return widget.child;
    if (_controller == null) return widget.child;

    return ForceRebuildScope(
      locale: _controller!.currentLocale,
      forceRtl: _controller!.forceRtl,
      forceLtr: _controller!.forceLtr,
      child: widget.child,
    );
  }
}

class _ForceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _ForceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      onSelected: onSelected,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}
