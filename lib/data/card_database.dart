import '../models/card_model.dart';

class CardDatabase {
  // Master pool containing all available cards
  static final List<CardModel> masterCardPool = [
    CardModel(
      id: 'basic_attack_001',
      set: 'basic',
      type: 'attack',
      cardClass: 'neutral',
      effect: 'attack once',
      title: 'Basic Attack',
      description: 'attack once',
      flavourText: 'endless possibilities at the palm of your hand',
    ),
  ];

  // Get initial player card pool (3 copies of basic attack)
  static List<CardModel> getInitialPlayerCardPool() {
    final basicAttack = masterCardPool.first;
    return [
      basicAttack.copyWith(id: 'player_basic_attack_001'),
      basicAttack.copyWith(id: 'player_basic_attack_002'),
      basicAttack.copyWith(id: 'player_basic_attack_003'),
    ];
  }
}
