import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_state/homes_controller.dart';
import '../../models/camera.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import 'audio_screen.dart';
import 'camera_info_screen.dart';
import 'danger_zone_screen.dart';
import 'detections_screen.dart';
import 'storage_screen.dart';
import 'video_display_screen.dart';

/// Camera settings landing screen: a menu of five sections, each pushing
/// its own sub-screen. Sub-screens are stubs for now — fields for each are
/// scoped and built one at a time.
class CameraSettingsScreen extends StatelessWidget {
  const CameraSettingsScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'settings';

  final Camera camera;
  final HomesController homesController;

  @override
  Widget build(BuildContext context) {
    final isOnline = camera.isOnline;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('CAMSET-001'),
          title: Text('${camera.name} Settings'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SettingsMenuTile(
              settingsKey: const Key('CAMSET-003'),
              icon: Icons.info_outline,
              label: 'Camera Info',
              enabled: isOnline,
              onTap: () => context.push(
                '${GoRouterState.of(context).matchedLocation}/${CameraInfoScreen.routeName}',
                extra: camera,
              ),
            ),
            const SizedBox(height: 12),
            _SettingsMenuTile(
              settingsKey: const Key('CAMSET-004'),
              icon: Icons.videocam_outlined,
              label: 'Video & Display',
              enabled: isOnline,
              onTap: () => context.push(
                '${GoRouterState.of(context).matchedLocation}/${VideoDisplayScreen.routeName}',
                extra: camera,
              ),
            ),
            const SizedBox(height: 12),
            _SettingsMenuTile(
              settingsKey: const Key('CAMSET-005'),
              icon: Icons.notifications_active_outlined,
              label: 'Detections',
              enabled: isOnline,
              onTap: () => context.push(
                '${GoRouterState.of(context).matchedLocation}/${DetectionsScreen.routeName}',
                extra: camera,
              ),
            ),
            const SizedBox(height: 12),
            _SettingsMenuTile(
              settingsKey: const Key('CAMSET-007'),
              icon: Icons.mic_none_outlined,
              label: 'Audio',
              enabled: isOnline,
              onTap: () => context.push(
                '${GoRouterState.of(context).matchedLocation}/${AudioScreen.routeName}',
                extra: camera,
              ),
            ),
            const SizedBox(height: 12),
            _SettingsMenuTile(
              settingsKey: const Key('CAMSET-009'),
              icon: Icons.sd_storage_outlined,
              label: 'Storage & Recordings',
              enabled: isOnline,
              onTap: () => context.push(
                '${GoRouterState.of(context).matchedLocation}/${StorageScreen.routeName}',
                extra: camera,
              ),
            ),
            const SizedBox(height: 12),
            _SettingsMenuTile(
              settingsKey: const Key('CAMSET-006'),
              icon: Icons.warning_amber_rounded,
              label: 'Danger Zone',
              iconColor: AppColors.offline,
              labelColor: AppColors.offline,
              onTap: () => context.push(
                '${GoRouterState.of(context).matchedLocation}/${DangerZoneScreen.routeName}',
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
    required this.onTap,
    this.iconColor,
    this.labelColor,
    this.enabled = true,
  });

  final Key settingsKey;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final disabledColor = Theme.of(context).disabledColor;

    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: settingsKey,
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: ListTile(
            leading: Icon(
              icon,
              color: enabled
                  ? (iconColor ?? colorScheme.primary)
                  : disabledColor,
            ),
            title: Text(
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                color: enabled ? labelColor : disabledColor,
              ),
            ),
            subtitle: enabled
                ? null
                : const Text('Camera is offline — reconnect to access'),
            trailing: Icon(
              Icons.chevron_right,
              color: enabled ? null : disabledColor,
            ),
          ),
        ),
      ),
    );
  }
}
