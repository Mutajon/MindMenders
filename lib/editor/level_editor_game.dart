import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import '../models/level_model.dart';
import '../models/tile_definition.dart';
import '../models/tile_model.dart';
import '../components/isometric_tile.dart';
import '../utils/grid_utils.dart';

class LevelEditorGame extends Forge2DGame
    with MouseMovementDetector, KeyboardEvents {
  final LevelModel level;
  late GridUtils gridUtils;
  List<List<TileDefinition>> tileGrid = [];

  @override
  void onMouseMove(PointerHoverInfo info) {
    handleMouseMove(info.eventPosition.widget);
  }

  // Brush state - expanded to support different brush modes
  String currentBrushMode = 'tile'; // 'tile', 'control', 'enemy', 'mender'
  String currentBrushOption = 'Dendrite'; // Changes based on mode
  bool isBrushActive = false;

  // Track last hovered tile to reduce debug spam
  IsometricTile? _lastHoveredTile;

  void handleMouseMove(Vector2 position) {
    // In the level editor, we use the position directly as it's already in game world space
    // camera.globalToLocal() doesn't work correctly here because the camera viewport
    // isn't set up the same way as in the main game

    IsometricTile? currentlyHovered;

    for (final component in children.whereType<IsometricTile>()) {
      final isHovered = component.containsPoint(position);
      component.setHovered(isHovered);
      if (isHovered) {
        currentlyHovered = component;
      }
    }

    // Only log when hover changes
    if (currentlyHovered != _lastHoveredTile) {
      _lastHoveredTile = currentlyHovered;
    }
  }

  void handleTapAt(Vector2 position) {
    // Use position directly (already in world space for our purposes)
    for (final component in children.whereType<IsometricTile>()) {
      if (component.containsPoint(position)) {
        handleTileTap(component.tileModel);
        break;
      }
    }
  }

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
    // Clear existing tiles if any
    children.whereType<IsometricTile>().forEach((t) => t.removeFromParent());

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

  void handleTileTap(TileModel tileModel) {
    print(
      '🔧 handleTileTap called: tile=(${tileModel.x}, ${tileModel.y}), brushActive=$isBrushActive, mode=$currentBrushMode, option=$currentBrushOption',
    );

    if (!isBrushActive) {
      print('🔧 Brush not active, ignoring tap');
      return;
    }

    final currentTile = tileGrid[tileModel.y][tileModel.x];
    print(
      '🔧 Current tile: ${currentTile.type}, alliance=${currentTile.alliance}, unit=${currentTile.unitName}',
    );

    // Apply brush based on current mode
    switch (currentBrushMode) {
      case 'tile':
        // Change tile type
        print('🔧 Changing tile type to $currentBrushOption');
        tileGrid[tileModel.y][tileModel.x] = TileDefinition(
          x: tileModel.x,
          y: tileModel.y,
          type: currentBrushOption,
          alliance: currentTile.alliance,
          unitName: currentTile.unitName,
        );
        break;

      case 'control':
        // Change tile alliance/control
        String alliance = currentBrushOption; // 'Hive', 'Menders', 'Neutral'
        print('🔧 Changing tile control to $alliance');
        tileGrid[tileModel.y][tileModel.x] = TileDefinition(
          x: tileModel.x,
          y: tileModel.y,
          type: currentTile.type,
          alliance: alliance,
          unitName: currentTile.unitName,
        );
        break;

      case 'enemy':
      case 'mender':
        // Place unit (replaces existing unit if any)
        print('🔧 Placing unit $currentBrushOption');
        tileGrid[tileModel.y][tileModel.x] = TileDefinition(
          x: tileModel.x,
          y: tileModel.y,
          type: currentTile.type,
          alliance: currentTile.alliance,
          unitName: currentBrushOption,
        );
        break;
    }

    print('🔧 Refreshing grid...');
    // Refresh visual
    _buildGrid();
  }

  LevelModel getUpdatedLevel() {
    final updatedLevel = LevelModel(
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
      enemyControlledTilesStartingPosition:
          level.enemyControlledTilesStartingPosition,
      neuronCoordinates: level.neuronCoordinates,
      brainDamageCoordinates: level.brainDamageCoordinates,
      memoryCoordinates: level.memoryCoordinates,
      startingEnemyCoordinates: level.startingEnemyCoordinates,
      tileGrid: tileGrid,
    );

    return updatedLevel;
  }
}
