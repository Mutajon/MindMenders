import '../models/tile_model.dart';
import '../models/grid_data.dart';
import '../utils/grid_utils.dart';

class AttackUtils {
  final GridData gridData;
  final GridUtils gridUtils;

  AttackUtils({required this.gridData, required this.gridUtils});

  /// Calculates valid attack targets and their paths for a given unit.
  /// Returns a map where the key is the target tile and the value is the path to it.
  Map<TileModel, List<TileModel>> calculateAttackTargets({
    required int startX,
    required int startY,
    required int range,
    required String attackType, // 'projectile', 'artillery', 'melee'
  }) {
    final targets = <TileModel, List<TileModel>>{};
    
    // The 6 hex directions (odd-r/even-r offset handling is tricky with axial,
    // but GridUtils.getNeighbors handles immediate. We need straight lines.)
    // Straight lines in Axial coords (q, r) are constant q, constant r, or constant q+r.
    // Our grid might be using offset coords (x,y).
    // Let's rely on mapping the 6 directions based on odd/even row logic if needed,
    // or better yet, simply iterate outwards in the 6 directions.
    
    // Directions for "odd-r" horizontal layout (often used with Tiled) or whatever GridUtils uses.
    // GridUtils.getNeighbors returns:
    // (x+1, y), (x-1, y), (x, y+1), (x, y-1), (x+1, y+1), (x-1, y-1) 
    // This looks like Axial coordinates where x and y are the axes?
    // Let's verify GridUtils.isNeighbor logic in our head:
    // (dx==1, dy==0), etc.
    // If the grid logic is strictly axial (x, y), then lines are easy.
    // Direction vectors: (1,0), (-1,0), (0,1), (0,-1), (1,1), (-1,-1)
    
    final directions = [
      (1, 0),   // Right
      (-1, 0),  // Left
      (0, 1),   // Down-Left ? (Depends on axis definition)
      (0, -1),  // Up-Right ?
      (1, 1),   // Down-Right ?
      (-1, -1), // Up-Left ?
    ];

    for (final dir in directions) {
      final List<TileModel> path = [];
      bool blocked = false;

      for (int i = 1; i <= range; i++) {
        final currentX = startX + (dir.$1 * i);
        final currentY = startY + (dir.$2 * i);
        
        final tile = gridData.getTileAt(currentX, currentY);
        
        if (tile == null) break; // Off map
        
        path.add(tile);

        // Check blocking rules
        if (attackType == 'projectile') {
            if (tile.blockShots) {
                 // Hit the blocker. Blocker is valid target? Usually yes.
                 // But path stops here.
                 targets[tile] = List.from(path);
                 blocked = true;
                 break;
            }
        }
        
        // Artillery logic: Can skip neighbors?
        // "if the attack is artillary, it can not attack tiles that are immidiatly adjacent"
        bool isValidTarget = true;
        if (attackType == 'artillery' && i == 1) {
            isValidTarget = false;
        }
        
        // Add as target if valid
        // NOTE: We assume we can attack ANY valid tile in range, 
        // not just occupied ones? 
        // "highlight in purple the possible tiles to attack"
        // Usually you can attack empty ground (e.g. to test usage) or strictly units?
        // Prompt says "click on valid attackable tile". 
        // Let's assume all walkable/controllable tiles are valid targets unless specified.
        if (isValidTarget) {
            targets[tile] = List.from(path);
        }
      }
    }

    return targets;
  }
}
