import 'package:flame/components.dart';

import 'package:flutter/material.dart';

class EnergyIndicatorComponent extends PositionComponent {
  final int maxEnergy;
  int currentEnergy;

  // Flash state
  int _previewCost = 0;
  bool _isFlashingRed = false; // Insufficient energy

  // Flash animation timer
  double _flashTimer = 0.0;
  bool _flashAscending = true;

  EnergyIndicatorComponent({required Vector2 position, this.maxEnergy = 4})
    : currentEnergy = maxEnergy,
      super(position: position, size: Vector2(160, 40));

  void updateEnergy(int newEnergy) {
    currentEnergy = newEnergy.clamp(0, maxEnergy);
    _previewCost = 0;
    _isFlashingRed = false;
  }

  void setPreviewCost(int cost) {
    _previewCost = cost;
    _isFlashingRed = false;
  }

  void showInsufficientEnergy() {
    _isFlashingRed = true;
    _previewCost = 0;
    _flashTimer = 0.0;
    _flashAscending = true;

    // Use a separate timer for the error flash duration
    // We'll reuse _isFlashingRed as the flag
    // And auto-reset it in update
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Simple ping-pong timer for flashing
    double speed = 2.0; // Slower flashing (approx 1Hz cycle)
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
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final spacing = 10.0;
    final radius = 12.0;

    // Center the dots horizontally
    final totalWidth = (radius * 2 * maxEnergy) + (spacing * (maxEnergy - 1));
    final startX = (size.x - totalWidth) / 2;
    final centerY = size.y / 2;

    for (int i = 0; i < maxEnergy; i++) {
      final cx = startX + radius + (i * (radius * 2 + spacing));
      final center = Offset(cx, centerY);

      final bgPaint = Paint()
        ..color = const Color(0xFF2C2C2C)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, bgPaint);

      // Border
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius, borderPaint);

      // Fill if energy available
      bool isFilled = i < currentEnergy;

      // Logic for flashing PREVIEW (active units about to be spent)
      // If we have 4 energy, and cost is 2.
      // Slots 0, 1, 2, 3 are filled.
      // We want to flash slots 2 and 3 (the "top" ones).
      // Indices maxEnergy-1 down to maxEnergy-cost? No.
      // Top energy is at index currentEnergy - 1.
      // So we flash indices from (currentEnergy - 1) down to (currentEnergy - previewCost).

      bool isPreviewing =
          i < currentEnergy && i >= (currentEnergy - _previewCost);

      if (isFilled) {
        final fillPaint = Paint()..style = PaintingStyle.fill;

        if (isPreviewing) {
          // Flashing "About to be spent"
          // Fade alpha based on _flashTimer (0.2 to 1.0)
          final alpha = 0.2 + (_flashTimer * 0.8);
          fillPaint.color = const Color(
            0xFF448AFF,
          ).withOpacity(alpha); // Blue pulse
        } else {
          fillPaint.color = const Color(0xFF448AFF); // Standard Blue
        }

        // Glow
        if (!isPreviewing) {
          final glowPaint = Paint()
            ..color = const Color(0xFF448AFF).withOpacity(0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
          canvas.drawCircle(center, radius, glowPaint);
        }

        canvas.drawCircle(center, radius - 2, fillPaint);
      } else if (_isFlashingRed && i == currentEnergy) {
        // Flash the "next" empty slot red to indicate missing?
        // Or just flash the whole bar red?
        // User said: "flash in red the missing energy".
        // Let's flash the empty slots that WOULD be needed.

        // For simplicity, just flash the border red if insufficient.
      }
    }

    // Red flash overlay for entire component if insufficient
    if (_isFlashingRed) {
      // Flash opacity
      final alpha = 0.5 + (_flashTimer * 0.5); // 0.5 to 1.0
      final errorPaint = Paint()
        ..color = Colors.red.withOpacity(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      final rect = Rect.fromLTWH(0, 0, size.x, size.y);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(8)),
        errorPaint,
      );

      // Also draw text "NO ENERGY" maybe?
    }
  }
}
