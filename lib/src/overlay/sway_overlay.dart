library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'force_rebuild_scope.dart';
import 'locale_adapter.dart';
import 'overlay_controller.dart';

/// A floating, draggable locale-switching overlay for development.
///
/// Shows a persistent floating button. Tap to open a language picker
/// dialog anchored above the button. Tap outside or on the button
/// again to close.
class SwayOverlay extends StatefulWidget {
  /// The child widget tree (should contain the app's MaterialApp).
  final Widget child;

  /// The adapter providing locale support.
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
  Offset _position = const Offset(300, 600);

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(SwayOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.adapter != oldWidget.adapter) {
      _removeList();
      _buttonEntry?.remove();
      _controller?.removeListener(_onChanged);
      _initController();
    }
  }

  @override
  void dispose() {
    _removeList();
    _buttonEntry?.remove();
    _controller?.removeListener(_onChanged);
    super.dispose();
  }

  void _initController() {
    if (widget.disabled || widget.adapter == null) return;
    _controller = OverlayController(adapter: widget.adapter!);
    _controller!.addListener(_onChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.disabled) {
        _buttonEntry = OverlayEntry(builder: _buildButton);
        Overlay.of(context).insert(_buttonEntry!);
      }
    });
  }

  void _onChanged() => setState(() {});

  void _toggleList() {
    if (_listEntry != null) {
      _removeList();
      return;
    }
    _listEntry = OverlayEntry(builder: _buildList);
    Overlay.of(context).insert(_listEntry!);
  }

  void _removeList() {
    _listEntry?.remove();
    _listEntry = null;
  }

  Widget _buildButton(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    return Positioned(
      left: _position.dx.clamp(0.0, screen.width - 44),
      top: _position.dy.clamp(0.0, screen.height - 44),
      child: Opacity(
        opacity: 0.7,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleList,
            onPanUpdate: (d) => setState(() => _position += d.delta),
            child: Icon(
              Icons.language,
              size: 32,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
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
    final screen = MediaQuery.of(context).size;

    final listLeft = _position.dx.clamp(0.0, screen.width - 180);
    final listTop = _position.dy - 8 - (locales.length * 48.0 + 16);
    final adjustedTop = listTop < 8 ? _position.dy + 52 : listTop;

    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _removeList,
          child: const SizedBox.expand(),
        ),
        Positioned(
          left: listLeft,
          top: adjustedTop,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 170,
                constraints: BoxConstraints(
                  maxHeight: screen.height * 0.4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: locales.length,
                  itemBuilder: (context, index) {
                    final locale = locales[index];
                    final isActive = locale == controller.currentLocale;
                    return ListTile(
                      dense: true,
                      title: Text(_localeName(locale)),
                      trailing: isActive
                          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary, size: 18)
                          : null,
                      onTap: () {
                        controller.setLocale(locale);
                        _removeList();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _localeName(Locale locale) {
    const names = {
      'en': 'English',
      'ar': 'العربية',
      'fr': 'Français',
      'de': 'Deutsch',
      'es': 'Español',
      'it': 'Italiano',
      'pt': 'Português',
      'ru': 'Русский',
      'zh': '中文',
      'ja': '日本語',
      'ko': '한국어',
      'hi': 'हिन्दी',
      'tr': 'Türkçe',
    };
    return names[locale.languageCode] ?? locale.languageCode;
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
