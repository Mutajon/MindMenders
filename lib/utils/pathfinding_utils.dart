import 'dart:collection';
import '../models/tile_model.dart';
import '../models/grid_data.dart';

class PathfindingUtils {
  // Calculate all reachable tiles from a starting position within a given range
  // Uses Breadth-First Search (BFS)
  static List<TileModel> calculateReachableTiles({
    required int startX,
    required int startY,
    required int range,
    required GridData gridData,
  }) {
    final List<TileModel> reachableTiles = [];
    final Set<String> visited = {};
    final Queue<_TileNode> queue = Queue();

    // Add starting tile
    final startTile = gridData.getTileAt(startX, startY);
    if (startTile == null) return [];

    queue.add(_TileNode(startTile, 0));
    visited.add('${startTile.x},${startTile.y}');

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final currentTile = current.tile;
      final currentDist = current.distance;

      // If we've reached the range limit, stop exploring this branch
      if (currentDist >= range) continue;

      // Get neighbors (hexagonal grid)
      // For "odd-r" horizontal layout (shoved rows) or similar, we need specific offsets
      // Based on IsometricTile logic:
      // Even rows (y%2==0): (x-1, y-1), (x, y-1), (x-1, y), (x+1, y), (x-1, y+1), (x, y+1)
      // Odd rows (y%2!=0): (x, y-1), (x+1, y-1), (x-1, y), (x+1, y), (x, y+1), (x+1, y+1)
      
      final neighbors = _getNeighbors(currentTile.x, currentTile.y, gridData);

      for (final neighbor in neighbors) {
        final key = '${neighbor.x},${neighbor.y}';
        
        // Skip if already visited
        if (visited.contains(key)) continue;
        
        // Skip if not walkable
        if (!neighbor.walkable) continue;

        // Add to reachable list
        reachableTiles.add(neighbor);
        visited.add(key);
        
        // Add to queue for further exploration
        queue.add(_TileNode(neighbor, currentDist + 1));
      }
    }

    return reachableTiles;
  }

  static List<TileModel> _getNeighbors(int x, int y, GridData gridData) {
    final List<TileModel> neighbors = [];
    
    // Hexagonal grid offsets depend on row parity (even/odd y)
    // This assumes "odd-r" or similar offset coordinates used in map generation
    // Adjust based on your specific grid layout if needed
    
    List<List<int>> offsets;
    if (y % 2 == 0) {
      // Even row
      offsets = [
        [-1, -1], [0, -1], // Top-left, Top-right
        [-1, 0], [1, 0],   // Left, Right
        [-1, 1], [0, 1]    // Bottom-left, Bottom-right
      ];
    } else {
      // Odd row
      offsets = [
        [0, -1], [1, -1],  // Top-left, Top-right
        [-1, 0], [1, 0],   // Left, Right
        [0, 1], [1, 1]     // Bottom-left, Bottom-right
      ];
    }

    for (final offset in offsets) {
      final nx = x + offset[0];
      final ny = y + offset[1];
      
      final neighbor = gridData.getTileAt(nx, ny);
      if (neighbor != null) {
        neighbors.add(neighbor);
      }
    }

    return neighbors;
  }
}

class _TileNode {
  final TileModel tile;
  final int distance;

  _TileNode(this.tile, this.distance);
}
