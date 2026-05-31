import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Widget displayed when a list or section has no content
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: iconColor ?? theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pre-configured empty state for common scenarios
class CommonEmptyStates {
  /// No stress assessments recorded yet
  static Widget noAssessments({VoidCallback? onTakeAssessment}) {
    return EmptyStateWidget(
      icon: Icons.assessment_outlined,
      iconColor: AppTheme.primary,
      title: 'No Assessments Yet',
      message:
          'Start tracking your stress levels by completing your first assessment.',
      actionLabel: onTakeAssessment != null ? 'Take Assessment' : null,
      onAction: onTakeAssessment,
    );
  }

  /// No history records available
  static Widget noHistory() {
    return const EmptyStateWidget(
      icon: Icons.history,
      title: 'No History',
      message:
          'Your assessment history will appear here once you complete your first stress check.',
    );
  }

  /// No tips available for current stress level
  static Widget noTips({VoidCallback? onRefresh}) {
    return EmptyStateWidget(
      icon: Icons.lightbulb_outline,
      iconColor: AppTheme.accent,
      title: 'No Tips Available',
      message:
          'We couldn\'t find personalized tips at the moment. Please try again later.',
      actionLabel: onRefresh != null ? 'Refresh' : null,
      onAction: onRefresh,
    );
  }

  /// No notifications
  static Widget noNotifications() {
    return const EmptyStateWidget(
      icon: Icons.notifications_none,
      title: 'No Notifications',
      message: 'You\'re all caught up! Check back later for updates.',
    );
  }

  /// No search results
  static Widget noSearchResults({required String query}) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'No Results Found',
      message:
          'We couldn\'t find anything matching "$query". Try a different search term.',
    );
  }

  /// Offline state
  static Widget offline({VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.cloud_off,
      iconColor: Colors.grey,
      title: 'You\'re Offline',
      message: 'Check your internet connection and try again.',
      actionLabel: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
    );
  }

  /// Content deleted
  static Widget contentDeleted({VoidCallback? onGoBack}) {
    return EmptyStateWidget(
      icon: Icons.delete_outline,
      iconColor: Colors.grey,
      title: 'Content Deleted',
      message: 'This content has been removed.',
      actionLabel: onGoBack != null ? 'Go Back' : null,
      onAction: onGoBack,
    );
  }
}
