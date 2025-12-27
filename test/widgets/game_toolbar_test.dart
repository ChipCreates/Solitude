import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/widgets/game_toolbar.dart';

import '../helpers/test_harness.dart';
import '../helpers/mocks.dart';

void main() {
  group('GameToolbar', () {
    testWidgets('renders menu button', (tester) async {
      final controller = TestHarness.createMockController();

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          GameToolbar(
            controller: controller,
            onMenuPressed: () {},
            onNewGame: () {},
          ),
          controller: controller,
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('renders undo button', (tester) async {
      final controller = TestHarness.createMockController();

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          GameToolbar(
            controller: controller,
            onMenuPressed: () {},
            onNewGame: () {},
          ),
          controller: controller,
        ),
      );

      expect(find.byIcon(Icons.undo), findsOneWidget);
    });

    testWidgets('renders new game button', (tester) async {
      final controller = TestHarness.createMockController();

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          GameToolbar(
            controller: controller,
            onMenuPressed: () {},
            onNewGame: () {},
          ),
          controller: controller,
        ),
      );

      expect(find.byIcon(Icons.add_box), findsOneWidget);
    });

    testWidgets('renders help button', (tester) async {
      final controller = TestHarness.createMockController();

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          GameToolbar(
            controller: controller,
            onMenuPressed: () {},
            onNewGame: () {},
          ),
          controller: controller,
        ),
      );

      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('renders stats button when callback provided', (tester) async {
      final controller = TestHarness.createMockController();

      // Set a larger view size to accommodate all toolbar buttons
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          GameToolbar(
            controller: controller,
            onMenuPressed: () {},
            onNewGame: () {},
            onStatsPressed: () {},
          ),
          controller: controller,
        ),
      );

      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
    });

    testWidgets('does not render stats button when callback is null', (tester) async {
      final controller = TestHarness.createMockController();

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          GameToolbar(
            controller: controller,
            onMenuPressed: () {},
            onNewGame: () {},
            onStatsPressed: null,
          ),
          controller: controller,
        ),
      );

      expect(find.byIcon(Icons.bar_chart), findsNothing);
    });

    testWidgets('calls onMenuPressed when menu button tapped', (tester) async {
      final controller = TestHarness.createMockController();
      bool wasPressed = false;

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          GameToolbar(
            controller: controller,
            onMenuPressed: () => wasPressed = true,
            onNewGame: () {},
          ),
          controller: controller,
        ),
      );

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(wasPressed, isTrue);
    });

    testWidgets('calls onNewGame when new game button tapped', (tester) async {
      final controller = TestHarness.createMockController();
      bool wasPressed = false;

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          GameToolbar(
            controller: controller,
            onMenuPressed: () {},
            onNewGame: () => wasPressed = true,
          ),
          controller: controller,
        ),
      );

      await tester.tap(find.byIcon(Icons.add_box));
      await tester.pumpAndSettle();

      expect(wasPressed, isTrue);
    });

    testWidgets('displays move count', (tester) async {
      final controller = TestHarness.createMockController();

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          GameToolbar(
            controller: controller,
            onMenuPressed: () {},
            onNewGame: () {},
          ),
          controller: controller,
        ),
      );

      // Initially 0 moves
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('displays timer at 00:00 initially', (tester) async {
      final controller = TestHarness.createMockController();

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          GameToolbar(
            controller: controller,
            onMenuPressed: () {},
            onNewGame: () {},
          ),
          controller: controller,
        ),
      );

      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('shows autoplay button when autoplay is enabled in settings', (tester) async {
      final settings = MockSettingsProvider(autoplay: true);
      final controller = TestHarness.createMockController(settings: settings);

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          GameToolbar(
            controller: controller,
            onMenuPressed: () {},
            onNewGame: () {},
          ),
          controller: controller,
          settings: settings,
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('hides autoplay button when autoplay is disabled in settings', (tester) async {
      final settings = MockSettingsProvider(autoplay: false);
      final controller = TestHarness.createMockController(settings: settings);

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          GameToolbar(
            controller: controller,
            onMenuPressed: () {},
            onNewGame: () {},
          ),
          controller: controller,
          settings: settings,
        ),
      );

      // Should not find play_arrow (autoplay button) but still find fiber_new (new game)
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('undo button calls controller.undo when canUndo is true', (tester) async {
      final controller = TestHarness.createMockController();

      // Make a move so undo is available - use game directly to avoid starting timers
      controller.game.tapStock();

      expect(controller.canUndo, isTrue);
      final moveCountBefore = controller.moveCount;

      await tester.pumpWidget(
        TestHarness.buildTestWidget(
          GameToolbar(
            controller: controller,
            onMenuPressed: () {},
            onNewGame: () {},
          ),
          controller: controller,
        ),
      );

      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();

      // After undo, the move count should decrease
      expect(controller.moveCount, lessThan(moveCountBefore));

      // Clean up the controller to stop any timers
      controller.dispose();
    });
  });
}
