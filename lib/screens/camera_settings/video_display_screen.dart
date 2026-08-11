import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_state/homes_controller.dart';
import '../../models/camera.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import 'imaging_screen.dart';
import 'night_mode_screen.dart';
import 'on_screen_display_screen.dart';
import 'privacy_mode_screen.dart';
import 'tags_screen.dart';
import 'video_encoder_screen.dart';
import 'video_mode_screen.dart';

/// Video & Display landing menu: seven sections, each pushing its own
/// sub-screen. Sub-screens hold local-only draft state (no backend/protocol
/// wired up yet — see CLAUDE.md), except the Tags screen's Bitrate/Live Tag
/// toggles, which are written through [homesController] so they take effect
/// on the Camera Live page.
class VideoDisplayScreen extends StatelessWidget {
  const VideoDisplayScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'video-display';

  final Camera camera;
  final HomesController homesController;

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('VIDDISP-001'),
          title: const Text('Video & Display'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SettingsMenuTile(
              settingsKey: const Key('VIDDISP-002'),
              icon: Icons.videocam_outlined,
              label: 'Video Mode',
              subtitle: 'Day, Auto, or Night switching',
              onTap: () => context.push(
                '${GoRouterState.of(context).matchedLocation}/${VideoModeScreen.routeName}',
                extra: camera,
              ),
            ),
            const SizedBox(height: 12),
            _SettingsMenuTile(
              settingsKey: const Key('VIDDISP-003'),
              icon: Icons.nightlight_outlined,
              label: 'Night Mode',
              subtitle: 'Infrared, Smart, or Full Color',
              onTap: () => context.push(
                '${GoRouterState.of(context).matchedLocation}/${NightModeScreen.routeName}',
                extra: camera,
              ),
            ),
            const SizedBox(height: 12),
            _SettingsMenuTile(
              settingsKey: const Key('VIDDISP-005'),
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Mode',
              subtitle: 'Block the feed fully or mask zones',
              onTap: () => context.push(
                '${GoRouterState.of(context).matchedLocation}/${PrivacyModeScreen.routeName}',
                extra: camera,
              ),
            ),
            const SizedBox(height: 12),
            _SettingsMenuTile(
              settingsKey: const Key('VIDDISP-006'),
              icon: Icons.text_fields_outlined,
              label: 'On-Screen Display',
              subtitle: 'Time and custom text overlays',
              onTap: () => context.push(
                '${GoRouterState.of(context).matchedLocation}/${OnScreenDisplayScreen.routeName}',
                extra: camera,
              ),
            ),
            const SizedBox(height: 12),
            _SettingsMenuTile(
              settingsKey: const Key('VIDDISP-007'),
              icon: Icons.tune,
              label: 'Imaging',
              subtitle: 'Brightness, contrast, WDR, exposure',
              onTap: () => context.push(
                '${GoRouterState.of(context).matchedLocation}/${ImagingScreen.routeName}',
                extra: camera,
              ),
            ),
            const SizedBox(height: 12),
            _SettingsMenuTile(
              settingsKey: const Key('VIDDISP-008'),
              icon: Icons.settings_input_component_outlined,
              label: 'Video Encoder',
              subtitle: 'Resolution, frame rate, bitrate, codec',
              onTap: () => context.push(
                '${GoRouterState.of(context).matchedLocation}/${VideoEncoderScreen.routeName}',
                extra: camera,
              ),
            ),
            const SizedBox(height: 12),
            _SettingsMenuTile(
              settingsKey: const Key('VIDDISP-011'),
              icon: Icons.label_outline,
              label: 'Tags',
              subtitle: 'Live, bitrate, and signal strength badges',
              onTap: () => context.push(
                '${GoRouterState.of(context).matchedLocation}/${TagsScreen.routeName}',
                extra: camera,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsMenuTile extends StatelessWidget {
  const _SettingsMenuTile({
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
