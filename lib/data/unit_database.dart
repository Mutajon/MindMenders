import '../models/unit_model.dart';

class UnitDatabase {
  static UnitModel getManipulator(int x, int y) {
    return UnitModel(
      name: 'Manipulator',
      alliance: 'Menders',
      maxHP: 3,
      attackRange: 5,
      attackValue: 1,
      attackType: 'artillery',
      specialAbility: 'replace position of two tiles',
      movementPoints: 3,
      x: x,
      y: y,
    );
  }
}
