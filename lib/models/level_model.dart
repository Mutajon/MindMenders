import 'dart:math';

class LevelModel {
  final String id;
  final String name;
  final String category; // (park, hospital, school, elderly house)
  final int neuronTilesCount;
  final int brainDamageTilesCount;
  final int memoryTilesCount;
  final int startingEnemiesCount;
  final List<String> startingEnemyTypes;
  final int gridSize;
  final double enemyControlledPercentage; // (starting percent of enemy controlled tiles)
  
  // Optional coordinate lists (if null/empty, use random generation)
  final List<Point<int>>? neuronCoordinates;
  final List<Point<int>>? brainDamageCoordinates;
  final List<Point<int>>? memoryCoordinates;
  final List<Point<int>>? startingEnemyCoordinates;
  final List<Point<int>>? enemyControlledCoordinates;

  const LevelModel({
    required this.id,
    required this.name,
    required this.category,
    required this.gridSize,
    required this.neuronTilesCount,
    required this.brainDamageTilesCount,
    required this.memoryTilesCount,
    required this.startingEnemiesCount,
    required this.startingEnemyTypes,
    required this.enemyControlledPercentage,
    this.neuronCoordinates,
    this.brainDamageCoordinates,
    this.memoryCoordinates,
    this.startingEnemyCoordinates,
    this.enemyControlledCoordinates,
  });
}
