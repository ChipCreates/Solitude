import 'dart:convert';

import '../abstract_solver.dart';

/// Represents a card in the Golf solver.
/// Format: 'rankSuit' where rank 1-13 (1=Ace, 13=King), suit H/D/C/S.
class GolfCard {
  final String value;

  GolfCard(this.value);

  int get rank => int.parse(value.substring(0, value.length - 1));

  String get suit => value.substring(value.length - 1);

  @override
  String toString() => value;

  /// Check if this card can be played to waste (+/- 1 rank)
  bool canPlayOn(GolfCard wasteTop, {bool allowWrapping = false}) {
    final diff = (rank - wasteTop.rank).abs();
    if (allowWrapping) {
      return diff == 1 || diff == 12; // 12 handles K-A wrapping
    }
    return diff == 1;
  }
}

/// Enum for different move types in Golf.
enum GolfMoveType {
  tableauToWaste,
  drawFromStock,
}

/// Represents a move in Golf solitaire.
class GolfMove extends SolverMove {
  final GolfMoveType type;
  final int tableauIndex; // Which tableau pile (-1 for stock draw)

  GolfMove(this.type, this.tableauIndex);

  @override
  int get priority => _calculatePriority();

  int _calculatePriority() {
    switch (type) {
      case GolfMoveType.tableauToWaste:
        return 5; // Prefer playing cards
      case GolfMoveType.drawFromStock:
        return 2; // Draw when needed
    }
  }

  @override
  String toString() => '$type idx:$tableauIndex';
}

/// Lightweight state representation for Golf solver.
class GolfSolverState implements SolverState<GolfMove> {
  final List<List<String>> tableau; // 7 piles
  final List<String> stock;
  final String? wasteTop; // Only top matters
  final bool allowWrapping;

  GolfSolverState({
    required this.tableau,
    required this.stock,
    required this.wasteTop,
    this.allowWrapping = false,
  });

  /// Creates a copy with modified fields.
  GolfSolverState copyWith({
    List<List<String>>? tableau,
    List<String>? stock,
    String? wasteTop,
    bool? allowWrapping,
  }) {
    return GolfSolverState(
      tableau: tableau ?? List.from(this.tableau.map((p) => List.from(p))),
      stock: stock ?? List.from(this.stock),
      wasteTop: wasteTop ?? this.wasteTop,
      allowWrapping: allowWrapping ?? this.allowWrapping,
    );
  }

  @override
  List<GolfMove> getAvailableMoves() {
    final moves = <GolfMove>[];

    // Tableau to waste moves
    if (wasteTop != null) {
      final wasteCard = GolfCard(wasteTop!);

      for (int i = 0; i < 7; i++) {
        if (tableau[i].isEmpty) continue;
        final topCard = GolfCard(tableau[i].last);
        if (topCard.canPlayOn(wasteCard, allowWrapping: allowWrapping)) {
          moves.add(GolfMove(GolfMoveType.tableauToWaste, i));
        }
      }
    }

    // Draw from stock
    if (stock.isNotEmpty) {
      moves.add(GolfMove(GolfMoveType.drawFromStock, -1));
    }

    return moves;
  }

  @override
  SolverState<GolfMove> applyMove(GolfMove move) {
    switch (move.type) {
      case GolfMoveType.tableauToWaste:
        final newTableau =
            List<List<String>>.from(tableau.map((p) => List<String>.from(p)));
        final card = newTableau[move.tableauIndex].removeLast();
        return copyWith(tableau: newTableau, wasteTop: card);

      case GolfMoveType.drawFromStock:
        final newStock = List<String>.from(stock);
        final card = newStock.removeLast();
        return copyWith(stock: newStock, wasteTop: card);
    }
  }

  @override
  bool get isWon => tableau.every((pile) => pile.isEmpty);

  @override
  String get signature {
    return jsonEncode({
      'tableau': tableau.map((p) => p.isEmpty ? '' : p.last).toList(),
      'stock': stock.length,
      'waste': wasteTop,
    });
  }

  @override
  int get heuristicScore {
    if (isWon) return 1000;

    int score = 0;

    // Count cards cleared (35 - remaining)
    int remaining = 0;
    for (final pile in tableau) {
      remaining += pile.length;
    }
    score += (35 - remaining) * 15;

    // Bonus for available moves
    if (wasteTop != null) {
      final wasteCard = GolfCard(wasteTop!);
      for (int i = 0; i < 7; i++) {
        if (tableau[i].isEmpty) continue;
        final topCard = GolfCard(tableau[i].last);
        if (topCard.canPlayOn(wasteCard, allowWrapping: allowWrapping)) {
          score += 10;
        }
      }
    }

    // Penalty for empty stock (fewer options)
    if (stock.isEmpty) score -= 20;

    // Bonus for empty piles
    score += tableau.where((p) => p.isEmpty).length * 5;

    return score;
  }
}
