import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Trashit'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Trashit',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Version 1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Trashit is a public, tongue-in-cheek “garbage bin” for the internet. Share a link, see a quick summary, and let the crowd weigh in with Retrash (agree it\'s trash) or Untrash (disagree).',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.balance, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Platform is neutral. Posts reflect community reactions, not editorial endorsements.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _bulletList(context, 'Features', const [
            'Share any link and auto-extract title, image, and hashtags',
            'AI-powered witty “Why It\'s Trash” summaries (optional)',
            'Trending and Recent feeds with transparent vote counts',
            'Duplicate-vote prevention via anonymous device ID',
          ]),
          const SizedBox(height: 24),
          _bulletList(context, 'Community Guidelines (Short)', const [
            'Don\'t submit illegal content, doxxing, or credible threats',
            'No hate speech or harassment',
            'Critique ideas and content, not people',
            'Respect copyrights; use the Report menu for DMCA or abuse',
          ]),
          const SizedBox(height: 24),
          _bulletList(context, 'Open Source & Credits', const [
            'Built with Flutter',
            'Uses Firebase when connected in Dreamflow',
            'Icons and images are credited to their respective owners',
          ]),
          const SizedBox(height: 24),
          Text(
            'Contact',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text('support@trashit.live', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _bulletList(BuildContext context, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...items.map((text) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            )),
      ],
    );
  }
}
