class UnitModel {
  final String name;
  final int hp;
  final String attackMode;
  final int damageValue;
  final int defense;
  final String specialAbility;
  final int x;
  final int y;
  final int movement;

  UnitModel({
    required this.name,
    required this.hp,
    required this.attackMode,
    required this.damageValue,
    required this.defense,
    required this.specialAbility,
    required this.x,
    required this.y,
    this.movement = 3,
  });
}
