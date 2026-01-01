import 'package:audioplayers/audioplayers.dart';
import '../../settings/services/settings_provider.dart';

enum SoundEffect { cardFlip, deal, win, error, click }

class AudioService {
  late final AudioPlayer _sfxPlayer;
  late final AudioPlayer _musicPlayer;
  late SettingsProvider _settings;

  AudioService(SettingsProvider settings) {
    _settings = settings;
    // Initialize players
    _sfxPlayer = AudioPlayer();
    _musicPlayer = AudioPlayer();
    // Apply initial settings
    updateSettings(settings);
  }

  void updateSettings(SettingsProvider newSettings) {
    _settings = newSettings;
    _sfxPlayer.setVolume(_settings.soundVolume);
    _musicPlayer.setVolume(_settings.musicVolume);
    if (_settings.musicEnabled) {
      playMusic();
    } else {
      stopMusic();
    }
  }

  Future<void> playSfx(SoundEffect effect) async {
    if (!_settings.soundEnabled) return;
    // Map SoundEffect enum to actual audio file names
    String filename;
    switch (effect) {
      case SoundEffect.cardFlip:
        filename = 'card_flip';
        break;
      case SoundEffect.deal:
        filename = 'card_shuffle';
        break;
      case SoundEffect.win:
        filename = 'success';
        break;
      case SoundEffect.error:
        filename = 'error';
        break;
      case SoundEffect.click:
        filename = 'card_place';
        break;
    }
    final String path = '$filename.mp3';
    await _sfxPlayer.play(AssetSource(path));
  }

  Future<void> playMusic() async {
    if (!_settings.musicEnabled) return;
    await _musicPlayer.play(AssetSource('background-music.mp3'));
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> stopMusic() async {
    await _musicPlayer.stop();
  }

  void dispose() {
    _sfxPlayer.dispose();
    _musicPlayer.dispose();
  }
}
