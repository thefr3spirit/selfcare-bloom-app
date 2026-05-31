import 'package:hive/hive.dart';

part 'app_settings.g.dart';

/// App settings and configuration
@HiveType(typeId: 5)
class AppSettings extends HiveObject {
  @HiveField(0)
  bool notificationsEnabled;

  @HiveField(1)
  int reassessmentIntervalDays; // Default: 2 days for pilot

  @HiveField(2)
  int notificationHour; // Default: 20 (8 PM)

  @HiveField(3)
  int notificationMinute; // Default: 0

  @HiveField(4)
  DateTime? lastAssessmentDate;

  @HiveField(5)
  DateTime? nextAssessmentDue;

  @HiveField(6)
  int totalAssessmentsCompleted;

  @HiveField(7)
  List<String> crisisEventsLog; // Timestamps of crisis detections

  AppSettings({
    this.notificationsEnabled = true,
    this.reassessmentIntervalDays = 2,
    this.notificationHour = 20,
    this.notificationMinute = 0,
    this.lastAssessmentDate,
    this.nextAssessmentDue,
    this.totalAssessmentsCompleted = 0,
    List<String>? crisisEventsLog,
  }) : crisisEventsLog = crisisEventsLog ?? [];

  void recordAssessment() {
    lastAssessmentDate = DateTime.now();
    nextAssessmentDue = DateTime.now().add(
      Duration(days: reassessmentIntervalDays),
    );
    totalAssessmentsCompleted++;
    // Note: Call saveSettings() after this method to persist changes
  }

  void logCrisisEvent() {
    crisisEventsLog.add(DateTime.now().toIso8601String());
    // Note: Call saveSettings() after this method to persist changes
  }

  bool get isAssessmentDue {
    if (nextAssessmentDue == null) return true;
    return DateTime.now().isAfter(nextAssessmentDue!);
  }

  int get daysUntilNextAssessment {
    if (nextAssessmentDue == null) return 0;
    final difference = nextAssessmentDue!.difference(DateTime.now());
    return difference.inDays;
  }
}
