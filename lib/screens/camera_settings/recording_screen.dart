import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_state/homes_controller.dart';
import '../../models/camera.dart';
import '../../utils/duration_format.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/navigation_leave_guard.dart';
import '../../widgets/saving_overlay.dart';
import '../../widgets/settings_save_button.dart';
import 'detections_screen.dart';

const _modeLabels = {
  RecordingStatus.continuous: 'Continuous',
  RecordingStatus.scheduled: 'Scheduled',
  RecordingStatus.eventTriggered: 'Event-Triggered',
  RecordingStatus.off: 'Off',
};

const _modeDescriptions = {
  RecordingStatus.continuous: 'Records around the clock',
  RecordingStatus.scheduled: 'Records only during the windows set below',
  RecordingStatus.eventTriggered: 'Records when a detection fires',
  RecordingStatus.off: 'No new footage is recorded',
};

const _dayLabels = {
  RecordingScheduleDay.monday: 'Monday',
  RecordingScheduleDay.tuesday: 'Tuesday',
  RecordingScheduleDay.wednesday: 'Wednesday',
  RecordingScheduleDay.thursday: 'Thursday',
  RecordingScheduleDay.friday: 'Friday',
  RecordingScheduleDay.saturday: 'Saturday',
  RecordingScheduleDay.sunday: 'Sunday',
};

String _formatMinutes(int minutes) {
  final time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

/// Local recording-mode settings: Continuous / Scheduled / Event-Triggered /
/// Off, with a day/time schedule editor (Scheduled) and a warning if
/// Event-Triggered has no detection type enabled on this camera yet.
/// Persisted through [HomesController.updateCamera] — see the note on
/// `videoMode` in `lib/models/camera.dart`. Reached directly from camera
/// settings (not nested under Video & Display).
class RecordingScreen extends StatefulWidget {
  const RecordingScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'recording';

  final Camera camera;
  final HomesController homesController;

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  late RecordingStatus _mode = widget.camera.recordingStatus;
  late final List<RecordingScheduleWindow> _scheduleWindows = [
    ...widget.camera.recordingScheduleWindows,
  ];
  bool _isDirty = false;
  bool _isSaving = false;

  bool get _hasAnyDetectionEnabled =>
      widget.camera.motionDetectionEnabled ||
      widget.camera.intrusionDetectionEnabled ||
      widget.camera.lineCrossingEnabled ||
      widget.camera.personDetectionEnabled ||
      widget.camera.vehicleDetectionEnabled;

  String get _footageEstimate {
    if (_mode == RecordingStatus.off) return 'No new footage is being recorded';
    if (!widget.camera.sdStorageEnabled || !widget.camera.sdCardPresent) {
      return 'No local storage available — see Storage settings';
    }
    final estimate = formatApproxDuration(
      widget.camera.estimatedRecordingTimeRemaining,
    );
    return 'Approximately $estimate of footage can be stored locally at '
        'current usage';
  }

  void _markDirty(VoidCallback update) {
    setState(() {
      update();
      _isDirty = true;
    });
  }

  bool _overlaps(RecordingScheduleWindow a, RecordingScheduleWindow b) {
    if (a.day != b.day) return false;
    return a.startMinutes < b.endMinutes && b.startMinutes < a.endMinutes;
  }

  Future<void> _openWindowDialog({RecordingScheduleWindow? editing}) async {
    var day = editing?.day ?? RecordingScheduleDay.monday;
    var start = editing?.startMinutes ?? 8 * 60;
    var end = editing?.endMinutes ?? 18 * 60;
    String? error;

    final result = await showDialog<RecordingScheduleWindow>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(editing == null ? 'Add window' : 'Edit window'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<RecordingScheduleDay>(
                key: const Key('REC-008-day'),
                initialValue: day,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Day'),
                items: [
                  for (final d in RecordingScheduleDay.values)
                    DropdownMenuItem(
                      value: d,
                      child: Text(
                        _dayLabels[d]!,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setDialogState(() => day = value ?? day),
              ),
              const SizedBox(height: 12),
              ListTile(
                key: const Key('REC-008-start'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Start time'),
                trailing: Text(_formatMinutes(start)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: dialogContext,
                    initialTime: TimeOfDay(
                      hour: start ~/ 60,
                      minute: start % 60,
                    ),
                  );
                  if (picked != null) {
                    setDialogState(
                      () => start = picked.hour * 60 + picked.minute,
                    );
                  }
                },
              ),
              ListTile(
                key: const Key('REC-008-end'),
                contentPadding: EdgeInsets.zero,
                title: const Text('End time'),
                trailing: Text(_formatMinutes(end)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: dialogContext,
                    initialTime: TimeOfDay(hour: end ~/ 60, minute: end % 60),
                  );
                  if (picked != null) {
                    setDialogState(
                      () => end = picked.hour * 60 + picked.minute,
                    );
                  }
                },
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error!,
                  style: TextStyle(
                    color: Theme.of(dialogContext).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (end <= start) {
                  setDialogState(
                    () => error = 'End time must be after start time',
                  );
                  return;
                }
                final candidate = RecordingScheduleWindow(
                  day: day,
                  startMinutes: start,
                  endMinutes: end,
                );
                final conflicts = _scheduleWindows.any(
                  (w) => w != editing && _overlaps(w, candidate),
                );
                if (conflicts) {
                  setDialogState(
                    () => error =
                        'This overlaps another window on ${_dayLabels[day]}',
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(candidate);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    _markDirty(() {
      if (editing != null) _scheduleWindows.remove(editing);
      _scheduleWindows.add(result);
    });
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
          recordingStatus: _mode,
          recordingScheduleWindows: _scheduleWindows,
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

  void _openDetectionsScreen() {
    final location = GoRouterState.of(context).matchedLocation;
    final parent = location.substring(0, location.lastIndexOf('/'));
    context.push('$parent/${DetectionsScreen.routeName}', extra: widget.camera);
  }

  Future<bool> _confirmLeave() => confirmDiscardOnLeave(
    context: context,
    isDirty: _isDirty,
    onSave: _save,
    isDirtyAfterSave: () => _isDirty,
    dialogKey: const Key('REC-011'),
    discardKey: const Key('REC-012'),
    saveKey: const Key('REC-013'),
  );

  @override
  Widget build(BuildContext context) {
    final showSchedule = _mode == RecordingStatus.scheduled;
    final showEventTriggeredWarning =
        _mode == RecordingStatus.eventTriggered && !_hasAnyDetectionEnabled;

    return LeaveGuard(
      canLeave: _confirmLeave,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            key: const Key('REC-001'),
            title: const Text('Recording'),
            actions: [
              SettingsSaveButton(
                settingsKey: const Key('REC-002'),
                isDirty: _isDirty,
                isSaving: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
          body: SavingOverlay(
            isSaving: _isSaving,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: RadioGroup<RecordingStatus>(
                    groupValue: _mode,
                    onChanged: (value) =>
                        _markDirty(() => _mode = value ?? _mode),
                    child: Column(
                      key: const Key('REC-003'),
                      children: [
                        for (final mode in RecordingStatus.values)
                          RadioListTile<RecordingStatus>(
                            value: mode,
                            title: Text(_modeLabels[mode]!),
                            subtitle: Text(_modeDescriptions[mode]!),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Row(
                    children: [
                      const Icon(Icons.sd_storage_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        key: const Key('REC-004'),
                        child: Text(_footageEstimate),
                      ),
                    ],
                  ),
                ),
                if (showEventTriggeredWarning) ...[
                  const SizedBox(height: 12),
                  GlassCard(
                    key: const Key('REC-009'),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'No detection is set up on this camera yet, '
                                'so Event-Triggered recording won\'t capture '
                                'anything.',
                              ),
                              TextButton(
                                key: const Key('REC-010'),
                                onPressed: _openDetectionsScreen,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  alignment: Alignment.centerLeft,
                                ),
                                child: const Text('Set up detection'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (showSchedule) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Schedule',
                    key: const Key('REC-005'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final window in _scheduleWindows) ...[
                    GlassCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        key: Key(
                          'REC-006-${window.day.name}-${window.startMinutes}',
                        ),
                        title: Text(_dayLabels[window.day]!),
                        subtitle: Text(
                          '${_formatMinutes(window.startMinutes)} – '
                          '${_formatMinutes(window.endMinutes)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _openWindowDialog(editing: window),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _markDirty(
                                () => _scheduleWindows.remove(window),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  OutlinedButton.icon(
                    key: const Key('REC-007'),
                    onPressed: () => _openWindowDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add window'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
