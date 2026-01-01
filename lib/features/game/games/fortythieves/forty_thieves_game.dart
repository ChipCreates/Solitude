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
import '../../ai/games/forty_thieves_solver_state.dart';

/// Forty Thieves Solitaire implementation.
///
/// Setup: 2 Decks (104 cards). 10 Tableau columns (4 cards each, all face up). Stock/Waste. 8 Foundations.
/// Moves:
///   - Build down by Suit (e.g., 8♠ on 9♠).
///   - Only move 1 card at a time (standard rule).
///   - Empty space can be filled by any card.
/// Win: All cards to 8 foundations.
class FortyThievesGame extends SolitaireGameBase {
  late Pile stock;
  late Pile waste;
  late List<Pile> foundations;
  late List<Pile> tableau;

  final List<Move> _moveHistory = [];
  final List<Move> _redoStack = [];
  int _moveCount = 0;

  FortyThievesGame() {
    _initializePiles();
  }

  void _initializePiles() {
    stock = Pile(type: PileType.stock);
    waste = Pile(type: PileType.waste);
    // 8 foundations for 2 decks (2 per suit)
    foundations =
        List.generate(8, (i) => Pile(type: PileType.foundation, index: i));
    tableau = List.generate(10, (i) => Pile(type: PileType.tableau, index: i));
  }

  @override
  void initialize({Random? random}) {
    _initializePiles();
    _moveHistory.clear();
    _redoStack.clear();
    _moveCount = 0;

    // Use 2 decks (104 cards)
    final deck = Deck(deckCount: 2);
    deck.shuffle(random ?? Random());

    // Deal 4 cards to each of 10 tableau columns (40 cards), all face up
    for (int col = 0; col < 10; col++) {
      for (int row = 0; row < 4; row++) {
        final card = deck.draw()!;
        card.faceUp = true;
        tableau[col].addCard(card);
      }
    }

    // Remaining 64 cards go to stock (face down)
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
  List<Pile> get allPiles => [stock, waste, ...foundations, ...tableau];

  @override
  int get moveCount => _moveCount;

  @override
  List<Move> get moveHistory => List.unmodifiable(_moveHistory);

  @override
  List<Move> get redoStack => List.unmodifiable(_redoStack);

  @override
  bool get canRedo => _redoStack.isNotEmpty;

  @override
  GameType get gameType => GameType.fortyThieves;

  @override
  int get deckSize => 104; // 2 decks

  @override
  LayoutConfig get layoutConfig => const LayoutConfig(
        tableauCount: 10,
        foundationCount: 8,
        hasStock: true,
        hasWaste: true,
        layoutType: LayoutType.grid,
      );

  // ==========================================================================
  // Pile Accessors (GameInterface)
  // ==========================================================================

  @override
  Pile? get stockPile => stock;

  @override
  Pile? get wastePile => waste;

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

    // Can't move to stock
    if (to.type == PileType.stock) return false;

    // Can't move to waste
    if (to.type == PileType.waste) return false;

    // Foundation moves
    if (to.type == PileType.foundation) {
      // Only single cards to foundation
      if (cards.length > 1) return false;
      return movingCard.canStackOnFoundation(to.topCard);
    }

    // Tableau moves
    if (to.type == PileType.tableau) {
      // Standard Forty Thieves: only 1 card at a time
      if (cards.length > 1) return false;

      if (to.isEmpty) {
        // Any card can go on empty tableau
        return true;
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

    // Remove cards from source
    final removed = from.removeFrom(startIndex);

    // Add to destination
    to.addCards(removed);

    final move = Move(
      fromPile: from,
      toPile: to,
      cards: removed,
      flippedCard: false, // All cards are face up in Forty Thieves
    );
    _moveHistory.add(move);
    _redoStack.clear();
    _moveCount++;

    return move;
  }

  @override
  Move? tapStock() {
    if (stock.isEmpty) {
      // Forty Thieves typically doesn't allow recycling
      return null;
    }

    // Draw one card from stock to waste
    final card = stock.removeTop()!;
    card.faceUp = true;
    waste.addCard(card);

    final move = Move(
      fromPile: stock,
      toPile: waste,
      cards: [card],
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

    // Handle stock draw undo
    if (move.drewFromStock) {
      final card = waste.removeTop()!;
      card.faceUp = false;
      stock.addCard(card);
      return true;
    }

    // Handle normal move undo
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

    // Handle stock draw redo
    if (move.drewFromStock) {
      final card = stock.removeTop()!;
      card.faceUp = true;
      waste.addCard(card);
      _moveHistory.add(move);
      return true;
    }

    // Handle normal move redo
    final startIndex = move.fromPile.indexOfCard(move.cards.first);
    if (startIndex == -1) return false;

    final removed = move.fromPile.removeFrom(startIndex);
    move.toPile.addCards(removed);

    _moveHistory.add(move);
    return true;
  }

  @override
  bool checkWin() {
    // Win when all foundations have 13 cards (8 foundations * 13 = 104 cards)
    return foundations.every((f) => f.length == 13);
  }

  @override
  bool canAutoComplete() {
    // Can auto-complete when all cards in tableau and waste are face-up
    // and stock is empty
    return stock.isEmpty;
  }

  @override
  bool autoCompleteStep() {
    // Try to move cards to foundations
    // Check waste first
    if (!waste.isEmpty) {
      final card = waste.topCard!;
      for (final foundation in foundations) {
        if (card.canStackOnFoundation(foundation.topCard)) {
          executeMove(waste, foundation, [card]);
          return true;
        }
      }
    }

    // Check tableau piles
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
    return !stock.isEmpty;
  }

  @override
  bool hasValidWasteMoves() {
    if (waste.isEmpty) return false;
    final card = waste.topCard!;

    // Check foundations
    for (final foundation in foundations) {
      if (card.canStackOnFoundation(foundation.topCard)) return true;
    }

    // Check tableau
    for (final pile in tableau) {
      if (isValidMove(waste, pile, [card])) return true;
    }

    return false;
  }

  @override
  bool hasValidTableauMoves() {
    for (final fromPile in tableau) {
      if (fromPile.isEmpty) continue;
      final card = fromPile.topCard!;

      // Check foundations
      for (final foundation in foundations) {
        if (card.canStackOnFoundation(foundation.topCard)) return true;
      }

      // Check tableau
      for (final toPile in tableau) {
        if (toPile == fromPile) continue;
        if (isValidMove(fromPile, toPile, [card])) return true;
      }
    }
    return false;
  }

  @override
  bool get isLost {
    if (hasAnyMove()) return false;
    return stock.isEmpty;
  }

  @override
  Pile? findBestAutoMoveDestination(Pile fromPile, List<PlayingCard> cards) {
    if (cards.isEmpty) return null;
    if (cards.length != 1) return null;

    final card = cards.first;

    // Priority 1: Aces go to empty foundations
    if (card.rank == Rank.ace) {
      for (final foundation in foundations) {
        if (foundation.isEmpty) {
          return foundation;
        }
      }
    }

    // Priority 2: Cards that can stack on foundations
    for (final foundation in foundations) {
      if (isValidMove(fromPile, foundation, [card])) {
        return foundation;
      }
    }

    // Priority 3: Valid tableau moves (prefer non-empty, same suit building)
    for (final t in tableau) {
      if (!t.isEmpty && t != fromPile && isValidMove(fromPile, t, cards)) {
        return t;
      }
    }

    // Priority 4: Empty tableau
    for (final t in tableau) {
      if (t.isEmpty && t != fromPile) {
        return t;
      }
    }

    return null;
  }

  @override
  ({Pile from, Pile to, List<PlayingCard> cards})? getHint() {
    // Priority 1: Move cards to foundations
    if (!waste.isEmpty) {
      final card = waste.topCard!;
      for (final foundation in foundations) {
        if (card.canStackOnFoundation(foundation.topCard)) {
          return (from: waste, to: foundation, cards: [card]);
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

    // Priority 2: Tableau to tableau (build sequences)
    for (final fromPile in tableau) {
      if (fromPile.isEmpty) continue;
      final card = fromPile.topCard!;

      // Prefer moving to non-empty piles
      for (final toPile in tableau) {
        if (toPile == fromPile) continue;
        if (toPile.isEmpty) continue;
        if (isValidMove(fromPile, toPile, [card])) {
          return (from: fromPile, to: toPile, cards: [card]);
        }
      }
    }

    // Priority 3: Waste to tableau
    if (!waste.isEmpty) {
      final card = waste.topCard!;
      for (final pile in tableau) {
        if (isValidMove(waste, pile, [card])) {
          return (from: waste, to: pile, cards: [card]);
        }
      }
    }

    // Priority 4: Draw from stock
    if (!stock.isEmpty) {
      return (from: stock, to: waste, cards: []);
    }

    return null;
  }

  @override
  void applyDifficulty(Difficulty difficulty) {
    // Forty Thieves doesn't have standard difficulty variations
  }

  @override
  void configure(SettingsProvider settings) {
    // Forty Thieves doesn't have configurable settings
  }

  @override
  SolverState<FortyThievesMove>? getSolverState() {
    // Convert card to solver format: "rankSuit" (e.g., "1H" for Ace of Hearts)
    String cardToString(PlayingCard card) {
      return '${card.value}${card.suit.name[0].toUpperCase()}';
    }

    // Convert tableau piles
    final tableauCards = <List<String>>[];
    for (final pile in tableau) {
      tableauCards.add(pile.cards.map(cardToString).toList());
    }

    // Convert foundations (top card or null)
    final foundationTops = <String?>[];
    for (final foundation in foundations) {
      if (foundation.isEmpty) {
        foundationTops.add(null);
      } else {
        foundationTops.add(cardToString(foundation.topCard!));
      }
    }

    // Convert stock
    final stockCards = stock.cards.map(cardToString).toList();

    // Get waste top
    final wasteTopCard = waste.isEmpty ? null : cardToString(waste.topCard!);

    return FortyThievesSolverState(
      tableau: tableauCards,
      foundations: foundationTops,
      stock: stockCards,
      wasteTop: wasteTopCard,
    );
  }

  @override
  Pile? getPile(PileType type) {
    switch (type) {
      case PileType.stock:
        return stock;
      case PileType.waste:
        return waste;
      default:
        return null;
    }
  }

  @override
  List<Pile> get focusablePiles {
    final piles = <Pile>[stock];
    if (!waste.isEmpty) {
      piles.add(waste);
    }
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
    if (pile.type == PileType.stock) {
      return tapStock();
    }
    return null;
  }

  @override
  List<PlayingCard>? getSelectableCards(Pile pile, PlayingCard card) {
    // In Forty Thieves, can only select the top card
    if (pile.type == PileType.tableau || pile.type == PileType.waste) {
      if (pile.topCard == card) {
        return [card];
      }
    }
    return null;
  }

  @override
  Suit? getFoundationSuit(int foundationIndex) {
    // In Forty Thieves with 2 decks, we have 2 foundations per suit
    // Foundations 0-3: first deck (hearts, diamonds, clubs, spades)
    // Foundations 4-7: second deck (hearts, diamonds, clubs, spades)
    if (foundationIndex < 0 || foundationIndex >= foundations.length) {
      return null;
    }
    return Suit.values[foundationIndex % 4];
  }
}
