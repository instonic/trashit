import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Trashit Privacy Policy',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Last updated: September 2025',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Trashit lets you share links and express an opinion by voting 'Retrash' (you agree it’s trash) or 'Untrash' (you disagree). We do not require accounts. We use an anonymous, random device ID to protect integrity (one action per device per post) and to keep the experience simple.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _section(
            context,
            title: 'Platform Neutrality',
            body:
                'Trashit is a neutral platform. Posts and reactions are user-generated and reflect community sentiment—not our views or endorsements. We provide tools for reporting and moderation to keep people safe while preserving open expression.',
          ),
          const SizedBox(height: 16),
          _section(
            context,
            title: 'What We Collect',
            body:
                '• Content you submit: link URL, title, hashtags, and an image preview.\n'
                '• Engagement: anonymous votes and timestamps.\n'
                '• Device-only data: a random device ID saved locally to prevent duplicate voting; optional preferences (e.g., blocked domains).\n'
                '• Optional analytics: if you consent in Preferences, we collect anonymized usage and optional coarse demographics (age band, gender, region).',
          ),
          const SizedBox(height: 16),
          _section(
            context,
            title: 'How We Use Data',
            body:
                '• Operate the app (Recent and Trending feeds, dedupe votes, show stats).\n'
                '• Moderate abuse and handle takedown requests.\n'
                '• If AI summaries are enabled, we send minimal metadata to our AI provider solely to generate a short, witty “Why it’s trash” blurb.',
          ),
          const SizedBox(height: 16),
          _section(
            context,
            title: 'Your Choices & Controls',
            body:
                '• Opt in/out of anonymous analytics anytime in Preferences.\n'
                '• Optionally share coarse demographics (never ethnicity or sensitive traits).\n'
                '• Blocklist: you can block domains locally so their posts don’t appear.\n'
                '• You may request content removal, report abuse, or submit DMCA notices (see below).',
          ),
          const SizedBox(height: 16),
          _section(
            context,
            title: 'Not For Minors',
            body:
                'Trashit does not target children or minors. Do not use the app if you are under the age required by your local law. We do not knowingly collect personal information from minors.',
          ),
          const SizedBox(height: 16),
          _section(
            context,
            title: 'Community Guidelines (Short)',
            body:
                '• Don’t submit illegal content, doxxing, or credible threats.\n'
                '• No hate speech or harassment.\n'
                '• Critique ideas and content, not people.\n'
                '• Respect copyrights; use the Report menu for DMCA or abuse.\n'
                '• Violations may result in removal or access restrictions.',
          ),
          const SizedBox(height: 16),
          _section(
            context,
            title: 'DMCA / Takedown',
            body:
                'If you believe your copyright is infringed, email dmca@trashit.live with: your contact info, the copyrighted work, the infringing link(s), and a statement under penalty of perjury that you are authorized to act. We will review and, if appropriate, remove the material.\n\n'
                'Counter-notices can be sent to the same address with sufficient detail to assess the claim.',
          ),
          const SizedBox(height: 16),
          _section(
            context,
            title: 'Third Parties',
            body:
                'We may use Firebase (database, analytics with consent) and an AI provider (for summaries). These providers process data according to their policies. We minimize what we send and retain only what is needed to run Trashit.',
          ),
          const SizedBox(height: 16),
          _section(
            context,
            title: 'Security & Retention',
            body:
                'We use industry-standard safeguards. Content and votes may be retained as long as needed to operate the service. You can request removal of specific posts at support@trashit.live.',
          ),
          const SizedBox(height: 16),
          _section(
            context,
            title: 'Contact',
            body: 'support@trashit.live',
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, {required String title, required String body}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
