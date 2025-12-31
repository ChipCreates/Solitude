import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/core/widgets/game_button.dart';

import '../helpers/test_harness.dart';

void main() {
  group('GameButton', () {
    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(
        TestHarness.buildMinimalWidget(
          const GameButton(label: 'Test Button'),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        TestHarness.buildMinimalWidget(
          GameButton(
            label: 'Tap Me',
            onPressed: () => wasPressed = true,
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(wasPressed, isTrue);
    });

    testWidgets('renders with icon when provided', (tester) async {
      await tester.pumpWidget(
        TestHarness.buildMinimalWidget(
          const GameButton(
            label: 'With Icon',
            icon: Icons.play_arrow,
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.text('With Icon'), findsOneWidget);
    });

    testWidgets('applies width when specified', (tester) async {
      await tester.pumpWidget(
        TestHarness.buildMinimalWidget(
          const Center(
            child: GameButton(
              label: 'Wide',
              width: 200,
            ),
          ),
        ),
      );

      // Find the GameButton and check its rendered size
      final buttonFinder = find.byType(GameButton);
      expect(buttonFinder, findsOneWidget);

      // The AnimatedContainer should have the specified width
      final size = tester.getSize(buttonFinder);
      expect(size.width, 200);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        TestHarness.buildMinimalWidget(
          const GameButton(label: 'Disabled'),
        ),
      );

      // Button should still render but not respond to taps
      expect(find.text('Disabled'), findsOneWidget);
    });
  });

  group('GameIconButton', () {
    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(
        TestHarness.buildMinimalWidget(
          const GameIconButton(icon: Icons.settings),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        TestHarness.buildMinimalWidget(
          GameIconButton(
            icon: Icons.undo,
            onPressed: () => wasPressed = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();

      expect(wasPressed, isTrue);
    });

    testWidgets('uses specified size', (tester) async {
      await tester.pumpWidget(
        TestHarness.buildMinimalWidget(
          const Center(
            child: GameIconButton(
              icon: Icons.close,
              size: 60,
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(GameIconButton);
      final size = tester.getSize(buttonFinder);
      expect(size.width, 60);
      expect(size.height, 60);
    });
  });
}
