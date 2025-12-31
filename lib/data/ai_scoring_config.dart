/// AI scoring configuration for tile evaluation during AI turns.
/// This is a data-driven system for easy modification and expansion.
library;

/// Scoring criteria for evaluating tiles during AI movement
enum ScoringCriterion {
  targetableByPlayer, // Tiles within attack range of player units (negative)
  canTargetPlayer, // Can attack player FROM this tile (positive)
  nextToNeuron, // Adjacent to Neuron tiles (positive)
  nextToNeutralMemory, // Adjacent to neutral Memory tiles (positive)
  nextToPlayerMemory, // Adjacent to player-controlled Memory tiles (positive)
  onPlayerTile, // Standing on player-controlled tile (positive)
  onNeutralAdjacentToNeutral, // Neutral tile next to neutral tile (positive)
  closerToPlayerUnit, // Closer to nearest player unit (step distance)
  closerToNeutralMemory, // Closer to nearest neutral Memory (step distance)
  closerToPlayerMemory, // Closer to nearest player Memory (step distance)
  closerToPlayerCluster, // Closer to nearest player tile cluster (step distance)
  closerToNeutralCluster, // Closer to nearest neutral tile cluster (step distance)
  escapeRange, // Moving from a targetable tile to a non-targetable one (positive)
  onHiveTile, // Standing on a Hive-controlled tile (negative for Sweepers)
}

/// AI scoring configuration database
class AIScoringConfig {
  /// Scoring weights per unit type
  static final Map<String, Map<ScoringCriterion, double>> unitScores = {
    'Sweeper 1.0': {
      ScoringCriterion.targetableByPlayer: -5,
      ScoringCriterion.canTargetPlayer: 0,
      ScoringCriterion.nextToNeuron: 2,
      ScoringCriterion.nextToNeutralMemory: 5,
      ScoringCriterion.nextToPlayerMemory: 7,
      ScoringCriterion.onPlayerTile: 0, // AI cannot move to player tiles
      ScoringCriterion.onNeutralAdjacentToNeutral: 1,
      ScoringCriterion.closerToPlayerUnit: -3,
      ScoringCriterion.closerToNeutralMemory: 2,
      ScoringCriterion.closerToPlayerMemory: 1,
      ScoringCriterion.closerToPlayerCluster: 4,
      ScoringCriterion.closerToNeutralCluster: 3,
      ScoringCriterion.escapeRange: 6,
      ScoringCriterion.onHiveTile: -5,
    },
    'Terminator 1.0': {
      ScoringCriterion.targetableByPlayer: -2,
      ScoringCriterion.canTargetPlayer: 7,
      ScoringCriterion.nextToNeuron: 3,
      ScoringCriterion.nextToNeutralMemory: 3,
      ScoringCriterion.nextToPlayerMemory: 2,
      ScoringCriterion.onPlayerTile: 0, // AI cannot move to player tiles
      ScoringCriterion.onNeutralAdjacentToNeutral: 1,
      ScoringCriterion.closerToPlayerUnit: 3,
      ScoringCriterion.closerToNeutralMemory: 2,
      ScoringCriterion.closerToPlayerMemory: 3,
      ScoringCriterion.closerToPlayerCluster: 2,
      ScoringCriterion.closerToNeutralCluster: 0,
      ScoringCriterion.escapeRange: 6,
      ScoringCriterion.onHiveTile: 0,
    },
  };

  /// Get scoring weights for a unit type
  static Map<ScoringCriterion, double>? getScoresForUnit(String unitName) {
    return unitScores[unitName];
  }
}
