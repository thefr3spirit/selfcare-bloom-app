import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_service.dart';

/// Analytics service for tracking notification delivery and engagement
/// Helps measure notification effectiveness and user engagement
class NotificationAnalyticsService {
  static final _firestore = FirebaseFirestore.instance;

  /// Log when user receives a notification (called in FCM message handler)
  static Future<void> logNotificationReceived({
    required String notificationId,
    required String notificationType,
    String? title,
    String? body,
  }) async {
    try {
      final uid = FirebaseService.getCurrentUser()?.uid;
      if (uid == null) return;

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notification_logs')
          .add({
        'notificationId': notificationId,
        'type':
            notificationType, // 'daily_reminder', 'inactive_user', 'weekly_report', 'achievement'
        'title': title,
        'body': body,
        'receivedAt': FieldValue.serverTimestamp(),
        'opened': false,
        'device': 'android', // Could be dynamic based on Platform.isAndroid
      });

      debugPrint('✅ Notification logged: $notificationType');
    } catch (e) {
      debugPrint('⚠️ Failed to log notification received: $e');
      // Non-critical - don't block user experience
    }
  }

  /// Log when user opens/taps a notification
  static Future<void> logNotificationOpened({
    required String notificationId,
  }) async {
    try {
      final uid = FirebaseService.getCurrentUser()?.uid;
      if (uid == null) return;

      // Find the notification log by ID
      final logs = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notification_logs')
          .where('notificationId', isEqualTo: notificationId)
          .limit(1)
          .get();

      if (logs.docs.isNotEmpty) {
        await logs.docs.first.reference.update({
          'opened': true,
          'openedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Notification opened logged: $notificationId');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to log notification opened: $e');
      // Non-critical - don't block user experience
    }
  }

  /// Get notification engagement stats for current user
  static Future<Map<String, dynamic>> getNotificationStats({
    int lastDays = 30,
  }) async {
    try {
      final uid = FirebaseService.getCurrentUser()?.uid;
      if (uid == null) {
        return {'error': 'User not authenticated'};
      }

      final cutoffDate = DateTime.now().subtract(Duration(days: lastDays));

      final logs = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notification_logs')
          .where('receivedAt', isGreaterThan: cutoffDate)
          .get();

      final totalReceived = logs.docs.length;
      final totalOpened =
          logs.docs.where((doc) => doc.data()['opened'] == true).length;
      final openRate = totalReceived > 0
          ? (totalOpened / totalReceived * 100).toStringAsFixed(1)
          : '0.0';

      // Count by type
      final byType = <String, int>{};
      for (var doc in logs.docs) {
        final type = doc.data()['type'] as String? ?? 'unknown';
        byType[type] = (byType[type] ?? 0) + 1;
      }

      return {
        'totalReceived': totalReceived,
        'totalOpened': totalOpened,
        'openRate': '$openRate%',
        'byType': byType,
        'lastDays': lastDays,
      };
    } catch (e) {
      debugPrint('⚠️ Failed to get notification stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Clear old notification logs (privacy/storage management)
  static Future<void> clearOldLogs({int olderThanDays = 90}) async {
    try {
      final uid = FirebaseService.getCurrentUser()?.uid;
      if (uid == null) return;

      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));

      final oldLogs = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notification_logs')
          .where('receivedAt', isLessThan: cutoffDate)
          .get();

      final batch = _firestore.batch();
      for (var doc in oldLogs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ Cleared ${oldLogs.docs.length} old notification logs');
    } catch (e) {
      debugPrint('⚠️ Failed to clear old logs: $e');
    }
  }
}
