import 'package:flutter_test/flutter_test.dart';
import 'package:solitude/core/services/audio_service.dart';

void main() {
  group('SilentAudioService', () {
    test('initializes with default values', () {
      final service = SilentAudioService();

      expect(service.isEnabled, isFalse);
      expect(service.volume, 1.0);
      expect(service.isMusicEnabled, isFalse);
      expect(service.musicVolume, 0.5);
    });

    test('initialize() completes without error', () async {
      final service = SilentAudioService();

      await expectLater(service.initialize(), completes);
    });

    test('setEnabled() updates isEnabled', () {
      final service = SilentAudioService();

      service.setEnabled(true);
      expect(service.isEnabled, isTrue);

      service.setEnabled(false);
      expect(service.isEnabled, isFalse);
    });

    test('setVolume() updates volume with clamping', () {
      final service = SilentAudioService();

      service.setVolume(0.5);
      expect(service.volume, 0.5);

      service.setVolume(0.0);
      expect(service.volume, 0.0);

      service.setVolume(1.0);
      expect(service.volume, 1.0);

      // Test clamping - values above 1.0
      service.setVolume(1.5);
      expect(service.volume, 1.0);

      service.setVolume(999.9);
      expect(service.volume, 1.0);

      // Test clamping - values below 0.0
      service.setVolume(-0.5);
      expect(service.volume, 0.0);

      service.setVolume(-999.9);
      expect(service.volume, 0.0);
    });

    test('setMusicEnabled() updates isMusicEnabled', () {
      final service = SilentAudioService();

      service.setMusicEnabled(true);
      expect(service.isMusicEnabled, isTrue);

      service.setMusicEnabled(false);
      expect(service.isMusicEnabled, isFalse);
    });

    test('setMusicVolume() updates musicVolume with clamping', () {
      final service = SilentAudioService();

      service.setMusicVolume(0.3);
      expect(service.musicVolume, 0.3);

      service.setMusicVolume(0.0);
      expect(service.musicVolume, 0.0);

      service.setMusicVolume(1.0);
      expect(service.musicVolume, 1.0);

      // Test clamping - values above 1.0
      service.setMusicVolume(2.0);
      expect(service.musicVolume, 1.0);

      service.setMusicVolume(100.0);
      expect(service.musicVolume, 1.0);

      // Test clamping - values below 0.0
      service.setMusicVolume(-0.2);
      expect(service.musicVolume, 0.0);

      service.setMusicVolume(-50.0);
      expect(service.musicVolume, 0.0);
    });

    test('playCardFlip() completes without error', () {
      final service = SilentAudioService();

      expect(() => service.playCardFlip(), returnsNormally);
    });

    test('playCardPlace() completes without error', () {
      final service = SilentAudioService();

      expect(() => service.playCardPlace(), returnsNormally);
    });

    test('playCardDraw() completes without error', () {
      final service = SilentAudioService();

      expect(() => service.playCardDraw(), returnsNormally);
    });

    test('playInvalidMove() completes without error', () {
      final service = SilentAudioService();

      expect(() => service.playInvalidMove(), returnsNormally);
    });

    test('playWin() completes without error', () {
      final service = SilentAudioService();

      expect(() => service.playWin(), returnsNormally);
    });

    test('startBackgroundMusic() completes without error', () async {
      final service = SilentAudioService();

      await expectLater(service.startBackgroundMusic(), completes);
    });

    test('stopBackgroundMusic() completes without error', () async {
      final service = SilentAudioService();

      await expectLater(service.stopBackgroundMusic(), completes);
    });

    test('dispose() completes without error', () {
      final service = SilentAudioService();

      expect(() => service.dispose(), returnsNormally);
    });

    test('play methods work regardless of enabled state', () {
      final service = SilentAudioService();

      // Test when disabled (default)
      expect(() => service.playCardFlip(), returnsNormally);
      expect(() => service.playCardPlace(), returnsNormally);
      expect(() => service.playCardDraw(), returnsNormally);

      // Test when enabled
      service.setEnabled(true);
      expect(() => service.playCardFlip(), returnsNormally);
      expect(() => service.playCardPlace(), returnsNormally);
      expect(() => service.playCardDraw(), returnsNormally);
    });

    test('music methods work regardless of music enabled state', () async {
      final service = SilentAudioService();

      // Test when disabled (default)
      await expectLater(service.startBackgroundMusic(), completes);
      await expectLater(service.stopBackgroundMusic(), completes);

      // Test when enabled
      service.setMusicEnabled(true);
      await expectLater(service.startBackgroundMusic(), completes);
      await expectLater(service.stopBackgroundMusic(), completes);
    });

    test('can change all settings in sequence', () {
      final service = SilentAudioService();

      service.setEnabled(true);
      service.setVolume(0.7);
      service.setMusicEnabled(true);
      service.setMusicVolume(0.3);

      expect(service.isEnabled, isTrue);
      expect(service.volume, 0.7);
      expect(service.isMusicEnabled, isTrue);
      expect(service.musicVolume, 0.3);
    });
  });

  group('GameAudioService', () {
    // Note: Testing GameAudioService is challenging because it uses real AudioPlayer instances
    // that require actual audio files and Flutter's platform channels to be initialized.
    // These tests focus on state management that doesn't require initialized AudioPlayers.

    test('initializes with default values', () {
      final service = GameAudioService();

      expect(service.isEnabled, isTrue);
      expect(service.volume, 0.2);
      expect(service.isMusicEnabled, isTrue);
      expect(service.musicVolume, 0.2);
    });

    test('setEnabled() updates isEnabled', () {
      final service = GameAudioService();

      service.setEnabled(false);
      expect(service.isEnabled, isFalse);

      service.setEnabled(true);
      expect(service.isEnabled, isTrue);
    });

    test('can be instantiated', () {
      expect(() => GameAudioService(), returnsNormally);
    });

    test('enabled state can be toggled multiple times', () {
      final service = GameAudioService();

      for (int i = 0; i < 10; i++) {
        service.setEnabled(i % 2 == 0);
        expect(service.isEnabled, i % 2 == 0);
      }
    });
  });
}
