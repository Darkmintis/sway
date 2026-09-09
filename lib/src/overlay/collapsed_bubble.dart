/// The collapsed floating bubble for the Sway overlay.
library;

import 'package:flutter/material.dart';

/// A small circular draggable bubble that expands the overlay panel on tap.
class CollapsedBubble extends StatelessWidget {
  /// Callback when the bubble is tapped.
  final VoidCallback onTap;

  /// Callback during drag with the new position.
  final void Function(Offset position) onDragUpdate;

  /// Callback when drag ends to snap to nearest edge.
  final void Function(Offset velocity) onDragEnd;

  /// Creates a [CollapsedBubble].
  const CollapsedBubble({
    super.key,
    required this.onTap,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onPanUpdate: (details) {
        onDragUpdate(details.delta);
      },
      onPanEnd: (details) {
        onDragEnd(details.velocity.pixelsPerSecond);
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.language,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
