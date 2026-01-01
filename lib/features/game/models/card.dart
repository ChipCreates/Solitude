enum Suit { hearts, diamonds, clubs, spades }

enum Rank {
  ace,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king
}

class PlayingCard {
  static int _idCounter = 0;

  final Suit suit;
  final Rank rank;
  final String uniqueId;
  bool faceUp;

  PlayingCard({
    required this.suit,
    required this.rank,
    String? uniqueId,
    this.faceUp = false,
  }) : uniqueId = uniqueId ?? (_idCounter++).toString();

  bool get isRed => suit == Suit.hearts || suit == Suit.diamonds;
  bool get isBlack => !isRed;

  int get value => rank.index + 1; // ace=1, king=13

  String get suitName {
    switch (suit) {
      case Suit.hearts:
        return 'heart';
      case Suit.diamonds:
        return 'diamond';
      case Suit.clubs:
        return 'club';
      case Suit.spades:
        return 'spade';
    }
  }

  String get rankName {
    switch (rank) {
      case Rank.ace:
        return '1';
      case Rank.jack:
        return 'jack';
      case Rank.queen:
        return 'queen';
      case Rank.king:
        return 'king';
      default:
        return (rank.index + 1).toString();
    }
  }

  // SVG card ID format for htdebeer cards
  String get svgId => '${suitName}_$rankName';

  String get displayRank {
    switch (rank) {
      case Rank.ace:
        return 'A';
      case Rank.jack:
        return 'J';
      case Rank.queen:
        return 'Q';
      case Rank.king:
        return 'K';
      default:
        return (rank.index + 1).toString();
    }
  }

  String get displaySuit {
    switch (suit) {
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
      case Suit.spades:
        return '♠';
    }
  }

  bool canStackOn(PlayingCard other,
      {required bool alternatingColors, required bool descending}) {
    if (alternatingColors && isRed == other.isRed) return false;
    if (descending && value != other.value - 1) return false;
    if (!descending && value != other.value + 1) return false;
    return true;
  }

  bool canStackOnFoundation(PlayingCard? topCard) {
    if (topCard == null) return rank == Rank.ace;
    return suit == topCard.suit && value == topCard.value + 1;
  }

  bool isSameFace(PlayingCard other) {
    return suit == other.suit && rank == other.rank;
  }

  PlayingCard copyWith({bool? faceUp}) {
    return PlayingCard(
      suit: suit,
      rank: rank,
      uniqueId: uniqueId,
      faceUp: faceUp ?? this.faceUp,
    );
  }

  @override
  String toString() => '$displayRank$displaySuit';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayingCard &&
        other.suit == suit &&
        other.rank == rank &&
        other.uniqueId == uniqueId;
  }

  @override
  int get hashCode => Object.hash(suit, rank, uniqueId);
}
