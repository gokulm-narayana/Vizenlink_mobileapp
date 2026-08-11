import 'package:flutter/material.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';

class _Session {
  const _Session({
    required this.deviceName,
    required this.os,
    required this.location,
    required this.lastActive,
    required this.icon,
    this.isCurrentDevice = false,
  });

  final String deviceName;
  final String os;
  final String location;
  final String lastActive;
  final IconData icon;
  final bool isCurrentDevice;
}

/// Active sessions: lists devices signed into the account. No auth backend
/// is wired up yet (see CLAUDE.md), so this is static mock data held in
/// local widget state — "sign out" just removes the row locally.
class ActiveSessionsScreen extends StatefulWidget {
  const ActiveSessionsScreen({super.key});

  static const routeName = 'sessions';

  @override
  State<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends State<ActiveSessionsScreen> {
  final _sessions = <_Session>[
    const _Session(
      deviceName: 'iPhone 17 Pro',
      os: 'iOS 26',
      location: 'San Francisco, CA',
      lastActive: 'Active now',
      icon: Icons.phone_iphone,
      isCurrentDevice: true,
    ),
    const _Session(
      deviceName: 'Pixel 9',
      os: 'Android 16',
      location: 'San Francisco, CA',
      lastActive: '2 hours ago',
      icon: Icons.phone_android,
    ),
    const _Session(
      deviceName: 'MacBook Pro',
      os: 'macOS 26',
      location: 'Oakland, CA',
      lastActive: 'Yesterday',
      icon: Icons.laptop_mac,
    ),
  ];

  void _signOut(_Session session) {
    setState(() => _sessions.remove(session));
  }

  void _signOutAllOthers() {
    setState(() => _sessions.removeWhere((s) => !s.isCurrentDevice));
  }

  @override
  Widget build(BuildContext context) {
    final hasOtherSessions = _sessions.any((s) => !s.isCurrentDevice);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('SESS-001'),
          title: const Text('Active Sessions'),
        ),
        body: ListView(
          key: const Key('SESS-002'),
          padding: const EdgeInsets.all(16),
          children: [
            for (final session in _sessions) ...[
              _SessionCard(
                session: session,
                onSignOut: () => _signOut(session),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              key: const Key('SESS-009'),
              onPressed: hasOtherSessions ? _signOutAllOthers : null,
              child: const Text('Sign out all other sessions'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onSignOut});

  final _Session session;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      child: Row(
        children: [
          Icon(
            session.icon,
            key: const Key('SESS-003'),
            color: colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        key: const Key('SESS-004'),
                        '${session.deviceName} · ${session.os}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (session.isCurrentDevice) ...[
                      const SizedBox(width: 8),
                      Chip(
                        key: const Key('SESS-007'),
                        label: const Text('This device'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  session.location,
                  key: const Key('SESS-005'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  session.lastActive,
                  key: const Key('SESS-006'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (!session.isCurrentDevice)
            TextButton(
              key: const Key('SESS-008'),
              onPressed: onSignOut,
              child: const Text('Sign out'),
            ),
        ],
      ),
    );
  }
}
