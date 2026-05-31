import 'package:hive/hive.dart';

part 'pss_assessment.g.dart';

/// PSS-10 Assessment Model
/// Stores individual assessment with calculated score and category
@HiveType(typeId: 1)
class PSSAssessment extends HiveObject {
  @HiveField(0)
  String assessmentId;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  List<int> responses; // 10 answers (0-4) for questions 0-9

  @HiveField(3)
  int totalScore; // 0-40

  @HiveField(4)
  String category; // LOW, MODERATE, HIGH

  @HiveField(5)
  bool isCrisis; // PSS > 26

  PSSAssessment({
    required this.assessmentId,
    required this.date,
    required this.responses,
    required this.totalScore,
    required this.category,
    required this.isCrisis,
  });

  factory PSSAssessment.fromResponses(Map<int, int> responsesMap) {
    // Convert map to list (index = question number)
    final responses = List<int>.filled(10, 0);
    responsesMap.forEach((question, answer) {
      if (question >= 0 && question < 10) {
        responses[question] = answer;
      }
    });

    // Calculate total score
    // Questions 4, 5, 7, 8 are reversed (need to subtract from 4)
    final reversedQuestions = {4, 5, 7, 8};
    int total = 0;

    for (int i = 0; i < responses.length; i++) {
      if (reversedQuestions.contains(i)) {
        total += (4 - responses[i]);
      } else {
        total += responses[i];
      }
    }

    // Determine category
    String category;
    if (total <= 13) {
      category = 'LOW';
    } else if (total <= 26) {
      category = 'MODERATE';
    } else {
      category = 'HIGH';
    }

    return PSSAssessment(
      assessmentId: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      responses: responses,
      totalScore: total,
      category: category,
      isCrisis: total > 26,
    );
  }

  /// Get individual response by question number (0-9)
  int? getResponse(int questionNumber) {
    if (questionNumber >= 0 && questionNumber < responses.length) {
      return responses[questionNumber];
    }
    return null;
  }
}

/// PSS-10 Questions (for UI display)
class PSSQuestions {
  static const String introText =
      'Over the last 4 weeks (30 days), how frequent have you experienced the following:';

  static const List<String> questions = [
    'How frequent was it that something annoying and unexpected disrupted your plans?',
    'How frequent was it that you felt important things in your life were beyond your control?',
    'How frequent was it that you felt tense, nervous, or stressed?',
    'How frequent was it that you felt confident in handling personal challenges?',
    'How frequent was it that you felt things were going according to your plans?',
    'How frequent was it that you felt overwhelmed by everything you had to do?',
    'How frequent was it that you were able to stay calm when frustrating situations occurred?',
    'How frequent was it that you felt in control of your daily responsibilities and commitments?',
    'How frequent was it that you felt annoyed because certain things seemed uncontrollable?',
    'How frequent was it that you felt work and other commitments were piling up faster than you could handle them?',
  ];

  static const List<String> answerOptions = [
    'Never',
    'Almost Never',
    'Sometimes',
    'Fairly Often',
    'Very Often',
  ];
}
