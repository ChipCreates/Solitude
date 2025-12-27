import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solitude/services/settings_provider.dart';
import 'package:solitude/models/draw_mode.dart';
import 'package:solitude/models/difficulty.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Clear any existing SharedPreferences data before each test
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsProvider Initialization', () {
    test('creates with default values', () {
      final provider = SettingsProvider();

      expect(provider.drawMode, DrawMode.one);
      expect(provider.autoComplete, isTrue);
      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.autoplay, isFalse);
      expect(provider.difficulty, Difficulty.medium);
      expect(provider.scoringMode, ScoringMode.standard);
      expect(provider.soundEnabled, isTrue);
      expect(provider.musicEnabled, isTrue);
    });

    test('loads settings from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'drawMode': 1, // DrawMode.three
        'autoComplete': false,
        'autoplay': true,
        'soundEnabled': false,
      });

      final provider = SettingsProvider();
      await provider.loadSettings();

      expect(provider.drawMode, DrawMode.three);
      expect(provider.autoComplete, isFalse);
      expect(provider.autoplay, isTrue);
      expect(provider.soundEnabled, isFalse);
    });
  });

  group('SettingsProvider Draw Mode', () {
    test('setDrawMode() updates draw mode and persists', () async {
      final provider = SettingsProvider();

      await provider.setDrawMode(DrawMode.three);

      expect(provider.drawMode, DrawMode.three);

      // Verify it was persisted
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('drawMode'), 1);
    });

    test('setDrawMode() notifies listeners', () async {
      final provider = SettingsProvider();
      bool notified = false;
      provider.addListener(() => notified = true);

      await provider.setDrawMode(DrawMode.three);

      expect(notified, isTrue);
    });
  });

  group('SettingsProvider Auto Complete', () {
    test('setAutoComplete() updates value and persists', () async {
      final provider = SettingsProvider();

      await provider.setAutoComplete(false);

      expect(provider.autoComplete, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('autoComplete'), isFalse);
    });

    test('setAutoComplete() notifies listeners', () async {
      final provider = SettingsProvider();
      bool notified = false;
      provider.addListener(() => notified = true);

      await provider.setAutoComplete(false);

      expect(notified, isTrue);
    });
  });

  group('SettingsProvider Autoplay', () {
    test('setAutoplay() updates value and persists', () async {
      final provider = SettingsProvider();

      await provider.setAutoplay(true);

      expect(provider.autoplay, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('autoplay'), isTrue);
    });
  });

  group('SettingsProvider Difficulty', () {
    test('setDifficulty() updates difficulty', () async {
      final provider = SettingsProvider();

      await provider.setDifficulty(Difficulty.hard);

      expect(provider.difficulty, Difficulty.hard);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('difficulty'), 2); // hard = index 2
    });
  });

  group('SettingsProvider Scoring Mode', () {
    test('setScoringMode() updates scoring mode', () async {
      final provider = SettingsProvider();

      await provider.setScoringMode(ScoringMode.vegas);

      expect(provider.scoringMode, ScoringMode.vegas);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('scoringMode'), 1);
    });
  });

  group('SettingsProvider Card Back', () {
    test('setCardBackVariant() updates variant', () async {
      final provider = SettingsProvider();

      await provider.setCardBackVariant('alternate');

      expect(provider.cardBackVariant, 'alternate');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cardBackVariant'), 'alternate');
    });

    test('setCardBackColor() updates color', () async {
      final provider = SettingsProvider();

      await provider.setCardBackColor('#ff0000');

      expect(provider.cardBackColor, '#ff0000');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cardBackColor'), '#ff0000');
    });

    test('setCardBackColored() updates colored flag', () async {
      final provider = SettingsProvider();

      await provider.setCardBackColored(true);

      expect(provider.cardBackColored, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('cardBackColored'), isTrue);
    });
  });

  group('SettingsProvider Sound', () {
    test('setSoundEnabled() updates sound state', () async {
      final provider = SettingsProvider();

      await provider.setSoundEnabled(false);

      expect(provider.soundEnabled, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('soundEnabled'), isFalse);
    });

    test('setSoundVolume() updates volume', () async {
      final provider = SettingsProvider();

      await provider.setSoundVolume(0.75);

      expect(provider.soundVolume, 0.75);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('soundVolume'), 0.75);
    });

    test('setMusicEnabled() updates music state', () async {
      final provider = SettingsProvider();

      await provider.setMusicEnabled(false);

      expect(provider.musicEnabled, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('musicEnabled'), isFalse);
    });

    test('setMusicVolume() updates music volume', () async {
      final provider = SettingsProvider();

      await provider.setMusicVolume(0.5);

      expect(provider.musicVolume, 0.5);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('musicVolume'), 0.5);
    });
  });

  group('SettingsProvider Theme Mode', () {
    test('setThemeMode() updates theme mode', () async {
      final provider = SettingsProvider();

      await provider.setThemeMode(ThemeMode.light);

      expect(provider.themeMode, ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('themeMode'), 1);
    });

    test('toggleTheme() switches between dark and light', () async {
      final provider = SettingsProvider();

      // Start with dark (default)
      expect(provider.themeMode, ThemeMode.dark);

      await provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.light);

      await provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.dark);
    });
  });

  group('SettingsProvider Current Theme', () {
    test('setCurrentTheme() updates theme', () async {
      final provider = SettingsProvider();

      await provider.setCurrentTheme('royal_blue');

      expect(provider.currentThemeId, 'royal_blue');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('currentThemeId'), 'royal_blue');
    });

    test('currentTheme returns correct ThemePreset', () async {
      final provider = SettingsProvider();

      await provider.setCurrentTheme('classic_green');

      final theme = provider.currentTheme;
      expect(theme.id, 'classic_green');
      expect(theme.name, 'Classic Felt');
    });

    test('currentTheme returns default when theme not found', () {
      final provider = SettingsProvider();
      // Current theme ID is default 'classic_green'

      final theme = provider.currentTheme;
      expect(theme, isNotNull);
    });
  });

  group('SettingsProvider Overlay Intensity', () {
    test('getOverlayIntensity() returns default for unset theme', () {
      final provider = SettingsProvider();

      final intensity = provider.getOverlayIntensity('royal_blue');

      // Should return theme's default or 0.5
      expect(intensity, greaterThanOrEqualTo(0.0));
      expect(intensity, lessThanOrEqualTo(1.0));
    });

    test('setOverlayIntensity() updates and persists intensity', () async {
      final provider = SettingsProvider();

      await provider.setOverlayIntensity('royal_blue', 0.7);

      expect(provider.getOverlayIntensity('royal_blue'), 0.7);

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('themeOverlayIntensities');
      expect(json, isNotNull);
    });

    test('currentOverlayIntensity returns intensity for current theme', () async {
      final provider = SettingsProvider();

      await provider.setCurrentTheme('royal_blue');
      await provider.setOverlayIntensity('royal_blue', 0.8);

      expect(provider.currentOverlayIntensity, 0.8);
    });
  });

  group('SettingsProvider Persistence', () {
    test('loads all settings from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'drawMode': 1,
        'autoComplete': false,
        'themeMode': 1,
        'autoplay': true,
        'difficulty': 2,
        'scoringMode': 1,
        'cardBackVariant': 'alternate',
        'cardBackColor': '#00ff00',
        'cardBackColored': true,
        'soundEnabled': false,
        'soundVolume': 0.6,
        'musicEnabled': false,
        'musicVolume': 0.3,
        'currentThemeId': 'royal_blue',
      });

      final provider = SettingsProvider();
      await provider.loadSettings();

      expect(provider.drawMode, DrawMode.three);
      expect(provider.autoComplete, isFalse);
      expect(provider.themeMode, ThemeMode.light);
      expect(provider.autoplay, isTrue);
      expect(provider.difficulty, Difficulty.hard);
      expect(provider.scoringMode, ScoringMode.vegas);
      expect(provider.cardBackVariant, 'alternate');
      expect(provider.cardBackColor, '#00ff00');
      expect(provider.cardBackColored, isTrue);
      expect(provider.soundEnabled, isFalse);
      expect(provider.soundVolume, 0.6);
      expect(provider.musicEnabled, isFalse);
      expect(provider.musicVolume, 0.3);
      expect(provider.currentThemeId, 'royal_blue');
    });

    test('multiple setters persist independently', () async {
      final provider = SettingsProvider();

      await provider.setDrawMode(DrawMode.three);
      await provider.setSoundEnabled(false);
      await provider.setDifficulty(Difficulty.easy);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('drawMode'), 1);
      expect(prefs.getBool('soundEnabled'), isFalse);
      expect(prefs.getInt('difficulty'), 0);
    });
  });

  group('SettingsProvider Listener Notifications', () {
    test('notifies listeners on draw mode change', () async {
      final provider = SettingsProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.setDrawMode(DrawMode.three);

      expect(notifyCount, 1);
    });

    test('notifies listeners on theme change', () async {
      final provider = SettingsProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.setCurrentTheme('royal_blue');

      expect(notifyCount, 1);
    });

    test('notifies listeners on overlay intensity change', () async {
      final provider = SettingsProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.setOverlayIntensity('royal_blue', 0.5);

      expect(notifyCount, 1);
    });
  });
}
