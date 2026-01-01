import 'dart:convert';

import '../abstract_solver.dart';

/// Represents a card in the Scorpion solver.
/// Format: 'rankSuit' where rank 1-13 (1=Ace, 13=King), suit H/D/C/S.
class ScorpionCard {
  final String value;
  final bool faceUp;

  ScorpionCard(this.value, {this.faceUp = true});

  int get rank => int.parse(value.substring(0, value.length - 1));

  String get suit => value.substring(value.length - 1);

  @override
  String toString() => faceUp ? value : '?';

  /// Check if this card can be placed on another in tableau (same suit, descending)
  bool canStackOn(ScorpionCard other) {
    if (suit != other.suit) return false; // Must be same suit
    return rank == other.rank - 1; // Must be descending
  }
}

/// Card info with face-up status
class ScorpionCardInfo {
  final String card;
  final bool faceUp;

  ScorpionCardInfo(this.card, this.faceUp);

  @override
  String toString() => faceUp ? card : '?';
}

/// Enum for different move types in Scorpion.
enum ScorpionMoveType {
  tableauToTableau,
  dealFromStock,
}

/// Represents a move in Scorpion solitaire.
class ScorpionMove extends SolverMove {
  final ScorpionMoveType type;
  final int fromTableau;
  final int toTableau;
  final int cardIndex; // Index of the first card to move

  ScorpionMove(this.type, this.fromTableau, this.toTableau, this.cardIndex);

  @override
  int get priority => _calculatePriority();

  int _calculatePriority() {
    switch (type) {
      case ScorpionMoveType.tableauToTableau:
        return 5;
      case ScorpionMoveType.dealFromStock:
        return 2;
    }
  }

  @override
  String toString() => '$type from:$fromTableau[$cardIndex] to:$toTableau';
}

/// Lightweight state representation for Scorpion solver.
class ScorpionSolverState implements SolverState<ScorpionMove> {
  final List<List<ScorpionCardInfo>> tableau; // 7 piles with face-up status
  final List<String> stock; // The "tail" (3 cards)
  final int completedSuits;

  ScorpionSolverState({
    required this.tableau,
    required this.stock,
    required this.completedSuits,
  });

  /// Creates a copy with modified fields.
  ScorpionSolverState copyWith({
    List<List<ScorpionCardInfo>>? tableau,
    List<String>? stock,
    int? completedSuits,
  }) {
    return ScorpionSolverState(
      tableau: tableau ??
          List.from(this.tableau.map((p) => List<ScorpionCardInfo>.from(p))),
      stock: stock ?? List.from(this.stock),
      completedSuits: completedSuits ?? this.completedSuits,
    );
  }

  /// Check for and count completed suit sequences
  int _countCompletedSuits(List<List<ScorpionCardInfo>> tableauState) {
    int completed = 0;

    for (final pile in tableauState) {
      if (pile.length < 13) continue;

      // Check if bottom 13 cards form a complete suit sequence K-A
      final start = pile.length - 13;
      final firstCard = ScorpionCard(pile[start].card);
      if (firstCard.rank != 13) continue; // Must start with King

      bool isComplete = true;
      final suit = firstCard.suit;

      for (int i = 0; i < 13; i++) {
        final card = ScorpionCard(pile[start + i].card);
        if (card.suit != suit || card.rank != 13 - i) {
          isComplete = false;
          break;
        }
      }

      if (isComplete) completed++;
    }

    return completed;
  }

  @override
  List<ScorpionMove> getAvailableMoves() {
    final moves = <ScorpionMove>[];

    // Tableau to tableau moves
    for (int t = 0; t < 7; t++) {
      if (tableau[t].isEmpty) continue;

      // Find all face-up cards - each can be moved with all cards above it
      for (int cardIdx = 0; cardIdx < tableau[t].length; cardIdx++) {
        final cardInfo = tableau[t][cardIdx];
        if (!cardInfo.faceUp) continue;

        final card = ScorpionCard(cardInfo.card);

        for (int dest = 0; dest < 7; dest++) {
          if (dest == t) continue;

          if (tableau[dest].isEmpty) {
            // Only Kings to empty
            if (card.rank == 13) {
              moves.add(ScorpionMove(
                ScorpionMoveType.tableauToTableau,
                t,
                dest,
                cardIdx,
              ));
            }
          } else {
            final destTop = ScorpionCard(tableau[dest].last.card);
            if (card.canStackOn(destTop)) {
              moves.add(ScorpionMove(
                ScorpionMoveType.tableauToTableau,
                t,
                dest,
                cardIdx,
              ));
            }
          }
        }
      }
    }

    // Deal from stock
    if (stock.isNotEmpty) {
      moves.add(ScorpionMove(ScorpionMoveType.dealFromStock, -1, -1, -1));
    }

    return moves;
  }

  @override
  SolverState<ScorpionMove> applyMove(ScorpionMove move) {
    switch (move.type) {
      case ScorpionMoveType.tableauToTableau:
        final newTableau = List<List<ScorpionCardInfo>>.from(
            tableau.map((p) => List<ScorpionCardInfo>.from(p)));

        // Move cards from index to end
        final cardsToMove =
            newTableau[move.fromTableau].sublist(move.cardIndex);
        newTableau[move.fromTableau] =
            newTableau[move.fromTableau].sublist(0, move.cardIndex);
        newTableau[move.toTableau].addAll(cardsToMove);

        // Flip newly exposed card
        if (newTableau[move.fromTableau].isNotEmpty &&
            !newTableau[move.fromTableau].last.faceUp) {
          final lastCard = newTableau[move.fromTableau].last;
          newTableau[move.fromTableau]
                  [newTableau[move.fromTableau].length - 1] =
              ScorpionCardInfo(lastCard.card, true);
        }

        // Check for completed suits
        final newCompleted = _countCompletedSuits(newTableau);
        if (newCompleted > completedSuits) {
          // Remove completed suit from tableau
          for (int p = 0; p < 7; p++) {
            if (newTableau[p].length >= 13) {
              final start = newTableau[p].length - 13;
              final firstCard = ScorpionCard(newTableau[p][start].card);
              if (firstCard.rank == 13) {
                bool isComplete = true;
                final suit = firstCard.suit;
                for (int i = 0; i < 13; i++) {
                  final card = ScorpionCard(newTableau[p][start + i].card);
                  if (card.suit != suit || card.rank != 13 - i) {
                    isComplete = false;
                    break;
                  }
                }
                if (isComplete) {
                  newTableau[p] = newTableau[p].sublist(0, start);
                  break;
                }
              }
            }
          }
        }

        return copyWith(
          tableau: newTableau,
          completedSuits: newCompleted,
        );

      case ScorpionMoveType.dealFromStock:
        final newTableau = List<List<ScorpionCardInfo>>.from(
            tableau.map((p) => List<ScorpionCardInfo>.from(p)));
        final newStock = List<String>.from(stock);

        // Deal 3 cards to first 3 columns
        for (int col = 0; col < 3 && newStock.isNotEmpty; col++) {
          final card = newStock.removeLast();
          newTableau[col].add(ScorpionCardInfo(card, true));
        }

        return copyWith(tableau: newTableau, stock: newStock);
    }
  }

  @override
  bool get isWon => completedSuits == 4;

  @override
  String get signature {
    // Create a unique signature for this state
    final tableauSig = tableau.map((pile) {
      return pile.map((c) => c.faceUp ? c.card : '?').join(',');
    }).join('|');
    return jsonEncode({
      'tableau': tableauSig,
      'stock': stock.length,
      'completed': completedSuits,
    });
  }

  @override
  int get heuristicScore {
    if (isWon) return 10000;

    int score = 0;

    // Completed suits are most important
    score += completedSuits * 500;

    // Bonus for face-up cards
    for (final pile in tableau) {
      for (final card in pile) {
        if (card.faceUp) score += 2;
      }
    }

    // Bonus for suit sequences (count consecutive same-suit descending cards)
    for (final pile in tableau) {
      if (pile.isEmpty) continue;
      int seqLength = 1;
      for (int i = pile.length - 2; i >= 0; i--) {
        if (!pile[i].faceUp) break;
        final card = ScorpionCard(pile[i].card);
        final nextCard = ScorpionCard(pile[i + 1].card);
        if (card.suit == nextCard.suit && card.rank == nextCard.rank + 1) {
          seqLength++;
        } else {
          break;
        }
      }
      if (seqLength > 1) {
        score += seqLength * 5;
      }
    }

    // Penalty for face-down cards
    for (final pile in tableau) {
      for (final card in pile) {
        if (!card.faceUp) score -= 5;
      }
    }

    // Bonus for empty piles
    score += tableau.where((p) => p.isEmpty).length * 10;

    return score;
  }
}
