import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../models/level_model.dart';
import '../models/tile_definition.dart';
import '../models/tile_model.dart';
import '../components/isometric_tile.dart';
import '../utils/grid_utils.dart';

class LevelEditorGame extends FlameGame {
  final LevelModel level;
  late GridUtils gridUtils;
  List<List<TileDefinition>> tileGrid = [];

  LevelEditorGame({required this.level});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    gridUtils = GridUtils();
    tileGrid = level.tileGrid ?? _createDefaultGrid();

    _buildGrid();
  }

  @override
  Color backgroundColor() => const Color(0xFF2C2C2C);

  List<List<TileDefinition>> _createDefaultGrid() {
    return List.generate(
      level.gridSize,
      (y) => List.generate(
        level.gridSize,
        (x) => TileDefinition(x: x, y: y, type: 'Dendrite'),
      ),
    );
  }

  void _buildGrid() {
    // Calculate centering offset based on current screen size
    final offset = gridUtils.getCenteringOffset(size, level.gridSize);

    for (int y = 0; y < level.gridSize; y++) {
      for (int x = 0; x < level.gridSize; x++) {
        final tileDef = tileGrid[y][x];

        // Create tile component (simplified for editor)
        final tile = IsometricTile(
          tileModel: _tileDefToModel(tileDef),
          gridUtils: gridUtils,
          centeringOffset: offset,
        );
        add(tile);
      }
    }
  }

  TileModel _tileDefToModel(TileDefinition def) {
    // Convert TileDefinition to TileModel for rendering
    // All tiles in editor are walkable and controllable
    return TileModel(
      x: def.x,
      y: def.y,
      type: def.type,
      description: def.type,
      walkable: true,
      controllable: true,
      alliance: def.alliance ?? 'Neutral',
    );
  }

  LevelModel getUpdatedLevel() {
    return LevelModel(
      id: level.id,
      name: level.name,
      category: level.category,
      gridSize: level.gridSize,
      neuronTilesCount: level.neuronTilesCount,
      brainDamageTilesCount: level.brainDamageTilesCount,
      memoryTilesCount: level.memoryTilesCount,
      startingEnemiesCount: level.startingEnemiesCount,
      startingEnemyTypes: level.startingEnemyTypes,
      enemyControlledPercentage: level.enemyControlledPercentage,
      tileGrid: tileGrid,
    );
  }
}
