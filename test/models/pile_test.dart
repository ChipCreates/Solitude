import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/features/game/models/card.dart';
import 'package:solitude/features/game/models/pile.dart';

void main() {
  group('Pile Creation', () {
    test('create pile with each PileType', () {
      final stock = Pile(type: PileType.stock);
      final waste = Pile(type: PileType.waste);
      final foundation = Pile(type: PileType.foundation);
      final tableau = Pile(type: PileType.tableau);

      expect(stock.type, PileType.stock);
      expect(waste.type, PileType.waste);
      expect(foundation.type, PileType.foundation);
      expect(tableau.type, PileType.tableau);
    });

    test('create pile with custom index', () {
      final pile = Pile(type: PileType.tableau, index: 5);
      expect(pile.index, 5);
    });

    test('default index is 0', () {
      final pile = Pile(type: PileType.foundation);
      expect(pile.index, 0);
    });
  });

  group('Pile isEmpty and length', () {
    test('isEmpty returns true for new pile', () {
      final pile = Pile(type: PileType.tableau);
      expect(pile.isEmpty, isTrue);
    });

    test('isEmpty returns false after adding card', () {
      final pile = Pile(type: PileType.tableau);
      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace));
      expect(pile.isEmpty, isFalse);
    });

    test('length tracks card count', () {
      final pile = Pile(type: PileType.tableau);
      expect(pile.length, 0);

      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace));
      expect(pile.length, 1);

      pile.addCard(PlayingCard(suit: Suit.spades, rank: Rank.king));
      expect(pile.length, 2);
    });
  });

  group('Pile topCard', () {
    test('topCard returns null for empty pile', () {
      final pile = Pile(type: PileType.tableau);
      expect(pile.topCard, isNull);
    });

    test('topCard returns last added card', () {
      final pile = Pile(type: PileType.tableau);
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      final king = PlayingCard(suit: Suit.spades, rank: Rank.king);

      pile.addCard(ace);
      expect(pile.topCard, equals(ace));

      pile.addCard(king);
      expect(pile.topCard, equals(king));
    });
  });

  group('Pile faceUpCards and faceUpCount', () {
    test('faceUpCards filters only face-up cards', () {
      final pile = Pile(type: PileType.tableau);
      final faceDown1 = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: false);
      final faceDown2 = PlayingCard(suit: Suit.spades, rank: Rank.two, faceUp: false);
      final faceUp1 = PlayingCard(suit: Suit.diamonds, rank: Rank.three, faceUp: true);
      final faceUp2 = PlayingCard(suit: Suit.clubs, rank: Rank.four, faceUp: true);

      pile.addCard(faceDown1);
      pile.addCard(faceDown2);
      pile.addCard(faceUp1);
      pile.addCard(faceUp2);

      final faceUpCards = pile.faceUpCards;
      expect(faceUpCards.length, 2);
      expect(faceUpCards.contains(faceUp1), isTrue);
      expect(faceUpCards.contains(faceUp2), isTrue);
    });

    test('faceUpCount counts face-up cards correctly', () {
      final pile = Pile(type: PileType.tableau);

      expect(pile.faceUpCount, 0);

      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: false));
      expect(pile.faceUpCount, 0);

      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.two, faceUp: true));
      expect(pile.faceUpCount, 1);

      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.three, faceUp: true));
      expect(pile.faceUpCount, 2);
    });
  });

  group('Pile addCard', () {
    test('addCard() adds single card', () {
      final pile = Pile(type: PileType.tableau);
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace);

      pile.addCard(card);

      expect(pile.length, 1);
      expect(pile.topCard, equals(card));
    });
  });

  group('Pile addCards', () {
    test('addCards() adds multiple cards', () {
      final pile = Pile(type: PileType.tableau);
      final cards = [
        PlayingCard(suit: Suit.hearts, rank: Rank.ace),
        PlayingCard(suit: Suit.hearts, rank: Rank.two),
        PlayingCard(suit: Suit.hearts, rank: Rank.three),
      ];

      pile.addCards(cards);

      expect(pile.length, 3);
      expect(pile.topCard, equals(cards.last));
    });
  });

  group('Pile removeTop', () {
    test('removeTop() returns null for empty pile', () {
      final pile = Pile(type: PileType.tableau);
      expect(pile.removeTop(), isNull);
    });

    test('removeTop() returns and removes top card', () {
      final pile = Pile(type: PileType.tableau);
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      final king = PlayingCard(suit: Suit.spades, rank: Rank.king);

      pile.addCard(ace);
      pile.addCard(king);

      final removed = pile.removeTop();

      expect(removed, equals(king));
      expect(pile.length, 1);
      expect(pile.topCard, equals(ace));
    });

    test('removeTop() reduces length', () {
      final pile = Pile(type: PileType.tableau);
      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace));
      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.two));

      expect(pile.length, 2);
      pile.removeTop();
      expect(pile.length, 1);
    });
  });

  group('Pile removeFrom', () {
    test('removeFrom() with valid index removes cards from that point', () {
      final pile = Pile(type: PileType.tableau);
      final cards = [
        PlayingCard(suit: Suit.hearts, rank: Rank.ace),
        PlayingCard(suit: Suit.hearts, rank: Rank.two),
        PlayingCard(suit: Suit.hearts, rank: Rank.three),
        PlayingCard(suit: Suit.hearts, rank: Rank.four),
      ];
      pile.addCards(cards);

      final removed = pile.removeFrom(2);

      expect(removed.length, 2);
      expect(removed[0], equals(cards[2]));
      expect(removed[1], equals(cards[3]));
      expect(pile.length, 2);
    });

    test('removeFrom() with negative index returns empty list', () {
      final pile = Pile(type: PileType.tableau);
      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace));

      final removed = pile.removeFrom(-1);

      expect(removed.isEmpty, isTrue);
      expect(pile.length, 1);
    });

    test('removeFrom() with index >= length returns empty list', () {
      final pile = Pile(type: PileType.tableau);
      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace));

      final removed = pile.removeFrom(5);

      expect(removed.isEmpty, isTrue);
      expect(pile.length, 1);
    });

    test('removeFrom() removes correct cards from pile', () {
      final pile = Pile(type: PileType.tableau);
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      final two = PlayingCard(suit: Suit.hearts, rank: Rank.two);
      final three = PlayingCard(suit: Suit.hearts, rank: Rank.three);

      pile.addCards([ace, two, three]);
      pile.removeFrom(1);

      expect(pile.length, 1);
      expect(pile.topCard, equals(ace));
    });
  });

  group('Pile removeAll', () {
    test('removeAll() returns all cards', () {
      final pile = Pile(type: PileType.tableau);
      final cards = [
        PlayingCard(suit: Suit.hearts, rank: Rank.ace),
        PlayingCard(suit: Suit.hearts, rank: Rank.two),
        PlayingCard(suit: Suit.hearts, rank: Rank.three),
      ];
      pile.addCards(cards);

      final removed = pile.removeAll();

      expect(removed.length, 3);
      expect(removed, equals(cards));
    });

    test('removeAll() clears pile', () {
      final pile = Pile(type: PileType.tableau);
      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace));
      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.two));

      pile.removeAll();

      expect(pile.isEmpty, isTrue);
      expect(pile.length, 0);
    });
  });

  group('Pile clear', () {
    test('clear() empties pile', () {
      final pile = Pile(type: PileType.tableau);
      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace));
      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.two));

      pile.clear();

      expect(pile.isEmpty, isTrue);
      expect(pile.length, 0);
      expect(pile.topCard, isNull);
    });
  });

  group('Pile indexOfCard', () {
    test('indexOfCard() finds card position', () {
      final pile = Pile(type: PileType.tableau);
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      final two = PlayingCard(suit: Suit.hearts, rank: Rank.two);
      final three = PlayingCard(suit: Suit.hearts, rank: Rank.three);

      pile.addCards([ace, two, three]);

      expect(pile.indexOfCard(ace), 0);
      expect(pile.indexOfCard(two), 1);
      expect(pile.indexOfCard(three), 2);
    });

    test('indexOfCard() returns -1 for missing card', () {
      final pile = Pile(type: PileType.tableau);
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      final king = PlayingCard(suit: Suit.spades, rank: Rank.king);

      pile.addCard(ace);

      expect(pile.indexOfCard(king), -1);
    });
  });

  group('Pile containsCard', () {
    test('containsCard() returns true for present card', () {
      final pile = Pile(type: PileType.tableau);
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace);

      pile.addCard(ace);

      expect(pile.containsCard(ace), isTrue);
    });

    test('containsCard() returns false for missing card', () {
      final pile = Pile(type: PileType.tableau);
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      final king = PlayingCard(suit: Suit.spades, rank: Rank.king);

      pile.addCard(ace);

      expect(pile.containsCard(king), isFalse);
    });
  });

  group('Pile cardAt', () {
    test('cardAt() returns card at valid index', () {
      final pile = Pile(type: PileType.tableau);
      final cards = [
        PlayingCard(suit: Suit.hearts, rank: Rank.ace),
        PlayingCard(suit: Suit.hearts, rank: Rank.two),
        PlayingCard(suit: Suit.hearts, rank: Rank.three),
      ];
      pile.addCards(cards);

      expect(pile.cardAt(0), equals(cards[0]));
      expect(pile.cardAt(1), equals(cards[1]));
      expect(pile.cardAt(2), equals(cards[2]));
    });

    test('cardAt() returns null for invalid index', () {
      final pile = Pile(type: PileType.tableau);
      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace));

      expect(pile.cardAt(-1), isNull);
      expect(pile.cardAt(5), isNull);
    });
  });

  group('Pile flipTopCard', () {
    test('flipTopCard() flips face-down top card', () {
      final pile = Pile(type: PileType.tableau);
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: false);
      pile.addCard(card);

      expect(card.faceUp, isFalse);

      pile.flipTopCard();

      expect(card.faceUp, isTrue);
    });

    test('flipTopCard() doesn\'t affect already face-up card', () {
      final pile = Pile(type: PileType.tableau);
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);
      pile.addCard(card);

      pile.flipTopCard();

      expect(card.faceUp, isTrue);
    });

    test('flipTopCard() on empty pile doesn\'t crash', () {
      final pile = Pile(type: PileType.tableau);

      expect(() => pile.flipTopCard(), returnsNormally);
    });
  });

  group('Pile cards getter', () {
    test('cards getter returns unmodifiable list', () {
      final pile = Pile(type: PileType.tableau);
      final cards = pile.cards;

      expect(() => cards.add(PlayingCard(suit: Suit.hearts, rank: Rank.ace)),
          throwsUnsupportedError);
    });
  });

  group('Pile toString', () {
    test('toString() formats pile information', () {
      final pile = Pile(type: PileType.tableau, index: 3);
      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true));
      pile.addCard(PlayingCard(suit: Suit.spades, rank: Rank.king, faceUp: true));

      final str = pile.toString();

      expect(str.contains('tableau'), isTrue);
      expect(str.contains('[3]'), isTrue);
    });
  });

  group('Pile Integration', () {
    test('complex pile operations maintain integrity', () {
      final pile = Pile(type: PileType.tableau, index: 2);
      final cards = [
        PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: false),
        PlayingCard(suit: Suit.hearts, rank: Rank.two, faceUp: false),
        PlayingCard(suit: Suit.hearts, rank: Rank.three, faceUp: true),
        PlayingCard(suit: Suit.hearts, rank: Rank.four, faceUp: true),
      ];

      pile.addCards(cards);
      expect(pile.length, 4);
      expect(pile.faceUpCount, 2);

      final removed = pile.removeFrom(2);
      expect(removed.length, 2);
      expect(pile.length, 2);
      expect(pile.faceUpCount, 0);

      pile.flipTopCard();
      expect(pile.faceUpCount, 1);

      pile.clear();
      expect(pile.isEmpty, isTrue);
    });
  });

  group('Pile version tracking', () {
    test('version starts at 0', () {
      final pile = Pile(type: PileType.tableau);
      expect(pile.version, 0);
    });

    test('addCard increments version', () {
      final pile = Pile(type: PileType.tableau);
      final initialVersion = pile.version;

      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace));

      expect(pile.version, initialVersion + 1);
    });

    test('addCards increments version', () {
      final pile = Pile(type: PileType.tableau);
      final initialVersion = pile.version;

      pile.addCards([
        PlayingCard(suit: Suit.hearts, rank: Rank.ace),
        PlayingCard(suit: Suit.hearts, rank: Rank.two),
      ]);

      expect(pile.version, initialVersion + 1);
    });

    test('removeTop increments version', () {
      final pile = Pile(type: PileType.tableau);
      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace));
      final versionAfterAdd = pile.version;

      pile.removeTop();

      expect(pile.version, versionAfterAdd + 1);
    });

    test('removeTop on empty pile does not increment version', () {
      final pile = Pile(type: PileType.tableau);
      final initialVersion = pile.version;

      pile.removeTop();

      expect(pile.version, initialVersion);
    });

    test('removeFrom increments version when cards removed', () {
      final pile = Pile(type: PileType.tableau);
      pile.addCards([
        PlayingCard(suit: Suit.hearts, rank: Rank.ace),
        PlayingCard(suit: Suit.hearts, rank: Rank.two),
        PlayingCard(suit: Suit.hearts, rank: Rank.three),
      ]);
      final versionAfterAdd = pile.version;

      pile.removeFrom(1);

      expect(pile.version, versionAfterAdd + 1);
    });

    test('removeFrom does not increment version for invalid index', () {
      final pile = Pile(type: PileType.tableau);
      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace));
      final versionAfterAdd = pile.version;

      pile.removeFrom(10);  // Invalid index

      expect(pile.version, versionAfterAdd);
    });

    test('removeAll increments version', () {
      final pile = Pile(type: PileType.tableau);
      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace));
      final versionAfterAdd = pile.version;

      pile.removeAll();

      expect(pile.version, versionAfterAdd + 1);
    });

    test('clear increments version', () {
      final pile = Pile(type: PileType.tableau);
      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace));
      final versionAfterAdd = pile.version;

      pile.clear();

      expect(pile.version, versionAfterAdd + 1);
    });

    test('flipTopCard increments version when card flipped', () {
      final pile = Pile(type: PileType.tableau);
      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: false));
      final versionAfterAdd = pile.version;

      pile.flipTopCard();

      expect(pile.version, versionAfterAdd + 1);
    });

    test('flipTopCard does not increment version when card already face up', () {
      final pile = Pile(type: PileType.tableau);
      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true));
      final versionAfterAdd = pile.version;

      pile.flipTopCard();

      expect(pile.version, versionAfterAdd);
    });

    test('multiple operations increment version correctly', () {
      final pile = Pile(type: PileType.tableau);
      expect(pile.version, 0);

      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: false));
      expect(pile.version, 1);

      pile.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.two, faceUp: false));
      expect(pile.version, 2);

      pile.flipTopCard();
      expect(pile.version, 3);

      pile.removeTop();
      expect(pile.version, 4);

      pile.clear();
      expect(pile.version, 5);
    });
  });
}
