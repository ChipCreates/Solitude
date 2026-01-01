import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/core/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioService Interface', () {
    test('SilentAudioService implements AudioService interface', () {
      final service = SilentAudioService();
      expect(service, isA<AudioService>());
    });
  });

  group('SilentAudioService', () {
    late SilentAudioService service;

    setUp(() {
      service = SilentAudioService();
    });

    group('initialization', () {
      test('initializes without error', () async {
        expect(() async => await service.initialize(), returnsNormally);
      });

      test('initialize is async and completes', () async {
        await expectLater(service.initialize(), completes);
      });

      test('can be initialized multiple times', () async {
        await service.initialize();
        await service.initialize();
        await service.initialize();
      });
    });

    group('playback methods are no-ops', () {
      test('playCardFlip does nothing', () {
        expect(() => service.playCardFlip(), returnsNormally);
      });

      test('playCardPlace does nothing', () {
        expect(() => service.playCardPlace(), returnsNormally);
      });

      test('playCardDraw does nothing', () {
        expect(() => service.playCardDraw(), returnsNormally);
      });

      test('playInvalidMove does nothing', () {
        expect(() => service.playInvalidMove(), returnsNormally);
      });

      test('playWin does nothing', () {
        expect(() => service.playWin(), returnsNormally);
      });
    });

    group('volume controls', () {
      test('setEnabled updates enabled state', () {
        expect(service.isEnabled, isFalse);

        service.setEnabled(true);
        expect(service.isEnabled, isTrue);

        service.setEnabled(false);
        expect(service.isEnabled, isFalse);
      });

      test('setVolume clamps values correctly', () {
        service.setVolume(-1.0);
        expect(service.volume, equals(0.0));

        service.setVolume(0.5);
        expect(service.volume, equals(0.5));

        service.setVolume(1.5);
        expect(service.volume, equals(1.0));
      });

      test('setMusicEnabled updates music state', () {
        expect(service.isMusicEnabled, isFalse);

        service.setMusicEnabled(true);
        expect(service.isMusicEnabled, isTrue);

        service.setMusicEnabled(false);
        expect(service.isMusicEnabled, isFalse);
      });

      test('setMusicVolume clamps values correctly', () {
        service.setMusicVolume(-0.5);
        expect(service.musicVolume, equals(0.0));

        service.setMusicVolume(0.7);
        expect(service.musicVolume, equals(0.7));

        service.setMusicVolume(2.0);
        expect(service.musicVolume, equals(1.0));
      });
    });

    group('getter properties', () {
      test('initial enabled state is false', () {
        expect(service.isEnabled, isFalse);
      });

      test('initial volume is 1.0', () {
        expect(service.volume, equals(1.0));
      });

      test('initial music enabled state is false', () {
        expect(service.isMusicEnabled, isFalse);
      });

      test('initial music volume is 0.5', () {
        expect(service.musicVolume, equals(0.5));
      });
    });

    group('background music controls', () {
      test('startBackgroundMusic does nothing', () async {
        expect(
            () async => await service.startBackgroundMusic(), returnsNormally);
      });

      test('stopBackgroundMusic does nothing', () async {
        expect(
            () async => await service.stopBackgroundMusic(), returnsNormally);
      });
    });

    group('disposal', () {
      test('dispose does nothing', () {
        expect(() => service.dispose(), returnsNormally);
      });

      test('can be disposed multiple times', () {
        service.dispose();
        service.dispose();
        service.dispose();
      });
    });

    group('music control edge cases', () {
      test('music controls work regardless of music enabled state', () async {
        service.setMusicEnabled(false);
        await service.startBackgroundMusic(); // Should not throw

        service.setMusicEnabled(true);
        await service.stopBackgroundMusic(); // Should not throw
      });
    });
  });

  group('GameAudioService', () {
    // Note: GameAudioService requires platform audio implementation
    // and is better tested through integration tests on real devices.
    // This test file focuses on the AudioService interface contract.

    test('GameAudioService implements AudioService interface', () {
      final service = GameAudioService();
      expect(service, isA<AudioService>());
    });

    test('GameAudioService has correct initial state', () {
      final service = GameAudioService();
      expect(service.isEnabled, isTrue);
      expect(service.volume, equals(0.2));
      expect(service.isMusicEnabled, isTrue);
      expect(service.musicVolume, equals(0.2));
    });

    // Note: GameAudioService requires initialization before disposal
    // and uses late fields that must be initialized first.
    // Testing this would require mocking AudioPlayer which is beyond unit test scope.
  });

  group('AudioService Interface Compliance', () {
    test('both implementations have required methods', () {
      final silentService = SilentAudioService();
      final gameService = GameAudioService();

      // Verify all required methods exist
      expect(silentService.playCardFlip, isNotNull);
      expect(silentService.playCardPlace, isNotNull);
      expect(silentService.playCardDraw, isNotNull);
      expect(silentService.playInvalidMove, isNotNull);
      expect(silentService.playWin, isNotNull);
      expect(silentService.setEnabled, isNotNull);
      expect(silentService.setVolume, isNotNull);
      expect(silentService.setMusicEnabled, isNotNull);
      expect(silentService.setMusicVolume, isNotNull);
      expect(silentService.startBackgroundMusic, isNotNull);
      expect(silentService.stopBackgroundMusic, isNotNull);
      expect(silentService.dispose, isNotNull);

      expect(gameService.playCardFlip, isNotNull);
      expect(gameService.playCardPlace, isNotNull);
      expect(gameService.playCardDraw, isNotNull);
      expect(gameService.playInvalidMove, isNotNull);
      expect(gameService.playWin, isNotNull);
      expect(gameService.setEnabled, isNotNull);
      expect(gameService.setVolume, isNotNull);
      expect(gameService.setMusicEnabled, isNotNull);
      expect(gameService.setMusicVolume, isNotNull);
      expect(gameService.startBackgroundMusic, isNotNull);
      expect(gameService.stopBackgroundMusic, isNotNull);
      expect(gameService.dispose, isNotNull);
    });

    test('both implementations have required getters', () {
      final silentService = SilentAudioService();
      final gameService = GameAudioService();

      // Verify all required getters exist and return expected types
      expect(silentService.isEnabled, isA<bool>());
      expect(silentService.volume, isA<double>());
      expect(silentService.isMusicEnabled, isA<bool>());
      expect(silentService.musicVolume, isA<double>());

      expect(gameService.isEnabled, isA<bool>());
      expect(gameService.volume, isA<double>());
      expect(gameService.isMusicEnabled, isA<bool>());
      expect(gameService.musicVolume, isA<double>());
    });
  });
}
