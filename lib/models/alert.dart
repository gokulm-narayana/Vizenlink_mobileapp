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

/// A single alert/notification, e.g. "Motion detected" for a camera. Backed
/// by `alerts_api`'s live `CameraAlertsHub.events` stream (see
/// `AlertsController`) and persisted locally via [toJson]/[fromJson] so
/// history survives an app restart — `alerts_api` itself only delivers
/// alerts live, going forward, with no historical-list endpoint.
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'message': message,
    'cameraId': cameraId,
    'cameraName': cameraName,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    if (description != null) 'description': description,
    if (snapshotUrl != null) 'snapshotUrl': snapshotUrl,
  };

  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
    id: json['id'] as String,
    type: AlertType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => AlertType.other,
    ),
    message: json['message'] as String,
    cameraId: json['cameraId'] as String,
    cameraName: json['cameraName'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    isRead: json['isRead'] as bool? ?? false,
    description: json['description'] as String?,
    snapshotUrl: json['snapshotUrl'] as String?,
  );
}
