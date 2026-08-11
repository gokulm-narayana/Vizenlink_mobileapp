import 'package:flutter/material.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';

const _appVersion = 'v1.0.0';

class _Faq {
  const _Faq({required this.question, required this.answer});

  final String question;
  final String answer;
}

const _faqs = [
  _Faq(
    question: 'Why does my camera show as offline?',
    answer:
        'Check that the camera has power and is connected to Wi-Fi. If it '
        "was recently moved, it may need to be reconnected via Camera "
        "Info → Configure Wi-Fi.",
  ),
  _Faq(
    question: 'How do I add a new camera?',
    answer:
        'From the Dashboard, tap the Add Camera button and follow the '
        'on-screen scanning steps.',
  ),
  _Faq(
    question: 'How do I share access with a family member?',
    answer:
        'Go to Profile → Users & Invites and tap Invite to send an '
        'invite or create a user directly.',
  ),
  _Faq(
    question: 'How do I change what I get notified about?',
    answer:
        'Go to Profile → Notification preferences to choose which '
        'alerts and channels are enabled.',
  ),
  _Faq(
    question: 'Can I limit access to just one camera?',
    answer:
        'Invite that person as a Temporary Guest from Users & Invites — '
        "it's time-limited access to a selected camera/live view only.",
  ),
];

/// Help & Support: FAQ plus support contact options. No support
/// backend/ticketing or external links are wired up yet (see CLAUDE.md),
/// so Contact Support / Report a Bug / User Guide are stubs.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  static const routeName = 'help';

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  String _query = '';

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label — coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _query.isEmpty
        ? _faqs
        : _faqs
              .where(
                (faq) =>
                    faq.question.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('HELP-001'),
          title: const Text('Help & Support'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('HELP-002'),
              decoration: const InputDecoration(
                labelText: 'Search FAQs',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 16),
            if (filteredFaqs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No results for "$_query"',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < filteredFaqs.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      ExpansionTile(
                        key: ValueKey('HELP-003-${filteredFaqs[i].question}'),
                        title: Text(filteredFaqs[i].question),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [Text(filteredFaqs[i].answer)],
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 16),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    key: const Key('HELP-004'),
                    leading: const Icon(Icons.support_agent_outlined),
                    title: const Text('Contact Support'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showComingSoon('Contact Support'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    key: const Key('HELP-005'),
                    leading: const Icon(Icons.bug_report_outlined),
                    title: const Text('Report a Bug'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showComingSoon('Report a Bug'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    key: const Key('HELP-006'),
                    leading: const Icon(Icons.menu_book_outlined),
                    title: const Text('User Guide'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showComingSoon('User Guide'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              key: const Key('HELP-007'),
              child: Text(
                _appVersion,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
