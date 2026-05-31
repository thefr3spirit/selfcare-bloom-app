import 'package:hive/hive.dart';

part 'stressor.g.dart';

/// Stressor with severity rating
@HiveType(typeId: 2)
class Stressor extends HiveObject {
  @HiveField(0)
  String type;

  @HiveField(1)
  int severity; // 1-10

  @HiveField(2)
  DateTime recordedAt;

  Stressor({
    required this.type,
    required this.severity,
    required this.recordedAt,
  });

  bool get isSevere => severity >= 8;
}

/// Predefined stressor types from questionnaire
class StressorTypes {
  static const List<String> all = [
    'Long working hours',
    'Heavy workload',
    'Academic pressure',
    'Financial difficulties',
    'Poor sleep',
    'Poor eating habits',
    'Health problems',
    'Relationship issues',
    'Family responsibilities',
    'Work environment',
    'Lack of personal time',
    'Social media',
  ];

  /// Get icon for each stressor type
  static String getIcon(String type) {
    switch (type) {
      case 'Financial difficulties':
        return '💰';
      case 'Lack of personal time':
        return '⏰';
      case 'Academic pressure':
        return '📚';
      case 'Work environment':
        return '🏢';
      case 'Relationship issues':
        return '💔';
      case 'Poor eating habits':
        return '🍔';
      case 'Poor sleep':
        return '😴';
      case 'Health problems':
        return '🏥';
      case 'Long working hours':
        return '⏱️';
      case 'Heavy workload':
        return '📊';
      case 'Family responsibilities':
        return '👨‍👩‍👧‍👦';
      case 'Social media':
        return '📱';
      default:
        return '⚠️';
    }
  }
}
