import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/models/card.dart';
import 'package:solitude/models/pile.dart';
import 'package:solitude/models/move.dart';

void main() {
  group('Move Creation', () {
    test('move creation with all required fields', () {
      final fromPile = Pile(type: PileType.waste);
      final toPile = Pile(type: PileType.foundation, index: 1);
      final cards = [PlayingCard(suit: Suit.hearts, rank: Rank.ace)];

      final move = Move(
        fromPile: fromPile,
        toPile: toPile,
        cards: cards,
      );

      expect(move.fromPile, equals(fromPile));
      expect(move.toPile, equals(toPile));
      expect(move.cards, equals(cards));
      expect(move.flippedCard, isFalse);
      expect(move.drewFromStock, isFalse);
      expect(move.stockRecycleCount, 0);
    });

    test('move tracks source and destination piles', () {
      final fromPile = Pile(type: PileType.tableau, index: 3);
      final toPile = Pile(type: PileType.tableau, index: 5);
      final cards = [
        PlayingCard(suit: Suit.hearts, rank: Rank.king),
        PlayingCard(suit: Suit.spades, rank: Rank.queen),
      ];

      final move = Move(
        fromPile: fromPile,
        toPile: toPile,
        cards: cards,
      );

      expect(move.fromPile.type, PileType.tableau);
      expect(move.fromPile.index, 3);
      expect(move.toPile.type, PileType.tableau);
      expect(move.toPile.index, 5);
    });

    test('move records cards moved', () {
      final fromPile = Pile(type: PileType.tableau, index: 0);
      final toPile = Pile(type: PileType.tableau, index: 1);
      final cards = [
        PlayingCard(suit: Suit.hearts, rank: Rank.five),
        PlayingCard(suit: Suit.spades, rank: Rank.four),
        PlayingCard(suit: Suit.hearts, rank: Rank.three),
      ];

      final move = Move(
        fromPile: fromPile,
        toPile: toPile,
        cards: cards,
      );

      expect(move.cards.length, 3);
      expect(move.cards[0].rank, Rank.five);
      expect(move.cards[1].rank, Rank.four);
      expect(move.cards[2].rank, Rank.three);
    });

    test('move stores flippedCard flag', () {
      final fromPile = Pile(type: PileType.tableau, index: 0);
      final toPile = Pile(type: PileType.tableau, index: 1);
      final cards = [PlayingCard(suit: Suit.hearts, rank: Rank.king)];

      final moveWithFlip = Move(
        fromPile: fromPile,
        toPile: toPile,
        cards: cards,
        flippedCard: true,
      );

      final moveWithoutFlip = Move(
        fromPile: fromPile,
        toPile: toPile,
        cards: cards,
        flippedCard: false,
      );

      expect(moveWithFlip.flippedCard, isTrue);
      expect(moveWithoutFlip.flippedCard, isFalse);
    });

    test('move stores drewFromStock flag', () {
      final fromPile = Pile(type: PileType.stock);
      final toPile = Pile(type: PileType.waste);
      final cards = [PlayingCard(suit: Suit.hearts, rank: Rank.king)];

      final stockDrawMove = Move(
        fromPile: fromPile,
        toPile: toPile,
        cards: cards,
        drewFromStock: true,
      );

      expect(stockDrawMove.drewFromStock, isTrue);
    });

    test('move stores stockRecycleCount', () {
      final fromPile = Pile(type: PileType.waste);
      final toPile = Pile(type: PileType.stock);
      final cards = [PlayingCard(suit: Suit.hearts, rank: Rank.king)];

      final recycleMove = Move(
        fromPile: fromPile,
        toPile: toPile,
        cards: cards,
        drewFromStock: true,
        stockRecycleCount: 2,
      );

      expect(recycleMove.stockRecycleCount, 2);
    });
  });

  group('Move toString', () {
    test('toString() formats move information correctly', () {
      final fromPile = Pile(type: PileType.tableau, index: 3);
      final toPile = Pile(type: PileType.foundation, index: 1);
      final cards = [PlayingCard(suit: Suit.hearts, rank: Rank.ace)];

      final move = Move(
        fromPile: fromPile,
        toPile: toPile,
        cards: cards,
      );

      final str = move.toString();

      expect(str.contains('1 card'), isTrue);
      expect(str.contains('tableau[3]'), isTrue);
      expect(str.contains('foundation[1]'), isTrue);
    });

    test('toString() includes plural for multiple cards', () {
      final fromPile = Pile(type: PileType.tableau, index: 0);
      final toPile = Pile(type: PileType.tableau, index: 1);
      final cards = [
        PlayingCard(suit: Suit.hearts, rank: Rank.king),
        PlayingCard(suit: Suit.spades, rank: Rank.queen),
      ];

      final move = Move(
        fromPile: fromPile,
        toPile: toPile,
        cards: cards,
      );

      final str = move.toString();

      expect(str.contains('2 card(s)'), isTrue);
    });

    test('toString() includes flipped indicator when card was flipped', () {
      final fromPile = Pile(type: PileType.tableau, index: 0);
      final toPile = Pile(type: PileType.tableau, index: 1);
      final cards = [PlayingCard(suit: Suit.hearts, rank: Rank.king)];

      final move = Move(
        fromPile: fromPile,
        toPile: toPile,
        cards: cards,
        flippedCard: true,
      );

      final str = move.toString();

      expect(str.contains('(flipped)'), isTrue);
    });
  });

  group('Move description', () {
    test('describes stock draw (1 card)', () {
      final stock = Pile(type: PileType.stock);
      final waste = Pile(type: PileType.waste);
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace);

      final move = Move(
        fromPile: stock,
        toPile: waste,
        cards: [ace],
        drewFromStock: true,
      );

      expect(move.description, 'Drew 1 card from stock');
    });

    test('describes stock draw (3 cards)', () {
      final stock = Pile(type: PileType.stock);
      final waste = Pile(type: PileType.waste);
      final cards = [
        PlayingCard(suit: Suit.hearts, rank: Rank.ace),
        PlayingCard(suit: Suit.hearts, rank: Rank.two),
        PlayingCard(suit: Suit.spades, rank: Rank.king),
      ];

      final move = Move(
        fromPile: stock,
        toPile: waste,
        cards: cards,
        drewFromStock: true,
      );

      expect(move.description, 'Drew 3 cards from stock');
    });

    test('describes stock recycle', () {
      final waste = Pile(type: PileType.waste);
      final stock = Pile(type: PileType.stock);
      final cards = [
        PlayingCard(suit: Suit.hearts, rank: Rank.ace),
        PlayingCard(suit: Suit.hearts, rank: Rank.two),
      ];

      final move = Move(
        fromPile: waste,
        toPile: stock,
        cards: cards,
        drewFromStock: true,
      );

      expect(move.description, 'Recycled waste to stock');
    });

    test('describes single card move from waste to foundation', () {
      final waste = Pile(type: PileType.waste);
      final foundation = Pile(type: PileType.foundation, index: 0);
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace);

      final move = Move(
        fromPile: waste,
        toPile: foundation,
        cards: [ace],
      );

      expect(move.description, 'Moved A♥ from Waste to Foundation 1');
    });

    test('describes single card move from tableau to tableau', () {
      final tableau1 = Pile(type: PileType.tableau, index: 0);
      final tableau5 = Pile(type: PileType.tableau, index: 4);
      final king = PlayingCard(suit: Suit.spades, rank: Rank.king);

      final move = Move(
        fromPile: tableau1,
        toPile: tableau5,
        cards: [king],
      );

      expect(move.description, 'Moved K♠ from Tableau 1 to Tableau 5');
    });

    test('describes multiple card move from tableau to tableau', () {
      final tableau1 = Pile(type: PileType.tableau, index: 0);
      final tableau5 = Pile(type: PileType.tableau, index: 4);
      final cards = [
        PlayingCard(suit: Suit.spades, rank: Rank.king),
        PlayingCard(suit: Suit.hearts, rank: Rank.two),
        PlayingCard(suit: Suit.hearts, rank: Rank.ace),
      ];

      final move = Move(
        fromPile: tableau1,
        toPile: tableau5,
        cards: cards,
      );

      expect(move.description, 'Moved K♠ + 2 more from Tableau 1 to Tableau 5');
    });

    test('foundation indices are 1-based in description', () {
      final waste = Pile(type: PileType.waste);
      final foundation3 = Pile(type: PileType.foundation, index: 2);
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace);

      final move = Move(
        fromPile: waste,
        toPile: foundation3,
        cards: [ace],
      );

      expect(move.description, 'Moved A♥ from Waste to Foundation 3');
    });

    test('tableau indices are 1-based in description', () {
      final tableau1 = Pile(type: PileType.tableau, index: 0);
      final tableau7 = Pile(type: PileType.tableau, index: 6);
      final king = PlayingCard(suit: Suit.spades, rank: Rank.king);

      final move = Move(
        fromPile: tableau1,
        toPile: tableau7,
        cards: [king],
      );

      expect(move.description, 'Moved K♠ from Tableau 1 to Tableau 7');
    });

    test('uses card suit symbols in description', () {
      final waste = Pile(type: PileType.waste);
      final foundation = Pile(type: PileType.foundation, index: 0);

      // Test all suits
      final hearts = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      final diamonds = PlayingCard(suit: Suit.diamonds, rank: Rank.two);
      final clubs = PlayingCard(suit: Suit.clubs, rank: Rank.three);
      final spades = PlayingCard(suit: Suit.spades, rank: Rank.four);

      expect(Move(fromPile: waste, toPile: foundation, cards: [hearts]).description.contains('♥'), true);
      expect(Move(fromPile: waste, toPile: foundation, cards: [diamonds]).description.contains('♦'), true);
      expect(Move(fromPile: waste, toPile: foundation, cards: [clubs]).description.contains('♣'), true);
      expect(Move(fromPile: waste, toPile: foundation, cards: [spades]).description.contains('♠'), true);
    });
  });

  group('Move Integration', () {
    test('move accurately represents a tableau-to-foundation move', () {
      final tableau = Pile(type: PileType.tableau, index: 5);
      final foundation = Pile(type: PileType.foundation, index: 2);
      final ace = PlayingCard(suit: Suit.diamonds, rank: Rank.ace);

      final move = Move(
        fromPile: tableau,
        toPile: foundation,
        cards: [ace],
        flippedCard: true,
      );

      expect(move.fromPile.type, PileType.tableau);
      expect(move.toPile.type, PileType.foundation);
      expect(move.cards.first.suit, Suit.diamonds);
      expect(move.cards.first.rank, Rank.ace);
      expect(move.flippedCard, isTrue);
    });

    test('move accurately represents a stock draw', () {
      final stock = Pile(type: PileType.stock);
      final waste = Pile(type: PileType.waste);
      final drawnCards = [
        PlayingCard(suit: Suit.hearts, rank: Rank.king),
        PlayingCard(suit: Suit.spades, rank: Rank.queen),
        PlayingCard(suit: Suit.diamonds, rank: Rank.jack),
      ];

      final move = Move(
        fromPile: stock,
        toPile: waste,
        cards: drawnCards,
        drewFromStock: true,
      );

      expect(move.drewFromStock, isTrue);
      expect(move.cards.length, 3);
      expect(move.fromPile.type, PileType.stock);
      expect(move.toPile.type, PileType.waste);
    });

    test('move accurately represents a stock recycle', () {
      final waste = Pile(type: PileType.waste);
      final stock = Pile(type: PileType.stock);
      final wasteCards = [
        PlayingCard(suit: Suit.hearts, rank: Rank.king),
        PlayingCard(suit: Suit.spades, rank: Rank.queen),
      ];

      final move = Move(
        fromPile: waste,
        toPile: stock,
        cards: wasteCards,
        drewFromStock: true,
        stockRecycleCount: 3,
      );

      expect(move.drewFromStock, isTrue);
      expect(move.stockRecycleCount, 3);
      expect(move.fromPile.type, PileType.waste);
      expect(move.toPile.type, PileType.stock);
    });
  });
}
