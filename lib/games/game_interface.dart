import 'dart:math';
import '../models/card.dart';
import '../models/pile.dart';
import '../models/move.dart';

/// Abstract interface that all solitaire game types must implement.
/// This allows for future expansion to Spider, FreeCell, etc.
abstract class GameInterface {
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
