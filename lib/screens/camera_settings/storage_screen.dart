import 'package:flutter/material.dart';

import '../../app_state/homes_controller.dart';
import '../../models/camera.dart';
import '../../utils/duration_format.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/navigation_leave_guard.dart';
import '../../widgets/saving_overlay.dart';
import '../../widgets/settings_save_button.dart';

const _retentionPresets = [3, 7, 14, 30, 60];

/// Local SD storage: enable/disable, capacity/free-space/estimated-time-
/// remaining, card health and endurance-rating warnings, a persistent
/// storage-failure banner, retention duration (with a feasibility warning),
/// Format SD Card (an immediate action, independent of Save — same pattern
/// as Danger Zone's resets), and a read-only deletion-history log. Persisted
/// through [HomesController.updateCamera] — see the note on `videoMode` in
/// `lib/models/camera.dart`. Reached directly from camera settings (not
/// nested under Video & Display).
class StorageScreen extends StatefulWidget {
  const StorageScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'storage';

  final Camera camera;
  final HomesController homesController;

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  late bool _sdStorageEnabled = widget.camera.sdStorageEnabled;
  late int _retentionDays = widget.camera.retentionDays;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _isFormatting = false;

  void _markDirty(VoidCallback update) {
    setState(() {
      update();
      _isDirty = true;
    });
  }

  Duration get _stagedEstimate {
    // Retention doesn't change free space, only the enable toggle does —
    // reuse the model's estimate with a staged override for the toggle.
    if (!_sdStorageEnabled) return Duration.zero;
    return widget.camera.estimatedRecordingTimeRemaining;
  }

  bool get _retentionExceedsCapacity {
    if (!_sdStorageEnabled) return false;
    final maxDays = _stagedEstimate.inHours / 24;
    return _retentionDays > maxDays;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final succeeded = await simulateCameraSave();
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (succeeded) {
      widget.homesController.updateCamera(
        widget.camera.id,
        (camera) => camera.copyWith(
          sdStorageEnabled: _sdStorageEnabled,
          retentionDays: _retentionDays,
        ),
      );
      setState(() => _isDirty = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Changes saved')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save changes. Try again.')),
      );
    }
  }

  Future<void> _formatCard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('STOR-012'),
        title: const Text('Format SD card?'),
        content: const Text(
          'All footage on this card will be permanently erased. This '
          'cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Format'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isFormatting = true);
    final succeeded = await simulateCameraSave();
    if (!mounted) return;
    setState(() => _isFormatting = false);
    if (succeeded) {
      widget.homesController.updateCamera(
        widget.camera.id,
        (camera) => camera.copyWith(
          sdCardUsedGb: 0,
          storageFailure: StorageFailure.none,
        ),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded ? 'SD card formatted' : 'Failed to format card. Try again.',
        ),
      ),
    );
  }

  Future<bool> _confirmLeave() => confirmDiscardOnLeave(
    context: context,
    isDirty: _isDirty,
    onSave: _save,
    isDirtyAfterSave: () => _isDirty,
    dialogKey: const Key('STOR-015'),
    discardKey: const Key('STOR-016'),
    saveKey: const Key('STOR-017'),
  );

  @override
  Widget build(BuildContext context) {
    final camera = widget.camera;
    final healthLabel = switch (camera.sdCardHealthPercent) {
      >= 80 => 'Good',
      >= 50 => 'Fair',
      _ => 'Poor',
    };
    final showEolWarning = camera.sdCardHealthPercent < 50;

    return LeaveGuard(
      canLeave: _confirmLeave,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            key: const Key('STOR-001'),
            title: const Text('Storage'),
            actions: [
              SettingsSaveButton(
                settingsKey: const Key('STOR-002'),
                isDirty: _isDirty,
                isSaving: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
          body: SavingOverlay(
            isSaving: _isSaving || _isFormatting,
            label: _isFormatting ? 'Formatting…' : 'Saving…',
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: SwitchListTile(
                    key: const Key('STOR-003'),
                    title: const Text('Enable SD Storage'),
                    value: _sdStorageEnabled,
                    onChanged: (value) =>
                        _markDirty(() => _sdStorageEnabled = value),
                  ),
                ),
                const SizedBox(height: 12),
                if (camera.storageFailure != StorageFailure.none) ...[
                  GlassCard(
                    key: const Key('STOR-008'),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(camera.storageFailure.message!)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key: const Key('STOR-004'),
                        camera.sdCardPresent
                            ? '${camera.sdCardCapacityGb.round()} GB card — '
                                  '${camera.sdCardUsedGb.round()} GB used, '
                                  '${camera.sdCardFreeGb.round()} GB free'
                            : 'No SD card detected',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (camera.sdCardPresent) ...[
                        const SizedBox(height: 8),
                        Text(
                          key: const Key('STOR-005'),
                          'Estimated time remaining: '
                          '${formatApproxDuration(_stagedEstimate)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                if (camera.sdCardPresent) ...[
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Text(
                      key: const Key('STOR-006'),
                      'Card health: $healthLabel '
                      '(${camera.sdCardHealthPercent.round()}%)'
                      '${showEolWarning ? ' — consider replacing this card soon' : ''}',
                    ),
                  ),
                  if (!camera.sdCardEnduranceRated) ...[
                    const SizedBox(height: 12),
                    GlassCard(
                      key: const Key('STOR-007'),
                      child: const Text(
                        'This card isn\'t rated for continuous surveillance '
                        'writes. A surveillance-rated (endurance) card is '
                        'recommended for reliable long-term recording.',
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                Text(
                  'Retention',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: RadioGroup<int>(
                    groupValue: _retentionDays,
                    onChanged: (value) => _markDirty(
                      () => _retentionDays = value ?? _retentionDays,
                    ),
                    child: Column(
                      key: const Key('STOR-009'),
                      children: [
                        for (final days in _retentionPresets)
                          RadioListTile<int>(
                            value: days,
                            title: Text('$days days'),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_retentionExceedsCapacity) ...[
                  const SizedBox(height: 8),
                  GlassCard(
                    key: const Key('STOR-010'),
                    child: Text(
                      'At current usage, this card can only hold about '
                      '${formatApproxDuration(_stagedEstimate)} of footage — '
                      'less than the selected retention period.',
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  key: const Key('STOR-011'),
                  onPressed: _isFormatting ? null : _formatCard,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Format SD Card'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Deletion history',
                  key: const Key('STOR-013'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: const [
                      _DeletionHistoryRow(
                        key: Key('STOR-014-1'),
                        text: '18 clips removed — Jan 3, retention policy',
                      ),
                      Divider(height: 1),
                      _DeletionHistoryRow(
                        key: Key('STOR-014-2'),
                        text: '9 clips removed — Dec 20, retention policy',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeletionHistoryRow extends StatelessWidget {
  const _DeletionHistoryRow({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ListTile(dense: true, title: Text(text));
  }
}
