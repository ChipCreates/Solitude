import 'package:hive/hive.dart';
import 'achievement_category.dart';

part 'achievement.g.dart';

@HiveType(typeId: 0)
class Achievement extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String iconPath;

  @HiveField(4)
  final AchievementCategory category;

  @HiveField(5)
  final int targetValue;

  @HiveField(6)
  final Map<String, dynamic> criteria;

  @HiveField(7)
  bool isUnlocked;

  @HiveField(8)
  DateTime? unlockedAt;

  @HiveField(9)
  int currentProgress;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.category,
    required this.targetValue,
    required this.criteria,
    this.isUnlocked = false,
    this.unlockedAt,
    this.currentProgress = 0,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconPath,
    AchievementCategory? category,
    int? targetValue,
    Map<String, dynamic>? criteria,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? currentProgress,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      category: category ?? this.category,
      targetValue: targetValue ?? this.targetValue,
      criteria: criteria ?? this.criteria,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      currentProgress: currentProgress ?? this.currentProgress,
    );
  }
}