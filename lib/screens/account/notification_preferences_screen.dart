import 'package:flutter/material.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';

/// Notification preferences: which alerts to be notified about and how.
/// No notification backend is wired up yet (see CLAUDE.md), so every
/// toggle just lives in local widget state — nothing is actually sent.
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  static const routeName = 'notifications';

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _motionDetected = true;
  bool _personDetected = true;
  bool _vehicleDetected = true;
  bool _cameraOffline = true;
  bool _cameraBackOnline = false;
  bool _quietHours = false;
  bool _sound = true;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);

  bool get _channelsEnabled => _pushEnabled || _emailEnabled;

  Future<void> _pickTime({
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('NOTIF-001'),
          title: const Text('Notification Preferences'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    key: const Key('NOTIF-002'),
                    title: const Text('Push notifications'),
                    value: _pushEnabled,
                    onChanged: (value) => setState(() => _pushEnabled = value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    key: const Key('NOTIF-003'),
                    title: const Text('Email notifications'),
                    value: _emailEnabled,
                    onChanged: (value) => setState(() => _emailEnabled = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    key: const Key('NOTIF-004'),
                    title: const Text('Motion detected'),
                    value: _motionDetected,
                    onChanged: _channelsEnabled
                        ? (value) => setState(() => _motionDetected = value)
                        : null,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    key: const Key('NOTIF-005'),
                    title: const Text('Person detected'),
                    value: _personDetected,
                    onChanged: _channelsEnabled
                        ? (value) => setState(() => _personDetected = value)
                        : null,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    key: const Key('NOTIF-006'),
                    title: const Text('Vehicle detected'),
                    value: _vehicleDetected,
                    onChanged: _channelsEnabled
                        ? (value) => setState(() => _vehicleDetected = value)
                        : null,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    key: const Key('NOTIF-007'),
                    title: const Text('Camera offline'),
                    value: _cameraOffline,
                    onChanged: _channelsEnabled
                        ? (value) => setState(() => _cameraOffline = value)
                        : null,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    key: const Key('NOTIF-008'),
                    title: const Text('Camera back online'),
                    value: _cameraBackOnline,
                    onChanged: _channelsEnabled
                        ? (value) => setState(() => _cameraBackOnline = value)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    key: const Key('NOTIF-009'),
                    title: const Text('Quiet hours'),
                    subtitle: const Text(
                      'Mute notifications during a set time range',
                    ),
                    value: _quietHours,
                    onChanged: _channelsEnabled
                        ? (value) => setState(() => _quietHours = value)
                        : null,
                  ),
                  if (_quietHours && _channelsEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      key: const Key('NOTIF-010'),
                      title: const Text('Start'),
                      trailing: Text(_quietHoursStart.format(context)),
                      onTap: () => _pickTime(
                        initial: _quietHoursStart,
                        onPicked: (time) => _quietHoursStart = time,
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      key: const Key('NOTIF-011'),
                      title: const Text('End'),
                      trailing: Text(_quietHoursEnd.format(context)),
                      onTap: () => _pickTime(
                        initial: _quietHoursEnd,
                        onPicked: (time) => _quietHoursEnd = time,
                      ),
                    ),
                  ],
                  const Divider(height: 1),
                  SwitchListTile(
                    key: const Key('NOTIF-012'),
                    title: const Text('Sound'),
                    value: _sound,
                    onChanged: _channelsEnabled
                        ? (value) => setState(() => _sound = value)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
