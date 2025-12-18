import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game.dart';

/// "Hive Spreading" indicator shown during AI turn
class HiveSpreadingIndicator extends PositionComponent with HasGameRef<MyGame> {
  double _animationTime = 0.0;

  HiveSpreadingIndicator() : super(priority: 1000); // Very high priority

  @override
  void onLoad() {
    super.onLoad();
    // Position at top center
    position = Vector2(gameRef.size.x / 2, 40);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animationTime += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Pulsing opacity
    final pulseSpeed = 2.0;
    final opacity = 0.5 + 0.5 * (1 + math.sin(_animationTime * pulseSpeed)) / 2;

    // Draw text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'HIVE SPREADING',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF0000).withOpacity(opacity),
          letterSpacing: 4,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.8),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }
}
