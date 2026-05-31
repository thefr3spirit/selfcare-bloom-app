import 'package:hive/hive.dart';

part 'coping_strategy.g.dart';

/// Coping strategy with effectiveness rating
@HiveType(typeId: 3)
class CopingStrategy extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String frequency; // daily, weekly, 2-3x per week, etc.

  @HiveField(2)
  String
      effectivenessRating; // Very effective, Somewhat effective, Neutral, Not effective

  @HiveField(3)
  DateTime recordedAt;

  CopingStrategy({
    required this.name,
    required this.frequency,
    required this.effectivenessRating,
    required this.recordedAt,
  });

  bool get isEffective =>
      effectivenessRating.contains('effective') &&
      !effectivenessRating.contains('Not');
  bool get isIneffective => effectivenessRating.contains('Not effective');
  bool get isPassive => _passiveStrategies.contains(name);

  static const List<String> _passiveStrategies = [
    'Watching movies/entertainment',
    'Sleeping/resting',
    'Listening to music',
  ];
}

/// Predefined coping strategies from questionnaire
class CopingStrategyTypes {
  static const List<String> all = [
    'Exercise',
    'Meditation/prayer',
    'Talking to friends/family',
    'Watching movies/entertainment',
    'Sleeping/resting',
    'Listening to music',
    'Journaling',
    'Therapy/counseling',
  ];

  static const List<String> frequencies = [
    'Daily',
    '4-6x per week',
    '2-3x per week',
    'Once a week',
    'Occasionally',
    'Rarely',
  ];

  static const List<String> effectiveness = [
    'Very effective',
    'Somewhat effective',
    'Neutral',
    'Not very effective',
  ];

  /// Get icon for each strategy
  static String getIcon(String strategy) {
    switch (strategy) {
      case 'Therapy/counseling':
        return '🏥';
      case 'Journaling':
        return '📝';
      case 'Exercise':
        return '🏃';
      case 'Talking to friends/family':
        return '🤝';
      case 'Meditation/prayer':
        return '🧘';
      case 'Watching movies/entertainment':
        return '📺';
      case 'Sleeping/resting':
        return '😴';
      case 'Listening to music':
        return '🎵';
      default:
        return '✨';
    }
  }
}
