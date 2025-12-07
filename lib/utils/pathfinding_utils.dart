import 'dart:collection';
import '../models/tile_model.dart';
import '../data/grid_data.dart';

class _TileNode {
  final TileModel tile;
  final int distance;
  final _TileNode? parent;

  _TileNode(this.tile, this.distance, [this.parent]);
}

class PathfindingUtils {
  // Find a path between start and end coordinates
  static List<TileModel> findPath({
    required int startX,
    required int startY,
    required int endX,
    required int endY,
    required GridData gridData,
    Set<String>? blockedTiles,
  }) {
    final Queue<_TileNode> queue = Queue();
    final Set<String> visited = {};
    
    final startTile = gridData.getTileAt(startX, startY);
    final endTile = gridData.getTileAt(endX, endY);
    
    if (startTile == null || endTile == null) return [];
    
    queue.add(_TileNode(startTile, 0));
    visited.add('${startTile.x},${startTile.y}');
    
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final currentTile = current.tile;
      
      // Check if we reached the destination
      if (currentTile.x == endX && currentTile.y == endY) {
        return _reconstructPath(current);
      }
      
      // Get neighbors
      final neighbors = _getNeighbors(currentTile.x, currentTile.y, gridData);
      
      for (final neighbor in neighbors) {
        final key = '${neighbor.x},${neighbor.y}';
        
        if (visited.contains(key)) continue;
        if (blockedTiles != null && blockedTiles.contains(key)) continue;
        if (!neighbor.walkable) continue;
        
        visited.add(key);
        queue.add(_TileNode(neighbor, current.distance + 1, current));
      }
    }
    
    return [];
  }

  static List<TileModel> _reconstructPath(_TileNode node) {
    final List<TileModel> path = [];
    _TileNode? current = node;
    
    while (current != null) {
      path.add(current.tile);
      current = current.parent;
    }
    
    // Reverse to get path from start to end
    return path.reversed.toList();
  }

  // Calculate all reachable tiles from a starting position within a given range
  // Uses Breadth-First Search (BFS)
  static List<TileModel> calculateReachableTiles({
    required int startX,
    required int startY,
    required int range,
    required GridData gridData,
    Set<String>? blockedTiles,
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

      // Get neighbors using axial hex coordinates
      final neighbors = _getNeighbors(currentTile.x, currentTile.y, gridData);

      for (final neighbor in neighbors) {
        final key = '${neighbor.x},${neighbor.y}';

        // Skip if already visited
        if (visited.contains(key)) continue;

        // Skip if not walkable
        if (visited.contains(key)) continue;
        
        // Skip if blocked
        if (blockedTiles != null && blockedTiles.contains(key)) continue;

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
// ... existing _getNeighbors ...

  static List<TileModel> _getNeighbors(int x, int y, GridData gridData) {
    final List<TileModel> neighbors = [];

    // Axial hex coordinate neighbors (same for all positions - no row parity)
    // These correspond to the 6 directions in our isometric hex grid
    final offsets = [
      [1, 0],   // Right (toward +x in screen)
      [-1, 0],  // Left (toward -x in screen)
      [0, 1],   // Lower-left diagonal
      [0, -1],  // Upper-right diagonal
      [1, 1],   // Bottom (Down)
      [-1, -1], // Top (Up)
    ];

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


