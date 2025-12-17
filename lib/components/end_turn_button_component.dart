import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class EndTurnButtonComponent extends PositionComponent
    with TapCallbacks, HoverCallbacks {
  final VoidCallback onPressed;
  bool _isHovered = false;

  EndTurnButtonComponent({required Vector2 position, required this.onPressed})
    : super(position: position, size: Vector2(100, 40), anchor: Anchor.center);

  @override
  void onHoverEnter() {
    _isHovered = true;
  }

  @override
  void onHoverExit() {
    _isHovered = false;
  }

  @override
  void onTapDown(TapDownEvent event) {
    onPressed();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final paint = Paint()
      ..color = _isHovered ? const Color(0xFFEF5350) : const Color(0xFFD32F2F)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      paint,
    );

    // Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      borderPaint,
    );

    // Text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'END TURN',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        (size.y - textPainter.height) / 2,
      ),
    );
  }
}
