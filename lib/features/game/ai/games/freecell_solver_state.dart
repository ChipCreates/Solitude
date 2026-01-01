import 'dart:convert';

import '../abstract_solver.dart';

/// Represents a card in the FreeCell solver.
/// Format: 'rankSuit' where rank 1-13 (1=Ace, 13=King), suit H/D/C/S.
class FreeCellCard {
  final String value;

  FreeCellCard(this.value);

  int get rank => int.parse(value.substring(0, value.length - 1));

  String get suit => value.substring(value.length - 1);

  bool get isRed => suit == 'H' || suit == 'D';

  bool get isBlack => !isRed;

  @override
  String toString() => value;

  /// Check if this card can be placed on top of another in tableau.
  /// (Alternating colors, descending rank)
  bool canPlaceOn(FreeCellCard other) {
    return (isRed && other.isBlack || isBlack && other.isRed) &&
        rank == other.rank - 1;
  }

  /// Check if this card can be placed in foundation on top of another.
  bool canPlaceOnFoundation(FreeCellCard? other) {
    if (other == null) return rank == 1;
    return suit == other.suit && rank == other.rank + 1;
  }
}

/// Enum for different move types in FreeCell.
enum FreeCellMoveType {
  tableauToTableau,
  tableauToFoundation,
  tableauToCell,
  cellToTableau,
  cellToFoundation,
}

/// Represents a move in FreeCell solitaire.
class FreeCellMove extends SolverMove {
  final FreeCellMoveType type;
  final int fromIndex; // Pile/cell index
  final int toIndex; // Pile/cell/foundation index
  final int cardCount; // Number of cards to move (for supermoves)

  FreeCellMove(this.type, this.fromIndex, this.toIndex, [this.cardCount = 1]);

  @override
  int get priority => _calculatePriority();

  int _calculatePriority() {
    switch (type) {
      case FreeCellMoveType.tableauToFoundation:
      case FreeCellMoveType.cellToFoundation:
        return 10; // High priority for foundation moves
      case FreeCellMoveType.cellToTableau:
        return 7; // Good to free up cells
      case FreeCellMoveType.tableauToTableau:
        return 5; // Medium for tableau moves
      case FreeCellMoveType.tableauToCell:
        return 2; // Low priority - use cells sparingly
    }
  }

  @override
  String toString() => '$type from:$fromIndex to:$toIndex cards:$cardCount';
}

/// Lightweight state representation for FreeCell solver.
class FreeCellSolverState implements SolverState<FreeCellMove> {
  final List<List<String>> tableau; // 8 piles
  final List<String?> freeCells; // 4 cells, null if empty
  final List<String?>
      foundation; // Top card for each suit H,D,C,S, null if empty

  FreeCellSolverState({
    required this.tableau,
    required this.freeCells,
    required this.foundation,
  });

  /// Creates a copy with modified fields.
  FreeCellSolverState copyWith({
    List<List<String>>? tableau,
    List<String?>? freeCells,
    List<String?>? foundation,
  }) {
    return FreeCellSolverState(
      tableau: tableau ?? List.from(this.tableau.map((p) => List.from(p))),
      freeCells: freeCells ?? List.from(this.freeCells),
      foundation: foundation ?? List.from(this.foundation),
    );
  }

  /// Calculate max moveable cards: (emptyCells + 1) * 2^emptyColumns
  int get _maxMoveableCards {
    final emptyCells = freeCells.where((c) => c == null).length;
    final emptyColumns = tableau.where((t) => t.isEmpty).length;
    return (emptyCells + 1) * (1 << emptyColumns);
  }

  /// Calculate max moveable cards when moving TO an empty column
  int get _maxMoveableCardsToEmpty {
    final emptyCells = freeCells.where((c) => c == null).length;
    int emptyColumns = tableau.where((t) => t.isEmpty).length - 1;
    if (emptyColumns < 0) emptyColumns = 0;
    return (emptyCells + 1) * (1 << emptyColumns);
  }

  /// Check if cards form valid alternating-color descending sequence
  bool _isValidSequence(List<String> cards) {
    if (cards.length <= 1) return true;
    for (int i = 1; i < cards.length; i++) {
      final prev = FreeCellCard(cards[i - 1]);
      final curr = FreeCellCard(cards[i]);
      if (curr.isRed == prev.isRed || curr.rank != prev.rank - 1) {
        return false;
      }
    }
    return true;
  }

  int _suitIndex(String suit) {
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
        throw ArgumentError('Invalid suit: $suit');
    }
  }

  @override
  List<FreeCellMove> getAvailableMoves() {
    final moves = <FreeCellMove>[];

    // Moves from free cells
    for (int cellIdx = 0; cellIdx < 4; cellIdx++) {
      final cellCard = freeCells[cellIdx];
      if (cellCard == null) continue;

      final card = FreeCellCard(cellCard);

      // Cell to foundation
      final suitIdx = _suitIndex(card.suit);
      final foundTop = foundation[suitIdx];
      if (foundTop == null && card.rank == 1) {
        moves.add(
            FreeCellMove(FreeCellMoveType.cellToFoundation, cellIdx, suitIdx));
      } else if (foundTop != null &&
          card.canPlaceOnFoundation(FreeCellCard(foundTop))) {
        moves.add(
            FreeCellMove(FreeCellMoveType.cellToFoundation, cellIdx, suitIdx));
      }

      // Cell to tableau
      for (int pileIdx = 0; pileIdx < 8; pileIdx++) {
        if (tableau[pileIdx].isEmpty) {
          moves.add(
              FreeCellMove(FreeCellMoveType.cellToTableau, cellIdx, pileIdx));
        } else {
          final topCard = FreeCellCard(tableau[pileIdx].last);
          if (card.canPlaceOn(topCard)) {
            moves.add(
                FreeCellMove(FreeCellMoveType.cellToTableau, cellIdx, pileIdx));
          }
        }
      }
    }

    // Moves from tableau
    for (int fromPile = 0; fromPile < 8; fromPile++) {
      if (tableau[fromPile].isEmpty) continue;

      // Try moving different sequence lengths
      for (int startIdx = 0; startIdx < tableau[fromPile].length; startIdx++) {
        final cardsToMove = tableau[fromPile].sublist(startIdx);
        if (!_isValidSequence(cardsToMove)) continue;

        final topCard = FreeCellCard(cardsToMove.first);
        final cardCount = cardsToMove.length;

        // Single card to foundation
        if (cardCount == 1) {
          final suitIdx = _suitIndex(topCard.suit);
          final foundTop = foundation[suitIdx];
          if (foundTop == null && topCard.rank == 1) {
            moves.add(FreeCellMove(
                FreeCellMoveType.tableauToFoundation, fromPile, suitIdx));
          } else if (foundTop != null &&
              topCard.canPlaceOnFoundation(FreeCellCard(foundTop))) {
            moves.add(FreeCellMove(
                FreeCellMoveType.tableauToFoundation, fromPile, suitIdx));
          }
        }

        // To other tableau piles
        for (int toPile = 0; toPile < 8; toPile++) {
          if (toPile == fromPile) continue;

          final maxCards = tableau[toPile].isEmpty
              ? _maxMoveableCardsToEmpty
              : _maxMoveableCards;
          if (cardCount > maxCards) continue;

          if (tableau[toPile].isEmpty) {
            // Any sequence can go on empty pile (if we have capacity)
            moves.add(FreeCellMove(FreeCellMoveType.tableauToTableau, fromPile,
                toPile, cardCount));
          } else {
            final destTop = FreeCellCard(tableau[toPile].last);
            if (topCard.canPlaceOn(destTop)) {
              moves.add(FreeCellMove(FreeCellMoveType.tableauToTableau,
                  fromPile, toPile, cardCount));
            }
          }
        }

        // Single card to free cell
        if (cardCount == 1) {
          for (int cellIdx = 0; cellIdx < 4; cellIdx++) {
            if (freeCells[cellIdx] == null) {
              moves.add(FreeCellMove(
                  FreeCellMoveType.tableauToCell, fromPile, cellIdx));
              break; // Only need one empty cell move
            }
          }
        }
      }
    }

    return moves;
  }

  @override
  SolverState<FreeCellMove> applyMove(FreeCellMove move) {
    switch (move.type) {
      case FreeCellMoveType.cellToFoundation:
        final card = freeCells[move.fromIndex]!;
        final newCells = List<String?>.from(freeCells);
        newCells[move.fromIndex] = null;
        final newFoundation = List<String?>.from(foundation);
        newFoundation[move.toIndex] = card;
        return copyWith(freeCells: newCells, foundation: newFoundation);

      case FreeCellMoveType.cellToTableau:
        final card = freeCells[move.fromIndex]!;
        final newCells = List<String?>.from(freeCells);
        newCells[move.fromIndex] = null;
        final newTableau =
            List<List<String>>.from(tableau.map((p) => List.from(p)));
        newTableau[move.toIndex].add(card);
        return copyWith(freeCells: newCells, tableau: newTableau);

      case FreeCellMoveType.tableauToFoundation:
        final pile = tableau[move.fromIndex];
        final card = pile.last;
        final newTableau =
            List<List<String>>.from(tableau.map((p) => List.from(p)));
        newTableau[move.fromIndex].removeLast();
        final newFoundation = List<String?>.from(foundation);
        newFoundation[move.toIndex] = card;
        return copyWith(tableau: newTableau, foundation: newFoundation);

      case FreeCellMoveType.tableauToTableau:
        final fromPile = tableau[move.fromIndex];
        final startIdx = fromPile.length - move.cardCount;
        final cardsToMove = fromPile.sublist(startIdx);
        final newTableau =
            List<List<String>>.from(tableau.map((p) => List.from(p)));
        newTableau[move.fromIndex] = fromPile.sublist(0, startIdx);
        newTableau[move.toIndex].addAll(cardsToMove);
        return copyWith(tableau: newTableau);

      case FreeCellMoveType.tableauToCell:
        final card = tableau[move.fromIndex].last;
        final newTableau =
            List<List<String>>.from(tableau.map((p) => List.from(p)));
        newTableau[move.fromIndex].removeLast();
        final newCells = List<String?>.from(freeCells);
        newCells[move.toIndex] = card;
        return copyWith(tableau: newTableau, freeCells: newCells);
    }
  }

  @override
  bool get isWon =>
      foundation.every((f) => f != null && FreeCellCard(f).rank == 13);

  @override
  String get signature {
    // Normalize tableau by sorting (order doesn't matter for equivalence)
    final sortedTableau =
        List<List<String>>.from(tableau.map((p) => List.from(p)));
    sortedTableau.sort((a, b) => a.join(',').compareTo(b.join(',')));

    return jsonEncode({
      'tableau': sortedTableau,
      'cells': freeCells,
      'foundation': foundation,
    });
  }

  @override
  int get heuristicScore {
    if (isWon) return 1000;

    int score = 0;

    // Foundation cards are very valuable
    for (final f in foundation) {
      if (f != null) score += 15 * FreeCellCard(f).rank;
    }

    // Empty cells are valuable
    score += freeCells.where((c) => c == null).length * 5;

    // Empty tableau columns are very valuable
    score += tableau.where((t) => t.isEmpty).length * 10;

    // Cards in proper sequences are valuable
    for (final pile in tableau) {
      if (pile.length > 1) {
        for (int i = pile.length - 1; i > 0; i--) {
          final lower = FreeCellCard(pile[i]);
          final upper = FreeCellCard(pile[i - 1]);
          if (lower.canPlaceOn(upper)) {
            score += 2;
          } else {
            break;
          }
        }
      }
    }

    return score;
  }
}
