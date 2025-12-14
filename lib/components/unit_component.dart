import "dart:async";import 'package:flame/components.dart';
import 'health_bar_component.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../models/unit_model.dart';
import '../models/tile_model.dart';
import '../game.dart';

class UnitComponent extends PositionComponent with TapCallbacks, HasPaint {
  final UnitModel unitModel;

  // Selection states
  bool _isSelectable = false;
  bool _isSelectedForAction = false;

  // Effects
  OpacityEffect? _pulseEffect;
  double _haloOpacity = 0.0;
  
  // Halo color
  Color _haloColor = Colors.white;
  
  // External Health Bar
  HealthBarComponent? _healthBarComponent;

  void setHaloColor(Color color) {
    _haloColor = color;
  }
  
  UnitComponent({
    required this.unitModel,
  }) : super(
          size: Vector2(25, 25), // Unit size
          anchor: Anchor.center,
          priority: 100, // Ensure strictly above tiles (default 0)
        );

  @override
  void onTapDown(TapDownEvent event) {
    print('UnitComponent tapped: ${unitModel.name}');
    // Forward interaction to game
    final game = findParent<MyGame>();
    if (game != null) {
      game.onUnitTapped(this);
    }
  }

  @override
  void onLoad() {
    super.onLoad();
    // Position from tile - MyGame is the source of truth
    final game = findParent<MyGame>();
    if (game != null) {
      final pos = game.getTilePosition(unitModel.x, unitModel.y);
      if (pos != null) {
        position = pos;
      }
      
      // Initialize Health Bar (Add to Game for global Z-ordering)
      _healthBarComponent = HealthBarComponent(unitModel: unitModel);
      game.add(_healthBarComponent!);
    }
  }

  @override
  void onRemove() {
    _healthBarComponent?.removeFromParent();
    super.onRemove();
  }

  // Hover state
  bool _isHovered = false;

  void setHovered(bool hovered) {
    _isHovered = hovered;
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

  // Shield animation
  double _shieldRotation = 0.0;
  
  void applyShield() {
    unitModel.hasShield = true;
  }

  void consumeShield() {
    unitModel.hasShield = false;
  }


  // Damage Preview State
  int _previewDamageAmount = 0;
  double _flashTimer = 0.0;
  bool _flashAscending = true;
  double _currentFlashIntensity = 0.0;

  // Damage Taking State
  ColorEffect? _damageFlashEffect;

  bool _willLoseShield = false;

  void setPreviewDamage(int amount, {bool willLoseShield = false}) {
    _previewDamageAmount = amount;
    _willLoseShield = willLoseShield;
  }

  void triggerDamageReaction() {
      // Flash Red Effect
      _damageFlashEffect?.removeFromParent();
      _damageFlashEffect = ColorEffect(
          const Color(0xFFFF0000), // Red
          EffectController(
            duration: 0.2, // Quick Flash
            reverseDuration: 0.2,
            repeatCount: 5, // Pulse a few times for approx 2 seconds total? No, 0.4 * 5 = 2.0s
          ),
          opacityTo: 0.7,
      );
      add(_damageFlashEffect!);
      
      // Shake Effect
      add(
          MoveEffect.by(
              Vector2(5, 0), 
              EffectController(
                  duration: 0.05,
                  reverseDuration: 0.05,
                  repeatCount: 10, // Shake for 1s
              ),
          ),
      );
  }

  @override
  void update(double dt) {
      super.update(dt);
      
      // Update Shield
      if (unitModel.hasShield) {
        _shieldRotation += dt * 1.5;
      }
      
      // Update Damage Preview Flash
      if (_previewDamageAmount > 0) {
          double speed = 2.0; // Flash speed
          if (_flashAscending) {
              _flashTimer += dt * speed;
              if (_flashTimer >= 1.0) {
                  _flashTimer = 1.0;
                  _flashAscending = false;
              }
          } else {
              _flashTimer -= dt * speed;
              if (_flashTimer <= 0.0) {
                  _flashTimer = 0.0;
                  _flashAscending = true;
              }
          }
          _currentFlashIntensity = _flashTimer; // 0..1
      }
      
      // Update Health Bar
      if (_healthBarComponent != null) {
          // Position above unit
          _healthBarComponent!.position = position + Vector2(0, -35); // Adjust offset as needed
          
          // Sync State
          _healthBarComponent!.setPreviewDamage(
              _previewDamageAmount, 
              _willLoseShield, 
              _currentFlashIntensity
          );
          
          // Visibility Logic
          bool shouldShow = _isSelectedForAction || _isHovered || _previewDamageAmount > 0 || _willLoseShield;
          _healthBarComponent!.isVisible = shouldShow;
      }
  }



  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final radius = size.x / 2;
    // Center of the component's bounding box (canvas origin is top-left)
    final center = Offset(size.x / 2, size.y / 2);

    // Draw halo if selectable or selected
    if (_isSelectable || _isSelectedForAction) {
      final haloPaint = Paint()
        ..color = _haloColor.withValues(alpha: _haloOpacity * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(center, radius + 8, haloPaint);

      // Inner glow
      final innerGlowPaint = Paint()
        ..color = _haloColor.withValues(alpha: _haloOpacity * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      canvas.drawCircle(center, radius + 4, innerGlowPaint);
    }
    

    
    // Draw Shield (Green Spinner)
    if (unitModel.hasShield) {
        final shieldPaint = Paint()
            ..color = const Color(0xFF69F0AE)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0
            ..strokeCap = StrokeCap.round;
            
        // Flash shield if pending loss
        if (_willLoseShield) {
             final flashColor = Color.lerp(
                const Color(0xFF69F0AE),
                const Color(0xFFFF0000).withValues(alpha: 0.0), // Fade to transparent/red
                _currentFlashIntensity
             ) ?? const Color(0xFF69F0AE);
             shieldPaint.color = flashColor;
        }
            
        final rect = Rect.fromCircle(center: center, radius: radius + 2);
        
        // Draw 3 animated arcs
        for (int i = 0; i < 3; i++) {
            final startAngle = _shieldRotation + (i * (3.14159 * 2 / 3));
            canvas.drawArc(rect, startAngle, 1.5, false, shieldPaint);
        }
    }

    // Determine color and icon based on unit type
    Color unitColor;
    IconData iconData;

    // Determine icon based on unit type
    if (unitModel.name.toLowerCase() == 'manipulator') {
      iconData = Icons.shield;
    } else if (unitModel.name.toLowerCase() == 'infector') {
      iconData = Icons.arrow_upward;
    } else if (unitModel.name.toLowerCase() == 'sweeper') {
      iconData = Icons.cleaning_services;
    } else if (unitModel.name.toLowerCase() == 'devourer') {
      iconData = Icons.dangerous;
    } else if (unitModel.name.toLowerCase() == 'crazy nina') {
      iconData = Icons.local_fire_department;
    } else if (unitModel.name.toLowerCase() == 'terminator') {
      iconData = Icons.android;
    } else {
      iconData = Icons.person;
    }

    // Determine color based on alliance
    if (unitModel.alliance == 'Hive') {
      unitColor = const Color(0xFFEF5350); // Red
    } else if (unitModel.alliance == 'Menders') {
      unitColor = const Color(0xFF42A5F5); // Blue
    } else {
      unitColor = const Color(0xFF9E9E9E); // Gray fallback
    }

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(center.dx, center.dy + 2), radius, shadowPaint);

    // Main circle
    final circlePaint = Paint()
      ..color = unitColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, circlePaint);

    // Border
    final borderPaint = Paint()
      ..color = _isSelectedForAction ? Colors.white : Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _isSelectedForAction ? 3.0 : 2.0;
    canvas.drawCircle(center, radius, borderPaint);

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
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    // Check if point is inside the circle (centered in bounding box)
    final radius = size.x / 2;
    final center = Vector2(size.x / 2, size.y / 2);
    return (point - center).length <= radius;
  }




  // Move unit to new grid coordinates with animation
  Future<void> moveTo(
    int newX, 
    int newY, 
    {
      List<TileModel>? path, 
      double stepDuration = 0.3,
      Future<void> Function(TileModel)? onTileEntered,
    }
  ) async {
    final game = findParent<MyGame>();
    if (game == null) return;
    
    if (path != null && path.isNotEmpty) {
      
      List<TileModel> actualPath = path;
      
      for (int i = 0; i < actualPath.length; i++) {
        final tile = actualPath[i];
        final targetPos = game.getTilePosition(tile.x, tile.y);
        
        if (targetPos != null) {
          final completer = Completer<void>();
          
          add(
            MoveEffect.to(
              targetPos,
              EffectController(
                duration: stepDuration,
                curve: Curves.linear,
              ),
              onComplete: () {
                completer.complete();
              },
            ),
          );
          
          // Wait for visual move to finish
          await completer.future;
          
          // Update model coordinates step-by-step
          unitModel.x = tile.x;
          unitModel.y = tile.y;
          
          // Trigger logical tile enter (can be async, e.g. for ambush)
          if (onTileEntered != null) {
             await onTileEntered(tile);
          }
          
          // Check death after callback (ambush might have killed us)
          if (unitModel.currentHP <= 0) {
              // Stop movement processing if dead
              break; 
          }
        }
      }
      
    } else {
      // Direct movement (fallback)
      final targetPos = game.getTilePosition(newX, newY);
      if (targetPos == null) return;

      final completer = Completer<void>();
      
      add(
        MoveEffect.to(
          targetPos,
          EffectController(
            duration: 0.6,
            curve: Curves.elasticOut,
          ),
          onComplete: () {
             completer.complete();
          },
        ),
      );
      
      await completer.future;
      
      // Update coordinates
      unitModel.x = newX;
      unitModel.y = newY;
      
      if (onTileEntered != null) {
          final tile = game.gridData.getTileAt(newX, newY);
          if (tile != null) await onTileEntered(tile);
      }
    }
    
    // Ensure final consistency if not dead
    if (unitModel.currentHP > 0) {
        unitModel.x = newX;
        unitModel.y = newY;
    }
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
