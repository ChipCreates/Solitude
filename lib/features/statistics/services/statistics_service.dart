import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solitude/features/game/games/game_factory.dart';

class Statistics {
  final int gamesPlayed;
  final int gamesWon;
  final int gamesLost;
  final int currentStreak;
  final int bestStreak;
  final Duration? bestTime;
  final int? fewestMoves;
  final int vegasCumulativeScore; // Total Vegas winnings/losses
  final int? vegasHighScore; // Best single-game Vegas score

  const Statistics({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.gamesLost = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.bestTime,
    this.fewestMoves,
    this.vegasCumulativeScore = 0,
    this.vegasHighScore,
  });

  double get winPercentage =>
    gamesPlayed > 0 ? (gamesWon / gamesPlayed) * 100 : 0;

  Statistics copyWith({
    int? gamesPlayed,
    int? gamesWon,
    int? gamesLost,
    int? currentStreak,
    int? bestStreak,
    Duration? bestTime,
    int? fewestMoves,
    int? vegasCumulativeScore,
    int? vegasHighScore,
    bool clearBestTime = false,
    bool clearFewestMoves = false,
    bool clearVegasHighScore = false,
  }) {
    return Statistics(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      gamesLost: gamesLost ?? this.gamesLost,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      bestTime: clearBestTime ? null : (bestTime ?? this.bestTime),
      fewestMoves: clearFewestMoves ? null : (fewestMoves ?? this.fewestMoves),
      vegasCumulativeScore: vegasCumulativeScore ?? this.vegasCumulativeScore,
      vegasHighScore: clearVegasHighScore ? null : (vegasHighScore ?? this.vegasHighScore),
    );
  }
}

class StatisticsService extends ChangeNotifier {
  // Key suffixes (prefixed with game type)
  static const String _gamesPlayedKey = 'gamesPlayed';
  static const String _gamesWonKey = 'gamesWon';
  static const String _currentStreakKey = 'currentStreak';
  static const String _bestStreakKey = 'bestStreak';
  static const String _bestTimeKey = 'bestTime';
  static const String _fewestMovesKey = 'fewestMoves';
  static const String _gamesLostKey = 'gamesLost';
  static const String _vegasCumulativeScoreKey = 'vegasCumulativeScore';
  static const String _vegasHighScoreKey = 'vegasHighScore';
  static const String _migrationCompleteKey = 'stats_migration_v1_complete';

  // Current game type being tracked
  GameType _currentGameType = GameType.klondike;

  // Cache of statistics per game type
  final Map<GameType, Statistics> _statisticsCache = {};

  // Track if legacy migration has been attempted
  bool _migrationAttempted = false;

  Statistics get statistics => _statisticsCache[_currentGameType] ?? const Statistics();
  GameType get currentGameType => _currentGameType;

  /// Get the storage key prefix for a game type
  /// Keys are now prefixed with game type name (e.g., 'klondike_gamesPlayed')
  String _keyPrefix(GameType type) => '${type.name}_';

  /// Get a full storage key for a game type and key suffix
  String _key(GameType type, String suffix) => '${_keyPrefix(type)}$suffix';

  /// Get the legacy (unprefixed) key for backward compatibility
  String _legacyKey(String suffix) => suffix;

  /// Switch to tracking a different game type
  Future<void> setGameType(GameType type) async {
    if (_currentGameType != type) {
      _currentGameType = type;
      if (!_statisticsCache.containsKey(type)) {
        await _loadStatisticsForType(type);
      }
      notifyListeners();
    }
  }

  /// Get statistics for a specific game type (loads if not cached)
  Future<Statistics> getStatisticsForType(GameType type) async {
    if (!_statisticsCache.containsKey(type)) {
      await _loadStatisticsForType(type);
    }
    return _statisticsCache[type] ?? const Statistics();
  }

  Future<void> loadStatistics() async {
    // Load statistics for current game type
    await _loadStatisticsForType(_currentGameType);
    notifyListeners();
  }

  Future<Box> _ensureBox() async {
    if (!Hive.isBoxOpen('statistics')) {
      try {
        await Hive.openBox('statistics');
      } catch (_) {
        // If Hive hasn't been initialized (tests or VM), initialize with a safe temp directory
        try {
          final tempDir = Directory('${Directory.systemTemp.path}/solitude_hive');
          if (!tempDir.existsSync()) tempDir.createSync(recursive: true);
          Hive.init(tempDir.path);
          await Hive.openBox('statistics');
        } catch (e) {
          rethrow;
        }
      }
    }
    return Hive.box('statistics');
  }

  Future<void> _loadStatisticsForType(GameType type) async {
    final prefs = await SharedPreferences.getInstance();
    final box = await _ensureBox();

    // Check if we need to migrate legacy unprefixed keys to Klondike
    // Legacy keys (unprefixed) are assumed to be Klondike stats since that was
    // the only game type before multi-game support
    if (!_migrationAttempted && type == GameType.klondike) {
      _migrationAttempted = true;
      await _migrateLegacyKeys(prefs, box);
    }

    // Try to load from Hive first (new prefixed keys)
    final prefixedKey = _key(type, _gamesPlayedKey);
    final hasHiveData = box.containsKey(prefixedKey);

    if (hasHiveData) {
      _statisticsCache[type] = Statistics(
        gamesPlayed: box.get(_key(type, _gamesPlayedKey)) as int? ?? 0,
        gamesWon: box.get(_key(type, _gamesWonKey)) as int? ?? 0,
        gamesLost: box.get(_key(type, _gamesLostKey)) as int? ?? 0,
        currentStreak: box.get(_key(type, _currentStreakKey)) as int? ?? 0,
        bestStreak: box.get(_key(type, _bestStreakKey)) as int? ?? 0,
        bestTime: box.get(_key(type, _bestTimeKey)) != null
            ? Duration(milliseconds: box.get(_key(type, _bestTimeKey)) as int)
            : null,
        fewestMoves: box.get(_key(type, _fewestMovesKey)) as int?,
        vegasCumulativeScore: box.get(_key(type, _vegasCumulativeScoreKey)) as int? ?? 0,
        vegasHighScore: box.get(_key(type, _vegasHighScoreKey)) as int?,
      );
      return;
    }

    // Check SharedPreferences for prefixed keys (intermediate migration state)
    final hasPrefixedPrefs = prefs.containsKey(_key(type, _gamesPlayedKey));
    if (hasPrefixedPrefs) {
      final gamesPlayed = prefs.getInt(_key(type, _gamesPlayedKey)) ?? 0;
      final gamesWon = prefs.getInt(_key(type, _gamesWonKey)) ?? 0;
      final gamesLost = prefs.getInt(_key(type, _gamesLostKey)) ?? 0;
      final currentStreak = prefs.getInt(_key(type, _currentStreakKey)) ?? 0;
      final bestStreak = prefs.getInt(_key(type, _bestStreakKey)) ?? 0;
      final bestTimeMs = prefs.getInt(_key(type, _bestTimeKey));
      final fewestMoves = prefs.getInt(_key(type, _fewestMovesKey));
      final vegasCumulative = prefs.getInt(_key(type, _vegasCumulativeScoreKey)) ?? 0;
      final vegasHighScore = prefs.getInt(_key(type, _vegasHighScoreKey));

      _statisticsCache[type] = Statistics(
        gamesPlayed: gamesPlayed,
        gamesWon: gamesWon,
        gamesLost: gamesLost,
        currentStreak: currentStreak,
        bestStreak: bestStreak,
        bestTime: bestTimeMs != null ? Duration(milliseconds: bestTimeMs) : null,
        fewestMoves: fewestMoves,
        vegasCumulativeScore: vegasCumulative,
        vegasHighScore: vegasHighScore,
      );

      // Migrate to Hive
      await _saveStatisticsToBox(box, type, _statisticsCache[type]!);
      return;
    }

    // No data found - start fresh
    _statisticsCache[type] = const Statistics();
  }

  /// Migrate legacy unprefixed keys to Klondike-prefixed keys
  Future<void> _migrateLegacyKeys(SharedPreferences prefs, Box box) async {
    // Check if migration already completed
    if (box.get(_migrationCompleteKey) == true) return;

    // Check for legacy unprefixed keys
    final hasLegacy = prefs.containsKey(_legacyKey(_gamesPlayedKey)) ||
        prefs.containsKey(_legacyKey(_gamesWonKey)) ||
        prefs.containsKey(_legacyKey(_gamesLostKey));

    if (!hasLegacy) {
      // No legacy data to migrate
      await box.put(_migrationCompleteKey, true);
      return;
    }

    // Migrate legacy stats to Klondike (the original game type)
    const klondikeType = GameType.klondike;
    final gamesPlayed = prefs.getInt(_legacyKey(_gamesPlayedKey)) ?? 0;
    final gamesWon = prefs.getInt(_legacyKey(_gamesWonKey)) ?? 0;
    final gamesLost = prefs.getInt(_legacyKey(_gamesLostKey)) ?? 0;
    final currentStreak = prefs.getInt(_legacyKey(_currentStreakKey)) ?? 0;
    final bestStreak = prefs.getInt(_legacyKey(_bestStreakKey)) ?? 0;
    final bestTimeMs = prefs.getInt(_legacyKey(_bestTimeKey));
    final fewestMoves = prefs.getInt(_legacyKey(_fewestMovesKey));
    final vegasCumulative = prefs.getInt(_legacyKey(_vegasCumulativeScoreKey)) ?? 0;
    final vegasHighScore = prefs.getInt(_legacyKey(_vegasHighScoreKey));

    // Save with new prefixed keys
    await box.put(_key(klondikeType, _gamesPlayedKey), gamesPlayed);
    await box.put(_key(klondikeType, _gamesWonKey), gamesWon);
    await box.put(_key(klondikeType, _gamesLostKey), gamesLost);
    await box.put(_key(klondikeType, _currentStreakKey), currentStreak);
    await box.put(_key(klondikeType, _bestStreakKey), bestStreak);
    await box.put(_key(klondikeType, _vegasCumulativeScoreKey), vegasCumulative);
    if (bestTimeMs != null) {
      await box.put(_key(klondikeType, _bestTimeKey), bestTimeMs);
    }
    if (fewestMoves != null) {
      await box.put(_key(klondikeType, _fewestMovesKey), fewestMoves);
    }
    if (vegasHighScore != null) {
      await box.put(_key(klondikeType, _vegasHighScoreKey), vegasHighScore);
    }

    // Mark migration complete
    await box.put(_migrationCompleteKey, true);

    debugPrint('StatisticsService: Migrated legacy stats to Klondike-prefixed keys');
  }

  /// Save statistics to Hive box
  Future<void> _saveStatisticsToBox(Box box, GameType type, Statistics stats) async {
    await box.put(_key(type, _gamesPlayedKey), stats.gamesPlayed);
    await box.put(_key(type, _gamesWonKey), stats.gamesWon);
    await box.put(_key(type, _gamesLostKey), stats.gamesLost);
    await box.put(_key(type, _currentStreakKey), stats.currentStreak);
    await box.put(_key(type, _bestStreakKey), stats.bestStreak);
    await box.put(_key(type, _vegasCumulativeScoreKey), stats.vegasCumulativeScore);

    if (stats.bestTime != null) {
      await box.put(_key(type, _bestTimeKey), stats.bestTime!.inMilliseconds);
    }
    if (stats.fewestMoves != null) {
      await box.put(_key(type, _fewestMovesKey), stats.fewestMoves!);
    }
    if (stats.vegasHighScore != null) {
      await box.put(_key(type, _vegasHighScoreKey), stats.vegasHighScore!);
    }
  }

  Future<void> _saveStatistics() async {
    final box = await _ensureBox();
    await _saveStatisticsToBox(box, _currentGameType, statistics);
  }

  Future<void> recordGameStarted() async {
    _statisticsCache[_currentGameType] = statistics.copyWith(
      gamesPlayed: statistics.gamesPlayed + 1,
    );
    await _saveStatistics();
    notifyListeners();
  }

  Future<void> recordWin({required Duration time, required int moves}) async {
    final stats = statistics;
    final newStreak = stats.currentStreak + 1;
    final newBestStreak = newStreak > stats.bestStreak
        ? newStreak
        : stats.bestStreak;

    Duration? newBestTime = stats.bestTime;
    if (newBestTime == null || time < newBestTime) {
      newBestTime = time;
    }

    int? newFewestMoves = stats.fewestMoves;
    if (newFewestMoves == null || moves < newFewestMoves) {
      newFewestMoves = moves;
    }

    _statisticsCache[_currentGameType] = stats.copyWith(
      gamesWon: stats.gamesWon + 1,
      currentStreak: newStreak,
      bestStreak: newBestStreak,
      bestTime: newBestTime,
      fewestMoves: newFewestMoves,
    );

    await _saveStatistics();
    notifyListeners();
  }

  Future<void> recordLoss() async {
    _statisticsCache[_currentGameType] = statistics.copyWith(
      currentStreak: 0,
      gamesLost: statistics.gamesLost + 1,
    );
    await _saveStatistics();
    notifyListeners();
  }

  /// Record Vegas scoring for a game
  Future<void> recordVegasScore(int score) async {
    final stats = statistics;
    int? newHighScore = stats.vegasHighScore;
    if (newHighScore == null || score > newHighScore) {
      newHighScore = score;
    }

    _statisticsCache[_currentGameType] = stats.copyWith(
      vegasCumulativeScore: stats.vegasCumulativeScore + score,
      vegasHighScore: newHighScore,
    );

    await _saveStatistics();
    notifyListeners();
  }

  /// Reset statistics for the current game type only
  Future<void> resetStatistics() async {
    final box = await _ensureBox();
    final type = _currentGameType;

    final keys = [
      _key(type, _gamesPlayedKey),
      _key(type, _gamesWonKey),
      _key(type, _gamesLostKey),
      _key(type, _currentStreakKey),
      _key(type, _bestStreakKey),
      _key(type, _bestTimeKey),
      _key(type, _fewestMovesKey),
      _key(type, _vegasCumulativeScoreKey),
      _key(type, _vegasHighScoreKey),
    ];
    await box.deleteAll(keys);

    _statisticsCache[type] = const Statistics();
    notifyListeners();
  }

  /// Reset statistics for all game types
  Future<void> resetAllStatistics() async {
    for (final type in GameType.values) {
      _currentGameType = type;
      await resetStatistics();
    }
    _currentGameType = GameType.klondike;
    notifyListeners();
  }

  String formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // For testing purposes
  void setTestStatistics(Statistics stats) {
    _statisticsCache[_currentGameType] = stats;
    notifyListeners();
  }
}
