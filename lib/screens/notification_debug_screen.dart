import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/firebase_push_service.dart';
import '../services/notification_analytics_service.dart';

/// Debug screen for testing notifications
/// Only enable in development/internal testing builds
class NotificationDebugScreen extends StatefulWidget {
  const NotificationDebugScreen({super.key});

  @override
  State<NotificationDebugScreen> createState() =>
      _NotificationDebugScreenState();
}

class _NotificationDebugScreenState extends State<NotificationDebugScreen> {
  String? _fcmToken;
  String? _deviceId;
  Map<String, dynamic>? _stats;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final token = await FirebasePushService.getDeviceToken();
    final deviceId = await FirebasePushService.getDeviceId();
    final stats = await NotificationAnalyticsService.getNotificationStats();

    setState(() {
      _fcmToken = token;
      _deviceId = deviceId;
      _stats = stats;
      _loading = false;
    });
  }

  void _copyToken() {
    if (_fcmToken != null) {
      Clipboard.setData(ClipboardData(text: _fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FCM Token copied to clipboard')),
      );
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      await FirebasePushService.sendTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Test notification sent'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearOldLogs() async {
    try {
      await NotificationAnalyticsService.clearOldLogs(olderThanDays: 7);
      await _loadData(); // Refresh stats
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Old logs cleared'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔔 Notification Debug'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Debug screen - Remove before production release',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // FCM Token Section
                  _buildSection(
                    'FCM Token',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_fcmToken != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _fcmToken!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _copyToken,
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy Token'),
                          ),
                        ] else
                          const Text('No FCM token available'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Device ID Section
                  _buildSection(
                    'Device ID',
                    Text(
                      _deviceId ?? 'Unknown',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Test Actions
                  _buildSection(
                    'Test Actions',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _sendTestNotification,
                          icon: const Icon(Icons.send),
                          label: const Text('Send Test Notification'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Data'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Analytics Stats
                  _buildSection(
                    'Notification Analytics (Last 30 Days)',
                    _stats != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatRow(
                                'Total Received',
                                _stats!['totalReceived'].toString(),
                                Icons.download_done,
                              ),
                              _buildStatRow(
                                'Total Opened',
                                _stats!['totalOpened'].toString(),
                                Icons.open_in_new,
                              ),
                              _buildStatRow(
                                'Open Rate',
                                _stats!['openRate'].toString(),
                                Icons.percent,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'By Type:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              ...(_stats!['byType'] as Map).entries.map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.only(
                                          left: 16, bottom: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.label,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text('${e.key}: ${e.value}'),
                                        ],
                                      ),
                                    ),
                                  ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _clearOldLogs,
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Clear Old Logs (7+ days)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade300,
                                ),
                              ),
                            ],
                          )
                        : const Text('No analytics data available'),
                  ),

                  const SizedBox(height: 24),

                  // Instructions
                  _buildSection(
                    'Testing Instructions',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInstruction(
                          '1',
                          'Copy FCM token',
                          'Use "Copy Token" button above',
                        ),
                        _buildInstruction(
                          '2',
                          'Open Firebase Console',
                          'Go to Cloud Messaging → Send test message',
                        ),
                        _buildInstruction(
                          '3',
                          'Paste token',
                          'Add token and send test notification',
                        ),
                        _buildInstruction(
                          '4',
                          'Check device',
                          'Notification should appear within seconds',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Text('$label: '),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(String step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.blue,
            child: Text(
              step,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
