import 'dart:async';
import 'dart:convert';

import 'package:alerts_api/alerts_api.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alert.dart';
import 'homes_controller.dart';

const _alertsPrefsKey = 'alerts_history_v1';

/// Cap on persisted/in-memory alert history — `alerts_api` has no historical
/// endpoint of its own (see `packages/alerts_api/API_REFERENCE.md`), so this
/// controller is the only thing keeping anything past the current session;
/// an unbounded list would grow forever for a camera left running for
/// months.
const _maxStoredAlerts = 200;

/// `event` strings `alerts_api`'s `CameraAlertEvent` reports that map onto an
/// existing [AlertType] with a real icon/filter bucket in the UI — anything
/// else falls back to [AlertType.other] with a best-effort human-readable
/// label derived from the raw event string (see `_labelForEvent`).
const _eventTypeMap = {'PersonDetected': AlertType.person};

/// Turns `"VideoModeChanged"` into `"Video mode changed"` — used for any
/// `CameraAlertEvent.event` this controller doesn't have a dedicated
/// [AlertType]/label pair for, so a newly-added camera event type still
/// shows something readable instead of a raw wire string.
String _labelForEvent(String event) {
  final withSpaces = event.replaceAllMapped(
    RegExp('(?<=[a-z0-9])(?=[A-Z])'),
    (m) => ' ',
  );
  final lower = withSpaces.toLowerCase();
  return lower[0].toUpperCase() + lower.substring(1);
}

/// Live camera alerts, backed by `alerts_api`'s `CameraAlertsHub.events`
/// stream — see that package's `API_REFERENCE.md`. `alerts_api` only
/// delivers alerts going forward, live, while this listener is running; it
/// has no historical-list endpoint, so persistence here (via
/// [SharedPreferences]) is what keeps history across an app restart, not a
/// backend. `CameraAlertsHub.ensureRunning`/`.stop` are driven by auth state
/// in `main.dart`, not by this controller — this class only ever reads its
/// `events` stream.
class AlertsController extends ValueNotifier<List<Alert>> {
  AlertsController({required this.homesController}) : super(const []) {
    _loadPersisted();
    _subscription = CameraAlertsHub.instance.events.listen(_onAlertEvent);
    // Diagnostic logging (same [Talk]/[LiveView] convention as
    // live_view_controller.dart) — alerts_api's MQTT connection runs in a
    // background isolate with no logging of its own, so this is the only
    // visibility into whether it ever actually connects.
    _statusSubscription = CameraAlertsHub.instance.statusUpdates.listen((
      status,
    ) {
      // ignore: avoid_print
      print(
        '[Alerts] status: connected=${status.connectedThingNames} '
        'watched=${status.watchedThingNames}',
      );
    });
  }

  final HomesController homesController;
  StreamSubscription<CameraAlertEvent>? _subscription;
  StreamSubscription<AlertsStatus>? _statusSubscription;

  final Set<String> _snoozedCameraIds = {};

  int get unreadCount => value.where((alert) => !alert.isRead).length;

  int unreadCountForCamera(String cameraId) => value
      .where((alert) => !alert.isRead && alert.cameraId == cameraId)
      .length;

  bool isCameraSnoozed(String cameraId) => _snoozedCameraIds.contains(cameraId);

  void toggleCameraSnooze(String cameraId) {
    if (!_snoozedCameraIds.add(cameraId)) {
      _snoozedCameraIds.remove(cameraId);
    }
    notifyListeners();
  }

  void markAllRead() {
    value = [for (final alert in value) alert.copyWith(isRead: true)];
    unawaited(_persist());
  }

  void markRead(String alertId) {
    value = [
      for (final alert in value)
        if (alert.id == alertId) alert.copyWith(isRead: true) else alert,
    ];
    unawaited(_persist());
  }

  void markUnread(String alertId) {
    value = [
      for (final alert in value)
        if (alert.id == alertId) alert.copyWith(isRead: false) else alert,
    ];
    unawaited(_persist());
  }

  void deleteAlert(String alertId) {
    value = [
      for (final alert in value)
        if (alert.id != alertId) alert,
    ];
    unawaited(_persist());
  }

  /// Re-adds a previously deleted alert, e.g. from an "Undo" snackbar
  /// action. No-ops if an alert with the same id is already present.
  void restoreAlert(Alert alert) {
    if (value.any((existing) => existing.id == alert.id)) return;
    value = [...value, alert];
    unawaited(_persist());
  }

  /// Looked up fresh from [homesController] each time, same as every
  /// camera-settings screen's own `_camera` getter — a camera's saved
  /// connection can change between alerts.
  ({String id, String name})? _cameraForThingName(String thingName) {
    for (final home in homesController.value.homes) {
      for (final camera in home.cameras) {
        if (camera.thingName == thingName) {
          return (id: camera.id, name: camera.name);
        }
      }
    }
    return null;
  }

  void _onAlertEvent(CameraAlertEvent event) {
    // ignore: avoid_print
    print(
      '[Alerts] received: thingName=${event.thingName} event=${event.event} '
      'body=${event.body}',
    );
    final camera = _cameraForThingName(event.thingName);
    final type = _eventTypeMap[event.event] ?? AlertType.other;
    final alert = Alert(
      id: '${event.thingName}-${event.event}-${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      message: _labelForEvent(event.event),
      cameraId: camera?.id ?? event.thingName,
      cameraName: camera?.name ?? event.thingName,
      timestamp: DateTime.now(),
    );
    value = [alert, ...value].take(_maxStoredAlerts).toList();
    unawaited(_persist());
  }

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_alertsPrefsKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      value = [
        for (final entry in decoded)
          Alert.fromJson(entry as Map<String, dynamic>),
      ];
    } catch (_) {
      // Corrupt/incompatible persisted data — start fresh rather than crash.
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _alertsPrefsKey,
      jsonEncode([for (final alert in value) alert.toJson()]),
    );
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_statusSubscription?.cancel());
    super.dispose();
  }
}
