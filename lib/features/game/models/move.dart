import 'card.dart';
import 'pile.dart';

class Move {
  final Pile fromPile;
  final Pile toPile;
  final List<PlayingCard> cards;
  final bool flippedCard; // Did this move reveal a face-down card?
  final bool drewFromStock; // Was this a stock draw?
  final int stockRecycleCount; // Track stock recycles for undo
  
  Move({
    required this.fromPile,
    required this.toPile,
    required this.cards,
    this.flippedCard = false,
    this.drewFromStock = false,
    this.stockRecycleCount = 0,
  });
  
  /// Get a human-readable description of this move
  String get description {
    // Handle stock draw/recycle
    if (drewFromStock) {
      if (toPile.type == PileType.stock) {
        return 'Recycled waste to stock';
      }
      final count = cards.length;
      return 'Drew ${count == 1 ? '1 card' : '$count cards'} from stock';
    }

    // Get card description
    String cardDesc;
    if (cards.length == 1) {
      cardDesc = cards.first.toString();
    } else {
      cardDesc = '${cards.first.toString()} + ${cards.length - 1} more';
    }

    // Get pile names
    final fromName = _getPileName(fromPile);
    final toName = _getPileName(toPile);

    return 'Moved $cardDesc from $fromName to $toName';
  }

  String _getPileName(Pile pile) {
    switch (pile.type) {
      case PileType.stock:
        return 'Stock';
      case PileType.waste:
        return 'Waste';
      case PileType.foundation:
        return 'Foundation ${pile.index + 1}';
      case PileType.tableau:
        return 'Tableau ${pile.index + 1}';
    }
  }

  @override
  String toString() =>
    'Move: ${cards.length} card(s) from ${fromPile.type.name}[${fromPile.index}] '
    'to ${toPile.type.name}[${toPile.index}]${flippedCard ? " (flipped)" : ""}';
}
