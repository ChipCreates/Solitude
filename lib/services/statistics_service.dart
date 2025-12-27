import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../games/game_factory.dart';

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

  // Current game type being tracked
  GameType _currentGameType = GameType.klondike;

  // Cache of statistics per game type
  final Map<GameType, Statistics> _statisticsCache = {};

  Statistics get statistics => _statisticsCache[_currentGameType] ?? const Statistics();
  GameType get currentGameType => _currentGameType;

  /// Get the storage key prefix for a game type
  String _keyPrefix(GameType type) => '${type.name}_';

  /// Get a full storage key for a game type and key suffix
  String _key(GameType type, String suffix) => '${_keyPrefix(type)}$suffix';

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

  Future<void> _loadStatisticsForType(GameType type) async {
    final prefs = await SharedPreferences.getInstance();

    final bestTimeMs = prefs.getInt(_key(type, _bestTimeKey));
    final fewestMoves = prefs.getInt(_key(type, _fewestMovesKey));
    final vegasHighScore = prefs.getInt(_key(type, _vegasHighScoreKey));

    _statisticsCache[type] = Statistics(
      gamesPlayed: prefs.getInt(_key(type, _gamesPlayedKey)) ?? 0,
      gamesWon: prefs.getInt(_key(type, _gamesWonKey)) ?? 0,
      gamesLost: prefs.getInt(_key(type, _gamesLostKey)) ?? 0,
      currentStreak: prefs.getInt(_key(type, _currentStreakKey)) ?? 0,
      bestStreak: prefs.getInt(_key(type, _bestStreakKey)) ?? 0,
      bestTime: bestTimeMs != null ? Duration(milliseconds: bestTimeMs) : null,
      fewestMoves: fewestMoves,
      vegasCumulativeScore: prefs.getInt(_key(type, _vegasCumulativeScoreKey)) ?? 0,
      vegasHighScore: vegasHighScore,
    );
  }

  Future<void> _saveStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final type = _currentGameType;
    final stats = statistics;

    await prefs.setInt(_key(type, _gamesPlayedKey), stats.gamesPlayed);
    await prefs.setInt(_key(type, _gamesWonKey), stats.gamesWon);
    await prefs.setInt(_key(type, _gamesLostKey), stats.gamesLost);
    await prefs.setInt(_key(type, _currentStreakKey), stats.currentStreak);
    await prefs.setInt(_key(type, _bestStreakKey), stats.bestStreak);
    await prefs.setInt(_key(type, _vegasCumulativeScoreKey), stats.vegasCumulativeScore);

    if (stats.bestTime != null) {
      await prefs.setInt(_key(type, _bestTimeKey), stats.bestTime!.inMilliseconds);
    }

    if (stats.fewestMoves != null) {
      await prefs.setInt(_key(type, _fewestMovesKey), stats.fewestMoves!);
    }

    if (stats.vegasHighScore != null) {
      await prefs.setInt(_key(type, _vegasHighScoreKey), stats.vegasHighScore!);
    }
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
    final prefs = await SharedPreferences.getInstance();
    final type = _currentGameType;

    await prefs.remove(_key(type, _gamesPlayedKey));
    await prefs.remove(_key(type, _gamesWonKey));
    await prefs.remove(_key(type, _gamesLostKey));
    await prefs.remove(_key(type, _currentStreakKey));
    await prefs.remove(_key(type, _bestStreakKey));
    await prefs.remove(_key(type, _bestTimeKey));
    await prefs.remove(_key(type, _fewestMovesKey));
    await prefs.remove(_key(type, _vegasCumulativeScoreKey));
    await prefs.remove(_key(type, _vegasHighScoreKey));

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
}
