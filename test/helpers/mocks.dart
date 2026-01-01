import 'package:flutter/material.dart';
import 'package:solitude/features/settings/services/settings_provider.dart';
import 'package:solitude/features/statistics/services/statistics_service.dart';
import 'package:solitude/core/services/audio_service.dart' as core_audio;
import 'package:solitude/features/game/services/audio_service.dart'
    as game_audio;
import 'package:solitude/features/game/models/draw_mode.dart';
import 'package:solitude/features/settings/models/difficulty.dart';
import 'package:solitude/features/settings/models/theme_preset.dart';

/// Mock SettingsProvider for testing
///
/// Provides configurable settings values without persistence.
class MockSettingsProvider extends SettingsProvider {
  bool _soundEnabled;
  double _soundVolume;
  bool _musicEnabled;
  double _musicVolume;
  Difficulty _difficulty;
  final DrawMode _drawMode;
  bool _autoplay;
  bool _autoComplete;
  ScoringMode _scoringMode;
  final ThemePreset _theme;
  ThemeMode _themeMode;

  MockSettingsProvider({
    bool soundEnabled = false,
    double soundVolume = 1.0,
    bool musicEnabled = false,
    double musicVolume = 0.5,
    Difficulty difficulty = Difficulty.medium,
    DrawMode drawMode = DrawMode.one,
    bool autoplay = true,
    bool autoComplete = true,
    ScoringMode scoringMode = ScoringMode.standard,
    ThemePreset? theme,
    ThemeMode themeMode = ThemeMode.dark,
  })  : _soundEnabled = soundEnabled,
        _soundVolume = soundVolume,
        _musicEnabled = musicEnabled,
        _musicVolume = musicVolume,
        _difficulty = difficulty,
        _drawMode = drawMode,
        _autoplay = autoplay,
        _autoComplete = autoComplete,
        _scoringMode = scoringMode,
        _theme = theme ?? ThemePreset.defaultTheme,
        _themeMode = themeMode;

  @override
  bool get soundEnabled => _soundEnabled;

  @override
  double get soundVolume => _soundVolume;

  @override
  bool get musicEnabled => _musicEnabled;

  @override
  double get musicVolume => _musicVolume;

  @override
  Difficulty get difficulty => _difficulty;

  @override
  DrawMode get drawMode => _drawMode;

  @override
  bool get autoplay => _autoplay;

  @override
  bool get autoComplete => _autoComplete;

  @override
  ScoringMode get scoringMode => _scoringMode;

  @override
  ThemePreset get currentTheme => _theme;

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  double get currentOverlayIntensity => 0.5;

  @override
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    notifyListeners();
  }

  @override
  Future<void> setSoundVolume(double volume) async {
    _soundVolume = volume;
    notifyListeners();
  }

  @override
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    notifyListeners();
  }

  @override
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume;
    notifyListeners();
  }

  @override
  Future<void> setDifficulty(Difficulty difficulty) async {
    _difficulty = difficulty;
    notifyListeners();
  }

  @override
  Future<void> setAutoplay(bool enabled) async {
    _autoplay = enabled;
    notifyListeners();
  }

  @override
  Future<void> setAutoComplete(bool enabled) async {
    _autoComplete = enabled;
    notifyListeners();
  }

  @override
  Future<void> setScoringMode(ScoringMode mode) async {
    _scoringMode = mode;
    notifyListeners();
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
  }
}

/// Mock StatisticsService for testing
///
/// Tracks method calls without persistence.
class MockStatisticsService extends StatisticsService {
  int gamesStartedCount = 0;
  int gamesWonCount = 0;
  int gamesLostCount = 0;
  int vegasScoresRecorded = 0;
  List<int> recordedVegasScores = [];
  Duration? lastWinTime;
  int? lastWinMoves;

  @override
  Future<void> recordGameStarted() async {
    gamesStartedCount++;
  }

  @override
  Future<void> recordWin({required Duration time, required int moves}) async {
    gamesWonCount++;
    lastWinTime = time;
    lastWinMoves = moves;
  }

  @override
  Future<void> recordLoss() async {
    gamesLostCount++;
  }

  @override
  Future<void> recordVegasScore(int score) async {
    vegasScoresRecorded++;
    recordedVegasScores.add(score);
  }

  /// Reset all tracked counts
  void reset() {
    gamesStartedCount = 0;
    gamesWonCount = 0;
    gamesLostCount = 0;
    vegasScoresRecorded = 0;
    recordedVegasScores.clear();
    lastWinTime = null;
    lastWinMoves = null;
  }
}

/// Mock AudioService for testing
///
/// Tracks audio method calls without playing actual sounds.
class MockAudioService implements core_audio.AudioService {
  int cardFlipCount = 0;
  int cardPlaceCount = 0;
  int cardDrawCount = 0;
  int invalidMoveCount = 0;
  int winCount = 0;
  int initializeCount = 0;
  int disposeCount = 0;
  int startMusicCount = 0;
  int stopMusicCount = 0;

  bool _enabled = false;
  double _volume = 1.0;
  bool _musicEnabled = false;
  double _musicVolume = 0.5;

  @override
  Future<void> initialize() async {
    initializeCount++;
  }

  @override
  void dispose() {
    disposeCount++;
  }

  @override
  void playCardFlip() {
    cardFlipCount++;
  }

  @override
  void playCardPlace() {
    cardPlaceCount++;
  }

  @override
  void playCardDraw() {
    cardDrawCount++;
  }

  @override
  void playInvalidMove() {
    invalidMoveCount++;
  }

  @override
  void playWin() {
    winCount++;
  }

  @override
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  @override
  void setVolume(double volume) {
    _volume = volume;
  }

  @override
  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
  }

  @override
  void setMusicVolume(double volume) {
    _musicVolume = volume;
  }

  @override
  Future<void> startBackgroundMusic() async {
    startMusicCount++;
  }

  @override
  Future<void> stopBackgroundMusic() async {
    stopMusicCount++;
  }

  @override
  bool get isEnabled => _enabled;

  @override
  double get volume => _volume;

  @override
  bool get isMusicEnabled => _musicEnabled;

  @override
  double get musicVolume => _musicVolume;

  /// Reset all tracked counts
  void reset() {
    cardFlipCount = 0;
    cardPlaceCount = 0;
    cardDrawCount = 0;
    invalidMoveCount = 0;
    winCount = 0;
    initializeCount = 0;
    disposeCount = 0;
    startMusicCount = 0;
    stopMusicCount = 0;
  }
}

/// Mock GameAudioService for testing
///
/// Tracks audio method calls without playing actual sounds.
class MockGameAudioService {
  int playSfxCount = 0;
  int updateSettingsCount = 0;
  int disposeCount = 0;

  void playSfx(game_audio.SoundEffect effect) {
    playSfxCount++;
  }

  void updateSettings(dynamic settings) {
    updateSettingsCount++;
  }

  void dispose() {
    disposeCount++;
  }

  /// Reset all tracked counts
  void reset() {
    playSfxCount = 0;
    updateSettingsCount = 0;
    disposeCount = 0;
  }
}
