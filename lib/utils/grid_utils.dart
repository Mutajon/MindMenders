import 'dart:ui';
import 'package:flame/components.dart';

/// Utility class for isometric hex grid coordinate calculations.
/// All grid-based components should use this for positioning.
///
/// The hex shape and spacing are mathematically derived to ensure
/// perfect tessellation - change tileWidth/tileHeight and everything adapts.
class GridUtils {
  // Tile dimensions - the visible size of each hex
  final double tileWidth;   // Horizontal span of hex
  final double tileHeight;  // Vertical span of hex

  // Derived spacing values (for isometric projection)
  late final double hStep;  // Horizontal spacing between adjacent tiles
  late final double vStep;  // Vertical spacing for isometric depth

  GridUtils({
    this.tileWidth = 64.0,
    this.tileHeight = 32.0,
  }) {
    // Spacing for proper hex tessellation with isometric projection
    hStep = tileWidth * 0.75;   // 48
    vStep = tileHeight * 0.5;   // 16
  }

  /// Convert grid coordinates to screen position (isometric projection)
  /// Uses the formula: screenX = (x - y) * hStep, screenY = (x + y) * vStep
  Vector2 gridToScreen(int x, int y) {
    final screenX = (x - y) * hStep;
    final screenY = (x + y) * vStep;
    return Vector2(screenX, screenY);
  }

  /// Get screen position for grid center
  Vector2 getGridCenterScreen(int gridSize) {
    final centerCoord = gridSize ~/ 2;
    return gridToScreen(centerCoord, centerCoord);
  }

  /// Calculate offset to center grid on screen
  Vector2 getCenteringOffset(Vector2 screenSize, int gridSize) {
    final gridCenter = getGridCenterScreen(gridSize);
    return Vector2(
      screenSize.x / 2 - gridCenter.x,
      screenSize.y / 2 - gridCenter.y,
    );
  }

  /// Get hex vertices for rendering (flat-top orientation for isometric view)
  /// This shape tessellates properly with the 0.75/0.5 spacing formula.
  List<Vector2> getHexVertices() {
    final w = tileWidth / 2;   // Half width
    final h = tileHeight / 2;  // Half height

    return [
      Vector2(-w * 0.5, -h),  // Top-left
      Vector2(w * 0.5, -h),   // Top-right
      Vector2(w, 0),          // Right
      Vector2(w * 0.5, h),    // Bottom-right
      Vector2(-w * 0.5, h),   // Bottom-left
      Vector2(-w, 0),         // Left
    ];
  }

  /// Create a Path for rendering the hex shape
  Path getHexPath() {
    final vertices = getHexVertices();
    final path = Path()..moveTo(vertices[0].x, vertices[0].y);
    for (int i = 1; i < vertices.length; i++) {
      path.lineTo(vertices[i].x, vertices[i].y);
    }
    path.close();
    return path;
  }

  /// Check if a point is inside the hex shape (for hit detection)
  bool containsPoint(Vector2 point) {
    final vertices = getHexVertices();

    // Use cross product to check if point is on the correct side of each edge
    for (int i = 0; i < vertices.length; i++) {
      final v1 = vertices[i];
      final v2 = vertices[(i + 1) % vertices.length];
      final edge = v2 - v1;
      final toPoint = point - v1;
      // Cross product: if negative, point is outside this edge
      if (edge.x * toPoint.y - edge.y * toPoint.x < 0) {
        return false;
      }
    }
    return true;
  }

  /// Get the 6 neighbor coordinates in axial hex grid
  /// For isometric hex, neighbors are at these relative positions
  List<(int, int)> getNeighbors(int x, int y) {
    return [
      (x + 1, y),     // Right (Down-Right)
      (x - 1, y),     // Left (Up-Left)
      (x, y + 1),     // Lower-left (Down-Left)
      (x, y - 1),     // Upper-right (Up-Right)
      (x + 1, y + 1), // Bottom (Down)
      (x - 1, y - 1), // Top (Up)
    ];
  }
}
