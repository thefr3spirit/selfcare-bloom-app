import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Privacy Policy screen for commercial app
/// Required for Google Play Store compliance (MANDATORY)
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String onlineUrl =
      'https://thefr3spirit.github.io/selfcare-bloom-policies/privacy.html';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lastUpdated =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'View Online',
            onPressed: () => _launchOnlineVersion(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              'Privacy Policy',
              'Last updated: $lastUpdated',
            ),
            const SizedBox(height: 20),
            _buildSection(
              'Introduction',
              '''Selfcare & Bloom ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.

By using the App, you consent to the data practices described in this policy. If you do not agree, please discontinue use of the App.''',
            ),
            _buildSection(
              '1. Information We Collect',
              '''1.1 Account Information:
When you create an account, we collect:
• Name
• Email address
• Age (optional)
• Gender (optional)
• Account credentials

1.2 Assessment & Wellness Data:
We collect data you provide during app use:
• PSS-10 assessment responses
• Stress scores and categories
• Identified stressors and severity ratings
• Coping strategies and effectiveness ratings
• Assessment timestamps and frequency
• Progress tracking data
• Recommendation interactions

1.3 Usage Data:
We automatically collect:
• App interaction patterns
• Feature usage statistics
• Session duration and frequency
• Screen navigation paths
• Error logs and crash reports

1.4 Technical Data:
• Device model and manufacturer
• Operating system version
• App version
• Device ID (for push notifications)
• IP address (for security)
• Time zone settings''',
            ),
            _buildSection(
              '2. How We Use Your Information',
              '''We use your information to:

2.1 Provide Services:
• Generate personalized wellness recommendations
• Track your stress levels over time
• Send assessment reminders (with your consent)
• Display progress analytics
• Provide customer support

2.2 Improve the App:
• Analyze usage patterns (anonymized)
• Fix bugs and improve performance
• Develop new features based on user needs
• Conduct research on stress patterns (anonymized)

2.3 Communication:
• Send important service announcements
• Notify you of policy changes
• Respond to support requests
• Send optional wellness tips (opt-in)

2.4 Legal Compliance:
• Comply with legal obligations
• Enforce our Terms of Service
• Protect against fraud and abuse
• Respond to law enforcement requests''',
            ),
            _buildSection(
              '3. Data Storage & Security',
              '''3.1 Where We Store Your Data:
• Local Storage: Encrypted Hive database on your device
• Cloud Storage: Google Firebase servers (US data centers)
• Backups: Encrypted daily backups on Firebase

3.2 Security Measures:
• End-to-end encryption for data in transit (TLS/SSL)
• AES-256 encryption for data at rest
• Secure authentication via Firebase Auth
• Role-based access controls
• Regular security audits and penetration testing
• Automatic security updates

3.3 Data Retention:
• Active accounts: Data retained while account is active
• Deleted accounts: Data permanently deleted within 30 days
• Backup data: Removed from backups within 90 days
• Anonymized analytics: Retained for 2 years maximum
• Legal compliance: May retain longer if required by law''',
            ),
            _buildSection(
              '4. Data Sharing & Disclosure',
              '''We do NOT sell, rent, or trade your personal information.

We may share data with:

4.1 Service Providers:
• Google Firebase (hosting, authentication, storage)
• Google Cloud Functions (push notifications)
• Cloud storage providers (encrypted backups)
• Analytics services (anonymized data only)

These providers are contractually bound to protect your data and use it only for specified services.

4.2 Legal Requirements:
We may disclose information when required to:
• Comply with court orders or legal processes
• Enforce our Terms of Service
• Protect our rights and property
• Prevent fraud or illegal activity
• Protect user safety in emergencies

4.3 Business Transfers:
In the event of a merger, acquisition, or sale, your data may be transferred. We will notify you and ensure the new entity honors this Privacy Policy.

4.4 With Your Consent:
We may share data for purposes not described here only with your explicit consent.''',
            ),
            _buildSection(
              '5. Your Privacy Rights',
              '''You have the following rights regarding your data:

5.1 Access:
• View all data we have about you
• Request a copy of your data (JSON format)
• Review data collection practices

5.2 Correction:
• Update inaccurate profile information
• Correct assessment data errors
• Edit preferences and settings

5.3 Deletion:
• Delete your account permanently
• Request removal of specific data
• Withdraw consent at any time

5.4 Portability:
• Export your data in a readable format
• Transfer data to another service
• Download assessment history

5.5 Opt-Out:
• Disable push notifications
• Opt out of data analytics
• Unsubscribe from emails

To exercise these rights:
• Go to Settings > Account > Privacy
• Email: privacy@selfcarebloom.com
• We will respond within 30 days''',
            ),
            _buildSection(
              '6. Regional Privacy Laws',
              '''6.1 California Privacy Rights (CCPA):
If you are a California resident, you have additional rights:
• Right to know what data is collected and why
• Right to delete your data
• Right to opt-out of data "sale" (we don't sell data)
• Right to non-discrimination for exercising rights

Contact: privacy@selfcarebloom.com

6.2 European Privacy Rights (GDPR):
If you are in the EU/EEA, you have rights under GDPR:
• Right to access your data
• Right to rectification
• Right to erasure ("right to be forgotten")
• Right to restrict processing
• Right to data portability
• Right to object to processing
• Right to withdraw consent

Legal basis for processing:
• Consent: For optional features
• Contract: To provide services
• Legitimate interests: App improvement
• Legal obligations: Compliance

Contact: dpo@selfcarebloom.com

6.3 Other Jurisdictions:
We comply with applicable data protection laws in Kenya, Uganda, and other countries where the App is available.''',
            ),
            _buildSection(
              '7. Children\'s Privacy',
              '''The App is not intended for children under 13 years of age.

We do not knowingly collect personal information from children under 13. If you believe we have collected data from a child under 13, please contact us immediately at privacy@selfcarebloom.com, and we will delete it promptly.

Parents and guardians: Please monitor your children's app usage.''',
            ),
            _buildSection(
              '8. International Data Transfers',
              '''Your data may be transferred to and processed in countries other than your country of residence, including the United States, where data protection laws may differ.

By using the App, you consent to the transfer of your data to:
• United States (Firebase servers)
• Countries where our service providers operate

We ensure appropriate safeguards through:
• Standard contractual clauses
• Privacy Shield frameworks (where applicable)
• Encryption during transfer''',
            ),
            _buildSection(
              '9. Cookies & Tracking Technologies',
              '''The App uses:

9.1 Essential Technologies:
• Authentication tokens (required for login)
• Session management
• Security features

9.2 Analytics:
• Firebase Analytics (anonymized usage data)
• Crash reporting (error logs)
• Performance monitoring

9.3 Not Used:
• Advertising cookies (we don't show ads)
• Third-party tracking for marketing
• Cross-site tracking

You can disable non-essential tracking in Settings > Privacy.''',
            ),
            _buildSection(
              '10. Third-Party Services',
              '''The App integrates with:

10.1 Firebase Services:
• Firebase Authentication
• Cloud Firestore
• Firebase Cloud Functions
• Firebase Cloud Messaging
• Firebase Analytics

Review Firebase's privacy policy at: 
https://firebase.google.com/support/privacy

10.2 External Links:
The App may contain links to crisis hotlines, mental health resources, or educational content. We are not responsible for the privacy practices of external websites.''',
            ),
            _buildSection(
              '11. Changes to This Privacy Policy',
              '''We may update this Privacy Policy periodically to reflect changes in our practices or legal requirements.

We will notify you of significant changes through:
• Prominent in-app notification
• Email (if you provided one)
• Update notes in app stores
• Notice on our website

Changes take effect:
• Immediately for new users
• 30 days after notification for existing users

Continued use after changes constitutes acceptance. If you disagree with changes, please discontinue use and delete your account.''',
            ),
            _buildSection(
              '12. Data Breach Notification',
              '''In the event of a data breach affecting your personal information, we will:

• Notify affected users within 72 hours
• Provide details about the breach
• Explain steps we're taking to address it
• Advise you on protective measures
• Report to relevant authorities as required by law

Contact our security team: security@selfcarebloom.com''',
            ),
            _buildSection(
              '13. Contact Us',
              '''For privacy questions, concerns, or requests:

Email: privacy@selfcarebloom.com
Support: support@selfcarebloom.com
Website: www.selfcarebloom.com/privacy
Mail: [Your Business Address]

Data Protection Officer: [Name]
DPO Email: dpo@selfcarebloom.com

Response time: Within 30 days (or as required by law)

For urgent privacy concerns, mark your email as "URGENT PRIVACY REQUEST"''',
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.security, color: Colors.green, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Your privacy is our priority',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Thank you for trusting Selfcare & Bloom',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  static Future<void> _launchOnlineVersion(BuildContext context) async {
    final Uri url = Uri.parse(onlineUrl);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open browser'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
