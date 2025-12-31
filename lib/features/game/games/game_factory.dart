import 'game_interface.dart';
import 'klondike/klondike_game.dart';
import 'spider/spider_game.dart';

/// Supported game types
enum GameType {
  klondike,
  spider;

  String get displayName {
    switch (this) {
      case GameType.klondike:
        return 'Klondike';
      case GameType.spider:
        return 'Spider';
    }
  }

  String get description {
    switch (this) {
      case GameType.klondike:
        return 'Classic solitaire with 7 tableau piles';
      case GameType.spider:
        return 'Advanced solitaire with 10 tableau piles';
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
      case GameType.spider:
        return SpiderGame();
    }
  }
}
