import '../camera_result.dart';

enum StreamStatus { active, idle, degraded, notCompiled }

/// WAN transport for the mobile live-view substream (FR-MOB-031/036): AWS IoT Core MQTT
/// command channel (`StartCloudStreaming`/`StopCloudStreaming`, fire-and-forget per the ICD's
/// §7.3 note that these predate FR-NE-053's request/response pattern — renamed 2026-08-06 from
/// `StartLiveStream`/`StopLiveStream`, numeric MQTT values unchanged) plus
/// `GetCloudStreamingStatus` (FR-NE-068, request/response, renamed 2026-08-06 from
/// `GetStreamStatus`) and AWS KVS playback-session retrieval.
///
/// **Interface only in this work item (NF1)** — DESIGN.md §7 flags that Flutter has no mature
/// pure-Dart AWS KVS consumer package as of writing, so the concrete implementation (AWS IoT
/// SigV4/WebSocket signing + a KVS consumer, possibly via a small platform-channel shim) is
/// deferred to a follow-on NF, evaluated against whatever packages exist at that time. Defining
/// the interface now — rather than skipping WAN entirely — lets [LiveViewController] (see
/// `live_view_controller.dart`) accept it as an optional, swappable dependency: adding a real
/// implementation later is additive (DESIGN.md §3's evolution rule), no existing method on
/// [LiveViewController] changes shape when WAN lands.
abstract interface class WanLiveViewClient {
  Future<CameraResult<void>> startCloudStreaming();
  Future<CameraResult<void>> stopCloudStreaming();
  Future<CameraResult<StreamStatus>> getCloudStreamingStatus();

  /// Resolves a playable media URI/session for the KVS-backed stream once
  /// [startCloudStreaming] + [getCloudStreamingStatus] report `active`.
  Future<CameraResult<Uri>> resolvePlaybackUri();
}
