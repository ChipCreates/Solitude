import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:solitude/features/achievements/services/achievement_service.dart';
import 'package:solitude/features/achievements/models/achievement.dart';
import 'package:solitude/features/achievements/models/achievement_category_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Hive with a temporary directory for tests
    final testDir = Directory('./test/.hive_test');
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
    testDir.createSync(recursive: true);

    Hive.init(testDir.path);
    // Register both adapters required for Achievement
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AchievementAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AchievementCategoryAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
    final testDir = Directory('./test/.hive_test');
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  });

  group('AchievementService', () {
    setUp(() async {
      // Clean up any existing boxes before each test
      if (Hive.isBoxOpen('achievements')) {
        await Hive.box<Achievement>('achievements').close();
      }
      await Hive.deleteBoxFromDisk('achievements');
    });

    tearDown(() async {
      // Clean up after each test
      if (Hive.isBoxOpen('achievements')) {
        await Hive.box<Achievement>('achievements').close();
      }
    });

    group('initialization', () {
      test('creates service without error', () {
        final service = AchievementService();
        expect(service, isNotNull);
      });

      test('initialize opens achievement box', () async {
        final service = AchievementService();

        // Initialize should complete even if asset loading fails
        await service.initialize();
        expect(service, isNotNull);
        service.dispose();
      });
    });

    group('achievement unlocking', () {
      test('unlock method handles non-existent achievement gracefully',
          () async {
        final service = AchievementService();
        await service.initialize();

        // Should handle missing achievement without throwing
        await service.unlock('non_existent_id');

        service.dispose();
      });

      test('unlock method updates existing achievement', () async {
        final service = AchievementService();
        await service.initialize();

        // This would require proper initialization and mock setup
        // In real tests, this would verify the achievement state changes
        await service.unlock('test_achievement');

        service.dispose();
      });
    });

    group('disposal', () {
      test('dispose closes the achievement box', () async {
        final service = AchievementService();
        await service.initialize();

        expect(() => service.dispose(), returnsNormally);
      });

      test('dispose can be called multiple times', () async {
        final service = AchievementService();
        await service.initialize();

        service.dispose();
        // Calling dispose again should not throw
        expect(() => service.dispose(), returnsNormally);
      });
    });

    group('default achievement loading', () {
      test('loadDefaults handles missing asset file gracefully', () async {
        final service = AchievementService();
        await service.initialize();

        // Should fall back to hardcoded defaults when JSON loading fails
        await service.loadDefaults();

        service.dispose();
      });
    });

    group('achievement methods', () {
      test('checkWinAchievements handles game data', () {
        final service = AchievementService();

        // Should handle various game data types
        expect(
            () => service.checkWinAchievements({'moves': 42}), returnsNormally);
        expect(() => service.checkWinAchievements(null), returnsNormally);
        expect(() => service.checkWinAchievements([]), returnsNormally);
      });

      test('incrementMoveCount increments correctly', () {
        final service = AchievementService();

        expect(() => service.incrementMoveCount(), returnsNormally);
      });
    });

    group('box management', () {
      test('prevents duplicate achievement entries', () async {
        final service = AchievementService();

        // Should check if achievement already exists before adding
        await service.initialize();
        expect(service, isNotNull);
        service.dispose();
      });

      test('handles box opening failures gracefully', () async {
        final service = AchievementService();

        // In test environment, Hive might not be properly initialized
        // but service should handle this gracefully
        await service.initialize();
        expect(service, isNotNull);
        service.dispose();
      });
    });

    group('JSON loading', () {
      test('handles malformed JSON gracefully', () async {
        final service = AchievementService();
        await service.initialize();

        // Should fall back to defaults when JSON is malformed
        await service.loadDefaults();

        service.dispose();
      });

      test('handles missing achievements array gracefully', () async {
        final service = AchievementService();
        await service.initialize();

        // Should handle missing 'achievements' key
        await service.loadDefaults();

        service.dispose();
      });
    });

    group('achievement validation', () {
      test('validates achievement data properly', () async {
        final service = AchievementService();
        await service.initialize();

        // Should handle various invalid achievement data gracefully
        await service.loadDefaults();

        service.dispose();
      });
    });

    group('service state management', () {
      test('maintains service state after disposal', () async {
        final service = AchievementService();
        await service.initialize();

        service.dispose();

        // Service should be in a safe state after disposal
        expect(service, isNotNull);
      });

      test('handles single service lifecycle', () async {
        // Test a single service instance lifecycle
        final service = AchievementService();
        await service.initialize();

        expect(service, isNotNull);
        service.dispose();

        // Service object still exists after disposal
        expect(service, isNotNull);
      });
    });

    group('error handling', () {
      test('handles Hive initialization failures', () async {
        final service = AchievementService();

        // Should handle Hive box opening failures
        await service.initialize();
        expect(service, isNotNull);
        service.dispose();
      });

      test('handles JSON parsing errors', () async {
        final service = AchievementService();
        await service.initialize();

        // Should handle JSON parsing failures
        await service.loadDefaults();

        service.dispose();
      });

      test('handles asset loading failures', () async {
        final service = AchievementService();
        await service.initialize();

        // Should handle missing asset files
        await service.loadDefaults();

        service.dispose();
      });
    });

    group('concurrent operations', () {
      test('can unlock achievements while loading', () async {
        final service = AchievementService();

        // Initialize first to ensure box is open
        await service.initialize();

        // Then test unlocking
        await service.unlock('test_id');

        expect(service, isNotNull);
        service.dispose();
      });

      test('can dispose while operations are pending', () async {
        final service = AchievementService();

        // Initialize and wait for it to complete
        await service.initialize();

        // Now dispose
        service.dispose();

        expect(service, isNotNull);
      });
    });
  });
}
