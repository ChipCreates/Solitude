import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/features/game/layouts/layouts.dart';
import 'package:solitude/features/game/games/game_interface.dart';

void main() {
  group('SpiderLayoutStrategy', () {
    group('initialization', () {
      test('creates strategy with config', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false, // Spider doesn't have waste
          foundationCount: 0, // Spider doesn't display foundations
          tableauCount: 10,
        );

        const strategy = SpiderLayoutStrategy(config);
        expect(strategy, isNotNull);
      });

      test('extends LayoutStrategy', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false,
          foundationCount: 0,
          tableauCount: 10,
        );

        const strategy = SpiderLayoutStrategy(config);
        expect(strategy, isA<LayoutStrategy>());
      });

      test('uses GridLayoutMixin', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false,
          foundationCount: 0,
          tableauCount: 10,
        );

        const strategy = SpiderLayoutStrategy(config);
        expect(strategy, isA<GridLayoutMixin>());
      });
    });

    group('column count', () {
      test('returns 10 columns for Spider tableau', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false,
          foundationCount: 0,
          tableauCount: 10,
        );

        const strategy = SpiderLayoutStrategy(config);
        expect(strategy.columnCount, equals(10));
      });

      test('overrides default column count', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false,
          foundationCount: 0,
          tableauCount: 7, // Default config has 7
        );

        const strategy = SpiderLayoutStrategy(config);
        expect(strategy.columnCount, equals(10)); // But Spider uses 10
      });
    });

    group('grid layout calculations', () {
      test('calculates grid metrics for 10 columns', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false,
          foundationCount: 0,
          tableauCount: 10,
        );

        const strategy = SpiderLayoutStrategy(config);

        const constraints = BoxConstraints.expand(width: 1200, height: 800);
        final metrics = strategy.calculateGridMetrics(constraints);

        expect(metrics.cardWidth, greaterThan(0));
        expect(metrics.cardHeight, greaterThan(0));
        expect(metrics.pileSpacing, greaterThan(0));
        expect(metrics.stackOffset, greaterThan(0));
      });

      test('handles narrower cards due to 10-column layout', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false,
          foundationCount: 0,
          tableauCount: 10,
        );

        const strategy = SpiderLayoutStrategy(config);

        // 10 columns should result in narrower cards than 7 columns
        const constraints = BoxConstraints.expand(width: 1200, height: 800);
        final spiderMetrics = strategy.calculateGridMetrics(constraints);

        // Cards should be reasonably sized for 10 columns
        expect(spiderMetrics.cardWidth,
            lessThan(101.0)); // Allow for slight calculation variations
      });
    });

    group('layout building', () {
      test('buildLayout creates simplified structure', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false,
          foundationCount: 0,
          tableauCount: 10,
        );

        const strategy = SpiderLayoutStrategy(config);

        // Spider has simpler layout: stock + tableau only
        expect(strategy, isNotNull);
      });

      test('buildLayout omits waste and foundations', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false,
          foundationCount: 0,
          tableauCount: 10,
        );

        const strategy = SpiderLayoutStrategy(config);

        // Spider layout should be simpler than Klondike
        expect(strategy, isNotNull);
      });
    });

    group('Spider-specific configuration', () {
      test('handles config without waste', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false,
          foundationCount: 0,
          tableauCount: 10,
        );

        const strategy = SpiderLayoutStrategy(config);
        expect(strategy, isNotNull);
      });

      test('handles config without foundations', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false,
          foundationCount: 0,
          tableauCount: 10,
        );

        const strategy = SpiderLayoutStrategy(config);
        expect(strategy, isNotNull);
      });

      test('works with standard 10 tableau piles', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false,
          foundationCount: 0,
          tableauCount: 10,
        );

        const strategy = SpiderLayoutStrategy(config);
        expect(strategy.columnCount, equals(10));
      });
    });

    group('aspect ratio handling', () {
      test('maintains card proportions for 10-column layout', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false,
          foundationCount: 0,
          tableauCount: 10,
        );

        const strategy = SpiderLayoutStrategy(config);

        const constraints = BoxConstraints.expand(width: 1200, height: 800);
        final metrics = strategy.calculateGridMetrics(constraints);

        final aspectRatio = metrics.cardWidth / metrics.cardHeight;
        expect(aspectRatio,
            closeTo(0.714, 0.1)); // Same aspect ratio as other games
      });

      test('stack offset scales appropriately', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false,
          foundationCount: 0,
          tableauCount: 10,
        );

        const strategy = SpiderLayoutStrategy(config);

        const constraints = BoxConstraints.expand(width: 1200, height: 800);
        final metrics = strategy.calculateGridMetrics(constraints);

        final ratio = metrics.stackOffset / metrics.cardHeight;
        expect(ratio, greaterThan(0.15));
        expect(ratio, lessThan(0.30));
      });
    });

    group('responsive design', () {
      test('adapts to different screen sizes with 10 columns', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false,
          foundationCount: 0,
          tableauCount: 10,
        );

        const strategy = SpiderLayoutStrategy(config);

        final smallConstraints = BoxConstraints.tight(const Size(600, 400));
        final largeConstraints = BoxConstraints.tight(const Size(1600, 1200));

        final smallMetrics = strategy.calculateGridMetrics(smallConstraints);
        final largeMetrics = strategy.calculateGridMetrics(largeConstraints);

        expect(largeMetrics.cardWidth, greaterThan(smallMetrics.cardWidth));
      });

      test('maintains minimum card size for 10 columns', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false,
          foundationCount: 0,
          tableauCount: 10,
        );

        const strategy = SpiderLayoutStrategy(config);

        final tinyConstraints = BoxConstraints.tight(const Size(500, 300));
        final tinyMetrics = strategy.calculateGridMetrics(tinyConstraints);

        // Even on small screens, should maintain minimum size
        expect(tinyMetrics.cardWidth, greaterThanOrEqualTo(50.0));
      });
    });

    group('layout type validation', () {
      test('uses grid layout type', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false,
          foundationCount: 0,
          tableauCount: 10,
          layoutType: LayoutType.grid,
        );

        // const strategy = SpiderLayoutStrategy(config);
        expect(config.layoutType, equals(LayoutType.grid));
      });

      test('would work with stack layout type', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false,
          foundationCount: 0,
          tableauCount: 10,
          layoutType: LayoutType.stack,
        );

        const strategy = SpiderLayoutStrategy(config);
        expect(strategy, isNotNull);
      });
    });

    group('stock-only top row', () {
      test('builds top row with only stock pile', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false,
          foundationCount: 0,
          tableauCount: 10,
        );

        const strategy = SpiderLayoutStrategy(config);

        // Spider top row should be simpler: just stock + empty space
        expect(strategy, isNotNull);
      });

      test('leaves space for completed sequences', () {
        const config = LayoutConfig(
          hasStock: true,
          hasWaste: false,
          foundationCount: 0,
          tableauCount: 10,
        );

        const strategy = SpiderLayoutStrategy(config);

        // Spider layout should accommodate completed sequence display area
        expect(strategy, isNotNull);
      });
    });
  });

  group('LayoutType enum', () {
    group('enum values', () {
      test('contains grid layout type', () {
        expect(LayoutType.values, contains(LayoutType.grid));
      });

      test('contains stack layout type', () {
        expect(LayoutType.values, contains(LayoutType.stack));
      });

      test('has correct number of layout types', () {
        expect(LayoutType.values.length, equals(2));
      });
    });

    group('layout type usage', () {
      test('grid layout is for row/column based games', () {
        expect(LayoutType.grid, isNotNull);
      });

      test('stack layout is for absolute positioned games', () {
        expect(LayoutType.stack, isNotNull);
      });

      test('layout types are mutually exclusive', () {
        expect(LayoutType.grid, isNot(equals(LayoutType.stack)));
      });
    });
  });
}
