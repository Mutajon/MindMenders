import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../models/tile_model.dart';
import '../game.dart';
import '../utils/grid_utils.dart';

class IsometricTile extends PositionComponent with TapCallbacks {
  final TileModel tileModel;
  final GridUtils gridUtils;

  bool _isHovered = false;
  bool _isMovementTarget = false;

  IsometricTile({
    required this.tileModel,
    required this.gridUtils,
  }) : super(
          size: Vector2(gridUtils.tileWidth, gridUtils.tileHeight),
          anchor: Anchor.center,
        );

  @override
  void onLoad() {
    super.onLoad();
    // Use GridUtils for isometric positioning
    position = gridUtils.gridToScreen(tileModel.x, tileModel.y);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Get hex path from GridUtils (pointy-top orientation)
    final path = gridUtils.getHexPath();

    // Choose color based on tile type
    Color fillColor;
    switch (tileModel.type) {
      case 'grass':
        fillColor = const Color(0xFF4CAF50);
        break;
      case 'water':
        fillColor = const Color(0xFF2196F3);
        break;
      case 'building':
        fillColor = const Color(0xFF9E9E9E);
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

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);
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
    return gridUtils.containsPoint(point);
  }

  @override
  void onTapDown(TapDownEvent event) {
    final game = findParent<MyGame>();
    if (game != null) {
      game.handleTileTap(tileModel);
    }
  }
}
