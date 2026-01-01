import 'dart:math';
import '../solitaire_game_base.dart';
import '../game_interface.dart';
import '../../models/card.dart';
import '../../models/deck.dart';
import '../../models/pile.dart';
import '../../models/move.dart';
import 'package:solitude/features/settings/models/difficulty.dart';
import 'package:solitude/features/settings/services/settings_provider.dart';
import '../../ai/abstract_solver.dart';
import '../../ai/games/scorpion_solver_state.dart';

/// Scorpion Solitaire implementation.
///
/// Setup: 7 Columns. First 4 cols have 3 face-down cards at bottom.
///        Last 3 cols are all face-up. 3 cards remain in Stock ("Tail").
/// Moves:
///   - Group Move: Like Yukon (move any face-up stack, regardless of sequence).
///   - Target Rule: Build down by Suit (e.g., 7♥ on 8♥).
///   - Stock: Click stock to deal remaining 3 cards to first 3 columns.
/// Win: Build 4 complete suit sequences K-A in tableau (they are removed).
class ScorpionGame extends SolitaireGameBase {
  late Pile stock; // The "tail" - 3 remaining cards
  late List<Pile> tableau;

  final List<Move> _moveHistory = [];
  final List<Move> _redoStack = [];
  int _moveCount = 0;
  int _completedSuits = 0;

  ScorpionGame() {
    _initializePiles();
  }

  void _initializePiles() {
    stock = Pile(type: PileType.stock);
    tableau = List.generate(7, (i) => Pile(type: PileType.tableau, index: i));
  }

  @override
  void initialize({Random? random}) {
    _initializePiles();
    _moveHistory.clear();
    _redoStack.clear();
    _moveCount = 0;
    _completedSuits = 0;

    final deck = Deck();
    deck.shuffle(random ?? Random());

    // Deal 49 cards to tableau (7 columns x 7 cards each)
    // Columns 0-3: First 3 cards face down, rest face up
    // Columns 4-6: All cards face up
    for (int row = 0; row < 7; row++) {
      for (int col = 0; col < 7; col++) {
        final card = deck.draw()!;
        // First 4 columns: first 3 rows are face down
        card.faceUp = col >= 4 || row >= 3;
        tableau[col].addCard(card);
      }
    }

    // Remaining 3 cards go to stock ("tail") - face down
    while (!deck.isEmpty) {
      final card = deck.draw()!;
      card.faceUp = false;
      stock.addCard(card);
    }
  }

  @override
  void reset() {
    initialize();
  }

  @override
  List<Pile> get allPiles => [stock, ...tableau];

  @override
  int get moveCount => _moveCount;

  @override
  List<Move> get moveHistory => List.unmodifiable(_moveHistory);

  @override
  List<Move> get redoStack => List.unmodifiable(_redoStack);

  @override
  bool get canRedo => _redoStack.isNotEmpty;

  @override
  GameType get gameType => GameType.scorpion;

  @override
  int get deckSize => 52;

  @override
  LayoutConfig get layoutConfig => const LayoutConfig(
        tableauCount: 7,
        foundationCount: 0,
        hasStock: true,
        hasWaste: false,
        layoutType: LayoutType.grid,
      );

  // ==========================================================================
  // Pile Accessors (GameInterface)
  // ==========================================================================

  @override
  Pile? get stockPile => stock;

  @override
  Pile? get wastePile => null;

  @override
  List<Pile> get foundationPiles => []; // No separate foundations

  @override
  List<Pile> get tableauPiles => tableau;

  /// Get count of completed suits
  int get completedSuits => _completedSuits;

  // ==========================================================================
  // Move Validation
  // ==========================================================================

  @override
  bool isValidMove(Pile from, Pile to, List<PlayingCard> cards) {
    if (cards.isEmpty) return false;
    if (from == to) return false;

    final movingCard = cards.first;

    // Can't move to stock
    if (to.type == PileType.stock) return false;

    // Tableau moves
    if (to.type == PileType.tableau) {
      // In Scorpion, like Yukon, cards don't need to be in sequence to move
      // Only the top card of the moving stack matters

      if (to.isEmpty) {
        // Only kings can go on empty tableau
        return movingCard.rank == Rank.king;
      }

      // Must be same suit and descending (build down by suit)
      final topCard = to.topCard!;
      return movingCard.suit == topCard.suit &&
          movingCard.value == topCard.value - 1;
    }

    return false;
  }

  @override
  Move? executeMove(Pile from, Pile to, List<PlayingCard> cards) {
    if (!isValidMove(from, to, cards)) return null;

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

    final move = Move(
      fromPile: from,
      toPile: to,
      cards: removed,
      flippedCard: willFlipCard,
    );
    _moveHistory.add(move);
    _redoStack.clear();
    _moveCount++;

    // Check for completed suits
    _checkAndRemoveCompleteSuits();

    return move;
  }

  /// Check for and remove any complete K-A suit sequences
  void _checkAndRemoveCompleteSuits() {
    for (final pile in tableau) {
      if (pile.length < 13) continue;

      // Check if the bottom 13 cards form a complete suit sequence
      final cards = pile.cards;
      final start = cards.length - 13;

      // Must start with King
      if (cards[start].rank != Rank.king) continue;

      // Check for complete descending same-suit sequence
      bool isComplete = true;
      final suit = cards[start].suit;

      for (int i = 0; i < 13; i++) {
        final card = cards[start + i];
        if (card.suit != suit || card.value != 13 - i) {
          isComplete = false;
          break;
        }
      }

      if (isComplete) {
        // Remove the complete suit
        pile.removeFrom(start);
        _completedSuits++;
      }
    }
  }

  @override
  Move? tapStock() {
    if (stock.isEmpty) return null;

    // Deal 3 cards to first 3 columns
    final dealtCards = <PlayingCard>[];
    for (int col = 0; col < 3 && !stock.isEmpty; col++) {
      final card = stock.removeTop()!;
      card.faceUp = true;
      tableau[col].addCard(card);
      dealtCards.add(card);
    }

    final move = Move(
      fromPile: stock,
      toPile: tableau[0], // Primary destination for undo purposes
      cards: dealtCards,
      drewFromStock: true,
      extraData: {'dealToColumns': true},
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
    if (move.drewFromStock && move.extraData?['dealToColumns'] == true) {
      // Remove cards from first 3 columns and put back to stock
      for (int col = 2; col >= 0 && col < move.cards.length; col--) {
        if (col < tableau.length && !tableau[col].isEmpty) {
          final card = tableau[col].removeTop()!;
          card.faceUp = false;
          stock.addCard(card);
        }
      }
      return true;
    }

    // Handle normal move undo
    // If a card was flipped, un-flip it
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
    if (move.drewFromStock && move.extraData?['dealToColumns'] == true) {
      for (int col = 0; col < 3 && !stock.isEmpty; col++) {
        final card = stock.removeTop()!;
        card.faceUp = true;
        tableau[col].addCard(card);
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
    _checkAndRemoveCompleteSuits();
    return true;
  }

  @override
  bool checkWin() {
    // Win when all 4 suits are completed
    return _completedSuits == 4;
  }

  @override
  bool canAutoComplete() {
    // Can auto-complete when all cards are face-up and stock is empty
    if (!stock.isEmpty) return false;
    for (final pile in tableau) {
      for (final card in pile.cards) {
        if (!card.faceUp) return false;
      }
    }
    return true;
  }

  @override
  bool autoCompleteStep() {
    // In Scorpion, we try to build complete suits
    // Look for moves that bring suit sequences together
    for (final fromPile in tableau) {
      if (fromPile.isEmpty) continue;

      for (int i = 0; i < fromPile.cards.length; i++) {
        final card = fromPile.cardAt(i);
        if (card == null || !card.faceUp) continue;

        final cardsToMove = fromPile.cards.sublist(i);

        for (final toPile in tableau) {
          if (toPile == fromPile) continue;
          if (isValidMove(fromPile, toPile, cardsToMove)) {
            executeMove(fromPile, toPile, cardsToMove);
            return true;
          }
        }
      }
    }
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
    return !stock.isEmpty;
  }

  @override
  bool hasValidWasteMoves() {
    return false; // No waste in Scorpion
  }

  @override
  bool hasValidTableauMoves() {
    for (final fromPile in tableau) {
      if (fromPile.isEmpty) continue;

      // In Scorpion, we can move ANY face-up card and all cards above it
      for (int i = 0; i < fromPile.cards.length; i++) {
        final card = fromPile.cardAt(i);
        if (card == null || !card.faceUp) continue;

        final cardsToMove = fromPile.cards.sublist(i);

        for (final toPile in tableau) {
          if (toPile == fromPile) continue;
          if (isValidMove(fromPile, toPile, cardsToMove)) return true;
        }
      }
    }
    return false;
  }

  @override
  bool get isLost {
    // Not lost if we can draw from stock
    if (!stock.isEmpty) return false;
    // Not lost if we have valid moves
    return !hasAnyMove();
  }

  @override
  Pile? findBestAutoMoveDestination(Pile fromPile, List<PlayingCard> cards) {
    if (cards.isEmpty) return null;
    final card = cards.first;

    // Priority 1: Kings to empty tableau
    if (card.rank == Rank.king) {
      for (final t in tableau) {
        if (t.isEmpty && t != fromPile) {
          return t;
        }
      }
    }

    // Priority 2: Valid tableau moves (prefer building suits)
    for (final t in tableau) {
      if (!t.isEmpty && t != fromPile && isValidMove(fromPile, t, cards)) {
        return t;
      }
    }

    return null;
  }

  @override
  ({Pile from, Pile to, List<PlayingCard> cards})? getHint() {
    // Priority 1: Moves that expose face-down cards
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

      // Try moving to non-empty tableau piles first
      for (final toPile in tableau) {
        if (toPile == fromPile) continue;
        if (toPile.isEmpty) continue;
        if (isValidMove(fromPile, toPile, cardsToMove)) {
          return (from: fromPile, to: toPile, cards: cardsToMove);
        }
      }

      // Then try empty piles (only if moving a King)
      if (cardsToMove.first.rank == Rank.king) {
        for (final toPile in tableau) {
          if (toPile == fromPile) continue;
          if (!toPile.isEmpty) continue;
          if (isValidMove(fromPile, toPile, cardsToMove)) {
            return (from: fromPile, to: toPile, cards: cardsToMove);
          }
        }
      }
    }

    // Priority 2: Moves that build suit sequences
    for (final fromPile in tableau) {
      if (fromPile.isEmpty) continue;

      for (int i = 0; i < fromPile.cards.length; i++) {
        final card = fromPile.cardAt(i);
        if (card == null || !card.faceUp) continue;

        final cardsToMove = fromPile.cards.sublist(i);

        for (final toPile in tableau) {
          if (toPile == fromPile) continue;
          if (toPile.isEmpty) continue;
          if (isValidMove(fromPile, toPile, cardsToMove)) {
            return (from: fromPile, to: toPile, cards: cardsToMove);
          }
        }
      }
    }

    // Priority 3: Move Kings to empty columns
    for (final fromPile in tableau) {
      if (fromPile.isEmpty) continue;

      for (int i = 0; i < fromPile.cards.length; i++) {
        final card = fromPile.cardAt(i);
        if (card == null || !card.faceUp) continue;
        if (card.rank != Rank.king) continue;

        // Don't move King if it's already at the bottom
        if (i == 0) continue;

        final cardsToMove = fromPile.cards.sublist(i);

        for (final toPile in tableau) {
          if (toPile == fromPile) continue;
          if (!toPile.isEmpty) continue;
          if (isValidMove(fromPile, toPile, cardsToMove)) {
            return (from: fromPile, to: toPile, cards: cardsToMove);
          }
        }
      }
    }

    // Priority 4: Deal from stock
    if (!stock.isEmpty) {
      return (from: stock, to: tableau[0], cards: []);
    }

    return null;
  }

  @override
  void applyDifficulty(Difficulty difficulty) {
    // Scorpion doesn't have standard difficulty variations
  }

  @override
  void configure(SettingsProvider settings) {
    // Scorpion doesn't have configurable settings
  }

  @override
  SolverState<ScorpionMove>? getSolverState() {
    // Convert card to solver format: "rankSuit" (e.g., "1H" for Ace of Hearts)
    String cardToString(PlayingCard card) {
      return '${card.value}${card.suit.name[0].toUpperCase()}';
    }

    // Convert tableau piles
    final tableauCards = <List<ScorpionCardInfo>>[];
    for (final pile in tableau) {
      tableauCards.add(
        pile.cards
            .map((c) => ScorpionCardInfo(cardToString(c), c.faceUp))
            .toList(),
      );
    }

    // Convert stock (the "tail")
    final stockCards = stock.cards.map(cardToString).toList();

    return ScorpionSolverState(
      tableau: tableauCards,
      stock: stockCards,
      completedSuits: _completedSuits,
    );
  }

  @override
  Pile? getPile(PileType type) {
    switch (type) {
      case PileType.stock:
        return stock;
      default:
        return null;
    }
  }

  @override
  List<Pile> get focusablePiles {
    final piles = <Pile>[];
    if (!stock.isEmpty) piles.add(stock);
    piles.addAll(tableau);
    return piles;
  }

  @override
  Pile? getNextFocus(Pile current) {
    final allFocusable = focusablePiles;
    final index = allFocusable.indexOf(current);
    if (index < 0) return allFocusable.isNotEmpty ? allFocusable[0] : null;
    return allFocusable[(index + 1) % allFocusable.length];
  }

  @override
  Move? handlePileTap(Pile pile) {
    if (pile.type == PileType.stock) {
      return tapStock();
    }
    return null;
  }

  @override
  List<PlayingCard>? getSelectableCards(Pile pile, PlayingCard card) {
    // In Scorpion, can select any face-up card and all cards above it
    if (pile.type == PileType.tableau) {
      final index = pile.indexOfCard(card);
      if (index >= 0 && card.faceUp) {
        return pile.cards.sublist(index);
      }
    }
    return null;
  }

  @override
  bool get supportsStockHints => !stock.isEmpty;

  @override
  ({Pile source, Pile destination})? getStockHint() {
    if (!stock.isEmpty) {
      return (source: stock, destination: stock);
    }
    return null;
  }
}
