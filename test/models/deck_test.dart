import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/features/game/models/card.dart';
import 'package:solitude/features/game/models/deck.dart';

void main() {
  group('Deck Creation', () {
    test('new deck contains exactly 52 cards', () {
      final deck = Deck();
      expect(deck.length, 52);
    });

    test('new deck has all 4 suits', () {
      final deck = Deck();
      final suits = deck.cards.map((c) => c.suit).toSet();
      expect(suits.length, 4);
      expect(suits.contains(Suit.hearts), isTrue);
      expect(suits.contains(Suit.diamonds), isTrue);
      expect(suits.contains(Suit.clubs), isTrue);
      expect(suits.contains(Suit.spades), isTrue);
    });

    test('new deck has all 13 ranks per suit', () {
      final deck = Deck();

      for (final suit in Suit.values) {
        final cardsOfSuit = deck.cards.where((c) => c.suit == suit).toList();
        expect(cardsOfSuit.length, 13);

        final ranks = cardsOfSuit.map((c) => c.rank).toSet();
        expect(ranks.length, 13);

        for (final rank in Rank.values) {
          expect(ranks.contains(rank), isTrue);
        }
      }
    });
  });

  group('Deck shuffle', () {
    test('shuffle() changes card order', () {
      final deck = Deck();
      final originalOrder = List<PlayingCard>.from(deck.cards);

      deck.shuffle();

      // Extremely unlikely to have same order after shuffle
      expect(deck.cards, isNot(equals(originalOrder)));
    });

    test('shuffle() with seeded Random produces deterministic card faces order',
        () {
      final deck1 = Deck();
      final deck2 = Deck();

      deck1.shuffle(Random(42));
      deck2.shuffle(Random(42));

      // Cards have different uniqueIds but same suit/rank ordering when using same seed
      expect(deck1.cards.length, equals(deck2.cards.length));
      for (int i = 0; i < deck1.cards.length; i++) {
        expect(deck1.cards[i].isSameFace(deck2.cards[i]), isTrue,
            reason: 'Card at position $i should have same face');
      }
    });

    test('shuffle() preserves all 52 cards (no duplication/loss)', () {
      final deck = Deck();
      deck.shuffle();

      expect(deck.length, 52);

      // Check all combinations still exist (using isSameFace since cards have unique IDs)
      for (final suit in Suit.values) {
        for (final rank in Rank.values) {
          final hasCard =
              deck.cards.any((c) => c.suit == suit && c.rank == rank);
          expect(hasCard, isTrue, reason: 'Missing $suit $rank');
        }
      }
    });
  });

  group('Deck draw', () {
    test('draw() returns card from top', () {
      final deck = Deck();
      final topCard = deck.cards.last;

      final drawn = deck.draw();

      expect(drawn, equals(topCard));
    });

    test('draw() reduces deck length by 1', () {
      final deck = Deck();
      final originalLength = deck.length;

      deck.draw();

      expect(deck.length, originalLength - 1);
    });

    test('draw() on empty deck returns null', () {
      final deck = Deck();

      // Draw all cards
      while (!deck.isEmpty) {
        deck.draw();
      }

      expect(deck.draw(), isNull);
    });
  });

  group('Deck drawMultiple', () {
    test('drawMultiple() draws correct number of cards', () {
      final deck = Deck();
      final drawn = deck.drawMultiple(5);

      expect(drawn.length, 5);
      expect(deck.length, 47);
    });

    test('drawMultiple() returns fewer cards if deck has insufficient cards',
        () {
      final deck = Deck();

      // Draw 50 cards, leaving 2
      deck.drawMultiple(50);

      final drawn = deck.drawMultiple(5);
      expect(drawn.length, 2);
      expect(deck.isEmpty, isTrue);
    });

    test('drawMultiple() on empty deck returns empty list', () {
      final deck = Deck();

      // Empty the deck
      deck.drawMultiple(52);

      final drawn = deck.drawMultiple(5);
      expect(drawn.isEmpty, isTrue);
    });

    test('drawMultiple(0) returns empty list', () {
      final deck = Deck();
      final drawn = deck.drawMultiple(0);

      expect(drawn.isEmpty, isTrue);
      expect(deck.length, 52);
    });
  });

  group('Deck isEmpty', () {
    test('isEmpty returns true for empty deck', () {
      final deck = Deck();
      deck.drawMultiple(52);

      expect(deck.isEmpty, isTrue);
    });

    test('isEmpty returns false for non-empty deck', () {
      final deck = Deck();

      expect(deck.isEmpty, isFalse);

      deck.drawMultiple(51);
      expect(deck.isEmpty, isFalse);
    });
  });

  group('Deck length', () {
    test('length tracks remaining cards correctly', () {
      final deck = Deck();

      expect(deck.length, 52);

      deck.draw();
      expect(deck.length, 51);

      deck.drawMultiple(10);
      expect(deck.length, 41);

      deck.drawMultiple(41);
      expect(deck.length, 0);
    });
  });

  group('Deck cards getter', () {
    test('cards getter returns unmodifiable list', () {
      final deck = Deck();
      final cards = deck.cards;

      expect(() => cards.add(PlayingCard(suit: Suit.hearts, rank: Rank.ace)),
          throwsUnsupportedError);
    });

    test('cards reflects current state after draws', () {
      final deck = Deck();

      final beforeDraw = deck.cards.length;
      deck.draw();
      final afterDraw = deck.cards.length;

      expect(afterDraw, beforeDraw - 1);
    });
  });

  group('Deck with Multiple Decks', () {
    test('deck with deckCount=2 contains exactly 104 cards', () {
      final deck = Deck(deckCount: 2);
      expect(deck.length, 104);
    });

    test('deck with deckCount=2 has two of each card face', () {
      final deck = Deck(deckCount: 2);

      // Count cards by suit and rank (not by identity, since each card has unique ID)
      for (final suit in Suit.values) {
        for (final rank in Rank.values) {
          final count =
              deck.cards.where((c) => c.suit == suit && c.rank == rank).length;
          expect(count, 2, reason: 'Expected 2 copies of $suit $rank');
        }
      }
    });

    test('deck with deckCount=3 contains exactly 156 cards', () {
      final deck = Deck(deckCount: 3);
      expect(deck.length, 156);
    });
  });

  group('Deck Integration', () {
    test('multiple operations maintain deck integrity', () {
      final deck = Deck();

      deck.shuffle();
      expect(deck.length, 52);

      final drawn = deck.drawMultiple(10);
      expect(drawn.length, 10);
      expect(deck.length, 42);

      deck.shuffle();
      expect(deck.length, 42);

      final moreDraw = deck.drawMultiple(50); // More than remaining
      expect(moreDraw.length, 42);
      expect(deck.isEmpty, isTrue);
    });
  });
}
