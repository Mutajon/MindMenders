import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../models/tile_model.dart';
import '../game.dart';

class IsometricTile extends PositionComponent with TapCallbacks {
  final TileModel tileModel;
  final double tileWidth;
  final double tileHeight;
  
  bool _isHovered = false;
  bool _isMovementTarget = false;

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
    // Calculate isometric position with increased spacing for hexagons
    // Hexagons need more horizontal space than diamonds
    final isoX = (tileModel.x - tileModel.y) * tileWidth * 0.75;
    final isoY = (tileModel.x + tileModel.y) * tileHeight * 0.5;
    position = Vector2(isoX, isoY);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Define the hexagon shape (flat-top orientation in isometric view)
    final w = tileWidth / 2;
    final h = tileHeight / 2;
    
    final path = Path()
      ..moveTo(-w * 0.5, -h) // Top-left
      ..lineTo(w * 0.5, -h) // Top-right
      ..lineTo(w, 0) // Right
      ..lineTo(w * 0.5, h) // Bottom-right
      ..lineTo(-w * 0.5, h) // Bottom-left
      ..lineTo(-w, 0) // Left
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
    // Check if point is inside the hexagon shape
    final w = tileWidth / 2;
    final h = tileHeight / 2;
    
    // Hexagon vertices (same as in render method)
    final vertices = [
      Vector2(-w * 0.5, -h), // Top-left
      Vector2(w * 0.5, -h),  // Top-right
      Vector2(w, 0),         // Right
      Vector2(w * 0.5, h),   // Bottom-right
      Vector2(-w * 0.5, h),  // Bottom-left
      Vector2(-w, 0),        // Left
    ];
    
    // Use cross product to check if point is on the correct side of each edge
    bool isInsidePolygon(Vector2 p, List<Vector2> verts) {
      for (int i = 0; i < verts.length; i++) {
        final v1 = verts[i];
        final v2 = verts[(i + 1) % verts.length];
        final edge = v2 - v1;
        final toPoint = p - v1;
        if (edge.x * toPoint.y - edge.y * toPoint.x < 0) {
          return false;
        }
      }
      return true;
    }
    
    return isInsidePolygon(point, vertices);
  }
  
  @override
  void onTapDown(TapDownEvent event) {
    final game = findParent<MyGame>();
    if (game != null) {
      game.handleTileTap(tileModel);
    }
  }
}

