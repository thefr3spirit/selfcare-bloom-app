import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'assessment_screen.dart';
import 'main_navigation_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

/// Commercial app consent screen - updated for production release
/// User must agree to Terms & Conditions and Privacy Policy
class SimplifiedConsentScreen extends StatefulWidget {
  const SimplifiedConsentScreen({super.key});

  @override
  State<SimplifiedConsentScreen> createState() =>
      _SimplifiedConsentScreenState();
}

class _SimplifiedConsentScreenState extends State<SimplifiedConsentScreen> {
  final StorageService _storage = StorageService();
  bool _hasReadConsent = false;
  bool _isLoading = false;

  Future<void> _submitConsent() async {
    if (!_hasReadConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please read and agree to the Terms & Privacy Policy'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get user info from Firebase Auth
      final firebaseUser = FirebaseService.getCurrentUser();
      final userName = firebaseUser?.displayName ?? 'User';

      // Create user profile with Firebase data
      final user = UserProfile.create(
        name: userName,
        age: null, // Optional - can be added in settings later
        gender: null, // Optional - can be added in settings later
      );

      // Mark consent as given
      user.giveConsent();

      // Save to storage
      await _storage.saveUserProfile(user);

      // Show assessment prompt
      if (mounted) {
        await _showAssessmentPrompt();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAssessmentPrompt() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Theme(
          data: AppTheme.lightTheme,
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.waving_hand, color: Colors.amber, size: 28),
                SizedBox(width: 12),
                Text('Welcome!'),
              ],
            ),
            content: const Text(
              'Thank you for choosing Selfcare & Bloom! Would you like to take your first wellness assessment now?\n\n'
              'It takes about 5 minutes and will help us provide personalized recommendations.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => const MainNavigationScreen()),
                  );
                },
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () {
                  // Pop dialog, clear consent screen from stack, push MainNav,
                  // then push Assessment on top — back button goes to HomeScreen
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const MainNavigationScreen()),
                    (route) => false,
                  );
                  Navigator.of(context, rootNavigator: false).push(
                    MaterialPageRoute(builder: (_) => const AssessmentScreen()),
                  );
                },
                child: const Text('Take Assessment'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: AppTheme.lightTheme,
        child: Scaffold(
          backgroundColor: const Color(0xFFF0FAF9),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // App logo
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/pictures/logo.jpg',
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Welcome text
                  Text(
                    'Welcome to\nSelfcare & Bloom',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Your Personal Wellness Companion',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.primary.withValues(alpha: 0.8)),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // What you get card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What You Get',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.psychology,
                            'Track your stress levels with PSS-10 assessments',
                          ),
                          _buildInfoRow(
                            Icons.lightbulb_outline,
                            'Get personalized coping recommendations',
                          ),
                          _buildInfoRow(
                            Icons.trending_up,
                            'Monitor your wellness progress over time',
                          ),
                          _buildInfoRow(
                            Icons.notifications_active,
                            'Receive gentle reminders for regular check-ins',
                          ),
                          _buildInfoRow(
                            Icons.security,
                            'Your data is private and encrypted',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Important medical disclaimer
                  Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Colors.amber),
                              const SizedBox(width: 8),
                              Text(
                                'Important Information',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'This app is for wellness purposes only and is NOT a substitute '
                            'for professional medical advice, diagnosis, or treatment.\n\n'
                            'If you are experiencing a mental health emergency, please contact '
                            'crisis services immediately:\n'
                            '• Kenya Befrienders: 0722 178 177\n'
                            '• Uganda Crisis Line: 0800 22 00 00',
                            style: TextStyle(height: 1.5, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Terms & Privacy links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TermsScreen()),
                        ),
                        child: const Text('Terms & Conditions'),
                      ),
                      const Text(' • '),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen()),
                        ),
                        child: const Text('Privacy Policy'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Consent checkbox
                  CheckboxListTile(
                    value: _hasReadConsent,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() => _hasReadConsent = value ?? false);
                          },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'I have read and agree to the Terms & Conditions and Privacy Policy',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Continue button
                  FilledButton(
                    onPressed: _isLoading ? null : _submitConsent,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'I Agree - Continue',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Decline option
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Decline Agreement'),
                                content: const Text(
                                  'To use Selfcare & Bloom, you must agree to the Terms & Conditions '
                                  'and Privacy Policy. If you decline, you will need to sign out.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Go Back'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await FirebaseService.signOut();
                                      if (context.mounted) {
                                        Navigator.of(context)
                                            .popUntil((route) => route.isFirst);
                                      }
                                    },
                                    child: const Text('Sign Out'),
                                  ),
                                ],
                              ),
                            );
                          },
                    child: const Text('I do not agree'),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ));
  }
}
