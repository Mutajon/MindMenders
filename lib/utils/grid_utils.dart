import 'dart:ui';
import 'package:flame/components.dart';

/// Utility class for isometric hex grid coordinate calculations.
/// All grid-based components should use this for positioning.
///
/// The hex shape and spacing are mathematically derived to ensure
/// perfect tessellation - change tileWidth/tileHeight and everything adapts.
class GridUtils {
  // Tile dimensions - the visible size of each hex
  final double tileWidth; // Horizontal span of hex
  final double tileHeight; // Vertical span of hex

  // Derived spacing values (for isometric projection)
  late final double hStep; // Horizontal spacing between adjacent tiles
  late final double vStep; // Vertical spacing for isometric depth

  GridUtils({this.tileWidth = 64.0, this.tileHeight = 32.0}) {
    // Spacing for proper isometric diamond tessellation
    // Standard flat-topped hex spacing is 0.75 width.
    // We use slightly more than 0.5 height (0.6) to provide vertical spacing.
    hStep = tileWidth * 0.82; // 48
    vStep = tileHeight * 0.48; // 19.2 (was 16)
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
    final w = tileWidth / 2; // Half width
    final h = tileHeight / 2; // Half height

    return [
      Vector2(-w * 0.5, -h), // Top-left
      Vector2(w * 0.5, -h), // Top-right
      Vector2(w, 0), // Right
      Vector2(w * 0.5, h), // Bottom-right
      Vector2(-w * 0.5, h), // Bottom-left
      Vector2(-w, 0), // Left
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
      (x + 1, y), // Right (Down-Right)
      (x - 1, y), // Left (Up-Left)
      (x, y + 1), // Lower-left (Down-Left)
      (x, y - 1), // Upper-right (Up-Right)
      (x + 1, y + 1), // Bottom (Down)
      (x - 1, y - 1), // Top (Up)
    ];
  }

  /// Check if two tiles are neighbors
  bool isNeighbor(int x1, int y1, int x2, int y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;

    // Check against the 6 valid neighbor offsets
    // (1,0), (-1,0), (0,1), (0,-1), (1,1), (-1,-1)
    return (dx == 1 && dy == 0) ||
        (dx == -1 && dy == 0) ||
        (dx == 0 && dy == 1) ||
        (dx == 0 && dy == -1) ||
        (dx == 1 && dy == 1) ||
        (dx == -1 && dy == -1);
  }

  /// Get all tiles within a certain range (in number of steps/hexes)
  List<(int, int)> getTilesInRange(int startX, int startY, int range) {
    final visited = <(int, int)>{};
    final queue = <(int, int, int)>[(startX, startY, 0)];
    final result = <(int, int)>[];

    visited.add((startX, startY));

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final cx = current.$1;
      final cy = current.$2;
      final dist = current.$3;

      if (dist > 0) result.add((cx, cy));

      if (dist < range) {
        for (final n in getNeighbors(cx, cy)) {
          if (!visited.contains(n)) {
            visited.add(n);
            queue.add((n.$1, n.$2, dist + 1));
          }
        }
      }
    }
    return result;
  }
}
