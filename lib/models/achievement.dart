import 'package:hive/hive.dart';

part 'achievement.g.dart';

/// User achievements and badges for gamification
@HiveType(typeId: 7)
class Achievement extends HiveObject {
  @HiveField(0)
  final String achievementId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String icon; // emoji

  @HiveField(4)
  final AchievementType type;

  @HiveField(5)
  final int requiredCount;

  @HiveField(6)
  int currentProgress;

  @HiveField(7)
  bool isUnlocked;

  @HiveField(8)
  DateTime? unlockedAt;

  Achievement({
    required this.achievementId,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.requiredCount,
    this.currentProgress = 0,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  /// Progress percentage (0-100)
  double get progressPercentage {
    return (currentProgress / requiredCount * 100).clamp(0.0, 100.0);
  }

  /// Increment progress
  void incrementProgress({int amount = 1}) {
    currentProgress += amount;
    if (currentProgress >= requiredCount && !isUnlocked) {
      unlock();
    }
    save();
  }

  /// Unlock achievement
  void unlock() {
    isUnlocked = true;
    unlockedAt = DateTime.now();
    save();
  }

  @override
  String toString() {
    return 'Achievement($title: $currentProgress/$requiredCount, unlocked: $isUnlocked)';
  }
}

@HiveType(typeId: 8)
enum AchievementType {
  @HiveField(0)
  assessmentStreak, // Complete X assessments in a row

  @HiveField(1)
  assessmentCount, // Complete X assessments total

  @HiveField(2)
  stressReduction, // Reduce PSS by X points

  @HiveField(3)
  recommendationCompletion, // Complete X recommendations

  @HiveField(4)
  consistency, // Use app X weeks in a row

  @HiveField(5)
  explorer, // View X different recommendations
}

/// Predefined achievements
class AchievementDefinitions {
  static List<Achievement> getAll() {
    return [
      // Assessment achievements
      Achievement(
        achievementId: 'first_assessment',
        title: '🌱 First Step',
        description: 'Complete your first stress assessment',
        icon: '🌱',
        type: AchievementType.assessmentCount,
        requiredCount: 1,
      ),
      Achievement(
        achievementId: 'assessment_5',
        title: '🔥 Getting Started',
        description: 'Complete 5 stress assessments',
        icon: '🔥',
        type: AchievementType.assessmentCount,
        requiredCount: 5,
      ),
      Achievement(
        achievementId: 'assessment_10',
        title: '⭐ Committed',
        description: 'Complete 10 stress assessments',
        icon: '⭐',
        type: AchievementType.assessmentCount,
        requiredCount: 10,
      ),
      Achievement(
        achievementId: 'assessment_20',
        title: '🏆 Stress Warrior',
        description: 'Complete 20 stress assessments',
        icon: '🏆',
        type: AchievementType.assessmentCount,
        requiredCount: 20,
      ),

      // Consistency achievements
      Achievement(
        achievementId: 'weekly_check_in',
        title: '📅 Weekly Warrior',
        description: 'Check in every week for 4 weeks',
        icon: '📅',
        type: AchievementType.consistency,
        requiredCount: 4,
      ),
      Achievement(
        achievementId: 'monthly_consistency',
        title: '💪 Monthly Master',
        description: 'Check in consistently for 8 weeks',
        icon: '💪',
        type: AchievementType.consistency,
        requiredCount: 8,
      ),

      // Stress reduction achievements
      Achievement(
        achievementId: 'stress_down_5',
        title: '🌤️ Feeling Better',
        description: 'Reduce your stress by 5 points',
        icon: '🌤️',
        type: AchievementType.stressReduction,
        requiredCount: 5,
      ),
      Achievement(
        achievementId: 'stress_down_10',
        title: '☀️ Major Progress',
        description: 'Reduce your stress by 10 points',
        icon: '☀️',
        type: AchievementType.stressReduction,
        requiredCount: 10,
      ),

      // Recommendation achievements
      Achievement(
        achievementId: 'rec_complete_3',
        title: '✅ Action Taker',
        description: 'Complete 3 recommendations',
        icon: '✅',
        type: AchievementType.recommendationCompletion,
        requiredCount: 3,
      ),
      Achievement(
        achievementId: 'rec_complete_10',
        title: '🎯 Self-Care Pro',
        description: 'Complete 10 recommendations',
        icon: '🎯',
        type: AchievementType.recommendationCompletion,
        requiredCount: 10,
      ),

      // Exploration achievements
      Achievement(
        achievementId: 'explorer',
        title: '🔍 Explorer',
        description: 'Try 5 different types of stress management',
        icon: '🔍',
        type: AchievementType.explorer,
        requiredCount: 5,
      ),
    ];
  }
}
