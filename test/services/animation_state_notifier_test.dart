import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/features/game/services/animation_state_notifier.dart';
import 'package:solitude/features/game/models/card.dart';

void main() {
  group('AnimationStateNotifier', () {
    test('initializes with null values', () {
      final notifier = AnimationStateNotifier();

      expect(notifier.cardAnimationData, isNull);
      expect(notifier.animatingCard, isNull);
    });

    test('startCardAnimation() sets animation data', () {
      final notifier = AnimationStateNotifier();
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);

      notifier.startCardAnimation(
        card: card,
        startPosition: const Offset(0, 0),
        endPosition: const Offset(100, 100),
        cardWidth: 50.0,
      );

      expect(notifier.animatingCard, card);
      expect(notifier.cardAnimationData, isNotNull);
      expect(notifier.cardAnimationData!.card, card);
      expect(notifier.cardAnimationData!.startPosition, const Offset(0, 0));
      expect(notifier.cardAnimationData!.endPosition, const Offset(100, 100));
      expect(notifier.cardAnimationData!.cardWidth, 50.0);
    });

    test('startCardAnimation() notifies listeners', () {
      final notifier = AnimationStateNotifier();
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);
      bool notified = false;
      notifier.addListener(() => notified = true);

      notifier.startCardAnimation(
        card: card,
        startPosition: const Offset(0, 0),
        endPosition: const Offset(100, 100),
        cardWidth: 50.0,
      );

      expect(notified, isTrue);
    });

    test('clearCardAnimation() clears animation data', () {
      final notifier = AnimationStateNotifier();
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);

      notifier.startCardAnimation(
        card: card,
        startPosition: const Offset(0, 0),
        endPosition: const Offset(100, 100),
        cardWidth: 50.0,
      );

      expect(notifier.animatingCard, isNotNull);

      notifier.clearCardAnimation();

      expect(notifier.animatingCard, isNull);
      expect(notifier.cardAnimationData, isNull);
    });

    test('clearCardAnimation() notifies listeners', () {
      final notifier = AnimationStateNotifier();
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);

      notifier.startCardAnimation(
        card: card,
        startPosition: const Offset(0, 0),
        endPosition: const Offset(100, 100),
        cardWidth: 50.0,
      );

      bool notified = false;
      notifier.addListener(() => notified = true);

      notifier.clearCardAnimation();

      expect(notified, isTrue);
    });

    test('isCardAnimating() returns true for animating card', () {
      final notifier = AnimationStateNotifier();
      final card1 = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);
      final card2 = PlayingCard(suit: Suit.spades, rank: Rank.king, faceUp: true);

      notifier.startCardAnimation(
        card: card1,
        startPosition: const Offset(0, 0),
        endPosition: const Offset(100, 100),
        cardWidth: 50.0,
      );

      expect(notifier.isCardAnimating(card1), isTrue);
      expect(notifier.isCardAnimating(card2), isFalse);
    });

    test('isCardAnimating() returns false when no animation', () {
      final notifier = AnimationStateNotifier();
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);

      expect(notifier.isCardAnimating(card), isFalse);
    });

    test('can update animation for different card', () {
      final notifier = AnimationStateNotifier();
      final card1 = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);
      final card2 = PlayingCard(suit: Suit.spades, rank: Rank.king, faceUp: true);

      notifier.startCardAnimation(
        card: card1,
        startPosition: const Offset(0, 0),
        endPosition: const Offset(100, 100),
        cardWidth: 50.0,
      );

      expect(notifier.animatingCard, card1);

      notifier.startCardAnimation(
        card: card2,
        startPosition: const Offset(50, 50),
        endPosition: const Offset(150, 150),
        cardWidth: 60.0,
      );

      expect(notifier.animatingCard, card2);
      expect(notifier.cardAnimationData!.startPosition, const Offset(50, 50));
      expect(notifier.cardAnimationData!.cardWidth, 60.0);
    });
  });
}
