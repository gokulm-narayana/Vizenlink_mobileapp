import 'package:camera_api/camera_api.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_state/homes_controller.dart';
import '../../models/camera.dart';
import '../../models/home.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/live_status_badges.dart' show formatBitrate;
import '../../widgets/navigation_leave_guard.dart';
import 'wifi_config_screen.dart';

const _unassignedRoomLabel = 'Unassigned';

/// User's choice in the unsaved-changes leave-confirmation dialog.
enum _LeaveChoice { save, discard }

/// Dummy timezone options until a real camera can report its own list.
const _dummyTimezones = [
  'UTC',
  'America/New_York',
  'America/Chicago',
  'America/Denver',
  'America/Los_Angeles',
  'Europe/London',
  'Europe/Berlin',
  'Asia/Kolkata',
  'Asia/Tokyo',
  'Australia/Sydney',
];

/// Camera Info: editable name and home/room location, read-only
/// device-info fields sourced from the [Camera] model (stub data until a
/// real CCTV protocol/backend exists — see CLAUDE.md), and a password
/// change dialog.
class CameraInfoScreen extends StatefulWidget {
  const CameraInfoScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'info';

  final Camera camera;
  final HomesController homesController;

  @override
  State<CameraInfoScreen> createState() => _CameraInfoScreenState();
}

class _CameraInfoScreenState extends State<CameraInfoScreen> {
  late final TextEditingController _nameController;
  late final String _originalHomeId;
  late String _homeId;
  late String? _room;
  late String _timezone;
  bool _isDirty = false;
  bool _syncing = false;

  /// The camera's current state from [HomesController], looked up fresh on
  /// every build rather than [widget.camera] directly — needed so
  /// [_syncFromCamera]'s live-fetched fields actually show up after a
  /// sync, since [widget.camera] itself stays the snapshot passed in when
  /// this screen was opened. Falls back to [widget.camera] if the camera
  /// was deleted from underneath this screen.
  Camera get _camera {
    for (final home in widget.homesController.value.homes) {
      for (final camera in home.cameras) {
        if (camera.id == widget.camera.id) return camera;
      }
    }
    return widget.camera;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.camera.name);
    _nameController.addListener(_markDirty);
    _originalHomeId = _homeContainingCamera(widget.camera.id).id;
    _homeId = _originalHomeId;
    _room = widget.camera.room;
    _timezone = widget.camera.timezone;
  }

  @override
  void dispose() {
    _nameController.removeListener(_markDirty);
    _nameController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Home _homeContainingCamera(String cameraId) {
    return widget.homesController.value.homes.firstWhere(
      (home) => home.cameras.any((camera) => camera.id == cameraId),
    );
  }

  void _onHomeChanged(String? newHomeId) {
    if (newHomeId == null || newHomeId == _homeId) return;
    setState(() {
      _homeId = newHomeId;
      _room = null;
      _isDirty = true;
    });
  }

  void _onRoomChanged(String? newRoom) {
    setState(() {
      _room = newRoom;
      _isDirty = true;
    });
  }

  void _onTimezoneChanged(String? newTimezone) {
    if (newTimezone == null) return;
    setState(() {
      _timezone = newTimezone;
      _isDirty = true;
    });
  }

  void _commitChanges() {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty && newName != widget.camera.name) {
      widget.homesController.renameCamera(
        _originalHomeId,
        widget.camera.id,
        newName,
      );
    }
    if (_homeId != _originalHomeId || _room != widget.camera.room) {
      widget.homesController.moveCameraToHome(
        fromHomeId: _originalHomeId,
        toHomeId: _homeId,
        cameraId: widget.camera.id,
        room: _room,
      );
    }
    if (_timezone != widget.camera.timezone) {
      widget.homesController.updateCameraTimezone(
        _homeId,
        widget.camera.id,
        _timezone,
      );
    }
    setState(() => _isDirty = false);
  }

  Future<void> _confirmAndSave() async {
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('CAMINFO-022'),
        title: const Text('Save changes?'),
        content: const Text(
          'This will update the camera\'s name, home/room, and timezone.',
        ),
        actions: [
          TextButton(
            key: const Key('CAMINFO-023'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('CAMINFO-024'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (shouldSave != true || !mounted) return;
    _commitChanges();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Changes saved')));
  }

  /// Called when the user tries to leave the screen with unsaved edits.
  /// Returns true if the pop should proceed (either nothing to save, or the
  /// user explicitly chose to discard).
  Future<bool> _confirmDiscardOnLeave() async {
    if (!_isDirty) return true;
    final choice = await showDialog<_LeaveChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('CAMINFO-025'),
        title: const Text('Unsaved changes'),
        content: const Text(
          'You have unsaved changes. Save them before leaving?',
        ),
        actions: [
          TextButton(
            key: const Key('CAMINFO-026'),
            onPressed: () =>
                Navigator.of(dialogContext).pop(_LeaveChoice.discard),
            child: const Text('Discard'),
          ),
          FilledButton(
            key: const Key('CAMINFO-027'),
            onPressed: () => Navigator.of(dialogContext).pop(_LeaveChoice.save),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (choice == _LeaveChoice.save) {
      _commitChanges();
      return true;
    }
    return choice == _LeaveChoice.discard;
  }

  Future<void> _openModifyPasswordDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          _ModifyPasswordDialog(key: const Key('CAMINFO-016')),
    );
  }

  /// Fetches this camera's live device information, network interface, and
  /// WAN capability over LAN (`OnvifDeviceClient`/`CapabilitiesClient`) and
  /// persists whatever comes back via [HomesController.updateCamera]. Only
  /// available once a `CameraConnection` has been saved for this camera
  /// (see [Camera.connection]'s doc) — cameras added before onboarding
  /// captured credentials, or whose scan setup form hasn't actually
  /// connected yet, have nothing to sync from.
  Future<void> _syncFromCamera() async {
    final connection = _camera.connection;
    if (connection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No saved connection for this camera yet'),
        ),
      );
      return;
    }

    setState(() => _syncing = true);
    final device = OnvifDeviceClient(connection);
    final nuraeye = NuraeyeClient(connection);
    try {
      final results = await Future.wait([
        device.getDeviceInformation(),
        device.getNetworkInterfaceInfo(),
        CapabilitiesClient(nuraeye).getCapabilities(),
      ]);
      final infoResult = results[0] as CameraResult<DeviceInformation>;
      final netResult = results[1] as CameraResult<NetworkInterfaceInfo>;
      final capsResult = results[2] as CameraResult<CameraCapabilities>;

      final failures = <String>[];
      DeviceInformation? info;
      NetworkInterfaceInfo? net;
      CameraCapabilities? caps;

      switch (infoResult) {
        case CameraSuccess(:final value):
          info = value;
        case CameraFailure(:final reason):
          failures.add('device info ($reason)');
        case CameraTimeout():
          failures.add('device info (timed out)');
      }
      switch (netResult) {
        case CameraSuccess(:final value):
          net = value;
        case CameraFailure(:final reason):
          failures.add('network info ($reason)');
        case CameraTimeout():
          failures.add('network info (timed out)');
      }
      switch (capsResult) {
        case CameraSuccess(:final value):
          caps = value;
        case CameraFailure(:final reason):
          failures.add('capabilities ($reason)');
        case CameraTimeout():
          failures.add('capabilities (timed out)');
      }

      if (info != null || net != null || caps != null) {
        widget.homesController.updateCamera(
          widget.camera.id,
          (current) => current.copyWith(
            manufacturer: info?.manufacturer,
            model: info?.model,
            firmwareVersion: info?.firmwareVersion,
            serialNumber: info?.serialNumber,
            hardwareId: info?.hardwareId,
            macAddress: net?.macAddress,
            ipAddress: net?.ipv4Address,
            // The device's serial number doubles as its AWS IoT thing
            // name/KVS stream name (OnvifDeviceClient.getSerialNumber's
            // doc) — this is what unlocks the WAN identity/live-view
            // clients for a camera onboarded via LAN.
            thingName: info?.serialNumber,
            wanLiveViewCapable: caps?.wanLiveViewCapable,
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failures.isEmpty
                ? 'Synced with camera'
                : 'Synced with camera, but ${failures.join(', ')} failed',
          ),
        ),
      );
    } finally {
      device.close();
      nuraeye.close();
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final homes = widget.homesController.value.homes;
    final selectedHome = homes.firstWhere((home) => home.id == _homeId);
    final rooms = selectedHome.rooms;

    return LeaveGuard(
      canLeave: _confirmDiscardOnLeave,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            key: const Key('CAMINFO-001'),
            title: const Text('Camera Info'),
            actions: [
              TextButton(
                key: const Key('CAMINFO-002'),
                onPressed: _isDirty ? _confirmAndSave : null,
                child: const Text('Save'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_camera.healthConditionMessages.isNotEmpty) ...[
                _SectionHeader('Health'),
                const SizedBox(height: 8),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (index, message)
                          in _camera.healthConditionMessages.indexed)
                        _InfoRow(
                          settingsKey: Key('CAMINFO-031-$index'),
                          icon: Icons.warning_amber_rounded,
                          label: message,
                          value: '',
                          isLast:
                              index ==
                              _camera.healthConditionMessages.length - 1,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _SectionHeader('Device Identity'),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const Key('CAMINFO-003'),
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Camera name',
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('CAMINFO-032'),
                onPressed: _syncing ? null : _syncFromCamera,
                icon: _syncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(_syncing ? 'Syncing…' : 'Sync from camera'),
              ),
              const SizedBox(height: 8),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _InfoRow(
                      settingsKey: const Key('CAMINFO-011'),
                      icon: Icons.precision_manufacturing_outlined,
                      label: 'Manufacturer & model',
                      value: '${_camera.manufacturer} ${_camera.model}',
                    ),
                    _InfoRow(
                      settingsKey: const Key('CAMINFO-013'),
                      icon: Icons.tag,
                      label: 'Serial number',
                      value: _camera.serialNumber,
                    ),
                    _InfoRow(
                      settingsKey: const Key('CAMINFO-014'),
                      icon: Icons.fingerprint,
                      label: 'Hardware ID',
                      value: _camera.hardwareId,
                    ),
                    _InfoRow(
                      settingsKey: const Key('CAMINFO-012'),
                      icon: Icons.system_update_outlined,
                      label: 'Firmware version',
                      value: _camera.firmwareVersion,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader('Network & Connectivity'),
              const SizedBox(height: 8),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _InfoRow(
                      settingsKey: const Key('CAMINFO-008'),
                      icon: Icons.wifi,
                      label: 'Wi-Fi network',
                      value: _camera.wifiNetwork,
                    ),
                    _InfoRow(
                      settingsKey: const Key('CAMINFO-009'),
                      icon: Icons.signal_cellular_alt,
                      label: 'Signal strength',
                      value: '${_camera.signalStrength} / 4',
                    ),
                    _InfoRow(
                      settingsKey: const Key('CAMINFO-030'),
                      icon: Icons.speed_outlined,
                      label: 'Network speed',
                      value: formatBitrate(_camera.networkSpeedKbps),
                    ),
                    _InfoRow(
                      settingsKey: const Key('CAMINFO-010'),
                      icon: Icons.memory,
                      label: 'MAC address',
                      value: _camera.macAddress,
                    ),
                    _InfoRow(
                      settingsKey: const Key('CAMINFO-028'),
                      icon: Icons.lan_outlined,
                      label: 'IP address',
                      value: _camera.ipAddress,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('CAMINFO-029'),
                onPressed: () => context.push(
                  '${GoRouterState.of(context).matchedLocation}/${WifiConfigScreen.routeName}',
                  extra: _camera,
                ),
                icon: const Icon(Icons.wifi_outlined),
                label: const Text('Configure Wi-Fi'),
              ),
              const SizedBox(height: 24),
              _SectionHeader('Location'),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      key: const Key('CAMINFO-004'),
                      initialValue: _homeId,
                      decoration: const InputDecoration(labelText: 'Home'),
                      items: [
                        for (final home in homes)
                          DropdownMenuItem(
                            value: home.id,
                            child: Text(home.name),
                          ),
                      ],
                      onChanged: _onHomeChanged,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      key: const Key('CAMINFO-005'),
                      initialValue: _room,
                      decoration: const InputDecoration(labelText: 'Room'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(_unassignedRoomLabel),
                        ),
                        for (final room in rooms)
                          DropdownMenuItem<String?>(
                            value: room,
                            child: Text(room),
                          ),
                      ],
                      onChanged: _onRoomChanged,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: const Key('CAMINFO-006'),
                      initialValue: _dummyTimezones.contains(_timezone)
                          ? _timezone
                          : _dummyTimezones.first,
                      decoration: const InputDecoration(labelText: 'Timezone'),
                      items: [
                        for (final zone in _dummyTimezones)
                          DropdownMenuItem(value: zone, child: Text(zone)),
                      ],
                      onChanged: _onTimezoneChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader('Recording'),
              const SizedBox(height: 8),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _InfoRow(
                      settingsKey: const Key('CAMINFO-007'),
                      icon: Icons.fiber_manual_record,
                      label: 'Recording status',
                      value: _recordingStatusLabel(_camera.recordingStatus),
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader('Security'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('CAMINFO-015'),
                onPressed: _openModifyPasswordDialog,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Modify Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _recordingStatusLabel(RecordingStatus status) {
    switch (status) {
      case RecordingStatus.continuous:
        return 'Continuous';
      case RecordingStatus.scheduled:
        return 'Scheduled';
      case RecordingStatus.eventTriggered:
        return 'Event-triggered';
      case RecordingStatus.off:
        return 'Off';
    }
  }
}

/// Section label above a group of related fields (e.g. "Device Identity",
/// "Network & Connectivity").
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.settingsKey,
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final Key settingsKey;
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: settingsKey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Change-password dialog: current, new, confirm password + Cancel/Save.
/// Validates fields and shows a success snackbar — there is no camera
/// credential backend yet, so Save does not perform a real change.
class _ModifyPasswordDialog extends StatefulWidget {
  const _ModifyPasswordDialog({super.key});

  @override
  State<_ModifyPasswordDialog> createState() => _ModifyPasswordDialogState();
}

class _ModifyPasswordDialogState extends State<_ModifyPasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _save() {
    if (_currentController.text.isEmpty) {
      setState(() => _errorText = 'Enter the current password');
      return;
    }
    if (_newController.text.length < 8) {
      setState(() => _errorText = 'New password must be at least 8 characters');
      return;
    }
    if (_newController.text != _confirmController.text) {
      setState(() => _errorText = 'Passwords do not match');
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Password updated')));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Modify Password',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('CAMINFO-017'),
                controller: _currentController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('CAMINFO-018'),
                controller: _newController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('CAMINFO-019'),
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              GradientButton(
                key: const Key('CAMINFO-021'),
                onPressed: _save,
                child: const Text('Save'),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('CAMINFO-020'),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
