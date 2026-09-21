// GENERATED CODE — DO NOT HAND-EDIT.
//
// Produced by tools/generate_dart_rest_client.py from design/Camera-REST-API.openapi.yaml.
// Fix the generator and re-run `python3 tools/generate_dart_rest_client.py` to regenerate.

/// Typed result of every generated `lan/nuraeye/rest_*.dart` call — kept as its own type,
/// separate from `camera_api`'s own `CameraResult<T>`, since [RestFailure] carries an HTTP
/// status code `CameraFailure` has no equivalent field for, and every generated client only
/// ever needs to reason about this REST wire shape specifically. Living in the same package as
/// `CameraResult` (merged 2026-08-11, previously a separate `camera_api_rest` package) doesn't
/// change that — the two types solve different problems, not the same one twice.
sealed class RestResult<T> {
  const RestResult();

  RestResult<R> map<R>(R Function(T value) transform) {
    final self = this;
    if (self is RestSuccess<T>) return RestSuccess(transform(self.value));
    if (self is RestFailure<T>) return RestFailure(self.reason, statusCode: self.statusCode);
    return const RestTimeout();
  }
}

class RestSuccess<T> extends RestResult<T> {
  const RestSuccess(this.value);
  final T value;

  // Real gap found 2026-08-13 (camera_result.dart's CameraSuccess/Failure/Timeout had the same
  // one): with no toString() override, every '...: $result'-style debug log silently printed
  // "Instance of 'RestFailure<T>'" instead of the actual reason.
  @override
  String toString() => 'RestSuccess<$T>($value)';
}

/// A request the camera actively rejected (non-2xx HTTP status with a decodable ErrorResponse
/// body) — distinct from [RestTimeout], since a rejection carries the camera's own error_msg.
class RestFailure<T> extends RestResult<T> {
  const RestFailure(this.reason, {this.statusCode});
  final String reason;
  final int? statusCode;

  @override
  String toString() => 'RestFailure<$T>($reason, statusCode: $statusCode)';
}

/// No response arrived within the call's bounded timeout.
class RestTimeout<T> extends RestResult<T> {
  const RestTimeout();

  @override
  String toString() => 'RestTimeout<$T>()';
}
