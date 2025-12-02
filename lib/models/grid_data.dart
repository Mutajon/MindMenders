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
          final rand = random.nextDouble();
          String type;
          String description;
          bool walkable;

          if (rand < 0.7) {
            type = 'Dendrite';
            description = 'A conductive dendrite pathway';
            walkable = true;
          } else if (rand < 0.9) {
            type = 'Neuron';
            description = 'A processing neuron node';
            walkable = false; // Buildings were not walkable
          } else {
            type = 'Brain Damage';
            description = 'Damaged neural tissue';
            walkable = false; // Water was not walkable
          }
          
          return TileModel(
            x: x,
            y: y,
            type: type,
            description: description,
            walkable: walkable,
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
