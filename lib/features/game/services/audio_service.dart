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
    final String path = 'assets/audio/${effect.name}.mp3';
    await _sfxPlayer.play(AssetSource(path));
  }

  Future<void> playMusic() async {
    if (!_settings.musicEnabled) return;
    await _musicPlayer.play(AssetSource('assets/audio/music_background.mp3'));
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
