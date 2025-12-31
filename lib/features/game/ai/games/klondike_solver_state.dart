import 'dart:convert';

import '../abstract_solver.dart';

/// Represents a card in the Klondike solver.
/// Format: 'rankSuit' where rank 1-13 (1=Ace, 13=King), suit H/D/C/S.
class Card {
  final String value;

  Card(this.value);

  int get rank => int.parse(value.substring(0, value.length - 1));

  String get suit => value.substring(value.length - 1);

  bool get isRed => suit == 'H' || suit == 'D';

  bool get isBlack => !isRed;

  @override
  String toString() => value;

  /// Check if this card can be placed on top of another in tableau.
  bool canPlaceOn(Card other) {
    return (isRed && other.isBlack || isBlack && other.isRed) &&
        rank == other.rank - 1;
  }

  /// Check if this card can be placed in foundation on top of another.
  bool canPlaceOnFoundation(Card? other) {
    if (other == null) return rank == 1;
    return suit == other.suit && rank == other.rank + 1;
  }
}

/// Enum for different move types in Klondike.
enum KlondikeMoveType {
  tableauToTableau,
  tableauToFoundation,
  wasteToTableau,
  wasteToFoundation,
  drawCard,
  flipTableauCard,
}

/// Represents a move in Klondike solitaire.
class KlondikeMove extends SolverMove {
  final KlondikeMoveType type;
  final int fromPile; // For tableau moves
  final int toPile; // For tableau moves
  final int fromIndex; // For tableau moves, the starting index in pile

  KlondikeMove(this.type, this.fromPile, this.toPile, this.fromIndex);

  @override
  int get priority => _calculatePriority();

  int _calculatePriority() {
    switch (type) {
      case KlondikeMoveType.tableauToFoundation:
      case KlondikeMoveType.wasteToFoundation:
        return 10; // High priority for foundation moves
      case KlondikeMoveType.tableauToTableau:
        return 5; // Medium for tableau moves
      case KlondikeMoveType.wasteToTableau:
        return 3;
      case KlondikeMoveType.drawCard:
        return 1; // Low priority
      case KlondikeMoveType.flipTableauCard:
        return 2;
    }
  }

  @override
  String toString() =>
      '$type fromPile:$fromPile toPile:$toPile fromIndex:$fromIndex';
}

/// Lightweight state representation for Klondike solver.
/// All cards are assumed face-up for simplicity.
class KlondikeSolverState implements SolverState<KlondikeMove> {
  final List<List<String>> tableau; // 7 piles, each list of card strings
  final List<String> waste; // List of cards in waste, top is last
  final List<String> stock; // Remaining stock cards
  final List<String?>
      foundation; // Top card for each suit H,D,C,S, null if empty

  KlondikeSolverState({
    required this.tableau,
    required this.waste,
    required this.stock,
    required this.foundation,
  });

  /// Creates a copy with modified fields.
  KlondikeSolverState copyWith({
    List<List<String>>? tableau,
    List<String>? waste,
    List<String>? stock,
    List<String?>? foundation,
  }) {
    return KlondikeSolverState(
      tableau: tableau ?? List.from(this.tableau.map((p) => List.from(p))),
      waste: waste ?? List.from(this.waste),
      stock: stock ?? List.from(this.stock),
      foundation: foundation ?? List.from(this.foundation),
    );
  }

  @override
  List<KlondikeMove> getAvailableMoves() {
    List<KlondikeMove> moves = [];

    // Draw from stock if available
    if (stock.isNotEmpty) {
      moves.add(KlondikeMove(KlondikeMoveType.drawCard, -1, -1, -1));
    }

    // Waste to foundation or tableau
    if (waste.isNotEmpty) {
      Card topWaste = Card(waste.last);
      // To foundation
      int suitIndex = _suitIndex(topWaste.suit);
      if (foundation[suitIndex] == null ||
          Card(foundation[suitIndex]!).canPlaceOnFoundation(topWaste)) {
        moves.add(KlondikeMove(
            KlondikeMoveType.wasteToFoundation, -1, suitIndex, -1));
      }
      // To tableau
      for (int i = 0; i < 7; i++) {
        if (tableau[i].isNotEmpty) {
          Card topTableau = Card(tableau[i].last);
          if (topWaste.canPlaceOn(topTableau)) {
            moves.add(KlondikeMove(KlondikeMoveType.wasteToTableau, -1, i, -1));
          }
        } else if (topWaste.rank == 13) {
          // King on empty
          moves.add(KlondikeMove(KlondikeMoveType.wasteToTableau, -1, i, -1));
        }
      }
    }

    // Tableau moves
    for (int from = 0; from < 7; from++) {
      if (tableau[from].isEmpty) continue;
      Card topCard = Card(tableau[from].last);

      // To foundation
      int suitIndex = _suitIndex(topCard.suit);
      if (foundation[suitIndex] == null ||
          Card(foundation[suitIndex]!).canPlaceOnFoundation(topCard)) {
        moves.add(KlondikeMove(
            KlondikeMoveType.tableauToFoundation, from, suitIndex, -1));
      }

      // To other tableau
      for (int to = 0; to < 7; to++) {
        if (to == from) continue;
        if (tableau[to].isNotEmpty) {
          Card destTop = Card(tableau[to].last);
          if (topCard.canPlaceOn(destTop)) {
            moves.add(
                KlondikeMove(KlondikeMoveType.tableauToTableau, from, to, -1));
          }
        } else if (topCard.rank == 13) {
          moves.add(
              KlondikeMove(KlondikeMoveType.tableauToTableau, from, to, -1));
        }
      }
    }

    // Flip tableau card (simplified, assume no face-down tracking)
    // For now, skip as we don't track face-down

    return moves;
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
        throw ArgumentError('Invalid suit');
    }
  }

  @override
  SolverState<KlondikeMove> applyMove(KlondikeMove move) {
    switch (move.type) {
      case KlondikeMoveType.drawCard:
        if (stock.isEmpty) throw StateError('No cards in stock');
        var newWaste = List<String>.from(waste)..add(stock.removeLast());
        return copyWith(waste: newWaste, stock: stock);

      case KlondikeMoveType.wasteToFoundation:
        if (waste.isEmpty) throw StateError('No cards in waste');
        var card = waste.last;
        var newWaste = List<String>.from(waste)..removeLast();
        var newFoundation = List<String?>.from(foundation);
        newFoundation[move.toPile] = card;
        return copyWith(waste: newWaste, foundation: newFoundation);

      case KlondikeMoveType.wasteToTableau:
        if (waste.isEmpty) throw StateError('No cards in waste');
        var card = waste.last;
        var newWaste = List<String>.from(waste)..removeLast();
        var newTableau =
            List<List<String>>.from(tableau.map((p) => List.from(p)));
        newTableau[move.toPile].add(card);
        return copyWith(waste: newWaste, tableau: newTableau);

      case KlondikeMoveType.tableauToFoundation:
        var pile = tableau[move.fromPile];
        if (pile.isEmpty) throw StateError('Pile is empty');
        var card = pile.last;
        var newTableau =
            List<List<String>>.from(tableau.map((p) => List.from(p)));
        newTableau[move.fromPile].removeLast();
        var newFoundation = List<String?>.from(foundation);
        newFoundation[move.toPile] = card;
        return copyWith(tableau: newTableau, foundation: newFoundation);

      case KlondikeMoveType.tableauToTableau:
        var fromPile = tableau[move.fromPile];
        if (fromPile.isEmpty) throw StateError('Pile is empty');
        var card = fromPile.last;
        var newTableau =
            List<List<String>>.from(tableau.map((p) => List.from(p)));
        newTableau[move.fromPile].removeLast();
        newTableau[move.toPile].add(card);
        return copyWith(tableau: newTableau);

      case KlondikeMoveType.flipTableauCard:
        // Not implemented
        return this;
    }
  }

  @override
  bool get isWon => foundation.every((f) => f != null && Card(f!).rank == 13);

  @override
  String get signature => jsonEncode({
        'tableau': tableau,
        'waste': waste,
        'stock': stock,
        'foundation': foundation,
      });

  @override
  int get heuristicScore {
    if (isWon) return 1000;
    int score = 0;
    foundation.forEach((f) {
      if (f != null) score += 10 * Card(f).rank;
    });
    // No face-down tracking, so no +5 for flipping
    return score;
  }
}
