/// Kind of recorded event a video clip was captured for. A narrower set
/// than [AlertType] — only trigger types that produce a playable clip
/// belong here (system/status alerts like "offline" or "low battery" do
/// not have a recording, so they live only in [AlertType]).
enum EventType {
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
}

/// A single recorded video clip, e.g. "Motion detected" with an associated
/// playable clip. Local-only mock data for now — no backend/protocol wired
/// up yet (see CLAUDE.md).
class RecordedEvent {
  const RecordedEvent({
    required this.id,
    required this.type,
    required this.cameraId,
    required this.cameraName,
    required this.timestamp,
    required this.duration,
    this.thumbnailUrl,
  });

  final String id;
  final EventType type;
  final String cameraId;
  final String cameraName;
  final DateTime timestamp;
  final Duration duration;

  /// Thumbnail captured at the start of the clip, if available.
  final String? thumbnailUrl;
}
