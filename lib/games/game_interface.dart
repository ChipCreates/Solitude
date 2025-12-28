import 'dart:math';
import '../models/card.dart';
import '../models/pile.dart';
import '../models/move.dart';
import '../models/difficulty.dart';

/// Abstract interface that all solitaire game types must implement.
/// This allows for future expansion to Spider, FreeCell, etc.
abstract class GameInterface {
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

  // ==========================================================================
  // Configuration
  // ==========================================================================

  /// Apply game-specific difficulty settings.
  /// Each game type interprets difficulty differently.
  /// Default implementation does nothing.
  void applyDifficulty(Difficulty difficulty) {}

  /// Get a specific pile by type (for single piles like stock/waste)
  Pile? getPile(PileType type);

  /// Get the next pile to focus on from the current pile
  Pile? getNextFocus(Pile current);

  /// Get all piles that can be focused (for keyboard navigation)
  List<Pile> get focusablePiles;

  /// Handle tap on a pile (game-specific behavior)
  Move? handlePileTap(Pile pile);

  /// Game-specific layout configuration
  LayoutConfig get layoutConfig;
}

class LayoutConfig {
  final int tableauCount;
  final int foundationCount;
  final bool hasStock;
  final bool hasWaste;
  
  const LayoutConfig({
    required this.tableauCount,
    required this.foundationCount,
    this.hasStock = true,
    this.hasWaste = true,
  });
}
