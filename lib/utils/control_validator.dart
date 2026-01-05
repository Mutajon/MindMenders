import '../data/grid_data.dart';
import '../models/tile_model.dart';
import 'dart:collection';

class ControlValidator {
  /// Checks if a tile is connected to at least one Memory tile of the same faction
  /// through a path of controlled tiles (BFS/flood-fill algorithm)
  static bool isConnectedToMemory(
    TileModel tile,
    String faction,
    GridData gridData,
  ) {
    // If the tile is not controlled by the faction, it's not connected
    if (tile.alliance != faction) {
      return false;
    }

    // BFS to find path to Memory tile
    final visited = <String>{};
    final queue = Queue<TileModel>();
    queue.add(tile);
    visited.add('${tile.x},${tile.y}');

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();

      // If we found a Memory tile controlled by this faction, we're connected!
      if (current.type == 'Memory' && current.alliance == faction) {
        return true;
      }

      // Get neighbors and add to queue if they're controlled by this faction
      final neighbors = _getNeighborTiles(current, gridData);
      for (final neighbor in neighbors) {
        final key = '${neighbor.x},${neighbor.y}';

        // Only traverse tiles controlled by this faction
        if (!visited.contains(key) && neighbor.alliance == faction) {
          visited.add(key);
          queue.add(neighbor);
        }
      }
    }

    // No path found to any Memory tile
    return false;
  }

  /// Get all neighboring tiles for a given tile
  static List<TileModel> _getNeighborTiles(TileModel tile, GridData gridData) {
    final neighbors = <TileModel>[];

    // Hexagonal grid neighbor offsets (assuming flat-top hexagons)
    final offsets = tile.y % 2 == 0
        ? [
            (-1, 0), (1, 0), // Left, Right
            (0, -1), (1, -1), // Top-Left, Top-Right
            (0, 1), (1, 1), // Bottom-Left, Bottom-Right
          ]
        : [
            (-1, 0), (1, 0), // Left, Right
            (-1, -1), (0, -1), // Top-Left, Top-Right
            (-1, 1), (0, 1), // Bottom-Left, Bottom-Right
          ];

    for (final offset in offsets) {
      final nx = tile.x + offset.$1;
      final ny = tile.y + offset.$2;
      final neighbor = gridData.getTileAt(nx, ny);

      if (neighbor != null) {
        neighbors.add(neighbor);
      }
    }

    return neighbors;
  }
}
