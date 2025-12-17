import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class FloatingTextComponent extends TextComponent {
  final Color baseColor;
  double _lifeTime = 1.0;
  late TextStyle _baseTextStyle;

  FloatingTextComponent({
    required String text,
    required Vector2 position,
    required Color color,
  }) : baseColor = color,
       super(
         text: text,
         position: position,
         anchor: Anchor.center,
         priority: 1000,
       );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Initialize base style
    _baseTextStyle = TextStyle(
      color: baseColor,
      fontSize: 16,
      fontWeight: FontWeight.bold,
      shadows: const [
        Shadow(blurRadius: 2.0, color: Colors.black, offset: Offset(1.0, 1.0)),
      ],
    );

    // Set initial renderer
    textRenderer = TextPaint(style: _baseTextStyle);

    // Float up
    add(
      MoveEffect.by(
        Vector2(0, -50),
        EffectController(duration: 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    _lifeTime -= dt;

    if (_lifeTime <= 0) {
      removeFromParent();
      return;
    }

    // Manual Fade Out logic
    // Start fading after 0.2s (so fading duration is 0.8s)
    if (_lifeTime < 0.8) {
      final opacity = (_lifeTime / 0.8).clamp(0.0, 1.0);

      // Create new TextPaint with updated opacity
      textRenderer = TextPaint(
        style: _baseTextStyle.copyWith(
          color: baseColor.withValues(alpha: opacity),
        ),
      );
    }
  }
}
