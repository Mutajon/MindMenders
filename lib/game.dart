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
import 'components/movement_path_arrow.dart';
import 'components/movement_border_component.dart';
import 'data/card_database.dart';
import 'utils/pathfinding_utils.dart';
import 'utils/grid_utils.dart';

class MyGame extends Forge2DGame with MouseMovementDetector {
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
  
  // Get world position of a tile center at coordinates
  Vector2? getTilePosition(int x, int y) {
    final key = '$x,$y';
    if (_tileComponents.containsKey(key)) {
      return _tileComponents[key]!.position.clone();
    }
    return null;
  }
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
      _setUnitsSelectable(true, _getCardColor(card.cardModel.type));
    }
  }
  
  // Deselect current card
  void deselectCard() {
    selectedCard = null;
    selectedCardForExecution = null;
    _setUnitsSelectable(false, Colors.white);
    _clearUnitSelection();
  }

  // Helper to set selectable state for all units
  void _setUnitsSelectable(bool selectable, Color color) {
    children.whereType<UnitComponent>().forEach((unit) {
      unit.setHaloColor(color);
      unit.setSelectable(selectable);
    });
  }
  
  // Helper to clear unit selection
  void _clearUnitSelection() {
    if (selectedUnitForMovement != null) {
      selectedUnitForMovement!.setSelected(false);
      selectedUnitForMovement = null;
    }
    _clearTileHighlights();
  }
  
  Color _getCardColor(String type) {
    switch (type.toLowerCase()) {
      case 'attack': return const Color(0xFFFF5252);
      case 'move': return const Color(0xFF448AFF);
      case 'defend': return const Color(0xFF69F0AE);
      default: return const Color(0xFFFFD700);
    }
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
      range: unit.unitModel.movementPoints,
      gridData: gridData,
    );
    
    highlightedMovementTiles = reachableTiles;
    
    // Create a set for the border that includes the unit's current tile
    final borderTiles = highlightedMovementTiles.toSet();
    final currentTile = gridData.getTileAt(unit.unitModel.x, unit.unitModel.y);
    if (currentTile != null) {
      borderTiles.add(currentTile);
    }
    
    // Update border component
    _movementBorder.updateTiles(borderTiles);
    
    // Highlight tiles visually - OLD METHOD REMOVED
    // for (final tile in highlightedMovementTiles) {
    //   // Find component for this tile
    //   final tileComponent = children.whereType<IsometricTile>().firstWhere(
    //     (c) => c.tileModel == tile,
    //   );
    //   tileComponent.setMovementTarget(true);
    // }
  }
  
  void _clearTileHighlights() {
    // Clear border
    _movementBorder.updateTiles({});

    for (final tile in highlightedMovementTiles) {
      final tileComponent = children.whereType<IsometricTile>().firstWhere(
        (c) => c.tileModel == tile,
        orElse: () => children.whereType<IsometricTile>().first, // Fallback
      );
      tileComponent.setMovementTarget(false);
    }
    highlightedMovementTiles.clear();
    
    // Clear arrow
    if (_movementArrow != null) {
      _movementArrow!.removeFromParent();
      _movementArrow = null;
    }
  }
  
  // Movement arrow
  MovementPathArrow? _movementArrow;
  
  // Movement border
  final MovementBorderComponent _movementBorder = MovementBorderComponent();
  
  // Current manual path
  final List<TileModel> _currentPath = [];

  void _updateMovementArrow(TileModel? targetTile) {
    // Check conditions
    if (selectedUnitForMovement == null || targetTile == null) {
      return;
    }
    
    // Initialize path if empty or unit changed
    if (_currentPath.isEmpty || 
        _currentPath.first.x != selectedUnitForMovement!.unitModel.x || 
        _currentPath.first.y != selectedUnitForMovement!.unitModel.y) {
      final startTile = gridData.getTileAt(selectedUnitForMovement!.unitModel.x, selectedUnitForMovement!.unitModel.y);
      if (startTile != null) {
        _currentPath.clear();
        _currentPath.add(startTile);
      }
    }
    
    // If hovering over a tile already in path, backtrack
    final existingIndex = _currentPath.indexOf(targetTile);
    if (existingIndex != -1) {
      // Remove everything after this tile
      _currentPath.removeRange(existingIndex + 1, _currentPath.length);
    } else {
      // Try to add new tile manually
      final lastTile = _currentPath.last;
      final isNeighbor = gridUtils.isNeighbor(lastTile.x, lastTile.y, targetTile.x, targetTile.y);
      
      if (isNeighbor && 
          targetTile.walkable && 
          _currentPath.length <= selectedUnitForMovement!.unitModel.movementPoints &&
          highlightedMovementTiles.contains(targetTile)) {
        _currentPath.add(targetTile);
      } else if (highlightedMovementTiles.contains(targetTile)) {
        // If not a neighbor but valid target, auto-calculate shortest path
        // This allows "snapping" to a new path if the user jumps the cursor
        final newPath = PathfindingUtils.findPath(
          startX: selectedUnitForMovement!.unitModel.x,
          startY: selectedUnitForMovement!.unitModel.y,
          endX: targetTile.x,
          endY: targetTile.y,
          gridData: gridData,
        );
        
        if (newPath.isNotEmpty) {
          _currentPath.clear();
          // Add start tile manually as findPath returns path including start/end
          // But we want to ensure consistency with our _currentPath structure
          // findPath usually returns [start, ..., end]
          _currentPath.addAll(newPath);
        }
      }
    }
    
    // Update arrow visual
    // Remove existing arrow
    if (_movementArrow != null) {
      _movementArrow!.removeFromParent();
      _movementArrow = null;
    }
    
    if (_currentPath.length < 2) return;
    
    // Convert to world coordinates
    final List<Vector2> pathPoints = [];
    
    for (final tile in _currentPath) {
      final pos = getTilePosition(tile.x, tile.y);
      if (pos != null) pathPoints.add(pos);
    }
    
    // Create and add arrow
    _movementArrow = MovementPathArrow(
      pathPoints: pathPoints,
      color: const Color(0xFF448AFF), // Blue to match move card
    );
    add(_movementArrow!);
  }

  // Handle tile tap from IsometricTile
  void handleTileTap(TileModel tile) {
    if (selectedUnitForMovement != null && highlightedMovementTiles.contains(tile)) {
      _executeMovement(tile);
    }
  }
  
  void _executeMovement(TileModel targetTile) {
    if (selectedUnitForMovement == null || selectedCardForExecution == null) return;
    
    // If we have a manual path, ensure we're moving to the end of it
    // (targetTile should match _currentPath.last if logic is correct)
    
    List<TileModel> movePath = List.from(_currentPath);
    
    // If manual path is empty or invalid for this target, calculate shortest path
    if (movePath.isEmpty || movePath.last != targetTile) {
      movePath = PathfindingUtils.findPath(
        startX: selectedUnitForMovement!.unitModel.x,
        startY: selectedUnitForMovement!.unitModel.y,
        endX: targetTile.x,
        endY: targetTile.y,
        gridData: gridData,
      );
    }
    
    // Move unit along path
    selectedUnitForMovement!.moveTo(
      targetTile.x, 
      targetTile.y, 
      path: movePath,
      stepDuration: 0.3, // Default speed
    );
    
    // Clear manual path
    _currentPath.clear();
    
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
    
    // Add movement border component
    add(_movementBorder);
    
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
            centeringOffset: offset,
          );
          add(tileComponent);
          // Store in lookup map
          _tileComponents['${tile.x},${tile.y}'] = tileComponent;
        }
      }
    }

    // Find valid Dendrite tiles for units
    TileModel? knightSpawn;
    double minKnightDist = 999.0;
    
    // Find best spawn for Knight near (5,5)
    for (int x = 0; x < gridData.gridSize; x++) {
      for (int y = 0; y < gridData.gridSize; y++) {
        final tile = gridData.getTileAt(x, y);
        if (tile != null && tile.type == 'Dendrite') {
           double d = ((x - 5) * (x - 5) + (y - 5) * (y - 5)).toDouble();
           if (d < minKnightDist) {
             minKnightDist = d;
             knightSpawn = tile;
           }
        }
      }
    }

    // Find best spawn for Archer near (0,5)
    TileModel? archerSpawn;
    double minArcherDist = 999.0;
    
    for (int x = 0; x < gridData.gridSize; x++) {
      for (int y = 0; y < gridData.gridSize; y++) {
        final tile = gridData.getTileAt(x, y);
        if (tile != null && tile.type == 'Dendrite' && tile != knightSpawn) {
           double d = ((x - 0) * (x - 0) + (y - 5) * (y - 5)).toDouble();
           if (d < minArcherDist) {
             minArcherDist = d;
             archerSpawn = tile;
           }
        }
      }
    }
    
    // Fallback if something went wrong (shouldn't happen with 70% Dendrites)
    knightSpawn ??= gridData.getTileAt(5, 5) ?? TileModel(x: 5, y: 5, type: 'Dendrite', description: 'Fallback', walkable: true);
    archerSpawn ??= gridData.getTileAt(0, 5) ?? TileModel(x: 0, y: 5, type: 'Dendrite', description: 'Fallback', walkable: true);

    // Create and add a demo unit at grid center
    final demoUnit = UnitModel(
      name: 'Manipulator',
      hp: 3,
      attackMode: 'Melee',
      damageValue: 2,
      specialAbility: 'Shield Bash',
      x: knightSpawn.x,
      y: knightSpawn.y,
      movementPoints: 2,
    );
    final unitComponent = UnitComponent(unitModel: demoUnit);
    add(unitComponent);

    // Create and add an Archer unit at the left side
    final archerUnit = UnitModel(
      name: 'Infector',
      hp: 2,
      attackMode: 'Ranged',
      damageValue: 3,
      specialAbility: 'Double Shot',
      x: archerSpawn.x,
      y: archerSpawn.y,
      movementPoints: 3,
    );
    final archerComponent = UnitComponent(unitModel: archerUnit);
    add(archerComponent);
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
      
      // Update movement arrow
      _updateMovementArrow(hoveredTile);
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
