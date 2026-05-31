import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/pss_assessment.dart';
import '../services/export_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/pss_trend_chart.dart';

/// Progress screen showing charts, statistics, and data export
/// Modern, clean design with visual data insights
class ProgressScreen extends StatefulWidget {
  final bool showAppBar;

  const ProgressScreen({super.key, this.showAppBar = true});

  @override
  State<ProgressScreen> createState() => ProgressScreenState();
}

class ProgressScreenState extends State<ProgressScreen> {
  final StorageService _storage = StorageService();
  final ExportService _export = ExportService();
  bool _isLoading = true;

  List<PSSAssessment> _assessments = [];
  int _totalAssessments = 0;
  double _averageScore = 0;
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Public method to refresh data (called from parent)
  void refresh() {
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _assessments = _storage.getAllAssessments();
    _totalAssessments = _assessments.length;

    if (_totalAssessments > 0) {
      final totalScore =
          _assessments.fold<int>(0, (sum, a) => sum + a.totalScore);
      _averageScore = totalScore / _totalAssessments;
      _currentStreak = _calculateStreak();
    }

    setState(() => _isLoading = false);
  }

  int _calculateStreak() {
    if (_assessments.isEmpty) return 0;

    // Sort by most recent
    final sorted = List<PSSAssessment>.from(_assessments)
      ..sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    DateTime? lastDate;

    for (final assessment in sorted) {
      final assessmentDate = DateTime(
        assessment.date.year,
        assessment.date.month,
        assessment.date.day,
      );

      if (lastDate == null) {
        // First assessment - check if today or yesterday
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final todayDate = DateTime(today.year, today.month, today.day);
        final yesterdayDate =
            DateTime(yesterday.year, yesterday.month, yesterday.day);

        if (assessmentDate == todayDate || assessmentDate == yesterdayDate) {
          streak = 1;
          lastDate = assessmentDate;
        } else {
          break;
        }
      } else {
        // Check if consecutive day
        final expectedDate = lastDate.subtract(const Duration(days: 1));
        if (assessmentDate == expectedDate) {
          streak++;
          lastDate = assessmentDate;
        } else {
          break;
        }
      }
    }

    return streak;
  }

  Future<void> _exportData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const OverlayLoadingIndicator(
        message: 'Exporting your data...',
      ),
    );

    final success = await _export.exportDataAndShare();

    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Data exported successfully!'
                : 'Export failed. Please try again.',
          ),
          backgroundColor: success ? AppTheme.success : AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text(
                'Progress',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.file_download_outlined),
                  tooltip: 'Export Data',
                  onPressed: _exportData,
                ),
              ],
            )
          : null,
      body: _isLoading
          ? const LoadingWidget(message: 'Loading your progress...')
          : _totalAssessments == 0
              ? const EmptyStateWidget(
                  icon: Icons.show_chart_outlined,
                  iconColor: AppTheme.primaryBlue,
                  title: 'No Data Yet',
                  message:
                      'Complete assessments to see your progress trends and statistics',
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Stats cards row
                      _buildStatsRow(theme),

                      const SizedBox(height: 16),

                      // Trend chart
                      _buildTrendChart(theme),

                      const SizedBox(height: 16),

                      // Recent assessments list
                      _buildRecentAssessments(theme),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            icon: Icons.assignment_turned_in,
            label: 'Total',
            value: '$_totalAssessments',
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            theme,
            icon: Icons.trending_up,
            label: 'Average',
            value: _averageScore.toStringAsFixed(1),
            color: theme.colorScheme.tertiary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            theme,
            icon: Icons.local_fire_department,
            label: 'Streak',
            value: '$_currentStreak',
            suffix: _currentStreak == 1 ? ' day' : ' days',
            color: AppTheme.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    String? suffix,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (suffix != null)
                    Text(
                      suffix,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(ThemeData theme) {
    if (_assessments.length < 2) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.insights_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Trend Chart Coming Soon',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Complete at least 2 assessments to see your stress level trends',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stress Level Trend',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            PssTrendChart(assessments: _assessments),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAssessments(ThemeData theme) {
    final recentAssessments = _assessments.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Assessments',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...recentAssessments.map((assessment) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildAssessmentTile(theme, assessment),
            )),
      ],
    );
  }

  Widget _buildAssessmentTile(ThemeData theme, PSSAssessment assessment) {
    Color categoryColor;
    String emoji;

    switch (assessment.category) {
      case 'LOW':
        categoryColor = AppTheme.stressLow;
        emoji = '😊';
        break;
      case 'MODERATE':
        categoryColor = AppTheme.stressModerate;
        emoji = '😐';
        break;
      case 'HIGH':
        categoryColor = AppTheme.stressSevere;
        emoji = '😰';
        break;
      default:
        categoryColor = AppTheme.textSecondary;
        emoji = '❓';
    }

    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      elevation: 0,
      color: categoryColor.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: categoryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: categoryColor.withValues(alpha: 0.2),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Row(
          children: [
            Text(
              '${assessment.totalScore}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: categoryColor,
              ),
            ),
            Text(
              '/40',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                assessment.category,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: categoryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${dateFormat.format(assessment.date)} • ${timeFormat.format(assessment.date)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
