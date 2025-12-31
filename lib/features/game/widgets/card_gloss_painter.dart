import 'package:flutter/material.dart';

/// CustomPainter for rendering glossy card surface effects.
/// Draws all gradient overlays in a single paint pass for maximum performance.
/// Replaces 7 separate Positioned gradient widgets with direct canvas operations.
class CardGlossPainter extends CustomPainter {
  final bool isFaceUp;
  final BorderRadius borderRadius;

  const CardGlossPainter({
    required this.isFaceUp,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    // Clip to rounded rectangle
    canvas.save();
    canvas.clipRRect(rrect);

    // 1. Top highlight reflection - glossy surface effect
    _paintTopHighlight(canvas, size);

    // 2. Diagonal light reflection - enhanced gloss
    _paintDiagonalHighlight(canvas, size);

    // 3. Bottom darkening - depth effect
    _paintBottomDarkening(canvas, size);

    // 4. Edge highlights and shadows - bevel effect
    _paintEdgeHighlights(canvas, size);

    canvas.restore();
  }

  /// Paints top highlight reflection for glossy surface
  void _paintTopHighlight(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.center,
      colors: [
        Colors.white.withValues(alpha:isFaceUp ? 0.5 : 0.25),
        Colors.white.withValues(alpha:isFaceUp ? 0.2 : 0.08),
        Colors.transparent,
      ],
      stops: const [0.0, 0.2, 0.5],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);
  }

  /// Paints diagonal light reflection for enhanced gloss
  void _paintDiagonalHighlight(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      begin: const Alignment(-1.0, -1.0),
      end: const Alignment(0.3, 0.3),
      colors: [
        Colors.white.withValues(alpha:isFaceUp ? 0.35 : 0.15),
        Colors.white.withValues(alpha:isFaceUp ? 0.08 : 0.03),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.6],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);
  }

  /// Paints bottom darkening for depth effect
  void _paintBottomDarkening(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      begin: Alignment.center,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        Colors.black.withValues(alpha:isFaceUp ? 0.06 : 0.12),
        Colors.black.withValues(alpha:isFaceUp ? 0.12 : 0.2),
      ],
      stops: const [0.4, 0.8, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);
  }

  /// Paints edge highlights and shadows for bevel effect
  void _paintEdgeHighlights(Canvas canvas, Size size) {
    const edgeSize = 3.0;

    // Top edge highlight
    final topGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha:isFaceUp ? 0.5 : 0.2),
        Colors.transparent,
      ],
    );

    final topPaint = Paint()
      ..shader = topGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, edgeSize),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, edgeSize),
      topPaint,
    );

    // Left edge highlight
    final leftGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.white.withValues(alpha:isFaceUp ? 0.4 : 0.15),
        Colors.transparent,
      ],
    );

    final leftPaint = Paint()
      ..shader = leftGradient.createShader(
        Rect.fromLTWH(0, 0, edgeSize, size.height),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, edgeSize, size.height),
      leftPaint,
    );

    // Bottom edge shadow
    final bottomGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        Colors.black.withValues(alpha:isFaceUp ? 0.2 : 0.3),
        Colors.transparent,
      ],
    );

    final bottomPaint = Paint()
      ..shader = bottomGradient.createShader(
        Rect.fromLTWH(0, size.height - edgeSize, size.width, edgeSize),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, size.height - edgeSize, size.width, edgeSize),
      bottomPaint,
    );

    // Right edge shadow
    final rightGradient = LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [
        Colors.black.withValues(alpha:isFaceUp ? 0.15 : 0.25),
        Colors.transparent,
      ],
    );

    final rightPaint = Paint()
      ..shader = rightGradient.createShader(
        Rect.fromLTWH(size.width - edgeSize, 0, edgeSize, size.height),
      );

    canvas.drawRect(
      Rect.fromLTWH(size.width - edgeSize, 0, edgeSize, size.height),
      rightPaint,
    );
  }

  @override
  bool shouldRepaint(CardGlossPainter oldDelegate) {
    // Only repaint if face-up state changes
    return isFaceUp != oldDelegate.isFaceUp;
  }
}
