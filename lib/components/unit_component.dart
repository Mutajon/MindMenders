import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/unit_model.dart';

class UnitComponent extends PositionComponent {
  final UnitModel unitModel;
  final double tileWidth;
  final double tileHeight;

  UnitComponent({
    required this.unitModel,
    this.tileWidth = 64.0,
    this.tileHeight = 32.0,
  }) : super(
          size: Vector2(40, 40), // Unit size
          anchor: Anchor.center,
        );

  @override
  void onLoad() {
    super.onLoad();
    // Calculate isometric position (same formula as tiles)
    final isoX = (unitModel.x - unitModel.y) * tileWidth * 0.75;
    final isoY = (unitModel.x + unitModel.y) * tileHeight * 0.5;
    position = Vector2(isoX, isoY);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final radius = size.x / 2;
    
    // Determine color and icon based on unit type
    Color unitColor;
    IconData iconData;
    
    if (unitModel.name.toLowerCase() == 'knight') {
      unitColor = const Color(0xFF4A90E2); // Blue
      iconData = Icons.shield;
    } else if (unitModel.name.toLowerCase() == 'archer') {
      unitColor = const Color(0xFF4CAF50); // Green
      iconData = Icons.sports; // Bow-like icon
    } else {
      unitColor = const Color(0xFF9E9E9E); // Gray fallback
      iconData = Icons.person;
    }
    
    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(const Offset(0, 2), radius, shadowPaint);
    
    // Main circle
    final circlePaint = Paint()
      ..color = unitColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius, circlePaint);
    
    // Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset.zero, radius, borderPaint);
    
    // Draw icon
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: 24,
          fontFamily: iconData.fontFamily,
          color: Colors.white,
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

  @override
  bool containsLocalPoint(Vector2 point) {
    // Check if point is inside the circle
    final radius = size.x / 2;
    return point.length <= radius;
  }

}
