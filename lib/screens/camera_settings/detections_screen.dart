import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/camera.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import 'intrusion_detection_screen.dart';
import 'line_crossing_screen.dart';
import 'motion_detection_screen.dart';
import 'person_detection_screen.dart';
import 'vehicle_detection_screen.dart';

/// Detections landing menu: five detection types, each pushing its own
/// sub-screen. Sub-screens hold local-only draft state (no backend/
/// protocol wired up yet — see CLAUDE.md).
class DetectionsScreen extends StatelessWidget {
  const DetectionsScreen({super.key, required this.camera});

  static const routeName = 'detections';

  final Camera camera;

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('DETECT-001'),
          title: const Text('Detections'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DetectionMenuTile(
              settingsKey: const Key('DETECT-003'),
              icon: Icons.directions_run,
              label: 'Motion Detection',
              subtitle: 'Trigger on any movement in view',
              onTap: () => context.push(
                '${GoRouterState.of(context).matchedLocation}/${MotionDetectionScreen.routeName}',
                extra: camera,
              ),
            ),
            const SizedBox(height: 12),
            _DetectionMenuTile(
              settingsKey: const Key('DETECT-004'),
              icon: Icons.crop_free,
              label: 'Intrusion Detection',
              subtitle: 'Trigger zones for restricted areas',
              onTap: () => context.push(
                '${GoRouterState.of(context).matchedLocation}/${IntrusionDetectionScreen.routeName}',
                extra: camera,
              ),
            ),
            const SizedBox(height: 12),
            _DetectionMenuTile(
              settingsKey: const Key('DETECT-005'),
              icon: Icons.timeline,
              label: 'Line Crossing',
              subtitle: 'Trigger when a line is crossed',
              onTap: () => context.push(
                '${GoRouterState.of(context).matchedLocation}/${LineCrossingScreen.routeName}',
                extra: camera,
              ),
            ),
            const SizedBox(height: 12),
            _DetectionMenuTile(
              settingsKey: const Key('DETECT-006'),
              icon: Icons.person_outline,
              label: 'Person Detection',
              subtitle: 'AI-based human detection',
              onTap: () => context.push(
                '${GoRouterState.of(context).matchedLocation}/${PersonDetectionScreen.routeName}',
                extra: camera,
              ),
            ),
            const SizedBox(height: 12),
            _DetectionMenuTile(
              settingsKey: const Key('DETECT-007'),
              icon: Icons.directions_car_outlined,
              label: 'Vehicle Detection',
              subtitle: 'AI-based vehicle detection',
              onTap: () => context.push(
                '${GoRouterState.of(context).matchedLocation}/${VehicleDetectionScreen.routeName}',
                extra: camera,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetectionMenuTile extends StatelessWidget {
  const _DetectionMenuTile({
    required this.settingsKey,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final Key settingsKey;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: settingsKey,
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: ListTile(
            leading: Icon(icon, color: colorScheme.primary),
            title: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ),
    );
  }
}
