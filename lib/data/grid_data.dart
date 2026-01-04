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
    tiles = List.generate(
      gridSize,
      (y) => List.generate(gridSize, (x) {
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
