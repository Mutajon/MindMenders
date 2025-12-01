import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../models/unit_model.dart';
import '../game.dart';

class UnitComponent extends PositionComponent with TapCallbacks {
  final UnitModel unitModel;

  // Selection states
  bool _isSelectable = false;
  bool _isSelectedForAction = false;

  // Effects
  OpacityEffect? _pulseEffect;
  double _haloOpacity = 0.0;

  UnitComponent({
    required this.unitModel,
  }) : super(
          size: Vector2(25, 25), // Unit size
          anchor: Anchor.center,
        );

  @override
  void onLoad() {
    super.onLoad();
    // Position from tile - tiles are the source of truth
    final game = findParent<MyGame>();
    if (game != null) {
      final tile = game.getTileAt(unitModel.x, unitModel.y);
      if (tile != null) {
        position = tile.position.clone();
      }
    }
  }

  // Set selectable state (pulsing white halo)
  void setSelectable(bool selectable) {
    if (_isSelectable == selectable) return;

    _isSelectable = selectable;

    if (_isSelectable) {
      // Start pulsing
      _startPulsing();
    } else {
      // Stop pulsing if not selected
      if (!_isSelectedForAction) {
        _stopPulsing();
      }
    }
  }

  // Set selected state (static white halo)
  void setSelected(bool selected) {
    if (_isSelectedForAction == selected) return;

    _isSelectedForAction = selected;

    if (_isSelectedForAction) {
      // Stop pulsing, show static halo
      _stopPulsing();
      _haloOpacity = 1.0;
    } else {
      // If still selectable, resume pulsing
      if (_isSelectable) {
        _startPulsing();
      } else {
        _haloOpacity = 0.0;
      }
    }
  }

  void _startPulsing() {
    _pulseEffect?.removeFromParent();
    _haloOpacity = 0.5; // Start at mid-opacity

    _pulseEffect = OpacityEffect.to(
      1.0,
      EffectController(
        duration: 0.8,
        reverseDuration: 0.8,
        infinite: true,
      ),
      onComplete: () {
        // This won't run because infinite is true, but good practice
      },
      target: _HaloTarget(this),
    );
    add(_pulseEffect!);
  }

  void _stopPulsing() {
    _pulseEffect?.removeFromParent();
    _pulseEffect = null;
    _haloOpacity = 0.0;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final radius = size.x / 2;

    // Draw halo if selectable or selected
    if (_isSelectable || _isSelectedForAction) {
      final haloPaint = Paint()
        ..color = Colors.white.withValues(alpha: _haloOpacity * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(Offset.zero, radius + 8, haloPaint);

      // Inner glow
      final innerGlowPaint = Paint()
        ..color = Colors.white.withValues(alpha: _haloOpacity * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      canvas.drawCircle(Offset.zero, radius + 4, innerGlowPaint);
    }

    // Determine color and icon based on unit type
    Color unitColor;
    IconData iconData;

    if (unitModel.name.toLowerCase() == 'knight') {
      unitColor = const Color(0xFF4A90E2); // Blue
      iconData = Icons.shield;
    } else if (unitModel.name.toLowerCase() == 'archer') {
      unitColor = const Color(0xFF4CAF50); // Green
      iconData = Icons.arrow_upward; // Arrow icon
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
      ..color = _isSelectedForAction ? Colors.white : Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _isSelectedForAction ? 3.0 : 2.0;
    canvas.drawCircle(Offset.zero, radius, borderPaint);

    // Draw icon
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: 15, // Proportional to 25x25 size
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

  @override
  void onTapDown(TapDownEvent event) {
    // Allow clicking even without halo - the game will check if a move card is active
    final game = findParent<MyGame>();
    if (game != null) {
      game.selectUnitForMovement(this);
    }
  }

  // Move unit to new grid coordinates with animation
  void moveTo(int newX, int newY) {
    final game = findParent<MyGame>();
    if (game == null) return;

    final targetTile = game.getTileAt(newX, newY);
    if (targetTile == null) return;

    // Update model coordinates
    unitModel.x = newX;
    unitModel.y = newY;

    // Animate movement with spring-like effect
    add(
      MoveToEffect(
        targetTile.position.clone(),
        EffectController(
          duration: 0.6,
          curve: Curves.elasticOut, // Spring-like bounce
        ),
      ),
    );
  }
}

// Helper class to target the halo opacity for effects
class _HaloTarget implements OpacityProvider {
  final UnitComponent component;

  _HaloTarget(this.component);

  @override
  double get opacity => component._haloOpacity;

  @override
  set opacity(double value) => component._haloOpacity = value;
}
