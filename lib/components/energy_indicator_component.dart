import 'package:flame/components.dart';

import 'package:flutter/material.dart';

class EnergyIndicatorComponent extends PositionComponent {
  final int maxEnergy;
  int currentEnergy;

  // Flash state
  // Flash state
  int _previewCost = 0;

  // Flash animation timer
  double _flashTimer = 0.0;
  bool _flashAscending = true;

  void showInsufficientEnergy() {
    // No-op for now as we shake the card,
    // but kept for API compatibility if game calls it.
    // We could potentially reset flash timer here if we wanted a visual sync.
  }
  EnergyIndicatorComponent({required Vector2 position, this.maxEnergy = 4})
    : currentEnergy = maxEnergy,
      super(position: position, size: Vector2(160, 40));

  void updateEnergy(int newEnergy) {
    currentEnergy = newEnergy.clamp(0, maxEnergy);
    _previewCost = 0;
  }

  void setPreviewCost(int cost) {
    _previewCost = cost;
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

      // Logic for flashing PREVIEW
      // Calculate how many we can afford and how many are missing
      final int affordablePart = _previewCost > currentEnergy
          ? currentEnergy
          : _previewCost;
      final int missingPart = _previewCost > currentEnergy
          ? _previewCost - currentEnergy
          : 0;

      // Blue Range (About to be spent): [currentEnergy - affordablePart, currentEnergy - 1]
      final bool isBlueFlash =
          i >= (currentEnergy - affordablePart) && i < currentEnergy;

      // Red Range (Missing): [currentEnergy, currentEnergy + missingPart - 1]
      final bool isRedFlash =
          i >= currentEnergy && i < (currentEnergy + missingPart);

      if (isFilled) {
        final fillPaint = Paint()..style = PaintingStyle.fill;

        if (isBlueFlash) {
          // BLUE Flash (Spending)
          final alpha = 0.4 + (_flashTimer * 0.6);
          fillPaint.color = const Color(0xFF448AFF).withOpacity(alpha);
        } else {
          fillPaint.color = const Color(0xFF448AFF); // Static Blue
        }

        // Glow (only if not flashing, or maybe keep it?)
        // User didn't specify, but let's keep it simple.
        canvas.drawCircle(center, radius - 2, fillPaint);

        // Add glow for filled (but maybe pulse it if flashing blue?)
        if (!isBlueFlash) {
          final glowPaint = Paint()
            ..color = const Color(0xFF448AFF).withOpacity(0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
          canvas.drawCircle(center, radius, glowPaint);
        }
      } else {
        // Empty slot
        if (isRedFlash) {
          // RED Flash (Missing)
          final alpha = 0.4 + (_flashTimer * 0.6);
          final redPaint = Paint()
            ..color = const Color(0xFFFF5252).withOpacity(alpha)
            ..style = PaintingStyle.fill;

          // Draw filled red circle
          canvas.drawCircle(center, radius - 2, redPaint);

          // Red Glow
          final redGlow = Paint()
            ..color = const Color(0xFFFF5252).withOpacity(0.6 * alpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
          canvas.drawCircle(center, radius, redGlow);
        }
      }
    }
  }
}
