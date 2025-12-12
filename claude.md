# Flutter Flame Tactical Game

A strategy/tactical grid-based game built with Flutter and Flame featuring isometric hexagonal grids, unit management, and card-based actions.

## Architecture Overview

```
lib/
  main.dart                 - Entry point, GameScreen widget, overlay management
  game.dart                 - MyGame (Forge2DGame) - core game loop & state
  main_menu.dart            - Start screen
  components/
    isometric_tile.dart     - Hex tile rendering, hit detection, movement highlighting
    unit_component.dart     - Unit rendering, selection halos, movement animation
    card_component.dart     - Card UI, hover/selection states
  models/
    tile_model.dart         - Tile data (x, y, type, walkable)
    unit_model.dart         - Unit stats (hp, attack, defense, movement, alliance)
    card_model.dart         - Card data with copyWith() for player instances
    grid_data.dart          - 10x10 grid generation & lookup
  data/
    card_database.dart      - Master card pool & player card initialization
  overlays/
    tile_info_overlay.dart  - Bottom-left hover info
    unit_info_overlay.dart  - Top-left hover info
  utils/
    grid_utils.dart         - Isometric hex coordinate math & hex shape geometry
    pathfinding_utils.dart  - BFS pathfinding with axial hex neighbors
    console_commands.dart   - Debug helpers for browser console
```

## Core Systems

### Isometric Hex Grid
- 10x10 grid with pointy-top hexagons (64x32px tiles)
- All coordinate math centralized in `GridUtils` utility class
- Position formula: `screenX = (x - y) * tileWidth`, `screenY = (x + y) * tileHeight/2`
- Hex vertices derived mathematically for perfect tessellation (no gaps/overlap)
- Tile types: Grass (walkable), Water (blocked), Building (blocked)
- Custom polygon hit detection using cross-product edge testing

### Movement System
- **Manual Path Drawing**: Players have full control over the unit's movement path.
    - Hovering over valid neighbor tiles incrementally builds the path.
    - Hovering over a previous tile in the path backtracks (truncates the path).
    - The path is visualized with a blue arrow.
    - Movement is executed to the end of the manually drawn path.
    - `MyGame` maintains the `_currentPath` state.
    - `GridUtils.isNeighbor` is used to validate incremental steps.
- **Movement Visualization**:
    - **Border**: A continuous, animated gradient border outlines the reachable area (including the unit's current tile).
    - **Path**: A blue arrow follows the exact movement path.
- **Tile Control**:
    - Tiles have `controllable` and `alliance` properties.
    - **Capture**: Units capture Neutral controllable tiles upon entering them.
    - **Visuals**: Controlled tiles show a colored overlay (Blue for Menders, Red for AI).

## Positioning System
- **Single Source of Truth**: `MyGame.getTilePosition(x, y)` returns the exact world position for any grid coordinate.
- **Consistency**: All entities (units, projectiles, effects) use this method to ensure perfect alignment with tile centers.
- **Rendering**: `IsometricTile` renders its hexagon centered on its position (using canvas translation), ensuring the visual center matches the logical center.
- **Usage**:
  - Initial placement: `position = game.getTilePosition(x, y)`
  - Movement: `MoveToEffect(game.getTilePosition(newX, newY))`

### Unit System
- Units use same `GridUtils.gridToScreen()` as tiles for perfect centering
- Selection states: pulsing halo (selectable), static halo (selected)
- Spring animation for movement (elasticOut, 0.6s)
- Current types: Knight (blue, shield icon), Archer (green, arrow icon)

### Card System
- Cards displayed at bottom of screen (120x160px)
- Types: Attack (red), Move (blue), Defend (green)
- Flow: Select card → Select unit → Select target tile → Execute → Discard
- Master pool in `card_database.dart`, player gets copies with unique IDs

### Pathfinding
- BFS algorithm in `pathfinding_utils.dart`
- Uses axial hex coordinates: neighbors at `(±1,0), (0,±1), (+1,-1), (-1,+1)`
- Returns reachable tiles within unit's movement range

## Key State (in MyGame)

```dart
// Card state
List<CardModel> currentPlayerCardPool
CardComponent? selectedCard
CardModel? selectedCardForExecution
List<CardModel> discardPile

// Movement state
UnitComponent? selectedUnitForMovement
List<TileModel> highlightedMovementTiles

// Hover state (for overlays)
TileModel? hoveredTile
UnitModel? hoveredUnit
```

## Dependencies

- `flame: ^1.34.0` - Game engine
- `flame_forge2d: ^0.19.2+2` - Physics (gravity Vector2(0, 10.0))
- `web: ^1.0.0` - Browser console debug commands

## Patterns Used

- **Component-based**: Flame's PositionComponent for all game objects
- **Model-View separation**: Models are pure data, Components render them
- **Callback pattern**: Game notifies UI of state changes via callbacks
- **Effect system**: Flame's OpacityEffect, MoveToEffect for animations

## Common Tasks

**Add new unit type**: Create in `UnitModel`, add icon rendering in `UnitComponent._getUnitIcon()`

**Add new card**: Add to `masterCardPool` in `card_database.dart`

**Add new tile type**: Add to `TileType` enum in `tile_model.dart`, handle in `IsometricTile._getBaseColor()`

**Modify movement range**: Change `movement` field in `UnitModel`

**Debug in browser**: Console commands available: `showPlayerCards()`, `showMasterCards()`, `showDiscardPile()`

## User Commands

- **save**: Agent saves all changes and commits locally.
- **push**: Agent saves, commits, and pushes changes to the remote repository.

## Agent Instructions

- **NEVER PUSH**: Do not run `git push` unless explicitly instructed by the user.
- **Automated Verification**: After making changes to the codebase, ALWAYS try to hot reload (if running) or build, and explicitly check the terminal output for errors. If errors exist, FIX THEM immediately.
