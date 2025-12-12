import '../models/unit_model.dart';

class UnitDatabase {
  static final Map<String, UnitModel Function(int x, int y)> units = {
    'Manipulator': (x, y) => UnitModel(
           name: 'Manipulator',
      description: 'Grid expert',
      alliance: 'Menders',
      maxHP: 3,
      attackRange: 4,
      attackValue: 1,
      attackType: 'artillery',
      specialAbility: 'replace position of two tiles',
      movementPoints: 2,
      x: x,
      y: y,
    ),
    'Crazy Nina': (x, y) => UnitModel(
        name: 'Crazy Nina',
      description: 'Attack specialist',
      alliance: 'Menders',
      maxHP: 4,
      attackRange: 2,
      attackValue: 2,
      attackType: 'projectile',
      specialAbility: 'deal 1 damage to ALL units in a 2 tile radius',
      movementPoints: 3,
      x: x,
      y: y,
    ),
    'Terminator': (x, y) => UnitModel(
          name: 'Terminator',
          description: 'Searches and destroys menders',
          alliance: 'Hive',
          maxHP: 3,
          attackRange: 5,
          attackValue: 1,
          attackType: 'projectile',
          specialAbility: '+1 damage when on 1 life',
          movementPoints: 3,
          x: x,
          y: y,
        ),
     'Sweeper': (x, y) => UnitModel(
          name: 'Sweeper',
          description: 'Claims brain territory',
          alliance: 'Hive',
          maxHP: 7,
          attackRange: 1,
          attackValue: 1,
          attackType: 'projectile',
          specialAbility: 'None',
          movementPoints: 3,
          x: x,
          y: y,
        ),
  };

  static UnitModel create(String unitName, int x, int y) {
    return units[unitName]!(x, y);
  }
}

