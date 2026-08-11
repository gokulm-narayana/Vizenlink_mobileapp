/// Kind of event an [Alert] was raised for.
enum AlertType {
  motion,
  person,
  vehicle,
  animal,
  package,
  faceRecognized,
  strangerDetected,
  loitering,
  lineCrossing,
  intrusion,
  tampered,
  cameraMoved,
  viewObscured,
  offline,
  online,
  unauthorizedAccess,
  sdCardRemoved,
  audioAnomaly,
  lowBattery,
  weakSignal,
  storageFull,
  firmwareUpdate,
  other,
}

/// A single alert/notification, e.g. "Motion detected" for a camera.
/// Local-only mock data for now — no backend/protocol wired up yet (see
/// CLAUDE.md).
class Alert {
  const Alert({
    required this.id,
    required this.type,
    required this.message,
    required this.cameraId,
    required this.cameraName,
    required this.timestamp,
    this.isRead = false,
    this.description,
    this.snapshotUrl,
  });

  final String id;
  final AlertType type;
  final String message;
  final String cameraId;
  final String cameraName;
  final DateTime timestamp;
  final bool isRead;

  /// Longer-form detail text shown on the alert detail screen. Falls back
  /// to [message] when unset.
  final String? description;

  /// Snapshot image captured at the time of the event, if available.
  final String? snapshotUrl;

  Alert copyWith({bool? isRead}) {
    return Alert(
      id: id,
      type: type,
      message: message,
      cameraId: cameraId,
      cameraName: cameraName,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      description: description,
      snapshotUrl: snapshotUrl,
    );
  }
}
