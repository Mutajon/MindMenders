import 'dart:math';
import '../models/tile_model.dart';

class GridData {
  final int gridSize;
  late List<List<TileModel>> tiles;

  final int neuronCount;
  final int brainDamageCount;
  final int memoryCount;

  final List<Point<int>>? neuronCoordinates;
  final List<Point<int>>? brainDamageCoordinates;
  final List<Point<int>>? memoryCoordinates;

  GridData({
    this.gridSize = 10, 
    this.neuronCount = 10,
    this.brainDamageCount = 5,
    this.memoryCount = 0,
    this.neuronCoordinates,
    this.brainDamageCoordinates,
    this.memoryCoordinates,
  }) {
    _initializeGrid();
  }

  void _initializeGrid() {
    final random = Random();
    
    // 1. Initialize all as Dendrite
    tiles = List.generate(
      gridSize,
      (x) => List.generate(
        gridSize,
        (y) => TileModel(
          x: x,
          y: y,
          type: 'Dendrite',
          description: 'A conductive dendrite pathway',
          walkable: true,
          controllable: true,
          blockShots: false,
        ),
      ),
    );

    // 2. Place Brain Damage
    if (brainDamageCoordinates != null && brainDamageCoordinates!.isNotEmpty) {
      for (final p in brainDamageCoordinates!) {
        if (p.x >= 0 && p.x < gridSize && p.y >= 0 && p.y < gridSize) {
          tiles[p.x][p.y] = TileModel(
            x: p.x,
            y: p.y,
            type: 'Brain Damage',
            description: 'Damaged neural tissue',
            walkable: false,
            blockShots: false,
          );
        }
      }
    } else {
      // Random placement
      int placedBD = 0;
      int attempts = 0;
      const maxAttempts = 1000;

      while (placedBD < brainDamageCount && attempts < maxAttempts) {
        attempts++;
        // Exclude edges
        final x = random.nextInt(gridSize - 2) + 1;
        final y = random.nextInt(gridSize - 2) + 1;

        if (tiles[x][y].type != 'Dendrite') continue;

        tiles[x][y] = TileModel(
          x: x,
          y: y,
          type: 'Brain Damage',
          description: 'Damaged neural tissue',
          walkable: false,
          blockShots: false,
        );
        placedBD++;
      }
    }
    
    // 3. Place Memory Tiles
    if (memoryCoordinates != null && memoryCoordinates!.isNotEmpty) {
      for (final p in memoryCoordinates!) {
        if (p.x >= 0 && p.x < gridSize && p.y >= 0 && p.y < gridSize) {
          tiles[p.x][p.y] = TileModel(
            x: p.x,
            y: p.y,
            type: 'Memory',
            description: 'A memory storage unit',
            walkable: false, // Not walkable
            controllable: true,
            blockShots: true,
          );
        }
      }
    } else {
      // Random placement
      int placedMemory = 0;
      int attempts = 0;
      const maxAttempts = 1000;

      while (placedMemory < memoryCount && attempts < maxAttempts) {
        attempts++;
        // Exclude edges
        final x = random.nextInt(gridSize - 2) + 1;
        final y = random.nextInt(gridSize - 2) + 1;

        if (tiles[x][y].type != 'Dendrite') continue;

        tiles[x][y] = TileModel(
          x: x,
          y: y,
          type: 'Memory',
          description: 'A memory storage unit',
          walkable: false, // Not walkable
          controllable: true,
          blockShots: true,
        );
        placedMemory++;
      }
    }

    // 4. Place Neurons
    if (neuronCoordinates != null && neuronCoordinates!.isNotEmpty) {
      for (final p in neuronCoordinates!) {
        if (p.x >= 0 && p.x < gridSize && p.y >= 0 && p.y < gridSize) {
          // Check for existing type? Assuming coordinates are valid and don't overlap
          tiles[p.x][p.y] = TileModel(
            x: p.x,
            y: p.y,
            type: 'Neuron',
            description: 'A processing neuron node',
            walkable: false,
            blockShots: true,
          );
        }
      }
    } else {
      // Random placement
      int placedNeurons = 0;
      int attempts = 0;
      const maxAttempts = 1000;

      while (placedNeurons < neuronCount && attempts < maxAttempts) {
        attempts++;
        // Exclude edges
        final x = random.nextInt(gridSize - 2) + 1;
        final y = random.nextInt(gridSize - 2) + 1;

        // Must be Dendrite
        if (tiles[x][y].type != 'Dendrite') continue;

        // Check neighbors for existing Neurons
        bool touchingNeuron = false;
        // Axial hex neighbors (corrected for isometric projection)
        final neighbors = [
          [x + 1, y], [x - 1, y],
          [x, y + 1], [x, y - 1],
          [x + 1, y + 1], [x - 1, y - 1]
        ];

        for (final n in neighbors) {
          final nx = n[0];
          final ny = n[1];
          if (nx >= 0 && nx < gridSize && ny >= 0 && ny < gridSize) {
            if (tiles[nx][ny].type == 'Neuron') {
              touchingNeuron = true;
              break;
            }
          }
        }

        if (!touchingNeuron) {
          tiles[x][y] = TileModel(
            x: x,
            y: y,
            type: 'Neuron',
            description: 'A processing neuron node',
            walkable: false,
            blockShots: true,
          );
          placedNeurons++;
        }
      }
    }
    
    // Verification
    for (int x = 0; x < gridSize; x++) {
      for (int y = 0; y < gridSize; y++) {
        if (tiles[x][y].type == 'Neuron') {
          final neighbors = [
            [x + 1, y], [x - 1, y],
            [x, y + 1], [x, y - 1],
            [x + 1, y + 1], [x - 1, y - 1]
          ];
          for (final n in neighbors) {
            final nx = n[0];
            final ny = n[1];
            if (nx >= 0 && nx < gridSize && ny >= 0 && ny < gridSize) {
              if (tiles[nx][ny].type == 'Neuron') {
                print('WARNING: Touching Neurons detected at ($x,$y) and ($nx,$ny)');
              }
            }
          }
        }
      }
    }
  }

  TileModel? getTileAt(int x, int y) {
    if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) {
      return tiles[x][y];
    }
    return null;
  }
}
