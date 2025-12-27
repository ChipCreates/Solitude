import 'game_interface.dart';
import '../models/card.dart';
import '../models/pile.dart';

/// Base class for solitaire games that provides common move-checking logic.
/// Subclasses implement game-specific rules while inheriting reusable patterns.
abstract class SolitaireGameBase implements GameInterface {
  // ==========================================================================
  // Common hasAnyMove() Implementation
  // ==========================================================================

  @override
  bool hasAnyMove() {
    // Early exits for performance - check most common moves first
    if (canDrawFromStock()) return true;
    if (hasValidWasteMoves()) return true;
    if (hasValidTableauMoves()) return true;
    return false;
  }

  // ==========================================================================
  // Abstract Methods for Game-Specific Logic
  // ==========================================================================

  /// Check if drawing from stock is possible
  bool canDrawFromStock();

  /// Check if the waste pile has any valid moves
  bool hasValidWasteMoves();

  /// Check if tableau piles have any valid moves
  bool hasValidTableauMoves();

  // ==========================================================================
  // Common Helper Methods (Optional Overrides)
  // ==========================================================================

  /// Check if a card can be placed on a foundation pile
  bool canMoveToFoundation(PlayingCard card, Pile foundation) {
    if (foundation.isEmpty) {
      return card.rank == Rank.ace; // Most solitaire games start foundations with Aces
    }
    final topCard = foundation.topCard!;
    return card.suit == topCard.suit && card.value == topCard.value + 1;
  }

  /// Check if cards can be moved to a tableau pile (basic alternating color rule)
  bool canMoveToTableau(List<PlayingCard> cards, Pile toPile) {
    if (cards.isEmpty) return false;
    final firstCard = cards.first;

    if (toPile.isEmpty) {
      return firstCard.rank == Rank.king; // Kings can go on empty tableau
    }

    final topCard = toPile.topCard!;
    // Alternating colors, descending rank
    return firstCard.isRed != topCard.isRed &&
           firstCard.value == topCard.value - 1;
  }

  /// Check if a sequence of cards forms a valid run (for tableau moves)
  bool isValidRun(List<PlayingCard> cards) {
    if (cards.length <= 1) return true;
    for (int i = 1; i < cards.length; i++) {
      final prev = cards[i - 1];
      final curr = cards[i];
      if (curr.isRed == prev.isRed || curr.value != prev.value - 1) {
        return false;
      }
    }
    return true;
  }
}