import 'dart:convert';

import '../abstract_solver.dart';

/// Represents a card in the Forty Thieves solver.
/// Format: 'rankSuit' where rank 1-13 (1=Ace, 13=King), suit H/D/C/S.
class FortyThievesCard {
  final String value;

  FortyThievesCard(this.value);

  int get rank => int.parse(value.substring(0, value.length - 1));

  String get suit => value.substring(value.length - 1);

  @override
  String toString() => value;

  /// Check if this card can be placed on another in tableau (same suit, descending)
  bool canStackOn(FortyThievesCard other) {
    return suit == other.suit && rank == other.rank - 1;
  }

  /// Check if this card can be placed on foundation
  bool canStackOnFoundation(FortyThievesCard? foundationTop) {
    if (foundationTop == null) {
      return rank == 1; // Only Aces on empty foundation
    }
    return suit == foundationTop.suit && rank == foundationTop.rank + 1;
  }
}

/// Enum for different move types in Forty Thieves.
enum FortyThievesMoveType {
  tableauToTableau,
  tableauToFoundation,
  wasteToTableau,
  wasteToFoundation,
  drawFromStock,
}

/// Represents a move in Forty Thieves solitaire.
class FortyThievesMove extends SolverMove {
  final FortyThievesMoveType type;
  final int fromIndex; // Source index (tableau or waste = -1)
  final int toIndex; // Destination index

  FortyThievesMove(this.type, this.fromIndex, this.toIndex);

  @override
  int get priority => _calculatePriority();

  int _calculatePriority() {
    switch (type) {
      case FortyThievesMoveType.tableauToFoundation:
      case FortyThievesMoveType.wasteToFoundation:
        return 10; // Prioritize foundation moves
      case FortyThievesMoveType.tableauToTableau:
        return 5;
      case FortyThievesMoveType.wasteToTableau:
        return 4;
      case FortyThievesMoveType.drawFromStock:
        return 2;
    }
  }

  @override
  String toString() => '$type from:$fromIndex to:$toIndex';
}

/// Lightweight state representation for Forty Thieves solver.
class FortyThievesSolverState implements SolverState<FortyThievesMove> {
  final List<List<String>> tableau; // 10 piles
  final List<String?> foundations; // 8 foundations (top card or null)
  final List<String> stock;
  final String? wasteTop;

  FortyThievesSolverState({
    required this.tableau,
    required this.foundations,
    required this.stock,
    required this.wasteTop,
  });

  /// Creates a copy with modified fields.
  FortyThievesSolverState copyWith({
    List<List<String>>? tableau,
    List<String?>? foundations,
    List<String>? stock,
    String? wasteTop,
    bool clearWaste = false,
  }) {
    return FortyThievesSolverState(
      tableau:
          tableau ?? List.from(this.tableau.map((p) => List<String>.from(p))),
      foundations: foundations ?? List.from(this.foundations),
      stock: stock ?? List.from(this.stock),
      wasteTop: clearWaste ? null : (wasteTop ?? this.wasteTop),
    );
  }

  /// Gets foundation index for a suit (returns any foundation that matches or empty one)
  int? _findFoundationForCard(FortyThievesCard card) {
    // First look for matching suit that can accept the card
    for (int i = 0; i < 8; i++) {
      final foundTop = foundations[i];
      if (foundTop != null) {
        final topCard = FortyThievesCard(foundTop);
        if (card.canStackOnFoundation(topCard)) {
          return i;
        }
      }
    }
    // Then look for empty foundation for aces
    if (card.rank == 1) {
      for (int i = 0; i < 8; i++) {
        if (foundations[i] == null) {
          return i;
        }
      }
    }
    return null;
  }

  @override
  List<FortyThievesMove> getAvailableMoves() {
    final moves = <FortyThievesMove>[];

    // Tableau to foundation/tableau moves
    for (int t = 0; t < 10; t++) {
      if (tableau[t].isEmpty) continue;
      final card = FortyThievesCard(tableau[t].last);

      // To foundation
      final foundIdx = _findFoundationForCard(card);
      if (foundIdx != null) {
        moves.add(FortyThievesMove(
          FortyThievesMoveType.tableauToFoundation,
          t,
          foundIdx,
        ));
      }

      // To other tableau
      for (int dest = 0; dest < 10; dest++) {
        if (dest == t) continue;
        if (tableau[dest].isEmpty) {
          // Any card to empty
          moves.add(FortyThievesMove(
            FortyThievesMoveType.tableauToTableau,
            t,
            dest,
          ));
        } else {
          final destTop = FortyThievesCard(tableau[dest].last);
          if (card.canStackOn(destTop)) {
            moves.add(FortyThievesMove(
              FortyThievesMoveType.tableauToTableau,
              t,
              dest,
            ));
          }
        }
      }
    }

    // Waste moves
    if (wasteTop != null) {
      final card = FortyThievesCard(wasteTop!);

      // To foundation
      final foundIdx = _findFoundationForCard(card);
      if (foundIdx != null) {
        moves.add(FortyThievesMove(
          FortyThievesMoveType.wasteToFoundation,
          -1,
          foundIdx,
        ));
      }

      // To tableau
      for (int dest = 0; dest < 10; dest++) {
        if (tableau[dest].isEmpty) {
          moves.add(FortyThievesMove(
            FortyThievesMoveType.wasteToTableau,
            -1,
            dest,
          ));
        } else {
          final destTop = FortyThievesCard(tableau[dest].last);
          if (card.canStackOn(destTop)) {
            moves.add(FortyThievesMove(
              FortyThievesMoveType.wasteToTableau,
              -1,
              dest,
            ));
          }
        }
      }
    }

    // Draw from stock
    if (stock.isNotEmpty) {
      moves.add(FortyThievesMove(
        FortyThievesMoveType.drawFromStock,
        -1,
        -1,
      ));
    }

    return moves;
  }

  @override
  SolverState<FortyThievesMove> applyMove(FortyThievesMove move) {
    switch (move.type) {
      case FortyThievesMoveType.tableauToFoundation:
        final newTableau =
            List<List<String>>.from(tableau.map((p) => List<String>.from(p)));
        final newFoundations = List<String?>.from(foundations);
        final card = newTableau[move.fromIndex].removeLast();
        newFoundations[move.toIndex] = card;
        return copyWith(tableau: newTableau, foundations: newFoundations);

      case FortyThievesMoveType.tableauToTableau:
        final newTableau =
            List<List<String>>.from(tableau.map((p) => List<String>.from(p)));
        final card = newTableau[move.fromIndex].removeLast();
        newTableau[move.toIndex].add(card);
        return copyWith(tableau: newTableau);

      case FortyThievesMoveType.wasteToFoundation:
        final newFoundations = List<String?>.from(foundations);
        newFoundations[move.toIndex] = wasteTop;
        return copyWith(foundations: newFoundations, clearWaste: true);

      case FortyThievesMoveType.wasteToTableau:
        final newTableau =
            List<List<String>>.from(tableau.map((p) => List<String>.from(p)));
        newTableau[move.toIndex].add(wasteTop!);
        return copyWith(tableau: newTableau, clearWaste: true);

      case FortyThievesMoveType.drawFromStock:
        final newStock = List<String>.from(stock);
        final card = newStock.removeLast();
        return copyWith(stock: newStock, wasteTop: card);
    }
  }

  @override
  bool get isWon {
    // All 8 foundations must have 13 cards (King on top)
    return foundations.every((f) {
      if (f == null) return false;
      return FortyThievesCard(f).rank == 13;
    });
  }

  @override
  String get signature {
    return jsonEncode({
      'tableau': tableau.map((p) => p.isEmpty ? '' : p.last).toList(),
      'foundations': foundations,
      'stock': stock.length,
      'waste': wasteTop,
    });
  }

  @override
  int get heuristicScore {
    if (isWon) return 10000;

    int score = 0;

    // Foundation progress is most important
    for (final f in foundations) {
      if (f != null) {
        score += FortyThievesCard(f).rank * 15;
      }
    }

    // Bonus for empty tableau piles
    score += tableau.where((p) => p.isEmpty).length * 8;

    // Bonus for available moves
    score += getAvailableMoves().length * 2;

    // Penalty for cards in stock (more options = better)
    score -= stock.length;

    return score;
  }
}
