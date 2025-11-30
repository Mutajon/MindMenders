import 'dart:math';
import 'tile_model.dart';

class GridData {
  final int gridSize;
  late List<List<TileModel>> tiles;

  GridData({this.gridSize = 10}) {
    _initializeGrid();
  }

  void _initializeGrid() {
    final random = Random();
    tiles = List.generate(
      gridSize,
      (x) => List.generate(
        gridSize,
        (y) {
          // Randomly assign tile types for variety
          final types = [
            {'type': 'grass', 'description': 'A patch of green grass'},
            {'type': 'water', 'description': 'Clear blue water'},
            {'type': 'building', 'description': 'A small structure'},
          ];
          final tileData = types[random.nextInt(types.length)];
          
          return TileModel(
            x: x,
            y: y,
            type: tileData['type']!,
            description: tileData['description']!,
            walkable: tileData['type'] == 'grass',
          );
        },
      ),
    );
  }

  TileModel? getTileAt(int x, int y) {
    if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) {
      return tiles[x][y];
    }
    return null;
  }
}
