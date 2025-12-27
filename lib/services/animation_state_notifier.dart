import 'package:flutter/material.dart';
import '../models/card.dart';
import '../widgets/animated_card_overlay.dart';

/// Manages animation state separately from game logic
/// to prevent unnecessary rebuilds of the entire game board
class AnimationStateNotifier extends ChangeNotifier {
  CardAnimationData? _cardAnimationData;
  PlayingCard? _animatingCard;

  CardAnimationData? get cardAnimationData => _cardAnimationData;
  PlayingCard? get animatingCard => _animatingCard;

  void startCardAnimation({
    required PlayingCard card,
    required Offset startPosition,
    required Offset endPosition,
    required double cardWidth,
  }) {
    _animatingCard = card;
    _cardAnimationData = CardAnimationData(
      card: card,
      startPosition: startPosition,
      endPosition: endPosition,
      cardWidth: cardWidth,
    );
    notifyListeners();
  }

  void clearCardAnimation() {
    _animatingCard = null;
    _cardAnimationData = null;
    notifyListeners();
  }

  bool isCardAnimating(PlayingCard card) {
    return _animatingCard == card;
  }
}
