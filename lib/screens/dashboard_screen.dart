import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/pss_assessment.dart';
import '../services/export_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pss_trend_chart.dart';
import 'achievements_screen.dart';
import 'assessment_screen.dart';
import 'profile_screen.dart';
import 'recommendations_screen.dart';

/// Main dashboard - home screen of the app
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StorageService _storage = StorageService();
  final ExportService _export = ExportService();

  PSSAssessment? _latestAssessment;
  AppSettings? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _latestAssessment = _storage.getLatestAssessment();
    _settings = _storage.getSettings();

    setState(() => _isLoading = false);
  }

  Future<void> _exportData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final success = await _export.exportDataAndShare();

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Data exported! Share via your preferred app.'
                : 'Export failed. Please try again.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _storage.getUserProfile();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Selfcare & Bloom',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Export Data',
            onPressed: _exportData,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome card
                    Card(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.35),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${user?.name ?? 'User'}! 👋',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getWelcomeMessage(),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Current stress status
                    _buildStressStatusCard(),

                    const SizedBox(height: 20),

                    // Assessment button or due notice
                    _buildAssessmentCard(),

                    const SizedBox(height: 20),

                    // Recommendations summary
                    if (_latestAssessment != null) _buildRecommendationsCard(),

                    const SizedBox(height: 20),

                    // Stats card
                    _buildStatsCard(),

                    const SizedBox(height: 20),

                    // PSS Trend Chart
                    if (_storage.getAssessmentCount() >= 2)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: PssTrendChart(
                            assessments: _storage.getAllAssessments(),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Achievements button
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AchievementsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.emoji_events),
                      label: const Text('View Achievements'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStressStatusCard() {
    if (_latestAssessment == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 60,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              const Text(
                'No assessments yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Take your first PSS-10 assessment to get started!',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final category = _latestAssessment!.category;
    Color color;
    String emoji;
    String label;

    switch (category) {
      case 'LOW':
        color = Colors.green;
        emoji = '😊';
        label = 'Low Stress';
        break;
      case 'MODERATE':
        color = Colors.orange;
        emoji = '😐';
        label = 'Moderate Stress';
        break;
      case 'HIGH':
        color = Colors.red;
        emoji = '😰';
        label = 'High Stress';
        break;
      default:
        color = Colors.grey;
        emoji = '❓';
        label = 'Unknown';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Your Current Stress Level',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Stress score circle
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
                border: Border.all(color: color, width: 3),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 4),
                  Text(
                    '${_latestAssessment!.totalScore}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '/40',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            if (_latestAssessment!.isCrisis) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Crisis level detected. Please check your recommendations.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentCard() {
    final isDue = _settings?.isAssessmentDue ?? true;
    final daysUntil = _settings?.daysUntilNextAssessment ?? 0;

    return Card(
      color: isDue
          ? Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.35)
          : null,
      child: InkWell(
        onTap: () => _navigateToAssessment(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.assignment,
                  size: 32,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDue ? 'Assessment Due!' : 'Take Assessment',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isDue
                          ? 'Time for your PSS-10 check-in'
                          : daysUntil > 0
                              ? 'Next due in $daysUntil days'
                              : 'Check your stress level',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final recommendations = _storage.getLatestRecommendations(limit: 3);

    return Card(
      child: InkWell(
        onTap: () => _navigateToRecommendations(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Recommendations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      color: Theme.of(context).colorScheme.primary),
                ],
              ),
              const SizedBox(height: 16),
              if (recommendations.isEmpty)
                const Text(
                  'Complete an assessment to get personalized recommendations',
                )
              else
                ...recommendations.take(2).map(
                      (rec) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              rec.isCrisisRecommendation
                                  ? Icons.warning
                                  : Icons.lightbulb_outline,
                              size: 20,
                              color: rec.isCrisisRecommendation
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                rec.title.replaceAll(RegExp(r'[^\w\s]'), ''),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final assessmentCount = _storage.getAssessmentCount();
    final crisisCount = _settings?.crisisEventsLog.length ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Progress',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.assignment_turned_in,
                    '$assessmentCount',
                    'Assessments',
                    AppTheme.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.trending_up,
                    _latestAssessment != null
                        ? '${_latestAssessment!.totalScore}'
                        : '-',
                    'Latest PSS',
                    AppTheme.accent,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.shield,
                    crisisCount > 0 ? '$crisisCount' : '0',
                    'Alerts',
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _getWelcomeMessage() {
    if (_latestAssessment == null) {
      return 'Let\'s start by understanding your current stress level.';
    }

    final daysSinceAssessment =
        DateTime.now().difference(_latestAssessment!.date).inDays;

    if (_settings?.isAssessmentDue ?? true) {
      return 'Time for your check-in! Let\'s see how you\'re doing today.';
    }

    if (daysSinceAssessment == 0) {
      return 'Great job completing your assessment today!';
    }

    return 'Keep track of your stress levels regularly for better insights.';
  }

  void _navigateToAssessment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AssessmentScreen()),
    );

    if (result == true) {
      _loadData(); // Refresh data after assessment
    }
  }

  void _navigateToRecommendations() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecommendationsScreen()),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              subtitle: Text(
                _settings?.notificationsEnabled ?? true
                    ? 'Enabled'
                    : 'Disabled',
              ),
              onTap: () {
                // Toggle notifications
                Navigator.pop(context);
                _toggleNotifications();
              },
            ),
            const ListTile(
              leading: Icon(Icons.info),
              title: Text('About'),
              subtitle: Text('Selfcare & Bloom v1.0'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleNotifications() async {
    final settings = _storage.getSettings();
    settings.notificationsEnabled = !settings.notificationsEnabled;
    await _storage.saveSettings(settings);

    try {
      if (settings.notificationsEnabled) {
        await NotificationService.scheduleDailyReminder(hour: 20, minute: 0);
      } else {
        await NotificationService.cancelAllNotifications();
      }
    } catch (e) {
      debugPrint('Notification toggle failed: $e');
      // Show user-friendly message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications not available on this device'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      // Revert the setting
      settings.notificationsEnabled = !settings.notificationsEnabled;
      await _storage.saveSettings(settings);
      setState(() => _settings = settings);
      return;
    }

    setState(() => _settings = settings);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          settings.notificationsEnabled
              ? 'Notifications enabled (8 PM daily)'
              : 'Notifications disabled',
        ),
      ),
    );
  }
}
