import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class MemoryShieldComponent extends PositionComponent {
  final Color factionColor;
  final double hexRadius;

  MemoryShieldComponent({required this.factionColor, this.hexRadius = 32.0})
    : super(
        anchor: Anchor.center,
        priority: 150, // Above tiles but below units
      );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = factionColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final fillPaint = Paint()
      ..color = factionColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Draw hexagonal shield bubble
    final path = _createHexPath(hexRadius);

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);
  }

  Path _createHexPath(double radius) {
    final path = Path();
    const sides = 6;
    const angleStep = (2 * pi) / sides;
    const startAngle = pi / 6; // Flat-top hexagon

    for (int i = 0; i <= sides; i++) {
      final angle = startAngle + (i * angleStep);
      final x = radius * cos(angle);
      final y = radius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    return path;
  }
}
