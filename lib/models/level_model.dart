import 'dart:math';
import 'tile_definition.dart';

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
  final double
  enemyControlledPercentage; // (starting percent of enemy controlled tiles)

  // Optional coordinate lists (if null/empty, use random generation)
  final List<Point<int>>? neuronCoordinates;
  final List<Point<int>>? brainDamageCoordinates;
  final List<Point<int>>? memoryCoordinates;
  final List<Point<int>>? startingEnemyCoordinates;

  // Strategy for enemy controlled tiles placement
  // Valid values: 'top', 'bottom', 'left', 'right', 'neurons', 'memories'
  final String enemyControlledTilesStartingPosition;

  // Full tile grid definition (optional, for custom levels)
  final List<List<TileDefinition>>? tileGrid;

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
    this.enemyControlledTilesStartingPosition = 'top',
    this.tileGrid,
  });

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'gridSize': gridSize,
      'neuronTilesCount': neuronTilesCount,
      'brainDamageTilesCount': brainDamageTilesCount,
      'memoryTilesCount': memoryTilesCount,
      'startingEnemiesCount': startingEnemiesCount,
      'startingEnemyTypes': startingEnemyTypes,
      'enemyControlledPercentage': enemyControlledPercentage,
      'enemyControlledTilesStartingPosition':
          enemyControlledTilesStartingPosition,
      if (tileGrid != null)
        'tileGrid': tileGrid!
            .map((row) => row.map((tile) => tile.toJson()).toList())
            .toList(),
      if (neuronCoordinates != null)
        'neuronCoordinates': neuronCoordinates!
            .map((p) => {'x': p.x, 'y': p.y})
            .toList(),
      if (brainDamageCoordinates != null)
        'brainDamageCoordinates': brainDamageCoordinates!
            .map((p) => {'x': p.x, 'y': p.y})
            .toList(),
      if (memoryCoordinates != null)
        'memoryCoordinates': memoryCoordinates!
            .map((p) => {'x': p.x, 'y': p.y})
            .toList(),
      if (startingEnemyCoordinates != null)
        'startingEnemyCoordinates': startingEnemyCoordinates!
            .map((p) => {'x': p.x, 'y': p.y})
            .toList(),
    };
  }

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      id: json['id'] ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] ?? 'Unnamed Level',
      category: json['category'] ?? 'custom',
      gridSize: json['gridSize'] ?? 10,
      neuronTilesCount: json['neuronTilesCount'] ?? 0,
      brainDamageTilesCount: json['brainDamageTilesCount'] ?? 0,
      memoryTilesCount: json['memoryTilesCount'] ?? 0,
      startingEnemiesCount: json['startingEnemiesCount'] ?? 0,
      startingEnemyTypes: json['startingEnemyTypes'] != null
          ? List<String>.from(json['startingEnemyTypes'])
          : [],
      enemyControlledPercentage:
          (json['enemyControlledPercentage'] as num?)?.toDouble() ?? 0.0,
      enemyControlledTilesStartingPosition:
          json['enemyControlledTilesStartingPosition'] ?? 'top',
      tileGrid: json['tileGrid'] != null
          ? (json['tileGrid'] as List)
                .map(
                  (row) => (row as List)
                      .map(
                        (t) =>
                            TileDefinition.fromJson(t as Map<String, dynamic>),
                      )
                      .toList(),
                )
                .toList()
          : null,
      neuronCoordinates: json['neuronCoordinates'] != null
          ? (json['neuronCoordinates'] as List)
                .map((p) => Point<int>(p['x'], p['y']))
                .toList()
          : null,
      brainDamageCoordinates: json['brainDamageCoordinates'] != null
          ? (json['brainDamageCoordinates'] as List)
                .map((p) => Point<int>(p['x'], p['y']))
                .toList()
          : null,
      memoryCoordinates: json['memoryCoordinates'] != null
          ? (json['memoryCoordinates'] as List)
                .map((p) => Point<int>(p['x'], p['y']))
                .toList()
          : null,
      startingEnemyCoordinates: json['startingEnemyCoordinates'] != null
          ? (json['startingEnemyCoordinates'] as List)
                .map((p) => Point<int>(p['x'], p['y']))
                .toList()
          : null,
    );
  }

  // Create empty level for level creator
  factory LevelModel.createEmpty({
    required String name,
    required int gridSize,
  }) {
    return LevelModel(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: 'custom',
      gridSize: gridSize,
      neuronTilesCount: 0,
      brainDamageTilesCount: 0,
      memoryTilesCount: 0,
      startingEnemiesCount: 0,
      startingEnemyTypes: [],
      enemyControlledPercentage: 0,
      tileGrid: _createEmptyGrid(gridSize),
    );
  }

  static List<List<TileDefinition>> _createEmptyGrid(int size) {
    return List.generate(
      size,
      (y) => List.generate(
        size,
        (x) => TileDefinition(
          x: x,
          y: y,
          type: 'Dendrite', // Default tile type
        ),
      ),
    );
  }
}
