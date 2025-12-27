import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _gamesPlayedKey = 'gamesPlayed';
  static const String _gamesWonKey = 'gamesWon';
  static const String _currentStreakKey = 'currentStreak';
  static const String _bestStreakKey = 'bestStreak';
  static const String _bestTimeKey = 'bestTime';
  static const String _fewestMovesKey = 'fewestMoves';
  static const String _gamesLostKey = 'gamesLost';
  static const String _vegasCumulativeScoreKey = 'vegasCumulativeScore';
  static const String _vegasHighScoreKey = 'vegasHighScore';
  
  Statistics _statistics = const Statistics();
  
  Statistics get statistics => _statistics;
  
  Future<void> loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();

    final bestTimeMs = prefs.getInt(_bestTimeKey);
    final fewestMoves = prefs.getInt(_fewestMovesKey);
    final vegasHighScore = prefs.getInt(_vegasHighScoreKey);

    _statistics = Statistics(
      gamesPlayed: prefs.getInt(_gamesPlayedKey) ?? 0,
      gamesWon: prefs.getInt(_gamesWonKey) ?? 0,
      gamesLost: prefs.getInt(_gamesLostKey) ?? 0,
      currentStreak: prefs.getInt(_currentStreakKey) ?? 0,
      bestStreak: prefs.getInt(_bestStreakKey) ?? 0,
      bestTime: bestTimeMs != null ? Duration(milliseconds: bestTimeMs) : null,
      fewestMoves: fewestMoves,
      vegasCumulativeScore: prefs.getInt(_vegasCumulativeScoreKey) ?? 0,
      vegasHighScore: vegasHighScore,
    );

    notifyListeners();
  }
  
  Future<void> _saveStatistics() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_gamesPlayedKey, _statistics.gamesPlayed);
    await prefs.setInt(_gamesWonKey, _statistics.gamesWon);
    await prefs.setInt(_gamesLostKey, _statistics.gamesLost);
    await prefs.setInt(_currentStreakKey, _statistics.currentStreak);
    await prefs.setInt(_bestStreakKey, _statistics.bestStreak);
    await prefs.setInt(_vegasCumulativeScoreKey, _statistics.vegasCumulativeScore);

    if (_statistics.bestTime != null) {
      await prefs.setInt(_bestTimeKey, _statistics.bestTime!.inMilliseconds);
    }

    if (_statistics.fewestMoves != null) {
      await prefs.setInt(_fewestMovesKey, _statistics.fewestMoves!);
    }

    if (_statistics.vegasHighScore != null) {
      await prefs.setInt(_vegasHighScoreKey, _statistics.vegasHighScore!);
    }
  }
  
  Future<void> recordGameStarted() async {
    _statistics = _statistics.copyWith(
      gamesPlayed: _statistics.gamesPlayed + 1,
    );
    await _saveStatistics();
    notifyListeners();
  }
  
  Future<void> recordWin({required Duration time, required int moves}) async {
    final newStreak = _statistics.currentStreak + 1;
    final newBestStreak = newStreak > _statistics.bestStreak 
        ? newStreak 
        : _statistics.bestStreak;
    
    Duration? newBestTime = _statistics.bestTime;
    if (newBestTime == null || time < newBestTime) {
      newBestTime = time;
    }
    
    int? newFewestMoves = _statistics.fewestMoves;
    if (newFewestMoves == null || moves < newFewestMoves) {
      newFewestMoves = moves;
    }
    
    _statistics = _statistics.copyWith(
      gamesWon: _statistics.gamesWon + 1,
      currentStreak: newStreak,
      bestStreak: newBestStreak,
      bestTime: newBestTime,
      fewestMoves: newFewestMoves,
    );
    
    await _saveStatistics();
    notifyListeners();
  }
  
  Future<void> recordLoss() async {
    _statistics = _statistics.copyWith(
      currentStreak: 0,
      gamesLost: _statistics.gamesLost + 1,
    );
    await _saveStatistics();
    notifyListeners();
  }

  /// Record Vegas scoring for a game
  Future<void> recordVegasScore(int score) async {
    int? newHighScore = _statistics.vegasHighScore;
    if (newHighScore == null || score > newHighScore) {
      newHighScore = score;
    }

    _statistics = _statistics.copyWith(
      vegasCumulativeScore: _statistics.vegasCumulativeScore + score,
      vegasHighScore: newHighScore,
    );

    await _saveStatistics();
    notifyListeners();
  }
  
  Future<void> resetStatistics() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_gamesPlayedKey);
    await prefs.remove(_gamesWonKey);
    await prefs.remove(_gamesLostKey);
    await prefs.remove(_currentStreakKey);
    await prefs.remove(_bestStreakKey);
    await prefs.remove(_bestTimeKey);
    await prefs.remove(_fewestMovesKey);
    await prefs.remove(_vegasCumulativeScoreKey);
    await prefs.remove(_vegasHighScoreKey);

    _statistics = const Statistics();
    notifyListeners();
  }
  
  String formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
