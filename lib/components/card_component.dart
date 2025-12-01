import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/card_model.dart';

class CardComponent extends PositionComponent {
  final CardModel cardModel;
  static const double cardWidth = 120.0;
  static const double cardHeight = 160.0;

  CardComponent({
    required this.cardModel,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(cardWidth, cardHeight),
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Card background
    final cardRect = Rect.fromLTWH(0, 0, size.x, size.y);
    final cardPaint = Paint()
      ..color = const Color(0xFF2C2C2C)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw card with rounded corners
    final cardPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        cardRect,
        const Radius.circular(8),
      ));
    
    canvas.drawPath(cardPath, cardPaint);
    canvas.drawPath(cardPath, borderPaint);

    // Draw card title
    final titlePainter = TextPainter(
      text: TextSpan(
        text: cardModel.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    titlePainter.layout(maxWidth: size.x - 16);
    titlePainter.paint(canvas, Offset((size.x - titlePainter.width) / 2, 8));

    // Draw card type
    final typePainter = TextPainter(
      text: TextSpan(
        text: cardModel.type.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    typePainter.layout(maxWidth: size.x - 16);
    typePainter.paint(canvas, Offset((size.x - typePainter.width) / 2, 28));

    // Draw description
    final descPainter = TextPainter(
      text: TextSpan(
        text: cardModel.description,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    descPainter.layout(maxWidth: size.x - 16);
    descPainter.paint(canvas, Offset((size.x - descPainter.width) / 2, size.y / 2));

    // Draw flavour text
    final flavourPainter = TextPainter(
      text: TextSpan(
        text: cardModel.flavourText,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 8,
          fontStyle: FontStyle.italic,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    flavourPainter.layout(maxWidth: size.x - 16);
    flavourPainter.paint(
      canvas,
      Offset((size.x - flavourPainter.width) / 2, size.y - 24),
    );
  }
}
