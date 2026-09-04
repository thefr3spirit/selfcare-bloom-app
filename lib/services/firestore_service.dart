import 'package:flutter/foundation.dart';

import '../models/coping_strategy.dart';
import '../models/pss_assessment.dart';
import '../models/recommendation.dart';
import '../models/stressor.dart';
import '../models/user_profile.dart';

/// Firestore Cloud Sync Service — DISABLED.
///
/// cloud_firestore pulls in a gRPC/abseil/leveldb/nanopb C++ dependency
/// chain that App Store Connect rejects at upload validation with
/// "No architectures in the binary" (confirmed via bisection against a
/// minimal throwaway app — see git history). The app is offline-first
/// (Hive) by design, so cloud sync/backup is now a no-op; every method
/// below keeps its original signature so existing call sites don't need
/// to change, and behaves exactly as it already did when unauthenticated
/// or offline (skip / return empty / no-op).
class FirestoreService {
  /// Always false — cloud sync is disabled.
  static bool get isAuthenticated => false;

  static Future<void> syncUserProfile(UserProfile profile) async {
    debugPrint('⏭️ Cloud sync disabled - skipping profile sync');
  }

  static Future<Map<String, dynamic>?> fetchUserProfile() async => null;

  static Future<void> syncAssessment(PSSAssessment assessment) async {
    debugPrint('⏭️ Cloud sync disabled - skipping assessment sync');
  }

  static Future<List<Map<String, dynamic>>> fetchAssessments() async => [];

  static Future<void> syncStressors(
      List<Stressor> stressors, String assessmentId) async {
    debugPrint('⏭️ Cloud sync disabled - skipping stressors sync');
  }

  static Future<List<Map<String, dynamic>>> fetchStressors() async => [];

  static Future<void> syncCopingStrategies(
      List<CopingStrategy> strategies, String assessmentId) async {
    debugPrint('⏭️ Cloud sync disabled - skipping coping strategies sync');
  }

  static Future<List<Map<String, dynamic>>> fetchCopingStrategies() async =>
      [];

  static Future<void> syncRecommendations(
      List<Recommendation> recommendations) async {
    debugPrint('⏭️ Cloud sync disabled - skipping recommendations sync');
  }

  static Future<List<Map<String, dynamic>>> fetchRecommendations() async =>
      [];

  /// Perform initial sync on app startup/login — no-op (cloud sync disabled).
  static Future<void> performInitialSync() async {
    debugPrint('⏭️ Cloud sync disabled - skipping initial sync');
  }

  static Future<void> performFullBackup({
    required UserProfile? profile,
    required List<PSSAssessment> assessments,
    required List<Stressor> stressors,
    required List<CopingStrategy> strategies,
    required List<Recommendation> recommendations,
  }) async {
    debugPrint('⏭️ Cloud sync disabled - skipping full backup');
  }

  static Future<bool> hasNewerCloudData(DateTime localLastSync) async => false;

  static Future<Map<String, int>> getCloudDataStats() async => {
        'assessments': 0,
        'stressors': 0,
        'strategies': 0,
        'recommendations': 0,
      };

  static Future<bool> testConnection() async => false;

  /// Clear all user data from Firestore (for account deletion) — no-op,
  /// since no data is ever written to Firestore now.
  static Future<void> deleteAllUserData() async {
    debugPrint('⏭️ Cloud sync disabled - no cloud data to delete');
  }
}
