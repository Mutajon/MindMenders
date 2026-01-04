import '../models/tile_model.dart';
import '../models/tile_definition.dart';
import 'tile_database.dart';

class GridData {
  final int gridSize;
  late List<List<TileModel>> tiles;

  // Store unit placement data from tileGrid
  final Map<String, String> unitPlacements = {}; // key: 'x,y', value: unitName

  // Pre-defined tile grid from level editor (required)
  final List<List<TileDefinition>> tileGrid;

  GridData({required this.gridSize, required this.tileGrid}) {
    _initializeGrid();
  }

  void _initializeGrid() {
    // Create tiles indexed as tiles[x][y] to match the rest of the codebase
    tiles = List.generate(
      gridSize,
      (x) => List.generate(gridSize, (y) {
        final tileDef = tileGrid[y][x];

        // Store unit placement for later spawning
        if (tileDef.unitName != null && tileDef.unitName!.isNotEmpty) {
          unitPlacements['$x,$y'] = tileDef.unitName!;
        }

        return TileDatabase.create(
          tileDef.type,
          x,
          y,
          alliance: tileDef.alliance ?? 'Neutral',
        );
      }),
    );
  }

  TileModel? getTileAt(int x, int y) {
    if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) {
      return tiles[x][y];
    }
    return null;
  }

  String? getUnitAt(int x, int y) {
    return unitPlacements['$x,$y'];
  }
}
