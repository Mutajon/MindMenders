class TileModel {
  final int x;
  final int y;
  final String type;
  final String description;
  final bool walkable;
  final bool controllable;
  final bool blockShots;
  String alliance;

  // Shield system for Memory tiles
  int shieldCount;
  final int maxShields;

  TileModel({
    required this.x,
    required this.y,
    required this.type,
    required this.description,
    this.walkable = false,
    this.controllable = false,
    this.blockShots = false,
    this.alliance = 'Neutral',
    this.shieldCount = 0,
    this.maxShields = 1,
  });
}
