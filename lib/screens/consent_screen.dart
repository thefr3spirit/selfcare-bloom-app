import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/storage_service.dart';
import 'assessment_screen.dart';
import 'main_navigation_screen.dart';

/// Consent screen - shown once on first app launch
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final StorageService _storage = StorageService();

  String? _selectedGender;
  bool _hasReadConsent = false;
  bool _isLoading = false;

  final List<String> _genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submitConsent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_hasReadConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm you\'ve read and agree to participate'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create user profile
      final user = UserProfile.create(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        gender: _selectedGender,
      );

      // Mark consent as given
      user.giveConsent();

      // Save to storage
      await _storage.saveUserProfile(user);

      // Show dialog prompting to take assessment
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
        return AlertDialog(
          title: const Text('Welcome! 👋'),
          content: const Text(
            'Thank you for joining the study! Would you like to take your first stress assessment now?\n\n'
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
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AssessmentScreen()),
                );
              },
              child: const Text('Take Assessment'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // App logo/icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/pictures/logo.jpg',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 24),

                // Welcome text
                Text(
                  'Welcome to\nSelfcare & Bloom',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: Colors.blue.shade900,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Text(
                  'Your personal stress management companion',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.blue.shade700),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Consent information card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Research Participation',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.assignment,
                          'Complete stress assessments (PSS-10)',
                        ),
                        _buildInfoRow(
                          Icons.lightbulb_outline,
                          'Receive personalized recommendations',
                        ),
                        _buildInfoRow(
                          Icons.lock_outline,
                          'Your data stays on your device',
                        ),
                        _buildInfoRow(
                          Icons.volunteer_activism,
                          'Voluntary - stop anytime',
                        ),
                        _buildInfoRow(
                          Icons.computer_outlined,
                          'Works completely offline',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Age field
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Age (Optional)',
                    hintText: 'Enter your age',
                    prefixIcon: Icon(Icons.cake),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final age = int.tryParse(value);
                      if (age == null || age < 13 || age > 120) {
                        return 'Please enter a valid age (13-120)';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Gender dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender (Optional)',
                    prefixIcon: Icon(Icons.people),
                    border: OutlineInputBorder(),
                  ),
                  items: _genders.map((gender) {
                    return DropdownMenuItem(value: gender, child: Text(gender));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedGender = value);
                  },
                ),

                const SizedBox(height: 24),

                // Consent checkbox
                CheckboxListTile(
                  value: _hasReadConsent,
                  onChanged: (value) {
                    setState(() => _hasReadConsent = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'I understand this is a research study and agree to participate. '
                    'I can stop at any time.',
                  ),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Your participation helps us understand stress management better. '
                      'Thank you for contributing to mental health research!',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitConsent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                Text(
                  'By continuing, you acknowledge that your data will be stored '
                  'locally on this device and can be exported for research purposes.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
