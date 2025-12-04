import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game.dart';

enum DeckType { draw, discard }

class DeckComponent extends PositionComponent with HoverCallbacks, HasGameRef<MyGame> {
  final DeckType type;
  bool _isHovered = false;
  
  DeckComponent({
    Vector2? position,
    this.type = DeckType.draw,
  }) : super(
    position: position,
    size: Vector2(60, 90),
    anchor: Anchor.bottomRight,
  );

  @override
  void render(Canvas canvas) {
    // Draw stack effect
    final paint = Paint()
      ..color = const Color(0xFF4A3B3B) // Dark brownish
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = const Color(0xFF2C2C2C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw 3 cards to simulate stack
    // For discard pile, show fewer cards if empty?
    // But for now, just visual representation.
    
    for (int i = 0; i < 3; i++) {
      final offset = i * 2.0;
      // Draw from bottom up visually
      final rect = Rect.fromLTWH(offset, -offset, size.x, size.y);
      
      // Fill
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)), 
        paint
      );
      
      // Border
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)), 
        borderPaint
      );
      
      // Card back design (simple cross) - ONLY FOR DISCARD PILE
      if (i == 2 && type == DeckType.discard) { // Top card
        final designPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.3) // More visible X
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
          
        canvas.drawLine(
          Offset(rect.left + 15, rect.top + 15),
          Offset(rect.right - 15, rect.bottom - 15),
          designPaint
        );
        canvas.drawLine(
          Offset(rect.right - 15, rect.top + 15),
          Offset(rect.left + 15, rect.bottom - 15),
          designPaint
        );
      }
    }
  }

  @override
  void onHoverEnter() {
    _isHovered = true;
    gameRef.onDeckHover(type, true);
  }

  @override
  void onHoverExit() {
    _isHovered = false;
    gameRef.onDeckHover(type, false);
  }
}
