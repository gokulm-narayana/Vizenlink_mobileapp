import 'package:camera_api/camera_api.dart';
import 'package:flutter/material.dart';

import '../../app_state/homes_controller.dart';
import '../../models/camera.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/reload_settings_button.dart';

/// Reformats a camera alert-type wire string ("PersonDetected") into a
/// readable label ("Person Detected") by splitting on capital letters.
String _formatEventTypeLabel(String type) {
  return type.replaceAllMapped(
    RegExp('(?<=[a-z0-9])(?=[A-Z])'),
    (match) => ' ',
  );
}

/// Reformats a deterrence/response-action wire string ("mobile_alert") into
/// a readable label ("Mobile Alert").
String _formatActionLabel(String action) {
  return action
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

/// Per-camera alert configuration — reached from AlertsScreen's ALERT-022
/// button. Three real `camera_api`-backed sections per camera, all built
/// from the camera's own reported capabilities rather than a hardcoded
/// list, per `.claude/rules/mobile-app-screen-conventions.md`:
///
/// - **Alert Types** (ALERTSET-007): `EventPreferencesClient` — does this
///   event type generate an alert at all.
/// - **Response Actions** (ALERTSET-012/013): `EventResponseActionsClient`
///   — for detection event types, which action(s) auto-fire when it does.
/// - **Deterrence** (ALERTSET-015): `DeterrenceClient` — live status plus
///   the shared auto-stop duration each manual/automatic trigger uses.
///
/// See `docs/screens/alerts/alert_settings_screen.md`.
class AlertSettingsScreen extends StatelessWidget {
  const AlertSettingsScreen({super.key, required this.homesController});

  static const routeName = 'settings';

  final HomesController homesController;

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('ALERTSET-001'),
          title: const Text('Alert Settings'),
        ),
        body: ValueListenableBuilder(
          valueListenable: homesController,
          builder: (context, state, _) {
            final homes = state.homes;
            final showHomeName = homes.length > 1;
            final cameras = <(Camera, String)>[
              for (final home in homes)
                for (final camera in home.cameras) (camera, home.name),
            ];

            if (cameras.isEmpty) {
              return const Center(child: Text('No cameras yet'));
            }

            return ListView.separated(
              key: const Key('ALERTSET-003'),
              padding: const EdgeInsets.all(16),
              itemCount: cameras.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final (camera, homeName) = cameras[index];
                return _CameraAlertSection(
                  camera: camera,
                  subtitle: showHomeName ? homeName : null,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CameraAlertSection extends StatefulWidget {
  const _CameraAlertSection({required this.camera, required this.subtitle});

  final Camera camera;
  final String? subtitle;

  @override
  State<_CameraAlertSection> createState() => _CameraAlertSectionState();
}

class _CameraAlertSectionState extends State<_CameraAlertSection> {
  bool _expanded = false;
  bool _loading = false;
  String? _error;

  // Alert Types
  List<String>? _supportedTypes;
  Map<String, bool>? _preferences;
  bool _masterBusy = false;
  final _busyTypes = <String>{};

  // Response Actions
  Map<String, List<String>>? _deterrenceOptions;
  Map<String, List<String>>? _responseActions;
  final _busyResponseActions = <String>{}; // "type|action"

  // Deterrence status/duration
  bool _sirenCapable = false;
  bool _spotlightCapable = false;
  bool _warningCapable = false;
  DeterrenceStatus? _deterrenceStatus;
  Map<String, int>? _deterrenceDurations;
  final _pendingDurations = <String, double>{};
  DeterrenceDurationOptions? _durationOptions;
  final _busyDurationActions = <String>{};

  CameraConnection? get _connection => widget.camera.connection;

  static const _durationKeyByAction = {
    'siren': 'siren_seconds',
    'spotlight': 'spotlight_seconds',
    'warning': 'warning_repeat_count',
  };

  Future<void> _toggleExpanded() async {
    final expanding = !_expanded;
    setState(() => _expanded = expanding);
    if (expanding && _supportedTypes == null && _connection != null) {
      await _load();
    }
  }

  Future<void> _load() async {
    final connection = _connection;
    if (connection == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final nuraeye = NuraeyeClient(connection);
    final capabilitiesResult = await CapabilitiesClient(
      nuraeye,
    ).getCapabilities();

    if (capabilitiesResult is! CameraSuccess<CameraCapabilities>) {
      nuraeye.close();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Couldn't load alert settings for this camera";
      });
      return;
    }
    final capabilities = capabilitiesResult.value;

    final results = await Future.wait([
      EventPreferencesClient(nuraeye).getEventPreferences(),
      if (capabilities.supportedEventDeterrenceOptions.isNotEmpty)
        EventResponseActionsClient(nuraeye).getEventResponseActions(),
      if (capabilities.sirenCapable ||
          capabilities.spotlightCapable ||
          capabilities.warningCapable) ...[
        DeterrenceClient(nuraeye).getDeterrenceStatus(),
        DeterrenceClient(nuraeye).getDeterrenceDurations(),
        DeterrenceClient(nuraeye).getDeterrenceDurationOptions(),
      ],
    ]);
    nuraeye.close();
    if (!mounted) return;

    var index = 0;
    final preferencesResult =
        results[index++] as CameraResult<Map<String, bool>>;
    if (preferencesResult is! CameraSuccess<Map<String, bool>>) {
      setState(() {
        _loading = false;
        _error = "Couldn't load alert settings for this camera";
      });
      return;
    }

    Map<String, List<String>>? responseActions;
    if (capabilities.supportedEventDeterrenceOptions.isNotEmpty) {
      final result =
          results[index++] as CameraResult<Map<String, List<String>>>;
      if (result case CameraSuccess(:final value)) responseActions = value;
    }

    DeterrenceStatus? deterrenceStatus;
    Map<String, int>? deterrenceDurations;
    DeterrenceDurationOptions? durationOptions;
    if (capabilities.sirenCapable ||
        capabilities.spotlightCapable ||
        capabilities.warningCapable) {
      final statusResult = results[index++] as CameraResult<DeterrenceStatus>;
      final durationsResult =
          results[index++] as CameraResult<Map<String, int>>;
      final optionsResult =
          results[index++] as CameraResult<DeterrenceDurationOptions>;
      if (statusResult case CameraSuccess(:final value)) {
        deterrenceStatus = value;
      }
      if (durationsResult case CameraSuccess(:final value)) {
        deterrenceDurations = value;
      }
      if (optionsResult case CameraSuccess(:final value)) {
        durationOptions = value;
      }
    }

    setState(() {
      _loading = false;
      _supportedTypes = capabilities.supportedEventTypes;
      _preferences = preferencesResult.value;
      _deterrenceOptions = capabilities.supportedEventDeterrenceOptions;
      _responseActions = responseActions;
      _sirenCapable = capabilities.sirenCapable;
      _spotlightCapable = capabilities.spotlightCapable;
      _warningCapable = capabilities.warningCapable;
      _deterrenceStatus = deterrenceStatus;
      _deterrenceDurations = deterrenceDurations;
      _durationOptions = durationOptions;
      _pendingDurations.clear();
      if (deterrenceDurations != null) {
        for (final entry in deterrenceDurations.entries) {
          _pendingDurations[entry.key] = entry.value.toDouble();
        }
      }
    });
  }

  /// Shared `EventPreferencesClient`/`WanEventPreferencesClient.
  /// setEventPreferences` call — retried over WAN on a LAN failure per
  /// `mobile-app-screen-conventions.md`'s LAN/WAN convention.
  Future<bool> _sendPreferences(Map<String, bool> changes) async {
    final connection = _connection;
    if (connection == null) return false;
    final nuraeye = NuraeyeClient(connection);
    var result = await EventPreferencesClient(
      nuraeye,
    ).setEventPreferences(changes);
    nuraeye.close();
    final thingName = connection.thingName;
    if (result is! CameraSuccess && thingName != null) {
      result = await WanEventPreferencesClient(
        thingName,
      ).setEventPreferences(changes);
    }
    return result is CameraSuccess;
  }

  /// Shared `EventResponseActionsClient`/`WanEventResponseActionsClient.
  /// setEventResponseActions` call, same LAN/WAN retry convention.
  Future<bool> _sendResponseActions(Map<String, List<String>> changes) async {
    final connection = _connection;
    if (connection == null) return false;
    final nuraeye = NuraeyeClient(connection);
    var result = await EventResponseActionsClient(
      nuraeye,
    ).setEventResponseActions(changes);
    nuraeye.close();
    final thingName = connection.thingName;
    if (result is! CameraSuccess && thingName != null) {
      result = await WanEventResponseActionsClient(
        thingName,
      ).setEventResponseActions(changes);
    }
    return result is CameraSuccess;
  }

  /// Shared `DeterrenceClient`/`WanDeterrenceClient.setDeterrenceDurations`
  /// call, same LAN/WAN retry convention.
  Future<bool> _sendDurations(Map<String, int> changes) async {
    final connection = _connection;
    if (connection == null) return false;
    final nuraeye = NuraeyeClient(connection);
    var result = await DeterrenceClient(
      nuraeye,
    ).setDeterrenceDurations(changes);
    nuraeye.close();
    final thingName = connection.thingName;
    if (result is! CameraSuccess && thingName != null) {
      result = await WanDeterrenceClient(
        thingName,
      ).setDeterrenceDurations(changes);
    }
    return result is CameraSuccess;
  }

  void _showFailureSnackBar(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to update $what. Try again.")),
    );
  }

  Future<void> _setMaster(bool value) async {
    final types = _supportedTypes;
    if (types == null || types.isEmpty) return;
    setState(() => _masterBusy = true);
    final succeeded = await _sendPreferences({
      for (final type in types) type: value,
    });
    if (!mounted) return;
    setState(() {
      _masterBusy = false;
      if (succeeded) _preferences = {for (final type in types) type: value};
    });
    if (!succeeded) _showFailureSnackBar('alert setting');
  }

  Future<void> _setType(String type, bool value) async {
    setState(() => _busyTypes.add(type));
    final succeeded = await _sendPreferences({type: value});
    if (!mounted) return;
    setState(() {
      _busyTypes.remove(type);
      if (succeeded) _preferences = {...?_preferences, type: value};
    });
    if (!succeeded) _showFailureSnackBar('alert setting');
  }

  Future<void> _toggleResponseAction(
    String type,
    String action,
    bool selected,
  ) async {
    final currentActions = _responseActions?[type] ?? const <String>[];
    final newActions = selected
        ? [...currentActions, action]
        : currentActions.where((a) => a != action).toList();
    final key = '$type|$action';
    setState(() => _busyResponseActions.add(key));
    final succeeded = await _sendResponseActions({type: newActions});
    if (!mounted) return;
    setState(() {
      _busyResponseActions.remove(key);
      if (succeeded) {
        _responseActions = {...?_responseActions, type: newActions};
      }
    });
    if (!succeeded) _showFailureSnackBar('response actions');
  }

  Future<void> _commitDuration(String action) async {
    final key = _durationKeyByAction[action];
    final pending = key == null ? null : _pendingDurations[key];
    if (key == null || pending == null) return;
    final newValue = pending.round();
    if (_deterrenceDurations?[key] == newValue) return;
    setState(() => _busyDurationActions.add(action));
    final succeeded = await _sendDurations({key: newValue});
    if (!mounted) return;
    setState(() {
      _busyDurationActions.remove(action);
      if (succeeded) {
        _deterrenceDurations = {...?_deterrenceDurations, key: newValue};
      } else {
        // Revert the slider to the last confirmed value on failure.
        final confirmed = _deterrenceDurations?[key];
        if (confirmed != null) _pendingDurations[key] = confirmed.toDouble();
      }
    });
    if (!succeeded) _showFailureSnackBar('deterrence duration');
  }

  @override
  Widget build(BuildContext context) {
    final preferences = _preferences;
    // "Any type enabled", not "every type enabled" — an all-enabled reading
    // would flip this switch off the moment a single detection type (e.g.
    // Person Detected) gets turned off while others stay on, and tapping it
    // to "fix" that would then blast every type back on, including ones
    // deliberately left off. "Alerts: off" should mean nothing is enabled
    // for this camera at all, not "not literally everything is enabled".
    final anyOn =
        preferences != null && preferences.values.any((enabled) => enabled);

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    key: Key('ALERTSET-006-${widget.camera.id}'),
                    onTap: _connection == null ? null : _toggleExpanded,
                    child: Row(
                      children: [
                        Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.camera.name,
                                key: Key('ALERTSET-004-${widget.camera.id}'),
                                style: Theme.of(context).textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.subtitle != null)
                                Text(
                                  widget.subtitle!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_connection == null)
                  Padding(
                    key: Key('ALERTSET-008-${widget.camera.id}'),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'No connection',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                else if (_masterBusy)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  Switch(
                    key: Key('ALERTSET-005-${widget.camera.id}'),
                    value: anyOn,
                    onChanged: preferences == null
                        ? null
                        : (value) => _setMaster(value),
                  ),
              ],
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            if (_loading)
              const Padding(
                key: Key('ALERTSET-009'),
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_error != null)
              Padding(
                key: const Key('ALERTSET-010'),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: Text(_error!)),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              )
            else ...[
              Align(
                alignment: Alignment.centerRight,
                child: ReloadSettingsButton(
                  settingsKey: Key('ALERTSET-017-${widget.camera.id}'),
                  isBusy: _loading,
                  onPressed: _load,
                ),
              ),
              _buildAlertTypesSection(context),
              _buildResponseActionsSection(context),
              _buildDeterrenceSection(context),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAlertTypesSection(BuildContext context) {
    final types = _supportedTypes;
    final preferences = _preferences;
    if (types == null || preferences == null || types.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        for (final type in types)
          SwitchListTile(
            key: Key('ALERTSET-007-${widget.camera.id}-$type'),
            title: Text(_formatEventTypeLabel(type)),
            value: preferences[type] ?? false,
            onChanged: _busyTypes.contains(type)
                ? null
                : (value) => _setType(type, value),
            secondary: _busyTypes.contains(type)
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
      ],
    );
  }

  Widget _buildResponseActionsSection(BuildContext context) {
    final options = _deterrenceOptions;
    if (options == null || options.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 24),
          Text(
            'Response Actions',
            key: Key('ALERTSET-011-${widget.camera.id}'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'What the camera does automatically when a detection fires.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          for (final type in options.keys)
            Padding(
              key: Key('ALERTSET-012-${widget.camera.id}-$type'),
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatEventTypeLabel(type)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final action in options[type]!)
                        _buildResponseActionChip(type, action),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResponseActionChip(String type, String action) {
    final busyKey = '$type|$action';
    final selected = _responseActions?[type]?.contains(action) ?? false;
    final busy = _busyResponseActions.contains(busyKey);
    return FilterChip(
      key: Key('ALERTSET-013-${widget.camera.id}-$type-$action'),
      label: busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(_formatActionLabel(action)),
      selected: selected,
      onSelected: busy
          ? null
          : (value) => _toggleResponseAction(type, action, value),
    );
  }

  Widget _buildDeterrenceSection(BuildContext context) {
    final durations = _deterrenceDurations;
    final options = _durationOptions;
    if (durations == null || options == null) return const SizedBox.shrink();

    final actions = [
      if (_sirenCapable) 'siren',
      if (_spotlightCapable) 'spotlight',
      if (_warningCapable) 'warning',
    ];
    if (actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 24),
          Text(
            'Deterrence',
            key: Key('ALERTSET-014-${widget.camera.id}'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Auto-stop duration for manual and automatic triggers.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          for (final action in actions) _buildDeterrenceRow(context, action),
        ],
      ),
    );
  }

  Widget _buildDeterrenceRow(BuildContext context, String action) {
    final durationKey = _durationKeyByAction[action]!;
    final options = _durationOptions!;
    final (min, max) = switch (action) {
      'siren' => (options.sirenSecondsMin, options.sirenSecondsMax),
      'spotlight' => (options.spotlightSecondsMin, options.spotlightSecondsMax),
      _ => (options.warningRepeatCountMin, options.warningRepeatCountMax),
    };
    final pending = _pendingDurations[durationKey] ?? min.toDouble();
    final isActive = _deterrenceStatus?.isActive(action) ?? false;
    final busy = _busyDurationActions.contains(action);
    final unit = action == 'warning' ? 'plays' : 's';

    return Padding(
      key: Key('ALERTSET-015-${widget.camera.id}-$action'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 10,
                color: isActive ? Colors.greenAccent : Colors.white24,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(_formatActionLabel(action))),
              if (busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text('${pending.round()}$unit'),
            ],
          ),
          Slider(
            key: Key('ALERTSET-016-${widget.camera.id}-$action'),
            value: pending.clamp(min.toDouble(), max.toDouble()),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: (max - min) > 0 ? max - min : null,
            onChanged: busy
                ? null
                : (value) =>
                      setState(() => _pendingDurations[durationKey] = value),
            onChangeEnd: busy ? null : (_) => _commitDuration(action),
          ),
        ],
      ),
    );
  }
}
