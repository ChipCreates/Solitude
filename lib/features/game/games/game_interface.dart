import 'dart:math';
import '../models/card.dart';
import '../models/pile.dart';
import '../models/move.dart';
import 'package:solitude/features/settings/models/difficulty.dart';
import 'package:solitude/features/settings/services/settings_provider.dart';
import '../ai/abstract_solver.dart';

/// Supported game types - used for routing to correct layout strategies
enum GameType {
  klondike,
  spider,
  pyramid,
  golf,
  freecell,
  triPeaks,
  yukon,
  fortyThieves,
  canfield,
  scorpion,
  // Future games: pyramid, golf, freecell, triPeaks, yukon, etc.
}

/// Abstract interface that all solitaire game types must implement.
/// This allows for future expansion to Spider, FreeCell, etc.
abstract class GameInterface {
  // ==========================================================================
  // Game Identity
  // ==========================================================================

  /// The type of game - used for layout strategy routing.
  /// This replaces pile-count based detection with explicit type identification.
  GameType get gameType;

  /// Number of cards in the deck(s) used by this game.
  /// Standard deck = 52, Spider (2 decks) = 104, Pyramid = 28 in play, etc.
  /// Used for game-agnostic scoring calculations.
  int get deckSize;
  // ==========================================================================
  // Pile Accessors
  // ==========================================================================

  /// Get the stock pile (if any). Returns null for games without stock.
  Pile? get stockPile;

  /// Get the waste pile (if any). Returns null for games without waste.
  Pile? get wastePile;

  /// Get foundation piles. Empty list for games without foundations.
  List<Pile> get foundationPiles;

  /// Get tableau piles.
  List<Pile> get tableauPiles;

  // ==========================================================================
  // Lifecycle
  // ==========================================================================

  /// Initialize a new game with shuffled deck.
  /// Optionally accepts a [Random] instance for deterministic testing.
  void initialize({Random? random});

  /// Reset the current game to its initial state
  void reset();

  /// Get all piles in the game
  List<Pile> get allPiles;

  /// Check if moving cards from one pile to another is valid
  bool isValidMove(Pile from, Pile to, List<PlayingCard> cards);

  /// Execute a move (assumes validity already checked)
  Move? executeMove(Pile from, Pile to, List<PlayingCard> cards);

  /// Undo the last move
  bool undo();

  /// Check if the game is won
  bool checkWin();

  /// Check if auto-complete is possible (all cards face-up)
  bool canAutoComplete();

  /// Perform one step of auto-complete, returns true if a move was made
  bool autoCompleteStep();

  /// Get the current move count
  int get moveCount;

  /// Get the move history for undo
  List<Move> get moveHistory;

  /// Handle tap on stock pile (draw cards)
  Move? tapStock();

  /// Find valid moves for a given card selection
  List<Pile> getValidDestinations(Pile from, List<PlayingCard> cards);

  /// Get hint for next possible move
  ({Pile from, Pile to, List<PlayingCard> cards})? getHint();

  /// Returns true if any legal move or draw is possible (used for loss detection)
  bool hasAnyMove();

  // ==========================================================================
  // Redo Support
  // ==========================================================================

  /// Redo the last undone move. Returns true if successful.
  /// Default implementation returns false (no redo support).
  bool redo() => false;

  /// Get the redo stack for UI display.
  /// Default implementation returns empty list.
  List<Move> get redoStack => const [];

  /// Whether redo is available.
  bool get canRedo => redoStack.isNotEmpty;

  // ==========================================================================
  // Loss Detection
  // ==========================================================================

  /// Check if the game is in an unwinnable state (no progress possible).
  /// Returns false if unknown or if the game can continue.
  /// Default implementation returns false (no loss detection).
  bool get isLost => false;

  // ==========================================================================
  // Auto-Move (Double-Tap)
  // ==========================================================================

  /// Find the best destination for auto-moving cards (double-tap behavior).
  /// Returns null if no auto-move is appropriate.
  /// Each game implements its own priority logic.
  Pile? findBestAutoMoveDestination(Pile fromPile, List<PlayingCard> cards);

  /// Whether double-tap auto-move is allowed for this card in this pile.
  /// Games with different selection rules can override this.
  ///
  /// Default implementation:
  /// - Waste: only top card
  /// - Tableau: only top card (single-card auto-move)
  /// - Other piles: only top card
  ///
  /// Games like Pyramid can override to allow any exposed card.
  bool canAutoMove(Pile pile, PlayingCard card) {
    // Default: only allow auto-move on top card
    return pile.topCard == card;
  }

  /// Get cards that would be moved in an auto-move operation.
  /// Default returns just the single card for most piles,
  /// or the full run from card to top for tableau.
  ///
  /// Games can override for different stack selection behavior.
  List<PlayingCard> getAutoMoveCards(Pile pile, PlayingCard card) {
    final cardIndex = pile.indexOfCard(card);
    if (cardIndex < 0) return [card];
    return pile.cards.sublist(cardIndex);
  }

  // ==========================================================================
  // Configuration
  // ==========================================================================

  /// Apply game-specific difficulty settings.
  /// Each game type interprets difficulty differently.
  /// Default implementation does nothing.
  void applyDifficulty(Difficulty difficulty) {}

  /// Configure the game based on current settings.
  /// This allows the game to adapt to Draw Mode, Vegas Mode, etc.
  /// Called after game creation in newGame().
  /// Default implementation does nothing.
  void configure(SettingsProvider settings) {}

  // ==========================================================================
  // Solver Support
  // ==========================================================================

  /// Returns a solver state snapshot for AI analysis.
  /// Returns null if the game doesn't support solving (e.g., Spider in V1.0).
  /// Each game type implements its own solver state conversion.
  SolverState? getSolverState();

  /// Get a specific pile by type (for single piles like stock/waste)
  Pile? getPile(PileType type);

  /// Get the next pile to focus on from the current pile
  Pile? getNextFocus(Pile current);

  /// Get all piles that can be focused (for keyboard navigation)
  List<Pile> get focusablePiles;

  /// Handle tap on a pile (game-specific behavior)
  Move? handlePileTap(Pile pile);

  /// Handle pile activation (Enter/Space key on focused pile).
  /// Returns a Move if the game handled the activation internally (e.g., stock tap).
  /// Returns null if the controller should use default behavior (select top card).
  /// Default implementation delegates to handlePileTap for stock piles.
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
  List<PlayingCard>? getSelectableCards(Pile pile, PlayingCard card) => null;

  /// Game-specific layout configuration
  LayoutConfig get layoutConfig;

  // ==========================================================================
  // Layout Helpers
  // ==========================================================================

  /// Get the suit for a foundation pile (for display purposes).
  /// Returns null if foundations are not suit-specific (e.g., Spider).
  ///
  /// Default implementation maps foundation index to Suit.values order.
  /// Games with different foundation semantics should override.
  Suit? getFoundationSuit(int foundationIndex) {
    if (foundationIndex < 0 || foundationIndex >= foundationPiles.length) {
      return null;
    }
    return Suit.values[foundationIndex % Suit.values.length];
  }

  // ==========================================================================
  // Hint System
  // ==========================================================================

  /// Get a stock-related hint (draw or recycle).
  /// Returns a record with source and destination piles if a stock hint is available.
  /// Returns null if no stock hint is applicable.
  ///
  /// Default implementation checks for stock draw or waste recycle.
  /// Games without stock/waste can override to return null.
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
  /// Games without stock (like some Pyramid variants) return false.
  bool get supportsStockHints => stockPile != null;
}

/// Layout type determines how cards are positioned on the board.
enum LayoutType {
  /// Grid-based layout with rows and columns (Klondike, Spider, Freecell)
  grid,

  /// Stack-based layout with absolute (x,y) positioning (Pyramid, TriPeaks, Golf)
  stack,

  // Future: spiral, tree, etc.
}

class LayoutConfig {
  final int tableauCount;
  final int foundationCount;
  final bool hasStock;
  final bool hasWaste;

  /// The type of layout this game uses.
  /// Grid layouts use Row/Column widgets.
  /// Stack layouts use Stack/Positioned widgets with absolute coordinates.
  final LayoutType layoutType;

  const LayoutConfig({
    required this.tableauCount,
    required this.foundationCount,
    this.hasStock = true,
    this.hasWaste = true,
    this.layoutType = LayoutType.grid,
  });
}
