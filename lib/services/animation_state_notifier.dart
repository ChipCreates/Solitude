import 'package:flutter/material.dart';
import '../models/card.dart';
import '../models/pile.dart';
import '../widgets/animated_card_overlay.dart';

/// Manages animation state separately from game logic
/// to prevent unnecessary rebuilds of the entire game board
class AnimationStateNotifier extends ChangeNotifier {
  CardAnimationData? _cardAnimationData;
  PlayingCard? _animatingCard;
  PlayingCard? _originalAnimatingCard;

  CardAnimationData? get cardAnimationData => _cardAnimationData;
  PlayingCard? get animatingCard => _animatingCard;

  void startCardAnimation({
    required PlayingCard card,
    required Offset startPosition,
    required Offset endPosition,
    required double cardWidth,
    Pile? fromPile,
    PlayingCard? animationCard,
  }) {
    _originalAnimatingCard = card;
    _animatingCard = animationCard ?? card;
    _cardAnimationData = CardAnimationData(
      card: _animatingCard!,
      startPosition: startPosition,
      endPosition: endPosition,
      cardWidth: cardWidth,
      fromPile: fromPile,
    );
    notifyListeners();
  }

  /// Triggers the 3D flip animation mid-flight by swapping the card instance
  /// with a Face-Up copy.
  void flipAnimatingCard() {
    if (_cardAnimationData != null && _animatingCard != null) {
      // Create a copy of the card with faceUp = true
      final flippedCard = _animatingCard!.copyWith(faceUp: true);
      _animatingCard = flippedCard;

      // Update the data object to point to the new flipped card instance
      _cardAnimationData = CardAnimationData(
        card: flippedCard,
        startPosition: _cardAnimationData!.startPosition,
        endPosition: _cardAnimationData!.endPosition,
        cardWidth: _cardAnimationData!.cardWidth,
        fromPile: _cardAnimationData!.fromPile,
      );

      notifyListeners();
    }
  }

  void clearCardAnimation() {
    _animatingCard = null;
    _originalAnimatingCard = null;
    _cardAnimationData = null;
    notifyListeners();
  }

  bool isCardAnimating(PlayingCard card) {
    return _originalAnimatingCard == card;
  }
}