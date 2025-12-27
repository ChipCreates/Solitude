import 'card.dart';

enum PileType { stock, waste, foundation, tableau }

class Pile {
  final PileType type;
  final int index;
  final List<PlayingCard> _cards = [];
  
  Pile({required this.type, this.index = 0});
  
  List<PlayingCard> get cards => List.unmodifiable(_cards);
  
  bool get isEmpty => _cards.isEmpty;
  int get length => _cards.length;
  
  PlayingCard? get topCard => _cards.isEmpty ? null : _cards.last;
  
  List<PlayingCard> get faceUpCards => 
    _cards.where((c) => c.faceUp).toList();
  
  int get faceUpCount => _cards.where((c) => c.faceUp).length;
  
  void addCard(PlayingCard card) {
    _cards.add(card);
  }
  
  void addCards(List<PlayingCard> cards) {
    _cards.addAll(cards);
  }
  
  PlayingCard? removeTop() {
    if (_cards.isEmpty) return null;
    return _cards.removeLast();
  }
  
  List<PlayingCard> removeFrom(int index) {
    if (index < 0 || index >= _cards.length) return [];
    final removed = _cards.sublist(index);
    _cards.removeRange(index, _cards.length);
    return removed;
  }
  
  List<PlayingCard> removeAll() {
    final all = List<PlayingCard>.from(_cards);
    _cards.clear();
    return all;
  }
  
  void clear() {
    _cards.clear();
  }
  
  int indexOfCard(PlayingCard card) {
    for (int i = 0; i < _cards.length; i++) {
      if (_cards[i] == card) return i;
    }
    return -1;
  }
  
  bool containsCard(PlayingCard card) => indexOfCard(card) != -1;
  
  PlayingCard? cardAt(int index) {
    if (index < 0 || index >= _cards.length) return null;
    return _cards[index];
  }
  
  void flipTopCard() {
    if (_cards.isNotEmpty && !_cards.last.faceUp) {
      _cards.last.faceUp = true;
    }
  }
  
  @override
  String toString() => '${type.name}[$index]: ${_cards.map((c) => c.toString()).join(", ")}';
}
