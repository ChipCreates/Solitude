import 'package:audioplayers/audioplayers.dart';

/// Audio service interface for sound support.
abstract class AudioService {
  void playCardFlip();
  void playCardPlace();
  void playCardDraw();
  void playInvalidMove();
  void playWin();
  void setEnabled(bool enabled);
  void setVolume(double volume);
  void setMusicEnabled(bool enabled);
  void setMusicVolume(double volume);
  Future<void> startBackgroundMusic();
  Future<void> stopBackgroundMusic();
  bool get isEnabled;
  double get volume;
  bool get isMusicEnabled;
  double get musicVolume;
  Future<void> initialize();
  void dispose();
}

/// Silent implementation - all methods are no-ops.
/// Swap to GameAudioService when sound support is added.
class SilentAudioService implements AudioService {
  bool _enabled = false;
  double _volume = 1.0;
  bool _musicEnabled = false;
  double _musicVolume = 0.5;

  @override
  Future<void> initialize() async {}

  @override
  void playCardFlip() {}

  @override
  void playCardPlace() {}

  @override
  void playCardDraw() {}

  @override
  void playInvalidMove() {}

  @override
  void playWin() {}

  @override
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  @override
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
  }

  @override
  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
  }

  @override
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
  }

  @override
  Future<void> startBackgroundMusic() async {}

  @override
  Future<void> stopBackgroundMusic() async {}

  @override
  bool get isEnabled => _enabled;

  @override
  double get volume => _volume;

  @override
  bool get isMusicEnabled => _musicEnabled;

  @override
  double get musicVolume => _musicVolume;

  @override
  void dispose() {}
}

/// Implementation with actual audio playback.
class GameAudioService implements AudioService {
  bool _enabled = true;
  double _volume = 0.2;
  bool _musicEnabled = true;
  double _musicVolume = 0.2;

  late AudioPlayer _cardFlipPlayer;
  late AudioPlayer _cardPlacePlayer;
  late AudioPlayer _cardDrawPlayer;
  late AudioPlayer _errorPlayer;
  late AudioPlayer _successPlayer;
  late AudioPlayer _musicPlayer;

  GameAudioService();

  @override
  Future<void> initialize() async {
    try {
      _cardFlipPlayer = AudioPlayer();
      _cardPlacePlayer = AudioPlayer();
      _cardDrawPlayer = AudioPlayer();
      _errorPlayer = AudioPlayer();
      _successPlayer = AudioPlayer();
      _musicPlayer = AudioPlayer();

      // Set initial volumes (guard against platform/audio failures)
      await _cardFlipPlayer.setVolume(_volume).catchError((_) {});
      await _cardPlacePlayer.setVolume(_volume).catchError((_) {});
      await _cardDrawPlayer.setVolume(_volume).catchError((_) {});
      await _errorPlayer.setVolume(_volume).catchError((_) {});
      await _successPlayer.setVolume(_volume).catchError((_) {});
      await _musicPlayer.setVolume(_musicVolume).catchError((_) {});

      // Preload audio files
      await _cardFlipPlayer.setSource(AssetSource('audio/card_flip.mp3')).catchError((_) {});
      await _cardPlacePlayer.setSource(AssetSource('audio/card_place.mp3')).catchError((_) {});
      await _cardDrawPlayer.setSource(AssetSource('audio/card_shuffle.mp3')).catchError((_) {});
      await _errorPlayer.setSource(AssetSource('audio/error.mp3')).catchError((_) {});
      await _successPlayer.setSource(AssetSource('audio/success.mp3')).catchError((_) {});

      // Preload background music and set to loop
      await _musicPlayer.setSource(AssetSource('audio/background-music.mp3')).catchError((_) {});
      await _musicPlayer.setReleaseMode(ReleaseMode.loop).catchError((_) {});
    } catch (_) {
      // Ignore audio initialization errors to avoid crashing the app/test environment
    }
  }

  @override
  void playCardFlip() {
    if (!_enabled) return;
    _cardFlipPlayer.seek(Duration.zero).then((_) {
      _cardFlipPlayer.resume().catchError((_) {});
    }).catchError((_) {});
  }

  @override
  void playCardPlace() {
    if (!_enabled) return;
    _cardPlacePlayer.seek(Duration.zero).then((_) {
      _cardPlacePlayer.resume().catchError((_) {});
    }).catchError((_) {});
  }

  @override
  void playCardDraw() {
    if (!_enabled) return;
    _cardDrawPlayer.seek(Duration.zero).then((_) {
      _cardDrawPlayer.resume().catchError((_) {});
    }).catchError((_) {});
  }

  @override
  void playInvalidMove() {
    if (!_enabled) return;
    _errorPlayer.seek(Duration.zero).then((_) {
      _errorPlayer.resume().catchError((_) {});
    }).catchError((_) {});
  }

  @override
  void playWin() {
    if (!_enabled) return;
    _successPlayer.seek(Duration.zero).then((_) {
      _successPlayer.resume().catchError((_) {});
    }).catchError((_) {});
  }

  @override
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  @override
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _cardFlipPlayer.setVolume(_volume).catchError((_) {});
    _cardPlacePlayer.setVolume(_volume).catchError((_) {});
    _cardDrawPlayer.setVolume(_volume).catchError((_) {});
    _errorPlayer.setVolume(_volume).catchError((_) {});
    _successPlayer.setVolume(_volume).catchError((_) {});
  }

  @override
  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled) {
      _musicPlayer.pause().catchError((_) {});
    } else {
      // Resume if paused or stopped, which will continue looping
      if (_musicPlayer.state == PlayerState.paused ||
          _musicPlayer.state == PlayerState.stopped ||
          _musicPlayer.state == PlayerState.completed) {
        _musicPlayer.resume().catchError((_) {});
      }
    }
  }

  @override
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    _musicPlayer.setVolume(_musicVolume).catchError((_) {});
  }

  @override
  Future<void> startBackgroundMusic() async {
    if (_musicEnabled) {
      try {
        await _musicPlayer.resume();
      } catch (_) {}
    }
  }

  @override
  Future<void> stopBackgroundMusic() async {
    try {
      await _musicPlayer.pause();
    } catch (_) {}
  }

  @override
  bool get isEnabled => _enabled;

  @override
  double get volume => _volume;

  @override
  bool get isMusicEnabled => _musicEnabled;

  @override
  double get musicVolume => _musicVolume;

  @override
  void dispose() {
    _cardFlipPlayer.dispose();
    _cardPlacePlayer.dispose();
    _cardDrawPlayer.dispose();
    _errorPlayer.dispose();
    _successPlayer.dispose();
    _musicPlayer.dispose();
  }
}
