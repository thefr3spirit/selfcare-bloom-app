import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'storage_service.dart';

/// Export service for data sharing
/// Generates CSV files and triggers Android share sheet
class ExportService {
  final StorageService _storage = StorageService();

  /// Export all data as CSV and send via email
  Future<bool> exportDataAndShare() async {
    try {
      // Generate CSV content
      final csvContent = await _generateCsvContent();

      // Get Downloads directory to save file persistently
      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/selfcare_export_$timestamp.csv';

      // Write CSV file
      final file = File(filePath);
      await file.writeAsString(csvContent);

      // Get user info for email subject
      final user = _storage.getUserProfile();
      final userName = user?.name ?? 'Anonymous User';

      // Share with email apps preferentially
      // The user will select email app and it will be pre-filled with recipient
      final result = await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'SelfCare Together - Data Export from $userName',
        text: 'TO: obilledwin@gmail.com\n\n'
            'Please send this data export to obilledwin@gmail.com.\n\n'
            'Export Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}\n'
            'User: $userName\n\n'
            'This file contains my PSS assessments, stressors, coping strategies, and recommendations from the SelfCare Together pilot study.',
      );

      // Clean up after 10 seconds (give more time for email attachment)
      Future.delayed(const Duration(seconds: 10), () {
        if (file.existsSync()) {
          file.delete();
        }
      });

      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('Export error: $e');
      return false;
    }
  }

  /// Generate comprehensive CSV content
  Future<String> _generateCsvContent() async {
    final user = _storage.getUserProfile();
    final assessments = _storage.getAllAssessments();
    final stressors = _storage.getLatestStressors();
    final copingStrategies = _storage.getLatestCopingStrategies();
    final recommendations = _storage.getAllRecommendations();
    final settings = _storage.getSettings();

    // Create CSV with multiple sections
    List<List<dynamic>> rows = [];

    // ========== SECTION 1: USER INFO ==========
    rows.add(['===== USER INFORMATION =====']);
    rows.add(['Field', 'Value']);
    rows.add(['User ID', user?.userId ?? 'N/A']);
    rows.add(['Name', user?.name ?? 'N/A']);
    rows.add(['Age', user?.age ?? 'N/A']);
    rows.add(['Gender', user?.gender ?? 'N/A']);
    rows.add(['Consent Given', user?.hasConsented ?? false]);
    rows.add([
      'Consent Timestamp',
      user?.consentTimestamp?.toIso8601String() ?? 'N/A',
    ]);
    rows.add(['Account Created', user?.createdAt.toIso8601String() ?? 'N/A']);
    rows.add([]); // Empty row

    // ========== SECTION 2: ASSESSMENT SUMMARY ==========
    rows.add(['===== ASSESSMENT SUMMARY =====']);
    rows.add(['Total Assessments Completed', assessments.length]);
    rows.add([
      'Current Stress Category',
      assessments.isNotEmpty ? assessments.first.category : 'N/A',
    ]);
    rows.add([
      'Current PSS Score',
      assessments.isNotEmpty ? assessments.first.totalScore : 'N/A',
    ]);
    rows.add(['Crisis Events Logged', settings.crisisEventsLog.length]);
    rows.add([
      'Last Assessment Date',
      settings.lastAssessmentDate?.toIso8601String() ?? 'N/A',
    ]);
    rows.add([
      'Next Assessment Due',
      settings.nextAssessmentDue?.toIso8601String() ?? 'N/A',
    ]);
    rows.add([]); // Empty row

    // ========== SECTION 3: PSS ASSESSMENTS ==========
    rows.add(['===== PSS-10 ASSESSMENTS =====']);
    rows.add([
      'Assessment ID',
      'Date',
      'Total Score (0-40)',
      'Category',
      'Is Crisis',
      'Q1',
      'Q2',
      'Q3',
      'Q4',
      'Q5',
      'Q6',
      'Q7',
      'Q8',
      'Q9',
      'Q10',
    ]);

    for (var assessment in assessments) {
      rows.add([
        assessment.assessmentId,
        DateFormat('yyyy-MM-dd HH:mm').format(assessment.date),
        assessment.totalScore,
        assessment.category,
        assessment.isCrisis,
        assessment.responses[0],
        assessment.responses[1],
        assessment.responses[2],
        assessment.responses[3],
        assessment.responses[4],
        assessment.responses[5],
        assessment.responses[6],
        assessment.responses[7],
        assessment.responses[8],
        assessment.responses[9],
      ]);
    }
    rows.add([]); // Empty row

    // ========== SECTION 4: STRESSORS ==========
    rows.add(['===== CURRENT STRESSORS =====']);
    rows.add([
      'Stressor Type',
      'Severity (1-10)',
      'Is Severe (≥8)',
      'Recorded At',
    ]);

    for (var stressor in stressors) {
      rows.add([
        stressor.type,
        stressor.severity,
        stressor.isSevere,
        DateFormat('yyyy-MM-dd HH:mm').format(stressor.recordedAt),
      ]);
    }
    rows.add([]); // Empty row

    // ========== SECTION 5: COPING STRATEGIES ==========
    rows.add(['===== CURRENT COPING STRATEGIES =====']);
    rows.add([
      'Strategy Name',
      'Frequency',
      'Effectiveness Rating',
      'Is Passive',
      'Recorded At',
    ]);

    for (var strategy in copingStrategies) {
      rows.add([
        strategy.name,
        strategy.frequency,
        strategy.effectivenessRating,
        strategy.isPassive,
        DateFormat('yyyy-MM-dd HH:mm').format(strategy.recordedAt),
      ]);
    }
    rows.add([]); // Empty row

    // ========== SECTION 6: RECOMMENDATIONS ==========
    rows.add(['===== RECOMMENDATIONS GENERATED =====']);
    rows.add([
      'Recommendation ID',
      'Generated At',
      'Type',
      'Priority Score',
      'Title',
      'Message Preview',
      'Is Crisis',
      'Is Viewed',
    ]);

    for (var rec in recommendations) {
      rows.add([
        rec.recommendationId,
        DateFormat('yyyy-MM-dd HH:mm').format(rec.generatedAt),
        rec.type,
        rec.priorityScore.toStringAsFixed(1),
        rec.title,
        rec.message.substring(
          0,
          rec.message.length > 100 ? 100 : rec.message.length,
        ),
        rec.isCrisisRecommendation,
        rec.isViewed,
      ]);
    }
    rows.add([]); // Empty row

    // ========== SECTION 7: CRISIS EVENTS ==========
    if (settings.crisisEventsLog.isNotEmpty) {
      rows.add(['===== CRISIS EVENTS LOG =====']);
      rows.add(['Timestamp']);
      for (var event in settings.crisisEventsLog) {
        rows.add([event]);
      }
      rows.add([]); // Empty row
    }

    // ========== FOOTER ==========
    rows.add(['===== EXPORT INFORMATION =====']);
    rows.add(['Export Generated', DateTime.now().toIso8601String()]);
    rows.add(['App Version', '1.0.0']);
    rows.add(['Study', 'SelfCare Together Pilot (Uganda/Kenya)']);

    // Convert to CSV string
    return const ListToCsvConverter().convert(rows);
  }

  /// Export data and save to Downloads folder (alternative method)
  /// This requires Android storage permissions
  Future<String?> exportToDownloads() async {
    try {
      // Generate CSV content
      final csvContent = await _generateCsvContent();

      // Get Downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');

        // Fallback to getExternalStorageDirectory if Download not accessible
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) return null;

      // Create file
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/selfcare_export_$timestamp.csv';
      final file = File(filePath);
      await file.writeAsString(csvContent);

      return filePath;
    } catch (e) {
      debugPrint('Export to Downloads error: $e');
      return null;
    }
  }

  /// Quick export summary (lightweight version)
  Future<String> generateQuickSummary() async {
    final user = _storage.getUserProfile();
    final latestAssessment = _storage.getLatestAssessment();
    final assessmentCount = _storage.getAssessmentCount();
    final settings = _storage.getSettings();

    return '''
SelfCare Together - Quick Summary

User: ${user?.name ?? 'N/A'}
Total Assessments: $assessmentCount
Current PSS Score: ${latestAssessment?.totalScore ?? 'N/A'}
Stress Category: ${latestAssessment?.category ?? 'N/A'}
Crisis Events: ${settings.crisisEventsLog.length}
Last Assessment: ${settings.lastAssessmentDate != null ? DateFormat('yyyy-MM-dd').format(settings.lastAssessmentDate!) : 'N/A'}

Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}
''';
  }
}
