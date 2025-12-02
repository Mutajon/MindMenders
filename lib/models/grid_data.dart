import 'dart:math';
import 'tile_model.dart';

class GridData {
  final int gridSize;
  late List<List<TileModel>> tiles;

  final int neuronCount;
  final int brainDamageCount;

  GridData({
    this.gridSize = 10, 
    this.neuronCount = 10,
    this.brainDamageCount = 5,
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
        ),
      ),
    );

    // 2. Place Brain Damage (Fixed count, no edges)
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
      );
      placedBD++;
    }

    // 3. Place Neurons (Fixed count, no edges, non-touching)
    int placedNeurons = 0;
    attempts = 0;

    while (placedNeurons < neuronCount && attempts < maxAttempts) {
      attempts++;
      // Exclude edges
      final x = random.nextInt(gridSize - 2) + 1;
      final y = random.nextInt(gridSize - 2) + 1;

      // Must be Dendrite (don't overwrite Brain Damage or existing Neuron)
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
        );
        placedNeurons++;
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
