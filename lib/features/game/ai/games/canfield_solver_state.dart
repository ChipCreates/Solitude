import 'dart:convert';

import '../abstract_solver.dart';

/// Represents a card in the Canfield solver.
/// Format: 'rankSuit' where rank 1-13 (1=Ace, 13=King), suit H/D/C/S.
class CanfieldCard {
  final String value;

  CanfieldCard(this.value);

  int get rank => int.parse(value.substring(0, value.length - 1));

  String get suit => value.substring(value.length - 1);

  bool get isRed => suit == 'H' || suit == 'D';
  bool get isBlack => suit == 'C' || suit == 'S';

  @override
  String toString() => value;

  /// Check if this card can be placed on another in tableau (alternating colors, descending with wrap)
  bool canStackOnTableau(CanfieldCard other) {
    if (isRed == other.isRed) return false; // Must alternate colors
    // Descending with wrap: expected value below other card
    final expected = other.rank == 1 ? 13 : other.rank - 1;
    return rank == expected;
  }

  /// Check if this card can be placed on foundation (same suit, ascending with wrap from base rank)
  bool canStackOnFoundation(CanfieldCard? foundationTop, int baseRank) {
    if (foundationTop == null) {
      return rank == baseRank; // Empty foundation must start with base rank
    }
    if (suit != foundationTop.suit) return false;
    // Ascending with wrap
    final expected = foundationTop.rank == 13 ? 1 : foundationTop.rank + 1;
    return rank == expected;
  }
}

/// Card info with face-up status
class CanfieldCardInfo {
  final String card;
  final bool faceUp;

  CanfieldCardInfo(this.card, this.faceUp);

  @override
  String toString() => faceUp ? card : '?';
}

/// Enum for different move types in Canfield.
enum CanfieldMoveType {
  tableauToTableau,
  tableauToFoundation,
  wasteToTableau,
  wasteToFoundation,
  reserveToTableau,
  reserveToFoundation,
  drawFromStock,
}

/// Represents a move in Canfield solitaire.
class CanfieldMove extends SolverMove {
  final CanfieldMoveType type;
  final int fromIndex; // Source index (for tableau)
  final int toIndex; // Destination index
  final int cardIndex; // For multi-card tableau moves

  CanfieldMove(this.type, this.fromIndex, this.toIndex, [this.cardIndex = -1]);

  @override
  int get priority => _calculatePriority();

  int _calculatePriority() {
    switch (type) {
      case CanfieldMoveType.tableauToFoundation:
      case CanfieldMoveType.wasteToFoundation:
      case CanfieldMoveType.reserveToFoundation:
        return 10; // Prioritize foundation moves
      case CanfieldMoveType.tableauToTableau:
        return 5;
      case CanfieldMoveType.wasteToTableau:
      case CanfieldMoveType.reserveToTableau:
        return 4;
      case CanfieldMoveType.drawFromStock:
        return 2;
    }
  }

  @override
  String toString() => '$type from:$fromIndex[$cardIndex] to:$toIndex';
}

/// Lightweight state representation for Canfield solver.
class CanfieldSolverState implements SolverState<CanfieldMove> {
  final List<List<CanfieldCardInfo>> tableau; // 4 piles
  final List<String?> foundations; // 4 foundations (top card or null)
  final List<CanfieldCardInfo> reserve; // Reserve pile
  final List<String> stock;
  final String? wasteTop;
  final int baseRank; // The base rank for all foundations

  CanfieldSolverState({
    required this.tableau,
    required this.foundations,
    required this.reserve,
    required this.stock,
    required this.wasteTop,
    required this.baseRank,
  });

  /// Creates a copy with modified fields.
  CanfieldSolverState copyWith({
    List<List<CanfieldCardInfo>>? tableau,
    List<String?>? foundations,
    List<CanfieldCardInfo>? reserve,
    List<String>? stock,
    String? wasteTop,
    bool clearWaste = false,
    int? baseRank,
  }) {
    return CanfieldSolverState(
      tableau: tableau ??
          List.from(this.tableau.map((p) => List<CanfieldCardInfo>.from(p))),
      foundations: foundations ?? List.from(this.foundations),
      reserve: reserve ?? List.from(this.reserve),
      stock: stock ?? List.from(this.stock),
      wasteTop: clearWaste ? null : (wasteTop ?? this.wasteTop),
      baseRank: baseRank ?? this.baseRank,
    );
  }

  /// Gets foundation index for a suit
  int _getSuitIndex(String card) {
    final suit = card.substring(card.length - 1);
    switch (suit) {
      case 'H':
        return 0;
      case 'D':
        return 1;
      case 'C':
        return 2;
      case 'S':
        return 3;
      default:
        return 0;
    }
  }

  /// Checks if cards form a valid tableau sequence
  bool _isValidTableauSequence(List<CanfieldCardInfo> cards) {
    if (cards.length <= 1) return true;
    for (int i = 1; i < cards.length; i++) {
      final prev = CanfieldCard(cards[i - 1].card);
      final curr = CanfieldCard(cards[i].card);
      if (!curr.canStackOnTableau(prev)) {
        return false;
      }
    }
    return true;
  }

  @override
  List<CanfieldMove> getAvailableMoves() {
    final moves = <CanfieldMove>[];

    // Tableau moves
    for (int t = 0; t < 4; t++) {
      if (tableau[t].isEmpty) continue;

      // Find movable sequences
      for (int cardIdx = 0; cardIdx < tableau[t].length; cardIdx++) {
        if (!tableau[t][cardIdx].faceUp) continue;

        final cardsToMove = tableau[t].sublist(cardIdx);
        if (!_isValidTableauSequence(cardsToMove)) continue;

        final card = CanfieldCard(tableau[t][cardIdx].card);

        // Foundation move (only top card)
        if (cardIdx == tableau[t].length - 1) {
          final suitIdx = _getSuitIndex(tableau[t][cardIdx].card);
          final foundTop = foundations[suitIdx] != null
              ? CanfieldCard(foundations[suitIdx]!)
              : null;
          if (card.canStackOnFoundation(foundTop, baseRank)) {
            moves.add(CanfieldMove(
              CanfieldMoveType.tableauToFoundation,
              t,
              suitIdx,
              cardIdx,
            ));
          }
        }

        // Tableau to tableau
        for (int dest = 0; dest < 4; dest++) {
          if (dest == t) continue;
          if (tableau[dest].isEmpty) {
            // Any card to empty
            moves.add(CanfieldMove(
              CanfieldMoveType.tableauToTableau,
              t,
              dest,
              cardIdx,
            ));
          } else {
            final destTop = CanfieldCard(tableau[dest].last.card);
            if (card.canStackOnTableau(destTop)) {
              moves.add(CanfieldMove(
                CanfieldMoveType.tableauToTableau,
                t,
                dest,
                cardIdx,
              ));
            }
          }
        }
      }
    }

    // Waste moves
    if (wasteTop != null) {
      final card = CanfieldCard(wasteTop!);
      final suitIdx = _getSuitIndex(wasteTop!);

      // To foundation
      final foundTop = foundations[suitIdx] != null
          ? CanfieldCard(foundations[suitIdx]!)
          : null;
      if (card.canStackOnFoundation(foundTop, baseRank)) {
        moves
            .add(CanfieldMove(CanfieldMoveType.wasteToFoundation, -1, suitIdx));
      }

      // To tableau
      for (int dest = 0; dest < 4; dest++) {
        if (tableau[dest].isEmpty) {
          moves.add(CanfieldMove(CanfieldMoveType.wasteToTableau, -1, dest));
        } else {
          final destTop = CanfieldCard(tableau[dest].last.card);
          if (card.canStackOnTableau(destTop)) {
            moves.add(CanfieldMove(CanfieldMoveType.wasteToTableau, -1, dest));
          }
        }
      }
    }

    // Reserve moves
    if (reserve.isNotEmpty && reserve.last.faceUp) {
      final card = CanfieldCard(reserve.last.card);
      final suitIdx = _getSuitIndex(reserve.last.card);

      // To foundation
      final foundTop = foundations[suitIdx] != null
          ? CanfieldCard(foundations[suitIdx]!)
          : null;
      if (card.canStackOnFoundation(foundTop, baseRank)) {
        moves.add(
            CanfieldMove(CanfieldMoveType.reserveToFoundation, -1, suitIdx));
      }

      // To tableau
      for (int dest = 0; dest < 4; dest++) {
        if (tableau[dest].isEmpty) {
          moves.add(CanfieldMove(CanfieldMoveType.reserveToTableau, -1, dest));
        } else {
          final destTop = CanfieldCard(tableau[dest].last.card);
          if (card.canStackOnTableau(destTop)) {
            moves
                .add(CanfieldMove(CanfieldMoveType.reserveToTableau, -1, dest));
          }
        }
      }
    }

    // Draw from stock
    if (stock.isNotEmpty) {
      moves.add(CanfieldMove(CanfieldMoveType.drawFromStock, -1, -1));
    }

    return moves;
  }

  @override
  SolverState<CanfieldMove> applyMove(CanfieldMove move) {
    switch (move.type) {
      case CanfieldMoveType.tableauToFoundation:
        final newTableau = List<List<CanfieldCardInfo>>.from(
            tableau.map((p) => List<CanfieldCardInfo>.from(p)));
        final newFoundations = List<String?>.from(foundations);
        final card = newTableau[move.fromIndex].removeLast();
        newFoundations[move.toIndex] = card.card;

        // Auto-fill from reserve if empty
        final result =
            copyWith(tableau: newTableau, foundations: newFoundations);
        return result._autoFillTableau();

      case CanfieldMoveType.tableauToTableau:
        final newTableau = List<List<CanfieldCardInfo>>.from(
            tableau.map((p) => List<CanfieldCardInfo>.from(p)));
        final cardsToMove = newTableau[move.fromIndex].sublist(move.cardIndex);
        newTableau[move.fromIndex] =
            newTableau[move.fromIndex].sublist(0, move.cardIndex);
        newTableau[move.toIndex].addAll(cardsToMove);

        final result = copyWith(tableau: newTableau);
        return result._autoFillTableau();

      case CanfieldMoveType.wasteToFoundation:
        final newFoundations = List<String?>.from(foundations);
        newFoundations[move.toIndex] = wasteTop;
        return copyWith(foundations: newFoundations, clearWaste: true);

      case CanfieldMoveType.wasteToTableau:
        final newTableau = List<List<CanfieldCardInfo>>.from(
            tableau.map((p) => List<CanfieldCardInfo>.from(p)));
        newTableau[move.toIndex].add(CanfieldCardInfo(wasteTop!, true));
        return copyWith(tableau: newTableau, clearWaste: true);

      case CanfieldMoveType.reserveToFoundation:
        final newReserve = List<CanfieldCardInfo>.from(reserve);
        final newFoundations = List<String?>.from(foundations);
        final card = newReserve.removeLast();
        newFoundations[move.toIndex] = card.card;
        // Flip new top of reserve
        if (newReserve.isNotEmpty && !newReserve.last.faceUp) {
          newReserve[newReserve.length - 1] =
              CanfieldCardInfo(newReserve.last.card, true);
        }
        return copyWith(reserve: newReserve, foundations: newFoundations);

      case CanfieldMoveType.reserveToTableau:
        final newReserve = List<CanfieldCardInfo>.from(reserve);
        final newTableau = List<List<CanfieldCardInfo>>.from(
            tableau.map((p) => List<CanfieldCardInfo>.from(p)));
        final card = newReserve.removeLast();
        newTableau[move.toIndex].add(CanfieldCardInfo(card.card, true));
        // Flip new top of reserve
        if (newReserve.isNotEmpty && !newReserve.last.faceUp) {
          newReserve[newReserve.length - 1] =
              CanfieldCardInfo(newReserve.last.card, true);
        }
        return copyWith(reserve: newReserve, tableau: newTableau);

      case CanfieldMoveType.drawFromStock:
        final newStock = List<String>.from(stock);
        // Draw up to 3 cards
        String? newWaste;
        for (int i = 0; i < 3 && newStock.isNotEmpty; i++) {
          newWaste = newStock.removeLast();
        }
        return copyWith(stock: newStock, wasteTop: newWaste);
    }
  }

  /// Auto-fill empty tableau from reserve
  CanfieldSolverState _autoFillTableau() {
    if (reserve.isEmpty) return this;

    final newTableau = List<List<CanfieldCardInfo>>.from(
        tableau.map((p) => List<CanfieldCardInfo>.from(p)));
    final newReserve = List<CanfieldCardInfo>.from(reserve);
    bool changed = false;

    for (int t = 0; t < 4; t++) {
      if (newTableau[t].isEmpty && newReserve.isNotEmpty) {
        final card = newReserve.removeLast();
        newTableau[t].add(CanfieldCardInfo(card.card, true));
        // Flip new top
        if (newReserve.isNotEmpty && !newReserve.last.faceUp) {
          newReserve[newReserve.length - 1] =
              CanfieldCardInfo(newReserve.last.card, true);
        }
        changed = true;
      }
    }

    if (!changed) return this;
    return copyWith(tableau: newTableau, reserve: newReserve);
  }

  @override
  bool get isWon => foundations.every((f) {
        if (f == null) return false;
        // Foundation is complete when it has 13 cards
        // Check if top card is one below base rank (wrapped)
        final card = CanfieldCard(f);
        final expectedTop = baseRank == 1 ? 13 : baseRank - 1;
        return card.rank == expectedTop;
      });

  @override
  String get signature {
    return jsonEncode({
      'tableau': tableau.map((p) => p.map((c) => c.card).join(',')).toList(),
      'foundations': foundations,
      'reserve': reserve.length,
      'stock': stock.length,
      'waste': wasteTop,
    });
  }

  @override
  int get heuristicScore {
    if (isWon) return 10000;

    int score = 0;

    // Foundation progress
    for (final f in foundations) {
      if (f != null) {
        score += 15; // Each foundation card
      }
    }

    // Bonus for empty reserve
    if (reserve.isEmpty) score += 50;
    score += (13 - reserve.length) * 3;

    // Penalty for cards in stock
    score -= stock.length;

    // Bonus for face-up tableau cards
    for (final pile in tableau) {
      for (final card in pile) {
        if (card.faceUp) score += 1;
      }
    }

    return score;
  }
}
