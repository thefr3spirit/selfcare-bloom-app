import 'package:flutter/foundation.dart';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Local notification service for reassessment reminders
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Request notification permissions (Android 13+)
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();

      // Android 13+ requires explicit notification permission
      if (androidInfo >= 33) {
        final status = await Permission.notification.request();
        return status.isGranted;
      }
    }

    // For older Android versions, permissions are granted at install
    return true;
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        return await Permission.notification.isGranted;
      }
    }
    return true;
  }

  /// Schedule daily reassessment reminder
  static Future<void> scheduleDailyReminder({
    int hour = 20, // 8 PM default
    int minute = 0,
  }) async {
    try {
      // Cancel existing notifications first
      await cancelAllNotifications();

      // Schedule notification
      await _notifications.zonedSchedule(
        0, // Notification ID
        'Time for Your Stress Check-In',
        'Take 5 minutes to complete your PSS-10 assessment and see your personalized recommendations.',
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reassessment_reminders',
            'Assessment Reminders',
            channelDescription: 'Reminders to complete stress assessments',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      );
    } catch (e) {
      debugPrint('Failed to schedule daily reminder: $e');
      // Fail silently - notifications are not critical
    }
  }

  /// Schedule one-time reminder after specific days
  static Future<void> scheduleReminderAfterDays(int days) async {
    if (!_initialized) return; // Skip if plugin not initialized (FCM handles notifications)
    try {
      final scheduledDate = DateTime.now().add(Duration(days: days));
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      await _notifications.zonedSchedule(
        1, // Different ID from daily reminder
        'Assessment Due',
        'It\'s been $days days since your last stress assessment. Time to check in!',
        tzScheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reassessment_reminders',
            'Assessment Reminders',
            channelDescription: 'Reminders to complete stress assessments',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Failed to schedule reminder after $days days: $e');
      // Fail silently - notifications are not critical
    }
  }

  /// Schedule testing reminder (every 2 minutes for testing)
  static Future<void> scheduleTestingReminder() async {
    try {
      // Cancel existing notifications first
      await cancelAllNotifications();

      // Schedule multiple notifications 2 minutes apart for next 20 minutes
      // This gives us 10 test notifications
      for (int i = 0; i < 10; i++) {
        final scheduledDate =
            DateTime.now().add(Duration(minutes: 2 * (i + 1)));
        final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

        await _notifications.zonedSchedule(
          i, // Different ID for each notification
          '🧪 Testing: Stress Check-In',
          'This is test notification #${i + 1}. Take your 2-minute stress assessment!',
          tzScheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'testing_reminders',
              'Testing Reminders',
              channelDescription: 'Test notifications every 2 minutes',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      debugPrint('Testing reminders scheduled: 10 notifications over 20 minutes');
    } catch (e) {
      debugPrint('Failed to schedule testing reminders: $e');
    }
  }

  /// Show immediate notification (for testing or urgent alerts)
  static Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      999, // Immediate notification ID
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'immediate_notifications',
          'Immediate Notifications',
          channelDescription: 'Important immediate notifications',
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
    );
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Cancel specific notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Get pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // ============================================================================
  // PRIVATE HELPERS
  // ============================================================================

  /// Calculate next instance of specified time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time is in the past, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Get Android SDK version
  static Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;

    // This is a simplified version - in production, use device_info_plus package
    // For now, assume Android 13+ (API 33+)
    return 33;
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // This will be handled by the app's navigation
    // The app will check if it was opened from notification
    // and navigate to assessment screen
    debugPrint('Notification tapped: ${response.payload}');
  }
}
