import 'dart:async';
import 'dart:math';
import 'package:mind_control/components/unit_component.dart';
import 'package:mind_control/game.dart';
import 'package:mind_control/models/tile_model.dart';
import 'package:mind_control/utils/pathfinding_utils.dart';
import 'package:mind_control/utils/tile_scorer.dart';

/// AI turn controller for managing Hive unit turns
class AITurnController {
  final MyGame game;
  late final TileScorer _scorer;
  final Random _random = Random();

  AITurnController(this.game) {
    _scorer = TileScorer(game);
  }

  /// Execute full AI turn for all Hive units
  Future<void> executeTurn() async {
    final hiveUnits = game.children
        .whereType<UnitComponent>()
        .where((u) => u.unitModel.alliance == 'Hive')
        .toList();

    print('AI Turn: ${hiveUnits.length} Hive units');

    for (int i = 0; i < hiveUnits.length; i++) {
      final unit = hiveUnits[i];
      print(
        'AI Turn: Unit ${i + 1}/${hiveUnits.length} - ${unit.unitModel.name}',
      );

      await _executeUnitTurn(unit);
    }
  }

  /// Execute turn for a single AI unit (movement + attack)
  Future<void> _executeUnitTurn(UnitComponent unit) async {
    // 1. Score all reachable tiles
    final scores = await _scoreMovementTiles(unit);

    if (scores.isEmpty) {
      print('No valid moves for ${unit.unitModel.name}');
      return;
    }

    // 2. Show debug visualization if enabled
    if (game.aiDebugMode) {
      await _showDebugScores(scores, unit);
    }

    // 3. Select best move (top 2 + random)
    final targetTile = _selectBestMove(scores);

    if (targetTile == null) {
      print('No target tile selected');
      return;
    }

    // 4. Execute movement
    await _executeMovement(unit, targetTile);

    // 5. Execute attack if possible
    await _executeAttack(unit);

    // 6. Clear debug visualization
    if (game.aiDebugMode) {
      game.clearDebugScores();
    }
  }

  /// Score all reachable tiles for a unit
  Future<Map<TileModel, double>> _scoreMovementTiles(UnitComponent unit) async {
    final scores = <TileModel, double>{};

    // Get movement range (with Neuron buff if applicable)
    final movementRange = game.getEffectiveMovementPoints(unit);

    // Get blocked tiles
    final blockedTiles = <String>{};
    for (final u in game.children.whereType<UnitComponent>()) {
      if (u != unit) {
        blockedTiles.add('${u.unitModel.x},${u.unitModel.y}');
      }
    }

    // Calculate reachable tiles
    final reachableTiles = PathfindingUtils.calculateReachableTiles(
      startX: unit.unitModel.x,
      startY: unit.unitModel.y,
      range: movementRange,
      gridData: game.gridData,
      blockedTiles: blockedTiles,
      excludeAlliance: 'Menders', // AI cannot move onto player-controlled tiles
    );

    // Score each reachable tile
    for (final tile in reachableTiles) {
      // Skip current position
      if (tile.x == unit.unitModel.x && tile.y == unit.unitModel.y) continue;

      final score = _scorer.scoreTile(tile, unit);
      scores[tile] = score;
    }

    return scores;
  }

  /// Select best move from scored tiles (top 2 + random selection)
  TileModel? _selectBestMove(Map<TileModel, double> scores) {
    if (scores.isEmpty) return null;

    // Sort by score (descending)
    final sortedEntries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Get top 2 scores
    final topTiles = sortedEntries.take(2).map((e) => e.key).toList();

    // Randomly select from top 2
    return topTiles[_random.nextInt(topTiles.length)];
  }

  /// Execute movement to target tile
  Future<void> _executeMovement(
    UnitComponent unit,
    TileModel targetTile,
  ) async {
    print(
      'Moving ${unit.unitModel.name} to (${targetTile.x}, ${targetTile.y})',
    );

    // Calculate path
    final blockedTiles = <String>{};
    for (final u in game.children.whereType<UnitComponent>()) {
      if (u != unit && u.unitModel.alliance != unit.unitModel.alliance) {
        blockedTiles.add('${u.unitModel.x},${u.unitModel.y}');
      }
    }

    final path = PathfindingUtils.findPath(
      startX: unit.unitModel.x,
      startY: unit.unitModel.y,
      endX: targetTile.x,
      endY: targetTile.y,
      gridData: game.gridData,
      blockedTiles: blockedTiles,
    );

    if (path.isEmpty) {
      print('No path found!');
      return;
    }

    // Execute movement using existing game logic
    final startX = unit.unitModel.x;
    final startY = unit.unitModel.y;
    final unitAlliance = unit.unitModel.alliance;

    await unit.moveTo(
      targetTile.x,
      targetTile.y,
      path: path,
      stepDuration: 0.3,
      onTileEntered: (tile) async {
        // Skip start tile
        if (tile.x == startX && tile.y == startY) return;

        // Handle ambush (AI can also be attacked)
        await game.handleAmbush(unit, tile);

        if (!tile.controllable) return;
        if (unit.unitModel.currentHP <= 0) return;

        // Capture logic

        bool isInFuturePath(TileModel candidate) {
          final currentIndex = path.indexOf(tile);
          if (currentIndex == -1) return false;
          for (int i = currentIndex + 1; i < path.length; i++) {
            if (path[i] == candidate) return true;
          }
          return false;
        }

        int tilesCapturedThisStep = 0;

        if (tile.alliance.toLowerCase() == 'neutral') {
          game.tileControlChange(tile, unitAlliance);
          tilesCapturedThisStep++;

          final neighbors = game.gridUtils.getNeighbors(tile.x, tile.y);
          for (final p in neighbors) {
            final neighbor = game.gridData.getTileAt(p.$1, p.$2);
            if (neighbor != null &&
                neighbor.controllable &&
                neighbor.alliance.toLowerCase() == 'neutral') {
              if (!isInFuturePath(neighbor)) {
                game.tileControlChange(neighbor, unitAlliance);
                tilesCapturedThisStep++;
              }
            }
          }
        } else if (tile.alliance != unitAlliance) {
          game.tileControlChange(tile, unitAlliance);
          tilesCapturedThisStep++;
        }

        // Show Visual Feedback for this step
        if (tilesCapturedThisStep > 0 && game.totalControllableTiles > 0) {
          final percent =
              (tilesCapturedThisStep / game.totalControllableTiles * 100)
                  .floor();
          if (percent > 0) {
            final pos = game.getTilePosition(tile.x, tile.y);
            if (pos != null) {
              game.showControlChange(pos, percent, unitAlliance);
            }
          }
        }
      },
    );

    // FIX: Update danger zones after movement to refresh UI
    game.updateDangerZones();
  }

  /// Execute attack if player unit is in range
  Future<void> _executeAttack(UnitComponent aiUnit) async {
    // Find all player units in attack range
    final playerUnits = game.children
        .whereType<UnitComponent>()
        .where((u) => u.unitModel.alliance == 'Menders')
        .toList();

    final targetsInRange = <UnitComponent>[];

    for (final playerUnit in playerUnits) {
      final distance = _getStepDistance(
        aiUnit.unitModel.x,
        aiUnit.unitModel.y,
        playerUnit.unitModel.x,
        playerUnit.unitModel.y,
      );

      if (distance != null && distance <= aiUnit.unitModel.attackRange) {
        // Check line of sight
        if (aiUnit.unitModel.attackType == 'artillery' ||
            _hasLineOfSight(aiUnit, playerUnit)) {
          targetsInRange.add(playerUnit);
        }
      }
    }

    if (targetsInRange.isEmpty) {
      print('No targets in range for ${aiUnit.unitModel.name}');
      return;
    }

    // Select target with lowest HP (random on tie)
    targetsInRange.sort((a, b) {
      final hpCompare = a.unitModel.currentHP.compareTo(b.unitModel.currentHP);
      if (hpCompare == 0) {
        return _random.nextBool() ? 1 : -1; // Random on tie
      }
      return hpCompare;
    });

    final target = targetsInRange.first;
    print(
      'Attacking ${target.unitModel.name} (HP: ${target.unitModel.currentHP})',
    );

    // Execute attack using existing game logic
    final targetTile = game.gridData.getTileAt(
      target.unitModel.x,
      target.unitModel.y,
    );
    if (targetTile == null) return;

    final startPos = game.getTilePosition(
      aiUnit.unitModel.x,
      aiUnit.unitModel.y,
    );
    final targetPos = game.getTilePosition(
      target.unitModel.x,
      target.unitModel.y,
    );

    if (startPos == null || targetPos == null) return;

    final damage = aiUnit.unitModel.attackValue;
    final completer = Completer<void>();

    // Spawn projectile (reuse existing ProjectileComponent)
    final projectile = game.createProjectile(
      startPos: startPos,
      targetPos: targetPos,
      isArtillery: aiUnit.unitModel.attackType == 'artillery',
      onHit: () {
        game.applyDamage(targetTile, damage);
        completer.complete();
      },
    );
    game.add(projectile);

    await completer.future;
  }

  /// Show debug scores on tiles
  Future<void> _showDebugScores(
    Map<TileModel, double> scores,
    UnitComponent unit,
  ) async {
    game.showDebugScores(scores);
    await Future.delayed(const Duration(seconds: 2));
  }

  /// Get step distance between two points
  int? _getStepDistance(int x1, int y1, int x2, int y2) {
    if (x1 == x2 && y1 == y2) return 0;

    final visited = <String>{};
    final queue = <(int, int, int)>[(x1, y1, 0)];
    visited.add('$x1,$y1');

    while (queue.isNotEmpty) {
      final (x, y, dist) = queue.removeAt(0);

      if (x == x2 && y == y2) return dist;

      final neighbors = game.gridUtils.getNeighbors(x, y);
      for (final (nx, ny) in neighbors) {
        final key = '$nx,$ny';
        if (!visited.contains(key)) {
          final tile = game.gridData.getTileAt(nx, ny);
          if (tile != null) {
            visited.add(key);
            queue.add((nx, ny, dist + 1));
          }
        }
      }
    }

    return null;
  }

  /// Check line of sight
  bool _hasLineOfSight(UnitComponent attacker, UnitComponent target) {
    final path = game.attackUtils.getAttackPath(
      attacker.unitModel.x,
      attacker.unitModel.y,
      target.unitModel.x,
      target.unitModel.y,
      attacker.unitModel.attackType,
    );
    return path != null;
  }
}
