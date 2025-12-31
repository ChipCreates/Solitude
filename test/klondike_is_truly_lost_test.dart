import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/features/game/games/klondike/klondike_game.dart';
import 'package:solitude/features/game/models/card.dart';
import 'package:solitude/features/game/models/pile.dart';

void main() {
  test('fresh game is not lost', () {
    final game = KlondikeGame();
    game.initialize();
    expect(game.isTrulyLost(), isFalse);
  });

  test('empty stock + no moves + no face-down reveal => lost', () {
    final game = KlondikeGame();

    // make all piles empty
    game.stock = Pile(type: PileType.stock);
    game.waste = Pile(type: PileType.waste);
    game.foundations = List.generate(4, (i) => Pile(type: PileType.foundation));
    game.tableau = List.generate(7, (i) => Pile(type: PileType.tableau));

    // Place a few face-up cards that cannot move
    final c1 = PlayingCard(suit: Suit.hearts, rank: Rank.five, faceUp: true);
    final c2 = PlayingCard(suit: Suit.clubs, rank: Rank.two, faceUp: true);
    game.tableau[0].addCard(c1);
    game.tableau[1].addCard(c2);

    expect(game.isTrulyLost(), isTrue);
  });

  test('hidden card that could be revealed by moving a sequence prevents loss', () {
    final game = KlondikeGame();

    // empty stock and waste
    game.stock = Pile(type: PileType.stock);
    game.waste = Pile(type: PileType.waste);

    // tableau with a face-down card under a face-up movable sequence
    game.tableau = List.generate(7, (i) => Pile(type: PileType.tableau));
    // pile 0: face-down card under a black 6
    final hidden = PlayingCard(suit: Suit.spades, rank: Rank.four, faceUp: false);
    final movable = PlayingCard(suit: Suit.hearts, rank: Rank.five, faceUp: true);
    game.tableau[0].addCard(hidden);
    game.tableau[0].addCard(movable);

    // pile 1: a black 6 so movable can go there and reveal the hidden card
    final dest = PlayingCard(suit: Suit.spades, rank: Rank.six, faceUp: true);
    game.tableau[1].addCard(dest);

    expect(game.isTrulyLost(), isFalse);
  });
}
