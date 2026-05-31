import 'package:flutter/foundation.dart';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_analytics_service.dart';

/// Firebase Cloud Messaging Service for push notifications
/// Handles daily reminders and engagement notifications
class FirebasePushService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize Firebase Cloud Messaging
  static Future<void> initialize() async {
    try {
      // Request notification permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('User granted provisional notification permission');
      } else {
        debugPrint('User declined notification permission');
        return;
      }

      // Get FCM token
      String? token = await _messaging.getToken();
      debugPrint('FCM Token: $token');

      // Initialize local notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

      // Handle notification opened app
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

      debugPrint('Firebase Push Service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Firebase Push Service: $e');
    }
  }

  // ============================================================================
  // MESSAGE HANDLERS
  // ============================================================================

  /// Handle foreground messages (when app is open)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message received: ${message.notification?.title}');

    // Log notification receipt for analytics
    await NotificationAnalyticsService.logNotificationReceived(
      notificationId: message.messageId ?? 'unknown',
      notificationType: message.data['type'] ?? 'unknown',
      title: message.notification?.title,
      body: message.notification?.body,
    );

    // Show local notification
    await _showLocalNotification(
      title: message.notification?.title ?? 'Selfcare & Bloom',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  /// Handle background messages (when app is closed)
  static Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
    debugPrint('Background message received: ${message.notification?.title}');

    // Log notification receipt for analytics
    await NotificationAnalyticsService.logNotificationReceived(
      notificationId: message.messageId ?? 'unknown',
      notificationType: message.data['type'] ?? 'unknown',
      title: message.notification?.title,
      body: message.notification?.body,
    );
  }

  /// Handle notification tap (opens app)
  static void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('Notification opened: ${message.notification?.title}');

    // Log notification opened for analytics
    final notificationId = message.messageId ?? 'unknown';
    NotificationAnalyticsService.logNotificationOpened(
      notificationId: notificationId,
    );

    // TODO: Navigate to appropriate screen based on message data
    // Example: if (message.data['screen'] == 'assessment') { navigate to assessment }
  }

  /// Handle local notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    // TODO: Navigate based on payload
  }

  // ============================================================================
  // LOCAL NOTIFICATION DISPLAY
  // ============================================================================

  /// Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'selfcare_reminders',
      'Selfcare Reminders',
      channelDescription: 'Daily check-in and stress management reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  // ============================================================================
  // SEND NOTIFICATIONS (For backend/testing)
  // ============================================================================

  /// Send a test notification (for development)
  static Future<void> sendTestNotification() async {
    await _showLocalNotification(
      title: '💙 Daily Check-In',
      body: 'How are you feeling today? Take a 2-minute stress assessment.',
    );
  }

  /// Get FCM token for this device
  static Future<String?> getDeviceToken() async {
    return await _messaging.getToken();
  }

  /// Get unique device ID
  static Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // Unique Android ID
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios';
    }
    return 'unknown_platform';
  }

  /// Store FCM token in Firestore via Cloud Functions
  /// Call this after successful login/registration
  static Future<void> storeFCMToken() async {
    try {
      final token = await getDeviceToken();
      if (token == null) {
        debugPrint('Failed to get FCM token');
        return;
      }

      final deviceId = await getDeviceId();

      // Call Cloud Function to store token
      final callable =
          FirebaseFunctions.instance.httpsCallable('storeFCMToken');
      await callable.call({
        'token': token,
        'deviceId': deviceId,
      });

      debugPrint('FCM token stored successfully: $deviceId');
    } catch (e) {
      debugPrint('Failed to store FCM token: $e');
      // Non-critical error - user can still use app without push notifications
    }
  }

  /// Update notification preferences via Cloud Functions
  static Future<void> updateNotificationPreferences({
    required bool dailyReminder,
    required bool weeklyReport,
    required bool achievementUnlocks,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'updateNotificationPreferences',
      );
      await callable.call({
        'preferences': {
          'dailyReminder': dailyReminder,
          'weeklyReport': weeklyReport,
          'achievementUnlocks': achievementUnlocks,
        },
      });

      debugPrint('Notification preferences updated successfully');
    } catch (e) {
      debugPrint('Failed to update notification preferences: $e');
      rethrow; // Let caller handle the error
    }
  }

  /// Subscribe to topic (for broadcast notifications)
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  // ============================================================================
  // DAILY REMINDER SCHEDULING
  // ============================================================================

  /// Schedule daily reminder notification
  /// This would typically be triggered from a backend server
  /// For MVP, you can use local notifications with flutter_local_notifications
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    // This is a placeholder - actual scheduling should be done via:
    // 1. Firebase Cloud Functions (cron jobs)
    // 2. OR flutter_local_notifications for local scheduling

    debugPrint('Daily reminder would be scheduled for $hour:$minute');
    // Implementation depends on whether you want:
    // - Server-side scheduling (Firebase Cloud Functions)
    // - Client-side scheduling (flutter_local_notifications)
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.notification?.title}');
}
