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
import '../../ai/games/golf_solver_state.dart';

/// Golf Solitaire implementation.
///
/// Setup: 7 Columns of 5 cards each (all face up), Stock, 1 Waste pile.
/// Moves: Move tableau card to Waste if it is +/- 1 Rank. (Standard: No wrapping K-A).
/// Win: Clear the tableau.
class GolfGame extends SolitaireGameBase {
  late Pile stock;
  late Pile waste;
  late List<Pile> tableau;

  final List<Move> _moveHistory = [];
  final List<Move> _redoStack = [];
  int _moveCount = 0;

  /// Whether King-Ace wrapping is allowed
  bool allowWrapping;

  GolfGame({this.allowWrapping = false}) {
    _initializePiles();
  }

  void _initializePiles() {
    stock = Pile(type: PileType.stock);
    waste = Pile(type: PileType.waste);
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

    // Deal 5 cards to each of 7 columns (35 cards), all face up
    for (int col = 0; col < 7; col++) {
      for (int row = 0; row < 5; row++) {
        final card = deck.draw()!;
        card.faceUp = true;
        tableau[col].addCard(card);
      }
    }

    // Deal 1 card to waste to start
    final wasteCard = deck.draw()!;
    wasteCard.faceUp = true;
    waste.addCard(wasteCard);

    // Remaining 16 cards go to stock (face down)
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
  List<Pile> get allPiles => [stock, waste, ...tableau];

  @override
  int get moveCount => _moveCount;

  @override
  List<Move> get moveHistory => List.unmodifiable(_moveHistory);

  @override
  List<Move> get redoStack => List.unmodifiable(_redoStack);

  @override
  bool get canRedo => _redoStack.isNotEmpty;

  @override
  GameType get gameType => GameType.golf;

  @override
  int get deckSize => 52;

  @override
  LayoutConfig get layoutConfig => const LayoutConfig(
        tableauCount: 7,
        foundationCount: 0,
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
  List<Pile> get foundationPiles => [];

  @override
  List<Pile> get tableauPiles => tableau;

  // ==========================================================================
  // Move Validation
  // ==========================================================================

  /// Check if card can be played to waste (is +/- 1 rank)
  bool canPlayToWaste(PlayingCard card) {
    if (waste.isEmpty) return false;
    final wasteTop = waste.topCard!;

    final cardValue = card.value;
    final wasteValue = wasteTop.value;

    final diff = (cardValue - wasteValue).abs();

    if (allowWrapping) {
      return diff == 1 || diff == 12; // 12 handles K-A wrapping
    } else {
      // Standard Golf: No wrapping, and some variants don't allow playing on King
      return diff == 1;
    }
  }

  @override
  bool isValidMove(Pile from, Pile to, List<PlayingCard> cards) {
    if (cards.isEmpty) return false;
    if (cards.length != 1) return false;

    // Only moves to waste are valid
    if (to.type != PileType.waste) return false;

    final card = cards.first;

    // Must be from tableau top card
    if (from.type != PileType.tableau) return false;
    if (from.topCard != card) return false;

    // Must be +/- 1 rank
    return canPlayToWaste(card);
  }

  @override
  Move? executeMove(Pile from, Pile to, List<PlayingCard> cards) {
    if (!isValidMove(from, to, cards)) return null;

    final card = cards.first;
    from.removeTop();
    waste.addCard(card);

    final move = Move(
      fromPile: from,
      toPile: waste,
      cards: [card],
      flippedCard: false,
    );
    _moveHistory.add(move);
    _redoStack.clear();
    _moveCount++;

    return move;
  }

  @override
  Move? tapStock() {
    if (stock.isEmpty) {
      // Golf typically doesn't allow recycling
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

    // Handle tableau to waste move undo
    final card = waste.removeTop()!;
    move.fromPile.addCard(card);
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

    // Handle tableau to waste redo
    final card = move.fromPile.removeTop()!;
    waste.addCard(card);
    _moveHistory.add(move);
    return true;
  }

  @override
  bool checkWin() {
    // Win when all tableau piles are empty
    return tableau.every((pile) => pile.isEmpty);
  }

  @override
  bool canAutoComplete() {
    return false; // Golf doesn't support auto-complete
  }

  @override
  bool autoCompleteStep() {
    return false;
  }

  @override
  List<Pile> getValidDestinations(Pile from, List<PlayingCard> cards) {
    if (cards.isEmpty || cards.length != 1) return [];

    if (from.type == PileType.tableau && from.topCard == cards.first) {
      if (canPlayToWaste(cards.first)) {
        return [waste];
      }
    }
    return [];
  }

  @override
  bool canDrawFromStock() {
    return !stock.isEmpty;
  }

  @override
  bool hasValidWasteMoves() {
    // In Golf, we check if any tableau card can be played
    for (final pile in tableau) {
      if (pile.isEmpty) continue;
      if (canPlayToWaste(pile.topCard!)) return true;
    }
    return false;
  }

  @override
  bool hasValidTableauMoves() {
    return hasValidWasteMoves();
  }

  @override
  bool get isLost {
    // Lost when no moves and stock is empty
    if (hasValidWasteMoves()) return false;
    return stock.isEmpty;
  }

  @override
  Pile? findBestAutoMoveDestination(Pile fromPile, List<PlayingCard> cards) {
    if (cards.isEmpty || cards.length != 1) return null;

    if (fromPile.type == PileType.tableau && fromPile.topCard == cards.first) {
      if (canPlayToWaste(cards.first)) {
        return waste;
      }
    }
    return null;
  }

  @override
  bool canAutoMove(Pile pile, PlayingCard card) {
    if (pile.type == PileType.tableau) {
      return pile.topCard == card;
    }
    return false;
  }

  @override
  ({Pile from, Pile to, List<PlayingCard> cards})? getHint() {
    // Find any card that can be played to waste
    for (final pile in tableau) {
      if (pile.isEmpty) continue;
      final card = pile.topCard!;
      if (canPlayToWaste(card)) {
        return (from: pile, to: waste, cards: [card]);
      }
    }

    // Suggest drawing from stock
    if (!stock.isEmpty) {
      return (from: stock, to: waste, cards: []);
    }

    return null;
  }

  @override
  void applyDifficulty(Difficulty difficulty) {
    // Could enable/disable wrapping based on difficulty
  }

  @override
  void configure(SettingsProvider settings) {
    // Could configure wrapping based on settings
  }

  @override
  SolverState<GolfMove>? getSolverState() {
    // Convert card to solver format: "rankSuit" (e.g., "1H" for Ace of Hearts)
    String cardToString(PlayingCard card) {
      return '${card.value}${card.suit.name[0].toUpperCase()}';
    }

    // Convert tableau piles
    final tableauCards = <List<String>>[];
    for (final pile in tableau) {
      tableauCards.add(pile.cards.map(cardToString).toList());
    }

    // Convert stock (face down, but we track them for the solver)
    final stockCards = stock.cards.map(cardToString).toList();

    // Get waste top
    final wasteTopCard = waste.isEmpty ? null : cardToString(waste.topCard!);

    return GolfSolverState(
      tableau: tableauCards,
      stock: stockCards,
      wasteTop: wasteTopCard,
      allowWrapping: allowWrapping,
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
    final piles = <Pile>[stock, waste];
    piles.addAll(tableau.where((p) => !p.isEmpty));
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
    if (pile.type == PileType.tableau && pile.topCard == card) {
      return [card];
    }
    return null;
  }

  /// Get the current "score" (cards remaining in tableau)
  int get score => tableau.fold(0, (sum, pile) => sum + pile.length);
}
