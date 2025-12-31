/// Abstract definitions for the solver engine.
///
/// This file defines the contracts that concrete game solvers must implement
/// to work with the generic SolverEngine.
library;

/// Abstract base class for moves in the solver.
///
/// Each game must define its own move type that extends this class.
/// The priority field helps in ordering moves during search.
abstract class SolverMove {
  int get priority;
}

/// Abstract base class for solver states.
///
/// [T] is the type of moves that can be applied to this state.
/// States must be lightweight and represent the game state efficiently
/// for search algorithms.
abstract class SolverState<T extends SolverMove> {
  /// Returns the list of available moves from this state.
  List<T> getAvailableMoves();

  /// Applies the given move and returns the new state.
  ///
  /// The returned state should be a new instance, not modified in-place,
  /// to maintain immutability for search algorithms.
  SolverState<T> applyMove(T move);

  /// Returns true if this state represents a winning condition.
  bool get isWon;

  /// Returns a unique string signature for this state.
  ///
  /// Used for cycle detection in search algorithms.
  /// Must be consistent and unique for equivalent states.
  String get signature;

  /// Returns a heuristic score (0-100) to prioritize states.
  ///
  /// Higher scores indicate more promising states.
  /// For winning states, this should be the maximum value.
  int get heuristicScore;
}
