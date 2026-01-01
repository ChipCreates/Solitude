import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import '../games/game_interface.dart';
import '../models/card.dart';
import '../models/pile.dart';
import '../ai/solver_engine.dart';
import '../ai/games/klondike_solver_state.dart';
import 'package:solitude/features/settings/models/hint_mode.dart';
import 'hint_state_notifier.dart';

/// Callback signature for executing a move on the game
typedef MoveExecutor = bool Function(
    Pile from, Pile to, List<PlayingCard> cards);

/// Callback signature for tapping a pile
typedef PileTapper = void Function(Pile pile);

/// SolverService handles all AI/solver-related logic, including:
/// - Background solving with debouncing
/// - Smart hints using cached winning paths
/// - Auto-play of solver solutions
///
/// This service decouples solver logic from the GameController,
/// following the Single Responsibility Principle.
class SolverService {
  final GameInterface _game;
  final HintStateNotifier _hintState;

  // Cached winning path for smart hints
  List<KlondikeMove>? _cachedWinningPath;

  // Debounce timer for background solving
  Timer? _solveDebounceTimer;

  // Track if disposed
  bool _isDisposed = false;

  /// Current hint mode (injected from settings)
  HintMode _hintMode = HintMode.smart;

  SolverService({
    required GameInterface game,
    required HintStateNotifier hintState,
  })  : _game = game,
        _hintState = hintState;

  /// Updates the hint mode from settings
  void updateHintMode(HintMode mode) {
    _hintMode = mode;
  }

  /// Returns the cached winning path (for debugging/testing)
  List<KlondikeMove>? get cachedWinningPath => _cachedWinningPath;

  /// Solves the current game using the AI solver in a background isolate.
  /// Returns null if the game doesn't support solving (e.g., Spider).
  Future<List<KlondikeMove>?> solveGame() async {
    if (_isDisposed) return null;

    // Get solver state from the game interface
    final solverState = _game.getSolverState();

    // If the game doesn't support solving, return null
    if (solverState == null) return null;

    // Currently only KlondikeSolverState is supported
    if (solverState is! KlondikeSolverState) return null;

    // Run the solver in a background isolate
    return await Isolate.run(() async {
      final engine = SolverEngine();
      return await engine.solve(solverState);
    });
  }

  /// Executes a single solver move using the provided callbacks.
  ///
  /// [tryMove] - Callback to attempt a card move
  /// [tapPile] - Callback to tap a pile (for stock draws)
  Future<void> executeSolverMove(
    KlondikeMove move, {
    required MoveExecutor tryMove,
    required PileTapper tapPile,
  }) async {
    if (_isDisposed) return;

    try {
      switch (move.type) {
        case KlondikeMoveType.tableauToTableau:
          final fromPile = _game.tableauPiles[move.fromPile];
          final toPile = _game.tableauPiles[move.toPile];
          if (fromPile.isEmpty) throw Exception('Source tableau pile is empty');
          final card = fromPile.topCard!;
          tryMove(fromPile, toPile, [card]);
          break;

        case KlondikeMoveType.tableauToFoundation:
          final fromPile = _game.tableauPiles[move.fromPile];
          final toPile = _game.foundationPiles[move.toPile];
          if (fromPile.isEmpty) throw Exception('Source tableau pile is empty');
          final card = fromPile.topCard!;
          tryMove(fromPile, toPile, [card]);
          break;

        case KlondikeMoveType.wasteToTableau:
          final fromPile = _game.wastePile!;
          final toPile = _game.tableauPiles[move.toPile];
          if (fromPile.isEmpty) throw Exception('Waste pile is empty');
          final card = fromPile.topCard!;
          tryMove(fromPile, toPile, [card]);
          break;

        case KlondikeMoveType.wasteToFoundation:
          final fromPile = _game.wastePile!;
          final toPile = _game.foundationPiles[move.toPile];
          if (fromPile.isEmpty) throw Exception('Waste pile is empty');
          final card = fromPile.topCard!;
          tryMove(fromPile, toPile, [card]);
          break;

        case KlondikeMoveType.drawCard:
          if (_game.stockPile != null && !_game.stockPile!.isEmpty) {
            tapPile(_game.stockPile!);
          }
          break;

        case KlondikeMoveType.flipTableauCard:
          // Face-down tracking not implemented, skip
          break;
      }
    } catch (e) {
      // Gracefully handle execution errors (sync issues)
      debugPrint('Solver move execution failed: $e');
    }
  }

  /// Auto-plays a sequence of solver moves with visual pacing.
  ///
  /// [isPlaying] - Callback to check if we should continue playing
  /// [tryMove] - Callback to attempt a card move
  /// [tapPile] - Callback to tap a pile (for stock draws)
  Future<void> autoPlaySolution(
    List<KlondikeMove> moves, {
    required bool Function() isPlaying,
    required MoveExecutor tryMove,
    required PileTapper tapPile,
  }) async {
    if (_isDisposed) return;

    for (var move in moves) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (_isDisposed || !isPlaying()) break;
      await executeSolverMove(move, tryMove: tryMove, tapPile: tapPile);
    }
  }

  /// Solves and auto-plays the current game (debug/power user tool).
  Future<void> solveAndAutoPlay({
    required bool Function() isPlaying,
    required MoveExecutor tryMove,
    required PileTapper tapPile,
  }) async {
    if (_isDisposed) return;
    final path = await solveGame();
    if (path != null && !_isDisposed) {
      await autoPlaySolution(
        path,
        isPlaying: isPlaying,
        tryMove: tryMove,
        tapPile: tapPile,
      );
    }
  }

  /// Shows a smart hint from the cached solver path, or falls back to fast hints.
  ///
  /// Returns true if a smart hint was shown, false otherwise.
  /// When false is returned, the caller should fall back to fast hints.
  bool showSmartHint({
    required void Function() onHintUsed,
    required void Function() clearHintAfterDelay,
  }) {
    // Check hint mode setting
    if (_hintMode != HintMode.smart) {
      return false;
    }

    // Check smart hint from solver cache
    if (_cachedWinningPath != null && _cachedWinningPath!.isNotEmpty) {
      final firstMove = _cachedWinningPath!.first;
      Pile? sourcePile, destinationPile;
      List<PlayingCard>? cards;

      switch (firstMove.type) {
        case KlondikeMoveType.tableauToTableau:
          sourcePile = _game.tableauPiles[firstMove.fromPile];
          destinationPile = _game.tableauPiles[firstMove.toPile];
          cards = !sourcePile.isEmpty ? [sourcePile.topCard!] : null;
          break;
        case KlondikeMoveType.tableauToFoundation:
          sourcePile = _game.tableauPiles[firstMove.fromPile];
          destinationPile = _game.foundationPiles[firstMove.toPile];
          cards = !sourcePile.isEmpty ? [sourcePile.topCard!] : null;
          break;
        case KlondikeMoveType.wasteToTableau:
          sourcePile = _game.wastePile;
          destinationPile = _game.tableauPiles[firstMove.toPile];
          cards = sourcePile != null && !sourcePile.isEmpty
              ? [sourcePile.topCard!]
              : null;
          break;
        case KlondikeMoveType.wasteToFoundation:
          sourcePile = _game.wastePile;
          destinationPile = _game.foundationPiles[firstMove.toPile];
          cards = sourcePile != null && !sourcePile.isEmpty
              ? [sourcePile.topCard!]
              : null;
          break;
        case KlondikeMoveType.drawCard:
          sourcePile = _game.stockPile;
          destinationPile = _game.stockPile;
          cards = null;
          break;
        case KlondikeMoveType.flipTableauCard:
          // Skip flip hints
          break;
      }

      if (sourcePile != null && destinationPile != null) {
        _hintState.setHint(
          sourcePile: sourcePile,
          cards: cards,
          destinationPile: destinationPile,
        );
        onHintUsed();
        clearHintAfterDelay();
        return true;
      }
    }

    // No smart hint available
    return false;
  }

  /// Invalidates cache and starts debounce timer for background solving.
  ///
  /// This should be called after any move that changes the game state.
  void invalidateCacheAndDebounceSolve() {
    _cachedWinningPath = null;
    _solveDebounceTimer?.cancel();

    // Only run solver if smart hint mode is enabled and game supports solving
    if (_hintMode == HintMode.smart && _game.getSolverState() != null) {
      _solveDebounceTimer = Timer(
        const Duration(milliseconds: 500),
        _backgroundSolve,
      );
    }
  }

  /// Background solver execution.
  void _backgroundSolve() async {
    if (_isDisposed) return;
    final path = await solveGame();
    if (!_isDisposed) {
      _cachedWinningPath = path;
    }
  }

  /// Clears the cached winning path (e.g., on new game)
  void clearCache() {
    _cachedWinningPath = null;
    _solveDebounceTimer?.cancel();
  }

  /// Disposes of the service and cancels any pending operations
  void dispose() {
    _isDisposed = true;
    _solveDebounceTimer?.cancel();
  }
}
