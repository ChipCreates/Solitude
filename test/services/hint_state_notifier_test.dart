import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/features/game/services/hint_state_notifier.dart';
import 'package:solitude/features/game/models/card.dart';
import 'package:solitude/features/game/models/pile.dart';

void main() {
  group('HintStateNotifier', () {
    test('initializes with null values', () {
      final notifier = HintStateNotifier();

      expect(notifier.sourcePile, isNull);
      expect(notifier.cards, isNull);
      expect(notifier.destinationPile, isNull);
      expect(notifier.isActive, isFalse);
    });

    test('setHint() sets all hint data', () {
      final notifier = HintStateNotifier();
      final sourcePile = Pile(type: PileType.tableau, index: 0);
      final destPile = Pile(type: PileType.foundation, index: 0);
      final cards = [PlayingCard(suit: Suit.hearts, rank: Rank.ace)];

      notifier.setHint(
        sourcePile: sourcePile,
        cards: cards,
        destinationPile: destPile,
      );

      expect(notifier.sourcePile, equals(sourcePile));
      expect(notifier.cards, equals(cards));
      expect(notifier.destinationPile, equals(destPile));
      expect(notifier.isActive, isTrue);
    });

    test('setHint() notifies listeners', () {
      final notifier = HintStateNotifier();
      final sourcePile = Pile(type: PileType.tableau, index: 0);
      final destPile = Pile(type: PileType.foundation, index: 0);

      int notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      notifier.setHint(
        sourcePile: sourcePile,
        cards: null,
        destinationPile: destPile,
      );

      expect(notifyCount, equals(1));
    });

    test('clear() clears all hint data', () {
      final notifier = HintStateNotifier();
      final sourcePile = Pile(type: PileType.tableau, index: 0);
      final destPile = Pile(type: PileType.foundation, index: 0);
      final cards = [PlayingCard(suit: Suit.hearts, rank: Rank.ace)];

      notifier.setHint(
        sourcePile: sourcePile,
        cards: cards,
        destinationPile: destPile,
      );

      notifier.clear();

      expect(notifier.sourcePile, isNull);
      expect(notifier.cards, isNull);
      expect(notifier.destinationPile, isNull);
      expect(notifier.isActive, isFalse);
    });

    test('clear() notifies listeners when there was active hint', () {
      final notifier = HintStateNotifier();
      final sourcePile = Pile(type: PileType.tableau, index: 0);
      final destPile = Pile(type: PileType.foundation, index: 0);

      notifier.setHint(
        sourcePile: sourcePile,
        cards: null,
        destinationPile: destPile,
      );

      int notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      notifier.clear();

      expect(notifyCount, equals(1));
    });

    test('clear() does not notify listeners when already cleared', () {
      final notifier = HintStateNotifier();

      int notifyCount = 0;
      notifier.addListener(() => notifyCount++);

      notifier.clear();

      expect(notifyCount, equals(0));
    });

    test('isSourcePile() returns true for source pile', () {
      final notifier = HintStateNotifier();
      final sourcePile = Pile(type: PileType.tableau, index: 0);
      final destPile = Pile(type: PileType.foundation, index: 0);
      final otherPile = Pile(type: PileType.tableau, index: 1);

      notifier.setHint(
        sourcePile: sourcePile,
        cards: null,
        destinationPile: destPile,
      );

      expect(notifier.isSourcePile(sourcePile), isTrue);
      expect(notifier.isSourcePile(destPile), isFalse);
      expect(notifier.isSourcePile(otherPile), isFalse);
    });

    test('isDestinationPile() returns true for destination pile', () {
      final notifier = HintStateNotifier();
      final sourcePile = Pile(type: PileType.tableau, index: 0);
      final destPile = Pile(type: PileType.foundation, index: 0);
      final otherPile = Pile(type: PileType.tableau, index: 1);

      notifier.setHint(
        sourcePile: sourcePile,
        cards: null,
        destinationPile: destPile,
      );

      expect(notifier.isDestinationPile(destPile), isTrue);
      expect(notifier.isDestinationPile(sourcePile), isFalse);
      expect(notifier.isDestinationPile(otherPile), isFalse);
    });

    test('isHintCard() returns true for hint cards', () {
      final notifier = HintStateNotifier();
      final sourcePile = Pile(type: PileType.tableau, index: 0);
      final destPile = Pile(type: PileType.foundation, index: 0);
      final hintCard = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      final otherCard = PlayingCard(suit: Suit.spades, rank: Rank.king);

      notifier.setHint(
        sourcePile: sourcePile,
        cards: [hintCard],
        destinationPile: destPile,
      );

      expect(notifier.isHintCard(hintCard), isTrue);
      expect(notifier.isHintCard(otherCard), isFalse);
    });

    test('isHintCard() returns false when no hint cards', () {
      final notifier = HintStateNotifier();
      final sourcePile = Pile(type: PileType.tableau, index: 0);
      final destPile = Pile(type: PileType.foundation, index: 0);
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace);

      notifier.setHint(
        sourcePile: sourcePile,
        cards: null,
        destinationPile: destPile,
      );

      expect(notifier.isHintCard(card), isFalse);
    });
  });
}
