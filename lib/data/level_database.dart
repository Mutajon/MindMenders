import '../models/level_model.dart';

class LevelDatabase {
  static final List<LevelModel> levels = [
    LevelModel(
      id: 'test_level',
      name: 'Test Level',
      category: 'test',
      gridSize: 10,
      neuronTilesCount: 5, // Approx 70% of 100 tiles
      brainDamageTilesCount: 3,
      memoryTilesCount: 2,
      startingEnemiesCount: 2,
      startingEnemyTypes: ['Sweeper', 'Devourer'],
      enemyControlledPercentage: 30,
      enemyControlledTilesStartingPosition: 'top',
    ),
  ];

  static LevelModel getLevel(String id) {
    return levels.firstWhere(
      (level) => level.id == id,
      orElse: () => levels.first,
    );
  }
}
