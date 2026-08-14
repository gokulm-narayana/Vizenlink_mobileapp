import 'dart:ui';

import 'package:camera_api/camera_api.dart';

import 'zone.dart';

/// How a camera is currently configured to record locally.
enum RecordingStatus { continuous, scheduled, eventTriggered, off }

/// Day of week for a [RecordingScheduleWindow], Monday-first.
enum RecordingScheduleDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

/// A single day/time window during which Scheduled recording is active.
/// [startMinutes]/[endMinutes] are minutes since midnight (0-1439);
/// [endMinutes] must be greater than [startMinutes] (no overnight-spanning
/// windows — model two windows instead).
class RecordingScheduleWindow {
  const RecordingScheduleWindow({
    required this.day,
    required this.startMinutes,
    required this.endMinutes,
  });

  final RecordingScheduleDay day;
  final int startMinutes;
  final int endMinutes;
}

/// A critical local-storage condition reported by the camera. `none` means
/// storage is healthy.
enum StorageFailure { none, full, cardRemoved, readOnly, unavailable }

extension StorageFailureMessage on StorageFailure {
  /// Plain-language description of this failure, or null for [StorageFailure.none].
  String? get message => switch (this) {
    StorageFailure.none => null,
    StorageFailure.full => 'SD card full — recording has stopped',
    StorageFailure.cardRemoved => 'SD card removed — no local recording',
    StorageFailure.readOnly => 'SD card is read-only — recording has stopped',
    StorageFailure.unavailable => 'SD card unavailable — recording has stopped',
  };
}

/// Overall connectivity + health status shown on live-view/dashboard status
/// badges — see [Camera.liveStatus].
enum CameraLiveStatus { online, needsAttention, offline }

/// Fixed preview-corner position for a non-draggable OSD tag (Bitrate,
/// Signal Strength).
enum OsdCorner { topLeft, topRight, bottomLeft, bottomRight }

/// Video Mode screen — day/night switching behavior.
enum CameraVideoMode { day, auto, night }

/// Night Mode screen — how the camera renders low-light footage.
enum CameraNightMode { infrared, smart, fullColor }

/// Privacy Mode screen — whether/how the feed is masked.
enum CameraPrivacyMode { off, full, zone }

/// Imaging screen — mirror/flip orientation.
enum CameraMirrorFlip { off, mirror, flip, both }

/// Imaging screen — auto vs. manual control, shared by white balance and
/// exposure.
enum CameraAutoManual { auto, manual }

/// Video Encoder screen — output resolution.
enum CameraResolution { p1080, p720, p480 }

/// Video Encoder screen — codec.
enum CameraEncoderType { h264, h265 }

/// Video Encoder screen — encoder profile.
enum CameraEncoderProfile { baseline, main, high }

/// Video Encoder screen — constant vs. variable bitrate.
enum CameraBitrateMode { cbr, vbr }

/// Line Crossing screen — which direction(s) count as a crossing.
enum CameraCrossingDirection { both, aToB, bToA }

class Camera {
  const Camera({
    required this.id,
    required this.name,
    required this.isOnline,
    this.room,
    this.isFavorite = false,
    this.isPinned = false,
    this.thumbnailUrl,
    this.lastSeen,
    this.timezone = 'UTC',
    this.recordingStatus = RecordingStatus.off,
    this.recordingScheduleWindows = const [],
    this.wifiNetwork = '—',
    this.ipAddress = '—',
    this.signalStrength = 0,
    this.networkSpeedKbps = 0,
    this.macAddress = '—',
    this.manufacturer = '—',
    this.model = '—',
    this.firmwareVersion = '—',
    this.serialNumber = '—',
    this.hardwareId = '—',
    this.bitrateOsdEnabled = false,
    this.bitrateOsdPosition = OsdCorner.bottomRight,
    this.signalStrengthOsdEnabled = false,
    this.signalStrengthOsdPosition = OsdCorner.topRight,
    this.liveTagOsdEnabled = true,
    this.videoMode = CameraVideoMode.auto,
    this.nightMode = CameraNightMode.smart,
    this.nightVisionColorCapable,
    this.nightVisionSmartCapable,
    this.privacyMode = CameraPrivacyMode.off,
    this.privacyZones = const [],
    this.mirrorFlip = CameraMirrorFlip.off,
    this.brightness = 50,
    this.contrast = 50,
    this.saturation = 50,
    this.sharpness = 50,
    this.wdrEnabled = false,
    this.wdrLevel = 50,
    this.whiteBalance = CameraAutoManual.auto,
    this.exposure = CameraAutoManual.auto,
    this.exposureTime = 10000,
    this.exposureGain = 0,
    this.videoResolution = CameraResolution.p1080,
    this.encoderType = CameraEncoderType.h264,
    this.encoderProfile = CameraEncoderProfile.main,
    this.frameRate = 15,
    this.govLength = 30,
    this.encoderQuality = 3,
    this.bitrateMode = CameraBitrateMode.cbr,
    this.bitrateKbps = 2048,
    this.motionDetectionEnabled = false,
    this.motionSensitivity = 50,
    this.intrusionDetectionEnabled = false,
    this.intrusionSensitivity = 50,
    this.intrusionZones = const [],
    this.lineCrossingEnabled = false,
    this.lineCrossingSensitivity = 50,
    this.lineCrossingStart = const Offset(0.2, 0.5),
    this.lineCrossingEnd = const Offset(0.8, 0.5),
    this.lineCrossingDirection = CameraCrossingDirection.both,
    this.personDetectionEnabled = false,
    this.personDetectionConfidence = 50,
    this.personDetectionZones = const [],
    this.vehicleDetectionEnabled = false,
    this.vehicleDetectionConfidence = 50,
    this.speakerVolume = 50,
    this.micGain = 50,
    this.audioRecordingEnabled = false,
    this.sdStorageEnabled = true,
    this.sdCardPresent = true,
    this.sdCardCapacityGb = 64,
    this.sdCardUsedGb = 20,
    this.sdCardHealthPercent = 95,
    this.sdCardEnduranceRated = true,
    this.retentionDays = 14,
    this.storageFailure = StorageFailure.none,
    this.host,
    this.username,
    this.password,
    this.thingName,
    this.wanLiveViewCapable,
  });

  final String id;
  final String name;
  final bool isOnline;
  final String? room;
  final bool isFavorite;

  /// Pinned cameras are sorted first on the Dashboard's "All" tab. Pinning
  /// is only offered on that tab — it does not affect Favourites or room
  /// tabs.
  final bool isPinned;

  /// Snapshot/thumbnail image for this camera. Currently points at
  /// placeholder images (picsum.photos) — swap for a real camera snapshot
  /// endpoint once a backend/protocol is wired up.
  final String? thumbnailUrl;

  /// When this camera was last seen online. Only meaningful while
  /// [isOnline] is false — shown in the offline overlay on the dashboard.
  final DateTime? lastSeen;

  /// The following device-info fields are stub-seeded per camera (see
  /// HomesController) until a real CCTV protocol/backend is wired up (see
  /// CLAUDE.md) — they are not hardcoded on the display screen itself, so
  /// swapping in a real device query later only touches the data source.
  final String timezone;
  final RecordingStatus recordingStatus;

  /// Only meaningful while [recordingStatus] is [RecordingStatus.scheduled].
  final List<RecordingScheduleWindow> recordingScheduleWindows;
  final String wifiNetwork;
  final String ipAddress;

  /// Wi-Fi signal strength as a 0–4 bar rating.
  final int signalStrength;

  /// Current network throughput in kbps — shown auto-scaled to KB/s or
  /// MB/s (see `formatBitrate` in `lib/widgets/live_status_badges.dart`).
  final double networkSpeedKbps;
  final String macAddress;
  final String manufacturer;
  final String model;
  final String firmwareVersion;
  final String serialNumber;
  final String hardwareId;

  /// The following are composited by the mobile app on top of the stream
  /// (not sent to or rendered by the camera) — edited from the Tags
  /// settings screen. Bitrate and Signal Strength each have their own
  /// enable toggle and fixed preview-corner position; Live Tag is always
  /// pinned to the top-left corner.
  final bool bitrateOsdEnabled;
  final OsdCorner bitrateOsdPosition;
  final bool signalStrengthOsdEnabled;
  final OsdCorner signalStrengthOsdPosition;
  final bool liveTagOsdEnabled;

  /// The following settings are persisted here so that once a real
  /// CCTV protocol/stream is wired up (see CLAUDE.md), applying them is
  /// just a matter of reading these fields — no further plumbing needed.
  /// They currently have no visible effect on the dummy preview video.
  final CameraVideoMode videoMode;
  final CameraNightMode nightMode;

  /// Hardware/firmware capability flags from the camera's own
  /// `GetNightVisionType` response — null means "camera not verified yet"
  /// (no connection, or the check hasn't returned), same fallback reasoning
  /// as the screen-local flags this mirrors in `night_mode_screen.dart`.
  final bool? nightVisionColorCapable;
  final bool? nightVisionSmartCapable;
  final CameraPrivacyMode privacyMode;
  final List<DrawableZone> privacyZones;
  final CameraMirrorFlip mirrorFlip;
  final double brightness;
  final double contrast;
  final double saturation;
  final double sharpness;
  final bool wdrEnabled;
  final double wdrLevel;
  final CameraAutoManual whiteBalance;
  final CameraAutoManual exposure;

  /// ONVIF `ExposureTime`/`Gain` — only meaningful when [exposure] is
  /// [CameraAutoManual.manual]; ignored by the camera in Auto mode. Units
  /// match `ImagingSettings.exposureTime`/`exposureGain`'s wire values
  /// (microseconds / dB), not independently re-derived here.
  final double exposureTime;
  final double exposureGain;
  final CameraResolution videoResolution;
  final CameraEncoderType encoderType;
  final CameraEncoderProfile encoderProfile;
  final double frameRate;
  final double govLength;
  final double encoderQuality;
  final CameraBitrateMode bitrateMode;
  final double bitrateKbps;
  final bool motionDetectionEnabled;
  final double motionSensitivity;
  final bool intrusionDetectionEnabled;
  final double intrusionSensitivity;
  final List<DrawableZone> intrusionZones;
  final bool lineCrossingEnabled;
  final double lineCrossingSensitivity;
  final Offset lineCrossingStart;
  final Offset lineCrossingEnd;
  final CameraCrossingDirection lineCrossingDirection;
  final bool personDetectionEnabled;
  final double personDetectionConfidence;
  final List<PolygonZone> personDetectionZones;
  final bool vehicleDetectionEnabled;
  final double vehicleDetectionConfidence;
  final double speakerVolume;
  final double micGain;

  /// Whether this camera's recordings include an audio track — independent
  /// of [speakerVolume]/[micGain], which affect two-way talk and warning
  /// playback, not what gets recorded.
  final bool audioRecordingEnabled;

  /// Independent of whether a card is physically present ([sdCardPresent]).
  final bool sdStorageEnabled;
  final bool sdCardPresent;
  final double sdCardCapacityGb;
  final double sdCardUsedGb;

  /// Wear-level health, 0-100 (100 = new/perfect condition).
  final double sdCardHealthPercent;

  /// Whether the inserted card is rated for continuous surveillance writes,
  /// as opposed to a general-purpose consumer card.
  final bool sdCardEnduranceRated;

  /// How long locally recorded footage is kept before being overwritten.
  final int retentionDays;

  /// A critical storage condition currently reported by the camera, or
  /// [StorageFailure.none] if storage is healthy.
  final StorageFailure storageFailure;

  /// The following are the camera's LAN/WAN connection credentials —
  /// captured once at onboarding (`ScannedDevicesScreen`'s setup form) and
  /// persisted so screens can open a `camera_api` `CameraConnection` without
  /// re-prompting for credentials. Null means this camera predates
  /// onboarding-time credential capture, or a scan-only stub camera whose
  /// setup flow hasn't actually run yet.
  final String? host;
  final String? username;
  final String? password;

  /// AWS IoT thing name — populated once `OnvifDeviceClient.getSerialNumber`
  /// resolves it at onboarding (see `CameraConnection.thingName`'s doc).
  final String? thingName;

  /// Whether this camera supports WAN live view, per `CapabilitiesClient`
  /// (queried once at onboarding). Null means unknown, not unsupported — see
  /// `CameraConnection.wanLiveViewCapable`'s doc for why that distinction
  /// matters to live-view fallback logic.
  final bool? wanLiveViewCapable;

  /// Builds a [CameraConnection] from this camera's saved credentials, or
  /// null if it doesn't have any yet (see [host]'s doc).
  CameraConnection? get connection {
    if (host == null || username == null || password == null) return null;
    return CameraConnection(
      host: host!,
      username: username!,
      password: password!,
      thingName: thingName,
      wanLiveViewCapable: wanLiveViewCapable,
      macAddress: macAddress == '—' ? null : macAddress,
    );
  }

  /// Free local storage in GB, derived from [sdCardCapacityGb] minus
  /// [sdCardUsedGb]. Zero (not negative) if the card is disabled/absent.
  double get sdCardFreeGb {
    if (!sdStorageEnabled || !sdCardPresent) return 0;
    final free = sdCardCapacityGb - sdCardUsedGb;
    return free < 0 ? 0 : free;
  }

  /// Approximate remaining local recording time at the camera's current
  /// encoder bitrate ([bitrateKbps]), based on [sdCardFreeGb]. Used by both
  /// the Storage and Recording screens so the estimate stays consistent
  /// between them.
  Duration get estimatedRecordingTimeRemaining {
    if (sdCardFreeGb <= 0 || bitrateKbps <= 0) return Duration.zero;
    final freeBits = sdCardFreeGb * 1e9 * 8;
    final seconds = freeBits / (bitrateKbps * 1000);
    return Duration(seconds: seconds.round());
  }

  /// Plain-language messages for every currently-open health condition on
  /// this camera. Empty means healthy. Drives [needsAttention]/[liveStatus]
  /// and the Health section on Camera Info.
  List<String> get healthConditionMessages {
    final messages = <String>[];
    final storageMessage = storageFailure.message;
    if (storageMessage != null) messages.add(storageMessage);
    if (sdCardPresent && sdCardHealthPercent < 50) {
      messages.add('SD card wearing out — consider replacing soon');
    }
    return messages;
  }

  bool get needsAttention => healthConditionMessages.isNotEmpty;

  /// Overall status for live-view/dashboard badges: offline takes priority
  /// over health conditions, which take priority over plain "online".
  CameraLiveStatus get liveStatus {
    if (!isOnline) return CameraLiveStatus.offline;
    return needsAttention
        ? CameraLiveStatus.needsAttention
        : CameraLiveStatus.online;
  }

  /// [room] uses an explicit presence flag ([setRoom]) rather than the usual
  /// `x ?? this.x` pattern so callers can clear the room (set it to null),
  /// e.g. when the room a camera belonged to is deleted.
  Camera copyWith({
    String? name,
    bool? isOnline,
    bool? isFavorite,
    bool? isPinned,
    String? room,
    bool setRoom = false,
    String? thumbnailUrl,
    DateTime? lastSeen,
    String? timezone,
    RecordingStatus? recordingStatus,
    List<RecordingScheduleWindow>? recordingScheduleWindows,
    String? wifiNetwork,
    String? ipAddress,
    int? signalStrength,
    double? networkSpeedKbps,
    String? macAddress,
    String? manufacturer,
    String? model,
    String? firmwareVersion,
    String? serialNumber,
    String? hardwareId,
    String? host,
    String? username,
    String? password,
    String? thingName,
    bool? wanLiveViewCapable,
    bool? bitrateOsdEnabled,
    OsdCorner? bitrateOsdPosition,
    bool? signalStrengthOsdEnabled,
    OsdCorner? signalStrengthOsdPosition,
    bool? liveTagOsdEnabled,
    CameraVideoMode? videoMode,
    CameraNightMode? nightMode,
    bool? nightVisionColorCapable,
    bool? nightVisionSmartCapable,
    CameraPrivacyMode? privacyMode,
    List<DrawableZone>? privacyZones,
    CameraMirrorFlip? mirrorFlip,
    double? brightness,
    double? contrast,
    double? saturation,
    double? sharpness,
    bool? wdrEnabled,
    double? wdrLevel,
    CameraAutoManual? whiteBalance,
    CameraAutoManual? exposure,
    double? exposureTime,
    double? exposureGain,
    CameraResolution? videoResolution,
    CameraEncoderType? encoderType,
    CameraEncoderProfile? encoderProfile,
    double? frameRate,
    double? govLength,
    double? encoderQuality,
    CameraBitrateMode? bitrateMode,
    double? bitrateKbps,
    bool? motionDetectionEnabled,
    double? motionSensitivity,
    bool? intrusionDetectionEnabled,
    double? intrusionSensitivity,
    List<DrawableZone>? intrusionZones,
    bool? lineCrossingEnabled,
    double? lineCrossingSensitivity,
    Offset? lineCrossingStart,
    Offset? lineCrossingEnd,
    CameraCrossingDirection? lineCrossingDirection,
    bool? personDetectionEnabled,
    double? personDetectionConfidence,
    List<PolygonZone>? personDetectionZones,
    bool? vehicleDetectionEnabled,
    double? vehicleDetectionConfidence,
    double? speakerVolume,
    double? micGain,
    bool? audioRecordingEnabled,
    bool? sdStorageEnabled,
    bool? sdCardPresent,
    double? sdCardCapacityGb,
    double? sdCardUsedGb,
    double? sdCardHealthPercent,
    bool? sdCardEnduranceRated,
    int? retentionDays,
    StorageFailure? storageFailure,
  }) {
    return Camera(
      id: id,
      name: name ?? this.name,
      isOnline: isOnline ?? this.isOnline,
      room: setRoom ? room : this.room,
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      lastSeen: lastSeen ?? this.lastSeen,
      timezone: timezone ?? this.timezone,
      recordingStatus: recordingStatus ?? this.recordingStatus,
      recordingScheduleWindows:
          recordingScheduleWindows ?? this.recordingScheduleWindows,
      wifiNetwork: wifiNetwork ?? this.wifiNetwork,
      ipAddress: ipAddress ?? this.ipAddress,
      signalStrength: signalStrength ?? this.signalStrength,
      networkSpeedKbps: networkSpeedKbps ?? this.networkSpeedKbps,
      macAddress: macAddress ?? this.macAddress,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      serialNumber: serialNumber ?? this.serialNumber,
      hardwareId: hardwareId ?? this.hardwareId,
      host: host ?? this.host,
      username: username ?? this.username,
      password: password ?? this.password,
      thingName: thingName ?? this.thingName,
      wanLiveViewCapable: wanLiveViewCapable ?? this.wanLiveViewCapable,
      bitrateOsdEnabled: bitrateOsdEnabled ?? this.bitrateOsdEnabled,
      bitrateOsdPosition: bitrateOsdPosition ?? this.bitrateOsdPosition,
      signalStrengthOsdEnabled:
          signalStrengthOsdEnabled ?? this.signalStrengthOsdEnabled,
      signalStrengthOsdPosition:
          signalStrengthOsdPosition ?? this.signalStrengthOsdPosition,
      liveTagOsdEnabled: liveTagOsdEnabled ?? this.liveTagOsdEnabled,
      videoMode: videoMode ?? this.videoMode,
      nightMode: nightMode ?? this.nightMode,
      nightVisionColorCapable:
          nightVisionColorCapable ?? this.nightVisionColorCapable,
      nightVisionSmartCapable:
          nightVisionSmartCapable ?? this.nightVisionSmartCapable,
      privacyMode: privacyMode ?? this.privacyMode,
      privacyZones: privacyZones ?? this.privacyZones,
      mirrorFlip: mirrorFlip ?? this.mirrorFlip,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      sharpness: sharpness ?? this.sharpness,
      wdrEnabled: wdrEnabled ?? this.wdrEnabled,
      wdrLevel: wdrLevel ?? this.wdrLevel,
      whiteBalance: whiteBalance ?? this.whiteBalance,
      exposure: exposure ?? this.exposure,
      exposureTime: exposureTime ?? this.exposureTime,
      exposureGain: exposureGain ?? this.exposureGain,
      videoResolution: videoResolution ?? this.videoResolution,
      encoderType: encoderType ?? this.encoderType,
      encoderProfile: encoderProfile ?? this.encoderProfile,
      frameRate: frameRate ?? this.frameRate,
      govLength: govLength ?? this.govLength,
      encoderQuality: encoderQuality ?? this.encoderQuality,
      bitrateMode: bitrateMode ?? this.bitrateMode,
      bitrateKbps: bitrateKbps ?? this.bitrateKbps,
      motionDetectionEnabled:
          motionDetectionEnabled ?? this.motionDetectionEnabled,
      motionSensitivity: motionSensitivity ?? this.motionSensitivity,
      intrusionDetectionEnabled:
          intrusionDetectionEnabled ?? this.intrusionDetectionEnabled,
      intrusionSensitivity: intrusionSensitivity ?? this.intrusionSensitivity,
      intrusionZones: intrusionZones ?? this.intrusionZones,
      lineCrossingEnabled: lineCrossingEnabled ?? this.lineCrossingEnabled,
      lineCrossingSensitivity:
          lineCrossingSensitivity ?? this.lineCrossingSensitivity,
      lineCrossingStart: lineCrossingStart ?? this.lineCrossingStart,
      lineCrossingEnd: lineCrossingEnd ?? this.lineCrossingEnd,
      lineCrossingDirection:
          lineCrossingDirection ?? this.lineCrossingDirection,
      personDetectionEnabled:
          personDetectionEnabled ?? this.personDetectionEnabled,
      personDetectionConfidence:
          personDetectionConfidence ?? this.personDetectionConfidence,
      personDetectionZones: personDetectionZones ?? this.personDetectionZones,
      vehicleDetectionEnabled:
          vehicleDetectionEnabled ?? this.vehicleDetectionEnabled,
      vehicleDetectionConfidence:
          vehicleDetectionConfidence ?? this.vehicleDetectionConfidence,
      speakerVolume: speakerVolume ?? this.speakerVolume,
      micGain: micGain ?? this.micGain,
      audioRecordingEnabled:
          audioRecordingEnabled ?? this.audioRecordingEnabled,
      sdStorageEnabled: sdStorageEnabled ?? this.sdStorageEnabled,
      sdCardPresent: sdCardPresent ?? this.sdCardPresent,
      sdCardCapacityGb: sdCardCapacityGb ?? this.sdCardCapacityGb,
      sdCardUsedGb: sdCardUsedGb ?? this.sdCardUsedGb,
      sdCardHealthPercent: sdCardHealthPercent ?? this.sdCardHealthPercent,
      sdCardEnduranceRated: sdCardEnduranceRated ?? this.sdCardEnduranceRated,
      retentionDays: retentionDays ?? this.retentionDays,
      storageFailure: storageFailure ?? this.storageFailure,
    );
  }
}
