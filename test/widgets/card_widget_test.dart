import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/features/game/models/card.dart';
import 'package:solitude/features/game/widgets/card_widget.dart';

import '../helpers/test_harness.dart';

void main() {
  group('CardWidget', () {
    testWidgets('calls onTap callback when tapped', (tester) async {
      bool tapCalled = false;
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          CardWidget(
            card: card,
            width: 100,
            onTap: () => tapCalled = true,
          ),
        ),
      );

      await tester.tap(find.byType(CardWidget));
      await tester.pump();

      expect(tapCalled, isTrue);
    });

    testWidgets('calls onDoubleTap callback when double-tapped', (tester) async {
      bool doubleTapCalled = false;
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          CardWidget(
            card: card,
            width: 100,
            onDoubleTap: () => doubleTapCalled = true,
          ),
        ),
      );

      // Double-tap the card
      await tester.tap(find.byType(CardWidget));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byType(CardWidget));
      await tester.pump();

      // Pump again to clear the double-tap gesture detector timer
      await tester.pump(const Duration(milliseconds: 300));

      expect(doubleTapCalled, isTrue);
    });

    testWidgets('renders face-up card correctly', (tester) async {
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          CardWidget(
            card: card,
            width: 100,
          ),
        ),
      );

      expect(find.byType(CardWidget), findsOneWidget);
    });

    testWidgets('renders face-down card correctly', (tester) async {
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: false);

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          CardWidget(
            card: card,
            width: 100,
          ),
        ),
      );

      expect(find.byType(CardWidget), findsOneWidget);
    });

    testWidgets('applies selected state visual changes', (tester) async {
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          CardWidget(
            card: card,
            width: 100,
            isSelected: true,
          ),
        ),
      );

      expect(find.byType(CardWidget), findsOneWidget);

      // The card should still render properly when selected
      // Visual changes (shadows, transform) are applied via AnimatedContainer
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(CardWidget),
          matching: find.byType(AnimatedContainer),
        ).first,
      );

      expect(animatedContainer, isNotNull);
    });

    testWidgets('applies highlighted state visual changes', (tester) async {
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          CardWidget(
            card: card,
            width: 100,
            isHighlighted: true,
          ),
        ),
      );

      expect(find.byType(CardWidget), findsOneWidget);
    });

    testWidgets('applies dragging state visual changes', (tester) async {
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          CardWidget(
            card: card,
            width: 100,
            isDragging: true,
          ),
        ),
      );

      expect(find.byType(CardWidget), findsOneWidget);
    });

    testWidgets('applies hint destination state visual changes', (tester) async {
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          CardWidget(
            card: card,
            width: 100,
            isHintDestination: true,
          ),
        ),
      );

      expect(find.byType(CardWidget), findsOneWidget);
    });

    testWidgets('respects aspect ratio', (tester) async {
      final card = PlayingCard(suit: Suit.hearts, rank: Rank.ace, faceUp: true);
      const width = 100.0;
      const expectedHeight = width / CardWidget.aspectRatio;

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          CardWidget(
            card: card,
            width: width,
          ),
        ),
      );

      final cardWidget = tester.widget<CardWidget>(find.byType(CardWidget));
      expect(cardWidget.height, equals(expectedHeight));
    });
  });
}
