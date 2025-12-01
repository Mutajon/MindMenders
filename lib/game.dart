import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'models/grid_data.dart';
import 'models/tile_model.dart';
import 'models/unit_model.dart';
import 'models/card_model.dart';
import 'components/isometric_tile.dart';
import 'components/unit_component.dart';
import 'components/card_component.dart';
import 'data/card_database.dart';
import 'utils/pathfinding_utils.dart';
import 'utils/grid_utils.dart';

class MyGame extends Forge2DGame {
  late GridData gridData;
  late GridUtils gridUtils;
  TileModel? hoveredTile;
  UnitModel? hoveredUnit;
  final Function(TileModel?)? onTileHoverChange;
  final Function(UnitModel?)? onUnitHoverChange;
  
  // Keep track of the currently highlighted tile component to update its visual state
  IsometricTile? _highlightedComponent;

  // Tile lookup map for efficient coordinate-based access
  final Map<String, IsometricTile> _tileComponents = {};

  // Get tile component at grid coordinates
  IsometricTile? getTileAt(int x, int y) => _tileComponents['$x,$y'];
  
  // Card system
  List<CardModel> currentPlayerCardPool = [];
  CardComponent? selectedCard;
  
  // Card Execution State
  CardComponent? selectedCardForExecution;
  UnitComponent? selectedUnitForMovement;
  List<TileModel> highlightedMovementTiles = [];
  List<CardModel> discardPile = [];

  MyGame({this.onTileHoverChange, this.onUnitHoverChange}) : super(gravity: Vector2(0, 10.0));

  // Handle card selection (only one card can be selected at a time)
  void selectCard(CardComponent card) {
    // Deselect previously selected card
    if (selectedCard != null && selectedCard != card) {
      selectedCard!.deselect();
    }
    
    // Update selected card reference
    selectedCard = card;
    selectedCardForExecution = card;
    
    // If it's a move card, make units selectable
    if (card.cardModel.type.toLowerCase() == 'move') {
      _setUnitsSelectable(true);
    }
  }
  
  // Deselect current card
  void deselectCard() {
    selectedCard = null;
    selectedCardForExecution = null;
    _setUnitsSelectable(false);
    _clearUnitSelection();
  }

  // Helper to set selectable state for all units
  void _setUnitsSelectable(bool selectable) {
    children.whereType<UnitComponent>().forEach((unit) {
      unit.setSelectable(selectable);
    });
  }
  
  // Helper to clear unit selection
  void _clearUnitSelection() {
    if (selectedUnitForMovement != null) {
      selectedUnitForMovement!.setSelected(false);
      selectedUnitForMovement = null;
    }
    // Clear tile highlights (to be implemented)
  }
  
  // Handle unit selection for movement
  void selectUnitForMovement(UnitComponent unit) {
    // Only allow selection if a move card is active
    if (selectedCardForExecution?.cardModel.type.toLowerCase() != 'move') return;
    
    // Clear previous tile highlights
    _clearTileHighlights();
    
    // Deselect previous unit if any
    if (selectedUnitForMovement != null) {
      selectedUnitForMovement!.setSelected(false);
      selectedUnitForMovement!.setSelectable(false); // Hide halo
    }
    
    // Hide halos from all other units (but keep them clickable)
    children.whereType<UnitComponent>().forEach((u) {
      if (u != unit) {
        u.setSelected(false);
        u.setSelectable(false);
      }
    });
    
    // Select the new unit (show static halo)
    selectedUnitForMovement = unit;
    unit.setSelected(true);
    
    // Calculate reachable tiles
    _calculateAndHighlightMovementTiles(unit);
  }
  
  void _calculateAndHighlightMovementTiles(UnitComponent unit) {
    // Clear previous highlights
    _clearTileHighlights();
    
    // Use pathfinding to find reachable tiles
    final reachableTiles = PathfindingUtils.calculateReachableTiles(
      startX: unit.unitModel.x,
      startY: unit.unitModel.y,
      range: unit.unitModel.movement,
      gridData: gridData,
    );
    
    highlightedMovementTiles = reachableTiles;
    
    // Highlight tiles visually
    for (final tile in highlightedMovementTiles) {
      // Find component for this tile
      final tileComponent = children.whereType<IsometricTile>().firstWhere(
        (c) => c.tileModel == tile,
      );
      tileComponent.setMovementTarget(true);
    }
  }
  
  void _clearTileHighlights() {
    for (final tile in highlightedMovementTiles) {
      final tileComponent = children.whereType<IsometricTile>().firstWhere(
        (c) => c.tileModel == tile,
        orElse: () => children.whereType<IsometricTile>().first, // Fallback
      );
      tileComponent.setMovementTarget(false);
    }
    highlightedMovementTiles.clear();
  }
  
  // Handle tile tap from IsometricTile
  void handleTileTap(TileModel tile) {
    if (selectedUnitForMovement != null && highlightedMovementTiles.contains(tile)) {
      _executeMovement(tile);
    }
  }
  
  void _executeMovement(TileModel targetTile) {
    if (selectedUnitForMovement == null || selectedCardForExecution == null) return;
    
    // Move unit
    selectedUnitForMovement!.moveTo(targetTile.x, targetTile.y);
    
    // Move card to discard pile
    final cardModel = selectedCardForExecution!.cardModel;
    discardPile.add(cardModel);
    currentPlayerCardPool.remove(cardModel);
    
    // Remove card component
    selectedCardForExecution!.removeFromParent();
    
    // Clear state
    deselectCard();
  }
  
  // Console command: Show discard pile
  void showDiscardPile() {
    print('=== DISCARD PILE ===');
    for (var card in discardPile) {
      print('ID: ${card.id}');
      print('  Title: ${card.title}');
      print('---');
    }
    print('Total cards in discard pile: ${discardPile.length}');
  }

  @override
  Color backgroundColor() => const Color(0xFF2C2C2C);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Reset camera to ensure 1:1 mapping with screen coordinates
    camera.viewfinder.zoom = 1.0;
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();
    
    // Handle unit selection for movement
    // NOTE: The following block seems to be intended for a tap/click handler,
    // not for the onLoad method. It also uses undefined variables `gridX` and `gridY`.
    // As per instructions, inserting faithfully, but be aware of potential issues.
    if (selectedUnitForMovement != null && highlightedMovementTiles.isNotEmpty) {
      // Check if clicked tile is a valid movement target
      // final clickedTile = gridData.getTile(gridX, gridY); // gridX, gridY are undefined
      // if (clickedTile != null && highlightedMovementTiles.contains(clickedTile)) {
      //   _executeMovement(clickedTile);
      //   return;
      // }
    }
    
    // Handle tile hover
    // NOTE: The following line seems to be intended for a tap/click handler,
    // not for the onLoad method. It also uses undefined variables `gridX` and `gridY`
    // and contains a syntax error in the original snippet.
    // Corrected syntax to be valid Dart, assuming `gridData.gridSize` was intended.
    // if (gridX >= 0 && gridX < gridData.gridSize && gridY >= 0 && gridY < gridData.gridSize) {
    //   // Placeholder for intended logic
    // }
    
    // Initialize GridUtils and grid data
    gridUtils = GridUtils(tileWidth: 64.0, tileHeight: 32.0);
    gridData = GridData(gridSize: 10);

    // Calculate centering offset using GridUtils
    final offset = gridUtils.getCenteringOffset(size, gridData.gridSize);

    // Create and add isometric tiles with offset
    for (int x = 0; x < gridData.gridSize; x++) {
      for (int y = 0; y < gridData.gridSize; y++) {
        final tile = gridData.getTileAt(x, y);
        if (tile != null) {
          final tileComponent = IsometricTile(
            tileModel: tile,
            gridUtils: gridUtils,
          );
          add(tileComponent);
          // Apply centering offset
          tileComponent.position.add(offset);
          // Store in lookup map
          _tileComponents['${tile.x},${tile.y}'] = tileComponent;
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
      movement: 3,
    );
    final unitComponent = UnitComponent(unitModel: demoUnit);
    add(unitComponent);

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
      movement: 2,
    );
    final archerComponent = UnitComponent(unitModel: archerUnit);
    add(archerComponent);
    
    // Initialize card system
    currentPlayerCardPool = CardDatabase.getInitialPlayerCardPool();
    
    // Display cards at bottom of screen
    final screenWidth = size.x;
    final screenHeight = size.y;
    final cardSpacing = 10.0;
    final totalCardWidth = (CardComponent.cardWidth * currentPlayerCardPool.length) + 
                          (cardSpacing * (currentPlayerCardPool.length - 1));
    final startX = (screenWidth - totalCardWidth) / 2 + (CardComponent.cardWidth / 2);
    final cardY = screenHeight - CardComponent.cardHeight / 2 - 20;
    
    for (int i = 0; i < currentPlayerCardPool.length; i++) {
      final cardX = startX + (i * (CardComponent.cardWidth + cardSpacing));
      final cardComponent = CardComponent(
        cardModel: currentPlayerCardPool[i],
        position: Vector2(cardX, cardY),
      );
      add(cardComponent);
    }
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
  
  // Expose debug commands to browser console
  void _setupConsoleCommands() {
    // These methods will be callable from browser console
  }
  
  // Console command: Show current player card pool
  void showPlayerCards() {
    print('=== CURRENT PLAYER CARD POOL ===');
    for (var card in currentPlayerCardPool) {
      print('ID: ${card.id}');
      print('  Title: ${card.title}');
      print('  Type: ${card.type}');
      print('  Class: ${card.cardClass}');
      print('  Effect: ${card.effect}');
      print('  Set: ${card.set}');
      print('---');
    }
    print('Total cards in player pool: ${currentPlayerCardPool.length}');
  }
  
  // Console command: Show master card pool
  void showMasterCards() {
    print('=== MASTER CARD POOL ===');
    for (var card in CardDatabase.masterCardPool) {
      print('ID: ${card.id}');
      print('  Title: ${card.title}');
      print('  Type: ${card.type}');
      print('  Class: ${card.cardClass}');
      print('  Effect: ${card.effect}');
      print('  Set: ${card.set}');
      print('---');
    }
    print('Total cards in master pool: ${CardDatabase.masterCardPool.length}');
  }
}
