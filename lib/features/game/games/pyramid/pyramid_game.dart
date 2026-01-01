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
import '../../ai/games/pyramid_solver_state.dart';

/// Pyramid Solitaire implementation.
///
/// Setup: 28 cards arranged in a pyramid (rows 1-7), Stock, Waste, 1 Discard pile.
/// Moves: Match pairs of cards summing to 13 (K=13 removes itself, Q=12, J=11, A=1).
/// Constraint: Only uncovered cards (no cards overlapping them) are selectable.
class PyramidGame extends SolitaireGameBase {
  late Pile stock;
  late Pile waste;
  late Pile discard;
  late List<Pile> pyramidPiles; // 28 piles, one for each pyramid position

  final List<Move> _moveHistory = [];
  final List<Move> _redoStack = [];
  int _moveCount = 0;

  /// Track which cards are covering which positions
  /// pyramidCovers[i] contains indices of cards that card i is covering
  final List<List<int>> _pyramidCovers = [];

  /// Track the row and column for each pyramid position
  final List<({int row, int col})> _pyramidPositions = [];

  PyramidGame() {
    _initializePiles();
    _buildPyramidStructure();
  }

  void _initializePiles() {
    stock = Pile(type: PileType.stock);
    waste = Pile(type: PileType.waste);
    discard = Pile(type: PileType.discard);
    pyramidPiles =
        List.generate(28, (i) => Pile(type: PileType.pyramid, index: i));
  }

  /// Build the pyramid structure - determines which cards cover which
  void _buildPyramidStructure() {
    _pyramidCovers.clear();
    _pyramidPositions.clear();

    // Pyramid has 7 rows, row i has i+1 cards
    // Card indices: row 0: [0], row 1: [1,2], row 2: [3,4,5], etc.
    for (int row = 0; row < 7; row++) {
      for (int col = 0; col <= row; col++) {
        _pyramidPositions.add((row: row, col: col));

        // Cards this position covers (in the row below)
        final covers = <int>[];
        if (row < 6) {
          // Not the bottom row
          final nextRowStart = _getRowStartIndex(row + 1);
          covers.add(nextRowStart + col); // Card directly below-left
          covers.add(nextRowStart + col + 1); // Card directly below-right
        }
        _pyramidCovers.add(covers);
      }
    }
  }

  /// Get the starting index for a given row
  int _getRowStartIndex(int row) {
    // Sum of arithmetic series: 0 + 1 + 2 + ... + (row-1) = row*(row-1)/2
    // But we need indices: row 0 starts at 0, row 1 at 1, row 2 at 3, etc.
    return (row * (row + 1)) ~/ 2;
  }

  /// Check if a pyramid card is uncovered (can be selected)
  bool isCardUncovered(int pyramidIndex) {
    if (pyramidIndex < 0 || pyramidIndex >= 28) return false;
    final pile = pyramidPiles[pyramidIndex];
    if (pile.isEmpty) return false;

    // Find which cards are covering this one
    // A card at position i is covered by cards at positions that have i in their covers list
    for (int i = 0; i < 28; i++) {
      if (_pyramidCovers[i].contains(pyramidIndex) &&
          !pyramidPiles[i].isEmpty) {
        return false;
      }
    }
    return true;
  }

  @override
  void initialize({Random? random}) {
    _initializePiles();
    _moveHistory.clear();
    _redoStack.clear();
    _moveCount = 0;

    final deck = Deck();
    deck.shuffle(random ?? Random());

    // Deal 28 cards to the pyramid (all face up)
    for (int i = 0; i < 28; i++) {
      final card = deck.draw()!;
      card.faceUp = true;
      pyramidPiles[i].addCard(card);
    }

    // Remaining 24 cards go to stock (face down)
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
  List<Pile> get allPiles => [stock, waste, discard, ...pyramidPiles];

  @override
  int get moveCount => _moveCount;

  @override
  List<Move> get moveHistory => List.unmodifiable(_moveHistory);

  @override
  List<Move> get redoStack => List.unmodifiable(_redoStack);

  @override
  bool get canRedo => _redoStack.isNotEmpty;

  @override
  GameType get gameType => GameType.pyramid;

  @override
  int get deckSize => 52;

  @override
  LayoutConfig get layoutConfig => const LayoutConfig(
        tableauCount: 0,
        foundationCount: 1,
        hasStock: true,
        hasWaste: true,
        layoutType: LayoutType.stack,
      );

  // ==========================================================================
  // Pile Accessors (GameInterface)
  // ==========================================================================

  @override
  Pile? get stockPile => stock;

  @override
  Pile? get wastePile => waste;

  @override
  List<Pile> get foundationPiles => [discard];

  @override
  List<Pile> get tableauPiles => pyramidPiles;

  /// Get the pyramid piles
  List<Pile> get pyramidCards => pyramidPiles;

  // ==========================================================================
  // Pair Matching Logic
  // ==========================================================================

  /// Check if two cards sum to 13
  bool cardsSumTo13(PlayingCard card1, PlayingCard card2) {
    return card1.value + card2.value == 13;
  }

  /// Check if a single card is a King (value 13, removes itself)
  bool isKing(PlayingCard card) {
    return card.rank == Rank.king;
  }

  /// Check if a card can be matched (is uncovered in pyramid, or is waste top)
  bool canMatch(Pile pile, PlayingCard card) {
    if (pile.type == PileType.pyramid) {
      final index = pyramidPiles.indexOf(pile);
      return isCardUncovered(index) && pile.topCard == card;
    }
    if (pile.type == PileType.waste) {
      return pile.topCard == card;
    }
    return false;
  }

  @override
  bool isValidMove(Pile from, Pile to, List<PlayingCard> cards) {
    if (cards.isEmpty) return false;

    // Only moves to discard pile are valid
    if (to.type != PileType.discard) return false;

    final card = cards.first;

    // King removes itself
    if (cards.length == 1 && isKing(card)) {
      return canMatch(from, card);
    }

    // Two cards that sum to 13
    if (cards.length == 2) {
      return cardsSumTo13(cards[0], cards[1]);
    }

    return false;
  }

  /// Special method for pairing two cards from different piles
  Move? matchPair(
      Pile pile1, PlayingCard card1, Pile pile2, PlayingCard card2) {
    if (!canMatch(pile1, card1) || !canMatch(pile2, card2)) return null;
    if (!cardsSumTo13(card1, card2)) return null;

    // Remove both cards
    pile1.removeTop();
    pile2.removeTop();

    // Add to discard
    card1.faceUp = true;
    card2.faceUp = true;
    discard.addCard(card1);
    discard.addCard(card2);

    final move = Move(
      fromPile: pile1,
      toPile: discard,
      cards: [card1, card2],
      flippedCard: false,
      extraData: {'secondPile': pile2},
    );
    _moveHistory.add(move);
    _redoStack.clear();
    _moveCount++;

    return move;
  }

  /// Remove a King (it matches itself)
  Move? removeKing(Pile pile, PlayingCard card) {
    if (!canMatch(pile, card)) return null;
    if (!isKing(card)) return null;

    pile.removeTop();
    card.faceUp = true;
    discard.addCard(card);

    final move = Move(
      fromPile: pile,
      toPile: discard,
      cards: [card],
      flippedCard: false,
    );
    _moveHistory.add(move);
    _redoStack.clear();
    _moveCount++;

    return move;
  }

  @override
  Move? executeMove(Pile from, Pile to, List<PlayingCard> cards) {
    if (!isValidMove(from, to, cards)) return null;

    if (cards.length == 1 && isKing(cards.first)) {
      return removeKing(from, cards.first);
    }

    // For pair matching, we need both piles
    // This method is mainly for single-source moves
    return null;
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

    // Handle pair removal undo
    if (move.cards.length == 2) {
      // Remove both from discard
      discard.removeTop();
      discard.removeTop();

      // Put them back
      final secondPile = move.extraData?['secondPile'] as Pile?;
      if (secondPile != null) {
        move.fromPile.addCard(move.cards[0]);
        secondPile.addCard(move.cards[1]);
      }
      return true;
    }

    // Handle King removal undo
    if (move.cards.length == 1) {
      discard.removeTop();
      move.fromPile.addCard(move.cards[0]);
      return true;
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

    // Handle pair removal redo
    if (move.cards.length == 2) {
      final secondPile = move.extraData?['secondPile'] as Pile?;
      if (secondPile != null) {
        move.fromPile.removeTop();
        secondPile.removeTop();
        discard.addCards(move.cards);
      }
      _moveHistory.add(move);
      return true;
    }

    // Handle King removal redo
    if (move.cards.length == 1) {
      move.fromPile.removeTop();
      discard.addCard(move.cards[0]);
      _moveHistory.add(move);
      return true;
    }

    return true;
  }

  @override
  bool checkWin() {
    // Win when all pyramid cards are removed
    return pyramidPiles.every((pile) => pile.isEmpty);
  }

  @override
  bool canAutoComplete() {
    // Pyramid doesn't really have auto-complete
    return false;
  }

  @override
  bool autoCompleteStep() {
    return false;
  }

  @override
  List<Pile> getValidDestinations(Pile from, List<PlayingCard> cards) {
    if (cards.isEmpty) return [];
    final card = cards.first;

    // Kings can go directly to discard
    if (isKing(card) && canMatch(from, card)) {
      return [discard];
    }

    // Find matching cards for pairing
    return [discard]; // All valid pairs go to discard
  }

  /// Get all cards that can be paired with the given card
  List<({Pile pile, PlayingCard card})> getMatchingCards(
      Pile fromPile, PlayingCard card) {
    final matches = <({Pile pile, PlayingCard card})>[];
    final targetValue = 13 - card.value;

    // Check pyramid cards
    for (int i = 0; i < 28; i++) {
      if (pyramidPiles[i].isEmpty) continue;
      if (!isCardUncovered(i)) continue;
      final pyramidCard = pyramidPiles[i].topCard!;
      if (pyramidCard == card) continue; // Can't match with self
      if (pyramidCard.value == targetValue) {
        matches.add((pile: pyramidPiles[i], card: pyramidCard));
      }
    }

    // Check waste
    if (!waste.isEmpty && waste.topCard != card) {
      if (waste.topCard!.value == targetValue) {
        matches.add((pile: waste, card: waste.topCard!));
      }
    }

    return matches;
  }

  @override
  bool canDrawFromStock() {
    return !stock.isEmpty || !waste.isEmpty;
  }

  @override
  bool hasValidWasteMoves() {
    if (waste.isEmpty) return false;
    final card = waste.topCard!;

    // Check for King
    if (isKing(card)) return true;

    // Check for matching pyramid cards
    return getMatchingCards(waste, card).isNotEmpty;
  }

  @override
  bool hasValidTableauMoves() {
    // Check pyramid for Kings and matching pairs
    for (int i = 0; i < 28; i++) {
      if (pyramidPiles[i].isEmpty) continue;
      if (!isCardUncovered(i)) continue;
      final card = pyramidPiles[i].topCard!;

      // Kings can always be removed
      if (isKing(card)) return true;

      // Check for matching cards
      if (getMatchingCards(pyramidPiles[i], card).isNotEmpty) return true;
    }

    return false;
  }

  @override
  bool get isLost {
    // Check if any moves are possible
    if (hasAnyMove()) return false;

    // Check if stock can be cycled
    if (!stock.isEmpty) return false;

    return true;
  }

  @override
  Pile? findBestAutoMoveDestination(Pile fromPile, List<PlayingCard> cards) {
    if (cards.isEmpty) return null;
    final card = cards.first;

    // Kings go to discard
    if (isKing(card) && canMatch(fromPile, card)) {
      return discard;
    }

    return null;
  }

  @override
  bool canAutoMove(Pile pile, PlayingCard card) {
    // In Pyramid, any uncovered card can be auto-moved (for matching)
    if (pile.type == PileType.pyramid) {
      final index = pyramidPiles.indexOf(pile);
      return isCardUncovered(index) && pile.topCard == card;
    }
    if (pile.type == PileType.waste) {
      return pile.topCard == card;
    }
    return false;
  }

  @override
  ({Pile from, Pile to, List<PlayingCard> cards})? getHint() {
    // Priority 1: Remove Kings
    for (int i = 0; i < 28; i++) {
      if (pyramidPiles[i].isEmpty) continue;
      if (!isCardUncovered(i)) continue;
      final card = pyramidPiles[i].topCard!;
      if (isKing(card)) {
        return (from: pyramidPiles[i], to: discard, cards: [card]);
      }
    }

    if (!waste.isEmpty && isKing(waste.topCard!)) {
      return (from: waste, to: discard, cards: [waste.topCard!]);
    }

    // Priority 2: Match pairs in pyramid
    for (int i = 0; i < 28; i++) {
      if (pyramidPiles[i].isEmpty) continue;
      if (!isCardUncovered(i)) continue;
      final card = pyramidPiles[i].topCard!;
      final matches = getMatchingCards(pyramidPiles[i], card);
      if (matches.isNotEmpty) {
        return (
          from: pyramidPiles[i],
          to: discard,
          cards: [card, matches.first.card]
        );
      }
    }

    // Priority 3: Match waste with pyramid
    if (!waste.isEmpty) {
      final card = waste.topCard!;
      final matches = getMatchingCards(waste, card);
      if (matches.isNotEmpty) {
        return (from: waste, to: discard, cards: [card, matches.first.card]);
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
    // Pyramid typically doesn't have difficulty settings
  }

  @override
  void configure(SettingsProvider settings) {
    // Pyramid doesn't have configurable settings
  }

  @override
  PyramidSolverState? getSolverState() {
    // Convert card to solver format
    String cardToString(PlayingCard card) {
      return '${card.value}${card.suit.name[0].toUpperCase()}';
    }

    // Convert pyramid piles
    final solverPyramid = pyramidPiles.map((pile) {
      if (pile.isEmpty) return null;
      return cardToString(pile.topCard!);
    }).toList();

    // Convert stock
    final solverStock = stock.cards.map((c) => cardToString(c)).toList();

    // Convert waste
    final solverWaste = waste.cards.map((c) => cardToString(c)).toList();

    return PyramidSolverState(
      pyramid: solverPyramid,
      stock: solverStock,
      waste: solverWaste,
    );
  }

  @override
  Pile? getPile(PileType type) {
    switch (type) {
      case PileType.stock:
        return stock;
      case PileType.waste:
        return waste;
      case PileType.discard:
        return discard;
      default:
        return null;
    }
  }

  @override
  List<Pile> get focusablePiles {
    final piles = <Pile>[stock];
    if (!waste.isEmpty) piles.add(waste);
    // Add uncovered pyramid cards
    for (int i = 0; i < 28; i++) {
      if (!pyramidPiles[i].isEmpty && isCardUncovered(i)) {
        piles.add(pyramidPiles[i]);
      }
    }
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
    // Only top cards of uncovered pyramid piles or waste can be selected
    if (pile.type == PileType.pyramid) {
      final index = pyramidPiles.indexOf(pile);
      if (isCardUncovered(index) && pile.topCard == card) {
        return [card];
      }
      return null;
    }
    if (pile.type == PileType.waste && pile.topCard == card) {
      return [card];
    }
    return null;
  }

  /// Get pyramid position for display purposes
  ({int row, int col})? getPyramidPosition(int index) {
    if (index < 0 || index >= 28) return null;
    return _pyramidPositions[index];
  }
}
