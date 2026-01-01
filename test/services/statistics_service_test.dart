import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:solitude/features/statistics/services/statistics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Directory? tempDir;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir!.path);
  });

  tearDown(() {
    Hive.close();
  });

  group('StatisticsService Initialization', () {
    test('creates with default statistics', () {
      final service = StatisticsService();

      expect(service.statistics.gamesPlayed, 0);
      expect(service.statistics.gamesWon, 0);
      expect(service.statistics.gamesLost, 0);
      expect(service.statistics.currentStreak, 0);
      expect(service.statistics.bestStreak, 0);
      expect(service.statistics.bestTime, isNull);
      expect(service.statistics.fewestMoves, isNull);
    });

    test('loads statistics from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'gamesPlayed': 10,
        'gamesWon': 6,
        'gamesLost': 4,
        'currentStreak': 2,
        'bestStreak': 5,
        'bestTime': 120000, // 2 minutes in ms
        'fewestMoves': 85,
      });

      final service = StatisticsService();
      await service.loadStatistics();

      expect(service.statistics.gamesPlayed, 10);
      expect(service.statistics.gamesWon, 6);
      expect(service.statistics.gamesLost, 4);
      expect(service.statistics.currentStreak, 2);
      expect(service.statistics.bestStreak, 5);
      expect(service.statistics.bestTime, const Duration(milliseconds: 120000));
      expect(service.statistics.fewestMoves, 85);
    });
  });

  group('StatisticsService Game Recording', () {
    test('recordGameStarted() increments games played', () async {
      final service = StatisticsService();

      await service.recordGameStarted();

      expect(service.statistics.gamesPlayed, 1);

      await service.recordGameStarted();

      expect(service.statistics.gamesPlayed, 2);
    });

    test('recordGameStarted() persists to storage', () async {
      final service = StatisticsService();

      await service.recordGameStarted();

      final box = await Hive.openBox('statistics');
      // Keys are now prefixed with game type (default is klondike)
      expect(box.get('klondike_gamesPlayed'), 1);
    });

    test('recordGameStarted() notifies listeners', () async {
      final service = StatisticsService();
      bool notified = false;
      service.addListener(() => notified = true);

      await service.recordGameStarted();

      expect(notified, isTrue);
    });
  });

  group('StatisticsService Win Recording', () {
    test('recordWin() increments games won', () async {
      final service = StatisticsService();
      await service.recordGameStarted();

      await service.recordWin(time: const Duration(seconds: 120), moves: 100);

      expect(service.statistics.gamesWon, 1);
    });

    test('recordWin() increments current streak', () async {
      final service = StatisticsService();
      await service.recordGameStarted();

      await service.recordWin(time: const Duration(seconds: 120), moves: 100);

      expect(service.statistics.currentStreak, 1);

      await service.recordWin(time: const Duration(seconds: 100), moves: 90);

      expect(service.statistics.currentStreak, 2);
    });

    test('recordWin() updates best streak', () async {
      final service = StatisticsService();
      await service.recordGameStarted();

      await service.recordWin(time: const Duration(seconds: 120), moves: 100);
      expect(service.statistics.bestStreak, 1);

      await service.recordWin(time: const Duration(seconds: 100), moves: 90);
      expect(service.statistics.bestStreak, 2);

      await service.recordWin(time: const Duration(seconds: 110), moves: 95);
      expect(service.statistics.bestStreak, 3);
    });

    test('recordWin() updates best time when faster', () async {
      final service = StatisticsService();
      await service.recordGameStarted();

      await service.recordWin(time: const Duration(seconds: 120), moves: 100);
      expect(service.statistics.bestTime, const Duration(seconds: 120));

      await service.recordWin(time: const Duration(seconds: 90), moves: 95);
      expect(service.statistics.bestTime, const Duration(seconds: 90));

      // Slower time shouldn't update
      await service.recordWin(time: const Duration(seconds: 150), moves: 80);
      expect(service.statistics.bestTime, const Duration(seconds: 90));
    });

    test('recordWin() updates fewest moves when lower', () async {
      final service = StatisticsService();
      await service.recordGameStarted();

      await service.recordWin(time: const Duration(seconds: 120), moves: 100);
      expect(service.statistics.fewestMoves, 100);

      await service.recordWin(time: const Duration(seconds: 90), moves: 85);
      expect(service.statistics.fewestMoves, 85);

      // Higher move count shouldn't update
      await service.recordWin(time: const Duration(seconds: 80), moves: 120);
      expect(service.statistics.fewestMoves, 85);
    });

    test('recordWin() persists to storage', () async {
      final service = StatisticsService();
      await service.recordGameStarted();

      await service.recordWin(time: const Duration(seconds: 120), moves: 100);

      final box = await Hive.openBox('statistics');
      // Keys are now prefixed with game type (default is klondike)
      expect(box.get('klondike_gamesWon'), 1);
      expect(box.get('klondike_currentStreak'), 1);
      expect(box.get('klondike_bestStreak'), 1);
      expect(box.get('klondike_bestTime'), 120000);
      expect(box.get('klondike_fewestMoves'), 100);
    });

    test('recordWin() notifies listeners', () async {
      final service = StatisticsService();
      await service.recordGameStarted();
      bool notified = false;
      service.addListener(() => notified = true);

      await service.recordWin(time: const Duration(seconds: 120), moves: 100);

      expect(notified, isTrue);
    });
  });

  group('StatisticsService Loss Recording', () {
    test('recordLoss() increments games lost', () async {
      final service = StatisticsService();
      await service.recordGameStarted();

      await service.recordLoss();

      expect(service.statistics.gamesLost, 1);

      await service.recordLoss();

      expect(service.statistics.gamesLost, 2);
    });

    test('recordLoss() resets current streak', () async {
      final service = StatisticsService();
      await service.recordGameStarted();

      // Build up a streak
      await service.recordWin(time: const Duration(seconds: 120), moves: 100);
      await service.recordWin(time: const Duration(seconds: 100), moves: 90);
      expect(service.statistics.currentStreak, 2);

      // Loss resets streak
      await service.recordLoss();
      expect(service.statistics.currentStreak, 0);
    });

    test('recordLoss() does not affect best streak', () async {
      final service = StatisticsService();
      await service.recordGameStarted();

      await service.recordWin(time: const Duration(seconds: 120), moves: 100);
      await service.recordWin(time: const Duration(seconds: 100), moves: 90);
      expect(service.statistics.bestStreak, 2);

      await service.recordLoss();
      expect(service.statistics.bestStreak, 2); // Unchanged
    });

    test('recordLoss() persists to storage', () async {
      final service = StatisticsService();
      await service.recordGameStarted();

      await service.recordLoss();

      final box = await Hive.openBox('statistics');
      // Keys are now prefixed with game type (default is klondike)
      expect(box.get('klondike_gamesLost'), 1);
      expect(box.get('klondike_currentStreak'), 0);
    });

    test('recordLoss() notifies listeners', () async {
      final service = StatisticsService();
      await service.recordGameStarted();
      bool notified = false;
      service.addListener(() => notified = true);

      await service.recordLoss();

      expect(notified, isTrue);
    });
  });

  group('StatisticsService Vegas Scoring', () {
    test('recordVegasScore() updates cumulative score', () async {
      final service = StatisticsService();

      await service.recordVegasScore(50);
      expect(service.statistics.vegasCumulativeScore, 50);

      await service.recordVegasScore(30);
      expect(service.statistics.vegasCumulativeScore, 80);

      // Negative scores (losses) should also be recorded
      await service.recordVegasScore(-20);
      expect(service.statistics.vegasCumulativeScore, 60);
    });

    test('recordVegasScore() updates high score', () async {
      final service = StatisticsService();

      await service.recordVegasScore(50);
      expect(service.statistics.vegasHighScore, 50);

      await service.recordVegasScore(75);
      expect(service.statistics.vegasHighScore, 75);

      // Lower score shouldn't update high score
      await service.recordVegasScore(40);
      expect(service.statistics.vegasHighScore, 75);
    });

    test('recordVegasScore() persists to storage', () async {
      final service = StatisticsService();

      await service.recordVegasScore(50);

      final box = await Hive.openBox('statistics');
      // Keys are now prefixed with game type (default is klondike)
      expect(box.get('klondike_vegasCumulativeScore'), 50);
      expect(box.get('klondike_vegasHighScore'), 50);
    });

    test('recordVegasScore() notifies listeners', () async {
      final service = StatisticsService();
      bool notified = false;
      service.addListener(() => notified = true);

      await service.recordVegasScore(50);

      expect(notified, isTrue);
    });
  });

  group('StatisticsService Win Percentage', () {
    test('winPercentage calculates correctly', () async {
      final service = StatisticsService();

      // No games played yet
      expect(service.statistics.winPercentage, 0.0);

      await service.recordGameStarted();
      await service.recordWin(time: const Duration(seconds: 120), moves: 100);

      // 1 win out of 1 game
      expect(service.statistics.winPercentage, 100.0);

      await service.recordGameStarted();
      await service.recordLoss();

      // 1 win out of 2 games
      expect(service.statistics.winPercentage, 50.0);

      await service.recordGameStarted();
      await service.recordWin(time: const Duration(seconds: 100), moves: 90);

      // 2 wins out of 3 games
      expect(service.statistics.winPercentage, closeTo(66.67, 0.01));
    });
  });

  group('StatisticsService Reset', () {
    test('resetStatistics() clears all statistics', () async {
      final service = StatisticsService();
      await service.recordGameStarted();
      await service.recordWin(time: const Duration(seconds: 120), moves: 100);
      await service.recordVegasScore(50);

      await service.resetStatistics();

      expect(service.statistics.gamesPlayed, 0);
      expect(service.statistics.gamesWon, 0);
      expect(service.statistics.gamesLost, 0);
      expect(service.statistics.currentStreak, 0);
      expect(service.statistics.bestStreak, 0);
      expect(service.statistics.bestTime, isNull);
      expect(service.statistics.fewestMoves, isNull);
      expect(service.statistics.vegasCumulativeScore, 0);
      expect(service.statistics.vegasHighScore, isNull);
    });

    test('resetStatistics() removes from storage', () async {
      final service = StatisticsService();
      await service.recordGameStarted();
      await service.recordWin(time: const Duration(seconds: 120), moves: 100);

      await service.resetStatistics();

      final box = await Hive.openBox('statistics');
      // Keys are now prefixed with game type (default is klondike)
      expect(box.get('klondike_gamesPlayed'), isNull);
      expect(box.get('klondike_gamesWon'), isNull);
      expect(box.get('klondike_currentStreak'), isNull);
    });

    test('resetStatistics() notifies listeners', () async {
      final service = StatisticsService();
      await service.recordGameStarted();
      bool notified = false;
      service.addListener(() => notified = true);

      await service.resetStatistics();

      expect(notified, isTrue);
    });
  });

  group('StatisticsService Complex Scenarios', () {
    test('tracks multiple wins and losses correctly', () async {
      final service = StatisticsService();

      // Game 1: Win
      await service.recordGameStarted();
      await service.recordWin(time: const Duration(seconds: 150), moves: 110);

      expect(service.statistics.gamesPlayed, 1);
      expect(service.statistics.gamesWon, 1);
      expect(service.statistics.currentStreak, 1);

      // Game 2: Win
      await service.recordGameStarted();
      await service.recordWin(time: const Duration(seconds: 120), moves: 95);

      expect(service.statistics.gamesPlayed, 2);
      expect(service.statistics.gamesWon, 2);
      expect(service.statistics.currentStreak, 2);
      expect(service.statistics.bestTime, const Duration(seconds: 120));

      // Game 3: Loss
      await service.recordGameStarted();
      await service.recordLoss();

      expect(service.statistics.gamesPlayed, 3);
      expect(service.statistics.gamesWon, 2);
      expect(service.statistics.gamesLost, 1);
      expect(service.statistics.currentStreak, 0);
      expect(service.statistics.bestStreak, 2);

      // Game 4: Win
      await service.recordGameStarted();
      await service.recordWin(time: const Duration(seconds: 90), moves: 80);

      expect(service.statistics.gamesPlayed, 4);
      expect(service.statistics.gamesWon, 3);
      expect(service.statistics.currentStreak, 1);
      expect(service.statistics.bestStreak, 2); // Unchanged
      expect(service.statistics.bestTime, const Duration(seconds: 90));
      expect(service.statistics.fewestMoves, 80);
    });

    test('persists state across service instances', () async {
      final service1 = StatisticsService();
      await service1.recordGameStarted();
      await service1.recordWin(time: const Duration(seconds: 120), moves: 100);

      await Future.delayed(const Duration(milliseconds: 10));

      // Create new service instance and load
      final service2 = StatisticsService();
      await service2.loadStatistics();

      expect(service2.statistics.gamesPlayed, 1);
      expect(service2.statistics.gamesWon, 1);
      expect(service2.statistics.bestTime, const Duration(seconds: 120));
      expect(service2.statistics.fewestMoves, 100);
    });
  });
}
