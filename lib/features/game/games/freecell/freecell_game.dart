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
import '../../ai/games/freecell_solver_state.dart';

/// FreeCell Solitaire implementation.
///
/// Setup: 8 Tableau columns (all face up), 4 empty FreeCells, 4 Foundations.
/// Moves: Tableau builds down by Alternating Color. FreeCells hold any 1 card.
/// Supermove: Allow moving stack size N if N <= (emptyCells + 1) * (2^emptyCols).
class FreeCellGame extends SolitaireGameBase {
  late List<Pile> freeCells;
  late List<Pile> foundations;
  late List<Pile> tableau;

  final List<Move> _moveHistory = [];
  final List<Move> _redoStack = [];
  int _moveCount = 0;

  FreeCellGame() {
    _initializePiles();
  }

  void _initializePiles() {
    freeCells = List.generate(4, (i) => Pile(type: PileType.cell, index: i));
    foundations =
        List.generate(4, (i) => Pile(type: PileType.foundation, index: i));
    tableau = List.generate(8, (i) => Pile(type: PileType.tableau, index: i));
  }

  @override
  void initialize({Random? random}) {
    _initializePiles();
    _moveHistory.clear();
    _redoStack.clear();
    _moveCount = 0;

    final deck = Deck();
    deck.shuffle(random ?? Random());

    // Deal all 52 cards to 8 tableau piles
    // First 4 piles get 7 cards, last 4 piles get 6 cards
    int pileIndex = 0;
    while (!deck.isEmpty) {
      final card = deck.draw()!;
      card.faceUp = true; // All cards face up in FreeCell
      tableau[pileIndex].addCard(card);
      pileIndex = (pileIndex + 1) % 8;
    }
  }

  @override
  void reset() {
    initialize();
  }

  @override
  List<Pile> get allPiles => [...freeCells, ...foundations, ...tableau];

  @override
  int get moveCount => _moveCount;

  @override
  List<Move> get moveHistory => List.unmodifiable(_moveHistory);

  @override
  List<Move> get redoStack => List.unmodifiable(_redoStack);

  @override
  bool get canRedo => _redoStack.isNotEmpty;

  @override
  GameType get gameType => GameType.freecell;

  @override
  int get deckSize => 52;

  @override
  LayoutConfig get layoutConfig => const LayoutConfig(
        tableauCount: 8,
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

  /// Get free cell piles
  List<Pile> get freeCellPiles => freeCells;

  // ==========================================================================
  // Supermove Calculation
  // ==========================================================================

  /// Calculate the maximum number of cards that can be moved as a group.
  /// Formula: (emptyCells + 1) * 2^(emptyColumns)
  int get maxMoveableCards {
    final emptyCells = freeCells.where((c) => c.isEmpty).length;
    final emptyColumns = tableau.where((t) => t.isEmpty).length;

    // (emptyCells + 1) * 2^emptyColumns
    return (emptyCells + 1) * (1 << emptyColumns);
  }

  /// Calculate moveable cards when moving TO an empty column
  /// (one less empty column available for temp storage)
  int get maxMoveableCardsToEmpty {
    final emptyCells = freeCells.where((c) => c.isEmpty).length;
    int emptyColumns = tableau.where((t) => t.isEmpty).length - 1;
    if (emptyColumns < 0) emptyColumns = 0;

    return (emptyCells + 1) * (1 << emptyColumns);
  }

  // ==========================================================================
  // Move Validation
  // ==========================================================================

  @override
  bool isValidMove(Pile from, Pile to, List<PlayingCard> cards) {
    if (cards.isEmpty) return false;
    final movingCard = cards.first;

    // Can't move to stock (doesn't exist) or back to same pile
    if (from == to) return false;

    // FreeCell (cell) moves
    if (to.type == PileType.cell) {
      // FreeCells can only hold 1 card
      if (to.isEmpty && cards.length == 1) return true;
      return false;
    }

    // Foundation moves
    if (to.type == PileType.foundation) {
      // Only single cards to foundation
      if (cards.length > 1) return false;
      return movingCard.canStackOnFoundation(to.topCard);
    }

    // Tableau moves
    if (to.type == PileType.tableau) {
      // Check if we have enough free space for a supermove
      final maxCards = to.isEmpty ? maxMoveableCardsToEmpty : maxMoveableCards;
      if (cards.length > maxCards) return false;

      // Verify the cards form a valid alternating-color descending sequence
      if (!_isValidDescendingAlternatingSequence(cards)) return false;

      if (to.isEmpty) {
        // Any card can go on empty tableau in FreeCell
        return true;
      }

      // Must be alternating colors and descending
      return movingCard.canStackOn(to.topCard!,
          alternatingColors: true, descending: true);
    }

    return false;
  }

  /// Check if a list of cards forms a valid descending alternating-color sequence
  bool _isValidDescendingAlternatingSequence(List<PlayingCard> cards) {
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

  @override
  Move? executeMove(Pile from, Pile to, List<PlayingCard> cards) {
    if (!isValidMove(from, to, cards)) return null;

    final startIndex = from.indexOfCard(cards.first);
    if (startIndex == -1) return null;

    // Remove cards from source
    final removed = from.removeFrom(startIndex);

    // Add to destination
    to.addCards(removed);

    // Record move
    final move = Move(
      fromPile: from,
      toPile: to,
      cards: removed,
      flippedCard: false,
    );
    _moveHistory.add(move);
    _redoStack.clear();
    _moveCount++;

    return move;
  }

  @override
  Move? tapStock() {
    // FreeCell has no stock
    return null;
  }

  @override
  bool undo() {
    if (_moveHistory.isEmpty) return false;

    final move = _moveHistory.removeLast();
    _redoStack.add(move);
    _moveCount--;

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
    // In FreeCell, all cards are always face-up
    // Can auto-complete when there are actually safe moves to foundation
    // Check if there's at least one card that can be safely auto-moved

    // Check freecells for safe moves
    for (final cell in freeCells) {
      if (cell.isEmpty) continue;
      final card = cell.topCard!;
      for (final foundation in foundations) {
        if (card.canStackOnFoundation(foundation.topCard) &&
            _isSafeToAutoMove(card)) {
          return true;
        }
      }
    }

    // Check tableau for safe moves
    for (final pile in tableau) {
      if (pile.isEmpty) continue;
      final card = pile.topCard!;
      for (final foundation in foundations) {
        if (card.canStackOnFoundation(foundation.topCard) &&
            _isSafeToAutoMove(card)) {
          return true;
        }
      }
    }

    return false;
  }

  @override
  bool autoCompleteStep() {
    // Find the minimum value safely moveable to foundation
    // (a card is safe if all cards that could stack on it are already on foundations)

    // Try to move cards from freecells to foundations
    for (final cell in freeCells) {
      if (cell.isEmpty) continue;
      final card = cell.topCard!;
      for (final foundation in foundations) {
        if (card.canStackOnFoundation(foundation.topCard)) {
          if (_isSafeToAutoMove(card)) {
            executeMove(cell, foundation, [card]);
            return true;
          }
        }
      }
    }

    // Try to move cards from tableau to foundations
    for (final pile in tableau) {
      if (pile.isEmpty) continue;
      final card = pile.topCard!;
      for (final foundation in foundations) {
        if (card.canStackOnFoundation(foundation.topCard)) {
          if (_isSafeToAutoMove(card)) {
            executeMove(pile, foundation, [card]);
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Check if a card can be safely auto-moved to foundation.
  /// A card is safe if all cards that could potentially stack on it
  /// in the tableau are already on foundations.
  bool _isSafeToAutoMove(PlayingCard card) {
    // Aces and 2s are always safe
    if (card.value <= 2) return true;

    // Find the minimum foundation value for opposite colors
    int minRedFoundation = 0;
    int minBlackFoundation = 0;

    for (final foundation in foundations) {
      if (foundation.isEmpty) continue;
      final topCard = foundation.topCard!;
      if (topCard.isRed) {
        minRedFoundation = max(minRedFoundation, topCard.value);
      } else {
        minBlackFoundation = max(minBlackFoundation, topCard.value);
      }
    }

    // A card is safe if the opposite color foundations have at least value - 1
    if (card.isRed) {
      return minBlackFoundation >= card.value - 1;
    } else {
      return minRedFoundation >= card.value - 1;
    }
  }

  @override
  List<Pile> getValidDestinations(Pile from, List<PlayingCard> cards) {
    final destinations = <Pile>[];

    // Check foundations
    for (final foundation in foundations) {
      if (isValidMove(from, foundation, cards)) {
        destinations.add(foundation);
      }
    }

    // Check free cells
    for (final cell in freeCells) {
      if (isValidMove(from, cell, cards)) {
        destinations.add(cell);
      }
    }

    // Check tableau
    for (final pile in tableau) {
      if (pile != from && isValidMove(from, pile, cards)) {
        destinations.add(pile);
      }
    }

    return destinations;
  }

  @override
  bool canDrawFromStock() {
    return false; // No stock in FreeCell
  }

  @override
  bool hasValidWasteMoves() {
    return false; // No waste in FreeCell
  }

  @override
  bool hasValidTableauMoves() {
    // Check if any tableau or freecell card can move
    for (final fromPile in tableau) {
      if (fromPile.isEmpty) continue;

      // Check each possible card group from this pile
      for (int i = 0; i < fromPile.cards.length; i++) {
        final card = fromPile.cardAt(i);
        if (card == null) continue;

        final cardsToMove = fromPile.cards.sublist(i);
        if (!_isValidDescendingAlternatingSequence(cardsToMove)) continue;

        // Check foundation moves (single card only)
        if (cardsToMove.length == 1) {
          for (final foundation in foundations) {
            if (cardsToMove.first.canStackOnFoundation(foundation.topCard)) {
              return true;
            }
          }
        }

        // Check tableau moves
        for (final toPile in tableau) {
          if (toPile == fromPile) continue;
          if (isValidMove(fromPile, toPile, cardsToMove)) return true;
        }

        // Check freecell moves (single card only)
        if (cardsToMove.length == 1) {
          for (final cell in freeCells) {
            if (cell.isEmpty) return true;
          }
        }
      }
    }

    // Check freecell cards
    for (final cell in freeCells) {
      if (cell.isEmpty) continue;
      final card = cell.topCard!;

      // Check foundation
      for (final foundation in foundations) {
        if (card.canStackOnFoundation(foundation.topCard)) return true;
      }

      // Check tableau
      for (final pile in tableau) {
        if (isValidMove(cell, pile, [card])) return true;
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
    if (card.rank == Rank.ace) {
      for (final foundation in foundations) {
        if (foundation.isEmpty && isValidMove(fromPile, foundation, [card])) {
          return foundation;
        }
      }
    }

    // Priority 2: Cards that can safely stack on foundations
    if (cards.length == 1 && _isSafeToAutoMove(card)) {
      for (final foundation in foundations) {
        if (isValidMove(fromPile, foundation, [card])) {
          return foundation;
        }
      }
    }

    // Priority 3: Valid tableau moves (prefer non-empty)
    for (final t in tableau) {
      if (!t.isEmpty && t != fromPile && isValidMove(fromPile, t, cards)) {
        return t;
      }
    }

    // Priority 4: Empty tableau
    for (final t in tableau) {
      if (t.isEmpty && t != fromPile && isValidMove(fromPile, t, cards)) {
        return t;
      }
    }

    // Priority 5: Empty freecell (for single cards only)
    if (cards.length == 1) {
      for (final cell in freeCells) {
        if (cell.isEmpty) {
          return cell;
        }
      }
    }

    return null;
  }

  @override
  ({Pile from, Pile to, List<PlayingCard> cards})? getHint() {
    // Priority 1: Move cards to foundations
    for (final cell in freeCells) {
      if (cell.isEmpty) continue;
      final card = cell.topCard!;
      for (final foundation in foundations) {
        if (card.canStackOnFoundation(foundation.topCard)) {
          return (from: cell, to: foundation, cards: [card]);
        }
      }
    }

    for (final pile in tableau) {
      if (pile.isEmpty) continue;
      final card = pile.topCard!;
      for (final foundation in foundations) {
        if (card.canStackOnFoundation(foundation.topCard)) {
          return (from: pile, to: foundation, cards: [card]);
        }
      }
    }

    // Priority 2: Build tableau sequences
    for (final fromPile in tableau) {
      if (fromPile.isEmpty) continue;

      for (int i = 0; i < fromPile.cards.length; i++) {
        final cardsToMove = fromPile.cards.sublist(i);
        if (!_isValidDescendingAlternatingSequence(cardsToMove)) continue;

        // Prefer moving to non-empty piles
        for (final toPile in tableau) {
          if (toPile == fromPile) continue;
          if (toPile.isEmpty) continue;
          if (isValidMove(fromPile, toPile, cardsToMove)) {
            return (from: fromPile, to: toPile, cards: cardsToMove);
          }
        }
      }
    }

    // Priority 3: Move freecell cards to tableau
    for (final cell in freeCells) {
      if (cell.isEmpty) continue;
      final card = cell.topCard!;
      for (final pile in tableau) {
        if (isValidMove(cell, pile, [card])) {
          return (from: cell, to: pile, cards: [card]);
        }
      }
    }

    // Priority 4: Move to empty tableau
    for (final fromPile in tableau) {
      if (fromPile.isEmpty) continue;

      for (int i = 0; i < fromPile.cards.length; i++) {
        final cardsToMove = fromPile.cards.sublist(i);
        if (!_isValidDescendingAlternatingSequence(cardsToMove)) continue;

        for (final toPile in tableau) {
          if (toPile == fromPile) continue;
          if (!toPile.isEmpty) continue;
          if (isValidMove(fromPile, toPile, cardsToMove)) {
            return (from: fromPile, to: toPile, cards: cardsToMove);
          }
        }
      }
    }

    // Priority 5: Use freecells
    for (final pile in tableau) {
      if (pile.isEmpty) continue;
      final card = pile.topCard!;
      for (final cell in freeCells) {
        if (cell.isEmpty) {
          return (from: pile, to: cell, cards: [card]);
        }
      }
    }

    return null;
  }

  @override
  void applyDifficulty(Difficulty difficulty) {
    // FreeCell doesn't have difficulty variations in standard rules
  }

  @override
  void configure(SettingsProvider settings) {
    // FreeCell doesn't have configurable settings
  }

  @override
  FreeCellSolverState? getSolverState() {
    // Convert card to solver format: "rankSuit" e.g. "1H" for Ace of Hearts
    String cardToString(PlayingCard card) {
      return '${card.value}${card.suit.name[0].toUpperCase()}';
    }

    // Convert tableau piles
    final solverTableau = tableau.map((pile) {
      return pile.cards.map((card) => cardToString(card)).toList();
    }).toList();

    // Convert free cells
    final solverCells = freeCells.map((cell) {
      if (cell.isEmpty) return null;
      return cardToString(cell.topCard!);
    }).toList();

    // Convert foundations (top card of each, indexed by suit H,D,C,S)
    final solverFoundation = <String?>[null, null, null, null];
    for (final foundation in foundations) {
      if (foundation.isEmpty) continue;
      final topCard = foundation.topCard!;
      final suitIdx = _suitToIndex(topCard.suit);
      solverFoundation[suitIdx] = cardToString(topCard);
    }

    return FreeCellSolverState(
      tableau: solverTableau,
      freeCells: solverCells,
      foundation: solverFoundation,
    );
  }

  int _suitToIndex(Suit suit) {
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

  @override
  Pile? getPile(PileType type) {
    switch (type) {
      case PileType.stock:
        return null;
      case PileType.waste:
        return null;
      default:
        return null;
    }
  }

  @override
  List<Pile> get focusablePiles {
    final piles = <Pile>[];
    piles.addAll(freeCells);
    piles.addAll(foundations);
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
    // FreeCell has no special tap behavior
    return null;
  }

  @override
  bool get supportsStockHints => false;

  @override
  ({Pile source, Pile destination})? getStockHint() => null;
}
