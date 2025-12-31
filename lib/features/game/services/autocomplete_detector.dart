import '../games/game_interface.dart';

/// Service for detecting when a game is in a state that can be auto-completed.
/// Auto-complete is possible when all cards that need to move are visible and
/// no further draws are needed.
class AutoCompleteDetector {
  /// Determines if the game can be auto-completed.
  ///
  /// The game is auto-complete capable when:
  /// - The stock pile is empty (no more cards to draw)
  /// - The waste pile is empty (no cards left to play from waste)
  /// - All cards in tableau piles are face up (no hidden cards)
  ///
  /// When these conditions are met, the player can simply click cards to move
  /// them to foundations with zero risk.
  static bool canAutoComplete(GameInterface game) {
    // Stock must be empty
    if (!(game.stockPile?.isEmpty ?? true)) return false;

    // Waste must be empty
    if (!(game.wastePile?.isEmpty ?? true)) return false;

    // All tableau cards must be face up
    for (final pile in game.tableauPiles) {
      for (final card in pile.cards) {
        if (!card.faceUp) return false;
      }
    }

    return true;
  }
}
