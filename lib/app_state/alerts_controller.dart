import 'package:flutter/foundation.dart';

import '../models/alert.dart';

class AlertsController extends ValueNotifier<List<Alert>> {
  AlertsController() : super(_seedAlerts());

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
  }

  void markRead(String alertId) {
    value = [
      for (final alert in value)
        if (alert.id == alertId) alert.copyWith(isRead: true) else alert,
    ];
  }

  void markUnread(String alertId) {
    value = [
      for (final alert in value)
        if (alert.id == alertId) alert.copyWith(isRead: false) else alert,
    ];
  }

  void deleteAlert(String alertId) {
    value = [
      for (final alert in value)
        if (alert.id != alertId) alert,
    ];
  }

  /// Re-adds a previously deleted alert, e.g. from an "Undo" snackbar
  /// action. No-ops if an alert with the same id is already present.
  void restoreAlert(Alert alert) {
    if (value.any((existing) => existing.id == alert.id)) return;
    value = [...value, alert];
  }

  static String _snapshotFor(String seed) =>
      'https://picsum.photos/seed/$seed/480/270';

  static List<Alert> _seedAlerts() {
    final now = DateTime.now();
    return [
      Alert(
        id: 'alert-1',
        type: AlertType.motion,
        message: 'Motion detected',
        description: 'Motion detected for 8 seconds',
        cameraId: 'cam-1',
        cameraName: 'Front Door Cam',
        timestamp: now.subtract(const Duration(minutes: 12)),
        snapshotUrl: _snapshotFor('alert-motion-1'),
      ),
      Alert(
        id: 'alert-2',
        type: AlertType.person,
        message: 'Person detected',
        description: 'A person was detected entering the frame',
        cameraId: 'cam-2',
        cameraName: 'Backyard Cam',
        timestamp: now.subtract(const Duration(hours: 1)),
        snapshotUrl: _snapshotFor('alert-person-1'),
      ),
      Alert(
        id: 'alert-3',
        type: AlertType.offline,
        message: 'Camera went offline',
        description: 'This camera lost connection to the network',
        cameraId: 'cam-3',
        cameraName: 'Garage Cam',
        timestamp: now.subtract(const Duration(hours: 3)),
        snapshotUrl: _snapshotFor('alert-offline-1'),
      ),
      Alert(
        id: 'alert-4',
        type: AlertType.motion,
        message: 'Motion detected',
        description: 'Motion detected for 15 seconds',
        cameraId: 'cam-1',
        cameraName: 'Front Door Cam',
        timestamp: now.subtract(const Duration(hours: 5)),
        snapshotUrl: _snapshotFor('alert-motion-2'),
      ),
      Alert(
        id: 'alert-5',
        type: AlertType.vehicle,
        message: 'Vehicle detected',
        description: 'A vehicle was detected in the driveway',
        cameraId: 'cam-4',
        cameraName: 'Living Room Cam',
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
        snapshotUrl: _snapshotFor('alert-vehicle-1'),
      ),
      Alert(
        id: 'alert-6',
        type: AlertType.animal,
        message: 'Animal detected',
        description: 'An animal was detected in the yard',
        cameraId: 'cam-2',
        cameraName: 'Backyard Cam',
        timestamp: now.subtract(const Duration(hours: 6)),
        snapshotUrl: _snapshotFor('alert-animal-1'),
      ),
      Alert(
        id: 'alert-7',
        type: AlertType.package,
        message: 'Package detected',
        description: 'A package was left at the front door',
        cameraId: 'cam-1',
        cameraName: 'Front Door Cam',
        timestamp: now.subtract(const Duration(hours: 7)),
        snapshotUrl: _snapshotFor('alert-package-1'),
      ),
      Alert(
        id: 'alert-8',
        type: AlertType.faceRecognized,
        message: 'Familiar face recognized',
        description: 'A known face was recognized at the front door',
        cameraId: 'cam-1',
        cameraName: 'Front Door Cam',
        timestamp: now.subtract(const Duration(hours: 8)),
        isRead: true,
        snapshotUrl: _snapshotFor('alert-face-1'),
      ),
      Alert(
        id: 'alert-9',
        type: AlertType.strangerDetected,
        message: 'Unrecognized person detected',
        description: 'A person not in your known faces list was detected',
        cameraId: 'cam-2',
        cameraName: 'Backyard Cam',
        timestamp: now.subtract(const Duration(hours: 9)),
        snapshotUrl: _snapshotFor('alert-stranger-1'),
      ),
      Alert(
        id: 'alert-10',
        type: AlertType.loitering,
        message: 'Loitering detected',
        description: 'A person lingered in view for over 2 minutes',
        cameraId: 'cam-3',
        cameraName: 'Garage Cam',
        timestamp: now.subtract(const Duration(hours: 10)),
        snapshotUrl: _snapshotFor('alert-loitering-1'),
      ),
      Alert(
        id: 'alert-11',
        type: AlertType.lineCrossing,
        message: 'Line crossing detected',
        description: 'Motion crossed a configured boundary line',
        cameraId: 'cam-4',
        cameraName: 'Living Room Cam',
        timestamp: now.subtract(const Duration(hours: 11)),
        snapshotUrl: _snapshotFor('alert-linecrossing-1'),
      ),
      Alert(
        id: 'alert-12',
        type: AlertType.intrusion,
        message: 'Intrusion detected',
        description: 'Motion detected inside a restricted zone',
        cameraId: 'cam-3',
        cameraName: 'Garage Cam',
        timestamp: now.subtract(const Duration(hours: 12)),
        snapshotUrl: _snapshotFor('alert-intrusion-1'),
      ),
      Alert(
        id: 'alert-13',
        type: AlertType.tampered,
        message: 'Camera tampered',
        description: 'The camera lens appears to be covered or obstructed',
        cameraId: 'cam-2',
        cameraName: 'Backyard Cam',
        timestamp: now.subtract(const Duration(hours: 13)),
        snapshotUrl: _snapshotFor('alert-tampered-1'),
      ),
      Alert(
        id: 'alert-14',
        type: AlertType.cameraMoved,
        message: 'Camera moved',
        description: 'The camera angle changed unexpectedly',
        cameraId: 'cam-1',
        cameraName: 'Front Door Cam',
        timestamp: now.subtract(const Duration(hours: 14)),
        snapshotUrl: _snapshotFor('alert-cameramoved-1'),
      ),
      Alert(
        id: 'alert-15',
        type: AlertType.viewObscured,
        message: 'View obscured',
        description: 'The camera view is blurry or partially blocked',
        cameraId: 'cam-4',
        cameraName: 'Living Room Cam',
        timestamp: now.subtract(const Duration(hours: 15)),
        snapshotUrl: _snapshotFor('alert-obscured-1'),
      ),
      Alert(
        id: 'alert-16',
        type: AlertType.online,
        message: 'Camera back online',
        description: 'This camera reconnected to the network',
        cameraId: 'cam-3',
        cameraName: 'Garage Cam',
        timestamp: now.subtract(const Duration(hours: 16)),
        isRead: true,
        snapshotUrl: _snapshotFor('alert-online-1'),
      ),
      Alert(
        id: 'alert-17',
        type: AlertType.unauthorizedAccess,
        message: 'Unauthorized access attempt',
        description: 'A failed login attempt was made on this camera',
        cameraId: 'cam-2',
        cameraName: 'Backyard Cam',
        timestamp: now.subtract(const Duration(hours: 17)),
        snapshotUrl: _snapshotFor('alert-unauthorized-1'),
      ),
      Alert(
        id: 'alert-18',
        type: AlertType.sdCardRemoved,
        message: 'SD card removed',
        description: 'The local storage card was removed from this camera',
        cameraId: 'cam-1',
        cameraName: 'Front Door Cam',
        timestamp: now.subtract(const Duration(hours: 18)),
        snapshotUrl: _snapshotFor('alert-sdcard-1'),
      ),
      Alert(
        id: 'alert-19',
        type: AlertType.audioAnomaly,
        message: 'Unusual sound detected',
        description: 'A loud or unexpected noise was picked up',
        cameraId: 'cam-4',
        cameraName: 'Living Room Cam',
        timestamp: now.subtract(const Duration(hours: 19)),
        snapshotUrl: _snapshotFor('alert-audio-1'),
      ),
      Alert(
        id: 'alert-20',
        type: AlertType.lowBattery,
        message: 'Low battery',
        description: 'This camera\'s battery is running low',
        cameraId: 'cam-3',
        cameraName: 'Garage Cam',
        timestamp: now.subtract(const Duration(hours: 20)),
        snapshotUrl: _snapshotFor('alert-battery-1'),
      ),
      Alert(
        id: 'alert-21',
        type: AlertType.weakSignal,
        message: 'Weak signal',
        description: 'This camera has a weak Wi-Fi connection',
        cameraId: 'cam-2',
        cameraName: 'Backyard Cam',
        timestamp: now.subtract(const Duration(hours: 21)),
        snapshotUrl: _snapshotFor('alert-signal-1'),
      ),
      Alert(
        id: 'alert-22',
        type: AlertType.storageFull,
        message: 'Storage almost full',
        description: 'Recording storage is nearly full for this camera',
        cameraId: 'cam-1',
        cameraName: 'Front Door Cam',
        timestamp: now.subtract(const Duration(days: 2)),
        snapshotUrl: _snapshotFor('alert-storage-1'),
      ),
      Alert(
        id: 'alert-23',
        type: AlertType.firmwareUpdate,
        message: 'Firmware update available',
        description: 'A new firmware version is available for this camera',
        cameraId: 'cam-4',
        cameraName: 'Living Room Cam',
        timestamp: now.subtract(const Duration(days: 2, hours: 4)),
        isRead: true,
        snapshotUrl: _snapshotFor('alert-firmware-1'),
      ),
    ];
  }
}
