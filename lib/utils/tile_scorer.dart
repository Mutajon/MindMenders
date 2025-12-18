import 'package:mind_control/components/unit_component.dart';
import 'package:mind_control/data/ai_scoring_config.dart';
import 'package:mind_control/game.dart';
import 'package:mind_control/models/tile_model.dart';

/// Tile scoring engine for AI decision making
class TileScorer {
  final MyGame game;

  TileScorer(this.game);

  /// Score a tile for an AI unit based on scoring configuration
  double scoreTile(TileModel tile, UnitComponent unit) {
    final unitName = unit.unitModel.name;
    final scoringWeights = AIScoringConfig.getScoresForUnit('$unitName 1.0');

    if (scoringWeights == null) {
      print('Warning: No scoring config for $unitName');
      return 0.0;
    }

    double totalScore = 0.0;

    // Evaluate each scoring criterion
    for (final entry in scoringWeights.entries) {
      final criterion = entry.key;
      final weight = entry.value;
      final count = _evaluateCriterion(criterion, tile, unit);
      totalScore += weight * count;
    }

    return totalScore;
  }

  /// Evaluate a single scoring criterion and return count (for cumulative scoring)
  double _evaluateCriterion(
    ScoringCriterion criterion,
    TileModel tile,
    UnitComponent unit,
  ) {
    switch (criterion) {
      case ScoringCriterion.targetableByPlayer:
        return _countTargetableByPlayer(tile);
      case ScoringCriterion.canTargetPlayer:
        return _countCanTargetPlayer(tile, unit);
      case ScoringCriterion.nextToNeuron:
        return _countAdjacentTileType(tile, 'Neuron');
      case ScoringCriterion.nextToNeutralMemory:
        return _countAdjacentMemory(tile, 'Neutral');
      case ScoringCriterion.nextToPlayerMemory:
        return _countAdjacentMemory(tile, 'Menders');
      case ScoringCriterion.onPlayerTile:
        return tile.alliance == 'Menders' ? 1.0 : 0.0;
      case ScoringCriterion.onNeutralAdjacentToNeutral:
        return _scoreNeutralAdjacentToNeutral(tile);
      case ScoringCriterion.closerToPlayerUnit:
        return _scoreCloserToPlayerUnit(tile, unit);
      case ScoringCriterion.closerToNeutralMemory:
        return _scoreCloserToMemory(tile, 'Neutral');
      case ScoringCriterion.closerToPlayerMemory:
        return _scoreCloserToMemory(tile, 'Menders');
      case ScoringCriterion.closerToPlayerCluster:
        return _scoreCloserToCluster(tile, 'Menders');
      case ScoringCriterion.closerToNeutralCluster:
        return _scoreCloserToCluster(tile, 'Neutral');
      case ScoringCriterion.escapeRange:
        return _scoreEscapeRange(tile, unit);
      case ScoringCriterion.onHiveTile:
        return tile.alliance.toLowerCase() == 'hive' ? 1.0 : 0.0;
    }
  }

  /// Count how many player units can attack this tile
  double _countTargetableByPlayer(TileModel tile) {
    int count = 0;
    final playerUnits = game.children.whereType<UnitComponent>().where(
      (u) => u.unitModel.alliance == 'Menders',
    );

    for (final playerUnit in playerUnits) {
      // Check if tile is in range
      final distance = _getStepDistance(
        playerUnit.unitModel.x,
        playerUnit.unitModel.y,
        tile.x,
        tile.y,
      );

      if (distance != null && distance <= playerUnit.unitModel.attackRange) {
        // Check line of sight if not artillery
        if (playerUnit.unitModel.attackType == 'artillery' ||
            _hasLineOfSight(playerUnit, tile)) {
          count++;
        }
      }
    }
    return count.toDouble();
  }

  /// Count how many player units this AI unit can attack FROM this tile
  double _countCanTargetPlayer(TileModel tile, UnitComponent aiUnit) {
    int count = 0;
    final playerUnits = game.children.whereType<UnitComponent>().where(
      (u) => u.unitModel.alliance == 'Menders',
    );

    for (final playerUnit in playerUnits) {
      final distance = _getStepDistance(
        tile.x,
        tile.y,
        playerUnit.unitModel.x,
        playerUnit.unitModel.y,
      );

      if (distance != null && distance <= aiUnit.unitModel.attackRange) {
        // Check line of sight if not artillery
        if (aiUnit.unitModel.attackType == 'artillery' ||
            _hasLineOfSightFrom(
              tile,
              playerUnit.unitModel.x,
              playerUnit.unitModel.y,
              aiUnit.unitModel.attackType,
            )) {
          count++;
        }
      }
    }
    return count.toDouble();
  }

  /// Count adjacent tiles of a specific type
  double _countAdjacentTileType(TileModel tile, String tileType) {
    int count = 0;
    final neighbors = game.gridUtils.getNeighbors(tile.x, tile.y);

    for (final (nx, ny) in neighbors) {
      final neighbor = game.gridData.getTileAt(nx, ny);
      if (neighbor != null && neighbor.type == tileType) {
        count++;
      }
    }
    return count.toDouble();
  }

  /// Count adjacent Memory tiles with specific alliance
  double _countAdjacentMemory(TileModel tile, String alliance) {
    int count = 0;
    final neighbors = game.gridUtils.getNeighbors(tile.x, tile.y);

    for (final (nx, ny) in neighbors) {
      final neighbor = game.gridData.getTileAt(nx, ny);
      if (neighbor != null &&
          neighbor.type == 'Memory' &&
          neighbor.alliance.toLowerCase() == alliance.toLowerCase()) {
        count++;
      }
    }
    return count.toDouble();
  }

  /// Score for neutral tile adjacent to another neutral tile
  double _scoreNeutralAdjacentToNeutral(TileModel tile) {
    if (tile.alliance.toLowerCase() != 'neutral') return 0.0;

    final neighbors = game.gridUtils.getNeighbors(tile.x, tile.y);
    for (final (nx, ny) in neighbors) {
      final neighbor = game.gridData.getTileAt(nx, ny);
      if (neighbor != null && neighbor.alliance.toLowerCase() == 'neutral') {
        return 1.0;
      }
    }
    return 0.0;
  }

  /// Score for escaping player attack range
  double _scoreEscapeRange(TileModel targetTile, UnitComponent unit) {
    // 1. Get current tile
    final currentTile = game.gridData.getTileAt(
      unit.unitModel.x,
      unit.unitModel.y,
    );
    if (currentTile == null) return 0.0;

    // 2. Is current tile targetable?
    final currentIsTargetable = _countTargetableByPlayer(currentTile) > 0;
    if (!currentIsTargetable) return 0.0;

    // 3. Is target tile non-targetable?
    final targetIsTargetable = _countTargetableByPlayer(targetTile) > 0;

    // If starting in danger and moving to safety, return 1.0 (will be multiplied by weight 6)
    return !targetIsTargetable ? 1.0 : 0.0;
  }

  /// Score based on distance to nearest player unit
  /// Uses inverse distance - closer = higher score
  double _scoreCloserToPlayerUnit(TileModel tile, UnitComponent aiUnit) {
    final playerUnits = game.children.whereType<UnitComponent>().where(
      (u) => u.unitModel.alliance == 'Menders',
    );

    if (playerUnits.isEmpty) return 0.0;

    int? minDistance;
    for (final playerUnit in playerUnits) {
      final distance = _getStepDistance(
        tile.x,
        tile.y,
        playerUnit.unitModel.x,
        playerUnit.unitModel.y,
      );
      if (distance != null) {
        minDistance = minDistance == null
            ? distance
            : (distance < minDistance ? distance : minDistance);
      }
    }

    if (minDistance == null || minDistance == 0) return 0.0;

    // Inverse distance: closer = higher score
    // Max reasonable distance is ~20, so normalize
    return (20 - minDistance).clamp(0, 20).toDouble();
  }

  /// Score based on distance to nearest Memory tile with specific alliance
  double _scoreCloserToMemory(TileModel tile, String alliance) {
    int? minDistance;

    for (final row in game.gridData.tiles) {
      for (final t in row) {
        if (t.type == 'Memory' &&
            t.alliance.toLowerCase() == alliance.toLowerCase()) {
          final distance = _getStepDistance(tile.x, tile.y, t.x, t.y);
          if (distance != null) {
            minDistance = minDistance == null
                ? distance
                : (distance < minDistance ? distance : minDistance);
          }
        }
      }
    }

    if (minDistance == null || minDistance == 0) return 0.0;
    return (20 - minDistance).clamp(0, 20).toDouble();
  }

  /// Score based on distance to nearest cluster of tiles
  /// Cluster size 3+ scores based on size (3=3, 4=4, etc.)
  double _scoreCloserToCluster(TileModel tile, String alliance) {
    final clusters = _findClusters(alliance);
    if (clusters.isEmpty) return 0.0;

    double bestScore = 0.0;

    for (final cluster in clusters) {
      if (cluster.length < 3) continue; // Need 3+ for a cluster

      // Find closest tile in cluster
      int? minDistance;
      for (final clusterTile in cluster) {
        final distance = _getStepDistance(
          tile.x,
          tile.y,
          clusterTile.x,
          clusterTile.y,
        );
        if (distance != null) {
          minDistance = minDistance == null
              ? distance
              : (distance < minDistance ? distance : minDistance);
        }
      }

      if (minDistance != null) {
        // Score = cluster size if close, reduced by distance
        final clusterScore = cluster.length.toDouble();
        final distancePenalty = minDistance.toDouble();
        final score = (clusterScore - distancePenalty * 0.5).clamp(
          0,
          clusterScore,
        );
        bestScore = score > bestScore ? score.toDouble() : bestScore;
      }
    }

    return bestScore;
  }

  /// Find all clusters of tiles with specific alliance (3+ connected tiles)
  List<List<TileModel>> _findClusters(String alliance) {
    final visited = <TileModel>{};
    final clusters = <List<TileModel>>[];

    for (final row in game.gridData.tiles) {
      for (final t in row) {
        if (t.alliance.toLowerCase() != alliance.toLowerCase()) continue;
        if (visited.contains(t)) continue;

        // BFS to find connected component
        final cluster = <TileModel>[];
        final queue = <TileModel>[t];
        visited.add(t);

        while (queue.isNotEmpty) {
          final current = queue.removeAt(0);
          cluster.add(current);

          final neighbors = game.gridUtils.getNeighbors(current.x, current.y);
          for (final (nx, ny) in neighbors) {
            final neighbor = game.gridData.getTileAt(nx, ny);
            if (neighbor != null &&
                neighbor.alliance.toLowerCase() == alliance.toLowerCase() &&
                !visited.contains(neighbor)) {
              visited.add(neighbor);
              queue.add(neighbor);
            }
          }
        }

        if (cluster.length >= 3) {
          clusters.add(cluster);
        }
      }
    }

    return clusters;
  }

  /// Get step-based distance between two points using BFS
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
            // Only count valid tiles
            visited.add(key);
            queue.add((nx, ny, dist + 1));
          }
        }
      }
    }

    return null; // No path found
  }

  /// Check line of sight from unit to tile
  bool _hasLineOfSight(UnitComponent unit, TileModel target) {
    final path = game.attackUtils.getAttackPath(
      unit.unitModel.x,
      unit.unitModel.y,
      target.x,
      target.y,
      unit.unitModel.attackType,
    );
    return path != null;
  }

  /// Check line of sight from tile to target coordinates
  bool _hasLineOfSightFrom(
    TileModel fromTile,
    int targetX,
    int targetY,
    String attackType,
  ) {
    final path = game.attackUtils.getAttackPath(
      fromTile.x,
      fromTile.y,
      targetX,
      targetY,
      attackType,
    );
    return path != null;
  }
}
