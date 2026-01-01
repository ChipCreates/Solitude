import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/features/game/models/card.dart';

void main() {
  group('PlayingCard Creation', () {
    test('card creation with all 52 combinations (all suits × all ranks)', () {
      final cards = <PlayingCard>[];
      for (final suit in Suit.values) {
        for (final rank in Rank.values) {
          cards.add(PlayingCard(suit: suit, rank: rank));
        }
      }
      expect(cards.length, 52);

      // Verify no duplicates
      final uniqueCards = cards.toSet();
      expect(uniqueCards.length, 52);
    });
  });

  group('PlayingCard Color Properties', () {
    test('isRed returns true for hearts and diamonds', () {
      final heartCard = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      final diamondCard = PlayingCard(suit: Suit.diamonds, rank: Rank.king);

      expect(heartCard.isRed, isTrue);
      expect(diamondCard.isRed, isTrue);
    });

    test('isBlack returns true for clubs and spades', () {
      final clubCard = PlayingCard(suit: Suit.clubs, rank: Rank.ace);
      final spadeCard = PlayingCard(suit: Suit.spades, rank: Rank.king);

      expect(clubCard.isBlack, isTrue);
      expect(spadeCard.isBlack, isTrue);
    });

    test('isRed and isBlack are opposites', () {
      for (final suit in Suit.values) {
        final card = PlayingCard(suit: suit, rank: Rank.five);
        expect(card.isRed, !card.isBlack);
      }
    });
  });

  group('PlayingCard Value', () {
    test('value returns correct numeric value (Ace=1, King=13)', () {
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.ace).value, 1);
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.two).value, 2);
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.three).value, 3);
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.four).value, 4);
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.five).value, 5);
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.six).value, 6);
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.seven).value, 7);
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.eight).value, 8);
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.nine).value, 9);
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.ten).value, 10);
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.jack).value, 11);
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.queen).value, 12);
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.king).value, 13);
    });
  });

  group('PlayingCard suitName', () {
    test('suitName returns correct strings', () {
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.ace).suitName, 'heart');
      expect(
          PlayingCard(suit: Suit.diamonds, rank: Rank.ace).suitName, 'diamond');
      expect(PlayingCard(suit: Suit.clubs, rank: Rank.ace).suitName, 'club');
      expect(PlayingCard(suit: Suit.spades, rank: Rank.ace).suitName, 'spade');
    });
  });

  group('PlayingCard rankName', () {
    test('rankName returns correct strings', () {
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.ace).rankName, '1');
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.two).rankName, '2');
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.three).rankName, '3');
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.jack).rankName, 'jack');
      expect(
          PlayingCard(suit: Suit.hearts, rank: Rank.queen).rankName, 'queen');
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.king).rankName, 'king');
    });
  });

  group('PlayingCard svgId', () {
    test('svgId formats correctly', () {
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.ace).svgId, 'heart_1');
      expect(
          PlayingCard(suit: Suit.spades, rank: Rank.king).svgId, 'spade_king');
      expect(
          PlayingCard(suit: Suit.diamonds, rank: Rank.five).svgId, 'diamond_5');
      expect(
          PlayingCard(suit: Suit.clubs, rank: Rank.queen).svgId, 'club_queen');
    });
  });

  group('PlayingCard displayRank', () {
    test('displayRank returns correct display strings', () {
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.ace).displayRank, 'A');
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.two).displayRank, '2');
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.three).displayRank, '3');
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.ten).displayRank, '10');
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.jack).displayRank, 'J');
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.queen).displayRank, 'Q');
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.king).displayRank, 'K');
    });
  });

  group('PlayingCard displaySuit', () {
    test('displaySuit returns correct Unicode symbols', () {
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.ace).displaySuit, '♥');
      expect(PlayingCard(suit: Suit.diamonds, rank: Rank.ace).displaySuit, '♦');
      expect(PlayingCard(suit: Suit.clubs, rank: Rank.ace).displaySuit, '♣');
      expect(PlayingCard(suit: Suit.spades, rank: Rank.ace).displaySuit, '♠');
    });
  });

  group('PlayingCard canStackOn - alternating colors', () {
    test('canStackOn() with alternating colors - red on black', () {
      final blackSix = PlayingCard(suit: Suit.spades, rank: Rank.six);
      final redFive = PlayingCard(suit: Suit.hearts, rank: Rank.five);

      expect(
          redFive.canStackOn(blackSix,
              alternatingColors: true, descending: true),
          isTrue);
    });

    test('canStackOn() with alternating colors - black on red', () {
      final redSix = PlayingCard(suit: Suit.hearts, rank: Rank.six);
      final blackFive = PlayingCard(suit: Suit.clubs, rank: Rank.five);

      expect(
          blackFive.canStackOn(redSix,
              alternatingColors: true, descending: true),
          isTrue);
    });

    test(
        'canStackOn() with same color returns false when alternatingColors=true',
        () {
      final redSix = PlayingCard(suit: Suit.hearts, rank: Rank.six);
      final redFive = PlayingCard(suit: Suit.diamonds, rank: Rank.five);

      expect(
          redFive.canStackOn(redSix, alternatingColors: true, descending: true),
          isFalse);

      final blackSix = PlayingCard(suit: Suit.spades, rank: Rank.six);
      final blackFive = PlayingCard(suit: Suit.clubs, rank: Rank.five);

      expect(
          blackFive.canStackOn(blackSix,
              alternatingColors: true, descending: true),
          isFalse);
    });
  });

  group('PlayingCard canStackOn - descending', () {
    test('canStackOn() descending - cards with value difference of 1', () {
      final six = PlayingCard(suit: Suit.spades, rank: Rank.six);
      final five = PlayingCard(suit: Suit.hearts, rank: Rank.five);

      expect(five.canStackOn(six, alternatingColors: true, descending: true),
          isTrue);
    });

    test('canStackOn() descending - cards with wrong values return false', () {
      final six = PlayingCard(suit: Suit.spades, rank: Rank.six);
      final four = PlayingCard(suit: Suit.hearts, rank: Rank.four);
      final seven = PlayingCard(suit: Suit.hearts, rank: Rank.seven);

      expect(four.canStackOn(six, alternatingColors: true, descending: true),
          isFalse);
      expect(seven.canStackOn(six, alternatingColors: true, descending: true),
          isFalse);
    });
  });

  group('PlayingCard canStackOn - ascending', () {
    test('canStackOn() ascending (descending=false)', () {
      final five = PlayingCard(suit: Suit.hearts, rank: Rank.five);
      final six = PlayingCard(suit: Suit.spades, rank: Rank.six);

      expect(six.canStackOn(five, alternatingColors: true, descending: false),
          isTrue);
    });

    test('canStackOn() ascending - wrong values return false', () {
      final five = PlayingCard(suit: Suit.hearts, rank: Rank.five);
      final seven = PlayingCard(suit: Suit.spades, rank: Rank.seven);

      expect(seven.canStackOn(five, alternatingColors: true, descending: false),
          isFalse);
    });
  });

  group('PlayingCard canStackOnFoundation', () {
    test('canStackOnFoundation() - ace on empty foundation', () {
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace);

      expect(ace.canStackOnFoundation(null), isTrue);
    });

    test('canStackOnFoundation() - non-ace on empty foundation returns false',
        () {
      final two = PlayingCard(suit: Suit.hearts, rank: Rank.two);
      final king = PlayingCard(suit: Suit.hearts, rank: Rank.king);

      expect(two.canStackOnFoundation(null), isFalse);
      expect(king.canStackOnFoundation(null), isFalse);
    });

    test('canStackOnFoundation() - same suit, sequential rank', () {
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      final two = PlayingCard(suit: Suit.hearts, rank: Rank.two);
      final three = PlayingCard(suit: Suit.hearts, rank: Rank.three);

      expect(two.canStackOnFoundation(ace), isTrue);
      expect(three.canStackOnFoundation(two), isTrue);
    });

    test('canStackOnFoundation() - different suit returns false', () {
      final aceHearts = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      final twoSpades = PlayingCard(suit: Suit.spades, rank: Rank.two);

      expect(twoSpades.canStackOnFoundation(aceHearts), isFalse);
    });

    test('canStackOnFoundation() - non-sequential rank returns false', () {
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      final three = PlayingCard(suit: Suit.hearts, rank: Rank.three);

      expect(three.canStackOnFoundation(ace), isFalse);
    });
  });

  group('PlayingCard copyWith', () {
    test('copyWith() creates new instance with same suit/rank', () {
      final original =
          PlayingCard(suit: Suit.hearts, rank: Rank.king, faceUp: true);
      final copy = original.copyWith();

      expect(copy.suit, original.suit);
      expect(copy.rank, original.rank);
      expect(copy.isSameFace(original), isTrue); // Same face
      expect(copy, isNot(equals(original))); // Different uniqueId
      expect(identical(copy, original), isFalse); // Different instance
    });

    test('copyWith() can change faceUp state', () {
      final original =
          PlayingCard(suit: Suit.hearts, rank: Rank.king, faceUp: true);
      final copy = original.copyWith(faceUp: false);

      expect(original.faceUp, isTrue);
      expect(copy.faceUp, isFalse);
    });

    test('copyWith() preserves faceUp when not specified', () {
      final faceUpCard =
          PlayingCard(suit: Suit.hearts, rank: Rank.king, faceUp: true);
      final faceDownCard =
          PlayingCard(suit: Suit.hearts, rank: Rank.queen, faceUp: false);

      expect(faceUpCard.copyWith().faceUp, isTrue);
      expect(faceDownCard.copyWith().faceUp, isFalse);
    });
  });

  group('PlayingCard Equality', () {
    test('isSameFace - same suit and rank are same face', () {
      final card1 = PlayingCard(suit: Suit.hearts, rank: Rank.king);
      final card2 = PlayingCard(suit: Suit.hearts, rank: Rank.king);

      expect(card1.isSameFace(card2), isTrue);
    });

    test('equality operator - same instance is equal', () {
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.king);

      expect(card, equals(card));
    });

    test('equality operator - different cards are not equal', () {
      final kingHearts1 = PlayingCard(suit: Suit.hearts, rank: Rank.king);
      final kingHearts2 = PlayingCard(suit: Suit.hearts, rank: Rank.king);
      final queenHearts = PlayingCard(suit: Suit.hearts, rank: Rank.queen);
      final kingSpades = PlayingCard(suit: Suit.spades, rank: Rank.king);

      expect(kingHearts1, isNot(equals(kingHearts2)));
      expect(kingHearts1, isNot(equals(queenHearts)));
      expect(kingHearts1, isNot(equals(kingSpades)));
    });

    test(
        'equality operator - faceUp state affects equality since uniqueId differs',
        () {
      final faceUp =
          PlayingCard(suit: Suit.hearts, rank: Rank.king, faceUp: true);
      final faceDown =
          PlayingCard(suit: Suit.hearts, rank: Rank.king, faceUp: false);

      expect(faceUp, isNot(equals(faceDown)));
    });

    test('hashCode differs for different instances', () {
      final card1 = PlayingCard(suit: Suit.hearts, rank: Rank.king);
      final card2 = PlayingCard(suit: Suit.hearts, rank: Rank.king);
      final card3 = PlayingCard(suit: Suit.spades, rank: Rank.king);

      expect(card1.hashCode, isNot(equals(card2.hashCode)));
      expect(card1.hashCode, isNot(equals(card3.hashCode)));
    });
  });

  group('PlayingCard toString', () {
    test('toString() formats correctly', () {
      expect(PlayingCard(suit: Suit.hearts, rank: Rank.ace).toString(), 'A♥');
      expect(PlayingCard(suit: Suit.spades, rank: Rank.king).toString(), 'K♠');
      expect(
          PlayingCard(suit: Suit.diamonds, rank: Rank.ten).toString(), '10♦');
      expect(PlayingCard(suit: Suit.clubs, rank: Rank.jack).toString(), 'J♣');
    });
  });
}
