import 'package:hive/hive.dart';
import '../models/achievement.dart';
import '../models/achievement_category.dart';

import 'dart:convert';
import 'package:flutter/services.dart';

class AchievementService {
  static const String _boxName = 'achievements';
  late Box<Achievement> _achievementBox;

  Future<void> initialize() async {
    _achievementBox = await Hive.openBox<Achievement>(_boxName);
    await loadDefaults();
  }

  Future<void> unlock(String id) async {
    final achievement = _achievementBox.get(id);
    if (achievement != null && !achievement.isUnlocked) {
      final updatedAchievement = achievement.copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
      await _achievementBox.put(id, updatedAchievement);
    }
  }

  void dispose() {
    _achievementBox.close();
  }

  Future<void> loadDefaults() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/achievements.json');
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

        if (!_achievementBox.containsKey(achievement.id)) {
          await _achievementBox.put(achievement.id, achievement);
        }
      }
    } catch (e) {
      // Fallback to hardcoded defaults if JSON loading fails
      await _loadFallbackDefaults();
    }
  }

  AchievementCategory _parseCategory(String categoryString) {
    switch (categoryString) {
      case 'speed': return AchievementCategory.speed;
      case 'efficiency': return AchievementCategory.efficiency;
      case 'streak': return AchievementCategory.streak;
      case 'milestone': return AchievementCategory.milestone;
      case 'special': return AchievementCategory.special;
      default: return AchievementCategory.milestone;
    }
  }

  Future<void> _loadFallbackDefaults() async {
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
      if (!_achievementBox.containsKey(achievement.id)) {
        await _achievementBox.put(achievement.id, achievement);
      }
    }
  }

  Future<void> checkWinAchievements(dynamic gameData) async {
    // Implementation for checking win-related achievements
    // This would be expanded based on game statistics
  }

  Future<void> incrementMoveCount() async {
    // Implementation for move-based achievements
    // This would track move counts and check efficiency achievements
  }
}