import 'camera_result.dart';

enum NightVisionType { grey, color, smart }

extension NightVisionTypeWire on NightVisionType {
  String get wireValue => switch (this) {
    NightVisionType.grey => 'Grey',
    NightVisionType.color => 'Color',
    NightVisionType.smart => 'Smart',
  };

  static NightVisionType? fromWire(String value) {
    return switch (value) {
      'Grey' => NightVisionType.grey,
      'Color' => NightVisionType.color,
      'Smart' => NightVisionType.smart,
      _ => null,
    };
  }
}

class NightVisionStatus {
  const NightVisionStatus({
    required this.type,
    required this.colorCapable,
    required this.smartCapable,
    this.subState,
  });

  final NightVisionType type;

  /// Hardware signal — does this SKU have a white light/spotlight to produce a color night
  /// image at all (`NURAEYE_CFG_COLOR_NIGHT_VISION`/`FR-CF-127`). The UI must hide the Color
  /// option entirely when `false`, not just disable it.
  final bool colorCapable;

  /// Firmware-wiring signal — is Smart mode's AI-event-triggered logic built on this firmware
  /// (`NURAEYE_CFG_SMART_NIGHT_VISION`/`FR-CF-128`). Still `false` until that flag is flipped on
  /// verified firmware (see Stage 2 `DESIGN.md` §C1's "Result" note) — kept here so the UI
  /// doesn't need a separate FR/build to start reading it once it lands.
  final bool smartCapable;

  /// Live Grey/Color sub-state, only present when [type] is [NightVisionType.smart] — reports
  /// whether the camera is currently reacting to a recent AI detection (`Color`) or sitting at
  /// Smart's passive-IR default (`Grey`). Always `null` for `grey`/`color`, where [type] alone
  /// already says everything there is to say.
  final NightVisionType? subState;

  /// Value equality — lets UI code (e.g. a pending-vs-applied dirty check on a settings screen)
  /// compare two instances by content instead of identity.
  @override
  bool operator ==(Object other) =>
      other is NightVisionStatus &&
      other.type == type &&
      other.colorCapable == colorCapable &&
      other.smartCapable == smartCapable &&
      other.subState == subState;

  @override
  int get hashCode => Object.hash(type, colorCapable, smartCapable, subState);
}

/// Shared interface for `GetNightVisionType`/`SetNightVisionType` regardless of transport — lets
/// UI code (`_NightVisionCard`) work against either `lan/night_vision_client.dart`'s
/// `NightVisionClient` or `wan/wan_night_vision_client.dart`'s `WanNightVisionClient` without
/// knowing which. Added 2026-08-02 for `FR-MOB-068`'s WAN half. Lives at the package root
/// (`src/`), not under `lan/`, precisely because both transports implement it — added
/// 2026-08-11 when the wire enum/status type/interface were split out of what was originally
/// one `lan/`-only file, so a `wan/` client no longer has to reach into `lan/` for its own
/// shared contract.
abstract class NightVisionSource {
  Future<CameraResult<NightVisionStatus>> getNightVisionType({Duration timeout});

  Future<CameraResult<void>> setNightVisionType(NightVisionType type, {Duration timeout});
}
