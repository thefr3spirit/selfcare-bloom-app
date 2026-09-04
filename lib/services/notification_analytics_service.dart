import 'package:flutter/foundation.dart';

/// Analytics service for tracking notification delivery and engagement —
/// DISABLED.
///
/// This was Firestore-backed; cloud_firestore pulls in a gRPC/abseil/
/// leveldb/nanopb C++ dependency chain that App Store Connect rejects at
/// upload validation with "No architectures in the binary" (confirmed via
/// bisection against a minimal throwaway app — see git history). Every
/// method below keeps its original signature so existing call sites don't
/// need to change, and is a no-op — these calls were already non-critical
/// (wrapped in try/catch, never blocking the user experience).
class NotificationAnalyticsService {
  static Future<void> logNotificationReceived({
    required String notificationId,
    required String notificationType,
    String? title,
    String? body,
  }) async {
    debugPrint('⏭️ Notification analytics disabled - skipping log');
  }

  static Future<void> logNotificationOpened({
    required String notificationId,
  }) async {
    debugPrint('⏭️ Notification analytics disabled - skipping log');
  }

  static Future<Map<String, dynamic>> getNotificationStats({
    int lastDays = 30,
  }) async {
    return {'error': 'Notification analytics disabled'};
  }

  static Future<void> clearOldLogs({int olderThanDays = 90}) async {
    debugPrint('⏭️ Notification analytics disabled - nothing to clear');
  }
}
