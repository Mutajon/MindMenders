import 'package:flutter/material.dart';
import '../game.dart';
import '../components/deck_component.dart';

class DeckInfoOverlay extends StatelessWidget {
  final DeckType? hoveredDeckType;
  final MyGame game;

  const DeckInfoOverlay({
    super.key,
    required this.hoveredDeckType,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    if (hoveredDeckType == null) return const SizedBox.shrink();

    String title;
    String countText;
    
    if (hoveredDeckType == DeckType.draw) {
      title = 'Draw Deck';
      countText = 'Cards Remaining: ${game.deck.length}';
    } else {
      title = 'Discard Pile';
      countText = 'Cards: ${game.discardPile.length}';
    }

    return Positioned(
      bottom: 120, // Above the deck
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              countText,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
