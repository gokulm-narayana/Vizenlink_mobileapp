import '../camera_result.dart';

enum StreamStatus { active, idle, degraded, notCompiled }

/// The three KVS quality tiers `FR-CF-154` streams, matching the LAN RTSPS `/high`/`/medium`/
/// `/low` naming (`FR-CF-153`) — one AWS Kinesis Video Streams stream per tier, named
/// `<thing_name>-high`/`-medium`/`-low`.
enum StreamQuality { high, medium, low }

extension StreamQualityWire on StreamQuality {
  /// The exact string `params.quality` expects (`StartCloudStreaming`) and the exact KVS stream
  /// name suffix (`resolvePlaybackUri`) — same word, two uses, kept as one extension so they can
  /// never drift apart.
  String get wireValue => switch (this) {
    StreamQuality.high => 'high',
    StreamQuality.medium => 'medium',
    StreamQuality.low => 'low',
  };
}

/// WAN transport for the mobile live-view substream (FR-MOB-031/036): AWS IoT Core MQTT
/// command channel (`StartCloudStreaming`/`StopCloudStreaming`, renamed 2026-08-06 from
/// `StartLiveStream`/`StopLiveStream`, numeric MQTT values unchanged) plus
/// `GetCloudStreamingStatus` (FR-NE-068) and AWS KVS playback-session retrieval.
///
/// **FR-CF-154 (2026-09-14): quality-selective, reference-counted.** Every camera-side KVS
/// stream is a real, independently-billed AWS resource, so the app must start only the quality
/// the user actually picked, and multiple viewers of the same quality share one stream via a
/// camera-side reference count. [startCloudStreaming] now takes the requested [StreamQuality]
/// and returns a per-viewer lease [int] token; [stopCloudStreaming] and
/// [getCloudStreamingStatus] take that token back — passing it to `GetCloudStreamingStatus` *is*
/// the heartbeat that keeps the camera-side lease alive (it expires, and the camera tears the
/// stream down, after 30s with no refresh) — see `bsp_camera_pollKvsViewerLeases()` firmware-side.
abstract interface class WanLiveViewClient {
  /// Returns the viewer's lease token on success — pass it to every subsequent
  /// [stopCloudStreaming]/[getCloudStreamingStatus] call for this session.
  Future<CameraResult<int>> startCloudStreaming(StreamQuality quality);

  Future<CameraResult<void>> stopCloudStreaming(int token);

  /// Also refreshes the camera-side lease for [token] — call at least once every 30s while the
  /// session is meant to stay up, or the camera will drop the reference and, once the last viewer
  /// does, tear the stream down.
  Future<CameraResult<StreamStatus>> getCloudStreamingStatus(int token);

  /// Resolves a playable media URI/session for the KVS-backed stream once [startCloudStreaming] +
  /// [getCloudStreamingStatus] report `active`.
  Future<CameraResult<Uri>> resolvePlaybackUri(StreamQuality quality);
}
