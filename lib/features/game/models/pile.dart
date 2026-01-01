import 'card.dart';

/// Types of piles that can exist in card games.
///
/// Core types used by most solitaire variants:
/// - [stock] - Draw pile (face-down cards to draw from)
/// - [waste] - Discard/talon pile (drawn cards, face-up)
/// - [foundation] - Build piles (goal piles, usually by suit)
/// - [tableau] - Playing area columns
///
/// Extended types for specialized games:
/// - [cell] - Free cells (temporary single-card storage, e.g., FreeCell)
/// - [reserve] - Reserve piles (restricted access piles)
/// - [pyramid] - Pyramid structure cards (e.g., Pyramid solitaire)
/// - [discard] - General discard pile (different from waste semantics)
enum PileType {
  stock,
  waste,
  foundation,
  tableau,
  // Extended types for future games
  cell,      // FreeCell's free cells
  reserve,   // Reserve piles (Canfield, etc.)
  pyramid,   // Pyramid layout cards
  discard,   // General discard (Golf, etc.)
}

class Pile {
  final PileType type;
  final int index;
  final List<PlayingCard> _cards = [];

  /// Version counter that increments on any mutation.
  /// Used by Selector to detect when pile contents change.
  int _version = 0;

  Pile({required this.type, this.index = 0});

  /// Unique ID for this pile, used for UI mapping
  String get id => '${type.name}_$index';

  /// Current version of this pile - changes on any mutation.
  int get version => _version;

  List<PlayingCard> get cards => List.unmodifiable(_cards);

  bool get isEmpty => _cards.isEmpty;
  int get length => _cards.length;

  PlayingCard? get topCard => _cards.isEmpty ? null : _cards.last;

  List<PlayingCard> get faceUpCards =>
    _cards.where((c) => c.faceUp).toList();

  int get faceUpCount => _cards.where((c) => c.faceUp).length;

  void addCard(PlayingCard card) {
    _cards.add(card);
    _version++;
  }

  void addCards(List<PlayingCard> cards) {
    _cards.addAll(cards);
    _version++;
  }

  PlayingCard? removeTop() {
    if (_cards.isEmpty) return null;
    _version++;
    return _cards.removeLast();
  }

  List<PlayingCard> removeFrom(int index) {
    if (index < 0 || index >= _cards.length) return [];
    final removed = _cards.sublist(index);
    _cards.removeRange(index, _cards.length);
    _version++;
    return removed;
  }

  List<PlayingCard> removeAll() {
    final all = List<PlayingCard>.from(_cards);
    _cards.clear();
    _version++;
    return all;
  }

  void clear() {
    _cards.clear();
    _version++;
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
      _version++;
    }
  }
  
  @override
  String toString() => '${type.name}[$index]: ${_cards.map((c) => c.toString()).join(", ")}';
}
