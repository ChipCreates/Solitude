import 'dart:isolate';
import '../games/game_interface.dart';
import '../models/card.dart';
import '../models/pile.dart';
import 'abstract_solver.dart';
import 'solver_engine.dart';
import 'games/klondike_solver_state.dart';

/// Callback signature for executing a move on the game
typedef SolverMoveExecutor = bool Function(
    Pile from, Pile to, List<PlayingCard> cards);

/// Callback signature for tapping a pile
typedef SolverPileTapper = void Function(Pile pile);

/// Abstract base class for game-specific solver strategies.
///
/// Each game type that supports solving should have its own solver strategy
/// that knows how to:
/// - Convert game state to solver state
/// - Execute solver moves on the game
/// - Interpret solver results for hints
abstract class SolverStrategy<M extends SolverMove> {
  /// Solve the current game state.
  /// Returns a list of moves to win, or null if unsolvable.
  Future<List<M>?> solve(GameInterface game);

  /// Execute a single solver move on the game.
  /// Returns true if the move was executed successfully.
  bool executeMove(
    GameInterface game,
    M move, {
    required SolverMoveExecutor tryMove,
    required SolverPileTapper tapPile,
  });

  /// Get hint data from a solver move.
  /// Returns source pile, destination pile, and cards to move.
  ({Pile? sourcePile, Pile? destinationPile, List<PlayingCard>? cards})?
      getHintFromMove(GameInterface game, M move);
}

/// Klondike-specific solver strategy.
class KlondikeSolverStrategy extends SolverStrategy<KlondikeMove> {
  @override
  Future<List<KlondikeMove>?> solve(GameInterface game) async {
    final solverState = game.getSolverState();
    if (solverState == null || solverState is! KlondikeSolverState) {
      return null;
    }

    return await Isolate.run(() async {
      final engine = SolverEngine();
      return await engine.solve(solverState);
    });
  }

  @override
  bool executeMove(
    GameInterface game,
    KlondikeMove move, {
    required SolverMoveExecutor tryMove,
    required SolverPileTapper tapPile,
  }) {
    try {
      switch (move.type) {
        case KlondikeMoveType.tableauToTableau:
          final fromPile = game.tableauPiles[move.fromPile];
          final toPile = game.tableauPiles[move.toPile];
          if (fromPile.isEmpty) return false;
          final card = fromPile.topCard!;
          return tryMove(fromPile, toPile, [card]);

        case KlondikeMoveType.tableauToFoundation:
          final fromPile = game.tableauPiles[move.fromPile];
          final toPile = game.foundationPiles[move.toPile];
          if (fromPile.isEmpty) return false;
          final card = fromPile.topCard!;
          return tryMove(fromPile, toPile, [card]);

        case KlondikeMoveType.wasteToTableau:
          final fromPile = game.wastePile;
          if (fromPile == null || fromPile.isEmpty) return false;
          final toPile = game.tableauPiles[move.toPile];
          final card = fromPile.topCard!;
          return tryMove(fromPile, toPile, [card]);

        case KlondikeMoveType.wasteToFoundation:
          final fromPile = game.wastePile;
          if (fromPile == null || fromPile.isEmpty) return false;
          final toPile = game.foundationPiles[move.toPile];
          final card = fromPile.topCard!;
          return tryMove(fromPile, toPile, [card]);

        case KlondikeMoveType.drawCard:
          final stockPile = game.stockPile;
          if (stockPile != null && !stockPile.isEmpty) {
            tapPile(stockPile);
            return true;
          }
          return false;

        case KlondikeMoveType.flipTableauCard:
          // Flip is handled automatically by the game
          return true;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  ({Pile? sourcePile, Pile? destinationPile, List<PlayingCard>? cards})?
      getHintFromMove(GameInterface game, KlondikeMove move) {
    switch (move.type) {
      case KlondikeMoveType.tableauToTableau:
        final source = game.tableauPiles[move.fromPile];
        final dest = game.tableauPiles[move.toPile];
        final cards = !source.isEmpty ? [source.topCard!] : null;
        return (sourcePile: source, destinationPile: dest, cards: cards);

      case KlondikeMoveType.tableauToFoundation:
        final source = game.tableauPiles[move.fromPile];
        final dest = game.foundationPiles[move.toPile];
        final cards = !source.isEmpty ? [source.topCard!] : null;
        return (sourcePile: source, destinationPile: dest, cards: cards);

      case KlondikeMoveType.wasteToTableau:
        final source = game.wastePile;
        if (source == null) return null;
        final dest = game.tableauPiles[move.toPile];
        final cards = !source.isEmpty ? [source.topCard!] : null;
        return (sourcePile: source, destinationPile: dest, cards: cards);

      case KlondikeMoveType.wasteToFoundation:
        final source = game.wastePile;
        if (source == null) return null;
        final dest = game.foundationPiles[move.toPile];
        final cards = !source.isEmpty ? [source.topCard!] : null;
        return (sourcePile: source, destinationPile: dest, cards: cards);

      case KlondikeMoveType.drawCard:
        final stock = game.stockPile;
        if (stock == null) return null;
        return (sourcePile: stock, destinationPile: stock, cards: null);

      case KlondikeMoveType.flipTableauCard:
        return null; // Skip flip hints
    }
  }
}

/// Factory for creating solver strategies based on game type.
///
/// This replaces the hardcoded Klondike type check in SolverService
/// with a proper strategy pattern.
class SolverStrategyFactory {
  static final Map<GameType, SolverStrategy> _strategies = {
    GameType.klondike: KlondikeSolverStrategy(),
    // Future: GameType.spider: SpiderSolverStrategy(),
  };

  /// Get the solver strategy for a game type.
  /// Returns null if the game type doesn't support solving.
  static SolverStrategy? getStrategy(GameType gameType) {
    return _strategies[gameType];
  }

  /// Check if a game type supports solving.
  static bool supportsSolving(GameType gameType) {
    return _strategies.containsKey(gameType);
  }
}
