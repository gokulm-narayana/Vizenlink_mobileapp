import 'package:camera_api/camera_api.dart';

/// Fires off every settings screen's `Get*Options`-style capability call for
/// [connection] in parallel, right after a camera is added, so their
/// process-lifetime, host-keyed static caches (`OnvifImagingClient`,
/// `OsdClient`, `OnvifVideoEncoderClient`, `MaskClient`,
/// `NetworkInfoClient` — see `.claude/rules/mobile-app-screen-conventions.md`'s
/// caching convention) are already warm by the time the user opens Imaging,
/// OSD, Video Encoder, Privacy/Intrusion/Line-Crossing/Person-Detection
/// (mask-backed), or Camera Info's timezone picker, instead of paying a cold
/// LAN round trip on each screen's first visit.
///
/// Also warms `AudioCapabilityClient`/`SpeakerVolumeClient` for
/// `AudioScreen` — those two only cache the resolved ONVIF service endpoint
/// (`_endpointCacheByHost`), not the capability/volume value itself (the
/// latter is genuinely live/mutable, so it's always re-fetched live on
/// screen open per the caching convention's "never cache live state" rule)
/// — but resolving that endpoint is itself a real LAN round trip, so warming
/// it here still saves one on Audio's first visit.
///
/// Best-effort and silent: a call that fails here simply leaves that
/// client's cache empty, and the owning screen falls back to its own normal
/// live fetch on first visit exactly as it did before this existed. Meant to
/// be called `unawaited()`, mirroring `syncCameraFromDevice`'s fire-and-forget
/// use in the add-camera flow — this never blocks add or reports failures of
/// its own.
///
/// **Run one call at a time, not concurrently** — an earlier version fired
/// all of these via `Future.wait`, which floods the camera's embedded HTTP
/// server and can turn a single screen open into a many-seconds-to-tens-of-
/// seconds stall (the sibling `nuraeye-rt` app hit and documented this exact
/// failure mode before rewriting its own equivalent prefetch to be
/// sequential).
Future<void> prefetchAndCache(CameraConnection connection) async {
  final imaging = OnvifImagingClient(connection);
  final osd = OsdClient(connection);
  final videoEncoder = OnvifVideoEncoderClient(connection);
  final mask = MaskClient(connection);
  final networkInfo = NetworkInfoClient(connection);
  final audioCapability = AudioCapabilityClient(connection);
  final speakerVolume = SpeakerVolumeClient(connection);
  try {
    await imaging.getImagingOptions();
    await osd.getOsdOptions();
    await videoEncoder.getVideoEncoderSettingsOptions();
    await mask.getMaskOptions();
    await networkInfo.getSupportedTimezones();
    await audioCapability.getAudioCapability();
    await speakerVolume.getSpeakerVolume();
  } finally {
    imaging.close();
    osd.close();
    videoEncoder.close();
    mask.close();
    networkInfo.close();
    audioCapability.close();
    speakerVolume.close();
  }
}
