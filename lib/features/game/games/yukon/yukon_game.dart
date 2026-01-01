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
import '../../ai/games/yukon_solver_state.dart';

/// Yukon Solitaire implementation.
///
/// Setup: 7 Columns (like Klondike but all cards dealt, specific face-up logic). No Stock.
/// Moves:
///   - Group Move: Can move any face-up stack, regardless of sequence.
///   - Target Rule: Build down by Alternating Color.
/// Win: All cards to foundations.
class YukonGame extends SolitaireGameBase {
  late List<Pile> foundations;
  late List<Pile> tableau;

  final List<Move> _moveHistory = [];
  final List<Move> _redoStack = [];
  int _moveCount = 0;

  YukonGame() {
    _initializePiles();
  }

  void _initializePiles() {
    foundations =
        List.generate(4, (i) => Pile(type: PileType.foundation, index: i));
    tableau = List.generate(7, (i) => Pile(type: PileType.tableau, index: i));
  }

  @override
  void initialize({Random? random}) {
    _initializePiles();
    _moveHistory.clear();
    _redoStack.clear();
    _moveCount = 0;

    final deck = Deck();
    deck.shuffle(random ?? Random());

    // Yukon layout:
    // Column 1: 1 card (face up)
    // Columns 2-7: i cards (bottom i-1 face down, top face up) + 4 extra face-up cards

    // First, deal like Klondike (1 to 7 cards per column)
    for (int i = 0; i < 7; i++) {
      for (int j = i; j < 7; j++) {
        final card = deck.draw()!;
        card.faceUp = (j == i); // Only top card face up initially
        tableau[j].addCard(card);
      }
    }

    // Then deal 4 extra face-up cards to columns 2-7 (indices 1-6)
    for (int col = 1; col < 7; col++) {
      for (int extra = 0; extra < 4; extra++) {
        final card = deck.draw()!;
        card.faceUp = true;
        tableau[col].addCard(card);
      }
    }

    // All 52 cards should now be dealt (1 + 2+4 + 3+4 + 4+4 + 5+4 + 6+4 + 7+4 = 1+6+7+8+9+10+11 = 52)
  }

  @override
  void reset() {
    initialize();
  }

  @override
  List<Pile> get allPiles => [...foundations, ...tableau];

  @override
  int get moveCount => _moveCount;

  @override
  List<Move> get moveHistory => List.unmodifiable(_moveHistory);

  @override
  List<Move> get redoStack => List.unmodifiable(_redoStack);

  @override
  bool get canRedo => _redoStack.isNotEmpty;

  @override
  GameType get gameType => GameType.yukon;

  @override
  int get deckSize => 52;

  @override
  LayoutConfig get layoutConfig => const LayoutConfig(
        tableauCount: 7,
        foundationCount: 4,
        hasStock: false,
        hasWaste: false,
        layoutType: LayoutType.grid,
      );

  // ==========================================================================
  // Pile Accessors (GameInterface)
  // ==========================================================================

  @override
  Pile? get stockPile => null;

  @override
  Pile? get wastePile => null;

  @override
  List<Pile> get foundationPiles => foundations;

  @override
  List<Pile> get tableauPiles => tableau;

  // ==========================================================================
  // Move Validation
  // ==========================================================================

  @override
  bool isValidMove(Pile from, Pile to, List<PlayingCard> cards) {
    if (cards.isEmpty) return false;
    if (from == to) return false;

    final movingCard = cards.first;

    // Foundation moves
    if (to.type == PileType.foundation) {
      // Only single cards to foundation
      if (cards.length > 1) return false;
      return movingCard.canStackOnFoundation(to.topCard);
    }

    // Tableau moves
    if (to.type == PileType.tableau) {
      // In Yukon, the cards being moved don't need to be in sequence
      // Only the top card of the moving stack needs to match the destination

      if (to.isEmpty) {
        // Only kings can go on empty tableau
        return movingCard.rank == Rank.king;
      }

      // Must be alternating colors and descending (only check the connection point)
      return movingCard.canStackOn(to.topCard!,
          alternatingColors: true, descending: true);
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

    return move;
  }

  @override
  Move? tapStock() {
    // Yukon has no stock
    return null;
  }

  @override
  bool undo() {
    if (_moveHistory.isEmpty) return false;

    final move = _moveHistory.removeLast();
    _redoStack.add(move);
    _moveCount--;

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
    // Win when all foundations have 13 cards
    return foundations.every((f) => f.length == 13);
  }

  @override
  bool canAutoComplete() {
    // Can auto-complete when all face-down cards are revealed
    for (final pile in tableau) {
      for (final card in pile.cards) {
        if (!card.faceUp) return false;
      }
    }
    return true;
  }

  @override
  bool autoCompleteStep() {
    // Try to move cards to foundations
    for (final pile in tableau) {
      if (pile.isEmpty) continue;
      final card = pile.topCard!;
      for (final foundation in foundations) {
        if (card.canStackOnFoundation(foundation.topCard)) {
          executeMove(pile, foundation, [card]);
          return true;
        }
      }
    }
    return false;
  }

  @override
  List<Pile> getValidDestinations(Pile from, List<PlayingCard> cards) {
    final destinations = <Pile>[];

    for (final foundation in foundations) {
      if (isValidMove(from, foundation, cards)) {
        destinations.add(foundation);
      }
    }

    for (final pile in tableau) {
      if (pile != from && isValidMove(from, pile, cards)) {
        destinations.add(pile);
      }
    }

    return destinations;
  }

  @override
  bool canDrawFromStock() {
    return false; // No stock in Yukon
  }

  @override
  bool hasValidWasteMoves() {
    return false; // No waste in Yukon
  }

  @override
  bool hasValidTableauMoves() {
    for (final fromPile in tableau) {
      if (fromPile.isEmpty) continue;

      // In Yukon, we can move ANY face-up card and all cards above it
      for (int i = 0; i < fromPile.cards.length; i++) {
        final card = fromPile.cardAt(i);
        if (card == null || !card.faceUp) continue;

        final cardsToMove = fromPile.cards.sublist(i);

        // Check foundation (single card only)
        if (cardsToMove.length == 1) {
          for (final foundation in foundations) {
            if (cardsToMove.first.canStackOnFoundation(foundation.topCard)) {
              return true;
            }
          }
        }

        // Check tableau
        for (final toPile in tableau) {
          if (toPile == fromPile) continue;
          if (isValidMove(fromPile, toPile, cardsToMove)) return true;
        }
      }
    }
    return false;
  }

  @override
  bool get isLost => !hasAnyMove();

  @override
  Pile? findBestAutoMoveDestination(Pile fromPile, List<PlayingCard> cards) {
    if (cards.isEmpty) return null;
    final card = cards.first;

    // Priority 1: Aces go to empty foundations
    if (card.rank == Rank.ace && cards.length == 1) {
      for (final foundation in foundations) {
        if (foundation.isEmpty && isValidMove(fromPile, foundation, [card])) {
          return foundation;
        }
      }
    }

    // Priority 2: Cards that can stack on foundations (single cards only)
    if (cards.length == 1) {
      for (final foundation in foundations) {
        if (isValidMove(fromPile, foundation, [card])) {
          return foundation;
        }
      }
    }

    // Priority 3: Kings to empty tableau
    if (card.rank == Rank.king) {
      for (final t in tableau) {
        if (t.isEmpty && t != fromPile && isValidMove(fromPile, t, cards)) {
          return t;
        }
      }
    }

    // Priority 4: Any valid tableau (prefer non-empty)
    for (final t in tableau) {
      if (!t.isEmpty && t != fromPile && isValidMove(fromPile, t, cards)) {
        return t;
      }
    }

    return null;
  }

  @override
  ({Pile from, Pile to, List<PlayingCard> cards})? getHint() {
    // Priority 1: Move cards to foundations
    for (final pile in tableau) {
      if (pile.isEmpty) continue;
      final card = pile.topCard!;
      for (final foundation in foundations) {
        if (card.canStackOnFoundation(foundation.topCard)) {
          return (from: pile, to: foundation, cards: [card]);
        }
      }
    }

    // Priority 2: Moves that expose face-down cards
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

    // Priority 3: General tableau building moves
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

    return null;
  }

  @override
  void applyDifficulty(Difficulty difficulty) {
    // Yukon doesn't have difficulty variations
  }

  @override
  void configure(SettingsProvider settings) {
    // Yukon doesn't have configurable settings
  }

  @override
  SolverState<YukonMove>? getSolverState() {
    // Convert card to solver format: "rankSuit" (e.g., "1H" for Ace of Hearts)
    String cardToString(PlayingCard card) {
      return '${card.value}${card.suit.name[0].toUpperCase()}';
    }

    // Get suit index for foundation
    int getSuitIndex(Suit suit) {
      switch (suit) {
        case Suit.hearts:
          return 0;
        case Suit.diamonds:
          return 1;
        case Suit.clubs:
          return 2;
        case Suit.spades:
          return 3;
      }
    }

    // Convert tableau piles
    final tableauCards = <List<YukonCardInfo>>[];
    for (final pile in tableau) {
      tableauCards.add(
        pile.cards
            .map((c) => YukonCardInfo(cardToString(c), c.faceUp))
            .toList(),
      );
    }

    // Convert foundations (just track top rank per suit)
    final foundationRanks = <int>[0, 0, 0, 0];
    for (final foundation in foundations) {
      if (!foundation.isEmpty) {
        final topCard = foundation.topCard!;
        final suitIdx = getSuitIndex(topCard.suit);
        foundationRanks[suitIdx] = topCard.value;
      }
    }

    return YukonSolverState(
      tableau: tableauCards,
      foundations: foundationRanks,
    );
  }

  @override
  Pile? getPile(PileType type) {
    return null; // No single stock/waste piles
  }

  @override
  List<Pile> get focusablePiles {
    final piles = <Pile>[];
    piles.addAll(tableau);
    piles.addAll(foundations);
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
    // Yukon has no special tap behavior
    return null;
  }

  @override
  List<PlayingCard>? getSelectableCards(Pile pile, PlayingCard card) {
    // In Yukon, can select any face-up card and all cards above it
    if (pile.type == PileType.tableau) {
      final index = pile.indexOfCard(card);
      if (index >= 0 && card.faceUp) {
        return pile.cards.sublist(index);
      }
    }
    return null;
  }

  @override
  bool get supportsStockHints => false;

  @override
  ({Pile source, Pile destination})? getStockHint() => null;
}
