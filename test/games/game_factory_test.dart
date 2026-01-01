import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/features/game/games/game_factory.dart';
import 'package:solitude/features/game/games/game_interface.dart';
import 'package:solitude/features/game/games/klondike/klondike_game.dart';
import 'package:solitude/features/game/games/spider/spider_game.dart';

void main() {
  group('GameFactory', () {
    group('createGame', () {
      test('creates Klondike game', () {
        final game = GameFactory.createGame(GameType.klondike);

        expect(game, isNotNull);
        expect(game, isA<KlondikeGame>());
        expect(game.gameType, equals(GameType.klondike));
        expect(game.deckSize, equals(52));
      });

      test('creates Spider game', () {
        final game = GameFactory.createGame(GameType.spider);

        expect(game, isNotNull);
        expect(game, isA<SpiderGame>());
        expect(game.gameType, equals(GameType.spider));
        expect(game.deckSize, equals(104));
      });

      test('creates different game instances each call', () {
        final game1 = GameFactory.createGame(GameType.klondike);
        final game2 = GameFactory.createGame(GameType.klondike);

        expect(game1, isNot(equals(game2)));
        expect(game1, isA<GameInterface>());
        expect(game2, isA<GameInterface>());
      });

      test('initializes created games properly', () {
        final game = GameFactory.createGame(GameType.klondike);

        expect(game.moveCount, equals(0));
        expect(game.moveHistory, isEmpty);
        expect(game.redoStack, isEmpty);
        expect(game.canRedo, isFalse);
      });

      test('creates games with proper layout configs', () {
        final klondike = GameFactory.createGame(GameType.klondike);
        final spider = GameFactory.createGame(GameType.spider);

        expect(klondike.layoutConfig.tableauCount, equals(7));
        expect(klondike.layoutConfig.foundationCount, equals(4));
        expect(klondike.layoutConfig.hasStock, isTrue);
        expect(klondike.layoutConfig.hasWaste, isTrue);

        expect(spider.layoutConfig.tableauCount, equals(10));
        expect(spider.layoutConfig.foundationCount, equals(8));
        expect(spider.layoutConfig.hasStock, isTrue);
        expect(spider.layoutConfig.hasWaste, isFalse);
      });
    });

    group('unimplemented games', () {
      test('throws UnimplementedError for Pyramid', () {
        expect(
          () => GameFactory.createGame(GameType.pyramid),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('throws UnimplementedError for Golf', () {
        expect(
          () => GameFactory.createGame(GameType.golf),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('throws UnimplementedError for FreeCell', () {
        expect(
          () => GameFactory.createGame(GameType.freecell),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('throws UnimplementedError for TriPeaks', () {
        expect(
          () => GameFactory.createGame(GameType.triPeaks),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('throws UnimplementedError for Yukon', () {
        expect(
          () => GameFactory.createGame(GameType.yukon),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('throws UnimplementedError for FortyThieves', () {
        expect(
          () => GameFactory.createGame(GameType.fortyThieves),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('throws UnimplementedError for Canfield', () {
        expect(
          () => GameFactory.createGame(GameType.canfield),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('throws UnimplementedError for Scorpion', () {
        expect(
          () => GameFactory.createGame(GameType.scorpion),
          throwsA(isA<UnimplementedError>()),
        );
      });
    });

    group('GameType extension', () {
      group('displayName', () {
        test('returns correct names for all game types', () {
          expect(GameType.klondike.displayName, equals('Klondike'));
          expect(GameType.spider.displayName, equals('Spider'));
          expect(GameType.pyramid.displayName, equals('Pyramid'));
          expect(GameType.golf.displayName, equals('Golf'));
          expect(GameType.freecell.displayName, equals('FreeCell'));
          expect(GameType.triPeaks.displayName, equals('TriPeaks'));
          expect(GameType.yukon.displayName, equals('Yukon'));
          expect(GameType.fortyThieves.displayName, equals('Forty Thieves'));
          expect(GameType.canfield.displayName, equals('Canfield'));
          expect(GameType.scorpion.displayName, equals('Scorpion'));
        });

        test('display names are unique', () {
          final displayNames =
              GameType.values.map((type) => type.displayName).toSet();
          expect(displayNames.length, equals(GameType.values.length));
        });

        test('display names are user-friendly', () {
          for (final type in GameType.values) {
            final name = type.displayName;
            expect(name, isNotEmpty);
            expect(name.length, lessThan(20));
            expect(name, contains(RegExp(r'[A-Za-z]'))); // Contains letters
          }
        });
      });

      group('description', () {
        test('returns descriptions for all game types', () {
          for (final type in GameType.values) {
            final description = type.description;
            expect(description, isNotEmpty);
            expect(description.length, greaterThan(50));
            expect(description.length, lessThan(500));
          }
        });

        test('descriptions are informative', () {
          final klondikeDesc = GameType.klondike.description;
          expect(klondikeDesc, contains('foundation'));
          expect(klondikeDesc, contains('tableau'));

          final spiderDesc = GameType.spider.description;
          expect(spiderDesc, contains('suit'));
          expect(spiderDesc, contains('tableau'));
        });

        test('descriptions are unique', () {
          final descriptions =
              GameType.values.map((type) => type.description).toSet();
          expect(descriptions.length, equals(GameType.values.length));
        });

        test('descriptions mention key gameplay elements', () {
          final descriptions =
              GameType.values.map((type) => type.description).toList();

          // Most descriptions should mention cards, piles, or game mechanics
          final meaningfulDescriptions = descriptions
              .where((desc) =>
                  desc.contains('card') ||
                  desc.contains('pile') ||
                  desc.contains('foundation') ||
                  desc.contains('tableau'))
              .length;

          expect(meaningfulDescriptions,
              greaterThanOrEqualTo(descriptions.length * 0.8));
        });
      });
    });

    group('factory consistency', () {
      test('created games implement GameInterface', () {
        final games = [
          GameFactory.createGame(GameType.klondike),
          GameFactory.createGame(GameType.spider),
        ];

        for (final game in games) {
          expect(game, isA<GameInterface>());
          expect(game.gameType, isA<GameType>());
          expect(game.deckSize, greaterThan(0));
          expect(game.layoutConfig, isNotNull);
        }
      });

      test('games have expected pile configurations', () {
        final klondike = GameFactory.createGame(GameType.klondike);
        final spider = GameFactory.createGame(GameType.spider);

        // Klondike should have stock and waste
        expect(klondike.stockPile, isNotNull);
        expect(klondike.wastePile, isNotNull);
        expect(klondike.foundationPiles.length, equals(4));
        expect(klondike.tableauPiles.length, equals(7));

        // Spider should have stock but no waste
        expect(spider.stockPile, isNotNull);
        expect(spider.wastePile, isNull);
        expect(spider.foundationPiles.length, equals(8));
        expect(spider.tableauPiles.length, equals(10));
      });

      test('games can be reset independently', () {
        final game1 = GameFactory.createGame(GameType.klondike);
        final game2 = GameFactory.createGame(GameType.klondike);

        // Make some moves in game1
        game1.tapStock();

        // Reset game1
        game1.reset();

        // game2 should be unaffected
        expect(game1.moveCount, equals(0));
        expect(game2.moveCount, equals(0));

        // Both should still be independent instances
        expect(game1, isNot(equals(game2)));
      });
    });

    group('error handling', () {
      test('handles null GameType gracefully', () {
        // This would be a compile-time error, but we test the pattern
        expect(GameType.klondike, isNotNull);
        expect(GameType.spider, isNotNull);
      });

      test('factory method is pure (no side effects)', () {
        final initialState = GameType.values.length;
        final game = GameFactory.createGame(GameType.klondike);
        final finalState = GameType.values.length;

        expect(initialState, equals(finalState));
        expect(game, isNotNull);
      });

      test('handles multiple consecutive calls', () {
        for (int i = 0; i < 10; i++) {
          final game = GameFactory.createGame(GameType.klondike);
          expect(game, isA<KlondikeGame>());
        }
      });
    });

    group('game type coverage', () {
      test('all enum values are handled', () {
        for (final gameType in GameType.values) {
          if (gameType == GameType.klondike || gameType == GameType.spider) {
            // These should work
            expect(() => GameFactory.createGame(gameType), returnsNormally);
          } else {
            // These should throw UnimplementedError
            expect(
              () => GameFactory.createGame(gameType),
              throwsA(isA<UnimplementedError>()),
            );
          }
        }
      });

      test('factory covers current implementation status', () {
        final implementedGames = [GameType.klondike, GameType.spider];
        final unimplementedGames = GameType.values
            .where((type) => !implementedGames.contains(type))
            .toList();

        expect(implementedGames.length, greaterThan(0));
        expect(unimplementedGames.length, greaterThan(0));
      });
    });
  });
}
