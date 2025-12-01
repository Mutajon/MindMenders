import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../game.dart';

class CardComponent extends PositionComponent with HoverCallbacks, TapCallbacks {
  final CardModel cardModel;
  static const double cardWidth = 120.0;
  static const double cardHeight = 160.0;
  
  bool _isHovered = false;
  bool _isSelected = false;
  late Vector2 _basePosition;
  double _haloOpacity = 0.0;
  double _currentHoverOffset = 0.0;
  double _currentSelectOffset = 0.0;

  CardComponent({
    required this.cardModel,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(cardWidth, cardHeight),
          anchor: Anchor.center,
        );

  @override
  void onLoad() {
    super.onLoad();
    _basePosition = position.clone();
  }

  @override
  void onHoverEnter() {
    _isHovered = true;
    _currentHoverOffset = -10;
    _updatePosition();
  }

  @override
  void onHoverExit() {
    _isHovered = false;
    _currentHoverOffset = 0;
    _updatePosition();
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Get reference to game
    final game = findParent<MyGame>();
    if (game == null) return;
    
    if (_isSelected) {
      // Deselect this card
      deselect();
      game.deselectCard();
    } else {
      // Select this card (will deselect others)
      _isSelected = true;
      _currentSelectOffset = -20;
      _haloOpacity = 1.0;
      _updatePosition();
      game.selectCard(this);
    }
  }
  
  // Public method to deselect this card (called by game)
  void deselect() {
    if (!_isSelected) return;
    
    _isSelected = false;
    _currentSelectOffset = 0;
    _haloOpacity = 0.0;
    _updatePosition();
  }
  
  void _updatePosition() {
    // Calculate total offset from base position
    final totalOffset = _currentHoverOffset + _currentSelectOffset;
    
    // Smoothly move to new position
    final targetPosition = Vector2(_basePosition.x, _basePosition.y + totalOffset);
    
    // Remove any existing move effects to prevent conflicts
    children.whereType<MoveToEffect>().forEach((effect) => effect.removeFromParent());
    
    add(
      MoveToEffect(
        targetPosition,
        EffectController(duration: 0.2),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Determine card color based on type
    Color cardBaseColor;
    Color iconColor;
    Color borderColor;
    Color haloColor;
    IconData cardIcon;
    
    switch (cardModel.type.toLowerCase()) {
      case 'attack':
        cardBaseColor = const Color(0xFF5D2E2E); // Reddish dark
        iconColor = const Color(0xFFFF5252); // Bright red
        borderColor = const Color(0xFF8B0000); // Dark red border
        haloColor = const Color(0xFFFF5252); // Red halo
        cardIcon = Icons.flash_on;
        break;
      case 'move':
        cardBaseColor = const Color(0xFF2E3B5D); // Blueish dark
        iconColor = const Color(0xFF448AFF); // Bright blue
        borderColor = const Color(0xFF1565C0); // Dark blue border
        haloColor = const Color(0xFF448AFF); // Blue halo
        cardIcon = Icons.directions_walk;
        break;
      case 'defend':
        cardBaseColor = const Color(0xFF2E5D32); // Greenish dark
        iconColor = const Color(0xFF69F0AE); // Bright green
        borderColor = const Color(0xFF1B5E20); // Dark green border
        haloColor = const Color(0xFF69F0AE); // Green halo
        cardIcon = Icons.shield;
        break;
      default:
        cardBaseColor = const Color(0xFF2C2C2C); // Default dark
        iconColor = const Color(0xFFFFD700); // Gold
        borderColor = const Color(0xFF8B7500); // Dark gold border
        haloColor = const Color(0xFFFFD700); // Gold halo
        cardIcon = Icons.help_outline;
    }

    // Draw halo effect if selected
    if (_isSelected && _haloOpacity > 0) {
      final haloPaint = Paint()
        ..color = haloColor.withValues(alpha: _haloOpacity * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      
      final haloRect = Rect.fromLTWH(-15, -15, size.x + 30, size.y + 30);
      canvas.drawRRect(
        RRect.fromRectAndRadius(haloRect, const Radius.circular(20)),
        haloPaint,
      );
      
      // Draw inner glow
      final innerGlowPaint = Paint()
        ..color = haloColor.withValues(alpha: _haloOpacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      
      final innerGlowRect = Rect.fromLTWH(-8, -8, size.x + 16, size.y + 16);
      canvas.drawRRect(
        RRect.fromRectAndRadius(innerGlowRect, const Radius.circular(14)),
        innerGlowPaint,
      );
    }

    // Card background
    final cardRect = Rect.fromLTWH(0, 0, size.x, size.y);
    final cardPaint = Paint()
      ..color = cardBaseColor
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = _isSelected ? borderColor : borderColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _isSelected ? 3.0 : 2.0;

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

    // Draw card icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(cardIcon.codePoint),
        style: TextStyle(
          fontSize: 48,
          fontFamily: cardIcon.fontFamily,
          color: iconColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset((size.x - iconPainter.width) / 2, 40), // Positioned below title
    );

    // Draw card type
    final typePainter = TextPainter(
      text: TextSpan(
        text: cardModel.type.toUpperCase(),
        style: TextStyle(
          color: iconColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    typePainter.layout(maxWidth: size.x - 16);
    typePainter.paint(canvas, Offset((size.x - typePainter.width) / 2, 95)); // Below icon

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
    descPainter.paint(canvas, Offset((size.x - descPainter.width) / 2, 115)); // Below type

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
      Offset((size.x - flavourPainter.width) / 2, size.y - 20),
    );
  }
}
