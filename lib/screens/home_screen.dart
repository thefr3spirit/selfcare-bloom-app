import 'package:flutter/material.dart';

import '../models/pss_assessment.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import 'assessment_screen.dart';
import 'recommendations_screen.dart';

/// Modern home screen - Main dashboard with quick access
/// Minimal scrolling, clean design
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final StorageService _storage = StorageService();
  PSSAssessment? _latestAssessment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh data when app resumes
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _latestAssessment = _storage.getLatestAssessment();
    setState(() => _isLoading = false);
  }

  /// Public method to refresh data (called from parent widget)
  void refresh() {
    _loadData();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = _storage.getUserProfile();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Selfcare & Bloom',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading your wellness data...')
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // Greeting Card
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.waving_hand,
                              color: Colors.amber,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name != null &&
                                          user!.name.isNotEmpty &&
                                          user.name != 'User'
                                      ? '${_getGreeting()},'
                                      : _getGreeting(),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (user?.name != null &&
                                    user!.name.isNotEmpty &&
                                    user.name != 'User')
                                  Text(
                                    user.name,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Current stress status card
                    _buildStressCard(theme),

                    const SizedBox(height: 16),

                    // Assessment CTA
                    _buildAssessmentButton(theme),

                    const SizedBox(height: 16),

                    // Recommendations preview (if available)
                    if (_latestAssessment != null)
                      _buildRecommendationsPreview(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStressCard(ThemeData theme) {
    if (_latestAssessment == null) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.psychology_outlined,
                  size: 48,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Start your wellness journey',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Take your first stress assessment to understand your mental health better',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Get stress level details using AppTheme
    final score = _latestAssessment!.totalScore;
    final category = _latestAssessment!.category;

    // Use AppTheme for stress color coding
    final foregroundColor = AppTheme.getStressColorByScore(score);
    final backgroundColor = foregroundColor.withValues(alpha: 0.1);

    String emoji;
    String label;

    switch (category) {
      case 'LOW':
        emoji = '😊';
        label = 'Low Stress';
        break;
      case 'MODERATE':
        emoji = '😐';
        label = 'Moderate Stress';
        break;
      case 'HIGH':
        emoji = '😰';
        label = 'High Stress';
        break;
      default:
        emoji = '❓';
        label = 'Unknown';
    }

    return Card(
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.space2XL,
          horizontal: AppTheme.spaceXL,
        ),
        child: Column(
          children: [
            // Centered stress score circle
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surface,
                border: Border.all(color: foregroundColor, width: 5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 44)),
                  const SizedBox(height: 4),
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: foregroundColor,
                    ),
                  ),
                  Text(
                    '/40',
                    style: TextStyle(
                      fontSize: 16,
                      color: foregroundColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Centered label
            Text(
              label,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: foregroundColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentButton(ThemeData theme) {
    final shouldTakeNewAssessment = _latestAssessment == null ||
        DateTime.now().difference(_latestAssessment!.date).inHours >= 24;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AssessmentScreen()),
          );
          if (result == true && mounted) {
            _loadData();
          }
        },
        icon: const Icon(Icons.assignment, size: 22),
        label: Text(
          shouldTakeNewAssessment ? 'Take New Assessment' : 'Retake Assessment',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsPreview(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RecommendationsScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.lightbulb,
                  color: theme.colorScheme.onSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personalized Tips',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View wellness recommendations',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer
                            .withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSecondaryContainer
                    .withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
