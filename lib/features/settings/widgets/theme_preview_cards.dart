import 'package:flutter/material.dart';
import 'package:solitude/features/game/models/card.dart';
import '../models/theme_preset.dart';
import 'package:solitude/features/game/widgets/card_widget.dart';

/// Displays a preview of three cards to demonstrate theme and overlay appearance
class ThemePreviewCards extends StatelessWidget {
  final ThemePreset theme;
  final double? overlayIntensity;
  final double cardWidth;

  const ThemePreviewCards({
    super.key,
    required this.theme,
    this.overlayIntensity,
    this.cardWidth = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Red card (Hearts Ace)
        SizedBox(
          width: cardWidth,
          child: CardWidget(
            card: PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true),
            width: cardWidth,
          ),
        ),
        const SizedBox(width: 8),
        // Black card (Spades King)
        SizedBox(
          width: cardWidth,
          child: CardWidget(
            card: PlayingCard(suit: Suit.spades, rank: Rank.king, faceUp: true),
            width: cardWidth,
          ),
        ),
        const SizedBox(width: 8),
        // Card back
        SizedBox(
          width: cardWidth,
          child: CardWidget(
            card: PlayingCard(suit: Suit.clubs, rank: Rank.two, faceUp: false),
            width: cardWidth,
          ),
        ),
      ],
    );
  }
}
