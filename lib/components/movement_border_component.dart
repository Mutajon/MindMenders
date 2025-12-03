import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/tile_model.dart';
import '../utils/grid_utils.dart';
import '../game.dart';

class MovementBorderComponent extends PositionComponent with HasGameRef<MyGame> {
  final Set<TileModel> _tiles = {};
  final Path _borderPath = Path();
  
  // Animation state
  double _animationTime = 0.0;
  
  MovementBorderComponent() : super(priority: 10); // Render above tiles

  void updateTiles(Set<TileModel> tiles) {
    _tiles.clear();
    _tiles.addAll(tiles);
    _recalculatePath();
  }

  void _recalculatePath() {
    _borderPath.reset();
    if (_tiles.isEmpty) return;

    final gridUtils = gameRef.gridUtils;
    final vertices = gridUtils.getHexVertices();
    
    // Mapping from neighbor index (0..5) to edge index (0..5)
    // Neighbor 0 (Right) -> Edge 2 (Right -> Bottom-Right)
    // Neighbor 1 (Left) -> Edge 5 (Left -> Top-Left)
    // Neighbor 2 (Down-Left) -> Edge 4 (Bottom-Left -> Left)
    // Neighbor 3 (Up-Right) -> Edge 1 (Top-Right -> Right)
    // Neighbor 4 (Down) -> Edge 3 (Bottom-Right -> Bottom-Left)
    // Neighbor 5 (Up) -> Edge 0 (Top-Left -> Top-Right)
    final edgeMapping = {
      0: 2, 
      1: 5, 
      2: 4, 
      3: 1, 
      4: 3, 
      5: 0
    };

    for (final tile in _tiles) {
      final center = gameRef.getTilePosition(tile.x, tile.y);
      if (center == null) continue;

      // Check all 6 neighbors
      final neighbors = gridUtils.getNeighbors(tile.x, tile.y);
      
      for (int i = 0; i < 6; i++) {
        final (nx, ny) = neighbors[i];
        
        // Check if neighbor is in the set
        // We need to find if any tile in _tiles has these coordinates
        // Optimization: _tiles is a Set, but TileModel equality depends on instance or id?
        // Assuming TileModel uses default equality (identity), we need to find by coords.
        // But wait, highlightedMovementTiles contains specific instances from GridData.
        // And GridData returns the same instances.
        // So we can check if the neighbor tile instance is in _tiles.
        
        final neighborTile = gameRef.gridData.getTileAt(nx, ny);
        final isNeighborInSet = neighborTile != null && _tiles.contains(neighborTile);
        
        if (!isNeighborInSet) {
          // This is a boundary edge
          final edgeIndex = edgeMapping[i]!;
          final v1 = vertices[edgeIndex];
          final v2 = vertices[(edgeIndex + 1) % 6];
          
          // Add segment to path
          _borderPath.moveTo(center.x + v1.x, center.y + v1.y);
          _borderPath.lineTo(center.x + v2.x, center.y + v2.y);
        }
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animationTime += dt;
  }

  @override
  void render(Canvas canvas) {
    if (_tiles.isEmpty) return;

    // Create a gradient paint
    // We'll use a sweep gradient centered on the group, or just a linear one
    // Let's use a linear gradient that rotates or shifts
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Animated gradient
    // Use a ping-pong loop for smooth transition
    // Cycle duration: 4 seconds
    final cycle = _animationTime % 4.0;
    final t = (cycle > 2.0 ? 4.0 - cycle : cycle) / 2.0; // 0 -> 1 -> 0
    
    // Interpolate start and end points
    final startOffset = Offset.lerp(const Offset(0, 0), const Offset(50, 50), t)!;
    final endOffset = Offset.lerp(const Offset(200, 200), const Offset(250, 250), t)!;
    
    paint.shader = ui.Gradient.linear(
      startOffset,
      endOffset,
      [
        const Color(0xFF448AFF), // Blue
        const Color(0xFF00BCD4), // Cyan
        const Color(0xFF448AFF), // Blue
      ],
      [0.0, 0.5, 1.0],
      TileMode.mirror,
    );

    canvas.drawPath(_borderPath, paint);
    
    // Optional: Add a glow
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..color = const Color(0xFF448AFF).withValues(alpha: 0.5);
      
    canvas.drawPath(_borderPath, glowPaint);
  }
}
