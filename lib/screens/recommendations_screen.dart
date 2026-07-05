import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/recommendation.dart';
import '../models/recommendation_feedback.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';

/// Recommendations display screen
class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final StorageService _storage = StorageService();
  List<Recommendation> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);

    _recommendations = _storage.getLatestRecommendations(limit: 5);

    debugPrint(
        'Loaded ${_recommendations.length} recommendations from storage');
    for (var rec in _recommendations) {
      debugPrint(
          '  - ${rec.title} (${rec.type}, priority: ${rec.priorityScore})');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Recommendations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading your recommendations...')
          : _recommendations.isEmpty
              ? CommonEmptyStates.noTips(onRefresh: _loadRecommendations)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _recommendations.length +
                      3, // +2 for score summary and header, +1 for done button
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildScoreSummary();
                    }
                    if (index == 1) {
                      return _buildHeader();
                    }
                    if (index == _recommendations.length + 2) {
                      return _buildDoneButton();
                    }
                    return _buildRecommendationCard(
                        _recommendations[index - 2]);
                  },
                ),
    );
  }

  Widget _buildScoreSummary() {
    final assessment = _storage.getLatestAssessment();
    if (assessment == null) return const SizedBox.shrink();

    // Determine color using AppTheme
    final color = AppTheme.getStressColorByScore(assessment.totalScore);
    String emoji;
    if (assessment.category == 'LOW') {
      emoji = '😊';
    } else if (assessment.category == 'MODERATE') {
      emoji = '😐';
    } else {
      emoji = '😰';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Your Assessment Results',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${assessment.totalScore}/40',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const Text(
                      'PSS Score',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Text(
                    '${assessment.category} STRESS',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hasCrisis = _recommendations.any((r) => r.isCrisisRecommendation);

    return Card(
      color: hasCrisis
          ? AppTheme.error.withValues(alpha: 0.06)
          : Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.3),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasCrisis ? Icons.warning : Icons.lightbulb,
                  color: hasCrisis ? AppTheme.error : AppTheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasCrisis
                        ? 'Urgent Recommendations'
                        : 'Personalized for You',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: hasCrisis
                          ? AppTheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              hasCrisis
                  ? 'We\'ve detected high stress levels. Please review these recommendations carefully and reach out for support.'
                  : 'Based on your assessment, here are evidence-based strategies to help reduce your stress.',
              style: TextStyle(
                color: hasCrisis
                    ? AppTheme.error.withValues(alpha: 0.8)
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Recommendation rec) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: rec.isCrisisRecommendation ? 4 : 2,
      color: rec.isCrisisRecommendation
          ? AppTheme.error.withValues(alpha: 0.06)
          : null,
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getRecommendationColor(rec).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getRecommendationIcon(rec),
            color: _getRecommendationColor(rec),
            size: 24,
          ),
        ),
        title: Text(
          rec.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              rec.type.replaceAll('_', ' '),
              style: TextStyle(
                fontSize: 12,
                color: _getRecommendationColor(rec),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.priority_high,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'Priority: ${rec.priorityScore.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    rec.message,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),

                const SizedBox(height: 16),

                // Evidence basis
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.science,
                        size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rec.evidenceBasis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                if (rec.actions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Action Steps:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...rec.actions.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildClickableText(entry.value),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                // Resources (for crisis recommendations)
                if (rec.resources != null && rec.resources!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      border: Border.all(color: Colors.amber),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.phone, color: Colors.amber),
                            SizedBox(width: 8),
                            Text(
                              'Crisis Resources',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...rec.resources!.map(
                          (resource) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              resource,
                              style: const TextStyle(
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Feedback section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💭 Was this helpful?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildFeedbackButton(
                            context,
                            '👍',
                            'Helpful',
                            AppTheme.success,
                            rec,
                            5,
                          ),
                          _buildFeedbackButton(
                            context,
                            '👌',
                            'Okay',
                            AppTheme.primary,
                            rec,
                            3,
                          ),
                          _buildFeedbackButton(
                            context,
                            '👎',
                            'Not Helpful',
                            AppTheme.accent,
                            rec,
                            1,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Mark as viewed button
                if (!rec.isViewed)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        rec.markAsViewed();
                        await _storage.saveRecommendations(_recommendations);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Marked as viewed')),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Mark as Viewed'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text(
            'Done — Back to Home',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppTheme.primary,
          ),
        ),
      ),
    );
  }

  Color _getRecommendationColor(Recommendation rec) {
    if (rec.isCrisisRecommendation) return AppTheme.error;
    switch (rec.type) {
      case 'STRESSOR_INTERVENTION':
        return AppTheme.accent;
      case 'COPING_STRATEGY':
        return AppTheme.success;
      case 'BEHAVIORAL_SHIFT':
        return Colors.purple;
      default:
        return AppTheme.primary;
    }
  }

  IconData _getRecommendationIcon(Recommendation rec) {
    if (rec.isCrisisRecommendation) return Icons.warning;
    switch (rec.type) {
      case 'STRESSOR_INTERVENTION':
        return Icons.healing;
      case 'COPING_STRATEGY':
        return Icons.self_improvement;
      case 'BEHAVIORAL_SHIFT':
        return Icons.sync_alt;
      default:
        return Icons.lightbulb;
    }
  }

  /// Build text with clickable URLs
  Widget _buildClickableText(String text) {
    // Regular expression to detect URLs
    final urlRegex = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );

    final matches = urlRegex.allMatches(text);

    if (matches.isEmpty) {
      // No URLs, return plain text
      return Text(
        text,
        style: const TextStyle(fontSize: 14, height: 1.4),
      );
    }

    // Build TextSpans with clickable links
    final spans = <TextSpan>[];
    int lastMatchEnd = 0;

    for (final match in matches) {
      // Add text before the URL
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: const TextStyle(fontSize: 14, height: 1.4),
        ));
      }

      // Add clickable URL
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: const TextStyle(
          fontSize: 14,
          height: 1.4,
          color: AppTheme.info,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not open $url')),
                );
              }
            }
          },
      ));

      lastMatchEnd = match.end;
    }

    // Add remaining text after last URL
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: const TextStyle(fontSize: 14, height: 1.4),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  /// Build feedback button
  Widget _buildFeedbackButton(
    BuildContext context,
    String emoji,
    String label,
    Color color,
    Recommendation rec,
    int rating,
  ) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () async {
          // Save feedback to database
          try {
            // Get current PSS score from latest assessment
            final latestAssessment = _storage.getLatestAssessment();

            // Create feedback object
            final feedback = RecommendationFeedback.create(
              recommendationId: rec.recommendationId,
              recommendationType: rec.type,
              recommendationTitle: rec.title,
              currentPssScore: latestAssessment?.totalScore,
            );

            // Set the rating directly (don't call rate() which calls save()
            // before the object is in a Hive box)
            feedback.helpfulnessRating = rating;

            // Save to local storage first (adds to Hive box)
            await _storage.saveFeedback(feedback);

            // Sync to Firebase (non-blocking)
            FirebaseService.backupFeedback(feedback.toMap()).catchError((e) {
              debugPrint('Firebase feedback sync failed (non-critical): $e');
            });

            // Show confirmation
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Thanks for your feedback! Rated: $label'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppTheme.success,
                ),
              );
            }
          } catch (e) {
            debugPrint('Error saving feedback: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error saving feedback. Please try again.'),
                  backgroundColor: AppTheme.error,
                ),
              );
            }
          }

          // Mark recommendation as viewed if not already
          if (!rec.isViewed) {
            rec.markAsViewed();
            await _storage.saveRecommendations(_recommendations);
            setState(() {});
          }
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: color),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
