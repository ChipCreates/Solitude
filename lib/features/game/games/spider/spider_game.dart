import 'dart:math';
import '../solitaire_game_base.dart';
import '../game_interface.dart';
import '../../models/card.dart';
import '../../models/pile.dart';
import '../../models/move.dart';
import 'package:solitude/features/settings/models/difficulty.dart';
import 'package:solitude/features/settings/services/settings_provider.dart';
import '../../ai/abstract_solver.dart';
import '../../ai/games/spider_solver_state.dart';

/// Spider Solitaire game implementation.
///
/// Rules:
/// - 2 Decks (104 Cards)
/// - 10 Tableau Piles
/// - Stock: Deals 1 card to each of the 10 piles
/// - Moves: Drag sequences of the same suit (Descending)
/// - Victory: Complete 8 full runs (K->A) of one suit, which are removed from the board
class SpiderGame extends SolitaireGameBase {
  late Pile stock;
  late List<Pile> tableau;
  late List<Pile> completedPiles; // Stores completed K->A runs

  final List<Move> _moveHistory = [];
  final List<Move> _redoStack = [];
  int _moveCount = 0;

  /// Number of suits to use (1 = easy, 2 = medium, 4 = hard)
  int numberOfSuits;

  SpiderGame({this.numberOfSuits = 4}) {
    _initializePiles();
  }

  void _initializePiles() {
    stock = Pile(type: PileType.stock);
    tableau = List.generate(10, (i) => Pile(type: PileType.tableau, index: i));
    completedPiles =
        List.generate(8, (i) => Pile(type: PileType.foundation, index: i));
  }

  @override
  void initialize({Random? random}) {
    _initializePiles();
    _moveHistory.clear();
    _redoStack.clear();
    _moveCount = 0;

    // Create 2 decks (104 cards)
    final allCards = <PlayingCard>[];

    // Determine which suits to use based on difficulty
    final suitsToUse = _getSuitsToUse();

    // Create cards for each suit
    for (int deckNum = 0; deckNum < 2; deckNum++) {
      for (final suit in suitsToUse) {
        for (int rankIndex = 0; rankIndex < 13; rankIndex++) {
          allCards.add(PlayingCard(
            suit: suit,
            rank: Rank.values[rankIndex],
            faceUp: false,
          ));
        }
      }
    }

    // Ensure we have 104 cards by repeating suits if necessary
    while (allCards.length < 104) {
      final suit = suitsToUse[allCards.length % suitsToUse.length];
      final rankIndex = allCards.length ~/ suitsToUse.length % 13;
      allCards.add(PlayingCard(
        suit: suit,
        rank: Rank.values[rankIndex],
        faceUp: false,
      ));
    }

    // Shuffle the cards
    final rng = random ?? Random();
    allCards.shuffle(rng);

    // Deal cards to tableau:
    // - First 4 piles get 6 cards each (24 cards)
    // - Last 6 piles get 5 cards each (30 cards)
    // - Total dealt: 54 cards
    // - Remaining in stock: 50 cards (5 deals of 10 cards each)
    int cardIndex = 0;

    for (int pileIndex = 0; pileIndex < 10; pileIndex++) {
      final cardCount = pileIndex < 4 ? 6 : 5;
      for (int j = 0; j < cardCount; j++) {
        final card = allCards[cardIndex++];
        // Only the top card of each pile is face up
        card.faceUp = (j == cardCount - 1);
        tableau[pileIndex].addCard(card);
      }
    }

    // Remaining cards go to stock (face down)
    while (cardIndex < allCards.length) {
      final card = allCards[cardIndex++];
      card.faceUp = false;
      stock.addCard(card);
    }
  }

  /// Get the suits to use based on numberOfSuits setting
  List<Suit> _getSuitsToUse() {
    switch (numberOfSuits) {
      case 1:
        // Easy: Only Spades (8 copies of one suit)
        return [Suit.spades];
      case 2:
        // Medium: Spades and Hearts (4 copies of each)
        return [Suit.spades, Suit.hearts];
      case 4:
      default:
        // Hard: All 4 suits (2 copies of each)
        return [Suit.spades, Suit.hearts, Suit.diamonds, Suit.clubs];
    }
  }

  @override
  void reset() {
    initialize();
  }

  @override
  List<Pile> get allPiles => [stock, ...tableau, ...completedPiles];

  @override
  int get moveCount => _moveCount;

  @override
  List<Move> get moveHistory => List.unmodifiable(_moveHistory);

  @override
  List<Move> get redoStack => List.unmodifiable(_redoStack);

  @override
  bool get canRedo => _redoStack.isNotEmpty;

  @override
  GameType get gameType => GameType.spider;

  @override
  int get deckSize => 104; // 2 decks

  @override
  LayoutConfig get layoutConfig => const LayoutConfig(
        tableauCount: 10,
        foundationCount: 8,
        hasStock: true,
        hasWaste: false,
        layoutType: LayoutType.grid,
      );

  // ==========================================================================
  // Layout Helpers
  // ==========================================================================

  /// Spider foundations are not suit-specific - any complete sequence goes there.
  /// Returns null to indicate no specific suit for the foundation.
  @override
  Suit? getFoundationSuit(int foundationIndex) => null;

  // ==========================================================================
  // Hint System
  // ==========================================================================

  /// Spider doesn't have waste pile, so stock hints only suggest drawing.
  @override
  ({Pile source, Pile destination})? getStockHint() {
    if (!stock.isEmpty && canDrawFromStock()) {
      return (source: stock, destination: stock);
    }
    return null;
  }

  // ==========================================================================
  // Pile Accessors (GameInterface)
  // ==========================================================================

  @override
  Pile? get stockPile => stock;

  @override
  Pile? get wastePile => null; // Spider doesn't have a waste pile

  @override
  List<Pile> get foundationPiles => completedPiles;

  @override
  List<Pile> get tableauPiles => tableau;

  // ==========================================================================
  // Loss Detection (GameInterface)
  // ==========================================================================

  @override
  bool get isLost => !hasAnyMove();

  // ==========================================================================
  // Configuration (GameInterface)
  // ==========================================================================

  @override
  void applyDifficulty(Difficulty difficulty) {
    // Map difficulty to number of suits
    switch (difficulty) {
      case Difficulty.easy:
        numberOfSuits = 1;
        break;
      case Difficulty.medium:
        numberOfSuits = 2;
        break;
      case Difficulty.hard:
        numberOfSuits = 4;
        break;
    }
  }

  @override
  void configure(SettingsProvider settings) {
    // Spider doesn't use draw mode or scoring mode differently
    // but could be extended for other settings
  }

  @override
  SpiderSolverState? getSolverState() {
    // Convert card to solver format
    String cardToString(PlayingCard card) {
      return '${card.value}${card.suit.name[0].toUpperCase()}';
    }

    // Convert tableau piles
    final solverTableau = tableau.map((pile) {
      return pile.cards
          .map((card) => SpiderCard(cardToString(card), faceUp: card.faceUp))
          .toList();
    }).toList();

    // Calculate stock deals remaining (each deal is 10 cards)
    final stockDeals = stock.length ~/ 10;

    // Count completed sequences
    final completed = completedPiles.where((p) => !p.isEmpty).length;

    return SpiderSolverState(
      tableau: solverTableau,
      stockDeals: stockDeals,
      completedSequences: completed,
    );
  }

  // ==========================================================================
  // Auto-Move (GameInterface)
  // ==========================================================================

  @override
  Pile? findBestAutoMoveDestination(Pile fromPile, List<PlayingCard> cards) {
    if (cards.isEmpty) return null;
    final card = cards.first;

    // In Spider, prefer moves that build same-suit sequences
    // First, try to find a tableau pile with matching suit
    for (final pile in tableau) {
      if (pile == fromPile) continue;
      if (pile.isEmpty) continue;

      final topCard = pile.topCard!;
      // Same suit and descending is preferred
      if (card.suit == topCard.suit && card.value == topCard.value - 1) {
        return pile;
      }
    }

    // Then try any valid descending move (different suit)
    for (final pile in tableau) {
      if (pile == fromPile) continue;
      if (pile.isEmpty) continue;

      final topCard = pile.topCard!;
      if (card.value == topCard.value - 1) {
        return pile;
      }
    }

    // Finally, try empty piles
    for (final pile in tableau) {
      if (pile == fromPile) continue;
      if (pile.isEmpty) {
        return pile;
      }
    }

    return null;
  }

  @override
  bool isValidMove(Pile from, Pile to, List<PlayingCard> cards) {
    if (cards.isEmpty) return false;

    // Can't move to stock or completed piles directly
    if (to.type == PileType.stock) return false;
    if (to.type == PileType.foundation) return false;

    // Cards must form a valid same-suit descending sequence
    if (!_isValidSameSuitSequence(cards)) return false;

    // Tableau moves
    if (to.type == PileType.tableau) {
      if (to.isEmpty) {
        // Any valid sequence can go to empty pile
        return true;
      }

      // Must be descending (any suit can stack, but only same-suit sequences can be moved)
      final topCard = to.topCard!;
      final movingCard = cards.first;
      return movingCard.value == topCard.value - 1;
    }

    return false;
  }

  /// Check if cards form a valid same-suit descending sequence
  bool _isValidSameSuitSequence(List<PlayingCard> cards) {
    if (cards.length <= 1) return true;

    for (int i = 1; i < cards.length; i++) {
      final prev = cards[i - 1];
      final curr = cards[i];

      // Must be same suit
      if (curr.suit != prev.suit) return false;

      // Must be descending
      if (curr.value != prev.value - 1) return false;
    }

    return true;
  }

  @override
  Move? executeMove(Pile from, Pile to, List<PlayingCard> cards) {
    if (!isValidMove(from, to, cards)) return null;

    // Find index of first card being moved
    final startIndex = from.indexOfCard(cards.first);
    if (startIndex == -1) return null;

    // Check if we'll need to flip a card after this move
    bool willFlipCard = false;
    if (from.type == PileType.tableau && startIndex > 0) {
      final cardBelow = from.cardAt(startIndex - 1);
      if (cardBelow != null && !cardBelow.faceUp) {
        willFlipCard = true;
      }
    }

    // Remove cards from source
    final removed = from.removeFrom(startIndex);

    // Add to destination
    to.addCards(removed);

    // Flip the newly exposed card if needed
    if (willFlipCard) {
      from.flipTopCard();
    }

    // Record move
    final move = Move(
      fromPile: from,
      toPile: to,
      cards: removed,
      flippedCard: willFlipCard,
    );
    _moveHistory.add(move);
    _redoStack.clear();
    _moveCount++;

    // Check for completed sequences
    _checkAndRemoveCompletedSequence(to);

    return move;
  }

  /// Check if a pile has a complete K->A same-suit sequence and remove it
  void _checkAndRemoveCompletedSequence(Pile pile) {
    if (pile.length < 13) return;

    // Check if the bottom 13 cards form a K->A same-suit sequence
    final startIndex = pile.length - 13;
    final potentialSequence = pile.cards.sublist(startIndex);

    // Must start with King and end with Ace
    if (potentialSequence.first.rank != Rank.king) return;
    if (potentialSequence.last.rank != Rank.ace) return;

    // Check if it's a valid same-suit descending sequence
    if (!_isValidSameSuitSequence(potentialSequence)) return;

    // All cards must be face up
    if (!potentialSequence.every((card) => card.faceUp)) return;

    // Find an empty completed pile
    for (final completed in completedPiles) {
      if (completed.isEmpty) {
        // Remove the sequence from tableau
        final removed = pile.removeFrom(startIndex);

        // Add to completed pile
        completed.addCards(removed);

        // Flip the new top card if needed
        if (!pile.isEmpty && pile.topCard != null && !pile.topCard!.faceUp) {
          pile.flipTopCard();
        }

        break;
      }
    }
  }

  @override
  Move? tapStock() {
    // In Spider, tapping stock deals one card to each tableau pile
    if (stock.isEmpty) return null;

    // Must have at least 10 cards in stock and no empty tableau piles
    for (final pile in tableau) {
      if (pile.isEmpty) {
        // Can't deal if any tableau pile is empty
        return null;
      }
    }

    // Deal one card to each of the 10 tableau piles
    final dealtCards = <PlayingCard>[];

    for (int i = 0; i < 10 && !stock.isEmpty; i++) {
      final card = stock.removeTop()!;
      card.faceUp = true;
      tableau[i].addCard(card);
      dealtCards.add(card);

      // Check for completed sequences after each card is dealt
      _checkAndRemoveCompletedSequence(tableau[i]);
    }

    final move = Move(
      fromPile: stock,
      toPile: tableau.first, // Reference first pile for the move
      cards: dealtCards,
      drewFromStock: true,
    );
    _moveHistory.add(move);
    _redoStack.clear();
    _moveCount++;

    return move;
  }

  @override
  bool undo() {
    if (_moveHistory.isEmpty) return false;

    final move = _moveHistory.removeLast();
    _redoStack.add(move);
    _moveCount--;

    // Handle stock deal undo
    if (move.drewFromStock) {
      // Remove the dealt cards from each tableau pile
      for (int i = move.cards.length - 1; i >= 0; i--) {
        if (i < tableau.length) {
          final card = tableau[i].removeTop();
          if (card != null) {
            card.faceUp = false;
            stock.addCard(card);
          }
        }
      }
      return true;
    }

    // Handle completed sequence undo (not implemented - would need to track)

    // Handle normal move undo
    if (move.flippedCard && move.fromPile.topCard != null) {
      move.fromPile.topCard!.faceUp = false;
    }

    // Move cards back
    for (final card in move.cards) {
      move.toPile.removeTop();
      move.fromPile.addCard(card);
    }

    return true;
  }

  @override
  bool redo() {
    if (_redoStack.isEmpty) return false;

    final move = _redoStack.removeLast();
    _moveCount++;

    // Handle stock deal redo
    if (move.drewFromStock) {
      for (int i = 0; i < move.cards.length && i < tableau.length; i++) {
        final card = stock.removeTop();
        if (card != null) {
          card.faceUp = true;
          tableau[i].addCard(card);
        }
      }
      _moveHistory.add(move);
      return true;
    }

    // Handle normal move redo
    final startIndex = move.fromPile.indexOfCard(move.cards.first);
    if (startIndex == -1) return false;

    final removed = move.fromPile.removeFrom(startIndex);
    move.toPile.addCards(removed);

    if (move.flippedCard && move.fromPile.topCard != null) {
      move.fromPile.flipTopCard();
    }

    _moveHistory.add(move);
    return true;
  }

  @override
  bool checkWin() {
    // Win when all 8 completed piles have cards (8 full K->A sequences)
    return completedPiles.every((pile) => !pile.isEmpty);
  }

  @override
  bool canAutoComplete() {
    // Auto-complete not available for Spider
    return false;
  }

  @override
  bool autoCompleteStep() {
    // Auto-complete not available for Spider
    return false;
  }

  @override
  List<Pile> getValidDestinations(Pile from, List<PlayingCard> cards) {
    final destinations = <Pile>[];

    for (final pile in tableau) {
      if (pile != from && isValidMove(from, pile, cards)) {
        destinations.add(pile);
      }
    }

    return destinations;
  }

  @override
  bool canDrawFromStock() {
    if (stock.isEmpty) return false;
    // Can only draw if no tableau pile is empty
    return tableau.every((pile) => !pile.isEmpty);
  }

  @override
  bool hasValidWasteMoves() {
    // Spider doesn't have a waste pile
    return false;
  }

  @override
  bool hasValidTableauMoves() {
    for (final fromPile in tableau) {
      if (fromPile.isEmpty) continue;

      // Check each possible face-up sequence
      for (int i = fromPile.cards.length - 1; i >= 0; i--) {
        final card = fromPile.cardAt(i);
        if (card == null || !card.faceUp) break;

        final cardsToMove = fromPile.cards.sublist(i);

        // Check if this forms a valid moveable sequence
        if (!_isValidSameSuitSequence(cardsToMove)) break;

        // Try moving to other tableau piles
        for (final toPile in tableau) {
          if (toPile == fromPile) continue;
          if (isValidMove(fromPile, toPile, cardsToMove)) return true;
        }
      }
    }
    return false;
  }

  @override
  ({Pile from, Pile to, List<PlayingCard> cards})? getHint() {
    // Priority 1: Complete a sequence (K->A same suit) if possible
    for (final pile in tableau) {
      if (pile.length >= 13) {
        // Check if we're close to completing a sequence
        final topCards =
            pile.cards.sublist(pile.length - 13 > 0 ? pile.length - 13 : 0);
        if (_isValidSameSuitSequence(topCards) &&
            topCards.isNotEmpty &&
            topCards.first.rank == Rank.king) {
          // This pile might complete soon - hint to build on it
        }
      }
    }

    // Priority 2: Build same-suit sequences
    for (final fromPile in tableau) {
      if (fromPile.isEmpty) continue;

      for (int i = fromPile.cards.length - 1; i >= 0; i--) {
        final card = fromPile.cardAt(i);
        if (card == null || !card.faceUp) break;

        final cardsToMove = fromPile.cards.sublist(i);
        if (!_isValidSameSuitSequence(cardsToMove)) break;

        // Try to find same-suit destination
        for (final toPile in tableau) {
          if (toPile == fromPile) continue;
          if (toPile.isEmpty) continue;

          final topCard = toPile.topCard!;
          if (cardsToMove.first.suit == topCard.suit &&
              cardsToMove.first.value == topCard.value - 1) {
            return (from: fromPile, to: toPile, cards: cardsToMove);
          }
        }
      }
    }

    // Priority 3: Expose face-down cards
    for (final fromPile in tableau) {
      if (fromPile.isEmpty) continue;

      // Find the first face-up card
      int firstFaceUp = -1;
      for (int i = 0; i < fromPile.cards.length; i++) {
        if (fromPile.cards[i].faceUp) {
          firstFaceUp = i;
          break;
        }
      }

      // Only interested if there's a face-down card to expose
      if (firstFaceUp <= 0) continue;

      final cardsToMove = fromPile.cards.sublist(firstFaceUp);
      if (!_isValidSameSuitSequence(cardsToMove)) continue;

      for (final toPile in tableau) {
        if (toPile == fromPile) continue;
        if (isValidMove(fromPile, toPile, cardsToMove)) {
          return (from: fromPile, to: toPile, cards: cardsToMove);
        }
      }
    }

    // Priority 4: Any valid move
    for (final fromPile in tableau) {
      if (fromPile.isEmpty) continue;

      for (int i = fromPile.cards.length - 1; i >= 0; i--) {
        final card = fromPile.cardAt(i);
        if (card == null || !card.faceUp) break;

        final cardsToMove = fromPile.cards.sublist(i);
        if (!_isValidSameSuitSequence(cardsToMove)) break;

        for (final toPile in tableau) {
          if (toPile == fromPile) continue;
          if (isValidMove(fromPile, toPile, cardsToMove)) {
            return (from: fromPile, to: toPile, cards: cardsToMove);
          }
        }
      }
    }

    // No moves found - suggest drawing from stock if possible
    return null;
  }

  @override
  Pile? getPile(PileType type) {
    switch (type) {
      case PileType.stock:
        return stockPile;
      case PileType.waste:
        return null;
      default:
        return null;
    }
  }

  @override
  List<Pile> get focusablePiles {
    final piles = <Pile>[];
    piles.add(stock);
    piles.addAll(tableau);
    return piles;
  }

  @override
  Pile? getNextFocus(Pile current) {
    if (current == stock) {
      return tableau.isNotEmpty ? tableau[0] : null;
    } else if (current.type == PileType.tableau) {
      final index = tableau.indexOf(current);
      if (index >= 0 && index < tableau.length - 1) {
        return tableau[index + 1];
      } else {
        return stock;
      }
    }
    return null;
  }

  @override
  Move? handlePileTap(Pile pile) {
    if (pile.type == PileType.stock) {
      return tapStock();
    }
    return null;
  }
}
