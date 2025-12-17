class CardModel {
  final String id;
  final String set;
  final String type;
  final String cardClass;
  final String effect;
  final String title;
  final String description;
  final String flavourText;
  final int energyCost;

  CardModel({
    required this.id,
    this.set = 'basic', //basic set, or expansion set
    this.type = 'attack', //attack, support, etc.
    this.cardClass =
        'neutral', //to which class the card belongs (neutral, manipulator, healer.)
    this.effect = 'attack once',
    this.title = 'Basic Attack',
    this.description = 'Attack once',
    this.flavourText = 'endless possibilities at the palm of your hand',
    this.energyCost = 1,
  });

  // Create a copy of this card with a new ID
  CardModel copyWith({String? id, int? energyCost}) {
    return CardModel(
      id: id ?? this.id,
      set: set,
      type: type,
      cardClass: cardClass,
      effect: effect,
      title: title,
      description: description,
      flavourText: flavourText,
      energyCost: energyCost ?? this.energyCost,
    );
  }
}
