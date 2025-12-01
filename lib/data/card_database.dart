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
      description: 'Attack once',
      flavourText: 'endless possibilities at the palm of your hand',
    ),
    CardModel(
      id: 'basic_move',
      set: 'basic',
      type: 'move',
      cardClass: 'neutral',
      effect: 'move once',
      title: 'Basic Move',
      description: 'Move once',
      flavourText: 'endless possibilities at the palm of your hand',
    ),
    CardModel(
      id: 'basic_defend',
      set: 'basic',
      type: 'defend',
      cardClass: 'neutral',
      effect: 'defend once',
      title: 'Basic Defend',
      description: 'Defend once',
      flavourText: 'endless possibilities at the palm of your hand',
    ),
  ];

  // Get initial player card pool (one copy of each card from master pool)
  static List<CardModel> getInitialPlayerCardPool() {
    return masterCardPool.asMap().entries.map((entry) {
      final index = entry.key;
      final card = entry.value;
      return card.copyWith(id: 'player_${card.id}_${index + 1}');
    }).toList();
  }
}
