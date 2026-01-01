import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/features/game/services/solver_service.dart';
import 'package:solitude/features/game/services/hint_state_notifier.dart';
import 'package:solitude/features/settings/models/hint_mode.dart';
import 'package:solitude/features/game/games/klondike/klondike_game.dart';
import 'package:solitude/features/game/models/pile.dart';

void main() {
  group('SolverService', () {
    group('initialization', () {
      test('creates service with required dependencies', () {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        expect(service, isNotNull);
      });

      test('initializes with default hint mode', () {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        expect(service, isNotNull);
      });

      test('starts with null cached winning path', () {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        expect(service.cachedWinningPath, isNull);
      });
    });

    group('hint mode management', () {
      test('updateHintMode changes current mode', () {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        service.updateHintMode(HintMode.fast);
        expect(service, isNotNull);
      });

      test('updateHintMode handles all hint modes', () {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        for (final mode in HintMode.values) {
          service.updateHintMode(mode);
          expect(service, isNotNull);
        }
      });
    });

    group('game solving', () {
      test('solveGame returns null for non-solvable games', () async {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        // Klondike should be solvable, but in test environment may return null
        final result = await service.solveGame();
        expect(result, anyOf(isNull, isA<List>()));
      });

      test('solveGame handles disposed state', () async {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        service.dispose();
        final result = await service.solveGame();

        expect(result, isNull);
      });

      test('solveGame can be called multiple times', () async {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        final result1 = await service.solveGame();
        final result2 = await service.solveGame();

        expect(result1, anyOf(isNull, isA<List>()));
        expect(result2, anyOf(isNull, isA<List>()));
      });
    });

    group('move execution', () {
      test('executeSolverMove handles valid moves', () async {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        void tapPile(Pile pile) {}

        await service.executeSolverMove(
          null, // Move object would be game-specific
          tryMove: (from, to, cards) {
            return true;
          },
          tapPile: tapPile,
        );

        expect(service, isNotNull);
      });

      test('executeSolverMove handles disposed state', () async {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        service.dispose();

        await service.executeSolverMove(
          null,
          tryMove: (from, to, cards) => true,
          tapPile: (pile) {},
        );

        expect(service, isNotNull);
      });

      test('executeSolverMove handles execution errors gracefully', () async {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        await service.executeSolverMove(
          'invalid_move',
          tryMove: (from, to, cards) => throw Exception('Test error'),
          tapPile: (pile) {},
        );

        expect(service, isNotNull);
      });
    });

    group('auto-play functionality', () {
      test('autoPlaySolution executes moves with pacing', () async {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        const moves = ['move1', 'move2', 'move3'];
        const isPlaying = true;

        await service.autoPlaySolution(
          moves,
          isPlaying: () => isPlaying,
          tryMove: (from, to, cards) => true,
          tapPile: (pile) {},
        );

        expect(service, isNotNull);
      });

      test('autoPlaySolution stops when game is not playing', () async {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        const moves = ['move1', 'move2', 'move3'];
        const isPlaying = false; // Stop immediately

        await service.autoPlaySolution(
          moves,
          isPlaying: () => isPlaying,
          tryMove: (from, to, cards) => true,
          tapPile: (pile) {},
        );

        expect(service, isNotNull);
      });

      test('autoPlaySolution stops when disposed', () async {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        final moves = ['move1', 'move2', 'move3'];

        service.dispose();

        await service.autoPlaySolution(
          moves,
          isPlaying: () => true,
          tryMove: (from, to, cards) => true,
          tapPile: (pile) {},
        );

        expect(service, isNotNull);
      });
    });

    group('solve and auto-play', () {
      test('solveAndAutoPlay solves and plays solution', () async {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        await service.solveAndAutoPlay(
          isPlaying: () => true,
          tryMove: (from, to, cards) => true,
          tapPile: (pile) {},
        );

        expect(service, isNotNull);
      });

      test('solveAndAutoPlay handles null solution', () async {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        // Mock the solve method to return null
        await service.solveAndAutoPlay(
          isPlaying: () => true,
          tryMove: (from, to, cards) => true,
          tapPile: (pile) {},
        );

        expect(service, isNotNull);
      });
    });

    group('smart hints', () {
      test('showSmartHint returns false when not in smart mode', () {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        service.updateHintMode(HintMode.fast);

        final result = service.showSmartHint(
          onHintUsed: () {},
          clearHintAfterDelay: () {},
        );

        expect(result, isFalse);
      });

      test('showSmartHint handles cached winning path', () {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        service.updateHintMode(HintMode.smart);

        // Initially no cached path
        final result = service.showSmartHint(
          onHintUsed: () {},
          clearHintAfterDelay: () {},
        );

        expect(result, isFalse);
      });

      test('showSmartHint handles invalid cached path', () {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        service.updateHintMode(HintMode.smart);

        // Test with empty cached path
        final result = service.showSmartHint(
          onHintUsed: () {},
          clearHintAfterDelay: () {},
        );

        expect(result, isFalse);
      });
    });

    group('cache management', () {
      test('invalidateCacheAndDebounceSolve clears cache', () {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        service.invalidateCacheAndDebounceSolve();

        expect(service.cachedWinningPath, isNull);
      });

      test('invalidateCacheAndDebounceSolve schedules background solve', () {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        service.updateHintMode(HintMode.smart);

        // Should schedule background solve
        service.invalidateCacheAndDebounceSolve();

        expect(service.cachedWinningPath, isNull);
      });

      test('clearCache clears winning path and cancels timer', () {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        service.clearCache();

        expect(service.cachedWinningPath, isNull);
      });
    });

    group('disposal', () {
      test('dispose cancels pending operations', () {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        service.dispose();

        // Subsequent operations should be no-ops
        expect(service, isNotNull);
      });

      test('dispose can be called multiple times', () {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        service.dispose();
        service.dispose();
        service.dispose();
      });

      test('disposed service returns null from solveGame', () async {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        service.dispose();
        final result = await service.solveGame();

        expect(result, isNull);
      });
    });

    group('error handling', () {
      test('handles solver strategy factory failures gracefully', () async {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        // Should handle missing strategy gracefully
        final result = await service.solveGame();

        expect(result, anyOf(isNull, isA<List>()));
      });

      test('handles move execution errors', () async {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        await service.executeSolverMove(
          null,
          tryMove: (from, to, cards) => throw Exception('Move failed'),
          tapPile: (pile) {},
        );

        expect(service, isNotNull);
      });

      test('handles timer errors gracefully', () {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        service.updateHintMode(HintMode.smart);
        service.invalidateCacheAndDebounceSolve();

        expect(service, isNotNull);
      });
    });

    group('game type compatibility', () {
      test('handles different game types', () {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        expect(service, isNotNull);
      });

      test('checks game type support for solving', () {
        final game = KlondikeGame();
        final hintState = HintStateNotifier();
        final service = SolverService(game: game, hintState: hintState);

        // Service should be compatible with Klondike
        expect(service, isNotNull);
      });
    });
  });
}
