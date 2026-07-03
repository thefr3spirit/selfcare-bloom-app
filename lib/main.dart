import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'models/user_profile.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/simplified_consent_screen.dart';
import 'services/firebase_push_service.dart';
import 'services/firebase_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');

    // Initialize Firebase Push Notifications
    await FirebasePushService.initialize();
  } catch (e) {
    debugPrint('Firebase initialization failed (non-critical): $e');
    // App continues to work without Firebase
  }

  // Initialize storage
  await StorageService.initialize();

  // 🔔 PRODUCTION NOTIFICATIONS: Firebase Cloud Messaging
  // Notifications are handled by FCM + Cloud Functions (server-side)
  // - Daily reminders: 8 PM EAT (Cloud Function: sendDailyReminder)
  // - Inactive users: 2 PM EAT (Cloud Function: sendInactiveUserReminder)
  // - Weekly reports: Sunday 8 PM (Cloud Function: sendWeeklyReport)
  // - Achievement unlocks: Real-time (Cloud Function: onAchievementUnlock)
  //
  // FCM tokens are automatically stored after authentication
  // No client-side scheduling needed - Cloud Functions handle everything

  debugPrint('✅ FCM notifications enabled via Cloud Functions');

  // Set preferred orientations (portrait only for simplicity)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load saved theme preference
  await ThemeNotifier.instance.initialize();

  runApp(const SelfCareTogetherApp());
}

class SelfCareTogetherApp extends StatelessWidget {
  const SelfCareTogetherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeNotifier.instance,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Selfcare & Bloom',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const AppInitializer(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/onboarding': (context) => const OnboardingScreen(),
          },
          // Accessibility: Limit text scaling to prevent layout issues
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                // Clamp text scale between 0.8 and 1.5 for readability
                textScaler: TextScaler.linear(
                  MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.5),
                ),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}

/// Initializer widget to determine which screen to show first
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  final StorageService _storage = StorageService();
  bool _isLoading = true;
  bool _hasConsented = false;
  bool _isAuthenticated = false;
  bool _onboardingComplete = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    _requestNotificationPermissions();
  }

  Future<void> _initialize() async {
    // Check onboarding status
    final prefs = await SharedPreferences.getInstance();
    _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    // Check authentication status (guard against Firebase not being initialized)
    try {
      _isAuthenticated = FirebaseService.isSignedIn();
    } catch (_) {
      _isAuthenticated = false;
    }

    // Check local storage first
    var user = _storage.getUserProfile();

    // If authenticated but no local consent, check Firestore (returning user after sign-out)
    if (_isAuthenticated && (user == null || !user.hasConsented)) {
      try {
        final cloudData = await FirestoreService.fetchUserProfile();
        if (cloudData != null && cloudData['hasConsented'] == true) {
          user = UserProfile.create(
            name: cloudData['name'] as String? ??
                FirebaseService.getUserDisplayName() ??
                'User',
            age: cloudData['age'] as int?,
            gender: cloudData['gender'] as String?,
          );
          user.giveConsent();
          await _storage.saveUserProfile(user);
        }
      } catch (_) {
        // Firestore unavailable — proceed to consent screen
      }
    }

    setState(() {
      _hasConsented = user?.hasConsented ?? false;
      _isLoading = false;
    });
  }

  Future<void> _requestNotificationPermissions() async {
    // Request notification permissions on Android 13+
    try {
      await NotificationService.requestPermissions();
    } catch (e) {
      debugPrint('Notification permission request failed (non-critical): $e');
      // App continues to work without notifications
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Authentication flow:
    // 1. First launch -> OnboardingScreen
    // 2. Not authenticated -> LoginScreen
    // 3. Authenticated but no consent -> SimplifiedConsentScreen
    // 4. Authenticated and consented -> MainNavigationScreen

    // Show onboarding on first launch
    if (!_onboardingComplete) {
      return const OnboardingScreen();
    }

    if (!_isAuthenticated) {
      return const LoginScreen();
    }

    return _hasConsented
        ? const MainNavigationScreen()
        : const SimplifiedConsentScreen();
  }
}
