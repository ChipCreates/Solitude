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
import '../../ai/games/canfield_solver_state.dart';

/// Canfield Solitaire implementation.
///
/// Setup: 4 Tableau, 1 Reserve (13 cards), Stock/Waste, 4 Foundations.
/// Base Rank: First card dealt to Foundation sets the base rank for all suits.
/// Moves:
///   - Tableau builds down by Alternating Color. Wraps A -> K.
///   - Empty Tableau filled automatically from Reserve.
/// Win: All cards to foundations.
class CanfieldGame extends SolitaireGameBase {
  late Pile stock;
  late Pile waste;
  late Pile reserve;
  late List<Pile> foundations;
  late List<Pile> tableau;

  final List<Move> _moveHistory = [];
  final List<Move> _redoStack = [];
  int _moveCount = 0;

  /// The base rank for foundations (set by first foundation card)
  Rank? _baseRank;

  CanfieldGame() {
    _initializePiles();
  }

  void _initializePiles() {
    stock = Pile(type: PileType.stock);
    waste = Pile(type: PileType.waste);
    reserve = Pile(type: PileType.reserve, index: 0);
    foundations =
        List.generate(4, (i) => Pile(type: PileType.foundation, index: i));
    tableau = List.generate(4, (i) => Pile(type: PileType.tableau, index: i));
  }

  @override
  void initialize({Random? random}) {
    _initializePiles();
    _moveHistory.clear();
    _redoStack.clear();
    _moveCount = 0;
    _baseRank = null;

    final deck = Deck();
    deck.shuffle(random ?? Random());

    // Deal 13 cards to reserve (face down, only top face up)
    for (int i = 0; i < 13; i++) {
      final card = deck.draw()!;
      card.faceUp = (i == 12); // Only top card face up
      reserve.addCard(card);
    }

    // Deal 1 card to first foundation - this sets the base rank
    final foundationCard = deck.draw()!;
    foundationCard.faceUp = true;
    foundations[0].addCard(foundationCard);
    _baseRank = foundationCard.rank;

    // Deal 1 card to each tableau pile (face up)
    for (int i = 0; i < 4; i++) {
      final card = deck.draw()!;
      card.faceUp = true;
      tableau[i].addCard(card);
    }

    // Remaining cards go to stock (face down)
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
  List<Pile> get allPiles =>
      [stock, waste, reserve, ...foundations, ...tableau];

  @override
  int get moveCount => _moveCount;

  @override
  List<Move> get moveHistory => List.unmodifiable(_moveHistory);

  @override
  List<Move> get redoStack => List.unmodifiable(_redoStack);

  @override
  bool get canRedo => _redoStack.isNotEmpty;

  @override
  GameType get gameType => GameType.canfield;

  @override
  int get deckSize => 52;

  @override
  LayoutConfig get layoutConfig => const LayoutConfig(
        tableauCount: 4,
        foundationCount: 4,
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

  /// Get the reserve pile
  Pile get reservePile => reserve;

  /// Get the base rank for foundations
  Rank? get baseRank => _baseRank;

  // ==========================================================================
  // Foundation Logic with Base Rank
  // ==========================================================================

  /// Get the expected value for a foundation given its current state
  int _getNextFoundationValue(Pile foundation) {
    if (foundation.isEmpty) {
      return _baseRank!.index + 1; // Base rank value
    }
    final topValue = foundation.topCard!.value;
    // Wrap from King (13) to Ace (1)
    return topValue == 13 ? 1 : topValue + 1;
  }

  /// Check if a card can be placed on a foundation (considering base rank and wrapping)
  bool canStackOnFoundationWithBase(PlayingCard card, Pile foundation) {
    if (_baseRank == null) return false;

    if (foundation.isEmpty) {
      // Empty foundation must start with base rank
      return card.rank == _baseRank;
    }

    final topCard = foundation.topCard!;
    // Must be same suit
    if (card.suit != topCard.suit) return false;

    // Check value with wrapping (K -> A)
    final expectedValue = _getNextFoundationValue(foundation);
    return card.value == expectedValue;
  }

  // ==========================================================================
  // Tableau Logic with Wrapping
  // ==========================================================================

  /// Check if a card can stack on another in tableau (alternating color, descending, wrapping)
  bool canStackOnTableauWithWrap(PlayingCard card, PlayingCard target) {
    // Must be alternating colors
    if (card.isRed == target.isRed) return false;

    // Check descending with wrap (A can go on 2, K can go on A)
    final expectedValue = target.value == 1 ? 13 : target.value - 1;
    return card.value == expectedValue;
  }

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

    // Can't move to reserve
    if (to.type == PileType.reserve) return false;

    // Foundation moves
    if (to.type == PileType.foundation) {
      // Only single cards to foundation
      if (cards.length > 1) return false;
      return canStackOnFoundationWithBase(movingCard, to);
    }

    // Tableau moves
    if (to.type == PileType.tableau) {
      // Verify the cards form a valid alternating-color descending sequence (with wrapping)
      if (!_isValidTableauSequence(cards)) return false;

      if (to.isEmpty) {
        // Any card can go on empty tableau (will be filled from reserve automatically)
        return true;
      }

      // Must be alternating colors and descending (with wrapping)
      return canStackOnTableauWithWrap(movingCard, to.topCard!);
    }

    return false;
  }

  /// Check if cards form a valid tableau sequence (alternating colors, descending, with wrapping)
  bool _isValidTableauSequence(List<PlayingCard> cards) {
    if (cards.length <= 1) return true;
    for (int i = 1; i < cards.length; i++) {
      final prev = cards[i - 1];
      final curr = cards[i];
      if (!canStackOnTableauWithWrap(curr, prev)) {
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

    // Record the move
    final move = Move(
      fromPile: from,
      toPile: to,
      cards: removed,
      flippedCard: false,
    );
    _moveHistory.add(move);
    _redoStack.clear();
    _moveCount++;

    // Auto-fill empty tableau from reserve
    _autoFillTableau();

    return move;
  }

  /// Automatically fill empty tableau piles from reserve
  void _autoFillTableau() {
    if (reserve.isEmpty) return;

    for (final pile in tableau) {
      if (pile.isEmpty && !reserve.isEmpty) {
        final card = reserve.removeTop()!;
        card.faceUp = true;
        pile.addCard(card);

        // Flip the new top of reserve
        if (!reserve.isEmpty && !reserve.topCard!.faceUp) {
          reserve.topCard!.faceUp = true;
        }
      }
    }
  }

  @override
  Move? tapStock() {
    if (stock.isEmpty) {
      // Recycle waste back to stock
      if (waste.isEmpty) return null;

      final wasteCards = waste.removeAll();
      for (final card in wasteCards.reversed) {
        card.faceUp = false;
        stock.addCard(card);
      }

      final move = Move(
        fromPile: waste,
        toPile: stock,
        cards: wasteCards,
        drewFromStock: true,
      );
      _moveHistory.add(move);
      _redoStack.clear();
      _moveCount++;
      return move;
    }

    // Draw 3 cards from stock to waste (or fewer if less available)
    final drawnCards = <PlayingCard>[];
    for (int i = 0; i < 3 && !stock.isEmpty; i++) {
      final card = stock.removeTop()!;
      card.faceUp = true;
      waste.addCard(card);
      drawnCards.add(card);
    }

    final move = Move(
      fromPile: stock,
      toPile: waste,
      cards: drawnCards,
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

    // Handle stock recycle undo
    if (move.drewFromStock && move.toPile.type == PileType.stock) {
      final stockCards = stock.removeAll();
      for (final card in stockCards.reversed) {
        card.faceUp = true;
        waste.addCard(card);
      }
      return true;
    }

    // Handle normal stock draw undo
    if (move.drewFromStock) {
      for (final card in move.cards.reversed) {
        waste.removeTop();
        card.faceUp = false;
        stock.addCard(card);
      }
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

    // Handle stock recycle redo
    if (move.drewFromStock && move.toPile.type == PileType.stock) {
      final wasteCards = waste.removeAll();
      for (final card in wasteCards.reversed) {
        card.faceUp = false;
        stock.addCard(card);
      }
      _moveHistory.add(move);
      return true;
    }

    // Handle normal stock draw redo
    if (move.drewFromStock) {
      for (final card in move.cards) {
        stock.removeTop();
        card.faceUp = true;
        waste.addCard(card);
      }
      _moveHistory.add(move);
      return true;
    }

    // Handle normal move redo
    final startIndex = move.fromPile.indexOfCard(move.cards.first);
    if (startIndex == -1) return false;

    final removed = move.fromPile.removeFrom(startIndex);
    move.toPile.addCards(removed);
    _autoFillTableau();

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
    // Can auto-complete when reserve and stock are empty
    return reserve.isEmpty && stock.isEmpty && waste.isEmpty;
  }

  @override
  bool autoCompleteStep() {
    // Try to move cards to foundations
    for (final pile in tableau) {
      if (pile.isEmpty) continue;
      final card = pile.topCard!;
      for (final foundation in foundations) {
        if (canStackOnFoundationWithBase(card, foundation)) {
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
    return !stock.isEmpty || !waste.isEmpty;
  }

  @override
  bool hasValidWasteMoves() {
    if (waste.isEmpty) return false;
    final card = waste.topCard!;

    // Check foundations
    for (final foundation in foundations) {
      if (canStackOnFoundationWithBase(card, foundation)) return true;
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

      // Check each card in the pile (can move any face-up card)
      for (int i = 0; i < fromPile.cards.length; i++) {
        final card = fromPile.cardAt(i);
        if (card == null || !card.faceUp) continue;

        final cardsToMove = fromPile.cards.sublist(i);
        if (!_isValidTableauSequence(cardsToMove)) continue;

        // Check foundations (single card only)
        if (cardsToMove.length == 1) {
          for (final foundation in foundations) {
            if (canStackOnFoundationWithBase(cardsToMove.first, foundation)) {
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

    // Check reserve
    if (!reserve.isEmpty) {
      final card = reserve.topCard!;
      for (final foundation in foundations) {
        if (canStackOnFoundationWithBase(card, foundation)) return true;
      }
      for (final pile in tableau) {
        if (isValidMove(reserve, pile, [card])) return true;
      }
    }

    return false;
  }

  @override
  bool get isLost {
    if (hasAnyMove()) return false;
    if (!stock.isEmpty || !waste.isEmpty) return false;
    return true;
  }

  @override
  Pile? findBestAutoMoveDestination(Pile fromPile, List<PlayingCard> cards) {
    if (cards.isEmpty) return null;
    final card = cards.first;

    // Priority 1: Base rank cards go to empty foundations
    if (card.rank == _baseRank && cards.length == 1) {
      for (final foundation in foundations) {
        if (foundation.isEmpty) {
          return foundation;
        }
      }
    }

    // Priority 2: Cards that can stack on foundations
    if (cards.length == 1) {
      for (final foundation in foundations) {
        if (canStackOnFoundationWithBase(card, foundation)) {
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

    return null;
  }

  @override
  ({Pile from, Pile to, List<PlayingCard> cards})? getHint() {
    // Priority 1: Move base rank to foundation
    if (!reserve.isEmpty && reserve.topCard!.rank == _baseRank) {
      for (final foundation in foundations) {
        if (foundation.isEmpty) {
          return (from: reserve, to: foundation, cards: [reserve.topCard!]);
        }
      }
    }

    // Priority 2: Move cards to foundations
    if (!waste.isEmpty) {
      final card = waste.topCard!;
      for (final foundation in foundations) {
        if (canStackOnFoundationWithBase(card, foundation)) {
          return (from: waste, to: foundation, cards: [card]);
        }
      }
    }

    for (final pile in tableau) {
      if (pile.isEmpty) continue;
      final card = pile.topCard!;
      for (final foundation in foundations) {
        if (canStackOnFoundationWithBase(card, foundation)) {
          return (from: pile, to: foundation, cards: [card]);
        }
      }
    }

    if (!reserve.isEmpty) {
      final card = reserve.topCard!;
      for (final foundation in foundations) {
        if (canStackOnFoundationWithBase(card, foundation)) {
          return (from: reserve, to: foundation, cards: [card]);
        }
      }
    }

    // Priority 3: Tableau building
    for (final fromPile in tableau) {
      if (fromPile.isEmpty) continue;

      for (int i = 0; i < fromPile.cards.length; i++) {
        final card = fromPile.cardAt(i);
        if (card == null || !card.faceUp) continue;

        final cardsToMove = fromPile.cards.sublist(i);
        if (!_isValidTableauSequence(cardsToMove)) continue;

        for (final toPile in tableau) {
          if (toPile == fromPile) continue;
          if (toPile.isEmpty) continue;
          if (isValidMove(fromPile, toPile, cardsToMove)) {
            return (from: fromPile, to: toPile, cards: cardsToMove);
          }
        }
      }
    }

    // Priority 4: Waste to tableau
    if (!waste.isEmpty) {
      final card = waste.topCard!;
      for (final pile in tableau) {
        if (isValidMove(waste, pile, [card])) {
          return (from: waste, to: pile, cards: [card]);
        }
      }
    }

    // Priority 5: Reserve to tableau
    if (!reserve.isEmpty) {
      final card = reserve.topCard!;
      for (final pile in tableau) {
        if (isValidMove(reserve, pile, [card])) {
          return (from: reserve, to: pile, cards: [card]);
        }
      }
    }

    // Priority 6: Draw from stock
    if (!stock.isEmpty) {
      return (from: stock, to: waste, cards: []);
    }

    return null;
  }

  @override
  void applyDifficulty(Difficulty difficulty) {
    // Canfield doesn't have standard difficulty variations
  }

  @override
  void configure(SettingsProvider settings) {
    // Canfield doesn't have configurable settings
  }

  @override
  SolverState<CanfieldMove>? getSolverState() {
    if (_baseRank == null) return null;

    // Convert card to solver format: "rankSuit" (e.g., "1H" for Ace of Hearts)
    String cardToString(PlayingCard card) {
      return '${card.value}${card.suit.name[0].toUpperCase()}';
    }

    // Convert tableau piles
    final tableauCards = <List<CanfieldCardInfo>>[];
    for (final pile in tableau) {
      tableauCards.add(
        pile.cards
            .map((c) => CanfieldCardInfo(cardToString(c), c.faceUp))
            .toList(),
      );
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

    // Convert reserve
    final reserveCards = reserve.cards
        .map((c) => CanfieldCardInfo(cardToString(c), c.faceUp))
        .toList();

    // Convert stock
    final stockCards = stock.cards.map(cardToString).toList();

    // Get waste top
    final wasteTopCard = waste.isEmpty ? null : cardToString(waste.topCard!);

    return CanfieldSolverState(
      tableau: tableauCards,
      foundations: foundationTops,
      reserve: reserveCards,
      stock: stockCards,
      wasteTop: wasteTopCard,
      baseRank: _baseRank!.index + 1, // Convert Rank enum to value (1-13)
    );
  }

  @override
  Pile? getPile(PileType type) {
    switch (type) {
      case PileType.stock:
        return stock;
      case PileType.waste:
        return waste;
      case PileType.reserve:
        return reserve;
      default:
        return null;
    }
  }

  @override
  List<Pile> get focusablePiles {
    final piles = <Pile>[stock];
    if (!waste.isEmpty) piles.add(waste);
    if (!reserve.isEmpty) piles.add(reserve);
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
    if (pile.type == PileType.waste && pile.topCard == card) {
      return [card];
    }
    if (pile.type == PileType.reserve && pile.topCard == card) {
      return [card];
    }
    if (pile.type == PileType.tableau) {
      final index = pile.indexOfCard(card);
      if (index >= 0 && card.faceUp) {
        final cards = pile.cards.sublist(index);
        if (_isValidTableauSequence(cards)) {
          return cards;
        }
      }
    }
    return null;
  }
}
