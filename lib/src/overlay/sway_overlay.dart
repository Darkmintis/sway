/// The main Sway overlay widget.
///
/// A floating, draggable, collapsible widget that lets a developer
/// switch locale and force LTR/RTL instantly, without touching device
/// settings, without restarting the app.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'collapsed_bubble.dart';
import 'expanded_panel.dart';
import 'force_rebuild_scope.dart';
import 'locale_adapter.dart';
import 'overlay_controller.dart';

/// The Sway locale-switching overlay.
///
/// Wraps the app's `MaterialApp`/`WidgetsApp` to enable instant
/// locale switching and RTL/LTR force-preview.
///
/// ```dart
/// SwayOverlay(
///   adapter: SwayFormatAdapter(...),
///   child: MaterialApp(...),
/// )
/// ```
class SwayOverlay extends StatefulWidget {
  /// The child widget tree (should contain the app's MaterialApp).
  final Widget child;

  /// The adapter providing locale support.
  ///
  /// If null, Sway will attempt to auto-detect a `SwayFormatAdapter`.
  final SwayLocaleAdapter? adapter;

  /// Whether the overlay is completely disabled.
  ///
  /// When true, no bubble or panel is rendered — useful for release builds
  /// or when the overlay is not wanted.
  final bool disabled;

  /// Creates a [SwayOverlay].
  const SwayOverlay({
    super.key,
    required this.child,
    this.adapter,
    this.disabled = false,
  });

  /// Creates a disabled [SwayOverlay] (no bubble rendered).
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
  OverlayEntry? _overlayEntry;
  Offset _bubblePosition = const Offset(300, 600);

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(SwayOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.adapter != oldWidget.adapter) {
      _disposeOverlay();
      _initController();
    }
  }

  @override
  void dispose() {
    _disposeOverlay();
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _initController() {
    if (widget.disabled || widget.adapter == null) return;

    _controller = OverlayController(
      adapter: widget.adapter!,
    );
    _controller!.addListener(_onControllerChanged);

    // Schedule overlay insertion after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.disabled) {
        _insertOverlay();
      }
    });
  }

  void _disposeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onControllerChanged() {
    _overlayEntry?.markNeedsBuild();
  }

  void _insertOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => _buildOverlay(context),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildOverlay(BuildContext context) {
    if (_controller == null) return const SizedBox.shrink();

    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        if (_controller!.isExpanded)
          Positioned(
            right: 16,
            bottom: 80,
            child: ExpandedPanel(
              controller: _controller!,
              onCollapse: () => _controller!.collapse(),
            ),
          ),
        Positioned(
          left: _bubblePosition.dx.clamp(0.0, screenSize.width - 48),
          top: _bubblePosition.dy.clamp(0.0, screenSize.height - 48),
          child: CollapsedBubble(
            onTap: () => _controller!.toggleExpanded(),
            onDragUpdate: (delta) {
              setState(() {
                _bubblePosition = Offset(
                  (_bubblePosition.dx + delta.dx).clamp(0.0, screenSize.width - 48),
                  (_bubblePosition.dy + delta.dy).clamp(0.0, screenSize.height - 48),
                );
              });
            },
            onDragEnd: (velocity) {
              // Snap to nearest edge
              final snapX = velocity.dx > 0
                  ? screenSize.width - 48
                  : 0.0;
              setState(() {
                _bubblePosition = Offset(snapX, _bubblePosition.dy);
              });
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gate: no overlay in release mode
    if (kReleaseMode || widget.disabled) {
      return widget.child;
    }

    if (_controller == null) {
      return widget.child;
    }

    return ForceRebuildScope(
      locale: _controller!.currentLocale,
      forceRtl: _controller!.forceRtl,
      forceLtr: _controller!.forceLtr,
      child: widget.child,
    );
  }
}
