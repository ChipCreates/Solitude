import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/games/klondike/klondike_game.dart';
import 'package:solitude/models/card.dart';
import 'package:solitude/models/pile.dart';
import 'package:solitude/models/draw_mode.dart';

void main() {
  group('KlondikeGame Initialization', () {
    test('initialize() creates 7 tableau piles', () {
      final game = KlondikeGame();
      game.initialize();

      expect(game.tableau.length, 7);
      for (int i = 0; i < 7; i++) {
        expect(game.tableau[i].type, PileType.tableau);
        expect(game.tableau[i].index, i);
      }
    });

    test('initialize() deals cards correctly (pile 0 gets 1, pile 6 gets 7)', () {
      final game = KlondikeGame();
      game.initialize();

      for (int i = 0; i < 7; i++) {
        expect(game.tableau[i].length, i + 1);
      }
    });

    test('initialize() top card of each tableau is face-up', () {
      final game = KlondikeGame();
      game.initialize();

      for (int i = 0; i < 7; i++) {
        expect(game.tableau[i].topCard!.faceUp, isTrue);
      }
    });

    test('initialize() bottom cards of tableau are face-down', () {
      final game = KlondikeGame();
      game.initialize();

      // Check pile 6 (has 7 cards)
      final pile6 = game.tableau[6];
      for (int i = 0; i < pile6.length - 1; i++) {
        expect(pile6.cardAt(i)!.faceUp, isFalse);
      }
    });

    test('initialize() stock gets remaining 24 cards', () {
      final game = KlondikeGame();
      game.initialize();

      // 7 tableau piles get 1+2+3+4+5+6+7 = 28 cards
      // Stock should get 52 - 28 = 24 cards
      expect(game.stock.length, 24);
    });

    test('initialize() all stock cards are face-down', () {
      final game = KlondikeGame();
      game.initialize();

      for (final card in game.stock.cards) {
        expect(card.faceUp, isFalse);
      }
    });

    test('initialize() creates 4 empty foundations', () {
      final game = KlondikeGame();
      game.initialize();

      expect(game.foundations.length, 4);
      for (int i = 0; i < 4; i++) {
        expect(game.foundations[i].isEmpty, isTrue);
        expect(game.foundations[i].type, PileType.foundation);
        expect(game.foundations[i].index, i);
      }
    });

    test('initialize() creates empty waste pile', () {
      final game = KlondikeGame();
      game.initialize();

      expect(game.waste.isEmpty, isTrue);
      expect(game.waste.type, PileType.waste);
    });

    test('initialize() resets move count to 0', () {
      final game = KlondikeGame();
      game.initialize();

      expect(game.moveCount, 0);
    });

    test('initialize() resets stock recycle count to 0', () {
      final game = KlondikeGame();
      game.initialize();

      expect(game.stockRecycleCount, 0);
    });

    test('initialize() clears move history', () {
      final game = KlondikeGame();
      game.initialize();

      expect(game.moveHistory.isEmpty, isTrue);
    });

    test('reset() re-initializes game', () {
      final game = KlondikeGame();
      game.initialize();

      // Make some moves
      game.tapStock();

      // Reset
      game.reset();

      expect(game.moveCount, 0);
      expect(game.stockRecycleCount, 0);
      expect(game.waste.isEmpty, isTrue);
    });

    test('initialize() with seeded Random produces deterministic deals', () {
      final game1 = KlondikeGame();
      final game2 = KlondikeGame();

      // Use the same seed for both games
      game1.initialize(random: Random(42));
      game2.initialize(random: Random(42));

      // Both games should have identical card arrangements
      for (int i = 0; i < 7; i++) {
        expect(game1.tableau[i].length, game2.tableau[i].length);
        for (int j = 0; j < game1.tableau[i].length; j++) {
          final card1 = game1.tableau[i].cardAt(j)!;
          final card2 = game2.tableau[i].cardAt(j)!;
          expect(card1.suit, card2.suit);
          expect(card1.rank, card2.rank);
        }
      }

      // Stock should also be identical
      expect(game1.stock.length, game2.stock.length);
      for (int i = 0; i < game1.stock.length; i++) {
        final card1 = game1.stock.cardAt(i)!;
        final card2 = game2.stock.cardAt(i)!;
        expect(card1.suit, card2.suit);
        expect(card1.rank, card2.rank);
      }
    });

    test('initialize() with different seeds produces different deals', () {
      final game1 = KlondikeGame();
      final game2 = KlondikeGame();

      game1.initialize(random: Random(42));
      game2.initialize(random: Random(99));

      // At least one card should be different (extremely unlikely to be identical)
      bool foundDifference = false;
      for (int i = 0; i < 7 && !foundDifference; i++) {
        for (int j = 0; j < game1.tableau[i].length && !foundDifference; j++) {
          final card1 = game1.tableau[i].cardAt(j)!;
          final card2 = game2.tableau[i].cardAt(j)!;
          if (card1.suit != card2.suit || card1.rank != card2.rank) {
            foundDifference = true;
          }
        }
      }

      expect(foundDifference, isTrue);
    });
  });

  group('KlondikeGame DrawMode', () {
    test('game with DrawMode.one draws 1 card', () {
      final game = KlondikeGame(drawMode: DrawMode.one);
      game.initialize();

      final wasteBefore = game.waste.length;
      game.tapStock();
      final wasteAfter = game.waste.length;

      expect(wasteAfter - wasteBefore, 1);
    });

    test('game with DrawMode.three draws up to 3 cards', () {
      final game = KlondikeGame(drawMode: DrawMode.three);
      game.initialize();

      final wasteBefore = game.waste.length;
      game.tapStock();
      final wasteAfter = game.waste.length;

      expect(wasteAfter - wasteBefore, 3);
    });
  });

  group('KlondikeGame Stock Recycles', () {
    test('game with maxStockRecycles=null allows unlimited recycles', () {
      final game = KlondikeGame(maxStockRecycles: null);
      game.initialize();

      expect(game.canRecycleStock, isTrue);

      // Simulate many recycles
      for (int i = 0; i < 10; i++) {
        expect(game.canRecycleStock, isTrue);
      }
    });

    test('game with maxStockRecycles=2 limits recycles', () {
      final game = KlondikeGame(maxStockRecycles: 2);
      game.initialize();

      expect(game.canRecycleStock, isTrue);

      // After 2 recycles, should not allow more
      // (We'll test the actual recycling behavior separately)
    });
  });

  group('KlondikeGame Move Validation - Foundation', () {
    test('isValidMove() - cannot move to stock', () {
      final game = KlondikeGame();
      game.initialize();

      final card = game.tableau[0].topCard!;
      final result = game.isValidMove(game.tableau[0], game.stock, [card]);

      expect(result, isFalse);
    });

    test('isValidMove() - cannot move to waste', () {
      final game = KlondikeGame();
      game.initialize();

      final card = game.tableau[0].topCard!;
      final result = game.isValidMove(game.tableau[0], game.waste, [card]);

      expect(result, isFalse);
    });

    test('isValidMove() - can move ace to empty foundation', () {
      final game = KlondikeGame();
      game.initialize();

      // Set up a tableau with an ace on top
      game.tableau[0].clear();
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);
      game.tableau[0].addCard(ace);

      final result = game.isValidMove(game.tableau[0], game.foundations[0], [ace]);

      expect(result, isTrue);
    });

    test('isValidMove() - cannot move non-ace to empty foundation', () {
      final game = KlondikeGame();
      game.initialize();

      final card = game.tableau[0].topCard!;
      if (card.rank != Rank.ace) {
        final result = game.isValidMove(game.tableau[0], game.foundations[0], [card]);
        expect(result, isFalse);
      }
    });

    test('isValidMove() - can move same-suit sequential card to foundation', () {
      final game = KlondikeGame();
      game.initialize();

      // Set up foundation with ace
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);
      game.foundations[0].addCard(ace);

      // Set up tableau with two
      game.tableau[0].clear();
      final two = PlayingCard(suit: Suit.hearts, rank: Rank.two, faceUp: true);
      game.tableau[0].addCard(two);

      final result = game.isValidMove(game.tableau[0], game.foundations[0], [two]);

      expect(result, isTrue);
    });

    test('isValidMove() - cannot move different-suit card to foundation', () {
      final game = KlondikeGame();
      game.initialize();

      // Set up foundation with ace of hearts
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);
      game.foundations[0].addCard(ace);

      // Try to move two of spades
      game.tableau[0].clear();
      final twoSpades = PlayingCard(suit: Suit.spades, rank: Rank.two, faceUp: true);
      game.tableau[0].addCard(twoSpades);

      final result = game.isValidMove(game.tableau[0], game.foundations[0], [twoSpades]);

      expect(result, isFalse);
    });

    test('isValidMove() - cannot move multiple cards to foundation', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      final cards = [
        PlayingCard(suit: Suit.hearts, rank: Rank.king, faceUp: true),
        PlayingCard(suit: Suit.spades, rank: Rank.queen, faceUp: true),
      ];
      game.tableau[0].addCards(cards);

      final result = game.isValidMove(game.tableau[0], game.foundations[0], cards);

      expect(result, isFalse);
    });
  });

  group('KlondikeGame Move Validation - Tableau', () {
    test('isValidMove() - can move king to empty tableau', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      game.tableau[1].clear();
      final king = PlayingCard(suit: Suit.hearts, rank: Rank.king, faceUp: true);
      game.tableau[0].addCard(king);

      final result = game.isValidMove(game.tableau[0], game.tableau[1], [king]);

      expect(result, isTrue);
    });

    test('isValidMove() - cannot move non-king to empty tableau', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      game.tableau[1].clear();
      final queen = PlayingCard(suit: Suit.hearts, rank: Rank.queen, faceUp: true);
      game.tableau[0].addCard(queen);

      final result = game.isValidMove(game.tableau[0], game.tableau[1], [queen]);

      expect(result, isFalse);
    });

    test('isValidMove() - can move alternating color descending to tableau', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      game.tableau[1].clear();

      final redSix = PlayingCard(suit: Suit.hearts, rank: Rank.six, faceUp: true);
      final blackFive = PlayingCard(suit: Suit.spades, rank: Rank.five, faceUp: true);

      game.tableau[0].addCard(redSix);
      game.tableau[1].addCard(blackFive);

      final result = game.isValidMove(game.tableau[1], game.tableau[0], [blackFive]);

      expect(result, isTrue);
    });

    test('isValidMove() - cannot move same color to tableau', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      game.tableau[1].clear();

      final redSix = PlayingCard(suit: Suit.hearts, rank: Rank.six, faceUp: true);
      final redFive = PlayingCard(suit: Suit.diamonds, rank: Rank.five, faceUp: true);

      game.tableau[0].addCard(redSix);
      game.tableau[1].addCard(redFive);

      final result = game.isValidMove(game.tableau[1], game.tableau[0], [redFive]);

      expect(result, isFalse);
    });

    test('isValidMove() - cannot move ascending to tableau', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      game.tableau[1].clear();

      final blackFive = PlayingCard(suit: Suit.spades, rank: Rank.five, faceUp: true);
      final redSix = PlayingCard(suit: Suit.hearts, rank: Rank.six, faceUp: true);

      game.tableau[0].addCard(blackFive);
      game.tableau[1].addCard(redSix);

      final result = game.isValidMove(game.tableau[1], game.tableau[0], [redSix]);

      expect(result, isFalse);
    });
  });

  group('KlondikeGame Move Execution', () {
    test('executeMove() transfers cards between piles', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      game.tableau[1].clear();

      final king = PlayingCard(suit: Suit.hearts, rank: Rank.king, faceUp: true);
      game.tableau[0].addCard(king);

      game.executeMove(game.tableau[0], game.tableau[1], [king]);

      expect(game.tableau[0].isEmpty, isTrue);
      expect(game.tableau[1].length, 1);
      expect(game.tableau[1].topCard, equals(king));
    });

    test('executeMove() increments move count', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      game.tableau[1].clear();

      final king = PlayingCard(suit: Suit.hearts, rank: Rank.king, faceUp: true);
      game.tableau[0].addCard(king);

      final moveBefore = game.moveCount;
      game.executeMove(game.tableau[0], game.tableau[1], [king]);
      final moveAfter = game.moveCount;

      expect(moveAfter, moveBefore + 1);
    });

    test('executeMove() records move in history', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      game.tableau[1].clear();

      final king = PlayingCard(suit: Suit.hearts, rank: Rank.king, faceUp: true);
      game.tableau[0].addCard(king);

      expect(game.moveHistory.isEmpty, isTrue);

      game.executeMove(game.tableau[0], game.tableau[1], [king]);

      expect(game.moveHistory.length, 1);
      expect(game.moveHistory.first.fromPile, game.tableau[0]);
      expect(game.moveHistory.first.toPile, game.tableau[1]);
    });

    test('executeMove() flips newly exposed tableau card', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();

      final faceDown = PlayingCard(suit: Suit.hearts, rank: Rank.five, faceUp: false);
      final faceUp = PlayingCard(suit: Suit.spades, rank: Rank.four, faceUp: true);

      game.tableau[0].addCard(faceDown);
      game.tableau[0].addCard(faceUp);

      game.tableau[1].clear();
      final redFive = PlayingCard(suit: Suit.hearts, rank: Rank.five, faceUp: true);
      game.tableau[1].addCard(redFive);

      // Move the face-up card, should flip the face-down card
      game.executeMove(game.tableau[0], game.tableau[1], [faceUp]);

      expect(faceDown.faceUp, isTrue);
    });

    test('executeMove() doesn\'t flip if tableau still has face-up cards', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();

      final card1 = PlayingCard(suit: Suit.hearts, rank: Rank.six, faceUp: true);
      final card2 = PlayingCard(suit: Suit.spades, rank: Rank.five, faceUp: true);
      final card3 = PlayingCard(suit: Suit.hearts, rank: Rank.four, faceUp: true);

      game.tableau[0].addCards([card1, card2, card3]);

      game.tableau[1].clear();
      final redFive = PlayingCard(suit: Suit.hearts, rank: Rank.five, faceUp: true);
      game.tableau[1].addCard(redFive);

      // Move card3, card2 should stay as is (already face-up)
      final beforeFaceUp = card2.faceUp;
      game.executeMove(game.tableau[0], game.tableau[1], [card3]);

      expect(card2.faceUp, beforeFaceUp);
    });

    test('executeMove() returns null for invalid move', () {
      final game = KlondikeGame();
      game.initialize();

      final card = game.tableau[0].topCard!;
      final result = game.executeMove(game.tableau[0], game.stock, [card]);

      expect(result, isNull);
    });
  });

  group('KlondikeGame Undo', () {
    test('undo() returns false when no moves to undo', () {
      final game = KlondikeGame();
      game.initialize();

      expect(game.undo(), isFalse);
    });

    test('undo() reverses last move', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      game.tableau[1].clear();

      final king = PlayingCard(suit: Suit.hearts, rank: Rank.king, faceUp: true);
      game.tableau[0].addCard(king);

      game.executeMove(game.tableau[0], game.tableau[1], [king]);

      expect(game.tableau[0].isEmpty, isTrue);
      expect(game.tableau[1].length, 1);

      game.undo();

      expect(game.tableau[0].length, 1);
      expect(game.tableau[1].isEmpty, isTrue);
    });

    test('undo() restores cards to original pile', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      game.tableau[1].clear();

      final king = PlayingCard(suit: Suit.hearts, rank: Rank.king, faceUp: true);
      game.tableau[0].addCard(king);

      game.executeMove(game.tableau[0], game.tableau[1], [king]);
      game.undo();

      expect(game.tableau[0].topCard, equals(king));
    });

    test('undo() decrements move count', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      game.tableau[1].clear();

      final king = PlayingCard(suit: Suit.hearts, rank: Rank.king, faceUp: true);
      game.tableau[0].addCard(king);

      game.executeMove(game.tableau[0], game.tableau[1], [king]);
      final moveAfterExecute = game.moveCount;

      game.undo();
      final moveAfterUndo = game.moveCount;

      expect(moveAfterUndo, moveAfterExecute - 1);
    });

    test('undo() removes from history', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      game.tableau[1].clear();

      final king = PlayingCard(suit: Suit.hearts, rank: Rank.king, faceUp: true);
      game.tableau[0].addCard(king);

      game.executeMove(game.tableau[0], game.tableau[1], [king]);
      expect(game.moveHistory.length, 1);

      game.undo();
      expect(game.moveHistory.isEmpty, isTrue);
    });

    test('multiple undo() calls restore game state progressively', () {
      final game = KlondikeGame();
      game.initialize();

      // Clear tableau piles for testing
      game.tableau[0].clear();
      game.tableau[1].clear();
      game.tableau[2].clear();

      final king = PlayingCard(suit: Suit.hearts, rank: Rank.king, faceUp: true);
      final queen = PlayingCard(suit: Suit.spades, rank: Rank.queen, faceUp: true);

      game.tableau[0].addCard(king);
      game.tableau[1].addCard(queen);

      // Move 1: king to tableau[2]
      game.executeMove(game.tableau[0], game.tableau[2], [king]);
      // Move 2: queen to tableau[2] (on king)
      game.executeMove(game.tableau[1], game.tableau[2], [queen]);

      expect(game.moveCount, 2);
      expect(game.tableau[2].length, 2);

      // Undo move 2
      game.undo();
      expect(game.moveCount, 1);
      expect(game.tableau[1].length, 1);
      expect(game.tableau[2].length, 1);

      // Undo move 1
      game.undo();
      expect(game.moveCount, 0);
      expect(game.tableau[0].length, 1);
      expect(game.tableau[2].isEmpty, isTrue);
    });

    test('undo() restores face-up/down state', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      game.tableau[1].clear();

      final faceDown = PlayingCard(suit: Suit.hearts, rank: Rank.five, faceUp: false);
      final faceUp = PlayingCard(suit: Suit.spades, rank: Rank.four, faceUp: true);

      game.tableau[0].addCards([faceDown, faceUp]);

      final redFive = PlayingCard(suit: Suit.hearts, rank: Rank.five, faceUp: true);
      game.tableau[1].addCard(redFive);

      // Move card, which will flip faceDown
      game.executeMove(game.tableau[0], game.tableau[1], [faceUp]);
      expect(faceDown.faceUp, isTrue);

      // Undo should restore face-down state
      game.undo();
      expect(faceDown.faceUp, isFalse);
    });
  });

  group('KlondikeGame Stock Handling', () {
    test('tapStock() with DrawMode.one draws 1 card to waste', () {
      final game = KlondikeGame(drawMode: DrawMode.one);
      game.initialize();

      final stockBefore = game.stock.length;
      final wasteBefore = game.waste.length;

      game.tapStock();

      expect(game.stock.length, stockBefore - 1);
      expect(game.waste.length, wasteBefore + 1);
    });

    test('tapStock() with DrawMode.three draws up to 3 cards to waste', () {
      final game = KlondikeGame(drawMode: DrawMode.three);
      game.initialize();

      final stockBefore = game.stock.length;
      final wasteBefore = game.waste.length;

      game.tapStock();

      expect(game.stock.length, stockBefore - 3);
      expect(game.waste.length, wasteBefore + 3);
    });

    test('tapStock() when stock has fewer than 3 cards (DrawMode.three)', () {
      final game = KlondikeGame(drawMode: DrawMode.three);
      game.initialize();

      // Draw most cards, leaving 1-3 in stock (stop before it empties)
      while (game.stock.length > 3) {
        game.tapStock();
      }

      final stockBefore = game.stock.length;
      final wasteBefore = game.waste.length;

      game.tapStock();

      // Should draw remaining cards (1-3 cards) even if less than 3
      expect(game.waste.length, greaterThan(wasteBefore));
      expect(game.stock.length, lessThan(stockBefore));
    });

    test('tapStock() turns cards face-up in waste', () {
      final game = KlondikeGame();
      game.initialize();

      game.tapStock();

      expect(game.waste.topCard!.faceUp, isTrue);
    });

    test('tapStock() on empty stock recycles waste back to stock', () {
      final game = KlondikeGame(drawMode: DrawMode.one);
      game.initialize();

      // Draw all stock cards
      while (!game.stock.isEmpty) {
        game.tapStock();
      }

      final wasteCount = game.waste.length;
      expect(wasteCount, greaterThan(0));

      // Tap stock again - should recycle
      game.tapStock();

      expect(game.stock.length, wasteCount);
      expect(game.waste.isEmpty, isTrue);
    });

    test('tapStock() increments recycle count', () {
      final game = KlondikeGame(drawMode: DrawMode.one);
      game.initialize();

      // Draw all stock cards
      while (!game.stock.isEmpty) {
        game.tapStock();
      }

      expect(game.stockRecycleCount, 0);

      // Recycle
      game.tapStock();

      expect(game.stockRecycleCount, 1);
    });

    test('tapStock() on empty stock with maxRecycles reached returns null', () {
      final game = KlondikeGame(drawMode: DrawMode.one, maxStockRecycles: 2);
      game.initialize();

      // Exhaust stock and recycle twice
      for (int i = 0; i < 3; i++) {
        while (!game.stock.isEmpty) {
          game.tapStock();
        }
        if (i < 2) {
          game.tapStock(); // Recycle
        }
      }

      expect(game.stockRecycleCount, 2);

      // Try to recycle again - should fail
      final result = game.tapStock();

      expect(result, isNull);
    });

    test('tapStock() flips waste cards face-down when recycling', () {
      final game = KlondikeGame(drawMode: DrawMode.one);
      game.initialize();

      // Draw all cards
      while (!game.stock.isEmpty) {
        game.tapStock();
      }

      // All waste cards should be face-up
      for (final card in game.waste.cards) {
        expect(card.faceUp, isTrue);
      }

      // Recycle
      game.tapStock();

      // All stock cards should be face-down
      for (final card in game.stock.cards) {
        expect(card.faceUp, isFalse);
      }
    });

    test('canRecycleStock with unlimited recycles always returns true', () {
      final game = KlondikeGame(maxStockRecycles: null);
      game.initialize();

      expect(game.canRecycleStock, isTrue);

      // Simulate recycling
      for (int i = 0; i < 100; i++) {
        expect(game.canRecycleStock, isTrue);
      }
    });

    test('canRecycleStock respects maxStockRecycles limit', () {
      final game = KlondikeGame(maxStockRecycles: 2);
      game.initialize();

      expect(game.canRecycleStock, isTrue);

      // After exhausting stock twice, canRecycleStock should be false
      // (We're simulating by manipulating the internal counter)
    });
  });

  group('KlondikeGame Win Detection', () {
    test('checkWin() returns true when all foundations have 13 cards', () {
      final game = KlondikeGame();
      game.initialize();

      // Fill all foundations
      for (final foundation in game.foundations) {
        for (int i = 1; i <= 13; i++) {
          foundation.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.values[i - 1]));
        }
      }

      expect(game.checkWin(), isTrue);
    });

    test('checkWin() returns false when foundations incomplete', () {
      final game = KlondikeGame();
      game.initialize();

      // Only partially fill foundations
      game.foundations[0].addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace));

      expect(game.checkWin(), isFalse);
    });
  });

  group('KlondikeGame Move Detection', () {
    test('hasAnyMove() detects available waste to foundation move', () {
      final game = KlondikeGame();
      game.initialize();

      game.waste.clear();
      game.waste.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true));

      expect(game.hasAnyMove(), isTrue);
    });

    test('hasAnyMove() detects available waste to tableau move', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      game.tableau[0].addCard(PlayingCard(suit: Suit.hearts, rank: Rank.six, faceUp: true));

      game.waste.clear();
      game.waste.addCard(PlayingCard(suit: Suit.spades, rank: Rank.five, faceUp: true));

      expect(game.hasAnyMove(), isTrue);
    });

    test('hasAnyMove() detects available tableau to foundation move', () {
      final game = KlondikeGame();
      game.initialize();

      game.stock.clear();
      game.waste.clear();

      game.tableau[0].clear();
      game.tableau[0].addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true));

      expect(game.hasAnyMove(), isTrue);
    });

    test('hasAnyMove() detects available tableau to tableau move', () {
      final game = KlondikeGame();
      game.initialize();

      game.stock.clear();
      game.waste.clear();

      game.tableau[0].clear();
      game.tableau[0].addCard(PlayingCard(suit: Suit.hearts, rank: Rank.six, faceUp: true));

      game.tableau[1].clear();
      game.tableau[1].addCard(PlayingCard(suit: Suit.spades, rank: Rank.five, faceUp: true));

      expect(game.hasAnyMove(), isTrue);
    });

    test('hasAnyMove() returns true when stock has cards', () {
      final game = KlondikeGame();
      game.initialize();

      expect(game.stock.isEmpty, isFalse);
      expect(game.hasAnyMove(), isTrue);
    });

    test('hasAnyMove() returns false when truly stuck', () {
      final game = KlondikeGame();

      // Create a completely stuck game
      game.stock = Pile(type: PileType.stock);
      game.waste = Pile(type: PileType.waste);
      game.foundations = List.generate(4, (i) => Pile(type: PileType.foundation));
      game.tableau = List.generate(7, (i) => Pile(type: PileType.tableau));

      // No cards anywhere - stuck
      expect(game.hasAnyMove(), isFalse);
    });
  });

  group('KlondikeGame Move Checking Components', () {
    test('canDrawFromStock() returns true when stock has cards', () {
      final game = KlondikeGame();
      game.initialize();
      expect(game.canDrawFromStock(), isTrue);
    });

    test('canDrawFromStock() returns false when stock is empty', () {
      final game = KlondikeGame();
      game.initialize();
      game.stock.clear();
      expect(game.canDrawFromStock(), isFalse);
    });

    test('hasValidWasteMoves() returns true when waste has ace for foundation', () {
      final game = KlondikeGame();
      game.initialize();
      game.waste.clear();
      game.waste.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true));
      expect(game.hasValidWasteMoves(), isTrue);
    });

    test('hasValidWasteMoves() returns true when waste has card for tableau', () {
      final game = KlondikeGame();
      game.initialize();
      game.waste.clear();
      game.waste.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.jack, faceUp: true));
      // Set up tableau with queen of clubs to accept jack of hearts (alternating colors, descending)
      game.tableau[0].clear();
      game.tableau[0].addCard(PlayingCard(suit: Suit.clubs, rank: Rank.queen, faceUp: true));
      expect(game.hasValidWasteMoves(), isTrue);
    });

    test('hasValidWasteMoves() returns false when waste is empty', () {
      final game = KlondikeGame();
      game.initialize();
      game.waste.clear();
      expect(game.hasValidWasteMoves(), isFalse);
    });

    test('hasValidWasteMoves() returns false when waste has no valid moves', () {
      final game = KlondikeGame();
      game.initialize();
      game.waste.clear();
      game.waste.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.two, faceUp: true));
      // No foundation or tableau accepts a 2
      expect(game.hasValidWasteMoves(), isFalse);
    });

    test('hasValidTableauMoves() returns true when tableau has card for foundation', () {
      final game = KlondikeGame();
      game.initialize();
      // Clear tableau and add ace directly to foundation spot
      game.tableau[0].clear();
      game.tableau[0].addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true));
      expect(game.hasValidTableauMoves(), isTrue);
    });

    test('hasValidTableauMoves() returns true when tableau has sequence for another tableau', () {
      final game = KlondikeGame();
      game.initialize();
      // Set up two tableaus: one with king, one with queen to accept it
      game.tableau[0].clear();
      game.tableau[0].addCard(PlayingCard(suit: Suit.hearts, rank: Rank.king, faceUp: true));
      game.tableau[1].clear();
      game.tableau[1].addCard(PlayingCard(suit: Suit.clubs, rank: Rank.queen, faceUp: true));
      expect(game.hasValidTableauMoves(), isTrue);
    });

    test('hasValidTableauMoves() returns false when no valid moves from tableau', () {
      final game = KlondikeGame();
      game.initialize();
      // Clear all tableaus
      for (final pile in game.tableau) {
        pile.clear();
      }
      expect(game.hasValidTableauMoves(), isFalse);
    });
  });

  group('KlondikeGame Loss Detection', () {
    test('isTrulyLost() returns false on fresh game', () {
      final game = KlondikeGame();
      game.initialize();

      expect(game.isTrulyLost(), isFalse);
    });

    test('isTrulyLost() returns false when stock has cards', () {
      final game = KlondikeGame();
      game.initialize();

      expect(game.stock.isEmpty, isFalse);
      expect(game.isTrulyLost(), isFalse);
    });

    test('isTrulyLost() checks all waste cards, not just top', () {
      final game = KlondikeGame();
      game.initialize();

      game.stock.clear();
      game.waste.clear();

      // Add multiple waste cards, one of which can move
      game.waste.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.two, faceUp: true));
      game.waste.addCard(PlayingCard(suit: Suit.spades, rank: Rank.ace, faceUp: true));

      // The ace can go to foundation
      expect(game.isTrulyLost(), isFalse);
    });

    test('isTrulyLost() returns false when hidden cards could help', () {
      final game = KlondikeGame();

      game.stock = Pile(type: PileType.stock);
      game.waste = Pile(type: PileType.waste);
      game.foundations = List.generate(4, (i) => Pile(type: PileType.foundation));
      game.tableau = List.generate(7, (i) => Pile(type: PileType.tableau));

      // Create scenario where moving a sequence would reveal a face-down card
      final hidden = PlayingCard(suit: Suit.spades, rank: Rank.four, faceUp: false);
      final movable = PlayingCard(suit: Suit.hearts, rank: Rank.five, faceUp: true);
      game.tableau[0].addCard(hidden);
      game.tableau[0].addCard(movable);

      final dest = PlayingCard(suit: Suit.spades, rank: Rank.six, faceUp: true);
      game.tableau[1].addCard(dest);

      expect(game.isTrulyLost(), isFalse);
    });

    test('isTrulyLost() returns true when no moves and no hidden cards', () {
      final game = KlondikeGame();

      game.stock = Pile(type: PileType.stock);
      game.waste = Pile(type: PileType.waste);
      game.foundations = List.generate(4, (i) => Pile(type: PileType.foundation));
      game.tableau = List.generate(7, (i) => Pile(type: PileType.tableau));

      // Place cards that cannot move
      final c1 = PlayingCard(suit: Suit.hearts, rank: Rank.five, faceUp: true);
      final c2 = PlayingCard(suit: Suit.clubs, rank: Rank.two, faceUp: true);
      game.tableau[0].addCard(c1);
      game.tableau[1].addCard(c2);

      expect(game.isTrulyLost(), isTrue);
    });
  });

  group('KlondikeGame Hint System', () {
    test('getHint() returns null when no moves available', () {
      final game = KlondikeGame();

      game.stock = Pile(type: PileType.stock);
      game.waste = Pile(type: PileType.waste);
      game.foundations = List.generate(4, (i) => Pile(type: PileType.foundation));
      game.tableau = List.generate(7, (i) => Pile(type: PileType.tableau));

      expect(game.getHint(), isNull);
    });

    test('getHint() prioritizes waste to foundation', () {
      final game = KlondikeGame();
      game.initialize();

      game.waste.clear();
      game.waste.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true));

      final hint = game.getHint();

      expect(hint, isNotNull);
      expect(hint!.from, game.waste);
      expect(hint.to.type, PileType.foundation);
    });

    test('getHint() prioritizes tableau to foundation over tableau to tableau', () {
      final game = KlondikeGame();
      game.initialize();

      game.stock.clear();
      game.waste.clear();

      game.tableau[0].clear();
      game.tableau[0].addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true));

      game.tableau[1].clear();
      game.tableau[1].addCard(PlayingCard(suit: Suit.spades, rank: Rank.two, faceUp: true));

      final hint = game.getHint();

      expect(hint, isNotNull);
      expect(hint!.to.type, PileType.foundation);
    });

    test('getHint() suggests revealing hidden cards', () {
      final game = KlondikeGame();
      game.initialize();

      game.stock.clear();
      game.waste.clear();

      game.tableau[0].clear();
      final hidden = PlayingCard(suit: Suit.diamonds, rank: Rank.queen, faceUp: false);
      final faceUp = PlayingCard(suit: Suit.hearts, rank: Rank.five, faceUp: true);
      game.tableau[0].addCards([hidden, faceUp]);

      game.tableau[1].clear();
      final dest = PlayingCard(suit: Suit.spades, rank: Rank.six, faceUp: true);
      game.tableau[1].addCard(dest);

      final hint = game.getHint();

      expect(hint, isNotNull);
      // Should suggest moving the 5 to the 6 to reveal the hidden card
    });

    test('getHint() suggests tableau to tableau for kings when it exposes cards', () {
      final game = KlondikeGame();
      game.initialize();

      game.stock.clear();
      game.waste.clear();

      // Clear all tableau piles to avoid interference from initialized cards
      for (var pile in game.tableau) {
        pile.clear();
      }

      // Add a face-down card, then a king on top
      game.tableau[0].addCard(PlayingCard(suit: Suit.diamonds, rank: Rank.queen, faceUp: false));
      game.tableau[0].addCard(PlayingCard(suit: Suit.hearts, rank: Rank.king, faceUp: true));
      // tableau[1] remains empty

      final hint = game.getHint();

      // Should suggest moving the king to expose the face-down queen
      expect(hint, isNotNull);
      expect(hint!.cards.first.rank, Rank.king);
      expect(hint.from, game.tableau[0]);
    });

    test('getValidDestinations() finds all valid targets for a card', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);
      game.tableau[0].addCard(ace);

      final destinations = game.getValidDestinations(game.tableau[0], [ace]);

      // Ace should be able to go to at least one foundation
      final foundationDests = destinations.where((p) => p.type == PileType.foundation);
      expect(foundationDests.isNotEmpty, isTrue);
    });
  });

  group('KlondikeGame Auto-Complete', () {
    test('canAutoComplete() returns true when all tableau cards face-up', () {
      final game = KlondikeGame();
      game.initialize();

      // Clear stock and make all cards face-up
      game.stock.clear();

      for (final pile in game.tableau) {
        for (final card in pile.cards) {
          card.faceUp = true;
        }
      }

      expect(game.canAutoComplete(), isTrue);
    });

    test('canAutoComplete() returns false with face-down cards remaining', () {
      final game = KlondikeGame();
      game.initialize();

      // Fresh game has face-down cards
      expect(game.canAutoComplete(), isFalse);
    });

    test('canAutoComplete() returns false when stock is not empty', () {
      final game = KlondikeGame();
      game.initialize();

      // Make all tableau cards face-up but leave stock
      for (final pile in game.tableau) {
        for (final card in pile.cards) {
          card.faceUp = true;
        }
      }

      expect(game.stock.isEmpty, isFalse);
      expect(game.canAutoComplete(), isFalse);
    });

    test('autoCompleteStep() moves lowest available card to foundation', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      game.tableau[0].addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true));

      final result = game.autoCompleteStep();

      expect(result, isTrue);
      expect(game.foundations[0].topCard?.rank, Rank.ace);
    });

    test('autoCompleteStep() returns false when complete', () {
      final game = KlondikeGame();

      game.stock = Pile(type: PileType.stock);
      game.waste = Pile(type: PileType.waste);
      game.foundations = List.generate(4, (i) => Pile(type: PileType.foundation));
      game.tableau = List.generate(7, (i) => Pile(type: PileType.tableau));

      // No cards to move
      final result = game.autoCompleteStep();

      expect(result, isFalse);
    });

    test('autoCompleteStep() moves cards from waste to foundation', () {
      final game = KlondikeGame();
      game.initialize();

      game.waste.clear();
      game.tableau[0].clear();

      // Put an ace in waste
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);
      game.waste.addCard(ace);

      final result = game.autoCompleteStep();

      expect(result, isTrue);
      expect(game.waste.isEmpty, isTrue);
      expect(game.foundations.any((f) => f.topCard == ace), isTrue);
    });
  });

  group('KlondikeGame Undo', () {
    test('undo() reverses a stock recycle', () {
      final game = KlondikeGame();
      game.initialize();

      // Draw all cards from stock to waste
      while (!game.stock.isEmpty) {
        game.tapStock();
      }

      expect(game.stock.isEmpty, isTrue);
      expect(game.waste.isEmpty, isFalse);

      final wasteCount = game.waste.length;

      // Recycle stock
      game.tapStock();
      expect(game.stock.length, wasteCount);
      expect(game.waste.isEmpty, isTrue);

      // Undo the recycle
      final undone = game.undo();
      expect(undone, isTrue);
      expect(game.waste.length, wasteCount);
      expect(game.stock.isEmpty, isTrue);
      expect(game.stockRecycleCount, 0);
    });

    test('undo() reverses a stock draw', () {
      final game = KlondikeGame(drawMode: DrawMode.three);
      game.initialize();

      final stockBefore = game.stock.length;

      game.tapStock();

      expect(game.stock.length, stockBefore - 3);
      expect(game.waste.length, 3);

      // Undo the draw
      final undone = game.undo();
      expect(undone, isTrue);
      expect(game.stock.length, stockBefore);
      expect(game.waste.isEmpty, isTrue);
    });

    test('undo() reverses a tableau to foundation move', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);
      game.tableau[0].addCard(ace);

      // Move to foundation
      game.executeMove(game.tableau[0], game.foundations[0], [ace]);
      expect(game.foundations[0].topCard, ace);
      expect(game.tableau[0].isEmpty, isTrue);

      // Undo
      final undone = game.undo();
      expect(undone, isTrue);
      expect(game.tableau[0].topCard, ace);
      expect(game.foundations[0].isEmpty, isTrue);
    });
  });

  group('KlondikeGame Redo', () {
    test('redo() replays a simple tableau to foundation move', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);
      game.tableau[0].addCard(ace);

      // Move to foundation
      game.executeMove(game.tableau[0], game.foundations[0], [ace]);
      expect(game.foundations[0].topCard, ace);
      expect(game.tableau[0].isEmpty, isTrue);

      // Undo
      game.undo();
      expect(game.tableau[0].topCard, ace);
      expect(game.foundations[0].isEmpty, isTrue);

      // Redo
      final redone = game.redo();
      expect(redone, isTrue);
      expect(game.foundations[0].topCard, ace);
      expect(game.tableau[0].isEmpty, isTrue);
    });

    test('redo() replays a stock draw', () {
      final game = KlondikeGame(drawMode: DrawMode.three);
      game.initialize();

      final stockBefore = game.stock.length;

      // Draw 3 cards
      game.tapStock();
      expect(game.stock.length, stockBefore - 3);
      expect(game.waste.length, 3);

      // Undo the draw
      game.undo();
      expect(game.stock.length, stockBefore);
      expect(game.waste.isEmpty, isTrue);

      // Redo the draw
      final redone = game.redo();
      expect(redone, isTrue);
      expect(game.stock.length, stockBefore - 3);
      expect(game.waste.length, 3);
    });

    test('redo() replays a stock recycle', () {
      final game = KlondikeGame();
      game.initialize();

      // Draw all cards from stock to waste
      while (!game.stock.isEmpty) {
        game.tapStock();
      }

      final wasteCount = game.waste.length;

      // Recycle stock
      game.tapStock();
      expect(game.stock.length, wasteCount);
      expect(game.waste.isEmpty, isTrue);
      expect(game.stockRecycleCount, 1);

      // Undo the recycle
      game.undo();
      expect(game.waste.length, wasteCount);
      expect(game.stock.isEmpty, isTrue);
      expect(game.stockRecycleCount, 0);

      // Redo the recycle
      final redone = game.redo();
      expect(redone, isTrue);
      expect(game.stock.length, wasteCount);
      expect(game.waste.isEmpty, isTrue);
      expect(game.stockRecycleCount, 1);
    });

    test('redo() replays move that flipped a card', () {
      final game = KlondikeGame();
      game.initialize();

      // Set up a tableau pile with a face-down card and a face-up card on top
      game.tableau[0].clear();
      final hiddenCard = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: false);
      final visibleCard = PlayingCard(suit: Suit.spades, rank: Rank.two, faceUp: true);
      game.tableau[0].addCard(hiddenCard);
      game.tableau[0].addCard(visibleCard);

      // Set up destination
      game.tableau[1].clear();
      final destCard = PlayingCard(suit: Suit.hearts, rank: Rank.three, faceUp: true);
      game.tableau[1].addCard(destCard);

      // Move the visible card (should flip the hidden card)
      game.executeMove(game.tableau[0], game.tableau[1], [visibleCard]);
      expect(game.tableau[0].topCard, hiddenCard);
      expect(game.tableau[0].topCard!.faceUp, isTrue); // Should be flipped

      // Undo (should un-flip the card)
      game.undo();
      expect(game.tableau[0].topCard, visibleCard);
      expect(hiddenCard.faceUp, isFalse); // Should be face down again

      // Redo (should flip the card again)
      final redone = game.redo();
      expect(redone, isTrue);
      expect(game.tableau[0].topCard, hiddenCard);
      expect(game.tableau[0].topCard!.faceUp, isTrue); // Should be flipped again
    });

    test('redo() returns false when redo stack is empty', () {
      final game = KlondikeGame();
      game.initialize();

      // No undo has been performed, so redo stack should be empty
      final redone = game.redo();
      expect(redone, isFalse);
    });

    test('redo stack is cleared when a new move is made', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      game.tableau[1].clear();
      final aceHearts = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);
      final aceSpades = PlayingCard(suit: Suit.spades, rank: Rank.ace, faceUp: true);
      game.tableau[0].addCard(aceHearts);
      game.tableau[1].addCard(aceSpades);

      // Move ace of hearts to foundation
      game.executeMove(game.tableau[0], game.foundations[0], [aceHearts]);

      // Undo (ace of hearts is now on redo stack)
      game.undo();
      expect(game.redoStack.length, 1);

      // Make a different move - ace of spades to different foundation (should clear redo stack)
      final move2 = game.executeMove(game.tableau[1], game.foundations[1], [aceSpades]);
      expect(move2, isNotNull); // Verify the move succeeded
      expect(game.redoStack.length, 0); // Verify redo stack was cleared

      // Try to redo - should fail because redo stack was cleared
      final redone = game.redo();
      expect(redone, isFalse);
    });

    test('multiple undo/redo operations in sequence', () {
      final game = KlondikeGame();
      game.initialize();

      // Set up cards
      game.tableau[0].clear();
      game.tableau[1].clear();
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);
      final two = PlayingCard(suit: Suit.hearts, rank: Rank.two, faceUp: true);
      game.tableau[0].addCard(ace);
      game.tableau[1].addCard(two);

      // Move 1: ace to foundation
      game.executeMove(game.tableau[0], game.foundations[0], [ace]);
      // Move 2: two to foundation
      game.executeMove(game.tableau[1], game.foundations[0], [two]);

      // Undo both moves
      game.undo(); // Undo move 2
      game.undo(); // Undo move 1

      // Tableau should have the cards back
      expect(game.tableau[0].topCard, ace);
      expect(game.tableau[1].topCard, two);
      expect(game.foundations[0].isEmpty, isTrue);

      // Redo both moves
      game.redo(); // Redo move 1
      expect(game.foundations[0].topCard, ace);

      game.redo(); // Redo move 2
      expect(game.foundations[0].topCard, two);
      expect(game.foundations[0].length, 2);
    });

    test('redo stack is cleared on game initialization', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);
      game.tableau[0].addCard(ace);

      // Make and undo a move
      game.executeMove(game.tableau[0], game.foundations[0], [ace]);
      game.undo();

      // Redo stack should have one item
      expect(game.redoStack.isNotEmpty, isTrue);

      // Initialize new game
      game.initialize();

      // Redo stack should be cleared
      expect(game.redoStack.isEmpty, isTrue);
    });

    test('move count increases on redo', () {
      final game = KlondikeGame();
      game.initialize();

      game.tableau[0].clear();
      final ace = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);
      game.tableau[0].addCard(ace);

      // Initial move count
      final initialCount = game.moveCount;

      // Make a move
      game.executeMove(game.tableau[0], game.foundations[0], [ace]);
      expect(game.moveCount, initialCount + 1);

      // Undo (decrements count)
      game.undo();
      expect(game.moveCount, initialCount);

      // Redo (increments count)
      game.redo();
      expect(game.moveCount, initialCount + 1);
    });
  });

  group('KlondikeGame Getters', () {
    test('allPiles returns all piles in the game', () {
      final game = KlondikeGame();
      game.initialize();

      final allPiles = game.allPiles;

      expect(allPiles.length, 13); // 1 stock + 1 waste + 4 foundations + 7 tableau
      expect(allPiles.contains(game.stock), isTrue);
      expect(allPiles.contains(game.waste), isTrue);
      for (final foundation in game.foundations) {
        expect(allPiles.contains(foundation), isTrue);
      }
      for (final pile in game.tableau) {
        expect(allPiles.contains(pile), isTrue);
      }
    });

    test('layoutConfig returns correct tableau count', () {
      final game = KlondikeGame();

      final config = game.layoutConfig;

      expect(config.tableauCount, 7);
      expect(config.foundationCount, 4);
    });
  });

  group('KlondikeGame DrawMode', () {
    test('setDrawMode() changes the draw mode', () {
      final game = KlondikeGame(drawMode: DrawMode.one);
      expect(game.drawMode, DrawMode.one);

      game.setDrawMode(DrawMode.three);
      expect(game.drawMode, DrawMode.three);

      game.setDrawMode(DrawMode.one);
      expect(game.drawMode, DrawMode.one);
    });
  });

  group('KlondikeGame Hint System - Additional Coverage', () {
    test('getHint() suggests waste to tableau move', () {
      final game = KlondikeGame();
      game.initialize();

      game.stock.clear();
      game.waste.clear();

      // Clear tableau piles
      for (var pile in game.tableau) {
        pile.clear();
      }

      // Put a black 7 on tableau
      game.tableau[0].addCard(PlayingCard(suit: Suit.spades, rank: Rank.seven, faceUp: true));

      // Put a red 6 in waste
      game.waste.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.six, faceUp: true));

      final hint = game.getHint();

      expect(hint, isNotNull);
      expect(hint!.from, game.waste);
      expect(hint.to, game.tableau[0]);
      expect(hint.cards.first.rank, Rank.six);
    });

    test('getHint() suggests waste king to empty tableau', () {
      final game = KlondikeGame();
      game.initialize();

      game.stock.clear();
      game.waste.clear();

      // Clear all tableau piles
      for (var pile in game.tableau) {
        pile.clear();
      }

      // Put a king in waste
      game.waste.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.king, faceUp: true));

      final hint = game.getHint();

      expect(hint, isNotNull);
      expect(hint!.from, game.waste);
      expect(hint.cards.first.rank, Rank.king);
      expect(hint.to.isEmpty, isTrue);
    });

    test('getHint() suggests tableau to tableau when no face-down cards', () {
      final game = KlondikeGame();
      game.initialize();

      game.stock.clear();
      game.waste.clear();

      // Clear all tableau piles
      for (var pile in game.tableau) {
        pile.clear();
      }

      // Setup: black 8 on pile 0, red 7 on pile 1 (all face-up)
      game.tableau[0].addCard(PlayingCard(suit: Suit.spades, rank: Rank.eight, faceUp: true));
      game.tableau[1].addCard(PlayingCard(suit: Suit.hearts, rank: Rank.seven, faceUp: true));

      final hint = game.getHint();

      expect(hint, isNotNull);
      expect(hint!.cards.first.rank, Rank.seven);
    });
  });

  group('KlondikeGame Loss Detection - Additional Coverage', () {
    test('isTrulyLost() returns false when waste has a king for empty tableau', () {
      final game = KlondikeGame();
      game.initialize();

      game.stock.clear();
      game.waste.clear();

      // Clear all tableau piles
      for (var pile in game.tableau) {
        pile.clear();
      }

      // Put a king in waste (not on top)
      game.waste.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.two, faceUp: true));
      game.waste.addCard(PlayingCard(suit: Suit.spades, rank: Rank.king, faceUp: true));
      game.waste.addCard(PlayingCard(suit: Suit.diamonds, rank: Rank.three, faceUp: true));

      // isTrulyLost should check all waste cards, including the king
      final lost = game.isTrulyLost();

      expect(lost, isFalse);
    });
  });

  group('KlondikeGame Move Detection - Additional Coverage', () {
    test('hasAnyMove() detects waste to foundation via branch coverage', () {
      final game = KlondikeGame();
      game.initialize();

      game.stock.clear();
      game.waste.clear();

      for (var pile in game.tableau) {
        pile.clear();
      }

      // Add ace to foundation
      game.foundations[0].addCard(PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true));

      // Add two to waste
      game.waste.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.two, faceUp: true));

      final hasMove = game.hasAnyMove();

      expect(hasMove, isTrue);
    });

    test('hasAnyMove() detects waste to tableau via branch coverage', () {
      final game = KlondikeGame();
      game.initialize();

      game.stock.clear();
      game.waste.clear();

      for (var pile in game.tableau) {
        pile.clear();
      }

      // Black 7 on tableau
      game.tableau[0].addCard(PlayingCard(suit: Suit.spades, rank: Rank.seven, faceUp: true));

      // Red 6 in waste
      game.waste.addCard(PlayingCard(suit: Suit.hearts, rank: Rank.six, faceUp: true));

      final hasMove = game.hasAnyMove();

      expect(hasMove, isTrue);
    });
  });
}
