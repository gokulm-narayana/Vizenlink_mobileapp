import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_state/homes_controller.dart';
import '../../models/camera.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/saving_overlay.dart';
import '../../widgets/settings_save_button.dart';
import '../dashboard/dashboard_screen.dart';

/// Danger Zone: Soft Reset and Hard Reset (both require the camera to be
/// online, since they round-trip to the device) plus Delete Camera (allowed
/// while offline — it only removes the camera from local app state via
/// [HomesController.deleteCamera]). No CCTV protocol/backend is wired up
/// yet (see CLAUDE.md), so the resets only simulate a round-trip.
class DangerZoneScreen extends StatefulWidget {
  const DangerZoneScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'danger-zone';

  final Camera camera;
  final HomesController homesController;

  @override
  State<DangerZoneScreen> createState() => _DangerZoneScreenState();
}

class _DangerZoneScreenState extends State<DangerZoneScreen> {
  bool _isBusy = false;
  String _busyLabel = '';

  String get _homeId {
    return widget.homesController.value.homes
        .firstWhere((home) => home.cameras.any((c) => c.id == widget.camera.id))
        .id;
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _softReset() async {
    final confirmed = await _confirm(
      title: 'Soft reset camera?',
      message: 'The camera will reboot. Settings and recordings are kept.',
      confirmLabel: 'Reboot',
    );
    if (!confirmed) return;

    setState(() {
      _isBusy = true;
      _busyLabel = 'Rebooting…';
    });
    final succeeded = await simulateCameraSave();
    if (!mounted) return;
    setState(() => _isBusy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded
              ? 'Camera is rebooting'
              : 'Failed to reboot camera. Try again.',
        ),
      ),
    );
  }

  Future<void> _hardReset() async {
    final confirmed = await _confirm(
      title: 'Hard reset camera?',
      message:
          'This erases all settings on the camera and restores factory '
          'defaults. This cannot be undone.',
      confirmLabel: 'Erase & Reset',
    );
    if (!confirmed) return;

    setState(() {
      _isBusy = true;
      _busyLabel = 'Resetting…';
    });
    final succeeded = await simulateCameraSave();
    if (!mounted) return;
    setState(() => _isBusy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded
              ? 'Camera has been reset to factory defaults'
              : 'Failed to reset camera. Try again.',
        ),
      ),
    );
  }

  Future<void> _deleteCamera() async {
    final confirmed = await _confirm(
      title: 'Delete camera?',
      message:
          '"${widget.camera.name}" will be removed from this home. '
          'This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!confirmed) return;

    widget.homesController.deleteCamera(_homeId, widget.camera.id);
    if (!mounted) return;
    context.go(DashboardScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = widget.camera.isOnline;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('DANGER-001'),
          title: const Text('Danger Zone'),
        ),
        body: SavingOverlay(
          isSaving: _isBusy,
          label: _busyLabel,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                key: const Key('DANGER-003'),
                'These actions are destructive and, in most cases, cannot '
                'be undone. Proceed with care.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _DangerTile(
                      settingsKey: const Key('DANGER-004'),
                      icon: Icons.restart_alt,
                      label: 'Soft Reset',
                      description: isOnline
                          ? 'Reboots the camera. Settings and recordings '
                                'are kept.'
                          : 'Camera is offline — reconnect it to reboot.',
                      enabled: isOnline && !_isBusy,
                      onTap: _softReset,
                    ),
                    const Divider(height: 1),
                    _DangerTile(
                      settingsKey: const Key('DANGER-005'),
                      icon: Icons.settings_backup_restore,
                      label: 'Hard Reset',
                      description: isOnline
                          ? 'Erases all settings and restores factory '
                                'defaults. This cannot be undone.'
                          : 'Camera is offline — reconnect it to reset.',
                      enabled: isOnline && !_isBusy,
                      onTap: _hardReset,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GlassCard(
                padding: EdgeInsets.zero,
                child: _DangerTile(
                  settingsKey: const Key('DANGER-006'),
                  icon: Icons.delete_forever_outlined,
                  label: 'Delete Camera',
                  description:
                      'Removes this camera from your home. This cannot be '
                      'undone.',
                  enabled: !_isBusy,
                  onTap: _deleteCamera,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  const _DangerTile({
    required this.settingsKey,
    required this.icon,
    required this.label,
    required this.description,
    required this.enabled,
    required this.onTap,
  });

  final Key settingsKey;
  final IconData icon;
  final String label;
  final String description;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.offline : Theme.of(context).disabledColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: settingsKey,
        onTap: enabled ? onTap : null,
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          subtitle: Text(description),
        ),
      ),
    );
  }
}
