import '../games/game_interface.dart';

/// Service for detecting when a game is in a state that can be auto-completed.
///
/// This service is now game-agnostic - it delegates the actual detection logic
/// to the game's [GameInterface.canAutoComplete] method.
///
/// The default implementation in [GameInterface] checks:
/// - Stock pile is empty (no more cards to draw)
/// - Waste pile is empty (no cards left to play from waste)
/// - All cards in tableau piles are face up (no hidden cards)
///
/// Games can override [GameInterface.canAutoComplete] for custom logic:
/// - Spider returns false (no auto-complete support)
/// - Pyramid might check if all exposed cards can be paired
class AutoCompleteDetector {
  /// Determines if the game can be auto-completed.
  ///
  /// Delegates to [GameInterface.canAutoComplete] for game-specific logic.
  /// This allows each game type to define its own auto-complete conditions.
  static bool canAutoComplete(GameInterface game) {
    return game.canAutoComplete();
  }
}
