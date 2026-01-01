import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/features/settings/models/difficulty.dart';
import 'package:solitude/features/game/models/draw_mode.dart';

void main() {
  group('Difficulty Enum', () {
    test('has three difficulty levels', () {
      expect(Difficulty.values.length, 3);
      expect(Difficulty.values, contains(Difficulty.easy));
      expect(Difficulty.values, contains(Difficulty.medium));
      expect(Difficulty.values, contains(Difficulty.hard));
    });

    test('displayName returns correct strings', () {
      expect(Difficulty.easy.displayName, 'Easy');
      expect(Difficulty.medium.displayName, 'Medium');
      expect(Difficulty.hard.displayName, 'Hard');
    });

    test('shortName returns correct strings', () {
      expect(Difficulty.easy.shortName, 'EASY');
      expect(Difficulty.medium.shortName, 'MED');
      expect(Difficulty.hard.shortName, 'HARD');
    });

    test('drawMode returns correct modes', () {
      expect(Difficulty.easy.drawMode, DrawMode.one);
      expect(Difficulty.medium.drawMode, DrawMode.one);
      expect(Difficulty.hard.drawMode, DrawMode.three);
    });

    test('maxStockRecycles returns correct values', () {
      expect(Difficulty.easy.maxStockRecycles, isNull); // Unlimited
      expect(Difficulty.medium.maxStockRecycles, isNull); // Unlimited
      expect(Difficulty.hard.maxStockRecycles, 2); // 3 passes total
    });

    test('description returns non-empty strings', () {
      expect(Difficulty.easy.description, isNotEmpty);
      expect(Difficulty.medium.description, isNotEmpty);
      expect(Difficulty.hard.description, isNotEmpty);
    });

    test('description contains key information', () {
      expect(Difficulty.easy.description, contains('Draw 1'));
      expect(Difficulty.easy.description, contains('Unlimited'));

      expect(Difficulty.medium.description, contains('Draw 1'));
      expect(Difficulty.medium.description, contains('Unlimited'));

      expect(Difficulty.hard.description, contains('Draw 3'));
      expect(Difficulty.hard.description, contains('3 passes'));
    });

    test('fullDescription returns detailed explanations', () {
      expect(Difficulty.easy.fullDescription, isNotEmpty);
      expect(Difficulty.medium.fullDescription, isNotEmpty);
      expect(Difficulty.hard.fullDescription, isNotEmpty);

      expect(Difficulty.easy.fullDescription.length,
          greaterThan(Difficulty.easy.description.length));
      expect(Difficulty.medium.fullDescription.length,
          greaterThan(Difficulty.medium.description.length));
      expect(Difficulty.hard.fullDescription.length,
          greaterThan(Difficulty.hard.description.length));
    });

    test('fullDescription contains specific details', () {
      expect(Difficulty.easy.fullDescription, contains('1-card'));
      expect(Difficulty.easy.fullDescription, contains('unlimited'));

      expect(Difficulty.medium.fullDescription, contains('1-card'));

      expect(Difficulty.hard.fullDescription, contains('3-card'));
      expect(Difficulty.hard.fullDescription, contains('3 passes'));
    });

    test('color returns valid Color objects', () {
      expect(Difficulty.easy.color, isA<Color>());
      expect(Difficulty.medium.color, isA<Color>());
      expect(Difficulty.hard.color, isA<Color>());
    });

    test('color returns expected colors', () {
      expect(Difficulty.easy.color, Colors.green);
      expect(Difficulty.medium.color, Colors.orange);
      expect(Difficulty.hard.color, Colors.red);
    });

    test('colors are distinct from each other', () {
      expect(Difficulty.easy.color, isNot(Difficulty.medium.color));
      expect(Difficulty.medium.color, isNot(Difficulty.hard.color));
      expect(Difficulty.hard.color, isNot(Difficulty.easy.color));
    });

    test('easy and medium have same drawMode and description', () {
      expect(Difficulty.easy.drawMode, Difficulty.medium.drawMode);
      expect(Difficulty.easy.description, Difficulty.medium.description);
      // But they have different full descriptions
      expect(Difficulty.easy.fullDescription,
          isNot(Difficulty.medium.fullDescription));
    });

    test('hard is the only difficulty with limited recycles', () {
      final unlimited =
          Difficulty.values.where((d) => d.maxStockRecycles == null).toList();
      final limited =
          Difficulty.values.where((d) => d.maxStockRecycles != null).toList();

      expect(unlimited, [Difficulty.easy, Difficulty.medium]);
      expect(limited, [Difficulty.hard]);
    });

    test('hard is the only difficulty with DrawMode.three', () {
      final drawOne =
          Difficulty.values.where((d) => d.drawMode == DrawMode.one).toList();
      final drawThree =
          Difficulty.values.where((d) => d.drawMode == DrawMode.three).toList();

      expect(drawOne, [Difficulty.easy, Difficulty.medium]);
      expect(drawThree, [Difficulty.hard]);
    });
  });

  group('ScoringMode Enum', () {
    test('has three scoring modes', () {
      expect(ScoringMode.values.length, 3);
      expect(ScoringMode.values, contains(ScoringMode.standard));
      expect(ScoringMode.values, contains(ScoringMode.vegas));
      expect(ScoringMode.values, contains(ScoringMode.vegasCumulative));
    });

    test('displayName returns correct strings', () {
      expect(ScoringMode.standard.displayName, 'Standard');
      expect(ScoringMode.vegas.displayName, 'Vegas');
      expect(ScoringMode.vegasCumulative.displayName, 'Vegas Cumulative');
    });

    test('shortName returns correct strings', () {
      expect(ScoringMode.standard.shortName, 'STD');
      expect(ScoringMode.vegas.shortName, 'VEGAS');
      expect(ScoringMode.vegasCumulative.shortName, 'VEGAS+');
    });

    test('vegasGameCost is constant', () {
      expect(ScoringMode.standard.vegasGameCost, -52);
      expect(ScoringMode.vegas.vegasGameCost, -52);
      expect(ScoringMode.vegasCumulative.vegasGameCost, -52);
    });

    test('vegasCardValue is constant', () {
      expect(ScoringMode.standard.vegasCardValue, 5);
      expect(ScoringMode.vegas.vegasCardValue, 5);
      expect(ScoringMode.vegasCumulative.vegasCardValue, 5);
    });

    test('vegas scoring break-even point', () {
      // Need more than 10.4 cards (11 cards) to break even
      final gameCost = ScoringMode.vegas.vegasGameCost;
      final cardValue = ScoringMode.vegas.vegasCardValue;

      expect(gameCost, -52);
      expect(cardValue, 5);

      // 10 cards: -52 + 50 = -2 (loss)
      expect(gameCost + (10 * cardValue), -2);

      // 11 cards: -52 + 55 = +3 (profit)
      expect(gameCost + (11 * cardValue), 3);

      // 52 cards (perfect game): -52 + 260 = +208
      expect(gameCost + (52 * cardValue), 208);
    });

    test('description returns non-empty strings', () {
      expect(ScoringMode.standard.description, isNotEmpty);
      expect(ScoringMode.vegas.description, isNotEmpty);
      expect(ScoringMode.vegasCumulative.description, isNotEmpty);
    });

    test('description contains key information', () {
      expect(ScoringMode.standard.description, contains('time'));
      expect(ScoringMode.standard.description, contains('moves'));

      expect(ScoringMode.vegas.description, contains('\$52'));
      expect(ScoringMode.vegas.description, contains('\$5'));

      expect(ScoringMode.vegasCumulative.description, contains('Bankroll'));
    });

    test('fullDescription returns detailed explanations', () {
      expect(ScoringMode.standard.fullDescription, isNotEmpty);
      expect(ScoringMode.vegas.fullDescription, isNotEmpty);
      expect(ScoringMode.vegasCumulative.fullDescription, isNotEmpty);

      expect(ScoringMode.standard.fullDescription.length,
          greaterThan(ScoringMode.standard.description.length));
      expect(ScoringMode.vegas.fullDescription.length,
          greaterThan(ScoringMode.vegas.description.length));
      expect(ScoringMode.vegasCumulative.fullDescription.length,
          greaterThan(ScoringMode.vegasCumulative.description.length));
    });

    test('fullDescription contains specific details', () {
      expect(ScoringMode.standard.fullDescription, contains('time'));
      expect(ScoringMode.standard.fullDescription, contains('moves'));

      expect(ScoringMode.vegas.fullDescription, contains('\$52'));
      expect(ScoringMode.vegas.fullDescription, contains('\$5'));
      expect(ScoringMode.vegas.fullDescription, contains('11 cards'));

      expect(ScoringMode.vegasCumulative.fullDescription, contains('bankroll'));
    });

    test('all scoring modes have different descriptions', () {
      expect(ScoringMode.standard.description,
          isNot(ScoringMode.vegas.description));
      expect(ScoringMode.standard.description,
          isNot(ScoringMode.vegasCumulative.description));
      expect(ScoringMode.vegas.description,
          isNot(ScoringMode.vegasCumulative.description));

      expect(ScoringMode.standard.fullDescription,
          isNot(ScoringMode.vegas.fullDescription));
      expect(ScoringMode.standard.fullDescription,
          isNot(ScoringMode.vegasCumulative.fullDescription));
      expect(ScoringMode.vegas.fullDescription,
          isNot(ScoringMode.vegasCumulative.fullDescription));
    });

    test('all scoring modes have different displayNames', () {
      expect(ScoringMode.standard.displayName,
          isNot(ScoringMode.vegas.displayName));
      expect(ScoringMode.standard.displayName,
          isNot(ScoringMode.vegasCumulative.displayName));
      expect(ScoringMode.vegas.displayName,
          isNot(ScoringMode.vegasCumulative.displayName));
    });

    test('all scoring modes have different shortNames', () {
      expect(
          ScoringMode.standard.shortName, isNot(ScoringMode.vegas.shortName));
      expect(ScoringMode.standard.shortName,
          isNot(ScoringMode.vegasCumulative.shortName));
      expect(ScoringMode.vegas.shortName,
          isNot(ScoringMode.vegasCumulative.shortName));
    });

    test('vegasGameCost is negative', () {
      expect(ScoringMode.vegas.vegasGameCost, lessThan(0));
    });

    test('vegasCardValue is positive', () {
      expect(ScoringMode.vegas.vegasCardValue, greaterThan(0));
    });
  });

  group('Difficulty and ScoringMode Integration', () {
    test('all difficulties can be used with all scoring modes', () {
      for (final difficulty in Difficulty.values) {
        for (final scoringMode in ScoringMode.values) {
          // Ensure we can access all properties without errors
          expect(difficulty.displayName, isNotEmpty);
          expect(difficulty.drawMode, isNotNull);
          expect(scoringMode.displayName, isNotEmpty);
        }
      }
    });

    test('vegas scoring calculations are consistent', () {
      final gameCost = ScoringMode.vegas.vegasGameCost;
      final cardValue = ScoringMode.vegas.vegasCardValue;

      // Simulate scores for different card counts
      for (int cards = 0; cards <= 52; cards += 10) {
        final score = gameCost + (cards * cardValue);
        expect(score, isA<int>());
      }
    });
  });
}
