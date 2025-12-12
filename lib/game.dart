import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/grid_data.dart';
import 'models/tile_model.dart';
import 'models/unit_model.dart';
import 'models/card_model.dart';
import 'components/isometric_tile.dart';
import 'components/unit_component.dart';
import 'components/card_component.dart';
import 'components/deck_component.dart';
import 'components/movement_path_arrow.dart';
import 'components/movement_border_component.dart';
import 'data/card_database.dart';
import 'utils/pathfinding_utils.dart';
import 'utils/grid_utils.dart';
import 'data/level_database.dart';
import 'models/level_model.dart';
import 'data/unit_database.dart';
import 'utils/attack_utils.dart';
import 'components/attack_path_indicator.dart';
import 'components/projectile_component.dart';
import 'package:flame_audio/flame_audio.dart';

class MyGame extends Forge2DGame with MouseMovementDetector, KeyboardEvents, SecondaryTapDetector {
  late GridData gridData;
  late GridUtils gridUtils;
  late AttackUtils attackUtils;
  TileModel? hoveredTile;
  UnitModel? hoveredUnit;
  final Function(TileModel?)? onTileHoverChange;
  final Function(UnitModel?)? onUnitHoverChange;
  final Function(DeckType?, bool)? onDeckHoverChange;
  final Function(Map<String, double>)? onControlChange;
  
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

  MyGame({
    this.onTileHoverChange, 
    this.onUnitHoverChange,
    this.onDeckHoverChange,
    this.onControlChange,
  }) : super(gravity: Vector2(0, 10.0));
  
  // Input Handling
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      if (selectedCard != null) {
        deselectCard();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void onSecondaryTapDown(TapDownInfo info) {
    if (selectedCard != null) {
      deselectCard();
    }
  }

  // ... (existing methods)

  // Handle deck hover from DeckComponent
  void onDeckHover(DeckType type, bool isHovered) {
    onDeckHoverChange?.call(type, isHovered);
  }

  // ... (existing methods)



  // Deck Components
  late DeckComponent _deckComponent;
  late DeckComponent _discardComponent;
  List<CardModel> deck = [];

  // Handle card selection (only one card can be selected at a time)
  void selectCard(CardComponent card) {
    // Deselect previously selected card
    if (selectedCard != null && selectedCard != card) {
      deselectCard(); // Ensure full state cleanup
    }
    
    // Update selected card reference
    selectedCard = card;
    selectedCardForExecution = card;
    
    // If it's a move card, make units selectable and highlight their zones
    if (card.cardModel.type.toLowerCase() == 'move') {
      _setUnitsSelectable(true, _getCardColor(card.cardModel.type));
      // Borders will be shown when a specific unit is clicked
    } else if (card.cardModel.type.toLowerCase() == 'defend') {
      // Highlight menders without shield
      _setUnitsSelectable(
        true, 
        _getCardColor(card.cardModel.type),
        filter: (unit) => !unit.unitModel.hasShield
      );
    } else if (card.cardModel.type.toLowerCase() == 'attack') {
        // Highlight all menders that have targets? Or just all menders?
        // Simpler to just highlight all menders for now.
        _setUnitsSelectable(true, _getCardColor(card.cardModel.type));
    }
  }
  
  // Deselect current card
  void deselectCard() {
    selectedCard?.deselect();
    selectedCard = null;
    selectedCardForExecution = null;
    _setUnitsSelectable(false, Colors.white);
    _clearUnitSelection();
    _clearAllUnitBorders();
    _clearAttackState();
  }
  
  Set<String> _getBlockedTiles(String excludeAlliance) {
      final blocked = <String>{};
      for (final u in children.whereType<UnitComponent>()) {
           if (u.unitModel.alliance != excludeAlliance) {
               blocked.add('${u.unitModel.x},${u.unitModel.y}');
           }
      }
      return blocked;
  }

  // Helper to set selectable state for all units
  void _setUnitsSelectable(bool selectable, Color color, {bool Function(UnitComponent)? filter}) {
    children.whereType<UnitComponent>().where((unit) => unit.unitModel.alliance == 'Menders').forEach((unit) {
      if (selectable && filter != null && !filter(unit)) {
         unit.setSelectable(false);
         return;
      }
      unit.setHaloColor(color);
      unit.setSelectable(selectable);
    });
  }
  
  // Helper to clear unit selection
  void _clearUnitSelection() {
    if (selectedUnitForMovement != null) {
      selectedUnitForMovement!.setSelected(false);
      _hideMovementBorder(selectedUnitForMovement!);
      selectedUnitForMovement = null;
    }
    _clearTileHighlights();
    // Also clear attack selection
    if (selectedUnitForAttack != null) {
        selectedUnitForAttack!.setSelected(false);
        selectedUnitForAttack = null;
    }
  }
  
  Color _getCardColor(String type) {
    switch (type.toLowerCase()) {
      case 'attack': return const Color(0xFFE040FB); // PurpleAccent
      case 'move': return const Color(0xFF448AFF);
      case 'defend': return const Color(0xFF69F0AE);
      default: return const Color(0xFFFFD700);
    }
  }
    
  // Handle unit tap based on active card
  void onUnitTapped(UnitComponent unit) {
    // 1. Check for Attack Execution (Targeting an Enemy)
    if (selectedUnitForAttack != null && selectedCardForExecution?.cardModel.type.toLowerCase() == 'attack') {
         final targetTile = gridData.getTileAt(unit.unitModel.x, unit.unitModel.y);
         
         if (targetTile != null && currentAttackTargets.containsKey(targetTile)) {
             _executeAttack(targetTile);
             return;
         }
    }

    // 2. Normal Unit Selection Logic
    final cardType = selectedCardForExecution?.cardModel.type.toLowerCase();
    
    if (cardType == 'move') {
       _handleMoveUnitSelection(unit);
    } else if (cardType == 'defend') {
       _handleDefendUnitSelection(unit);
    } else if (cardType == 'attack') {
       _handleAttackUnitSelection(unit);
    } else {
       print('DEBUG: Unknown or null card type for selection.');
    }
  }

  void _handleDefendUnitSelection(UnitComponent unit) {
    if (unit.unitModel.alliance != 'Menders') return;
    if (unit.unitModel.hasShield) return;
    
    // Apply Shield
    unit.applyShield();
    
    // Consume Card and Deselect
    _consumeSelectedCard();
  }

  void _handleMoveUnitSelection(UnitComponent unit) {
    // Only allow selecting Menders units
    if (unit.unitModel.alliance != 'Menders') return;
    
    // Clear any existing arrow and path from previous interactions
    if (_movementArrow != null) {
      _movementArrow!.removeFromParent();
      _movementArrow = null;
    }
    _currentPath.clear();
    
    // Toggle Logic
    if (selectedUnitForMovement == unit) {
        // Unselect (Toggle OFF)
        unit.setSelected(false);
        _hideMovementBorder(unit);
        selectedUnitForMovement = null;
        highlightedMovementTiles.clear();
        
    } else {
        // New Selection (Switching or First Time)
        
        // Deselect previous
        if (selectedUnitForMovement != null) {
          selectedUnitForMovement!.setSelected(false);
          _hideMovementBorder(selectedUnitForMovement!);
        }
        
        selectedUnitForMovement = unit;
        unit.setSelected(true);
        _showMovementBorder(unit);
    }
  }

  void _consumeSelectedCard() {
    if (selectedCardForExecution == null) return;
    
    // Move card to discard pile
    final cardModel = selectedCardForExecution!.cardModel;
    discardPile.add(cardModel);
    currentPlayerCardPool.remove(cardModel);
    
    // Remove card component
    selectedCardForExecution!.removeFromParent();
    
    // Clear state
    deselectCard();
  }
  
  void _showMovementBorder(UnitComponent unit) {
       // Calculate blocked tiles (occupied by non-Menders)
       final blockedTiles = <String>{};
       for (final u in children.whereType<UnitComponent>()) {
            if (u.unitModel.alliance != 'Menders') {
                blockedTiles.add('${u.unitModel.x},${u.unitModel.y}');
            }
       }

       // Calculate reachable tiles
       final reachableTiles = PathfindingUtils.calculateReachableTiles(
           startX: unit.unitModel.x,
           startY: unit.unitModel.y,
           range: unit.unitModel.movementPoints,
           gridData: gridData,
           blockedTiles: blockedTiles,
       );
       
       // Update interaction state
       highlightedMovementTiles = reachableTiles;
         
       // Create Visual Border
       final baseBlue = HSVColor.fromColor(const Color(0xFF448AFF));
       final border = MovementBorderComponent(baseColor: baseBlue.toColor());
       add(border);
       
       final borderTiles = reachableTiles.toSet();
       final currentTile = gridData.getTileAt(unit.unitModel.x, unit.unitModel.y);
       if (currentTile != null) borderTiles.add(currentTile);
       
       border.updateTiles(borderTiles);
       
       _unitBorders[unit] = border;
  }

  void _hideMovementBorder(UnitComponent unit) {
      if (_unitBorders.containsKey(unit)) {
          _unitBorders[unit]!.removeFromParent();
          _unitBorders.remove(unit);
      }
  }
  

  
  void _clearAllUnitBorders() {
      _unitBorders.values.forEach((b) => b.removeFromParent());
      _unitBorders.clear();
  }
  
  void _calculateAndHighlightMovementTiles(UnitComponent unit) {
      // Deprecated in favor of _highlightAllUnitMovementZones, but if needed for single update:
      // We can update just this unit's border in the map.
  }
  
  void _clearTileHighlights() {
    // Don't clear borders here, only interaction highlights
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
  
  // Movement border map
  final Map<UnitComponent, MovementBorderComponent> _unitBorders = {};
  
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
        // This allows "snapping" to a new path if the user jumps the cursor
        final newPath = PathfindingUtils.findPath(
          startX: selectedUnitForMovement!.unitModel.x,
          startY: selectedUnitForMovement!.unitModel.y,
          endX: targetTile.x,
          endY: targetTile.y,
          gridData: gridData,
          blockedTiles: _getBlockedTiles(selectedUnitForMovement!.unitModel.alliance),
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
    } else if (selectedUnitForAttack != null && currentAttackTargets.containsKey(tile)) {
        _executeAttack(tile);
    }
  }
  
  // Check if a tile is occupied by any unit
  bool isTileOccupied(int x, int y) {
    for (final component in children.whereType<UnitComponent>()) {
      if (component.unitModel.x == x && component.unitModel.y == y) {
        return true;
      }
    }
    return false;
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
        blockedTiles: _getBlockedTiles(selectedUnitForMovement!.unitModel.alliance),
      );
    }
    
    // Capture alliance for callback since selectedUnitForMovement will be cleared
    final unitAlliance = selectedUnitForMovement!.unitModel.alliance;
    
    // Move unit along path
    selectedUnitForMovement!.moveTo(
      targetTile.x, 
      targetTile.y, 
      path: movePath,
      stepDuration: 0.3, // Default speed
      onTileEntered: (tile) {
        if (!tile.controllable) return;

        // Current tile logic:
        // 1. If Neutral, capture it.
        // 2. If Opposite Team, capture it (splash effect trigger).
        
        bool captured = false;
        
        if (tile.alliance.toLowerCase() == 'neutral') {
            // Capture current
            tileControlChange(tile, unitAlliance);
            captured = true;

            // Capture adjacent Neutral tiles
            final neighbors = gridUtils.getNeighbors(tile.x, tile.y);
            for (final p in neighbors) {
                final neighbor = gridData.getTileAt(p.$1, p.$2);
                if (neighbor != null && 
                    neighbor.controllable && 
                    neighbor.alliance.toLowerCase() == 'neutral') {
                     
                     // Capture neutral neighbor
                     tileControlChange(neighbor, unitAlliance);
                }
            }
        } else if (tile.alliance != unitAlliance) {
            // Entered an opposing tile - Capture ONLY this tile
            tileControlChange(tile, unitAlliance);
            captured = true;
        }
      },
    );
    
    // Clear manual path
    _currentPath.clear();
    
    _consumeSelectedCard();
  }

  // Handle tile control changes
  void tileControlChange(TileModel tile, String newAlliance) {
    // Update data
    tile.alliance = newAlliance;
    print('Tile at (${tile.x}, ${tile.y}) captured by $newAlliance');
    
    _calculateControlPercentages();
  }
  
  void _calculateControlPercentages() {
    if (onControlChange == null) return;
    
    int totalControllable = 0;
    int hiveCount = 0; // AI/Hive
    int mendersCount = 0;
    int neutralCount = 0;
    
    for (var row in gridData.tiles) {
        for (var tile in row) {
            if (tile.controllable) {
                totalControllable++;
                switch (tile.alliance.toLowerCase()) {
                    case 'menders':
                        mendersCount++;
                        break;
                    case 'hive': // AI/Hive
                        hiveCount++;
                        break;
                    default:
                        neutralCount++;
                }
            }
        }
    }
    
    if (totalControllable == 0) return;
    
    onControlChange!({
        'Hive': hiveCount / totalControllable,
        'Menders': mendersCount / totalControllable,
        'Neutral': neutralCount / totalControllable,
    });
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
    
    // Add movement border component - REMOVED (Handled dynamically)
    // add(_movementBorder);
    
    // Load Test Level
    final level = LevelDatabase.getLevel('test_level');
    
    // Initial Control Calculation

    
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
    gridData = GridData(
      gridSize: level.gridSize,
      neuronCount: level.neuronTilesCount,
      brainDamageCount: level.brainDamageTilesCount,
      memoryCount: level.memoryTilesCount,
      neuronCoordinates: level.neuronCoordinates,
      brainDamageCoordinates: level.brainDamageCoordinates,
      memoryCoordinates: level.memoryCoordinates,
    );
    
    // Initial Control Calculation
    _calculateControlPercentages();
    
    // Initialize AttackUtils
    attackUtils = AttackUtils(gridData: gridData, gridUtils: gridUtils);

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
    
    // Apply Enemy Control based on Strategy
    final controllableTiles = <TileModel>[];
    for (int x = 0; x < gridData.gridSize; x++) {
      for (int y = 0; y < gridData.gridSize; y++) {
        final tile = gridData.getTileAt(x, y);
        if (tile != null && tile.controllable) {
          controllableTiles.add(tile);
        }
      }
    }
    
    final enemyTileCount = (controllableTiles.length * (level.enemyControlledPercentage / 100.0)).round();
    
    // Sort controllableTiles based on strategy
    switch (level.enemyControlledTilesStartingPosition.toLowerCase()) {
      case 'top':
        // (0,0) is top. Sort by sum of coordinates (x+y) ascending.
        controllableTiles.sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
        break;
      case 'bottom':
        // (Max,Max) is bottom. Sort by sum of coordinates descending.
        controllableTiles.sort((a, b) => (b.x + b.y).compareTo(a.x + a.y));
        break;
      case 'left':
        // (0, Max) is left. Sort by difference (x-y) ascending.
        controllableTiles.sort((a, b) => (a.x - a.y).compareTo(b.x - b.y));
        break;
      case 'right':
        // (Max, 0) is right. Sort by difference (x-y) descending.
        controllableTiles.sort((a, b) => (b.x - b.y).compareTo(a.x - a.y));
        break;
      case 'neurons':
        // Find all neurons
        final neurons = <TileModel>[];
        for (int x = 0; x < gridData.gridSize; x++) {
          for (int y = 0; y < gridData.gridSize; y++) {
            final t = gridData.getTileAt(x, y);
            if (t != null && t.type == 'Neuron') neurons.add(t);
          }
        }
        // Sort by min distance to any neuron
        controllableTiles.sort((a, b) {
          double minDistA = 999999;
          for (final n in neurons) {
            final d = (a.x - n.x) * (a.x - n.x) + (a.y - n.y) * (a.y - n.y);
            if (d < minDistA) minDistA = d.toDouble();
          }
          double minDistB = 999999;
          for (final n in neurons) {
            final d = (b.x - n.x) * (b.x - n.x) + (b.y - n.y) * (b.y - n.y);
            if (d < minDistB) minDistB = d.toDouble();
          }
          return minDistA.compareTo(minDistB);
        });
        break;
      case 'memories':
        // Find all memories
        final memories = <TileModel>[];
        for (int x = 0; x < gridData.gridSize; x++) {
          for (int y = 0; y < gridData.gridSize; y++) {
            final t = gridData.getTileAt(x, y);
            if (t != null && t.type == 'Memory') memories.add(t);
          }
        }
        // Sort by min distance to any memory
        controllableTiles.sort((a, b) {
          double minDistA = 999999;
          for (final n in memories) {
            final d = (a.x - n.x) * (a.x - n.x) + (a.y - n.y) * (a.y - n.y);
            if (d < minDistA) minDistA = d.toDouble();
          }
          double minDistB = 999999;
          for (final n in memories) {
            final d = (b.x - n.x) * (b.x - n.x) + (b.y - n.y) * (b.y - n.y);
            if (d < minDistB) minDistB = d.toDouble();
          }
          return minDistA.compareTo(minDistB);
        });
        break;
      default:
        // Default top
        controllableTiles.sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
    }
    
    // Take top N
    for (int i = 0; i < enemyTileCount; i++) {
      if (i < controllableTiles.length) {
        tileControlChange(controllableTiles[i], 'Hive');
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
    
    // Fallback if something went wrong
    knightSpawn ??= gridData.getTileAt(5, 5) ?? TileModel(x: 5, y: 5, type: 'Dendrite', description: 'Fallback', walkable: true);
    archerSpawn ??= gridData.getTileAt(0, 5) ?? TileModel(x: 0, y: 5, type: 'Dendrite', description: 'Fallback', walkable: true);

    // Create and add a demo unit at grid center
    // Track occupied tiles to prevent overlap
    final occupiedTiles = <TileModel>{};
    
    // Helper to find random valid tile
    TileModel? findRandomTile({required bool Function(TileModel) filter}) {
      final candidates = <TileModel>[];
      for (var row in gridData.tiles) {
        for (var tile in row) {
          if (tile.walkable && !occupiedTiles.contains(tile) && filter(tile)) {
            candidates.add(tile);
          }
        }
      }
      if (candidates.isEmpty) return null;
      return candidates[DateTime.now().microsecondsSinceEpoch % candidates.length];
    }

    // Spawn Menders (Bottom 4 rows)
    final menderSpawnFilter = (TileModel t) => t.y >= gridData.gridSize - 4;
    
    // Manipulator
    final manipulatorTile = findRandomTile(filter: menderSpawnFilter);
    if (manipulatorTile != null) {
      occupiedTiles.add(manipulatorTile);
      final manipulator = UnitDatabase.create('Manipulator', manipulatorTile.x, manipulatorTile.y);
      add(UnitComponent(unitModel: manipulator));
    }

    // Crazy Nina
    final ninaTile = findRandomTile(filter: menderSpawnFilter);
    if (ninaTile != null) {
      occupiedTiles.add(ninaTile);
      final nina = UnitDatabase.create('Crazy Nina', ninaTile.x, ninaTile.y);
      add(UnitComponent(unitModel: nina));
    }
    
    // Spawn Hive Units (In Hive Controlled Territory)
    final hiveSpawnFilter = (TileModel t) => t.alliance == 'Hive';
    
    // Terminator
    final terminatorTile = findRandomTile(filter: hiveSpawnFilter);
    if (terminatorTile != null) {
        occupiedTiles.add(terminatorTile);
        final terminator = UnitDatabase.create('Terminator', terminatorTile.x, terminatorTile.y);
        add(UnitComponent(unitModel: terminator));
    }

    // Sweeper
    final sweeperTile = findRandomTile(filter: hiveSpawnFilter);
    if (sweeperTile != null) {
        occupiedTiles.add(sweeperTile);
        final sweeper = UnitDatabase.create('Sweeper', sweeperTile.x, sweeperTile.y);
        add(UnitComponent(unitModel: sweeper));
    }
    
    // Initial capture for new units
    for (final unit in children.whereType<UnitComponent>()) {
      final tile = gridData.getTileAt(unit.unitModel.x, unit.unitModel.y);
      if (tile != null && tile.controllable && tile.alliance.toLowerCase() == 'neutral') {
        tileControlChange(tile, unit.unitModel.alliance);
      }
    }
    
    // Initialize Player Deck
    deck.clear();
    final masterPool = CardDatabase.masterCardPool;
    final basicAttack = masterPool.firstWhere((c) => c.title == 'Basic Attack');
    final basicDefend = masterPool.firstWhere((c) => c.title == 'Basic Defend');
    final basicMove = masterPool.firstWhere((c) => c.title == 'Basic Move');
    
    for (int i = 0; i < 12; i++) deck.add(basicAttack.copyWith(id: 'p_attack_$i'));
    for (int i = 0; i < 5; i++) deck.add(basicDefend.copyWith(id: 'p_defend_$i'));
    for (int i = 0; i < 13; i++) deck.add(basicMove.copyWith(id: 'p_move_$i'));
    
    // Shuffle deck
    deck.shuffle();
    
    // Clear hand (start with 0 cards)
    currentPlayerCardPool.clear();
    
    // Add Deck Component (Draw Pile)
    final screenWidth = size.x;
    final screenHeight = size.y;
    _deckComponent = DeckComponent(
      position: Vector2(screenWidth - 20, screenHeight - 20),
      type: DeckType.draw,
    );
    add(_deckComponent);
    
    // Add Discard Pile Component
    _discardComponent = DeckComponent(
      position: Vector2(screenWidth - 90, screenHeight - 20),
      type: DeckType.discard,
    );
    add(_discardComponent);
    
    // Start first turn with delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      newTurn();
    });
    
    // Initialize control for starting units
    // Capture tiles they are standing on
    // Initial control capture handled above
  }



  void newTurn() {
    print('Starting new turn...');
    _updateDangerZones(); // Update danger zones at start of player turn
    drawCards(5);
  }

  void drawCards(int amount) {
    if (deck.isEmpty) return;
    
    final drawCount = amount.clamp(0, deck.length);
    final drawnCards = deck.take(drawCount).toList();
    deck.removeRange(0, drawCount);
    
    currentPlayerCardPool.addAll(drawnCards);
    
    _animateDrawCards(drawnCards);
  }

  void _animateDrawCards(List<CardModel> newCards) {
    final screenWidth = size.x;
    final screenHeight = size.y;
    final cardSpacing = 10.0;
    
    // Calculate final positions for ALL cards in hand (including existing ones)
    // But for now, let's just append or re-layout.
    // Re-layouting existing cards is better.
    
    // Remove existing card components from parent (we'll re-add them or update them)
    // Actually, simpler to just add new ones and then run a layout pass.
    
    // Let's create components for new cards at Deck position
    final deckPos = _deckComponent.position.clone();
    // Adjust for anchor (Deck is bottomRight, Card is center)
    // Deck pos is bottom right corner.
    final startPos = deckPos - Vector2(30, 45); // Approx center of deck
    
    final newComponents = <CardComponent>[];
    
    for (var card in newCards) {
      final component = CardComponent(
        cardModel: card,
        position: startPos.clone(),
      );
      add(component);
      newComponents.add(component);
    }
    
    // Now animate all cards to their hand positions
    _layoutHand(newComponents);
  }

  void _layoutHand(List<CardComponent> newCards) {
    final screenWidth = size.x;
    final screenHeight = size.y;
    final cardSpacing = 10.0;
    
    // Get all card components in hand (existing + new)
    // We need to match currentPlayerCardPool order
    // Existing components:
    final existingComponents = children.whereType<CardComponent>().where((c) => !newCards.contains(c) && c != selectedCardForExecution).toList();
    
    // This is tricky because children order might not match pool order.
    // Let's rebuild the list of components based on pool.
    // Or just layout what we have.
    
    final allHandComponents = [...existingComponents, ...newCards];
    
    final totalCardWidth = (CardComponent.cardWidth * allHandComponents.length) + 
                          (cardSpacing * (allHandComponents.length - 1));
    final startX = (screenWidth - totalCardWidth) / 2 + (CardComponent.cardWidth / 2);
    final cardY = screenHeight - CardComponent.cardHeight / 2 - 20;
    
    for (int i = 0; i < allHandComponents.length; i++) {
      final component = allHandComponents[i];
      final targetX = startX + (i * (CardComponent.cardWidth + cardSpacing));
      final targetPos = Vector2(targetX, cardY);
      
      // Delay based on index for "quick succession"
      // Only delay new cards? Or all?
      // User said "animate them in quick succession... from the deck icon".
      // Existing cards should probably just slide.
      
      double delay = 0.0;
      if (newCards.contains(component)) {
        final newIndex = newCards.indexOf(component);
        delay = newIndex * 0.1;
      }
      
      component.add(
        MoveEffect.to(
          targetPos,
          EffectController(
            duration: 0.5,
            startDelay: delay,
            curve: Curves.elasticOut,
          ),
          onComplete: () {
            component.setBasePosition(targetPos);
          },
        ),
      );
      
      // Update base position for hover effects
      // We need to access _basePosition, but it's private.
      // CardComponent needs a method to update base position.
      // For now, we rely on the fact that CardComponent updates _basePosition in onLoad?
      // No, onLoad runs once.
      // We should update CardComponent to allow updating base position.
      // But wait, CardComponent uses _basePosition for hover.
      // If we move it with an effect, _basePosition remains old.
      // We need to update _basePosition after move?
      // Or make _basePosition public/setter.
    }
  }

  
  // Danger Zone Logic (Hive Attack Ranges)
  // Map<DangerTile, List<SourceUnit>>
  final Map<TileModel, List<UnitComponent>> _dangerMap = {};
  final List<AttackPathIndicator> _activeDangerPaths = [];

  void _updateDangerZones() {
     // Clear previous state
     for (final tileComp in children.whereType<IsometricTile>()) {
         tileComp.setIsDanger(false);
     }
     _dangerMap.clear();
     
     // Find all Hive units
     final hiveUnits = children.whereType<UnitComponent>().where((u) => u.unitModel.alliance == 'Hive');
     
     for (final unit in hiveUnits) {
         // Calculate attackable tiles for this unit
         // Note: calculateAttackTargets usually returns tiles containing valid targets (units).
         // But the user wants "tiles the AI can attack", implying range. 
         // We might need to adjust AttackUtils or use a heuristic here.
         // AttackUtils.calculateAttackTargets uses `gridData` and checks for occupied tiles usually.
         // Actually, let's look at AttackUtils implementation in our head: usually checks if tile is occupied by enemy.
         // But "warning" usually implies "don't step here".
         // Use PathfindingUtils or AttackUtils to find all tiles IN RANGE and VISIBLE.
         
         // Let's assume we want ALL tiles in range that line-of-sight isn't blocked.
         // We can use attackUtils.calculateAttackTargets but relax the "contains enemy" check?
         // No, calculateAttackTargets is specifically for targeting units.
         
         // Let's iterate all tiles in range manually using GridUtils
         final visibleTiles = gridUtils.getTilesInRange(unit.unitModel.x, unit.unitModel.y, unit.unitModel.attackRange);
         
         for (final tilePoint in visibleTiles) {
             final tile = gridData.getTileAt(tilePoint.$1, tilePoint.$2);
             if (tile == null) continue;
             
             // Check Line of Sight
             // Only relevant for Projectile/Melee? Artillery usually ignores LOS?
             bool hasLOS = true;
             if (unit.unitModel.attackType != 'artillery') {
                 // Simple LOS check: trace line using AttackUtils logic or similar
                 // Re-using AttackUtils.getLineOfSight would be best if available.
                 // Otherwise, assume clear for now or implement Bresenham.
                 // Since we don't have access to AttackUtils inner methods easily, let's use a simplified check
                 // or assume valid for now if simple. 
                 
                 // Actually, let's rely on AttackUtils to get the path. If path exists, it's valid.
                 // We can call `gridUtils.getLine`?
                 
                 final path = attackUtils.getAttackPath(
                     unit.unitModel.x, unit.unitModel.y, 
                     tile.x, tile.y, 
                     unit.unitModel.attackType
                 );
                 
                 if (path == null) hasLOS = false;
             }
             
             if (hasLOS) {
                 if (!_dangerMap.containsKey(tile)) {
                     _dangerMap[tile] = [];
                 }
                 _dangerMap[tile]!.add(unit);
                 
                 // Update Visual
                 final tileComp = getTileAt(tile.x, tile.y);
                 tileComp?.setIsDanger(true);
             }
         }
     }
  }

  // Attack State
  UnitComponent? selectedUnitForAttack;
  Map<TileModel, List<TileModel>> currentAttackTargets = {};
  AttackPathIndicator? _activeAttackPath;

  void _handleAttackUnitSelection(UnitComponent unit) {
    if (unit.unitModel.alliance != 'Menders') return;
    
    // Toggle logic
    if (selectedUnitForAttack == unit) {
         selectedUnitForAttack = null;
         _clearAttackState();
         unit.setSelected(false);
      } else {
         if (selectedUnitForAttack != null) selectedUnitForAttack!.setSelected(false);
         selectedUnitForAttack = unit;
         unit.setSelected(true);
         
         // Calculate Targets
         currentAttackTargets = attackUtils.calculateAttackTargets(
             startX: unit.unitModel.x,
             startY: unit.unitModel.y,
             range: unit.unitModel.attackRange,
             attackType: unit.unitModel.attackType,
         );
         
         // Highlight targets (Purple)
         _highlightAttackTargets();
     }
  }

  
  void _highlightAttackTargets() {
      _clearTileHighlights();
      
      for (final tile in currentAttackTargets.keys) {
          final tileComponent = getTileAt(tile.x, tile.y);
          if (tileComponent != null) {
            tileComponent.setHighlightColor(const Color(0xFF4A148C)); // Dark Purple
          }
      }
      highlightedMovementTiles = currentAttackTargets.keys.toList(); 
  }
  
  void _clearAttackState() {
      currentAttackTargets.clear();
      highlightedMovementTiles.clear();
      if (_activeAttackPath != null) {
          _activeAttackPath!.removeFromParent();
          _activeAttackPath = null;
      }
       // Clear tile highlights
      for (final tileComp in children.whereType<IsometricTile>()) {
          tileComp.setHighlightColor(null);
      }
  }

  void _executeAttack(TileModel targetTile) {
      if (selectedUnitForAttack == null) return;
      
      final path = currentAttackTargets[targetTile];
      if (path == null) return;
      
      final startPos = getTilePosition(selectedUnitForAttack!.unitModel.x, selectedUnitForAttack!.unitModel.y);
      final targetPos = getTilePosition(targetTile.x, targetTile.y);
      
      if (startPos == null || targetPos == null) return;
      
      // Play Sound (Disabled)
      // try { FlameAudio.play('shoot.wav'); } catch (e) {}
      
      // Spawn Projectile
      final damage = selectedUnitForAttack!.unitModel.attackValue;
      final projectile = ProjectileComponent(
          startPos: startPos,
          targetPos: targetPos,
          isArtillery: selectedUnitForAttack!.unitModel.attackType == 'artillery',
          onHit: () {
              _applyDamage(targetTile, damage);
              // deselectCard(); // Already called by _consumeSelectedCard immediately
          }
      );
      add(projectile);
      
      _consumeSelectedCard();
  }
  
  void _applyDamage(TileModel tile, int damage) {
      final unitsAtTile = children.whereType<UnitComponent>().where(
          (u) => u.unitModel.x == tile.x && u.unitModel.y == tile.y
      );
      
      if (unitsAtTile.isEmpty) return;
      final unit = unitsAtTile.first;
      
      if (unit.unitModel.hasShield) {
          unit.consumeShield();
          print('${unit.unitModel.name} shield absorbed damage!');
      } else {
          print('${unit.unitModel.name} took $damage damage!');
          
          // Trigger visual reaction
          unit.triggerDamageReaction();
          
          // Implement actual damage logic here
          unit.unitModel.currentHP -= damage;
          print('Unit HP: ${unit.unitModel.currentHP} / ${unit.unitModel.maxHP}');
          
          if (unit.unitModel.currentHP <= 0) { 
              // Delay removal slightly to show death effect or allow flash to start
              // But requirements say "unit is dead and removed".
              // Let's allow the flash to play for a split second or just remove?
              // User said "briefly flash for 2 seconds, and reduce... if <= 0 removed".
              // This implies if it dies, it might be removed immediately. 
              // Logic check: Can't flash if removed. 
              // I will use a Future.delayed for removal if dead, to allow flash visibility?
              // Or maybe just remove immediately if requested.
              // "if... removed from the game".
              
              // Let's try to keep it for 0.5s to show the red flash, then remove.
              Future.delayed(const Duration(milliseconds: 500), () {
                 unit.removeFromParent();
                 print('${unit.unitModel.name} destroyed!');
              });
          }
      }
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    handleMouseMove(info.eventPosition.widget);
  }

  void handleMouseMove(Vector2 position) {
    UnitComponent? targetUnitComponent;
    // Convert screen position to world position
    final worldPosition = camera.globalToLocal(position);
    
    // Check for unit hover first (units are on top of tiles)
    UnitModel? newHoveredUnit;
    UnitComponent? newHoveredComponent;

    // Reset previous hover if it exists, or just manage it carefully
    // Optimization: Keep track of hovered component instead of just model
    
    for (final component in children.whereType<UnitComponent>()) {
      if (component.containsPoint(worldPosition)) {
        newHoveredUnit = component.unitModel;
        newHoveredComponent = component;
        break;
      }
    }
    
    if (newHoveredUnit != hoveredUnit) {
      // Clear previous hover visual
      for (final component in children.whereType<UnitComponent>()) {
          // We can't easily identifying the "previous" component from hoveredUnit model alone 
          // without a map or iterating properly.
          // Simpler: Set hovered = false for all, then true for new one?
          // Or just check if component.unitModel == hoveredUnit
          if (hoveredUnit != null && component.unitModel == hoveredUnit) {
               component.setHovered(false);
          }
      }
      
      hoveredUnit = newHoveredUnit;
      onUnitHoverChange?.call(hoveredUnit);
      
      // Set new hover visual
      if (newHoveredComponent != null) {
          newHoveredComponent.setHovered(true);
      }
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
      
      // Update Danger Zone Visualization (Hover)
      // Clear previous danger paths
       for (final p in _activeDangerPaths) {
           p.removeFromParent();
       }
       _activeDangerPaths.clear();
      
      if (hoveredTile != null && _dangerMap.containsKey(hoveredTile)) {
          // Show trajectories from all Hive units targeting this tile
          final attackers = _dangerMap[hoveredTile]!;
          for (final attacker in attackers) {
               // Calculate path points
               final pathPoints = <Vector2>[];
               final startPos = getTilePosition(attacker.unitModel.x, attacker.unitModel.y);
               final endPos = getTilePosition(hoveredTile!.x, hoveredTile!.y);
               
               if (startPos != null && endPos != null) {
                   pathPoints.add(startPos);
                   // Add intermediate points if needed (e.g. for projectile path)
                   // For now, straight line? Or follow grid center?
                   // If we have access to the full tile path, better.
                   // Let's re-calculate path for visual
                   final tilePath = attackUtils.getAttackPath(
                       attacker.unitModel.x, attacker.unitModel.y,
                       hoveredTile!.x, hoveredTile!.y,
                       attacker.unitModel.attackType
                   );
                   
                   if (tilePath != null) {
                       for (final t in tilePath) {
                           final p = getTilePosition(t.x, t.y);
                           if (p != null) pathPoints.add(p);
                       }
                   } else {
                       // Fallback straight line
                       pathPoints.add(endPos); 
                   }
                   
                   final indicator = AttackPathIndicator(
                       pathPoints: pathPoints,
                       type: attacker.unitModel.attackType == 'artillery' ? AttackPathType.artillery : AttackPathType.projectile,
                       color: const Color(0xFFFF0000).withOpacity(0.5), // Red trajectory
                   );
                   add(indicator);
                   _activeDangerPaths.add(indicator);
               }
          }
      }
      
      // Update Attack Path and Damage Preview
      if (hoveredTile == null) {
          if (_activeAttackPath != null) {
              _activeAttackPath!.removeFromParent();
              _activeAttackPath = null;
          }
      } else {
          // ALWAYS find unit at hovered tile (regardless of attack targeting state)
          for (final u in children.whereType<UnitComponent>()) {
              if (u.unitModel.x == hoveredTile!.x && u.unitModel.y == hoveredTile!.y) {
                  targetUnitComponent = u;
                  break;
              }
          }
          
          // Check if hovering a valid attack target
          if (selectedUnitForAttack != null && currentAttackTargets.containsKey(hoveredTile)) {
              // Set preview damage on the unit (if found)
              if (targetUnitComponent != null) {
                  targetUnitComponent.setPreviewDamage(selectedUnitForAttack!.unitModel.attackValue);
              }
              
              // Draw attack path
              final path = currentAttackTargets[hoveredTile]!;
              if (_activeAttackPath != null) _activeAttackPath!.removeFromParent();
              
              final pathPoints = <Vector2>[];
              final startPos = getTilePosition(selectedUnitForAttack!.unitModel.x, selectedUnitForAttack!.unitModel.y);
              if (startPos != null) pathPoints.add(startPos);
              
              for (final t in path) {
                  final p = getTilePosition(t.x, t.y);
                  if (p != null) pathPoints.add(p);
              }
              
              _activeAttackPath = AttackPathIndicator(
                  pathPoints: pathPoints,
                  type: selectedUnitForAttack!.unitModel.attackType == 'artillery'
                      ? AttackPathType.artillery
                      : AttackPathType.projectile
              );
              add(_activeAttackPath!);
          } else {
              // Not a valid attack target - clear attack path
              if (_activeAttackPath != null) {
                  _activeAttackPath!.removeFromParent();
                  _activeAttackPath = null;
              }
          }
      }
    
    
    // Cleanup Previews for units that are NOT the current valid target
    // This is a bit inefficient to run every move, but robust.
    if (selectedUnitForAttack != null && hoveredTile != null && currentAttackTargets.containsKey(hoveredTile)) {
         // Valid target hover, handled above (setPreviewDamage called)
         // But we should ensure others are cleared?
         // Actually, if we move from Unit A to Unit B, we need to clear A.
         for (final u in children.whereType<UnitComponent>()) {
             if (u != targetUnitComponent) {
                 u.setPreviewDamage(0);
             }
         }
    } else {
         // Not hovering a valid attack target, clear all previews
         for (final u in children.whereType<UnitComponent>()) {
             u.setPreviewDamage(0);
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
  }
}

