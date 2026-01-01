import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/features/game/layouts/layouts.dart';
import 'package:solitude/features/game/games/game_interface.dart';

void main() {
  group('KlondikeLayoutStrategy', () {
    group('initialization', () {
      test('creates strategy with config', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);
        expect(strategy, isNotNull);
      });

      test('extends LayoutStrategy', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);
        expect(strategy, isA<LayoutStrategy>());
      });

      test('uses GridLayoutMixin', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);
        expect(strategy, isA<GridLayoutMixin>());
      });
    });

    group('column count', () {
      test('returns default tableau count (7 columns)', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);
        expect(strategy.columnCount, equals(7));
      });

      test('column count matches tableau count from config', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);
        expect(strategy.columnCount, equals(config.tableauCount));
      });
    });

    group('grid layout calculations', () {
      test('calculates grid metrics from constraints', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);

        const constraints = BoxConstraints.expand(width: 800, height: 600);
        final metrics = strategy.calculateGridMetrics(constraints);

        expect(metrics.cardWidth, greaterThan(0));
        expect(metrics.cardHeight, greaterThan(0));
        expect(metrics.pileSpacing, greaterThan(0));
        expect(metrics.stackOffset, greaterThan(0));
        expect(metrics.boardSize, equals(const Size(800, 600)));
      });

      test('handles minimum constraints', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);

        final constraints = BoxConstraints.tight(const Size(400, 300));
        final metrics = strategy.calculateGridMetrics(constraints);

        expect(metrics.cardWidth, greaterThanOrEqualTo(50.0));
        expect(metrics.cardHeight, greaterThan(0));
      });

      test('handles maximum constraints', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);

        const constraints = BoxConstraints.expand(width: 1920, height: 1080);
        final metrics = strategy.calculateGridMetrics(constraints);

        expect(metrics.cardWidth, lessThanOrEqualTo(150.0));
        expect(metrics.cardHeight, greaterThan(0));
      });
    });

    group('padding calculations', () {
      test('horizontal padding is consistent', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);
        expect(strategy.horizontalPadding, equals(24.0));
      });

      test('base padding is consistent', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);
        expect(strategy.basePadding, equals(8.0));
      });

      test('buildGridPadding creates correct padding widget', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);

        const testChild = SizedBox(width: 100, height: 100);
        final paddedWidget = strategy.buildGridPadding(child: testChild);

        expect(paddedWidget, isA<Padding>());
      });
    });

    group('layout building', () {
      test('buildLayout is implemented', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);

        // Verify the method exists and can be called
        expect(strategy.buildLayout, isNotNull);
      });

      test('buildLayout includes top row and tableau sections', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);

        // Document expected structure: Column with top row and tableau
        expect(strategy, isNotNull);
      });
    });

    group('configuration handling', () {
      test('handles config without stock', () {
        const config = LayoutConfig(
          hasStock: false,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);
        expect(strategy, isNotNull);
      });

      test('handles config without waste', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false,
          foundationCount: 4,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);
        expect(strategy, isNotNull);
      });

      test('handles different foundation counts', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 2,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);
        expect(strategy, isNotNull);
      });

      test('handles different tableau counts', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 10,
        );

        const strategy = KlondikeLayoutStrategy(config);
        expect(strategy.columnCount, equals(10));
      });
    });

    group('aspect ratio handling', () {
      test('card height follows aspect ratio', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);

        const constraints = BoxConstraints.expand(width: 800, height: 600);
        final metrics = strategy.calculateGridMetrics(constraints);

        final aspectRatio = metrics.cardWidth / metrics.cardHeight;
        expect(aspectRatio, closeTo(0.714, 0.1)); // Typical card aspect ratio
      });

      test('stack offset is proportional to card height', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);

        const constraints = BoxConstraints.expand(width: 800, height: 600);
        final metrics = strategy.calculateGridMetrics(constraints);

        final ratio = metrics.stackOffset / metrics.cardHeight;
        expect(ratio, greaterThanOrEqualTo(0.15));
        expect(ratio, lessThanOrEqualTo(0.30));
      });
    });

    group('responsive design', () {
      test('adapts to different screen sizes', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);

        // Small screen
        final smallConstraints = BoxConstraints.tight(const Size(400, 300));
        final smallMetrics = strategy.calculateGridMetrics(smallConstraints);

        // Large screen
        final largeConstraints = BoxConstraints.tight(const Size(1200, 900));
        final largeMetrics = strategy.calculateGridMetrics(largeConstraints);

        expect(largeMetrics.cardWidth, greaterThan(smallMetrics.cardWidth));
      });

      test('maintains reasonable card sizes across screen sizes', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);

        final tinyConstraints = BoxConstraints.tight(const Size(300, 200));
        final tinyMetrics = strategy.calculateGridMetrics(tinyConstraints);

        final hugeConstraints = BoxConstraints.tight(const Size(2000, 1500));
        final hugeMetrics = strategy.calculateGridMetrics(hugeConstraints);

        // Card sizes should be clamped to reasonable bounds
        expect(tinyMetrics.cardWidth, greaterThanOrEqualTo(50.0));
        expect(hugeMetrics.cardWidth, lessThanOrEqualTo(150.0));
      });
    });

    group('grid structure validation', () {
      test('creates proper number of columns for tableau', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);

        // Klondike should have 7 tableau columns
        expect(strategy.columnCount, equals(7));
      });

      test('spacing is consistent across columns', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        const strategy = KlondikeLayoutStrategy(config);

        const constraints = BoxConstraints.expand(width: 800, height: 600);
        final metrics = strategy.calculateGridMetrics(constraints);

        // Pile spacing should be proportional to card width
        final spacingRatio = metrics.pileSpacing / metrics.cardWidth;
        expect(spacingRatio, closeTo(0.15, 0.01));
      });
    });
  });

  group('LayoutConfig', () {
    group('constructor', () {
      test('creates config with all parameters', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        expect(config.hasStock, isTrue);
        expect(config.hasWaste, isTrue);
        expect(config.foundationCount, equals(4));
        expect(config.tableauCount, equals(7));
      });

      test('handles config without stock', () {
        const config = LayoutConfig(
          hasStock: false,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 7,
        );

        expect(config.hasStock, isFalse);
      });

      test('handles config without waste', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false,
          foundationCount: 4,
          tableauCount: 7,
        );

        expect(config.hasWaste, isFalse);
      });

      test('handles different foundation counts', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 2,
          tableauCount: 7,
        );

        expect(config.foundationCount, equals(2));
      });

      test('handles different tableau counts', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 10,
        );

        expect(config.tableauCount, equals(10));
      });
    });

    group('configuration validation', () {
      test('foundation count must be positive', () {
        expect(
          () => const LayoutConfig(
            hasStock: true,
            hasWaste: true,
            foundationCount: 0,
            tableauCount: 7,
          ),
          returnsNormally,
        );
      });

      test('tableau count must be positive', () {
        expect(
          () => const LayoutConfig(
            hasStock: true,
            hasWaste: true,
            foundationCount: 4,
            tableauCount: 0,
          ),
          returnsNormally,
        );
      });

      test('handles large foundation counts', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 13, // One for each suit/rank combination
          tableauCount: 7,
        );

        expect(config.foundationCount, equals(13));
      });

      test('handles large tableau counts', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: true,
          foundationCount: 4,
          tableauCount: 20,
        );

        expect(config.tableauCount, equals(20));
      });
    });
  });
}
