import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Full-screen error display with retry option
class ErrorDisplay extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  final Color iconColor;

  const ErrorDisplay({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.iconColor = AppTheme.error,
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
              color: iconColor,
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
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
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

/// Inline error banner (non-intrusive)
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.onDismiss,
    this.backgroundColor = const Color(0xFFFFF1F2),
    this.textColor = AppTheme.error,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: TextStyle(color: textColor),
              ),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.close, color: textColor, size: 20),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pre-configured error displays for common scenarios
class CommonErrors {
  /// Network/connectivity error
  static Widget networkError({VoidCallback? onRetry}) {
    return ErrorDisplay(
      icon: Icons.wifi_off,
      iconColor: AppTheme.accent,
      title: 'Connection Error',
      message:
          'Unable to connect to the server. Please check your internet connection and try again.',
      onRetry: onRetry,
    );
  }

  /// Server error (500)
  static Widget serverError({VoidCallback? onRetry}) {
    return ErrorDisplay(
      icon: Icons.cloud_off,
      iconColor: AppTheme.error,
      title: 'Server Error',
      message: 'Something went wrong on our end. Please try again later.',
      onRetry: onRetry,
    );
  }

  /// Permission denied
  static Widget permissionDenied({VoidCallback? onRetry}) {
    return ErrorDisplay(
      icon: Icons.lock_outline,
      iconColor: AppTheme.accent,
      title: 'Permission Denied',
      message:
          'You don\'t have permission to access this content. Please log in and try again.',
      onRetry: onRetry,
    );
  }

  /// Content not found (404)
  static Widget notFound({VoidCallback? onGoBack}) {
    return ErrorDisplay(
      icon: Icons.search_off,
      iconColor: Colors.grey,
      title: 'Not Found',
      message:
          'The content you\'re looking for doesn\'t exist or has been removed.',
      onRetry: onGoBack,
    );
  }

  /// Generic error
  static Widget generic({required String message, VoidCallback? onRetry}) {
    return ErrorDisplay(
      message: message,
      onRetry: onRetry,
    );
  }

  /// Network error banner
  static Widget networkErrorBanner(
      {VoidCallback? onRetry, VoidCallback? onDismiss}) {
    return ErrorBanner(
      message: 'No internet connection',
      onRetry: onRetry,
      onDismiss: onDismiss,
      icon: Icons.wifi_off,
    );
  }

  /// Sync error banner
  static Widget syncErrorBanner(
      {VoidCallback? onRetry, VoidCallback? onDismiss}) {
    return ErrorBanner(
      message: 'Failed to sync your data',
      onRetry: onRetry,
      onDismiss: onDismiss,
    );
  }

  /// Save error banner
  static Widget saveErrorBanner(
      {VoidCallback? onRetry, VoidCallback? onDismiss}) {
    return ErrorBanner(
      message: 'Failed to save changes',
      onRetry: onRetry,
      onDismiss: onDismiss,
    );
  }

  /// Warning banner (yellow)
  static Widget warningBanner({
    required String message,
    VoidCallback? onDismiss,
  }) {
    return ErrorBanner(
      message: message,
      onDismiss: onDismiss,
      backgroundColor: const Color(0xFFFEFCE8),
      textColor: AppTheme.accent,
      icon: Icons.warning_amber,
    );
  }

  /// Info banner (blue)
  static Widget infoBanner({
    required String message,
    VoidCallback? onDismiss,
  }) {
    return ErrorBanner(
      message: message,
      onDismiss: onDismiss,
      backgroundColor: AppTheme.primaryLight,
      textColor: AppTheme.primary,
      icon: Icons.info_outline,
    );
  }
}
