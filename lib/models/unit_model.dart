class UnitModel {
  final String name;
  final int maxHP;
  int currentHP;
  final int attackRange;
  final int attackValue;
  final String attackType; //artillary, melee, projectile
  final String specialAbility;
  int x;
  int y;
  final int movementPoints;
  final String alliance; // menders, enemies, neutral

  UnitModel({
    required this.name,
    required this.maxHP,
    int? currentHP,
    required this.attackRange,
    required this.attackValue,
    required this.attackType,
    required this.specialAbility,
    required this.x,
    required this.y,
    this.movementPoints = 3,
    this.alliance = 'Menders',
    this.hasShield = false,
  }) : currentHP = currentHP ?? maxHP;

  bool hasShield;
}
