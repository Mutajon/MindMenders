class TileDefinition {
  final int x;
  final int y;
  final String type;
  final String? alliance; // Optional, for pre-set alliances
  final String? unitName; // Optional, for placing units in the editor

  const TileDefinition({
    required this.x,
    required this.y,
    required this.type,
    this.alliance,
    this.unitName,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'type': type,
      if (alliance != null) 'alliance': alliance,
      if (unitName != null) 'unitName': unitName,
    };
  }

  factory TileDefinition.fromJson(Map<String, dynamic> json) {
    return TileDefinition(
      x: json['x'],
      y: json['y'],
      type: json['type'],
      alliance: json['alliance'],
      unitName: json['unitName'],
    );
  }
}
