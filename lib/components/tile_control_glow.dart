import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class TileControlGlow extends PositionComponent {
  final String alliance;
  double _pulseTime = 0.0;

  TileControlGlow({
    required Vector2 position,
    required Vector2 size,
    required this.alliance,
  }) : super(
         position: position,
         size: size,
         anchor: Anchor.center,
         priority: 100, // Render on top of all tiles
       );

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTime += dt * 3.0; // Speed of pulse
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Translate to center for consistent drawing with IsometricTile
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    // Path logic matching IsometricTile (topWidthFactor = 0.7)
    // Applied slight scaling (0.85) to prevent overlap with neighbors
    final w = (size.x / 2) * 0.95;
    final h = (size.y / 2) * 0.95;
    const topWidthFactor = 0.7;

    final path = Path()
      ..moveTo(w * topWidthFactor, -h) // Top-Right
      ..lineTo(w, 0) // Right
      ..lineTo(w * topWidthFactor, h) // Bottom-Right
      ..lineTo(-w * topWidthFactor, h) // Bottom-Left
      ..lineTo(-w, 0) // Left
      ..lineTo(-w * topWidthFactor, -h) // Top-Left
      ..close();

    Color glowColor;
    if (alliance.toLowerCase() == 'menders') {
      glowColor = const Color(0xFF448AFF); // Blue
    } else {
      glowColor = const Color(0xFFFF5252); // Red
    }

    // Calculate pulsing alpha
    final alpha = (math.sin(_pulseTime) + 1) / 2 * 0.5 + 0.3; // 0.3 to 0.8

    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    canvas.drawPath(path, glowPaint);

    // Draw sharper inner line
    final borderPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(path, borderPaint);

    canvas.restore();
  }
}
