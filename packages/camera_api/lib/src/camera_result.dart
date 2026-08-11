/// Typed result of every `camera_api` call — the API-stability contract (DESIGN.md §3) commits
/// to returning structured values, never a formatted string or a UI-specific exception, so a
/// human UI and a future in-app agent can consume the exact same return value.
sealed class CameraResult<T> {
  const CameraResult();
}

class CameraSuccess<T> extends CameraResult<T> {
  const CameraSuccess(this.value);
  final T value;
}

/// A request the camera actively rejected or failed to service (HTTP error, SOAP Fault,
/// MQTT error response) — distinct from [CameraTimeout], since a rejection is informative
/// (e.g. "Smart night vision not wired yet") while a timeout only means "no answer".
class CameraFailure<T> extends CameraResult<T> {
  const CameraFailure(this.reason);
  final String reason;
}

/// No response arrived within the call's bounded timeout. Kept distinct from [CameraFailure]
/// per FR-NE-053's WAN contract: "no response within the bounded timeout is treated as
/// failed/undelivered" — callers (UI or agent) may want to retry a timeout, but should never
/// retry an explicit rejection the same way.
class CameraTimeout<T> extends CameraResult<T> {
  const CameraTimeout();
}
