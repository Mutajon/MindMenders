import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/unit_model.dart';

class HealthBarComponent extends PositionComponent {
  final UnitModel unitModel;
  
  // State for damage preview
  int _previewDamageAmount = 0;
  bool _willLoseShield = false;
  double _currentFlashIntensity = 0.0;
  
  // Visibility control
  bool isVisible = false;

  HealthBarComponent({
    required this.unitModel,
  }) : super(priority: 1000); // Very high priority to ensure it's on top

  void setPreviewDamage(int amount, bool willLoseShield, double flashIntensity) {
    _previewDamageAmount = amount;
    _willLoseShield = willLoseShield;
    _currentFlashIntensity = flashIntensity;
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible || unitModel.maxHP <= 0) return;

    // Drawing logic adapted from UnitComponent
    const segmentWidth = 10.0;
    const segmentHeight = 6.0;
    const spacing = 2.0;
    final totalWidth = (unitModel.maxHP * segmentWidth) + ((unitModel.maxHP - 1) * spacing);
    
    // Position is relative to this component's position (which we anchor at center)
    // We want to center the bar horizontally
    final startLeft = -totalWidth / 2;
    final top = 0.0; // Drawing at the anchor point (top-left of bar area)

    // Draw each health segment
    for (int i = 0; i < unitModel.maxHP; i++) {
        final left = startLeft + i * (segmentWidth + spacing);
        final segmentRect = Rect.fromLTWH(left, top, segmentWidth, segmentHeight);
        
        // 1. Draw Background (Black)
        final bgPaint = Paint()..color = Colors.black;
        canvas.drawRect(segmentRect, bgPaint);
        
        bool isNormallyFilled = i < unitModel.currentHP;
        bool isPreviewLost = false;
        
        if (isNormallyFilled && _previewDamageAmount > 0) {
            if (i >= (unitModel.currentHP - _previewDamageAmount)) {
                isPreviewLost = true;
            }
        }
        
        // 2. Draw Fill
        if (isNormallyFilled) {
            final fillRect = segmentRect.deflate(1.0); // Slight padding inside
            Paint fillPaint = Paint()..color = const Color(0xFF00FF00); // Default Bright Green
            
            if (isPreviewLost) {
               // Flash from Bright Green to Red to indicate damage
               // We use the flash intensity passed from parent
               final flashColor = Color.lerp(
                   const Color(0xFF00FF00), 
                   const Color(0xFFFF0000), 
                   _currentFlashIntensity
               ) ?? const Color(0xFF00FF00);
               
               fillPaint = Paint()..color = flashColor;
            }
            
            canvas.drawRect(fillRect, fillPaint);
        }
        
        // 3. Draw Border (White)
        final borderPaint = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;
        canvas.drawRect(segmentRect, borderPaint);
    }
  }
}
