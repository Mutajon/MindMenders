class TileModel {
  final int x;
  final int y;
  final String type;
  final String description;
  final bool walkable;

  TileModel({
    required this.x,
    required this.y,
    required this.type,
    required this.description,
    this.walkable = false,
  });
}
