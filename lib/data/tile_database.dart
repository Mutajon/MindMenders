import '../models/tile_model.dart';

class TileDatabase {
  static final Map<String, TileModel> tiles = {
    'Dendrite': TileModel(
      x: 0,
      y: 0,
      type: 'Dendrite',
      description: 'No special effect',
      walkable: true,
      controllable: true,
      blockShots: false,
    ),
    'Brain Damage': TileModel(
      x: 0,
      y: 0,
      type: 'Brain Damage',
      description: 'Cannot be walked through. Spawning point for enemy units.',
      walkable: false,
      controllable: false,
      blockShots: false,
    ),
    'Memory': TileModel(
      x: 0,
      y: 0,
      type: 'Memory',
      description:
          'Strategic control point. Walkable. Blocks shots. Gains shield when controlled.',
      walkable: true,
      controllable: true,
      blockShots: true,
    ),
    'Neuron': TileModel(
      x: 0,
      y: 0,
      type: 'Neuron',
      description:
          'Blocks shots and movement. +1 movement if starting a turn next to it.',
      walkable: false,
      controllable: false,
      blockShots: true,
    ),
  };

  // Factory method to create a new instance at specific coordinates
  static TileModel create(
    String type,
    int x,
    int y, {
    String alliance = 'Neutral',
  }) {
    final template = tiles[type];
    if (template == null) {
      throw Exception('Tile type $type not found in database');
    }

    // Initialize shield count for Memory tiles
    int shieldCount = 0;
    int maxShields = 1;

    if (type == 'Memory') {
      maxShields = 1;
      // Memory tiles start with a shield if controlled by a faction
      shieldCount = (alliance != 'Neutral') ? 1 : 0;
    }

    return TileModel(
      x: x,
      y: y,
      type: template.type,
      description: template.description,
      walkable: template.walkable,
      controllable: template.controllable,
      blockShots: template.blockShots,
      alliance: alliance,
      shieldCount: shieldCount,
      maxShields: maxShields,
    );
  }
}
