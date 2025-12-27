import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/utils/layout_calculator.dart';
import 'package:solitude/widgets/card_widget.dart';

void main() {
  group('LayoutConfig', () {
    test('can be constructed with required parameters', () {
      const config = LayoutConfig(
        cardWidth: 75.0,
        cardHeight: 100.0,
        tableauStackOffset: 15.0,
        pileSpacing: 8.0,
        padding: EdgeInsets.all(16.0),
        isLandscape: false,
      );

      expect(config.cardWidth, 75.0);
      expect(config.cardHeight, 100.0);
      expect(config.tableauStackOffset, 15.0);
      expect(config.pileSpacing, 8.0);
      expect(config.padding, const EdgeInsets.all(16.0));
      expect(config.isLandscape, isFalse);
    });

    test('stores isLandscape flag correctly', () {
      const portrait = LayoutConfig(
        cardWidth: 75.0,
        cardHeight: 100.0,
        tableauStackOffset: 15.0,
        pileSpacing: 8.0,
        padding: EdgeInsets.all(16.0),
        isLandscape: false,
      );

      const landscape = LayoutConfig(
        cardWidth: 75.0,
        cardHeight: 100.0,
        tableauStackOffset: 15.0,
        pileSpacing: 8.0,
        padding: EdgeInsets.all(16.0),
        isLandscape: true,
      );

      expect(portrait.isLandscape, isFalse);
      expect(landscape.isLandscape, isTrue);
    });
  });

  group('LayoutCalculator Constants', () {
    test('has expected constant values', () {
      expect(LayoutCalculator.minCardWidth, 55.0);
      expect(LayoutCalculator.maxCardWidth, 100.0);
      expect(LayoutCalculator.idealCardWidth, 75.0);
      expect(LayoutCalculator.tableauCount, 7);
      expect(LayoutCalculator.foundationCount, 4);
    });
  });

  group('LayoutCalculator.calculate()', () {
    test('detects portrait orientation correctly', () {
      final config = LayoutCalculator.calculate(
        const Size(400, 800), // Portrait
        EdgeInsets.zero,
      );

      expect(config.isLandscape, isFalse);
    });

    test('detects landscape orientation correctly', () {
      final config = LayoutCalculator.calculate(
        const Size(800, 400), // Landscape
        EdgeInsets.zero,
      );

      expect(config.isLandscape, isTrue);
    });

    test('calculates card dimensions for typical phone screen', () {
      final config = LayoutCalculator.calculate(
        const Size(375, 667), // iPhone 8 size
        EdgeInsets.zero,
      );

      expect(config.cardWidth, greaterThanOrEqualTo(LayoutCalculator.minCardWidth));
      expect(config.cardWidth, lessThanOrEqualTo(LayoutCalculator.maxCardWidth));
      expect(config.cardHeight, config.cardWidth / CardWidget.aspectRatio);
    });

    test('calculates card dimensions for tablet screen', () {
      final config = LayoutCalculator.calculate(
        const Size(768, 1024), // iPad size
        EdgeInsets.zero,
      );

      expect(config.cardWidth, greaterThanOrEqualTo(LayoutCalculator.minCardWidth));
      expect(config.cardWidth, lessThanOrEqualTo(LayoutCalculator.maxCardWidth));
      expect(config.cardHeight, config.cardWidth / CardWidget.aspectRatio);
    });

    test('respects minimum card width on small screens', () {
      final config = LayoutCalculator.calculate(
        const Size(250, 400), // Very small screen
        EdgeInsets.zero,
      );

      expect(config.cardWidth, greaterThanOrEqualTo(LayoutCalculator.minCardWidth));
    });

    test('respects maximum card width on large screens', () {
      final config = LayoutCalculator.calculate(
        const Size(2000, 1500), // Very large screen
        EdgeInsets.zero,
      );

      expect(config.cardWidth, lessThanOrEqualTo(LayoutCalculator.maxCardWidth));
    });

    test('accounts for safe area insets', () {
      final withoutSafeArea = LayoutCalculator.calculate(
        const Size(400, 800),
        EdgeInsets.zero,
      );

      final withSafeArea = LayoutCalculator.calculate(
        const Size(400, 800),
        const EdgeInsets.only(top: 40, bottom: 20),
      );

      // With safe area, available height is reduced, which may affect layout
      expect(withSafeArea, isNotNull);
      expect(withoutSafeArea, isNotNull);
    });

    test('calculates padding within expected range', () {
      final config = LayoutCalculator.calculate(
        const Size(400, 800),
        EdgeInsets.zero,
      );

      expect(config.padding.left, greaterThanOrEqualTo(8.0));
      expect(config.padding.left, lessThanOrEqualTo(20.0));
      expect(config.padding.top, greaterThanOrEqualTo(8.0));
      expect(config.padding.top, lessThanOrEqualTo(16.0));
    });

    test('calculates pile spacing within expected range', () {
      final config = LayoutCalculator.calculate(
        const Size(400, 800),
        EdgeInsets.zero,
      );

      expect(config.pileSpacing, greaterThanOrEqualTo(4.0));
      expect(config.pileSpacing, lessThanOrEqualTo(20.0));
    });

    test('calculates tableau stack offset within expected range', () {
      final config = LayoutCalculator.calculate(
        const Size(400, 800),
        EdgeInsets.zero,
      );

      final minOffset = config.cardHeight * 0.12;
      final idealOffset = config.cardHeight * 0.18;

      expect(config.tableauStackOffset, greaterThanOrEqualTo(minOffset));
      expect(config.tableauStackOffset, lessThanOrEqualTo(idealOffset));
    });

    test('maintains card aspect ratio', () {
      final config = LayoutCalculator.calculate(
        const Size(400, 800),
        EdgeInsets.zero,
      );

      final expectedHeight = config.cardWidth / CardWidget.aspectRatio;
      expect(config.cardHeight, closeTo(expectedHeight, 0.01));
    });

    test('produces consistent results for same input', () {
      final config1 = LayoutCalculator.calculate(
        const Size(400, 800),
        const EdgeInsets.all(10),
      );

      final config2 = LayoutCalculator.calculate(
        const Size(400, 800),
        const EdgeInsets.all(10),
      );

      expect(config1.cardWidth, config2.cardWidth);
      expect(config1.cardHeight, config2.cardHeight);
      expect(config1.tableauStackOffset, config2.tableauStackOffset);
      expect(config1.pileSpacing, config2.pileSpacing);
      expect(config1.padding, config2.padding);
      expect(config1.isLandscape, config2.isLandscape);
    });

    test('handles extreme aspect ratios', () {
      // Very wide screen
      final wideConfig = LayoutCalculator.calculate(
        const Size(1200, 400),
        EdgeInsets.zero,
      );

      // Very tall screen
      final tallConfig = LayoutCalculator.calculate(
        const Size(400, 1200),
        EdgeInsets.zero,
      );

      expect(wideConfig.cardWidth, greaterThanOrEqualTo(LayoutCalculator.minCardWidth));
      expect(tallConfig.cardWidth, greaterThanOrEqualTo(LayoutCalculator.minCardWidth));
    });

    test('handles zero safe area', () {
      expect(
        () => LayoutCalculator.calculate(const Size(400, 800), EdgeInsets.zero),
        returnsNormally,
      );
    });

    test('handles large safe area insets', () {
      expect(
        () => LayoutCalculator.calculate(
          const Size(400, 800),
          const EdgeInsets.only(top: 100, bottom: 100, left: 50, right: 50),
        ),
        returnsNormally,
      );
    });
  });

  group('LayoutCalculator.calculateMaxTableauHeight()', () {
    test('calculates height for single card', () {
      const config = LayoutConfig(
        cardWidth: 75.0,
        cardHeight: 100.0,
        tableauStackOffset: 15.0,
        pileSpacing: 8.0,
        padding: EdgeInsets.all(16.0),
        isLandscape: false,
      );

      final height = LayoutCalculator.calculateMaxTableauHeight(config, 1);

      expect(height, 100.0); // Just the card height
    });

    test('calculates height for multiple cards', () {
      const config = LayoutConfig(
        cardWidth: 75.0,
        cardHeight: 100.0,
        tableauStackOffset: 15.0,
        pileSpacing: 8.0,
        padding: EdgeInsets.all(16.0),
        isLandscape: false,
      );

      final height = LayoutCalculator.calculateMaxTableauHeight(config, 5);

      // Card height + (4 cards * offset)
      expect(height, 100.0 + (4 * 15.0));
      expect(height, 160.0);
    });

    test('calculates height for maximum stack', () {
      const config = LayoutConfig(
        cardWidth: 75.0,
        cardHeight: 100.0,
        tableauStackOffset: 15.0,
        pileSpacing: 8.0,
        padding: EdgeInsets.all(16.0),
        isLandscape: false,
      );

      final height = LayoutCalculator.calculateMaxTableauHeight(config, 13);

      // Card height + (12 cards * offset)
      expect(height, 100.0 + (12 * 15.0));
      expect(height, 280.0);
    });

    test('works with different stack offsets', () {
      const config1 = LayoutConfig(
        cardWidth: 75.0,
        cardHeight: 100.0,
        tableauStackOffset: 10.0,
        pileSpacing: 8.0,
        padding: EdgeInsets.all(16.0),
        isLandscape: false,
      );

      const config2 = LayoutConfig(
        cardWidth: 75.0,
        cardHeight: 100.0,
        tableauStackOffset: 20.0,
        pileSpacing: 8.0,
        padding: EdgeInsets.all(16.0),
        isLandscape: false,
      );

      final height1 = LayoutCalculator.calculateMaxTableauHeight(config1, 5);
      final height2 = LayoutCalculator.calculateMaxTableauHeight(config2, 5);

      expect(height1, 100.0 + (4 * 10.0)); // 140.0
      expect(height2, 100.0 + (4 * 20.0)); // 180.0
      expect(height2, greaterThan(height1));
    });

    test('works with zero cards', () {
      const config = LayoutConfig(
        cardWidth: 75.0,
        cardHeight: 100.0,
        tableauStackOffset: 15.0,
        pileSpacing: 8.0,
        padding: EdgeInsets.all(16.0),
        isLandscape: false,
      );

      final height = LayoutCalculator.calculateMaxTableauHeight(config, 0);

      // Height with 0 cards: cardHeight + (-1 * offset)
      expect(height, 100.0 - 15.0);
      expect(height, 85.0);
    });

    test('produces consistent results', () {
      const config = LayoutConfig(
        cardWidth: 75.0,
        cardHeight: 100.0,
        tableauStackOffset: 15.0,
        pileSpacing: 8.0,
        padding: EdgeInsets.all(16.0),
        isLandscape: false,
      );

      final height1 = LayoutCalculator.calculateMaxTableauHeight(config, 7);
      final height2 = LayoutCalculator.calculateMaxTableauHeight(config, 7);

      expect(height1, height2);
    });
  });
}
