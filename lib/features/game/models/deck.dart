import 'dart:math';
import 'card.dart';

class Deck {
  final List<PlayingCard> _cards = [];
  
  Deck({int deckCount = 1}) {
    _createStandardDeck(deckCount);
  }
  
  void _createStandardDeck(int deckCount) {
    _cards.clear();
    for (int deck = 0; deck < deckCount; deck++) {
      for (final suit in Suit.values) {
        for (final rank in Rank.values) {
          _cards.add(PlayingCard(suit: suit, rank: rank));
        }
      }
    }
  }
  
  void shuffle([Random? random]) {
    random ??= Random();
    for (int i = _cards.length - 1; i > 0; i--) {
      final int j = random.nextInt(i + 1);
      final temp = _cards[i];
      _cards[i] = _cards[j];
      _cards[j] = temp;
    }
  }
  
  PlayingCard? draw() {
    if (_cards.isEmpty) return null;
    return _cards.removeLast();
  }
  
  List<PlayingCard> drawMultiple(int count) {
    final drawn = <PlayingCard>[];
    for (int i = 0; i < count && _cards.isNotEmpty; i++) {
      drawn.add(_cards.removeLast());
    }
    return drawn;
  }
  
  bool get isEmpty => _cards.isEmpty;
  int get length => _cards.length;
  
  List<PlayingCard> get cards => List.unmodifiable(_cards);
}
