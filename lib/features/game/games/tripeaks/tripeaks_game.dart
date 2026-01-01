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
import '../../ai/games/tripeaks_solver_state.dart';

/// TriPeaks Solitaire implementation.
///
/// Setup: 3 Pyramids with overlapping bases (28 cards total), Stock, 1 Waste pile.
/// Moves: Move tableau card to Waste if it is +/- 1 Rank (A wraps to K).
/// Win: Clear all three peaks.
class TriPeaksGame extends SolitaireGameBase {
  late Pile stock;
  late Pile waste;
  late List<Pile> peakPiles; // 28 piles for the tri-peaks structure

  final List<Move> _moveHistory = [];
  final List<Move> _redoStack = [];
  int _moveCount = 0;

  /// Track which cards are covering which positions
  /// Similar to Pyramid, but with 3 overlapping peaks
  final List<List<int>> _peakCovers = [];

  /// Track position info for each pile
  final List<({int peak, int row, int col})> _peakPositions = [];

  TriPeaksGame() {
    _initializePiles();
    _buildPeakStructure();
  }

  void _initializePiles() {
    stock = Pile(type: PileType.stock);
    waste = Pile(type: PileType.waste);
    peakPiles =
        List.generate(28, (i) => Pile(type: PileType.pyramid, index: i));
  }

  /// Build the tri-peaks structure
  /// Layout:
  ///       0       1       2          (Row 0: 3 peak tops)
  ///      3 4     5 6     7 8        (Row 1: 6 cards)
  ///     9 10 11 12 13 14 15 16 17   (Row 2: 9 cards, overlapping)
  ///    18 19 20 21 22 23 24 25 26 27 (Row 3: 10 cards, bottom row)
  void _buildPeakStructure() {
    _peakCovers.clear();
    _peakPositions.clear();

    // Initialize all 28 positions
    for (int i = 0; i < 28; i++) {
      _peakCovers.add([]);
      _peakPositions.add((peak: 0, row: 0, col: 0));
    }

    // Row 0: Peak tops (indices 0, 1, 2)
    _peakPositions[0] = (peak: 0, row: 0, col: 0);
    _peakPositions[1] = (peak: 1, row: 0, col: 0);
    _peakPositions[2] = (peak: 2, row: 0, col: 0);
    _peakCovers[0] = [3, 4];
    _peakCovers[1] = [5, 6];
    _peakCovers[2] = [7, 8];

    // Row 1: (indices 3-8)
    _peakPositions[3] = (peak: 0, row: 1, col: 0);
    _peakPositions[4] = (peak: 0, row: 1, col: 1);
    _peakPositions[5] = (peak: 1, row: 1, col: 0);
    _peakPositions[6] = (peak: 1, row: 1, col: 1);
    _peakPositions[7] = (peak: 2, row: 1, col: 0);
    _peakPositions[8] = (peak: 2, row: 1, col: 1);
    _peakCovers[3] = [9, 10];
    _peakCovers[4] = [10, 11];
    _peakCovers[5] = [12, 13];
    _peakCovers[6] = [13, 14];
    _peakCovers[7] = [15, 16];
    _peakCovers[8] = [16, 17];

    // Row 2: (indices 9-17)
    for (int i = 0; i < 9; i++) {
      final peak = i < 3 ? 0 : (i < 6 ? 1 : 2);
      _peakPositions[9 + i] = (peak: peak, row: 2, col: i);
      _peakCovers[9 + i] = [18 + i, 18 + i + 1];
    }

    // Row 3: Bottom row (indices 18-27) - not covering anything
    for (int i = 0; i < 10; i++) {
      final peak = i < 4 ? 0 : (i < 7 ? 1 : 2);
      _peakPositions[18 + i] = (peak: peak, row: 3, col: i);
      _peakCovers[18 + i] = []; // Bottom row covers nothing
    }
  }

  /// Check if a card is uncovered (can be selected)
  bool isCardUncovered(int peakIndex) {
    if (peakIndex < 0 || peakIndex >= 28) return false;
    final pile = peakPiles[peakIndex];
    if (pile.isEmpty) return false;

    // A card is uncovered if all cards it covers are empty
    for (final coveredIndex in _peakCovers[peakIndex]) {
      if (!peakPiles[coveredIndex].isEmpty) {
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

    // Deal 28 cards to the peaks
    // Top 18 cards are face-down, bottom 10 are face-up (row 3)
    for (int i = 0; i < 28; i++) {
      final card = deck.draw()!;
      // Bottom row (18-27) is face up, rest face down initially
      // But cards become face up when uncovered
      card.faceUp = i >= 18;
      peakPiles[i].addCard(card);
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
  List<Pile> get allPiles => [stock, waste, ...peakPiles];

  @override
  int get moveCount => _moveCount;

  @override
  List<Move> get moveHistory => List.unmodifiable(_moveHistory);

  @override
  List<Move> get redoStack => List.unmodifiable(_redoStack);

  @override
  bool get canRedo => _redoStack.isNotEmpty;

  @override
  GameType get gameType => GameType.triPeaks;

  @override
  int get deckSize => 52;

  @override
  LayoutConfig get layoutConfig => const LayoutConfig(
        tableauCount: 0,
        foundationCount: 0,
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
  List<Pile> get foundationPiles => [];

  @override
  List<Pile> get tableauPiles => peakPiles;

  // ==========================================================================
  // Move Validation
  // ==========================================================================

  /// Check if card can be played to waste (is +/- 1 rank, wrapping K-A)
  bool canPlayToWaste(PlayingCard card) {
    if (waste.isEmpty) return false;
    final wasteTop = waste.topCard!;

    // Get values with A=1, K=13
    final cardValue = card.value;
    final wasteValue = wasteTop.value;

    // Check +/- 1 with wrapping
    final diff = (cardValue - wasteValue).abs();
    return diff == 1 || diff == 12; // 12 handles K-A wrapping
  }

  @override
  bool isValidMove(Pile from, Pile to, List<PlayingCard> cards) {
    if (cards.isEmpty) return false;
    if (cards.length != 1) return false;

    // Only moves to waste are valid
    if (to.type != PileType.waste) return false;

    final card = cards.first;

    // Must be from peaks
    if (from.type != PileType.pyramid) return false;

    // Card must be uncovered
    final index = peakPiles.indexOf(from);
    if (!isCardUncovered(index)) return false;

    // Must be +/- 1 rank
    return canPlayToWaste(card);
  }

  @override
  Move? executeMove(Pile from, Pile to, List<PlayingCard> cards) {
    if (!isValidMove(from, to, cards)) return null;

    final card = cards.first;
    from.removeTop();
    card.faceUp = true;
    waste.addCard(card);

    // Flip newly uncovered cards
    _flipUncoveredCards();

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

  /// Flip any cards that are now uncovered
  void _flipUncoveredCards() {
    for (int i = 0; i < 28; i++) {
      if (peakPiles[i].isEmpty) continue;
      if (!peakPiles[i].topCard!.faceUp && isCardUncovered(i)) {
        peakPiles[i].topCard!.faceUp = true;
      }
    }
  }

  @override
  Move? tapStock() {
    if (stock.isEmpty) {
      // TriPeaks typically doesn't allow recycling
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

    // Handle peak to waste move undo
    final card = waste.removeTop()!;
    move.fromPile.addCard(card);

    // Note: We don't need to unflip cards as they stay face-up once revealed
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

    // Handle peak to waste redo
    final card = move.fromPile.removeTop()!;
    card.faceUp = true;
    waste.addCard(card);
    _flipUncoveredCards();
    _moveHistory.add(move);
    return true;
  }

  @override
  bool checkWin() {
    // Win when all peak piles are empty
    return peakPiles.every((pile) => pile.isEmpty);
  }

  @override
  bool canAutoComplete() {
    return false; // TriPeaks doesn't support auto-complete
  }

  @override
  bool autoCompleteStep() {
    return false;
  }

  @override
  List<Pile> getValidDestinations(Pile from, List<PlayingCard> cards) {
    if (cards.isEmpty || cards.length != 1) return [];

    if (from.type == PileType.pyramid) {
      final index = peakPiles.indexOf(from);
      if (!isCardUncovered(index)) return [];
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
    // Check if any uncovered card can be played
    for (int i = 0; i < 28; i++) {
      if (peakPiles[i].isEmpty) continue;
      if (!isCardUncovered(i)) continue;
      if (canPlayToWaste(peakPiles[i].topCard!)) return true;
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

    if (fromPile.type == PileType.pyramid) {
      final index = peakPiles.indexOf(fromPile);
      if (!isCardUncovered(index)) return null;
      if (canPlayToWaste(cards.first)) {
        return waste;
      }
    }
    return null;
  }

  @override
  bool canAutoMove(Pile pile, PlayingCard card) {
    if (pile.type == PileType.pyramid) {
      final index = peakPiles.indexOf(pile);
      return isCardUncovered(index) && pile.topCard == card;
    }
    return false;
  }

  @override
  ({Pile from, Pile to, List<PlayingCard> cards})? getHint() {
    // Find any card that can be played to waste
    for (int i = 0; i < 28; i++) {
      if (peakPiles[i].isEmpty) continue;
      if (!isCardUncovered(i)) continue;
      final card = peakPiles[i].topCard!;
      if (canPlayToWaste(card)) {
        return (from: peakPiles[i], to: waste, cards: [card]);
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
    // TriPeaks typically doesn't have difficulty settings
  }

  @override
  void configure(SettingsProvider settings) {
    // TriPeaks doesn't have configurable settings
  }

  @override
  SolverState<TriPeaksMove>? getSolverState() {
    // Convert card to solver format: "rankSuit" (e.g., "1H" for Ace of Hearts)
    String cardToString(PlayingCard card) {
      return '${card.value}${card.suit.name[0].toUpperCase()}';
    }

    // Convert peak piles to list of card strings (null = empty)
    final peakCards = <String?>[];
    for (int i = 0; i < 28; i++) {
      if (peakPiles[i].isEmpty) {
        peakCards.add(null);
      } else {
        peakCards.add(cardToString(peakPiles[i].topCard!));
      }
    }

    // Convert stock
    final stockCards = stock.cards.map(cardToString).toList();

    // Get waste top
    final wasteTopCard = waste.isEmpty ? null : cardToString(waste.topCard!);

    return TriPeaksSolverState(
      peaks: peakCards,
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
    final piles = <Pile>[stock, waste];
    // Add uncovered peak cards
    for (int i = 0; i < 28; i++) {
      if (!peakPiles[i].isEmpty && isCardUncovered(i)) {
        piles.add(peakPiles[i]);
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
    if (pile.type == PileType.pyramid) {
      final index = peakPiles.indexOf(pile);
      if (isCardUncovered(index) && pile.topCard == card) {
        return [card];
      }
      return null;
    }
    return null;
  }

  /// Get peak position for display purposes
  ({int peak, int row, int col})? getPeakPosition(int index) {
    if (index < 0 || index >= 28) return null;
    return _peakPositions[index];
  }
}
