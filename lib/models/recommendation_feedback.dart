import 'package:hive/hive.dart';

part 'recommendation_feedback.g.dart';

/// Tracks user feedback and engagement with recommendations
@HiveType(typeId: 6)
class RecommendationFeedback extends HiveObject {
  @HiveField(0)
  final String feedbackId;

  @HiveField(1)
  final String recommendationId;

  @HiveField(2)
  final String recommendationType;

  @HiveField(3)
  final String recommendationTitle;

  @HiveField(4)
  final DateTime viewedAt;

  @HiveField(5)
  DateTime? completedAt;

  @HiveField(6)
  int? helpfulnessRating; // 1-5 scale

  @HiveField(7)
  bool wasCompleted;

  @HiveField(8)
  int? pssBeforeAction;

  @HiveField(9)
  int? pssAfterAction;

  @HiveField(10)
  String? userNotes;

  @HiveField(11)
  final DateTime createdAt;

  RecommendationFeedback({
    required this.feedbackId,
    required this.recommendationId,
    required this.recommendationType,
    required this.recommendationTitle,
    required this.viewedAt,
    this.completedAt,
    this.helpfulnessRating,
    this.wasCompleted = false,
    this.pssBeforeAction,
    this.pssAfterAction,
    this.userNotes,
    required this.createdAt,
  });

  /// Create new feedback instance
  factory RecommendationFeedback.create({
    required String recommendationId,
    required String recommendationType,
    required String recommendationTitle,
    int? currentPssScore,
  }) {
    final now = DateTime.now();
    return RecommendationFeedback(
      feedbackId: now.millisecondsSinceEpoch.toString(),
      recommendationId: recommendationId,
      recommendationType: recommendationType,
      recommendationTitle: recommendationTitle,
      viewedAt: now,
      wasCompleted: false,
      pssBeforeAction: currentPssScore,
      createdAt: now,
    );
  }

  /// Mark recommendation as completed
  void markCompleted({int? pssAfterAction}) {
    wasCompleted = true;
    completedAt = DateTime.now();
    this.pssAfterAction = pssAfterAction;
    save();
  }

  /// Add helpfulness rating
  void rate(int rating, {String? notes}) {
    helpfulnessRating = rating;
    userNotes = notes;
    save();
  }

  /// Calculate effectiveness (PSS reduction)
  int? get effectiveness {
    if (pssBeforeAction != null && pssAfterAction != null) {
      return pssBeforeAction! - pssAfterAction!;
    }
    return null;
  }

  /// Check if this was viewed recently (within 7 days)
  bool get isRecent {
    return DateTime.now().difference(viewedAt).inDays <= 7;
  }

  /// Convert to map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'feedbackId': feedbackId,
      'recommendationId': recommendationId,
      'recommendationType': recommendationType,
      'recommendationTitle': recommendationTitle,
      'viewedAt': viewedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'helpfulnessRating': helpfulnessRating,
      'wasCompleted': wasCompleted,
      'pssBeforeAction': pssBeforeAction,
      'pssAfterAction': pssAfterAction,
      'userNotes': userNotes,
      'effectiveness': effectiveness,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'RecommendationFeedback('
        'id: $feedbackId, '
        'recommendation: $recommendationTitle, '
        'completed: $wasCompleted, '
        'helpful: $helpfulnessRating/5, '
        'effectiveness: ${effectiveness ?? "N/A"})';
  }
}
