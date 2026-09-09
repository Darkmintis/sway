library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../shared/locale_meta.dart';
import 'force_rebuild_scope.dart';
import 'locale_adapter.dart';
import 'overlay_controller.dart';

const double _kBubbleSize = 48;
const double _kEdgeMargin = 8;
const double _kPanelWidth = 220;
const double _kDragTapSlop = 8;

/// A floating, draggable locale-switching overlay for development.
///
/// Shows a persistent floating button. Tap to open a language picker
/// panel anchored near the button. Drag snaps to the nearest screen edge.
/// Includes Force RTL / Force LTR preview toggles.
///
/// Only active in debug/profile builds (absent in release unless you
/// also pass [disabled]).
class SwayOverlay extends StatefulWidget {
  /// The child widget tree. Typically wraps content under a [MaterialApp]
  /// route so an [Overlay] ancestor exists, or wrap [MaterialApp] itself
  /// if you provide your own [Overlay].
  final Widget child;

  /// The adapter providing locale support.
  ///
  /// Required when the overlay is enabled. Omitting it in debug throws
  /// a clear [FlutterError] instead of rendering a silent no-op.
  final SwayLocaleAdapter? adapter;

  /// Whether the overlay is completely disabled (no button rendered).
  final bool disabled;

  /// Creates a [SwayOverlay].
  const SwayOverlay({
    super.key,
    required this.child,
    this.adapter,
    this.disabled = false,
  });

  /// Creates a disabled [SwayOverlay] (no button rendered).
  const SwayOverlay.disabled({
    super.key,
    required this.child,
  })  : adapter = null,
        disabled = true;

  @override
  State<SwayOverlay> createState() => _SwayOverlayState();
}

class _SwayOverlayState extends State<SwayOverlay> {
  OverlayController? _controller;
  OverlayEntry? _buttonEntry;
  OverlayEntry? _listEntry;
  Offset? _position;
  double _dragDistance = 0;
  String _searchQuery = '';
  bool _missingAdapterReported = false;

  bool get _active =>
      !kReleaseMode && !widget.disabled && widget.adapter != null;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(SwayOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.adapter != oldWidget.adapter ||
        widget.disabled != oldWidget.disabled) {
      _teardownOverlay();
      _initController();
    }
  }

  @override
  void dispose() {
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
    if (kReleaseMode || widget.disabled) return;

    if (widget.adapter == null) {
      if (!_missingAdapterReported) {
        _missingAdapterReported = true;
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: FlutterError(
              'SwayOverlay requires an adapter when enabled.\n'
              'Pass SwayFormatAdapter, ManualAdapter, EasyLocalizationAdapter, '
              'or IntlAdapter — or use SwayOverlay.disabled / disabled: true.',
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
              'Place it under MaterialApp (e.g. as home) or wrap MaterialApp '
              'in an Overlay widget.',
            ),
            library: 'sway',
          ),
        );
        return;
      }
      _ensurePosition(MediaQuery.sizeOf(context));
      _buttonEntry = OverlayEntry(builder: _buildButton);
      overlay.insert(_buttonEntry!);
    });
  }

  void _ensurePosition(Size screen) {
    _position ??= Offset(
      screen.width - _kBubbleSize - _kEdgeMargin,
      screen.height - _kBubbleSize - 96,
    );
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
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final screen = MediaQuery.sizeOf(context);
    _ensurePosition(screen);
    _dragDistance += details.delta.distance;
    _position = Offset(
      (_position!.dx + details.delta.dx)
          .clamp(0.0, screen.width - _kBubbleSize),
      (_position!.dy + details.delta.dy)
          .clamp(0.0, screen.height - _kBubbleSize),
    );
    _markOverlayDirty();
  }

  void _onPanEnd(DragEndDetails details) {
    final screen = MediaQuery.sizeOf(context);
    _ensurePosition(screen);
    final midX = screen.width / 2;
    final snapLeft = _position!.dx + _kBubbleSize / 2 < midX;
    _position = Offset(
      snapLeft ? _kEdgeMargin : screen.width - _kBubbleSize - _kEdgeMargin,
      _position!.dy.clamp(
        _kEdgeMargin,
        screen.height - _kBubbleSize - _kEdgeMargin,
      ),
    );
    _markOverlayDirty();

    if (_dragDistance < _kDragTapSlop) {
      _toggleList();
    }
  }

  Widget _buildButton(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    _ensurePosition(screen);
    final theme = Theme.of(context);
    final locale = _controller?.currentLocale;
    final code = (locale?.languageCode ?? '?').toUpperCase();

    return Positioned(
      left: _position!.dx.clamp(0.0, screen.width - _kBubbleSize),
      top: _position!.dy.clamp(0.0, screen.height - _kBubbleSize),
      child: Material(
        elevation: 6,
        shadowColor: Colors.black54,
        shape: const CircleBorder(),
        color: theme.colorScheme.primary,
        child: SizedBox(
          width: _kBubbleSize,
          height: _kBubbleSize,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.translate_rounded,
                  size: 22,
                  color: theme.colorScheme.onPrimary,
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (_controller == null) return const SizedBox.shrink();
    final controller = _controller!;
    final locales = controller.supportedLocales;
    final filtered = _searchQuery.isEmpty
        ? locales
        : locales.where((l) {
            final name = SwayLocaleMeta.fromLanguageCode(l.languageCode)
                .displayName
                .toLowerCase();
            final q = _searchQuery.toLowerCase();
            return name.contains(q) || l.languageCode.contains(q);
          }).toList();
    final screen = MediaQuery.sizeOf(context);
    final showSearch = locales.length > 8;
    final panelHeight = (showSearch ? 56.0 : 0) +
        52 + // force toggles
        (filtered.length * 48.0).clamp(48.0, screen.height * 0.35) +
        8;

    final listLeft = (_position!.dx)
        .clamp(_kEdgeMargin, screen.width - _kPanelWidth - _kEdgeMargin);
    final preferAbove = _position!.dy > panelHeight + 16;
    final listTop = preferAbove
        ? (_position!.dy - 8 - panelHeight)
            .clamp(_kEdgeMargin, screen.height - panelHeight - _kEdgeMargin)
        : (_position!.dy + _kBubbleSize + 8)
            .clamp(_kEdgeMargin, screen.height - panelHeight - _kEdgeMargin);

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
    if (kReleaseMode || widget.disabled) return widget.child;
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
