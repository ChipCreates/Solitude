import '../games/game_interface.dart';
import '../services/game_controller.dart';
import 'layout_strategy.dart';
import 'klondike_layout_strategy.dart';
import 'spider_layout_strategy.dart';

/// Factory for creating layout strategies based on game type.
///
/// This replaces the fragile pile-count based detection with explicit
/// GameType-based routing. Each game type maps to exactly one layout strategy.
///
/// To add a new game:
/// 1. Add the GameType enum value in game_interface.dart
/// 2. Create a new layout strategy class (extend LayoutStrategy, optionally with GridLayoutMixin)
/// 3. Add the case to this factory
class LayoutStrategyFactory {
  /// Create the appropriate layout strategy for a game controller.
  ///
  /// Uses the game's explicit [GameType] for routing instead of
  /// inferring from pile counts.
  static LayoutStrategy create(GameController controller) {
    final game = controller.game;
    final config = game.layoutConfig;

    return createFromType(game.gameType, config);
  }

  /// Create a layout strategy directly from a GameType and LayoutConfig.
  ///
  /// Useful when you don't have a controller but know the game type.
  static LayoutStrategy createFromType(GameType type, LayoutConfig config) {
    switch (type) {
      case GameType.klondike:
        return KlondikeLayoutStrategy(config);
      case GameType.spider:
        return SpiderLayoutStrategy(config);
      // Future games - throw until implemented
      case GameType.pyramid:
      case GameType.golf:
      case GameType.freecell:
      case GameType.triPeaks:
      case GameType.yukon:
      case GameType.fortyThieves:
      case GameType.canfield:
      case GameType.scorpion:
        throw UnimplementedError(
          'Layout strategy for $type is not yet implemented. '
          'To add support: create a new strategy class and add it to this factory.',
        );
    }
  }
}
