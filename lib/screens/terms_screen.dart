import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

/// Terms & Conditions screen for commercial app
/// Required for Google Play Store compliance
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const String onlineUrl =
      'https://thefr3spirit.github.io/selfcare-bloom-policies/terms.html';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lastUpdated =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
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
              'Terms of Service',
              'Last updated: $lastUpdated',
            ),
            const SizedBox(height: 20),
            _buildSection(
              '1. Acceptance of Terms',
              '''By downloading, installing, or using Selfcare & Bloom ("the App"), you agree to be bound by these Terms & Conditions. If you do not agree, do not use the App.''',
            ),
            _buildSection(
              '2. Description of Service',
              '''Selfcare & Bloom is a wellness application that provides:

• Stress assessment tools (PSS-10)
• Stressor identification and tracking
• Personalized coping strategy recommendations
• Progress monitoring and analytics
• Daily wellness check-in reminders

The App is designed to support your mental wellness journey but is NOT a substitute for professional medical advice, diagnosis, or treatment.''',
            ),
            _buildWarningSection(
              '3. Medical Disclaimer',
              '''⚠️ IMPORTANT MEDICAL DISCLAIMER

This App is for informational and educational purposes only. It is NOT intended to:

• Diagnose medical or mental health conditions
• Provide medical or psychiatric advice
• Replace professional mental health treatment
• Serve as emergency mental health support

If you are experiencing a mental health emergency or crisis, please contact:

• Emergency services: 112 (Kenya), 999 (Uganda), 911 (US)
• Kenya Befrienders: 0722 178 177
• Uganda Crisis Line: 0800 22 00 00
• Your healthcare provider immediately

Always seek professional medical advice for any mental health concerns. Never disregard professional medical advice or delay seeking it because of information from this App.''',
            ),
            _buildSection(
              '4. User Responsibilities',
              '''By using the App, you agree to:

• Provide accurate information in assessments
• Use the App for personal wellness purposes only
• Not rely solely on the App for health decisions
• Maintain confidentiality of your account credentials
• Not share sensitive personal information in feedback
• Not use the App in any unlawful manner
• Not attempt to access unauthorized features
• Not interfere with other users' experience''',
            ),
            _buildSection(
              '5. Account & Data',
              '''5.1 Account Creation:
• You must provide accurate information
• You are responsible for account security
• You must be at least 13 years old to use the App

5.2 Data Ownership:
• You retain ownership of your assessment data
• We store data to provide services (see Privacy Policy)
• You can export or delete your data at any time

5.3 Account Termination:
• You may delete your account through Settings
• We may suspend accounts for Terms violations
• Data deletion occurs within 30 days of account removal''',
            ),
            _buildSection(
              '6. Limitation of Liability',
              '''TO THE MAXIMUM EXTENT PERMITTED BY LAW:

The App and all content are provided "AS IS" and "AS AVAILABLE" without warranties of any kind, either express or implied.

We are NOT liable for:
• Decisions made based on App recommendations
• Technical errors, bugs, or downtime
• Data loss or corruption
• Indirect, incidental, or consequential damages
• Any damages resulting from App use

Maximum liability: The amount you paid for the App (currently free).

Some jurisdictions do not allow limitation of implied warranties or liability, so these limitations may not apply to you.''',
            ),
            _buildSection(
              '7. Data & Privacy',
              '''Your privacy is important to us. Please review our Privacy Policy for details on:

• What data we collect and why
• How we use and protect your data
• Your data rights (access, deletion, portability)
• Third-party services we use
• International data transfers
• Security measures in place

By using the App, you consent to data collection and use as described in our Privacy Policy.''',
            ),
            _buildSection(
              '8. Subscription & Payments',
              '''8.1 Current Status:
• The App is currently FREE to use
• All core features are available at no cost

8.2 Future Changes:
• We reserve the right to introduce paid features
• Any premium features will be clearly disclosed
• Pricing and billing terms will be provided upfront
• Refund policies will be stated at purchase

8.3 Trial Periods:
• Free trial terms will be clearly stated
• You can cancel before trial ends to avoid charges
• Auto-renewal terms will be explicit''',
            ),
            _buildSection(
              '9. Intellectual Property',
              '''All content, features, and functionality of the App are owned by Selfcare & Bloom or its licensors and are protected by copyright, trademark, and other intellectual property laws.

You may NOT:
• Copy, modify, or distribute App content
• Reverse engineer or decompile the App
• Use the App's branding without written permission
• Create derivative works based on the App
• Remove copyright or proprietary notices

You retain ownership of content you create (assessments, notes).''',
            ),
            _buildSection(
              '10. Prohibited Uses',
              '''You may NOT use the App to:

• Violate any laws or regulations
• Harm minors in any way
• Impersonate others or provide false information
• Upload viruses or malicious code
• Collect user data without consent
• Spam, harass, or abuse other users
• Interfere with App security features
• Access the App through automated means (bots)
• Resell or commercialize the App''',
            ),
            _buildSection(
              '11. Termination',
              '''11.1 By You:
• You may stop using the App at any time
• Delete your account through Settings
• Data will be removed per our retention policy

11.2 By Us:
• We may terminate access for Terms violations
• We may suspend accounts for suspicious activity
• We may discontinue the App with 30 days notice

11.3 Effect of Termination:
• Your right to use the App ceases immediately
• Data may be retained as required by law
• Provisions that should survive termination will remain in effect''',
            ),
            _buildSection(
              '12. Changes to Terms',
              '''We may update these Terms at any time. Changes will be effective when posted. We will notify you of significant changes through:

• In-app notification
• Email (if provided)
• App update notes

Continued use of the App after changes constitutes acceptance of the modified Terms. If you disagree with changes, discontinue use.''',
            ),
            _buildSection(
              '13. Dispute Resolution',
              '''13.1 Informal Resolution:
• Contact us first to resolve disputes informally
• Email: support@selfcarebloom.com
• We will attempt resolution within 30 days

13.2 Binding Arbitration:
• Disputes will be resolved through arbitration
• Arbitration is conducted in the jurisdiction specified in Section 14 (Governing Law)
• Class action waiver applies

13.3 Exceptions:
• Small claims court cases
• Injunctive relief requests
• Intellectual property disputes''',
            ),
            _buildSection(
              '14. Governing Law',
              '''These Terms are governed by and construed in accordance with the laws of Uganda and Kenya, without regard to conflict of law principles.

Any legal action or proceeding shall be brought exclusively in the courts located in Uganda or Kenya, whichever jurisdiction the user resides in.''',
            ),
            _buildSection(
              '15. Severability',
              '''If any provision of these Terms is found to be unenforceable or invalid, that provision will be limited or eliminated to the minimum extent necessary, and the remaining provisions will remain in full force and effect.''',
            ),
            _buildSection(
              '16. Entire Agreement',
              '''These Terms, together with the Privacy Policy, constitute the entire agreement between you and Selfcare & Bloom regarding the App and supersede all prior agreements.''',
            ),
            _buildSection(
              '17. Contact Information',
              '''For questions, concerns, or support regarding these Terms:

Email: support@selfcarebloom.com
Website: www.selfcarebloom.com

Response time: Within 2-3 business days''',
            ),
            const SizedBox(height: 40),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.verified_user,
                      color: AppTheme.primary, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'Thank you for using Selfcare & Bloom',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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

  Widget _buildWarningSection(String title, String content) {
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
