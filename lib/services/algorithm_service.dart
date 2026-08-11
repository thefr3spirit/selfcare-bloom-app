import 'dart:math';

import '../models/coping_strategy.dart';
import '../models/pss_assessment.dart';
import '../models/recommendation.dart';
import '../models/stressor.dart';

/// Rule-based Recommendation Algorithm Service
/// Ported from Python recommendation_engine.py
///
/// Implements 8 core rules:
/// 1. Crisis Detection & Response
/// 2. Financial Stress Priority
/// 3. Lack of Personal Time Warning
/// 4. Protective Strategy Promotion (with exercise prioritized)
/// 5. Passive Coping Detection
/// 6. Increase Frequency for Effective Strategies
/// 7. Active Coping for Moderate-High Stress (PSS > 25)
/// 8. Physical Social Interaction for Stress Relief (PSS > 25)
class AlgorithmService {
  // Evidence-based PSS impact values (from research)
  static const Map<String, double> stressorPssImpact = {
    'Financial difficulties': 5.0,
    'Lack of personal time': 1.5,
    'Academic pressure': 1.0,
    'Work environment': 0.9,
    'Relationship issues': 0.8,
    'Poor eating habits': 0.8,
    'Poor sleep': 0.7,
    'Health problems': -2.4, // Protective (people managing health actively)
    'Long working hours': 1.2,
    'Heavy workload': 1.1,
    'Family responsibilities': 0.9,
    'Social media': 0.6,
  };

  // Evidence-based strategy effectiveness (PSS reduction)
  static const Map<String, double> strategyPssReduction = {
    'Therapy/counseling': -5.8, // Most effective
    'Journaling': -2.9,
    'Talking to friends/family': -2.0,
    'Exercise': -1.6,
    'Meditation/prayer': -1.4,
    'Watching movies/entertainment': 0.0, // Passive (no long-term benefit)
    'Sleeping/resting': 0.0, // Passive
    'Listening to music': -0.5, // Slight benefit
  };

  /// Generate personalized recommendations
  /// Returns list of recommendations sorted by priority
  List<Recommendation> generateRecommendations({
    required PSSAssessment assessment,
    required List<Stressor> stressors,
    required List<CopingStrategy> copingStrategies,
    int maxRecommendations = 5,
  }) {
    final recommendations = <Recommendation>[];

    // Calculate risk score
    final riskScore = calculateRiskScore(
      assessment: assessment,
      stressors: stressors,
      copingStrategies: copingStrategies,
    );

    // Check if crisis
    final isCrisis = detectCrisis(
      assessment: assessment,
      stressors: stressors,
      riskScore: riskScore,
    );

    // Rule 1: Crisis Detection
    if (isCrisis) {
      recommendations.addAll(_crisisInterventions(assessment, riskScore));
      return recommendations.take(maxRecommendations).toList();
    }

    // Rule 2: Financial Stress Priority
    final financialStressor = stressors.firstWhere(
      (s) => s.type == 'Financial difficulties',
      orElse: () => Stressor(type: '', severity: 0, recordedAt: DateTime.now()),
    );
    if (financialStressor.severity >= 5) {
      recommendations.add(
        _financialStressIntervention(assessment, financialStressor),
      );
    }

    // Rule 3: Lack of Personal Time Warning
    final personalTimeStressor = stressors.firstWhere(
      (s) => s.type == 'Lack of personal time',
      orElse: () => Stressor(type: '', severity: 0, recordedAt: DateTime.now()),
    );
    if (personalTimeStressor.severity >= 5) {
      recommendations.add(
        _personalTimeIntervention(assessment, personalTimeStressor),
      );
    }

    // Rule 4: Protective Strategy Promotion
    final missingStrategies = _getMissingProtectiveStrategies(copingStrategies);
    recommendations.addAll(
      _promoteProtectiveStrategies(
        assessment,
        missingStrategies,
        copingStrategies,
      ),
    );

    // Rule 5: Passive Coping Detection
    final passiveRatio = _calculatePassiveCopingRatio(copingStrategies);
    if (passiveRatio > 0.6) {
      recommendations.add(
        _behavioralShiftRecommendation(assessment, passiveRatio),
      );
    }

    // Rule 6: Effective but infrequent coping strategies
    final infrequentEffective =
        _getInfrequentEffectiveStrategies(copingStrategies);
    if (infrequentEffective.isNotEmpty) {
      for (var strategy in infrequentEffective) {
        recommendations.add(
          _increaseFrequencyRecommendation(assessment, strategy),
        );
      }
    }

    // Rule 7: Always recommend active coping for moderate-high stress (PSS > 25)
    if (assessment.totalScore > 25) {
      final lacksActiveCoping = _lacksActiveCoping(copingStrategies);
      if (lacksActiveCoping) {
        recommendations.add(
          _activeCopingRecommendation(assessment, copingStrategies),
        );
      }
    }

    // Rule 8: Recommend physical social interaction at least once a week for PSS > 25
    if (assessment.totalScore > 25) {
      recommendations.add(
        _physicalInteractionRecommendation(assessment),
      );
    }

    // Add stressor-specific interventions (lowered threshold to severity >= 5)
    for (var stressor in stressors) {
      if (stressor.severity >= 5) {
        final intervention = _stressorIntervention(assessment, stressor);
        if (intervention != null) {
          recommendations.add(intervention);
        }
      }
    }

    // Include one contextual micro-intervention (quick win)
    recommendations.add(getContextualMicroIntervention(assessment));

    // Calculate priorities and sort
    for (var rec in recommendations) {
      final priority = _calculatePriority(
        recommendation: rec,
        assessment: assessment,
        stressors: stressors,
        copingStrategies: copingStrategies,
      );
      // Update priority (create new instance since priority is final)
      final index = recommendations.indexOf(rec);
      recommendations[index] = Recommendation(
        recommendationId: rec.recommendationId,
        generatedAt: rec.generatedAt,
        type: rec.type,
        priorityScore: priority,
        title: rec.title,
        message: rec.message,
        actions: rec.actions,
        evidenceBasis: rec.evidenceBasis,
        resources: rec.resources,
        isCrisisRecommendation: rec.isCrisisRecommendation,
      );
    }

    // Remove duplicates by title
    final seen = <String>{};
    final deduplicated = <Recommendation>[];
    for (var rec in recommendations) {
      if (!seen.contains(rec.title)) {
        seen.add(rec.title);
        deduplicated.add(rec);
      }
    }

    // Sort by priority
    deduplicated.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

    // Limit micro-interventions to max 1
    int microCount = 0;
    final filtered = <Recommendation>[];
    for (var rec in deduplicated) {
      if (rec.type == 'MICRO_INTERVENTION') {
        if (microCount < 1) {
          filtered.add(rec);
          microCount++;
        }
      } else {
        filtered.add(rec);
      }
    }

    // Return between 4 and maxRecommendations, capped at 5
    final limit = maxRecommendations.clamp(4, 5);
    return filtered.take(limit).toList();
  }

  /// Calculate risk score (0-100)
  double calculateRiskScore({
    required PSSAssessment assessment,
    required List<Stressor> stressors,
    required List<CopingStrategy> copingStrategies,
  }) {
    double score = 0.0;

    // Base stress level (40 points max)
    score += assessment.totalScore;

    // Severe stressors (25 points max)
    final severeCount = stressors.where((s) => s.severity >= 8).length;
    score += min(severeCount * 8, 25);

    // Lack of personal time flag (15 points)
    final hasPersonalTimeStressor = stressors.any(
      (s) => s.type == 'Lack of personal time' && s.severity >= 7,
    );
    if (hasPersonalTimeStressor) {
      score += 15;
    }

    // Ineffective coping (10 points)
    final hasIneffectiveCoping = copingStrategies.any((s) => s.isIneffective);
    if (hasIneffectiveCoping) {
      score += 10;
    }

    // Passive coping overload (10 points)
    final passiveRatio = _calculatePassiveCopingRatio(copingStrategies);
    if (passiveRatio > 0.6) {
      score += 10;
    }

    return min(score, 100.0);
  }

  /// Detect crisis situation
  /// Crisis ONLY if: PSS ≥ 32 AND (Risk Score > 85 OR 4+ stressors ≥ 9)
  bool detectCrisis({
    required PSSAssessment assessment,
    required List<Stressor> stressors,
    required double riskScore,
  }) {
    // Must meet PSS threshold first
    if (assessment.totalScore < 32) return false;

    // Then check if Risk score > 85 OR 4+ extreme stressors
    if (riskScore > 85) return true;

    final extremeStressors = stressors.where((s) => s.severity >= 9).length;
    if (extremeStressors >= 4) return true;

    return false;
  }

  // ============================================================================
  // PRIVATE: CRISIS INTERVENTIONS
  // ============================================================================

  List<Recommendation> _crisisInterventions(
    PSSAssessment assessment,
    double riskScore,
  ) {
    return [
      Recommendation(
        recommendationId: 'crisis_${DateTime.now().millisecondsSinceEpoch}',
        generatedAt: DateTime.now(),
        type: 'CRISIS_ALERT',
        priorityScore: 100.0,
        title: '🚨 Immediate Support Needed',
        message: CrisisResources.getCrisisMessage(),
        actions: [
          'Call a crisis hotline right now',
          'Try the 5-4-3-2-1 grounding exercise',
          'Reach out to someone you trust',
          'Consider professional help today',
        ],
        evidenceBasis:
            'Your stress level (${assessment.totalScore}) indicates need for urgent support',
        resources: CrisisResources.hotlines
            .map((h) => '${h['name']}: ${h['number']}')
            .toList(),
        isCrisisRecommendation: true,
      ),
      Recommendation(
        recommendationId: 'breathing_${DateTime.now().millisecondsSinceEpoch}',
        generatedAt: DateTime.now(),
        type: 'CRISIS_ALERT',
        priorityScore: 95.0,
        title: '🫁 Immediate Relief: Breathing Exercise',
        message:
            'When stress is overwhelming, calming your nervous system helps immediately.',
        actions: [
          'Find a quiet space',
          'Breathe in slowly for 4 counts',
          'Hold for 4 counts',
          'Breathe out for 6 counts',
          'Repeat 5 times',
        ],
        evidenceBasis:
            'Controlled breathing activates the parasympathetic nervous system',
        isCrisisRecommendation: true,
      ),
      Recommendation(
        recommendationId:
            'safety_plan_${DateTime.now().millisecondsSinceEpoch}',
        generatedAt: DateTime.now(),
        type: 'CRISIS_ALERT',
        priorityScore: 90.0,
        title: '🛡️ Create Your Safety Plan',
        message:
            'Having a plan helps you know what to do when stress becomes overwhelming.',
        actions: [
          'List 3 people you can call anytime',
          'Write down warning signs you notice',
          'Identify safe places you can go',
          'Keep crisis numbers saved in your phone',
        ],
        evidenceBasis: 'Safety planning reduces crisis severity and duration',
        isCrisisRecommendation: true,
      ),
    ];
  }

  // ============================================================================
  // PRIVATE: STRESSOR INTERVENTIONS
  // ============================================================================

  Recommendation _financialStressIntervention(
    PSSAssessment assessment,
    Stressor stressor,
  ) {
    final isHighStress = assessment.category == 'HIGH';

    return Recommendation(
      recommendationId: 'financial_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      type: 'STRESSOR_INTERVENTION',
      priorityScore: 0, // Will be calculated later
      title: '💰 Financial Stress Support',
      message:
          'Financial difficulties have the strongest impact on stress (+5 points). '
          'Let\'s address this systematically.',
      actions: isHighStress
          ? [
              'Find emergency assistance (food banks, rent help)',
              'Contact a free financial counselor',
              'Create a crisis budget (essentials only)',
              'Explore government assistance programs',
              '💡 Helpful Resources:',
              '  • Video: "Budgeting Basics" - https://youtube.com/watch?v=sVKQn2H0mII',
              '  • Free budgeting help: https://www.nfcc.org (National Foundation for Credit Counseling)',
              '  • Budget calculator: https://www.mint.com',
            ]
          : [
              'Track expenses for one week',
              'Create a simple budget',
              'Identify one area to reduce spending',
              'Consider free financial counseling',
              '💡 Helpful Resources:',
              '  • Video: "Budgeting 101" - https://youtube.com/watch?v=sVKQn2H0mII',
              '  • Free app: Mint, YNAB (You Need A Budget)',
              '  • Finance guide: https://www.consumerfinance.gov/consumer-tools',
            ],
      evidenceBasis:
          'Financial stress increases PSS by 5.0 points (highest impact)',
    );
  }

  Recommendation _personalTimeIntervention(
    PSSAssessment assessment,
    Stressor stressor,
  ) {
    return Recommendation(
      recommendationId:
          'personal_time_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      type: 'STRESSOR_INTERVENTION',
      priorityScore: 0,
      title: '⏰ Reclaim Your Time',
      message: '100% of high-stress users report lack of personal time. '
          'This is a critical warning sign that needs attention.',
      actions: [
        'Complete a 3-day time audit',
        'Identify one activity you can delegate or eliminate',
        'Block 30 minutes daily for yourself (non-negotiable)',
        'Practice saying "no" to new commitments',
        'Set boundaries with work/family',
        '💡 Helpful Resources:',
        '  • Video: "Setting Boundaries" - https://youtube.com/watch?v=5U9oshi41U4',
        '  • Time management guide: https://www.mindtools.com/pages/main/newMN_HTE.htm',
      ],
      evidenceBasis:
          '100% of high-stress users (PSS>26) report severe lack of personal time',
    );
  }

  Recommendation? _stressorIntervention(
    PSSAssessment assessment,
    Stressor stressor,
  ) {
    String title;
    String message;
    List<String> actions;

    switch (stressor.type) {
      case 'Academic pressure':
        title = '📚 Academic Stress Support';
        message =
            'Academic pressure can feel overwhelming. Break it into manageable steps.';
        actions = [
          'Talk to your advisor about your workload',
          'Create a study schedule with breaks',
          'Form or join a study group',
          'Use campus counseling services (free)',
          'Consider reducing course load if possible',
        ];
        break;

      case 'Work environment':
        title = '🏢 Work Stress Management';
        message = 'A stressful work environment affects overall well-being.';
        actions = [
          'Set clear work-life boundaries',
          'Take breaks every 90 minutes',
          'Document issues if considering HR',
          'Update your resume (backup plan)',
          'Use employee assistance program if available',
        ];
        break;

      case 'Relationship issues':
        title = '💕 Relationship Support';
        message = 'Relationship stress impacts mental health significantly.';
        actions = [
          'Practice "I feel" statements vs. blame',
          'Schedule weekly check-ins with partner',
          'Consider couples counseling',
          'Set aside time for connection',
          'Know when to seek help or exit if unsafe',
        ];
        break;

      case 'Poor sleep':
        title = '😴 Sleep Improvement';
        message =
            'Poor sleep makes stress worse. Better sleep = better coping.';
        actions = [
          'Set consistent bed/wake times',
          'No screens 1 hour before bed',
          'Keep bedroom cool and dark',
          'Try progressive muscle relaxation',
          'Limit caffeine after 2 PM',
        ];
        break;

      case 'Poor eating habits':
        title = '🍎 Nutrition for Stress';
        message = 'What you eat affects how you feel.';
        actions = [
          'Eat regular meals (don\'t skip)',
          'Add one vegetable to each meal',
          'Stay hydrated (water, not soda)',
          'Limit sugar and processed foods',
          'Plan meals weekly to reduce stress',
        ];
        break;

      case 'Health problems':
        title = '🏥 Health Management';
        message = 'Managing health actively is protective against stress.';
        actions = [
          'Follow up with healthcare provider',
          'Take medications as prescribed',
          'Track symptoms to identify patterns',
          'Join support group if available',
          'Address mental health alongside physical',
        ];
        break;

      case 'Long working hours':
        title = '⏱️ Work-Life Balance';
        message = 'Excessive working hours damage health and relationships.';
        actions = [
          'Calculate actual hours worked weekly',
          'Identify what\'s urgent vs. important',
          'Discuss workload with supervisor',
          'Set "hard stop" time daily',
          'Evaluate if this job is sustainable',
        ];
        break;

      case 'Heavy workload':
        title = '📊 Workload Management';
        message = 'Heavy workload requires strategic prioritization.';
        actions = [
          'Use Eisenhower Matrix (urgent/important)',
          'Delegate or eliminate 20% of tasks',
          'Focus on 3 priorities per day max',
          'Block "deep work" time',
          'Say no to non-essential requests',
        ];
        break;

      case 'Family responsibilities':
        title = '👨‍👩‍👧‍👦 Family Balance';
        message =
            'Family responsibilities are important but shouldn\'t overwhelm you.';
        actions = [
          'Share responsibilities fairly',
          'Ask family members to help',
          'Set realistic expectations',
          'Schedule personal time',
          'Seek community support resources',
        ];
        break;

      case 'Social media':
        title = '📱 Digital Wellness';
        message =
            'Social media can increase stress through comparison and overwhelm.';
        actions = [
          'Track screen time this week',
          'Set app time limits',
          'Turn off non-essential notifications',
          'Have phone-free times/places',
          'Unfollow accounts that cause stress',
        ];
        break;

      default:
        return null;
    }

    return Recommendation(
      recommendationId:
          '${stressor.type.toLowerCase().replaceAll('/', '_').replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      type: 'STRESSOR_INTERVENTION',
      priorityScore: 0,
      title: title,
      message: message,
      actions: actions,
      evidenceBasis:
          'Direct intervention for ${stressor.type} (severity: ${stressor.severity}/10)',
    );
  }

  // ============================================================================
  // PRIVATE: PROTECTIVE STRATEGY PROMOTION
  // ============================================================================

  List<String> _getMissingProtectiveStrategies(List<CopingStrategy> current) {
    const protective = [
      'Therapy/counseling',
      'Journaling',
      'Exercise',
      'Talking to friends/family',
      'Meditation/prayer',
    ];

    final currentNames = current.map((s) => s.name).toSet();
    return protective.where((s) => !currentNames.contains(s)).toList();
  }

  List<Recommendation> _promoteProtectiveStrategies(
    PSSAssessment assessment,
    List<String> missingStrategies,
    List<CopingStrategy> currentStrategies,
  ) {
    final recommendations = <Recommendation>[];

    for (var strategy in missingStrategies.take(2)) {
      // Add top 2 missing strategies
      final rec = _createStrategyRecommendation(strategy, assessment);
      if (rec != null) {
        recommendations.add(rec);
      }
    }

    return recommendations;
  }

  Recommendation? _createStrategyRecommendation(
    String strategy,
    PSSAssessment assessment,
  ) {
    String title;
    String message;
    List<String> actions;
    String evidence;

    switch (strategy) {
      case 'Therapy/counseling':
        // Only recommend therapy for very high stress (PSS > 34)
        if (assessment.totalScore <= 34) {
          return null; // Skip therapy recommendation for lower stress levels
        }
        title = '🏥 Try Professional Support';
        message = 'Therapy is the #1 most effective stress-reduction strategy. '
            'It\'s not weakness—it\'s smart.';
        actions = [
          'Ask your workplace about employee assistance programs (EAP)',
          'Search for community mental health centers (often free/low-cost)',
          'Try online therapy if in-person is difficult',
          'Start with just one session',
          '💡 Helpful Resources:',
          '  • Video: "How Therapy Works" - https://youtube.com/watch?v=GZw8fRPK-8k',
          '  • Find therapists: https://www.psychologytoday.com/us/therapists',
          '  • Online therapy: https://www.betterhelp.com',
        ];
        evidence =
            'Therapy reduces stress by 5.8 points (strongest evidence, p<0.05)';
        break;

      case 'Journaling':
        title = '📝 Start Journaling (3 Minutes)';
        message =
            'Just 3 minutes of writing per day can reduce stress by 3 points. '
            'You don\'t need to write perfectly.';
        actions = [
          'Get a notebook or use your phone',
          'Daily prompt: "What stressed me today? What can I control?"',
          'Write for 3 minutes, no editing',
          'Do it before bed to clear your mind',
          'Track your stress rating before/after',
          '💡 Helpful Resources:',
          '  • Video: "Journaling for Mental Health" - https://youtube.com/watch?v=Z-8FaiKlcJE',
          '  • Free app: Journey or Day One',
          '  • Prompts: https://positivepsychology.com/journal-prompts',
        ];
        evidence = 'Journaling reduces stress by 2.9 points';
        break;

      case 'Exercise':
        title = '🏃 Get Moving';
        message = 'Movement helps mood. Even 10 minutes makes a difference.';
        actions = [
          'Start with 10-minute walks',
          'Choose something you enjoy (dance, sports, walking)',
          'Exercise with a friend (adds social support)',
          'Schedule it like an appointment',
          'Celebrate small wins',
          '💡 Professional Workout Channels:',
          '  • Full Body (10-min): https://youtube.com/watch?v=ml6cT4AZdqI',
          '  • Aerobics/Cardio: https://youtube.com/@fitness22',
          '  • Dance Workouts: https://youtube.com/@TheFitnessMarshall',
          '  • Weight Training: https://youtube.com/@HASfit',
          '  • Yoga/Stretching: https://youtube.com/@yogawithadriene',
          '  • Walking guide: https://www.nhs.uk/live-well/exercise/walking-for-health',
        ];
        evidence = 'Exercise reduces stress by 1.6 points';
        break;

      case 'Talking to friends/family':
        title = '🤝 Connect With Others';
        message = 'You don\'t have to face this alone. Talking helps.';
        actions = [
          'Reach out to one person this week',
          'Be honest: "I\'m struggling and need to talk"',
          'Schedule regular check-ins (weekly coffee, phone call)',
          'Join a support group if friends/family unavailable',
          'Remember: accepting help is strength, not weakness',
        ];
        evidence = 'Social support reduces stress by 2.0 points';
        break;

      case 'Meditation/prayer':
        title = '🧘 Calm Your Mind';
        message =
            'Meditation/prayer helps regulate stress response. Start small.';
        actions = [
          'Start with 2 minutes per day',
          'Use guided meditation app or YouTube',
          'Focus on breath (in for 4, out for 6)',
          'Don\'t judge yourself—the practice is the point',
          'Gradually increase to 10 minutes',
          '💡 Helpful Resources:',
          '  • Video: "5-Min Guided Meditation" - https://youtube.com/watch?v=inpok4MKVLM',
          '  • Free apps: Headspace (free basics), Insight Timer',
          '  • Learn more: https://www.mindful.org/meditation/mindfulness-getting-started',
        ];
        evidence = 'Meditation/prayer reduces stress by 1.4 points';
        break;

      default:
        return null;
    }

    return Recommendation(
      recommendationId:
          '${strategy.toLowerCase().replaceAll('/', '_').replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      type: 'COPING_STRATEGY',
      priorityScore: 0,
      title: title,
      message: message,
      actions: actions,
      evidenceBasis: evidence,
    );
  }

  // ============================================================================
  // PRIVATE: BEHAVIORAL SHIFT
  // ============================================================================

  Recommendation _behavioralShiftRecommendation(
    PSSAssessment assessment,
    double passiveRatio,
  ) {
    return Recommendation(
      recommendationId:
          'behavioral_shift_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      type: 'BEHAVIORAL_SHIFT',
      priorityScore: 0,
      title: '⚖️ Balance Your Coping',
      message:
          'You\'re using strategies like TV, sleep, or music to cope—these help in the moment. '
          'BUT: 100% of high-stress users rely on these alone. '
          'Research shows adding just ONE active strategy reduces stress by 2+ points.',
      actions: [
        'Keep doing what you\'re doing (don\'t stop relaxing)',
        'Add ONE active strategy this week:',
        '  • 3 minutes of journaling',
        '  • 10-minute phone call with a friend',
        '  • 15-minute walk',
        'See how you feel after 1 week',
      ],
      evidenceBasis:
          '100% of high-stress users rely on passive coping; adding active strategies reduces stress',
    );
  }

  // ============================================================================
  // PRIVATE: PRIORITY CALCULATION
  // ============================================================================

  double _calculatePriority({
    required Recommendation recommendation,
    required PSSAssessment assessment,
    required List<Stressor> stressors,
    required List<CopingStrategy> copingStrategies,
  }) {
    double score = 0;

    // Factor 1: Evidence strength (0-30 points)
    score += _getEvidenceScore(recommendation);

    // Factor 2: Stress level (0-25 points)
    score += (assessment.totalScore / 40) * 25;

    // Factor 3: Direct match to stressor (0-20 points)
    score += _getStressorMatchScore(recommendation, stressors);

    // Factor 4: Fresh idea bonus (0-15 points)
    score += _getFreshIdeasScore(recommendation, copingStrategies);

    // Factor 5: Accessibility (0-5 points)
    score += _getAccessibilityScore(recommendation);

    // Factor 6: Contextual bonuses
    score += _getContextualBonuses(
      recommendation,
      assessment,
      copingStrategies,
    );

    return min(score, 100.0);
  }

  double _getEvidenceScore(Recommendation rec) {
    if (rec.evidenceBasis.contains('5.8')) return 30;
    if (rec.evidenceBasis.contains('2.9')) return 20;
    if (rec.evidenceBasis.contains('2.0')) return 18;
    if (rec.evidenceBasis.contains('1.6')) return 15;
    if (rec.evidenceBasis.contains('1.4')) return 12;
    if (rec.isCrisisRecommendation) return 30;
    return 10;
  }

  double _getStressorMatchScore(Recommendation rec, List<Stressor> stressors) {
    for (var stressor in stressors) {
      if (rec.title.toLowerCase().contains(stressor.type.toLowerCase()) ||
          rec.message.toLowerCase().contains(stressor.type.toLowerCase())) {
        return stressor.severity * 2.0;
      }
    }
    return 5;
  }

  double _getFreshIdeasScore(
    Recommendation rec,
    List<CopingStrategy> strategies,
  ) {
    final strategyNames = strategies.map((s) => s.name.toLowerCase()).toSet();

    if (rec.title.toLowerCase().contains('therapy') &&
        !strategyNames.contains('therapy/counseling')) {
      return 15;
    }
    if (rec.title.toLowerCase().contains('journal') &&
        !strategyNames.contains('journaling')) {
      return 15;
    }
    if (rec.title.toLowerCase().contains('exercise') &&
        !strategyNames.contains('exercise')) {
      return 20; // Higher boost for exercise (prioritize physical activity)
    }

    return 5;
  }

  double _getAccessibilityScore(Recommendation rec) {
    if (rec.title.toLowerCase().contains('breathing') ||
        rec.title.toLowerCase().contains('journal')) {
      return 5; // Easy, free, immediate
    }
    if (rec.title.toLowerCase().contains('therapy')) {
      return 2; // Barriers: cost, finding provider
    }
    return 3;
  }

  double _getContextualBonuses(
    Recommendation rec,
    PSSAssessment assessment,
    List<CopingStrategy> copingStrategies,
  ) {
    double bonus = 0;

    // Crisis situation
    if (rec.isCrisisRecommendation) {
      bonus += 20;
    }

    // High stress + high-impact strategy
    if (assessment.category == 'HIGH' && rec.evidenceBasis.contains('5.8')) {
      bonus += 10;
    }

    // Financial difficulties present
    if (rec.title.contains('Financial')) {
      bonus += 15;
    }

    // Stressor interventions always get a strong priority boost
    if (rec.type == 'STRESSOR_INTERVENTION') {
      bonus += 20;
    }

    // Ineffective coping + high-impact recommendation
    final hasIneffective = copingStrategies.any((s) => s.isIneffective);
    if (hasIneffective && rec.type == 'COPING_STRATEGY') {
      bonus += 10;
    }

    return bonus;
  }

  // ============================================================================
  // HELPER FUNCTIONS
  // ============================================================================

  double _calculatePassiveCopingRatio(List<CopingStrategy> strategies) {
    if (strategies.isEmpty) return 0.0;
    final passiveCount = strategies.where((s) => s.isPassive).length;
    return passiveCount / strategies.length;
  }

  /// Get effective strategies with low frequency
  List<CopingStrategy> _getInfrequentEffectiveStrategies(
      List<CopingStrategy> strategies) {
    return strategies.where((s) {
      // Effective rating ("Very effective" or "Somewhat effective") but low frequency
      final isInfrequent =
          s.frequency == 'Once a week' || s.frequency == 'Rarely';
      return s.isEffective && isInfrequent;
    }).toList();
  }

  /// Check if user lacks active coping strategies
  bool _lacksActiveCoping(List<CopingStrategy> strategies) {
    final activeStrategies = [
      'Exercise',
      'Meditation/prayer',
      'Journaling',
      'Therapy/counseling',
      'Talking to friends/family'
    ];
    final hasActive = strategies.any((s) => activeStrategies.contains(s.name));
    return !hasActive;
  }

  /// Recommend increasing frequency of effective strategies
  Recommendation _increaseFrequencyRecommendation(
    PSSAssessment assessment,
    CopingStrategy strategy,
  ) {
    return Recommendation(
      recommendationId: 'frequency_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      type: 'FREQUENCY_INCREASE',
      priorityScore: 70.0,
      title: '📈 Increase ${strategy.name} Frequency',
      message:
          'You rated ${strategy.name} as effective (${strategy.effectivenessRating}/5), '
          'but you\'re only doing it ${strategy.frequency.toLowerCase()}. '
          'Increasing frequency can significantly reduce your stress.',
      actions: [
        'Current: ${strategy.frequency}',
        'Goal: 3-4 times per week (or daily if possible)',
        'Start small: Add one extra session this week',
        'Schedule it like an appointment',
        'Track your stress levels before and after',
      ],
      evidenceBasis: 'Consistent practice amplifies stress-reduction benefits',
    );
  }

  /// Recommend active coping mechanisms for moderate-high stress
  Recommendation _activeCopingRecommendation(
    PSSAssessment assessment,
    List<CopingStrategy> currentStrategies,
  ) {
    return Recommendation(
      recommendationId:
          'active_coping_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      type: 'ACTIVE_COPING',
      priorityScore: 75.0,
      title: '💪 Add Active Stress Management',
      message: 'With your current stress level (${assessment.totalScore}/40), '
          'active coping strategies are essential. Passive methods alone won\'t reduce stress long-term.',
      actions: [
        'Try ONE active strategy this week:',
        '  • Exercise (even 10-min walks):',
        '    - Aerobics: https://youtube.com/@fitness22',
        '    - Dance: https://youtube.com/@TheFitnessMarshall',
        '    - Weights: https://youtube.com/@HASfit',
        '    - Yoga: https://youtube.com/@yogawithadriene',
        '  • Journaling (3 min/day): https://youtube.com/watch?v=Z-8FaiKlcJE',
        '  • Meditation/prayer (5 min): https://youtube.com/watch?v=inpok4MKVLM',
        '  • Talk to a friend/family member',
        'Active coping builds resilience over time',
      ],
      evidenceBasis:
          'Active coping reduces PSS scores 2-6 points (evidence-based)',
      resources: [
        'Quick exercise guide: https://youtube.com/watch?v=ml6cT4AZdqI',
        'Aerobics workouts: https://youtube.com/@fitness22',
        'Dance workouts: https://youtube.com/@TheFitnessMarshall',
        'Weight training: https://youtube.com/@HASfit',
        'Yoga: https://youtube.com/@yogawithadriene',
        'Journaling prompts: https://positivepsychology.com/journal-prompts',
        'Guided meditation: https://youtube.com/watch?v=inpok4MKVLM',
      ],
    );
  }

  /// Recommend physical social interaction for stress relief (PSS > 25)
  Recommendation _physicalInteractionRecommendation(PSSAssessment assessment) {
    return Recommendation(
      recommendationId:
          'physical_interaction_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      type: 'SOCIAL_CONNECTION',
      priorityScore: 72.0,
      title: '🤝 Meet Someone in Person (Weekly)',
      message: 'With stress at ${assessment.totalScore}/40, face-to-face '
          'interaction is crucial. Physical presence releases oxytocin and reduces cortisol.',
      actions: [
        'Meet at least ONE person physically this week:',
        '  • Coffee with a friend (30 minutes)',
        '  • Walk with a family member',
        '  • Join a group activity (sports, church, club)',
        '  • Attend a community event',
        'Aim for weekly in-person connections',
        'Even brief interactions (15-30 min) help',
        'Quality matters more than quantity',
      ],
      evidenceBasis:
          'Physical social interaction reduces stress hormones and improves mood (evidence-based)',
      resources: [
        'Benefits of in-person connection: https://www.helpguide.org/articles/mental-health/social-connection.htm',
        'Finding social groups: https://www.meetup.com',
      ],
    );
  }

  // ============================================================================
  // MICRO-INTERVENTIONS (2-5 minute quick activities)
  // ============================================================================

  /// 2-minute box breathing exercise
  Recommendation _boxBreathingMicro(PSSAssessment assessment) {
    return Recommendation(
      recommendationId:
          'micro_breathing_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      type: 'MICRO_INTERVENTION',
      priorityScore: 65.0,
      title: '🫁 Box Breathing (2 min)',
      message:
          'Quick stress relief technique used by Navy SEALs. Works in under 2 minutes.',
      actions: [
        'Find a quiet spot (or do at your desk)',
        'Breathe IN for 4 counts',
        'HOLD for 4 counts',
        'Breathe OUT for 4 counts',
        'HOLD for 4 counts',
        'Repeat 4-6 times (2 minutes total)',
        '💡 Video guide: https://youtube.com/watch?v=tEmt1Znux58',
      ],
      evidenceBasis:
          'Reduces cortisol and activates parasympathetic nervous system',
      resources: [
        'Box breathing guide: https://youtube.com/watch?v=tEmt1Znux58'
      ],
    );
  }

  /// 5-4-3-2-1 grounding technique (3 min)
  Recommendation _groundingTechniqueMicro(PSSAssessment assessment) {
    return Recommendation(
      recommendationId:
          'micro_grounding_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      type: 'MICRO_INTERVENTION',
      priorityScore: 68.0,
      title: '🌟 5-4-3-2-1 Grounding (3 min)',
      message:
          'Immediate anxiety relief technique. Brings you back to the present moment.',
      actions: [
        'Look around and name:',
        '  • 5 things you can SEE',
        '  • 4 things you can TOUCH',
        '  • 3 things you can HEAR',
        '  • 2 things you can SMELL',
        '  • 1 thing you can TASTE',
        'Take your time with each sense',
        '💡 Video guide: https://youtube.com/watch?v=30VMIEmA114',
      ],
      evidenceBasis:
          'Mindfulness-based grounding reduces anxiety by 40% immediately',
      resources: [
        'Grounding techniques: https://youtube.com/watch?v=30VMIEmA114'
      ],
    );
  }

  /// Progressive muscle relaxation mini (5 min)
  Recommendation _pmrMicro(PSSAssessment assessment) {
    return Recommendation(
      recommendationId: 'micro_pmr_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      type: 'MICRO_INTERVENTION',
      priorityScore: 62.0,
      title: '💪 Quick Muscle Relaxation (5 min)',
      message:
          'Release physical tension fast. Great for desk work or before sleep.',
      actions: [
        'Tense and release each body part (5 seconds each):',
        '  1. Hands → make fists, release',
        '  2. Arms → flex biceps, release',
        '  3. Shoulders → raise to ears, drop',
        '  4. Face → scrunch tight, relax',
        '  5.Jaw → clench, release',
        '  6. Legs → straighten & tense, release',
        '💡 Guided audio: https://youtube.com/watch?v=1nZEdqcGVzo',
      ],
      evidenceBasis: 'PMR reduces muscle tension and anxiety within minutes',
      resources: ['PMR guide: https://youtube.com/watch?v=1nZEdqcGVzo'],
    );
  }

  /// 2-minute desk stretches
  Recommendation _deskStretchesMicro(PSSAssessment assessment) {
    return Recommendation(
      recommendationId:
          'micro_stretch_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      type: 'MICRO_INTERVENTION',
      priorityScore: 60.0,
      title: '🧘 Desk Stretches (2 min)',
      message: 'Release tension from sitting. No equipment needed.',
      actions: [
        'Do each stretch for 15-20 seconds:',
        '  • Neck rolls (both directions)',
        '  • Shoulder shrugs (up & down)',
        '  • Chest opener (clasp hands behind back)',
        '  • Seated spinal twist (both sides)',
        '  • Wrist circles (if typing a lot)',
        'No need to stand up!',
        '💡 Video guide: https://youtube.com/watch?v=EcUU_aNeHGM',
      ],
      evidenceBasis: 'Micro-breaks reduce stress and increase productivity',
      resources: ['Desk stretches: https://youtube.com/watch?v=EcUU_aNeHGM'],
    );
  }

  /// 3-minute gratitude practice
  Recommendation _gratitudeQuickMicro(PSSAssessment assessment) {
    return Recommendation(
      recommendationId:
          'micro_gratitude_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      type: 'MICRO_INTERVENTION',
      priorityScore: 64.0,
      title: '🙏 Quick Gratitude (3 min)',
      message:
          'Shift from stress to appreciation. Scientifically proven mood booster.',
      actions: [
        'Write down or think of 3 things:',
        '  1. One thing that went well today',
        '  2. One person you appreciate',
        '  3. One thing your body did for you today',
        'Why does each matter to you?',
        'Take 30 seconds per item',
        '💡 Tip: Do this daily before bed',
      ],
      evidenceBasis:
          'Gratitude practice reduces stress hormones and improves sleep quality',
      resources: [
        'Science of gratitude: https://positivepsychology.com/gratitude-research/'
      ],
    );
  }

  /// 5-minute walk break
  Recommendation _walkBreakMicro(PSSAssessment assessment) {
    return Recommendation(
      recommendationId: 'micro_walk_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      type: 'MICRO_INTERVENTION',
      priorityScore: 66.0,
      title: '🚶 5-Minute Walk Break',
      message: 'Movement clears your mind. Even 5 minutes helps.',
      actions: [
        'Step outside or walk indoors',
        'Walk at comfortable pace',
        'Notice 3 things around you (sights, sounds)',
        'Take deep breaths while walking',
        'No phone/music - just walk',
        'Set a 5-minute timer',
        '💡 Aim for one walk break per day',
      ],
      evidenceBasis: 'Short walks reduce stress by 15% and improve focus',
      resources: [
        'Walking benefits: https://www.health.harvard.edu/staying-healthy/5-surprising-benefits-of-walking'
      ],
    );
  }

  /// 2-minute cold water face dip
  Recommendation _coldWaterMicro(PSSAssessment assessment) {
    return Recommendation(
      recommendationId:
          'micro_coldwater_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      type: 'MICRO_INTERVENTION',
      priorityScore: 70.0,
      title: '❄️ Cold Water Reset (2 min)',
      message:
          'Activates"dive reflex" - instantly calms nervous system. Works FAST.',
      actions: [
        'Fill bowl/sink with cold water + ice (if available)',
        'Take deep breath IN',
        'Dip face in water for 15-30 seconds',
        'Come up, breathe normally',
        'Repeat 2-3 times',
        'OR: Splash cold water on face 10-15 times',
        '⚠️ Consult doctor if heart conditions',
      ],
      evidenceBasis: 'Mammalian dive reflex slows heart rate and reduces panic',
      resources: [
        'Dive reflex explained: https://www.healthline.com/health/dive-reflex'
      ],
    );
  }

  /// 3-minute worry dump
  Recommendation _worryDumpMicro(PSSAssessment assessment) {
    return Recommendation(
      recommendationId: 'micro_worry_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      type: 'MICRO_INTERVENTION',
      priorityScore: 63.0,
      title: '📝 Worry Dump (3 min)',
      message: 'Get anxious thoughts out of your head and onto paper.',
      actions: [
        'Grab paper or phone notes app',
        'Set timer for 3 minutes',
        'Write EVERY worry/stress - no filter',
        'Don\'t edit, just dump it all out',
        'When timer ends, STOP writing',
        'Optional: Tear up paper (symbolic release)',
        'Notice how you feel after',
      ],
      evidenceBasis:
          'Expressive writing reduces rumination and intrusive thoughts',
      resources: [
        'Worry journaling: https://positivepsychology.com/worry-journal/'
      ],
    );
  }

  /// 4-minute guided imagery
  Recommendation _guidedImageryMicro(PSSAssessment assessment) {
    return Recommendation(
      recommendationId:
          'micro_imagery_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      type: 'MICRO_INTERVENTION',
      priorityScore: 61.0,
      title: '🏝️ Safe Place Visualization (4 min)',
      message: 'Mental escape to calm place. Reduces stress hormones.',
      actions: [
        'Close eyes, take 3 deep breaths',
        'Picture your favorite peaceful place:',
        '  • Beach? Forest? Childhood home?',
        'Imagine in detail:',
        '  • What do you see? (colors, shapes)',
        '  • What do you hear? (waves, birds)',
        '  • What do you smell? (ocean, pine)',
        '  • How does your body feel?',
        'Stay there for 4 minutes',
        '💡 Audio guide: https://youtube.com/watch?v=ihO02wUzgkc',
      ],
      evidenceBasis:
          'Guided imagery reduces cortisol and lowers blood pressure',
      resources: ['Guided imagery: https://youtube.com/watch?v=ihO02wUzgkc'],
    );
  }

  /// 2-minute positive affirmations
  Recommendation _affirmationsMicro(PSSAssessment assessment) {
    return Recommendation(
      recommendationId:
          'micro_affirmations_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      type: 'MICRO_INTERVENTION',
      priorityScore: 58.0,
      title: '💬 Positive Affirmations (2 min)',
      message: 'Rewire negative thought patterns. Works with repetition.',
      actions: [
        'Choose 3 affirmations (or use these):',
        '  • "I am capable of handling this"',
        '  • "This feeling is temporary"',
        '  • "I am stronger than my stress"',
        '  • "I deserve peace and rest"',
        'Say each one 5 times (out loud if possible)',
        'Put hand on heart while saying them',
        'Repeat daily for best results',
      ],
      evidenceBasis:
          'Self-affirmation activates brain reward centers and reduces stress',
      resources: [
        'Affirmations guide: https://positivepsychology.com/daily-affirmations/'
      ],
    );
  }

  /// 3-minute body scan
  Recommendation _bodyScanMicro(PSSAssessment assessment) {
    return Recommendation(
      recommendationId:
          'micro_bodyscan_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      type: 'MICRO_INTERVENTION',
      priorityScore: 59.0,
      title: '🧘 Quick Body Scan (3 min)',
      message:
          'Check in with your body. Release tension you didn\'t know you had.',
      actions: [
        'Sit or lie comfortably',
        'Close eyes, take 3 deep breaths',
        'Scan from head to toe (30 seconds each):',
        '  • Head/face - any tension?',
        '  • Shoulders/neck - holding tightness?',
        '  • Chest/stomach - breathing shallow?',
        '  • Legs/feet - clenched?',
        'Breathe into tense areas',
        'Imagine tension melting away',
        '💡 Audio guide: https://youtube.com/watch?v=15q-N-_kkrU',
      ],
      evidenceBasis: 'Body scan meditation reduces physical stress symptoms',
      resources: ['Body scan: https://youtube.com/watch?v=15q-N-_kkrU'],
    );
  }

  /// Get random micro-intervention
  Recommendation getRandomMicroIntervention(PSSAssessment assessment) {
    final random = Random();
    final microInterventions = [
      _boxBreathingMicro,
      _groundingTechniqueMicro,
      _pmrMicro,
      _deskStretchesMicro,
      _gratitudeQuickMicro,
      _walkBreakMicro,
      _coldWaterMicro,
      _worryDumpMicro,
      _guidedImageryMicro,
      _affirmationsMicro,
      _bodyScanMicro,
    ];

    final selectedMethod =
        microInterventions[random.nextInt(microInterventions.length)];
    return selectedMethod(assessment);
  }

  /// Get time-based micro-intervention
  Recommendation getContextualMicroIntervention(PSSAssessment assessment) {
    final hour = DateTime.now().hour;

    // Morning (6-9 AM): Energizing activities
    if (hour >= 6 && hour <= 9) {
      return _deskStretchesMicro(assessment);
    }
    // Midday (12-2 PM): Quick resets
    else if (hour >= 12 && hour <= 14) {
      return _walkBreakMicro(assessment);
    }
    // Evening (6-9 PM): Calming activities
    else if (hour >= 18 && hour <= 21) {
      return _gratitudeQuickMicro(assessment);
    }
    // Night (9 PM+): Sleep prep
    else if (hour >= 21 || hour <= 5) {
      return _bodyScanMicro(assessment);
    }
    // Default: Breathing
    else {
      return _boxBreathingMicro(assessment);
    }
  }
}
