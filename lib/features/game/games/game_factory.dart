import 'game_interface.dart';
import 'klondike/klondike_game.dart';
import 'spider/spider_game.dart';

// Re-export GameType for convenience
export 'game_interface.dart' show GameType;

/// Extension on GameType to provide display information
extension GameTypeDisplay on GameType {
  String get displayName {
    switch (this) {
      case GameType.klondike:
        return 'Klondike';
      case GameType.spider:
        return 'Spider';
      case GameType.pyramid:
        return 'Pyramid';
      case GameType.golf:
        return 'Golf';
      case GameType.freecell:
        return 'FreeCell';
      case GameType.triPeaks:
        return 'TriPeaks';
      case GameType.yukon:
        return 'Yukon';
      case GameType.fortyThieves:
        return 'Forty Thieves';
      case GameType.canfield:
        return 'Canfield';
      case GameType.scorpion:
        return 'Scorpion';
    }
  }

  String get description {
    switch (this) {
      case GameType.klondike:
        return 'The quintessential version of Solitaire that most players know simply as "the game." Your goal is to build four foundations from Ace to King by maneuvering cards through a tableau of descending, alternating colors. It strikes a classic balance between luck and strategy, offering a familiar rhythm of revealing hidden cards and managing your waste pile.';
      case GameType.spider:
        return 'This challenging variant requires you to assemble complete suits within the tableau itself before they can be removed. Dealing two decks of cards, you must weave complex sequences to clear the board. It is a true test of patience and planning, where managing your empty columns is often the key to untangling the web.';
      case GameType.pyramid:
        return 'A mathematical puzzle where the goal is not to build sequences, but to dismantle a pyramid of cards by pairing them up. You must find combinations that add up to 13 to remove them from the board. As you chip away at the structure, the challenge lies in uncovering the buried cards you need before the draw pile runs out.';
      case GameType.golf:
        return 'Named for the desire to earn the lowest score possible, this game demands that you clear a tableau of cards into a single waste pile. You can play any card that is one rank higher or lower than the top card on the pile, regardless of suit. With no redrawing allowed, every move is critical, forcing you to plan your runs carefully to make par.';
      case GameType.freecell:
        return 'A game of open information where almost every deal is winnable if you have the foresight to solve it. All cards are visible from the start, and you are given four temporary "free cells" to hold cards while you reorganize the tableau. It is less about luck and more about strategic sequencing, rewarding players who can think several moves ahead.';
      case GameType.triPeaks:
        return 'A mathematical puzzle where the goal is not to build sequences, but to dismantle a pyramid of cards by pairing them up. You must find combinations that add up to 13 to remove them from the board. As you chip away at the structure, the challenge lies in uncovering the buried cards you need before the draw pile runs out.';
      case GameType.yukon:
        return 'This variant allows for great freedom of movement, letting you move any group of face-up cards regardless of what is beneath them. The catch is that you must still place them on a card of the opposite color and next highest rank. This flexibility creates dynamic gameplay where you can tear apart large stacks to uncover the vital cards hidden underneath.';
      case GameType.fortyThieves:
        return 'Widely considered one of the most difficult solitaire games, this variant uses two decks and strict rules. You face a wide tableau where you can only move the top card of each stack, and you must build sequences by suit. Victories here are rare and hard-earned, making it a favorite for players seeking a rigorous mental workout.';
      case GameType.canfield:
        return 'Originally a casino game, Canfield offers a high-difficulty challenge with a unique reserve pile that acts as a ticking clock. You must move cards to the foundation while managing a small tableau and a difficult draw pile. It is a compact, tight game where resources are scarce, and turning the tide requires sharp tactical decisions.';
      case GameType.scorpion:
        return 'A hybrid that borrows the movement rules of Yukon and the objective of Spider. You must build complete suits from King down to Ace within the tableau, and you can move large groups of cards even if they aren\'t in order. It is an intense puzzle of exposure, where you must fight to flip face-down cards while keeping your stacks organized.';
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
      case GameType.pyramid:
        throw UnimplementedError('Pyramid game is not yet implemented.');
      case GameType.golf:
        throw UnimplementedError('Golf game is not yet implemented.');
      case GameType.freecell:
        throw UnimplementedError('FreeCell game is not yet implemented.');
      case GameType.triPeaks:
        throw UnimplementedError('TriPeaks game is not yet implemented.');
      case GameType.yukon:
        throw UnimplementedError('Yukon game is not yet implemented.');
      case GameType.fortyThieves:
        throw UnimplementedError('Forty Thieves game is not yet implemented.');
      case GameType.canfield:
        throw UnimplementedError('Canfield game is not yet implemented.');
      case GameType.scorpion:
        throw UnimplementedError('Scorpion game is not yet implemented.');
    }
  }
}
