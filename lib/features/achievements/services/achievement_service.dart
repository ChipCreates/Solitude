import 'package:hive/hive.dart';
import '../models/achievement.dart';
import '../models/achievement_category.dart';
import 'package:flutter/foundation.dart';

import 'dart:convert';
import 'package:flutter/services.dart';

class AchievementService {
  static const String _boxName = 'achievements';
  Box<Achievement>? _achievementBox;

  // Track session data for achievements
  int _sessionMoveCount = 0;
  bool _sessionUsedUndo = false;
  bool _sessionUsedHint = false;

  Future<void> initialize() async {
    _achievementBox = await Hive.openBox<Achievement>(_boxName);
    await loadDefaults();
  }

  bool get _isInitialized => _achievementBox != null;

  Future<void> unlock(String id) async {
    if (!_isInitialized) return;

    final achievement = _achievementBox!.get(id);
    if (achievement != null && !achievement.isUnlocked) {
      final updatedAchievement = achievement.copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
      await _achievementBox!.put(id, updatedAchievement);
      debugPrint('Achievement unlocked: ${achievement.title}');
    }
  }

  /// Get all achievements
  List<Achievement> getAllAchievements() {
    if (!_isInitialized) return [];
    return _achievementBox!.values.toList();
  }

  /// Get unlocked achievements
  List<Achievement> getUnlockedAchievements() {
    if (!_isInitialized) return [];
    return _achievementBox!.values.where((a) => a.isUnlocked).toList();
  }

  /// Reset session tracking when a new game starts
  void resetSessionTracking() {
    _sessionMoveCount = 0;
    _sessionUsedUndo = false;
    _sessionUsedHint = false;
  }

  void dispose() {
    _achievementBox?.close();
  }

  Future<void> loadDefaults() async {
    if (!_isInitialized) return;

    try {
      final jsonString =
          await rootBundle.loadString('assets/data/achievements.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final achievementsData = jsonData['achievements'] as List<dynamic>;

      for (final achievementData in achievementsData) {
        final achievement = Achievement(
          id: achievementData['id'] as String,
          title: achievementData['title'] as String,
          description: achievementData['description'] as String,
          iconPath: achievementData['icon'] ?? 'assets/solitude-logo.svg',
          category: _parseCategory(achievementData['category'] as String),
          targetValue: achievementData['targetValue'] ?? 1,
          criteria: achievementData['criteria'] as Map<String, dynamic>,
        );

        if (!_achievementBox!.containsKey(achievement.id)) {
          await _achievementBox!.put(achievement.id, achievement);
        }
      }
    } catch (e) {
      debugPrint('Failed to load achievements.json: $e');
      // Fallback to hardcoded defaults if JSON loading fails
      await _loadFallbackDefaults();
    }
  }

  AchievementCategory _parseCategory(String categoryString) {
    switch (categoryString) {
      case 'speed':
        return AchievementCategory.speed;
      case 'efficiency':
        return AchievementCategory.efficiency;
      case 'streak':
        return AchievementCategory.streak;
      case 'milestone':
        return AchievementCategory.milestone;
      case 'special':
        return AchievementCategory.special;
      default:
        return AchievementCategory.milestone;
    }
  }

  Future<void> _loadFallbackDefaults() async {
    if (!_isInitialized) return;

    final defaults = [
      Achievement(
        id: 'first_win',
        title: 'First Victory',
        description: 'Win your first game',
        iconPath: 'assets/badges/first_win.svg',
        category: AchievementCategory.milestone,
        targetValue: 1,
        criteria: {'wins': 1},
      ),
    ];

    for (final achievement in defaults) {
      if (!_achievementBox!.containsKey(achievement.id)) {
        await _achievementBox!.put(achievement.id, achievement);
      }
    }
  }

  /// Check win-related achievements
  /// gameData should contain: {time, moves, streak, usedUndo, usedHint}
  Future<void> checkWinAchievements(dynamic gameData) async {
    if (!_isInitialized) return;
    if (gameData == null || gameData is! Map<String, dynamic>) return;

    final time = gameData['time'] as Duration?;
    final moves = gameData['moves'] as int?;
    final streak = gameData['streak'] as int?;
    final usedUndo = gameData['usedUndo'] as bool? ?? _sessionUsedUndo;
    final usedHint = gameData['usedHint'] as bool? ?? _sessionUsedHint;

    // Check all achievements
    for (final achievement in _achievementBox!.values) {
      if (achievement.isUnlocked) continue;

      bool shouldUnlock = false;

      // Evaluate based on achievement type
      switch (achievement.id) {
        case 'first_win':
          // Check if this is their first win (criteria: wins >= 1)
          shouldUnlock = _evaluateCriteria(achievement.criteria, {
            'wins': 1,
          });
          break;

        case 'speed_demon':
          // Win in under specified time (criteria: maxTime in seconds)
          if (time != null) {
            final maxTime = achievement.criteria['maxTime'] as int?;
            if (maxTime != null) {
              shouldUnlock = time.inSeconds <= maxTime;
            }
          }
          break;

        case 'efficiency_expert':
          // Win with fewer than specified moves (criteria: maxMoves)
          if (moves != null) {
            final maxMoves = achievement.criteria['maxMoves'] as int?;
            if (maxMoves != null) {
              shouldUnlock = moves < maxMoves;
            }
          }
          break;

        case 'streak_5':
          // Win streak achievement (criteria: targetValue for streak count)
          if (streak != null) {
            shouldUnlock = streak >= achievement.targetValue;
          }
          break;

        case 'perfect_game':
          // Win without using undo or hints
          if (!usedUndo && !usedHint) {
            shouldUnlock = true;
          }
          break;

        default:
          // Generic criteria evaluation
          shouldUnlock = _evaluateCriteria(achievement.criteria, gameData);
          break;
      }

      if (shouldUnlock) {
        await unlock(achievement.id);
      }
    }

    // Reset session tracking after checking
    resetSessionTracking();
  }

  /// Evaluate achievement criteria against provided data
  bool _evaluateCriteria(
      Map<String, dynamic> criteria, Map<String, dynamic> data) {
    if (criteria.isEmpty) return false;

    for (final entry in criteria.entries) {
      final key = entry.key;
      final requiredValue = entry.value;

      if (!data.containsKey(key)) return false;

      final actualValue = data[key];

      // Handle different comparison types
      if (requiredValue is int && actualValue is int) {
        if (actualValue < requiredValue) return false;
      } else if (requiredValue is double && actualValue is num) {
        if (actualValue < requiredValue) return false;
      } else if (requiredValue is bool && actualValue is bool) {
        if (actualValue != requiredValue) return false;
      }
    }

    return true;
  }

  /// Track move count for efficiency achievements
  Future<void> incrementMoveCount() async {
    _sessionMoveCount++;

    // Update progress for move-based achievements
    await _updateMoveProgress();
  }

  /// Track undo usage for perfect game achievement
  void trackUndoUsed() {
    _sessionUsedUndo = true;
  }

  /// Track hint usage for perfect game achievement
  void trackHintUsed() {
    _sessionUsedHint = true;
  }

  /// Update progress for move-based achievements
  Future<void> _updateMoveProgress() async {
    // Could be extended to track cumulative move counts across games
    // For now, move tracking is per-session and checked on win
  }

  /// Update progress for an achievement (for gradual achievements)
  Future<void> updateProgress(String achievementId, int progress) async {
    if (!_isInitialized) return;

    final achievement = _achievementBox!.get(achievementId);
    if (achievement != null && !achievement.isUnlocked) {
      final updatedAchievement = achievement.copyWith(
        currentProgress: progress,
      );
      await _achievementBox!.put(achievementId, updatedAchievement);

      // Check if target reached
      if (progress >= achievement.targetValue) {
        await unlock(achievementId);
      }
    }
  }

  /// Increment progress for an achievement
  Future<void> incrementProgress(String achievementId, {int amount = 1}) async {
    if (!_isInitialized) return;

    final achievement = _achievementBox!.get(achievementId);
    if (achievement != null && !achievement.isUnlocked) {
      final newProgress = achievement.currentProgress + amount;
      await updateProgress(achievementId, newProgress);
    }
  }
}
