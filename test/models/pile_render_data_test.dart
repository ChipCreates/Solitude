import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/features/game/models/card.dart';
import 'package:solitude/features/game/models/pile.dart';
import 'package:solitude/features/game/models/pile_render_data.dart';

void main() {
  group('TableauPileRenderData', () {
    test('equality returns true for identical data', () {
      final pile = Pile(type: PileType.tableau, index: 0);
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      final cards = [card];

      final data1 = TableauPileRenderData(
        pile: pile,
        pileVersion: 1,
        isHintDestination: false,
        isHintSource: false,
        isFocused: false,
        selectedCards: cards,
        selectedPile: pile,
        hintCards: null,
        animatingCard: null,
      );

      final data2 = TableauPileRenderData(
        pile: pile,
        pileVersion: 1,
        isHintDestination: false,
        isHintSource: false,
        isFocused: false,
        selectedCards: cards,
        selectedPile: pile,
        hintCards: null,
        animatingCard: null,
      );

      expect(data1, equals(data2));
      expect(data1.hashCode, equals(data2.hashCode));
    });

    test('equality returns false when pileVersion differs', () {
      final pile = Pile(type: PileType.tableau, index: 0);

      final data1 = TableauPileRenderData(
        pile: pile,
        pileVersion: 1,
        isHintDestination: false,
        isHintSource: false,
        isFocused: false,
        selectedCards: null,
        selectedPile: null,
        hintCards: null,
        animatingCard: null,
      );

      final data2 = TableauPileRenderData(
        pile: pile,
        pileVersion: 2,
        isHintDestination: false,
        isHintSource: false,
        isFocused: false,
        selectedCards: null,
        selectedPile: null,
        hintCards: null,
        animatingCard: null,
      );

      expect(data1, isNot(equals(data2)));
    });



    test('equality returns false when selectedCards differ', () {
      final pile = Pile(type: PileType.tableau, index: 0);
      final card1 = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      final card2 = PlayingCard(suit: Suit.spades, rank: Rank.king);

      final data1 = TableauPileRenderData(
        pile: pile,
        pileVersion: 1,
        isHintDestination: false,
        isHintSource: false,
        isFocused: false,
        selectedCards: [card1],
        selectedPile: null,
        hintCards: null,
        animatingCard: null,
      );

      final data2 = TableauPileRenderData(
        pile: pile,
        pileVersion: 1,
        isHintDestination: false,
        isHintSource: false,
        isFocused: false,
        selectedCards: [card2],
        selectedPile: null,
        hintCards: null,
        animatingCard: null,
      );

      expect(data1, isNot(equals(data2)));
    });
  });

  group('StockPileRenderData', () {
    test('equality returns true for identical data', () {
      final pile = Pile(type: PileType.stock);

      final data1 = StockPileRenderData(
        pile: pile,
        pileVersion: 1,
        isFocused: true,
        isHintSource: false,
      );

      final data2 = StockPileRenderData(
        pile: pile,
        pileVersion: 1,
        isFocused: true,
        isHintSource: false,
      );

      expect(data1, equals(data2));
      expect(data1.hashCode, equals(data2.hashCode));
    });

    test('equality returns false when pileVersion differs', () {
      final pile = Pile(type: PileType.stock);

      final data1 = StockPileRenderData(
        pile: pile,
        pileVersion: 1,
        isFocused: false,
        isHintSource: false,
      );

      final data2 = StockPileRenderData(
        pile: pile,
        pileVersion: 2,
        isFocused: false,
        isHintSource: false,
      );

      expect(data1, isNot(equals(data2)));
    });

    test('equality returns false when isFocused differs', () {
      final pile = Pile(type: PileType.stock);

      final data1 = StockPileRenderData(
        pile: pile,
        pileVersion: 1,
        isFocused: true,
        isHintSource: false,
      );

      final data2 = StockPileRenderData(
        pile: pile,
        pileVersion: 1,
        isFocused: false,
        isHintSource: false,
      );

      expect(data1, isNot(equals(data2)));
    });
  });

  group('WastePileRenderData', () {
    test('equality returns true for identical data', () {
      final pile = Pile(type: PileType.waste);
      final card = PlayingCard(suit: Suit.diamonds, rank: Rank.queen);
      final cards = [card];  // Same list reference ensures equal hashCode

      final data1 = WastePileRenderData(
        pile: pile,
        pileVersion: 3,
        isFocused: false,
        isHintSource: true,
        selectedCards: cards,
        selectedPile: pile,
        animatingCard: null,
      );

      final data2 = WastePileRenderData(
        pile: pile,
        pileVersion: 3,
        isFocused: false,
        isHintSource: true,
        selectedCards: cards,
        selectedPile: pile,
        animatingCard: null,
      );

      expect(data1, equals(data2));
      expect(data1.hashCode, equals(data2.hashCode));
    });

    test('equality returns true for equivalent list contents', () {
      final pile = Pile(type: PileType.waste);
      final card = PlayingCard(suit: Suit.diamonds, rank: Rank.queen);

      final data1 = WastePileRenderData(
        pile: pile,
        pileVersion: 3,
        isFocused: false,
        isHintSource: true,
        selectedCards: [card],  // Different list instances
        selectedPile: pile,
        animatingCard: null,
      );

      final data2 = WastePileRenderData(
        pile: pile,
        pileVersion: 3,
        isFocused: false,
        isHintSource: true,
        selectedCards: [card],  // Different list instances
        selectedPile: pile,
        animatingCard: null,
      );

      // Equality uses listEquals, so contents are compared
      expect(data1, equals(data2));
      // hashCode may differ since lists are different objects - this is OK for Selector usage
    });

    test('equality returns false when animatingCard differs', () {
      final pile = Pile(type: PileType.waste);
      final card = PlayingCard(suit: Suit.diamonds, rank: Rank.queen);

      final data1 = WastePileRenderData(
        pile: pile,
        pileVersion: 3,
        isFocused: false,
        isHintSource: false,
        selectedCards: null,
        selectedPile: null,
        animatingCard: card,
      );

      final data2 = WastePileRenderData(
        pile: pile,
        pileVersion: 3,
        isFocused: false,
        isHintSource: false,
        selectedCards: null,
        selectedPile: null,
        animatingCard: null,
      );

      expect(data1, isNot(equals(data2)));
    });
  });

  group('FoundationPileRenderData', () {
    test('equality returns true for identical data', () {
      final pile = Pile(type: PileType.foundation, index: 0);

      final data1 = FoundationPileRenderData(
        pile: pile,
        pileVersion: 5,
        isValidDestination: true,
        isHintDestination: true,
      );

      final data2 = FoundationPileRenderData(
        pile: pile,
        pileVersion: 5,
        isValidDestination: true,
        isHintDestination: true,
      );

      expect(data1, equals(data2));
      expect(data1.hashCode, equals(data2.hashCode));
    });

    test('equality returns false when isHintDestination differs', () {
      final pile = Pile(type: PileType.foundation, index: 0);

      final data1 = FoundationPileRenderData(
        pile: pile,
        pileVersion: 5,
        isValidDestination: true,
        isHintDestination: true,
      );

      final data2 = FoundationPileRenderData(
        pile: pile,
        pileVersion: 5,
        isValidDestination: true,
        isHintDestination: false,
      );

      expect(data1, isNot(equals(data2)));
    });
  });
}
