import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/citations.dart';
import '../theme/app_theme.dart';

/// Displays every external, independently verifiable source the app relies
/// on for the health/wellness information it shows (the PSS-10 instrument
/// and the general stress-management techniques), plus a plain-language
/// explanation of where the app's own point-value estimates come from.
///
/// Reachable from Settings and from an info icon on the Recommendations
/// screen, so citations are easy to find as required by App Store
/// Guideline 1.4.1.
class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sources & References'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Where Our Information Comes From',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            icon: Icons.rule,
            title: 'The Stress Assessment (PSS-10)',
            body:
                'Your stress score and LOW / MODERATE / HIGH category come from the '
                'Perceived Stress Scale (PSS-10), a validated psychological '
                'questionnaire — not something we invented.',
            citation: Citations.pss10,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            icon: Icons.science_outlined,
            title: 'Coping Techniques We Recommend',
            body:
                'Each recommendation card shows a "Source" link to a published, '
                'reputable health organization (e.g. NIMH, APA, Mayo Clinic, '
                'Harvard Medical School) describing that technique in general.',
          ),
          const SizedBox(height: 16),
          _buildPilotDisclosureCard(context),
          const SizedBox(height: 28),
          const Text(
            'Full Reference List',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...Citations.all.map((c) => _buildCitationTile(context, c)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'SelfCare Together does not provide medical diagnosis or treatment. '
              'Always consult a qualified healthcare provider about your mental '
              'or physical health.',
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    Citation? citation,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(body, style: const TextStyle(fontSize: 14, height: 1.5)),
            if (citation != null) ...[
              const SizedBox(height: 10),
              _buildLink(context, citation),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPilotDisclosureCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.amber.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.amber),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: Colors.amber),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'About the "Reduces stress by X points" Numbers',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'Some recommendations show a specific number, such as "Therapy '
              'reduces stress by 5.8 points." These exact figures come from '
              'SelfCare Together\'s own pilot study of 50 participants who '
              'completed the PSS-10 and reported which coping strategies they '
              'used — they are not drawn from external published research, and '
              'the sample is too small to be statistically conclusive on its own.\n\n'
              'We show them because they reflect real patterns in our pilot '
              'data and are directionally consistent with the published '
              'research on these techniques (linked above), but they should be '
              'read as early, exploratory findings from our own program — not '
              'as clinically validated outcomes you should expect to replicate.',
              style: TextStyle(fontSize: 13.5, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitationTile(BuildContext context, Citation c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _launch(context, c.url),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.link, size: 18, color: AppTheme.info),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.publisher,
                      style: TextStyle(
                          fontSize: 12.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLink(BuildContext context, Citation c) {
    return InkWell(
      onTap: () => _launch(context, c.url),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.open_in_new, size: 14, color: AppTheme.info),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Source: ${c.label}',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.info,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _launch(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }
}
