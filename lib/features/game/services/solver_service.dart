import 'dart:async';
import 'package:flutter/foundation.dart';
import '../games/game_interface.dart';
import '../models/card.dart';
import '../models/pile.dart';
import '../ai/solver_strategy.dart';
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
/// This service is now game-agnostic through the SolverStrategyFactory.
/// Each game type that supports solving has its own SolverStrategy.
class SolverService {
  final GameInterface _game;
  final HintStateNotifier _hintState;

  // Cached winning path for smart hints (typed as dynamic list for game-agnostic storage)
  List<dynamic>? _cachedWinningPath;

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
  List<dynamic>? get cachedWinningPath => _cachedWinningPath;

  /// Solves the current game using the appropriate solver strategy.
  /// Returns null if the game doesn't support solving.
  Future<List<dynamic>?> solveGame() async {
    if (_isDisposed) return null;

    // Get the appropriate solver strategy for this game type
    final strategy = SolverStrategyFactory.getStrategy(_game.gameType);
    if (strategy == null) return null;

    return await strategy.solve(_game);
  }

  /// Executes a single solver move using the provided callbacks.
  Future<void> executeSolverMove(
    dynamic move, {
    required MoveExecutor tryMove,
    required PileTapper tapPile,
  }) async {
    if (_isDisposed) return;

    final strategy = SolverStrategyFactory.getStrategy(_game.gameType);
    if (strategy == null) return;

    try {
      // Wrap the callbacks to match SolverStrategy's expected types
      strategy.executeMove(
        _game,
        move,
        tryMove: (from, to, cards) => tryMove(from, to, cards),
        tapPile: (pile) => tapPile(pile),
      );
    } catch (e) {
      debugPrint('Solver move execution failed: $e');
    }
  }

  /// Auto-plays a sequence of solver moves with visual pacing.
  Future<void> autoPlaySolution(
    List<dynamic> moves, {
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
  bool showSmartHint({
    required void Function() onHintUsed,
    required void Function() clearHintAfterDelay,
  }) {
    if (_hintMode != HintMode.smart) return false;

    // Get the solver strategy for this game
    final strategy = SolverStrategyFactory.getStrategy(_game.gameType);
    if (strategy == null) return false;

    // Check smart hint from solver cache
    if (_cachedWinningPath != null && _cachedWinningPath!.isNotEmpty) {
      final firstMove = _cachedWinningPath!.first;
      final hintData = strategy.getHintFromMove(_game, firstMove);

      if (hintData != null &&
          hintData.sourcePile != null &&
          hintData.destinationPile != null) {
        _hintState.setHint(
          sourcePile: hintData.sourcePile!,
          cards: hintData.cards,
          destinationPile: hintData.destinationPile!,
        );
        onHintUsed();
        clearHintAfterDelay();
        return true;
      }
    }

    return false;
  }

  /// Invalidates cache and starts debounce timer for background solving.
  void invalidateCacheAndDebounceSolve() {
    _cachedWinningPath = null;
    _solveDebounceTimer?.cancel();

    // Only run solver if smart hint mode is enabled and game supports solving
    if (_hintMode == HintMode.smart &&
        SolverStrategyFactory.supportsSolving(_game.gameType)) {
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
