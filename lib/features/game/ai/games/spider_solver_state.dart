import 'dart:convert';

import '../abstract_solver.dart';

/// Represents a card in the Spider solver.
/// Format: 'rankSuit' where rank 1-13 (1=Ace, 13=King), suit H/D/C/S.
/// Also tracks if card is face-up.
class SpiderCard {
  final String value;
  final bool faceUp;

  SpiderCard(this.value, {this.faceUp = true});

  int get rank => int.parse(value.substring(0, value.length - 1));

  String get suit => value.substring(value.length - 1);

  @override
  String toString() => faceUp ? value : '?';

  /// Check if this card can stack on another in tableau.
  /// (Descending rank, any suit for stacking)
  bool canStackOn(SpiderCard other) {
    return rank == other.rank - 1;
  }

  /// Check if this card is same suit as another
  bool isSameSuit(SpiderCard other) => suit == other.suit;
}

/// Enum for different move types in Spider.
enum SpiderMoveType {
  tableauToTableau,
  dealFromStock,
}

/// Represents a move in Spider solitaire.
class SpiderMove extends SolverMove {
  final SpiderMoveType type;
  final int fromPile;
  final int toPile;
  final int cardCount;

  SpiderMove(this.type, this.fromPile, this.toPile, [this.cardCount = 1]);

  @override
  int get priority => _calculatePriority();

  int _calculatePriority() {
    switch (type) {
      case SpiderMoveType.tableauToTableau:
        return 5;
      case SpiderMoveType.dealFromStock:
        return 1; // Low priority - only deal when needed
    }
  }

  @override
  String toString() => '$type from:$fromPile to:$toPile cards:$cardCount';
}

/// Lightweight state representation for Spider solver.
class SpiderSolverState implements SolverState<SpiderMove> {
  final List<List<SpiderCard>> tableau; // 10 piles
  final int stockDeals; // Number of deals remaining (0-5)
  final int completedSequences; // Number of K->A sequences completed (0-8)

  SpiderSolverState({
    required this.tableau,
    required this.stockDeals,
    required this.completedSequences,
  });

  /// Creates a copy with modified fields.
  SpiderSolverState copyWith({
    List<List<SpiderCard>>? tableau,
    int? stockDeals,
    int? completedSequences,
  }) {
    return SpiderSolverState(
      tableau: tableau ?? List.from(this.tableau.map((p) => List.from(p))),
      stockDeals: stockDeals ?? this.stockDeals,
      completedSequences: completedSequences ?? this.completedSequences,
    );
  }

  /// Check if cards form a valid same-suit descending sequence.
  bool _isValidSameSuitSequence(List<SpiderCard> cards) {
    if (cards.length <= 1) return true;
    for (int i = 1; i < cards.length; i++) {
      final prev = cards[i - 1];
      final curr = cards[i];
      if (curr.suit != prev.suit || curr.rank != prev.rank - 1) {
        return false;
      }
    }
    return true;
  }

  /// Check if pile has a complete K->A sequence at the bottom.
  bool _hasCompleteSequence(List<SpiderCard> pile) {
    if (pile.length < 13) return false;

    final startIdx = pile.length - 13;
    final sequence = pile.sublist(startIdx);

    // Must start with King and all face up
    if (sequence.first.rank != 13) return false;
    if (!sequence.every((c) => c.faceUp)) return false;

    return _isValidSameSuitSequence(sequence);
  }

  @override
  List<SpiderMove> getAvailableMoves() {
    final moves = <SpiderMove>[];

    // Tableau to tableau moves
    for (int fromPile = 0; fromPile < 10; fromPile++) {
      if (tableau[fromPile].isEmpty) continue;

      // Find all valid same-suit sequences we can move
      for (int startIdx = tableau[fromPile].length - 1;
          startIdx >= 0;
          startIdx--) {
        final card = tableau[fromPile][startIdx];
        if (!card.faceUp) break; // Can't move face-down cards

        final cardsToMove = tableau[fromPile].sublist(startIdx);
        if (!_isValidSameSuitSequence(cardsToMove)) break;

        final topCard = cardsToMove.first;

        // Try moving to other piles
        for (int toPile = 0; toPile < 10; toPile++) {
          if (toPile == fromPile) continue;

          if (tableau[toPile].isEmpty) {
            // Any sequence can go on empty pile
            moves.add(SpiderMove(
              SpiderMoveType.tableauToTableau,
              fromPile,
              toPile,
              cardsToMove.length,
            ));
          } else {
            final destTop = tableau[toPile].last;
            if (topCard.canStackOn(destTop)) {
              moves.add(SpiderMove(
                SpiderMoveType.tableauToTableau,
                fromPile,
                toPile,
                cardsToMove.length,
              ));
            }
          }
        }
      }
    }

    // Deal from stock (only if no empty piles and stock has cards)
    if (stockDeals > 0) {
      final hasEmptyPile = tableau.any((p) => p.isEmpty);
      if (!hasEmptyPile) {
        moves.add(SpiderMove(SpiderMoveType.dealFromStock, -1, -1));
      }
    }

    return moves;
  }

  @override
  SolverState<SpiderMove> applyMove(SpiderMove move) {
    switch (move.type) {
      case SpiderMoveType.tableauToTableau:
        final fromPile = tableau[move.fromPile];
        final startIdx = fromPile.length - move.cardCount;
        final cardsToMove = fromPile.sublist(startIdx);

        final newTableau = List<List<SpiderCard>>.from(
            tableau.map((p) => List<SpiderCard>.from(p)));

        // Remove cards from source
        newTableau[move.fromPile] = fromPile.sublist(0, startIdx);

        // Flip top card if needed
        if (newTableau[move.fromPile].isNotEmpty &&
            !newTableau[move.fromPile].last.faceUp) {
          final topCard = newTableau[move.fromPile].last;
          newTableau[move.fromPile][newTableau[move.fromPile].length - 1] =
              SpiderCard(topCard.value, faceUp: true);
        }

        // Add to destination
        newTableau[move.toPile].addAll(cardsToMove);

        // Check for completed sequence
        var newCompletedSequences = completedSequences;
        if (_hasCompleteSequence(newTableau[move.toPile])) {
          // Remove the completed sequence
          newTableau[move.toPile] = newTableau[move.toPile]
              .sublist(0, newTableau[move.toPile].length - 13);
          newCompletedSequences++;

          // Flip new top card if needed
          if (newTableau[move.toPile].isNotEmpty &&
              !newTableau[move.toPile].last.faceUp) {
            final topCard = newTableau[move.toPile].last;
            newTableau[move.toPile][newTableau[move.toPile].length - 1] =
                SpiderCard(topCard.value, faceUp: true);
          }
        }

        return copyWith(
            tableau: newTableau, completedSequences: newCompletedSequences);

      case SpiderMoveType.dealFromStock:
        // Deal one card to each pile
        final newTableau = List<List<SpiderCard>>.from(
            tableau.map((p) => List<SpiderCard>.from(p)));

        // Add a placeholder face-up card to each pile
        // In the real game, this would be actual cards from stock
        // For solver, we track this as new cards
        for (int i = 0; i < 10; i++) {
          // Add a generic card (solver will explore from here)
          newTableau[i].add(SpiderCard('0X', faceUp: true));
        }

        return copyWith(
          tableau: newTableau,
          stockDeals: stockDeals - 1,
        );
    }
  }

  @override
  bool get isWon => completedSequences >= 8;

  @override
  String get signature {
    // Create a normalized signature
    final tableauSig = tableau
        .map((pile) => pile.map((c) => c.faceUp ? c.value : '?').join(','))
        .join('|');

    return jsonEncode({
      'tableau': tableauSig,
      'stock': stockDeals,
      'completed': completedSequences,
    });
  }

  @override
  int get heuristicScore {
    if (isWon) return 1000;

    int score = 0;

    // Completed sequences are very valuable
    score += completedSequences * 100;

    // Count face-up cards
    int faceUpCards = 0;
    for (final pile in tableau) {
      for (final card in pile) {
        if (card.faceUp) faceUpCards++;
      }
    }
    score += faceUpCards;

    // Bonus for same-suit sequences
    for (final pile in tableau) {
      if (pile.length > 1) {
        int sequenceLength = 1;
        for (int i = pile.length - 1; i > 0; i--) {
          final lower = pile[i];
          final upper = pile[i - 1];
          if (lower.faceUp &&
              upper.faceUp &&
              lower.isSameSuit(upper) &&
              lower.canStackOn(upper)) {
            sequenceLength++;
          } else {
            break;
          }
        }
        score += sequenceLength * 3;
      }
    }

    // Penalty for face-down cards
    for (final pile in tableau) {
      for (final card in pile) {
        if (!card.faceUp) score -= 2;
      }
    }

    // Empty piles are valuable
    score += tableau.where((p) => p.isEmpty).length * 10;

    return score;
  }
}
