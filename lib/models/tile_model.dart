class TileModel {
  final int x;
  final int y;
  final String type;
  final String description;
  final bool walkable;
  final bool controllable;
  String alliance;

  TileModel({
    required this.x,
    required this.y,
    required this.type,
    required this.description,
    this.walkable = false,
    this.controllable = false,
    this.alliance = 'Neutral',
  });
}
