import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'models/grid_data.dart';
import 'models/tile_model.dart';
import 'models/unit_model.dart';
import 'components/isometric_tile.dart';
import 'components/unit_component.dart';

class MyGame extends Forge2DGame {
  late GridData gridData;
  TileModel? hoveredTile;
  UnitModel? hoveredUnit;
  final Function(TileModel?)? onTileHoverChange;
  final Function(UnitModel?)? onUnitHoverChange;
  
  // Keep track of the currently highlighted tile component to update its visual state
  IsometricTile? _highlightedComponent;

  MyGame({this.onTileHoverChange, this.onUnitHoverChange}) : super(gravity: Vector2(0, 10.0));

  @override
  Color backgroundColor() => const Color(0xFF2C2C2C);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Reset camera to ensure 1:1 mapping with screen coordinates
    camera.viewfinder.zoom = 1.0;
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();
    
    // Initialize grid with gridSize = 10
    gridData = GridData(gridSize: 10);
    
    // Calculate offset to center the grid
    // The grid center in isometric space
    final gridCenter = gridData.gridSize / 2;
    final gridCenterX = (gridCenter - gridCenter) * 32; // Will be 0
    final gridCenterY = (gridCenter + gridCenter) * 16; // gridSize * 16
    
    // Offset to move grid to screen center
    final offsetX = size.x / 2 - gridCenterX;
    final offsetY = size.y / 2 - gridCenterY;
    
    // Create and add isometric tiles with offset
    for (int x = 0; x < gridData.gridSize; x++) {
      for (int y = 0; y < gridData.gridSize; y++) {
        final tile = gridData.getTileAt(x, y);
        if (tile != null) {
          final tileComponent = IsometricTile(
            tileModel: tile,
          );
          add(tileComponent);
          // Apply offset after adding
          tileComponent.position.add(Vector2(offsetX, offsetY));
        }
      }
    }
    
    // Create and add a demo unit at grid center
    final demoUnit = UnitModel(
      name: 'Knight',
      hp: 3,
      attackMode: 'Melee',
      damageValue: 2,
      defense: 1,
      specialAbility: 'Shield Bash',
      x: 5,
      y: 5,
    );
    final unitComponent = UnitComponent(unitModel: demoUnit);
    add(unitComponent);
    unitComponent.position.add(Vector2(offsetX, offsetY));
    
    // Create and add an Archer unit at the left side
    final archerUnit = UnitModel(
      name: 'Archer',
      hp: 2,
      attackMode: 'Ranged',
      damageValue: 3,
      defense: 0,
      specialAbility: 'Double Shot',
      x: 0,
      y: 5,
    );
    final archerComponent = UnitComponent(unitModel: archerUnit);
    add(archerComponent);
    archerComponent.position.add(Vector2(offsetX, offsetY));
  }

  void handleMouseMove(Vector2 position) {
    // Convert screen position to world position
    final worldPosition = camera.globalToLocal(position);
    
    // Check for unit hover first (units are on top of tiles)
    UnitModel? newHoveredUnit;
    for (final component in children.whereType<UnitComponent>()) {
      if (component.containsPoint(worldPosition)) {
        newHoveredUnit = component.unitModel;
        break;
      }
    }
    
    if (newHoveredUnit != hoveredUnit) {
      hoveredUnit = newHoveredUnit;
      onUnitHoverChange?.call(hoveredUnit);
    }
    
    // Find the tile that contains this point
    TileModel? newHoveredTile;
    
    // Iterate through all isometric tiles to find which one is hovered
    for (final component in children.whereType<IsometricTile>()) {
      if (component.containsPoint(worldPosition)) {
        newHoveredTile = component.tileModel;
        break;
      }
    }
    
    if (newHoveredTile != hoveredTile) {
      // Clear previous highlight
      if (_highlightedComponent != null) {
        _highlightedComponent!.setHovered(false);
        _highlightedComponent = null;
      }
      
      hoveredTile = newHoveredTile;
      onTileHoverChange?.call(hoveredTile);
      
      // Set new highlight
      if (hoveredTile != null) {
        // Find the component for this tile
        // Since we don't have a direct map, we iterate. Optimization: maintain a map if needed.
        for (final component in children.whereType<IsometricTile>()) {
          if (component.tileModel == hoveredTile) {
            component.setHovered(true);
            _highlightedComponent = component;
            break;
          }
        }
      }
    }
  }
}
