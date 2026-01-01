import 'dart:convert';

import '../abstract_solver.dart';

/// Represents a card in the Yukon solver.
/// Format: 'rankSuit' where rank 1-13 (1=Ace, 13=King), suit H/D/C/S.
class YukonCard {
  final String value;
  final bool faceUp;

  YukonCard(this.value, {this.faceUp = true});

  int get rank => int.parse(value.substring(0, value.length - 1));

  String get suit => value.substring(value.length - 1);

  bool get isRed => suit == 'H' || suit == 'D';
  bool get isBlack => suit == 'C' || suit == 'S';

  @override
  String toString() => faceUp ? value : '?';

  /// Check if this card can be placed on another in tableau (alternating colors, descending)
  bool canStackOn(YukonCard other) {
    if (isRed == other.isRed) return false; // Must alternate colors
    return rank == other.rank - 1; // Must be descending
  }
}

/// Enum for different move types in Yukon.
enum YukonMoveType {
  tableauToTableau,
  tableauToFoundation,
}

/// Represents a move in Yukon solitaire.
class YukonMove extends SolverMove {
  final YukonMoveType type;
  final int fromTableau;
  final int toDestination; // Tableau or foundation index
  final int cardIndex; // Index of the first card to move

  YukonMove(this.type, this.fromTableau, this.toDestination, this.cardIndex);

  @override
  int get priority => _calculatePriority();

  int _calculatePriority() {
    switch (type) {
      case YukonMoveType.tableauToFoundation:
        return 10; // Prioritize foundation moves
      case YukonMoveType.tableauToTableau:
        return 5;
    }
  }

  @override
  String toString() => '$type from:$fromTableau[$cardIndex] to:$toDestination';
}

/// Card representation in a pile (with face-up status)
class YukonCardInfo {
  final String card;
  final bool faceUp;

  YukonCardInfo(this.card, this.faceUp);

  @override
  String toString() => faceUp ? card : '?';
}

/// Lightweight state representation for Yukon solver.
class YukonSolverState implements SolverState<YukonMove> {
  final List<List<YukonCardInfo>> tableau; // 7 piles with face-up status
  final List<int> foundations; // Top rank of each foundation (0 = empty)

  YukonSolverState({
    required this.tableau,
    required this.foundations,
  });

  /// Creates a copy with modified fields.
  YukonSolverState copyWith({
    List<List<YukonCardInfo>>? tableau,
    List<int>? foundations,
  }) {
    return YukonSolverState(
      tableau: tableau ??
          List.from(this.tableau.map((p) => List<YukonCardInfo>.from(p))),
      foundations: foundations ?? List.from(this.foundations),
    );
  }

  /// Gets the suit index (0-3) for a card
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

  @override
  List<YukonMove> getAvailableMoves() {
    final moves = <YukonMove>[];

    for (int t = 0; t < 7; t++) {
      if (tableau[t].isEmpty) continue;

      // Find all face-up cards - each can be moved with all cards above it
      for (int cardIdx = 0; cardIdx < tableau[t].length; cardIdx++) {
        final cardInfo = tableau[t][cardIdx];
        if (!cardInfo.faceUp) continue;

        final card = YukonCard(cardInfo.card);

        // Foundation moves (only top card)
        if (cardIdx == tableau[t].length - 1) {
          final suitIdx = _getSuitIndex(cardInfo.card);
          if (card.rank == foundations[suitIdx] + 1) {
            moves.add(YukonMove(
              YukonMoveType.tableauToFoundation,
              t,
              suitIdx,
              cardIdx,
            ));
          }
        }

        // Tableau to tableau moves
        for (int dest = 0; dest < 7; dest++) {
          if (dest == t) continue;

          if (tableau[dest].isEmpty) {
            // Only Kings to empty
            if (card.rank == 13) {
              moves.add(YukonMove(
                YukonMoveType.tableauToTableau,
                t,
                dest,
                cardIdx,
              ));
            }
          } else {
            final destTop = YukonCard(tableau[dest].last.card);
            if (card.canStackOn(destTop)) {
              moves.add(YukonMove(
                YukonMoveType.tableauToTableau,
                t,
                dest,
                cardIdx,
              ));
            }
          }
        }
      }
    }

    return moves;
  }

  @override
  SolverState<YukonMove> applyMove(YukonMove move) {
    switch (move.type) {
      case YukonMoveType.tableauToFoundation:
        final newTableau = List<List<YukonCardInfo>>.from(
            tableau.map((p) => List<YukonCardInfo>.from(p)));
        final newFoundations = List<int>.from(foundations);

        final card = newTableau[move.fromTableau].removeLast();
        final cardObj = YukonCard(card.card);
        newFoundations[move.toDestination] = cardObj.rank;

        // Flip newly exposed card
        if (newTableau[move.fromTableau].isNotEmpty &&
            !newTableau[move.fromTableau].last.faceUp) {
          final lastCard = newTableau[move.fromTableau].last;
          newTableau[move.fromTableau]
                  [newTableau[move.fromTableau].length - 1] =
              YukonCardInfo(lastCard.card, true);
        }

        return copyWith(tableau: newTableau, foundations: newFoundations);

      case YukonMoveType.tableauToTableau:
        final newTableau = List<List<YukonCardInfo>>.from(
            tableau.map((p) => List<YukonCardInfo>.from(p)));

        // Move cards from index to end
        final cardsToMove =
            newTableau[move.fromTableau].sublist(move.cardIndex);
        newTableau[move.fromTableau] =
            newTableau[move.fromTableau].sublist(0, move.cardIndex);
        newTableau[move.toDestination].addAll(cardsToMove);

        // Flip newly exposed card
        if (newTableau[move.fromTableau].isNotEmpty &&
            !newTableau[move.fromTableau].last.faceUp) {
          final lastCard = newTableau[move.fromTableau].last;
          newTableau[move.fromTableau]
                  [newTableau[move.fromTableau].length - 1] =
              YukonCardInfo(lastCard.card, true);
        }

        return copyWith(tableau: newTableau);
    }
  }

  @override
  bool get isWon => foundations.every((f) => f == 13);

  @override
  String get signature {
    // Create a unique signature for this state
    final tableauSig = tableau.map((pile) {
      return pile.map((c) => c.faceUp ? c.card : '?').join(',');
    }).join('|');
    return jsonEncode({
      'tableau': tableauSig,
      'foundations': foundations,
    });
  }

  @override
  int get heuristicScore {
    if (isWon) return 10000;

    int score = 0;

    // Foundation progress is most important
    for (final f in foundations) {
      score += f * 20;
    }

    // Bonus for face-up cards
    for (final pile in tableau) {
      for (final card in pile) {
        if (card.faceUp) score += 2;
      }
    }

    // Bonus for empty tableau piles
    score += tableau.where((p) => p.isEmpty).length * 5;

    // Penalty for face-down cards
    for (final pile in tableau) {
      for (final card in pile) {
        if (!card.faceUp) score -= 3;
      }
    }

    return score;
  }
}
