/// `FR-NE-117`: one recorded clip, as reported by `GET /nuraeye/recordings`.
class RecordingClip {
  const RecordingClip({
    required this.id,
    required this.start,
    required this.end,
    required this.sizeBytes,
    required this.active,
    this.trigger,
  });

  /// UTC epoch seconds, clip start time. Pass to `GET /nuraeye/recordings/{id}/clip`
  /// ([RecordingsClient.clipUri]) to play or download this clip.
  final int id;

  /// UTC epoch seconds.
  final int start;

  /// UTC epoch seconds.
  final int end;

  /// Not final while [active] is true — the camera is still writing this segment.
  final int sizeBytes;

  /// True if this is the segment the camera is currently recording to.
  final bool active;

  /// Present only when a matching event was found in the camera's recent (last ~100 events,
  /// RAM-only, does not survive a reboot) alert history — see `FR-NE-117`'s own doc for why.
  /// Absence does not mean nothing happened during this clip, just that it's outside that
  /// window. One of the wire event-name strings this app already uses elsewhere (e.g.
  /// `"PersonDetected"`), not a free-form description.
  final String? trigger;
}

/// `FR-NE-117`: `GET /nuraeye/recordings`'s full response.
class RecordingsList {
  const RecordingsList({
    required this.storageAvailable,
    required this.cardPresent,
    required this.truncated,
    required this.clips,
  });

  /// Capability + presence, mirroring `LocalStorageStatus`'s own two-independent-facts split
  /// (`FR-CF-044`) — a genuinely unreachable camera never produces any response at all, so
  /// these are the only two states this call itself can report.
  final bool storageAvailable;
  final bool cardPresent;

  /// True if more clips exist in the requested range than fit in this response — narrow the
  /// `start`/`end` query range rather than expecting pagination (`FR-NE-117` has none).
  final bool truncated;

  final List<RecordingClip> clips;
}
