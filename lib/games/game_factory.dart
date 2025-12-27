import 'game_interface.dart';
import 'klondike/klondike_game.dart';

/// Supported game types
enum GameType {
  klondike;

  String get displayName {
    switch (this) {
      case GameType.klondike:
        return 'Klondike';
    }
  }

  String get description {
    switch (this) {
      case GameType.klondike:
        return 'Classic solitaire with 7 tableau piles';
    }
  }
}

/// Factory for creating game instances
class GameFactory {
  /// Create a new game instance for the given type
  static GameInterface createGame(GameType type) {
    switch (type) {
      case GameType.klondike:
        return KlondikeGame();
    }
  }
}
