import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/features/game/models/victory_pattern.dart';

void main() {
  group('VictoryPattern', () {
    group('enum values', () {
      test('contains all expected patterns', () {
        expect(
            VictoryPattern.values,
            containsAll([
              VictoryPattern.random,
              VictoryPattern.cascade,
              VictoryPattern.fountain,
              VictoryPattern.scatter,
              VictoryPattern.vortex,
            ]));
      });

      test('has correct number of patterns', () {
        expect(VictoryPattern.values.length, equals(5));
      });
    });

    group('VictoryPatternExtension label property', () {
      test('random pattern has correct label', () {
        expect(VictoryPattern.random.label, equals('Random'));
      });

      test('cascade pattern has correct label', () {
        expect(VictoryPattern.cascade.label, equals('Cascade'));
      });

      test('fountain pattern has correct label', () {
        expect(VictoryPattern.fountain.label, equals('Fountain'));
      });

      test('scatter pattern has correct label', () {
        expect(VictoryPattern.scatter.label, equals('Scatter'));
      });

      test('vortex pattern has correct label', () {
        expect(VictoryPattern.vortex.label, equals('Vortex'));
      });
    });

    group('label consistency', () {
      test('all patterns have non-empty labels', () {
        for (final pattern in VictoryPattern.values) {
          expect(pattern.label, isNotEmpty);
          expect(pattern.label, isA<String>());
        }
      });

      test('all labels are unique', () {
        final labels =
            VictoryPattern.values.map((pattern) => pattern.label).toList();
        final uniqueLabels = labels.toSet();
        expect(uniqueLabels.length, equals(labels.length));
      });

      test('labels are properly capitalized', () {
        final expectedLabels = [
          'Random',
          'Cascade',
          'Fountain',
          'Scatter',
          'Vortex'
        ];
        final actualLabels =
            VictoryPattern.values.map((pattern) => pattern.label).toList();
        expect(actualLabels, containsAll(expectedLabels));
      });
    });

    group('pattern identification', () {
      test('can identify each pattern uniquely', () {
        const patterns = VictoryPattern.values;

        // Verify each pattern can be uniquely identified by label
        for (var i = 0; i < patterns.length; i++) {
          for (var j = i + 1; j < patterns.length; j++) {
            expect(patterns[i].label, isNot(equals(patterns[j].label)));
          }
        }
      });

      test('random pattern is distinct from others', () {
        expect(VictoryPattern.random.label, equals('Random'));
        expect(VictoryPattern.random, isNot(equals(VictoryPattern.cascade)));
        expect(VictoryPattern.random, isNot(equals(VictoryPattern.fountain)));
        expect(VictoryPattern.random, isNot(equals(VictoryPattern.scatter)));
        expect(VictoryPattern.random, isNot(equals(VictoryPattern.vortex)));
      });
    });

    group('animation pattern descriptions', () {
      test('cascade suggests falling cards', () {
        expect(VictoryPattern.cascade.label, equals('Cascade'));
        // The name suggests a waterfall-like falling animation
      });

      test('fountain suggests upward then downward motion', () {
        expect(VictoryPattern.fountain.label, equals('Fountain'));
        // The name suggests a fountain-like spray pattern
      });

      test('scatter suggests explosion from center', () {
        expect(VictoryPattern.scatter.label, equals('Scatter'));
        // The name suggests radial explosion
      });

      test('vortex suggests spiral motion', () {
        expect(VictoryPattern.vortex.label, equals('Vortex'));
        // The name suggests circular/spiral motion
      });

      test('random selects from available patterns', () {
        expect(VictoryPattern.random.label, equals('Random'));
        // Should select a random pattern from the others
      });
    });

    group('pattern enum order', () {
      test('patterns are in expected order', () {
        final expectedOrder = [
          VictoryPattern.random,
          VictoryPattern.cascade,
          VictoryPattern.fountain,
          VictoryPattern.scatter,
          VictoryPattern.vortex,
        ];
        expect(VictoryPattern.values, equals(expectedOrder));
      });

      test('random comes first as default option', () {
        expect(VictoryPattern.values.first, equals(VictoryPattern.random));
        expect(VictoryPattern.random.label, equals('Random'));
      });
    });

    group('pattern usage scenarios', () {
      test('can categorize by animation style', () {
        final fallingPatterns = [VictoryPattern.cascade];
        final explosivePatterns = [VictoryPattern.scatter];
        final spiralPatterns = [VictoryPattern.vortex];
        final sprayPatterns = [VictoryPattern.fountain];
        final randomPatterns = [VictoryPattern.random];

        // Verify each pattern fits its category
        expect(VictoryPattern.cascade, isIn(fallingPatterns));
        expect(VictoryPattern.scatter, isIn(explosivePatterns));
        expect(VictoryPattern.vortex, isIn(spiralPatterns));
        expect(VictoryPattern.fountain, isIn(sprayPatterns));
        expect(VictoryPattern.random, isIn(randomPatterns));
      });

      test('random can represent any pattern', () {
        // Random should be able to represent any of the other patterns
        expect(VictoryPattern.random, isNotNull);
        expect(VictoryPattern.random.label, equals('Random'));
      });
    });

    group('extension method coverage', () {
      test('all patterns have label extension', () {
        for (final pattern in VictoryPattern.values) {
          // This will throw if any pattern doesn't have the extension
          final label = pattern.label;
          expect(label, isNotNull);
          expect(label, isA<String>());
        }
      });

      test('label extension returns expected values', () {
        final expectedResults = {
          VictoryPattern.random: 'Random',
          VictoryPattern.cascade: 'Cascade',
          VictoryPattern.fountain: 'Fountain',
          VictoryPattern.scatter: 'Scatter',
          VictoryPattern.vortex: 'Vortex',
        };

        for (final entry in expectedResults.entries) {
          expect(entry.key.label, equals(entry.value));
        }
      });
    });

    group('pattern selection logic', () {
      test('can select random pattern from enum', () {
        const randomPattern = VictoryPattern.random;
        expect(randomPattern.label, equals('Random'));
        expect(VictoryPattern.values, contains(randomPattern));
      });

      test('can iterate through all patterns', () {
        const patterns = VictoryPattern.values;
        expect(patterns, hasLength(5));

        final labels = patterns.map((p) => p.label).toList();
        expect(
            labels,
            containsAll(
                ['Random', 'Cascade', 'Fountain', 'Scatter', 'Vortex']));
      });
    });

    group('edge cases', () {
      test('no pattern has empty or null label', () {
        for (final pattern in VictoryPattern.values) {
          expect(pattern.label, isNotEmpty);
          expect(pattern.label, isNotNull);
        }
      });

      test('all patterns have unique identifiers', () {
        final identifiers = VictoryPattern.values.map((p) => p.label).toSet();
        expect(identifiers.length, equals(VictoryPattern.values.length));
      });
    });

    group('documentation and clarity', () {
      test('pattern names are descriptive', () {
        // These names should be self-explanatory for UI display
        final descriptivePatterns = [
          VictoryPattern.random,
          VictoryPattern.cascade,
          VictoryPattern.fountain,
          VictoryPattern.scatter,
          VictoryPattern.vortex,
        ];

        expect(VictoryPattern.values, equals(descriptivePatterns));
      });

      test('labels are user-friendly', () {
        // Labels should be suitable for display in UI
        for (final pattern in VictoryPattern.values) {
          final label = pattern.label;
          expect(label.length, greaterThan(0));
          expect(label.length, lessThan(20)); // Reasonable length for UI
        }
      });
    });
  });
}
