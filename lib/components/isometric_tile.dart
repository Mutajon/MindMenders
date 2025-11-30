import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/tile_model.dart';

class IsometricTile extends PositionComponent {
  final TileModel tileModel;
  final double tileWidth;
  final double tileHeight;
  
  bool _isHovered = false;

  IsometricTile({
    required this.tileModel,
    this.tileWidth = 64.0,
    this.tileHeight = 32.0,
  }) : super(
          size: Vector2(tileWidth, tileHeight),
          anchor: Anchor.center,
        );

  @override
  void onLoad() {
    super.onLoad();
    // Calculate isometric position
    final isoX = (tileModel.x - tileModel.y) * tileWidth / 2;
    final isoY = (tileModel.x + tileModel.y) * tileHeight / 2;
    position = Vector2(isoX, isoY);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Define the isometric diamond shape
    final path = Path()
      ..moveTo(0, -tileHeight / 2) // Top
      ..lineTo(tileWidth / 2, 0) // Right
      ..lineTo(0, tileHeight / 2) // Bottom
      ..lineTo(-tileWidth / 2, 0) // Left
      ..close();

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

  @override
  bool containsLocalPoint(Vector2 point) {
    // Check if point is inside the diamond shape
    // Diamond vertices relative to center (anchor is center)
    final top = Vector2(0, -tileHeight / 2);
    final right = Vector2(tileWidth / 2, 0);
    final bottom = Vector2(0, tileHeight / 2);
    final left = Vector2(-tileWidth / 2, 0);
    
    // Use cross product to check if point is on the correct side of each edge
    bool isInsideDiamond(Vector2 p, Vector2 v1, Vector2 v2) {
      final edge = v2 - v1;
      final toPoint = p - v1;
      return edge.x * toPoint.y - edge.y * toPoint.x >= 0;
    }
    
    return isInsideDiamond(point, top, right) &&
           isInsideDiamond(point, right, bottom) &&
           isInsideDiamond(point, bottom, left) &&
           isInsideDiamond(point, left, top);
  }
}

