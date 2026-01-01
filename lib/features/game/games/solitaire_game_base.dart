import 'game_interface.dart';
import '../models/card.dart';
import '../models/pile.dart';
import '../models/move.dart';

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
      return card.rank ==
          Rank.ace; // Most solitaire games start foundations with Aces
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

  // ==========================================================================
  // Default Implementations (GameInterface)
  // ==========================================================================

  /// Handle pile activation (Enter/Space key on focused pile).
  /// Returns a Move if the game handled the activation internally (e.g., stock tap).
  /// Returns null if the controller should use default behavior (select top card).
  /// Default implementation delegates to handlePileTap for stock piles.
  @override
  Move? handlePileActivation(Pile pile) {
    if (pile.type == PileType.stock) {
      return handlePileTap(pile);
    }
    return null;
  }

  /// Get the selectable cards from a pile starting from a given card.
  /// Returns null to use default behavior (all cards from card to top).
  /// Games can override this to enforce selection rules (e.g., waste only allows top card).
  /// Default implementation returns null.
  @override
  List<PlayingCard>? getSelectableCards(Pile pile, PlayingCard card) => null;

  // ==========================================================================
  // Auto-Move Defaults (GameInterface)
  // ==========================================================================

  /// Whether double-tap auto-move is allowed for this card in this pile.
  /// Default: only allow auto-move on top card.
  @override
  bool canAutoMove(Pile pile, PlayingCard card) {
    return pile.topCard == card;
  }

  /// Get cards that would be moved in an auto-move operation.
  /// Default returns the full run from card to top.
  @override
  List<PlayingCard> getAutoMoveCards(Pile pile, PlayingCard card) {
    final cardIndex = pile.indexOfCard(card);
    if (cardIndex < 0) return [card];
    return pile.cards.sublist(cardIndex);
  }

  // ==========================================================================
  // Layout Helpers Defaults (GameInterface)
  // ==========================================================================

  /// Get the suit for a foundation pile (for display purposes).
  /// Default maps foundation index to Suit.values order.
  @override
  Suit? getFoundationSuit(int foundationIndex) {
    if (foundationIndex < 0 || foundationIndex >= foundationPiles.length) {
      return null;
    }
    return Suit.values[foundationIndex % Suit.values.length];
  }

  // ==========================================================================
  // Hint System Defaults (GameInterface)
  // ==========================================================================

  /// Get a stock-related hint (draw or recycle).
  /// Default checks for stock draw or waste recycle.
  @override
  ({Pile source, Pile destination})? getStockHint() {
    final stock = stockPile;
    final waste = wastePile;

    // Suggest recycling waste back to stock
    if (stock != null && stock.isEmpty && waste != null && !waste.isEmpty) {
      return (source: stock, destination: stock);
    }

    // Suggest drawing from stock
    if (stock != null && !stock.isEmpty) {
      return (source: stock, destination: stock);
    }

    return null;
  }

  /// Whether the game supports stock/waste hint suggestions.
  @override
  bool get supportsStockHints => stockPile != null;
}
