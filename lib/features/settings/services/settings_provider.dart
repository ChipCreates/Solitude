import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:solitude/features/game/models/draw_mode.dart';
import '../models/difficulty.dart';
import '../models/theme_preset.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _drawModeKey = 'drawMode';
  static const String _autoCompleteKey = 'autoComplete';
  static const String _themeModeKey = 'themeMode';
  static const String _autoplayKey = 'autoplay';
  static const String _difficultyKey = 'difficulty';
  static const String _scoringModeKey = 'scoringMode';
  static const String _cardBackVariantKey = 'cardBackVariant';
  static const String _cardBackColorKey = 'cardBackColor';
  static const String _cardBackColoredKey = 'cardBackColored';
  static const String _soundEnabledKey = 'soundEnabled';
  static const String _soundVolumeKey = 'soundVolume';
  static const String _musicEnabledKey = 'musicEnabled';
  static const String _musicVolumeKey = 'musicVolume';
  static const String _currentThemeIdKey = 'currentThemeId';
  static const String _themeOverlayIntensitiesKey = 'themeOverlayIntensities';

  DrawMode _drawMode = DrawMode.one;
  bool _autoComplete = true;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _autoplay = false;

  Difficulty _difficulty = Difficulty.medium;
  ScoringMode _scoringMode = ScoringMode.standard;
  bool _soundEnabled = true;
  double _soundVolume = 0.2;
  bool _musicEnabled = true;
  double _musicVolume = 0.2;

  // Card back variant: 'back' | 'alternate'
  String _cardBackVariant = 'back';
  String _cardBackColor = '#0062ff';
  bool _cardBackColored = false;

  // Theme management
  String _currentThemeId = 'classic_green';
  Map<String, double> _themeOverlayIntensities = {};

  DrawMode get drawMode => _drawMode;
  bool get autoComplete => _autoComplete;
  ThemeMode get themeMode => _themeMode;
  bool get autoplay => _autoplay;
  Difficulty get difficulty => _difficulty;
  ScoringMode get scoringMode => _scoringMode;
  String get cardBackVariant => _cardBackVariant;
  String get cardBackColor => _cardBackColor;
  bool get cardBackColored => _cardBackColored;
  bool get soundEnabled => _soundEnabled;
  double get soundVolume => _soundVolume;
  bool get musicEnabled => _musicEnabled;
  double get musicVolume => _musicVolume;
  String get currentThemeId => _currentThemeId;

  ThemePreset get currentTheme {
    return ThemePreset.findById(_currentThemeId) ?? ThemePreset.defaultTheme;
  }

  double getOverlayIntensity(String themeId) {
    return _themeOverlayIntensities[themeId] ??
           ThemePreset.findById(themeId)?.defaultOverlayIntensity ??
           0.5;
  }

  double get currentOverlayIntensity => getOverlayIntensity(_currentThemeId);
  
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final drawModeIndex = prefs.getInt(_drawModeKey) ?? 0;
    _drawMode = DrawMode.values[drawModeIndex.clamp(0, DrawMode.values.length - 1)];
    
    _autoComplete = prefs.getBool(_autoCompleteKey) ?? true;

    _autoplay = prefs.getBool(_autoplayKey) ?? false;
    
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? 2; // Default to dark
    _themeMode = ThemeMode.values[themeModeIndex.clamp(0, ThemeMode.values.length - 1)];

    final difficultyIndex = prefs.getInt(_difficultyKey) ?? 1; // Default to medium
    _difficulty = Difficulty.values[difficultyIndex.clamp(0, Difficulty.values.length - 1)];

    final scoringModeIndex = prefs.getInt(_scoringModeKey) ?? 0; // Default to standard
    _scoringMode = ScoringMode.values[scoringModeIndex.clamp(0, ScoringMode.values.length - 1)];

    _cardBackVariant = prefs.getString(_cardBackVariantKey) ?? 'back';
    _cardBackColor = prefs.getString(_cardBackColorKey) ?? '#0062ff';
    _cardBackColored = prefs.getBool(_cardBackColoredKey) ?? false;
    _soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
    _soundVolume = prefs.getDouble(_soundVolumeKey) ?? 0.2;
    _musicEnabled = prefs.getBool(_musicEnabledKey) ?? true;
    _musicVolume = prefs.getDouble(_musicVolumeKey) ?? 0.2;

    _currentThemeId = prefs.getString(_currentThemeIdKey) ?? 'classic_green';
    final intensitiesJson = prefs.getString(_themeOverlayIntensitiesKey);
    if (intensitiesJson != null) {
      try {
        final decoded = jsonDecode(intensitiesJson) as Map<String, dynamic>;
        _themeOverlayIntensities = decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
      } catch (_) {
        _themeOverlayIntensities = {};
      }
    }

    notifyListeners();
  }
  
  Future<void> setDrawMode(DrawMode mode) async {
    _drawMode = mode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_drawModeKey, mode.index);
  }
  
  Future<void> setAutoComplete(bool value) async {
    _autoComplete = value;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoCompleteKey, value);
  }

  Future<void> setAutoplay(bool value) async {
    _autoplay = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoplayKey, value);
  }

  Future<void> setDifficulty(Difficulty level) async {
    _difficulty = level;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_difficultyKey, level.index);
  }

  Future<void> setScoringMode(ScoringMode mode) async {
    _scoringMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_scoringModeKey, mode.index);
  }

  Future<void> setCardBackVariant(String variant) async {
    debugPrint('Setting card back variant to: $variant');
    _cardBackVariant = variant;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cardBackVariantKey, variant);
  }

  Future<void> setCardBackColor(String hex) async {
    _cardBackColor = hex;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cardBackColorKey, hex);
  }

  Future<void> setCardBackColored(bool value) async {
    _cardBackColored = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cardBackColoredKey, value);
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, value);
  }

  Future<void> setSoundVolume(double value) async {
    _soundVolume = value.clamp(0.0, 1.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_soundVolumeKey, _soundVolume);
  }

  Future<void> setMusicEnabled(bool value) async {
    _musicEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicEnabledKey, value);
  }

  Future<void> setMusicVolume(double value) async {
    _musicVolume = value.clamp(0.0, 1.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_musicVolumeKey, _musicVolume);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  Future<void> setCurrentTheme(String themeId) async {
    _currentThemeId = themeId;
    // Tune default card back color to the first suggested color for the selected theme
    final theme = ThemePreset.findById(themeId) ?? ThemePreset.defaultTheme;
    final suggested = theme.suggestedBackColors(_themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light);
    if (suggested.isNotEmpty) {
      _cardBackColor = '#${(suggested.first.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    }

    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentThemeIdKey, themeId);
    await prefs.setString(_cardBackColorKey, _cardBackColor);
  }

  Future<void> setOverlayIntensity(String themeId, double intensity) async {
    _themeOverlayIntensities[themeId] = intensity.clamp(0.0, 1.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeOverlayIntensitiesKey, jsonEncode(_themeOverlayIntensities));
  }
}
