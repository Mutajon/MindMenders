import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../models/tile_model.dart';
import '../game.dart';
import '../utils/grid_utils.dart';

class IsometricTile extends PositionComponent with TapCallbacks {
  final TileModel tileModel;
  final GridUtils gridUtils;
  final Vector2 centeringOffset;

  bool _isHovered = false;
  bool _isMovementTarget = false;

  IsometricTile({
    required this.tileModel,
    required this.gridUtils,
    required this.centeringOffset,
  }) : super(
          size: Vector2(gridUtils.tileWidth, gridUtils.tileHeight),
          anchor: Anchor.center,
        );

  @override
  void onLoad() {
    super.onLoad();
    // Apply both grid position and centering offset in onLoad
    // so tile has final position before units read it
    position = gridUtils.gridToScreen(tileModel.x, tileModel.y) + centeringOffset;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Translate canvas to center of component so hex is drawn centered
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    // Get hex path from GridUtils (pointy-top orientation)
    final path = gridUtils.getHexPath();

    // Choose color based on tile type
    Color fillColor;
    switch (tileModel.type) {
      case 'Dendrite':
        fillColor = const Color(0xFF808080); // Gray
        break;
      case 'Brain Damage':
        fillColor = Colors.transparent; // Transparent
        break;
      case 'Neuron':
        fillColor = const Color(0xFFFF00FF); // Fuchsia Purple
        break;
      default:
        fillColor = const Color(0xFFBDBDBD);
    }

    // Brighten color if hovered
    if (_isHovered) {
      fillColor = Color.lerp(fillColor, Colors.white, 0.3)!;
    }

    // Draw the tile
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // Draw movement target highlight (blue glow)
    if (_isMovementTarget) {
      final highlightPaint = Paint()
        ..color = const Color(0xFF448AFF).withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, highlightPaint);

      final highlightBorderPaint = Paint()
        ..color = const Color(0xFF448AFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(path, highlightBorderPaint);
    }

    // Draw border (skip for Brain Damage to keep it fully transparent)
    if (tileModel.type != 'Brain Damage') {
      final borderPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawPath(path, borderPaint);
    }
    
    canvas.restore();
  }

  void setHovered(bool isHovered) {
    _isHovered = isHovered;
  }

  void setMovementTarget(bool isTarget) {
    _isMovementTarget = isTarget;
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    // Use GridUtils for hit detection
    // Adjust point to be relative to center (since GridUtils assumes 0,0 center)
    return gridUtils.containsPoint(point - size / 2);
  }

  @override
  void onTapDown(TapDownEvent event) {
    final game = findParent<MyGame>();
    if (game != null) {
      game.handleTileTap(tileModel);
    }
  }
}
