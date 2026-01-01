import 'dart:convert';

import '../abstract_solver.dart';

/// Represents a card in the Pyramid solver.
/// Format: 'rankSuit' where rank 1-13 (1=Ace, 13=King), suit H/D/C/S.
class PyramidCard {
  final String value;

  PyramidCard(this.value);

  int get rank => int.parse(value.substring(0, value.length - 1));

  String get suit => value.substring(value.length - 1);

  bool get isKing => rank == 13;

  @override
  String toString() => value;

  /// Check if this card pairs with another to sum to 13
  bool pairsWith(PyramidCard other) => rank + other.rank == 13;
}

/// Enum for different move types in Pyramid.
enum PyramidMoveType {
  removeKing, // Remove a King by itself
  matchPair, // Match two cards summing to 13
  drawFromStock, // Draw a card from stock to waste
  recycleWaste, // Recycle waste back to stock
}

/// Represents a move in Pyramid solitaire.
class PyramidMove extends SolverMove {
  final PyramidMoveType type;
  final int cardIndex1; // Pyramid index or -1 for waste
  final int cardIndex2; // Second card index for pairs, -1 otherwise

  PyramidMove(this.type, this.cardIndex1, [this.cardIndex2 = -1]);

  @override
  int get priority => _calculatePriority();

  int _calculatePriority() {
    switch (type) {
      case PyramidMoveType.removeKing:
        return 10; // High priority - always good to remove Kings
      case PyramidMoveType.matchPair:
        return 8; // Good priority for matches
      case PyramidMoveType.drawFromStock:
        return 3; // Medium priority
      case PyramidMoveType.recycleWaste:
        return 1; // Low priority
    }
  }

  @override
  String toString() => '$type idx1:$cardIndex1 idx2:$cardIndex2';
}

/// Lightweight state representation for Pyramid solver.
class PyramidSolverState implements SolverState<PyramidMove> {
  // Pyramid positions: 28 slots, null if removed
  final List<String?> pyramid;
  final List<String> stock; // Cards in stock
  final List<String> waste; // Cards in waste

  // Track which positions cover which (static structure)
  static final List<List<int>> _covers = _buildCoverStructure();

  PyramidSolverState({
    required this.pyramid,
    required this.stock,
    required this.waste,
  });

  static List<List<int>> _buildCoverStructure() {
    final covers = <List<int>>[];
    for (int row = 0; row < 7; row++) {
      for (int col = 0; col <= row; col++) {
        final covering = <int>[];
        if (row < 6) {
          final nextRowStart = (row + 1) * (row + 2) ~/ 2;
          covering.add(nextRowStart + col);
          covering.add(nextRowStart + col + 1);
        }
        covers.add(covering);
      }
    }
    return covers;
  }

  /// Check if a pyramid position is uncovered
  bool isUncovered(int index) {
    if (index < 0 || index >= 28) return false;
    if (pyramid[index] == null) return false;

    // Check if any card is covering this position
    for (int i = 0; i < 28; i++) {
      if (_covers[i].contains(index) && pyramid[i] != null) {
        return false;
      }
    }
    return true;
  }

  /// Creates a copy with modified fields.
  PyramidSolverState copyWith({
    List<String?>? pyramid,
    List<String>? stock,
    List<String>? waste,
  }) {
    return PyramidSolverState(
      pyramid: pyramid ?? List.from(this.pyramid),
      stock: stock ?? List.from(this.stock),
      waste: waste ?? List.from(this.waste),
    );
  }

  @override
  List<PyramidMove> getAvailableMoves() {
    final moves = <PyramidMove>[];

    // Collect all matchable cards
    final uncoveredPyramid = <int>[];
    for (int i = 0; i < 28; i++) {
      if (isUncovered(i)) {
        uncoveredPyramid.add(i);
      }
    }

    // Remove Kings from pyramid
    for (final idx in uncoveredPyramid) {
      final card = PyramidCard(pyramid[idx]!);
      if (card.isKing) {
        moves.add(PyramidMove(PyramidMoveType.removeKing, idx));
      }
    }

    // Remove King from waste
    if (waste.isNotEmpty) {
      final wasteTop = PyramidCard(waste.last);
      if (wasteTop.isKing) {
        moves.add(PyramidMove(PyramidMoveType.removeKing, -1));
      }
    }

    // Match pairs within pyramid
    for (int i = 0; i < uncoveredPyramid.length; i++) {
      final card1 = PyramidCard(pyramid[uncoveredPyramid[i]]!);
      if (card1.isKing) continue;

      for (int j = i + 1; j < uncoveredPyramid.length; j++) {
        final card2 = PyramidCard(pyramid[uncoveredPyramid[j]]!);
        if (card1.pairsWith(card2)) {
          moves.add(PyramidMove(
            PyramidMoveType.matchPair,
            uncoveredPyramid[i],
            uncoveredPyramid[j],
          ));
        }
      }
    }

    // Match pyramid with waste
    if (waste.isNotEmpty) {
      final wasteTop = PyramidCard(waste.last);
      if (!wasteTop.isKing) {
        for (final idx in uncoveredPyramid) {
          final pyramidCard = PyramidCard(pyramid[idx]!);
          if (pyramidCard.pairsWith(wasteTop)) {
            moves.add(PyramidMove(PyramidMoveType.matchPair, idx, -1));
          }
        }
      }
    }

    // Draw from stock
    if (stock.isNotEmpty) {
      moves.add(PyramidMove(PyramidMoveType.drawFromStock, -1));
    }

    // Recycle waste (only if stock is empty and waste has cards)
    if (stock.isEmpty && waste.isNotEmpty) {
      moves.add(PyramidMove(PyramidMoveType.recycleWaste, -1));
    }

    return moves;
  }

  @override
  SolverState<PyramidMove> applyMove(PyramidMove move) {
    switch (move.type) {
      case PyramidMoveType.removeKing:
        if (move.cardIndex1 == -1) {
          // King from waste
          final newWaste = List<String>.from(waste);
          newWaste.removeLast();
          return copyWith(waste: newWaste);
        } else {
          // King from pyramid
          final newPyramid = List<String?>.from(pyramid);
          newPyramid[move.cardIndex1] = null;
          return copyWith(pyramid: newPyramid);
        }

      case PyramidMoveType.matchPair:
        final newPyramid = List<String?>.from(pyramid);

        if (move.cardIndex2 == -1) {
          // Matching pyramid with waste
          newPyramid[move.cardIndex1] = null;
          final newWaste = List<String>.from(waste);
          newWaste.removeLast();
          return copyWith(pyramid: newPyramid, waste: newWaste);
        } else {
          // Matching two pyramid cards
          newPyramid[move.cardIndex1] = null;
          newPyramid[move.cardIndex2] = null;
          return copyWith(pyramid: newPyramid);
        }

      case PyramidMoveType.drawFromStock:
        final newStock = List<String>.from(stock);
        final card = newStock.removeLast();
        final newWaste = List<String>.from(waste)..add(card);
        return copyWith(stock: newStock, waste: newWaste);

      case PyramidMoveType.recycleWaste:
        // Waste goes back to stock (reversed)
        final newStock = waste.reversed.toList();
        return copyWith(stock: newStock, waste: []);
    }
  }

  @override
  bool get isWon => pyramid.every((card) => card == null);

  @override
  String get signature {
    return jsonEncode({
      'pyramid': pyramid,
      'stock': stock.length, // Only track count for stock
      'waste': waste.isEmpty ? '' : waste.last, // Only top of waste matters
    });
  }

  @override
  int get heuristicScore {
    if (isWon) return 1000;

    int score = 0;

    // Count removed pyramid cards (very valuable)
    final removedCount = pyramid.where((c) => c == null).length;
    score += removedCount * 20;

    // Bonus for uncovered cards (more options)
    for (int i = 0; i < 28; i++) {
      if (isUncovered(i)) score += 3;
    }

    // Bonus for accessible Kings
    for (int i = 0; i < 28; i++) {
      if (isUncovered(i) && pyramid[i] != null) {
        final card = PyramidCard(pyramid[i]!);
        if (card.isKing) score += 5;
      }
    }

    // Bonus for matching pairs available
    final uncovered = <int>[];
    for (int i = 0; i < 28; i++) {
      if (isUncovered(i)) uncovered.add(i);
    }

    for (int i = 0; i < uncovered.length; i++) {
      final card1 = PyramidCard(pyramid[uncovered[i]]!);
      for (int j = i + 1; j < uncovered.length; j++) {
        final card2 = PyramidCard(pyramid[uncovered[j]]!);
        if (card1.pairsWith(card2)) score += 8;
      }
    }

    return score;
  }
}
