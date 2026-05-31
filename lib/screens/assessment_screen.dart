import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../models/coping_strategy.dart';
import '../models/pss_assessment.dart';
import '../models/stressor.dart';
import '../services/algorithm_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'achievements_screen.dart';
import 'recommendations_screen.dart';

/// Multi-step assessment screen
class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final PageController _pageController = PageController();
  final StorageService _storage = StorageService();
  final AlgorithmService _algorithm = AlgorithmService();

  int _currentStep = 0;
  final int _totalSteps = 3;

  // PSS-10 responses
  final Map<int, int> _pssResponses = {};

  // Stressors
  final Map<String, int> _stressorSeverities = {};

  // Coping strategies
  final Map<String, String> _copingFrequencies = {}; // strategy -> frequency
  final Map<String, String> _copingEffectiveness =
      {}; // strategy -> effectiveness

  bool _isSubmitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      if (_validateCurrentStep()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep++);
      }
    } else {
      _submitAssessment();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // PSS-10
        if (_pssResponses.length < 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please answer all 10 questions')),
          );
          return false;
        }
        return true;
      case 1: // Stressors
        if (_stressorSeverities.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select at least one stressor'),
            ),
          );
          return false;
        }
        return true;
      case 2: // Coping
        if (_copingFrequencies.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select at least one coping strategy'),
            ),
          );
          return false;
        }
        // Check if all selected strategies have effectiveness ratings
        for (var strategy in _copingFrequencies.keys) {
          if (!_copingEffectiveness.containsKey(strategy)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please rate effectiveness for "$strategy"'),
              ),
            );
            return false;
          }
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _submitAssessment() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isSubmitting = true);

    try {
      // Create PSS assessment
      final assessment = PSSAssessment.fromResponses(_pssResponses);

      await _storage.saveAssessment(assessment);

      // Create stressors
      final stressors = _stressorSeverities.entries
          .map(
            (e) => Stressor(
              type: e.key,
              severity: e.value,
              recordedAt: DateTime.now(),
            ),
          )
          .toList();
      await _storage.saveStressors(stressors);

      // Create coping strategies
      final strategies = _copingFrequencies.entries
          .map(
            (e) => CopingStrategy(
              name: e.key,
              frequency: e.value,
              effectivenessRating: _copingEffectiveness[e.key] ?? 'Neutral',
              recordedAt: DateTime.now(),
            ),
          )
          .toList();
      await _storage.saveCopingStrategies(strategies);

      // Update settings
      final settings = _storage.getSettings();
      settings.recordAssessment();
      if (assessment.isCrisis) {
        settings.logCrisisEvent();
      }
      await _storage.saveSettings(settings);

      // Track achievements
      await _updateAchievements(assessment);

      // Schedule next notification (non-critical - fail silently)
      try {
        await NotificationService.scheduleReminderAfterDays(
          settings.reassessmentIntervalDays,
        );
      } catch (e) {
        // Continue without notifications - this is not critical to app function
      }

      // Generate recommendations
      final recommendations = _algorithm.generateRecommendations(
        assessment: assessment,
        stressors: stressors,
        copingStrategies: strategies,
        maxRecommendations: 5,
      );

      // Clear old recommendations before saving new ones
      await _storage.clearAllRecommendations();
      await _storage.saveRecommendations(recommendations);

      // Navigate to recommendations, then return true when complete
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecommendationsScreen()),
        );
        // After viewing recommendations, pop back with success result
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Update achievement progress after assessment completion
  Future<void> _updateAchievements(PSSAssessment newAssessment) async {
    try {
      // Initialize achievements if this is first assessment
      await _storage.initializeAchievements();

      // Update assessment count achievements
      await _storage.updateAchievementProgress('assessment_1', 1);
      await _storage.updateAchievementProgress('assessment_5', 1);
      await _storage.updateAchievementProgress('assessment_10', 1);
      await _storage.updateAchievementProgress('assessment_20', 1);

      // Update streak achievements (weekly/monthly)
      final assessments = _storage.getAllAssessments();
      if (assessments.length >= 4) {
        // Check if there are assessments in last 4 weeks
        final fourWeeksAgo = DateTime.now().subtract(const Duration(days: 28));
        final recentCount =
            assessments.where((a) => a.date.isAfter(fourWeeksAgo)).length;
        if (recentCount >= 4) {
          await _storage.updateAchievementProgress('streak_4', 1);
        }
      }
      if (assessments.length >= 8) {
        // Check if there are assessments in last 8 weeks
        final eightWeeksAgo = DateTime.now().subtract(const Duration(days: 56));
        final recentCount =
            assessments.where((a) => a.date.isAfter(eightWeeksAgo)).length;
        if (recentCount >= 8) {
          await _storage.updateAchievementProgress('streak_8', 1);
        }
      }

      // Track stress reduction (compare with previous assessment)
      if (assessments.length >= 2) {
        final previousAssessment = assessments[1]; // Second most recent
        final reduction =
            previousAssessment.totalScore - newAssessment.totalScore;

        if (reduction > 0) {
          // Stress has decreased - good!
          await _storage.updateAchievementProgress('stress_down_5', reduction);
          await _storage.updateAchievementProgress('stress_down_10', reduction);
        }
      }

      // Track recommendation completion (explorer achievement)
      final feedback = _storage.getAllFeedback();
      final uniqueTypes =
          feedback.map((f) => f.recommendationType).toSet().length;
      if (uniqueTypes >= 5) {
        await _storage.updateAchievementProgress('explorer', 1);
      }

      // Track recommendation action (completion achievements)
      final completedCount = _storage.getCompletedFeedback().length;
      if (completedCount >= 3) {
        await _storage.updateAchievementProgress('action_taker', 1);
      }
      if (completedCount >= 10) {
        await _storage.updateAchievementProgress('self_care_pro', 1);
      }

      // Check if any achievement was just unlocked
      final achievements = _storage.getAllAchievements();
      final justUnlocked = achievements.where((a) {
        return a.isUnlocked &&
            a.unlockedAt != null &&
            DateTime.now().difference(a.unlockedAt!).inSeconds < 5;
      }).toList();

      // Show congratulations for newly unlocked achievements
      for (var achievement in justUnlocked) {
        _showAchievementUnlocked(achievement);
      }
    } catch (e) {
      debugPrint('Achievement tracking failed (non-critical): $e');
      // Continue without achievements - this is not critical
    }
  }

  /// Show achievement unlocked notification
  void _showAchievementUnlocked(Achievement achievement) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(
              achievement.icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Achievement Unlocked!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    achievement.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AchievementsScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assessment (${_currentStep + 1}/$_totalSteps)'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: Colors.grey.shade200,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPssStep(),
                _buildStressorsStep(),
                _buildCopingStep(),
              ],
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : _previousStep,
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _currentStep < _totalSteps - 1 ? 'Next' : 'Finish',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPssStep() {
    return Column(
      children: [
        // Header text
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: const Text(
            PSSQuestions.introText,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryDark,
              height: 1.4,
            ),
          ),
        ),
        // Questions list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: PSSQuestions.questions.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question ${index + 1}/10',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        PSSQuestions.questions[index],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(5, (answerIndex) {
                        return RadioListTile<int>(
                          title: Text(PSSQuestions.answerOptions[answerIndex]),
                          value: answerIndex,
                          groupValue: _pssResponses[index],
                          onChanged: (value) {
                            setState(() => _pssResponses[index] = value!);
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStressorsStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'What is causing you stress?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select all that apply and rate their severity (1-10)',
          style: TextStyle(),
        ),
        const SizedBox(height: 20),
        ...StressorTypes.all.map((stressor) {
          final isSelected = _stressorSeverities.containsKey(stressor);
          final severity = _stressorSeverities[stressor] ?? 5;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: isSelected
                ? Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.5)
                : null,
            child: Column(
              children: [
                CheckboxListTile(
                  title: Row(
                    children: [
                      Text(
                        StressorTypes.getIcon(stressor),
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(stressor)),
                    ],
                  ),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _stressorSeverities[stressor] = 5;
                      } else {
                        _stressorSeverities.remove(stressor);
                      }
                    });
                  },
                ),
                if (isSelected) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Severity:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$severity/10',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: severity >= 8
                                    ? AppTheme.error
                                    : AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Semantics(
                          label: 'Stress severity slider for $stressor',
                          value: '$severity out of 10',
                          hint: 'Swipe left or right to adjust severity level',
                          child: Slider(
                            value: severity.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: '$severity',
                            onChanged: (value) {
                              setState(
                                () => _stressorSeverities[stressor] =
                                    value.toInt(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCopingStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'How do you cope with stress?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select strategies you use and rate how well they work',
          style: TextStyle(),
        ),
        const SizedBox(height: 20),
        ...CopingStrategyTypes.all.map((strategy) {
          final isSelected = _copingFrequencies.containsKey(strategy);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color:
                isSelected ? AppTheme.stressLow.withValues(alpha: 0.1) : null,
            child: Column(
              children: [
                CheckboxListTile(
                  title: Row(
                    children: [
                      Text(
                        CopingStrategyTypes.getIcon(strategy),
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(strategy)),
                    ],
                  ),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _copingFrequencies[strategy] = 'Once a week';
                        _copingEffectiveness[strategy] = 'Neutral';
                      } else {
                        _copingFrequencies.remove(strategy);
                        _copingEffectiveness.remove(strategy);
                      }
                    });
                  },
                ),
                if (isSelected) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Frequency
                        const Text(
                          'Frequency:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        DropdownButton<String>(
                          isExpanded: true,
                          value: _copingFrequencies[strategy],
                          items: CopingStrategyTypes.frequencies
                              .map(
                                (freq) => DropdownMenuItem(
                                  value: freq,
                                  child: Text(freq),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(
                              () => _copingFrequencies[strategy] = value!,
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // Effectiveness
                        const Text(
                          'How effective is it?',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        DropdownButton<String>(
                          isExpanded: true,
                          value: _copingEffectiveness[strategy],
                          items: CopingStrategyTypes.effectiveness
                              .map(
                                (eff) => DropdownMenuItem(
                                  value: eff,
                                  child: Text(eff),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(
                              () => _copingEffectiveness[strategy] = value!,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
