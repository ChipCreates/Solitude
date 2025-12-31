import 'dart:collection';
import 'dart:async';

import 'abstract_solver.dart';

/// The generic solver engine that uses best-first search with heuristics.
///
/// This engine can solve any game that implements the SolverState contract.
/// It runs a priority-based search algorithm, prioritizing states with higher
/// heuristic scores.
class SolverEngine {
  static const Duration _timeout = Duration(seconds: 5);

  /// Attempts to solve the game starting from the given initial state.
  ///
  /// Returns a list of moves that lead to a winning state, or null if no
  /// solution is found within the timeout or if the search space is exhausted.
  Future<List<T>?> solve<T extends SolverMove>(SolverState<T> initialState) {
    return Future(() => _compute(initialState))
        .timeout(_timeout)
        .catchError((_) => null);
  }

  /// Synchronous computation of the solution path.
  List<T>? _compute<T extends SolverMove>(SolverState<T> initialState) {
    // Priority queue for states, max-heap based on heuristic score
    var openSet = PriorityQueue<SolverState<T>>(
      (a, b) => b.heuristicScore.compareTo(a.heuristicScore),
    );

    // Maps for reconstructing the path
    var cameFrom = <String, SolverState<T>>{};
    var moveToHere = <String, T>{};

    // Set of visited state signatures to avoid cycles
    var visited = <String>{};

    openSet.add(initialState);
    visited.add(initialState.signature);

    while (openSet.isNotEmpty) {
      var current = openSet.removeFirst();

      if (current.isWon) {
        // Reconstruct the path by backtracking
        List<T> path = [];
        var state = current;
        while (moveToHere.containsKey(state.signature)) {
          path.add(moveToHere[state.signature]!);
          state = cameFrom[state.signature]!;
        }
        return path.reversed.toList();
      }

      // Generate and enqueue neighboring states
      for (var move in current.getAvailableMoves()) {
        var neighbor = current.applyMove(move);
        var sig = neighbor.signature;
        if (visited.contains(sig)) continue;
        visited.add(sig);
        cameFrom[sig] = current;
        moveToHere[sig] = move;
        openSet.add(neighbor);
      }
    }

    // No solution found
    return null;
  }
}
