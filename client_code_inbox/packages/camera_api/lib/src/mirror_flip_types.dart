/// Shared wire vocabulary for `SetMirrorFlip`/`GetMirrorFlip` (`FR-NE-039`) — used by both
/// `lan/mirror_flip_client.dart`'s `MirrorFlipClient` and `wan/wan_mirror_flip_client.dart`'s
/// `WanMirrorFlipClient`, so it lives at the package root rather than under `lan/`.
enum MirrorFlipMode { off, mirror, flip, both }

extension MirrorFlipModeWire on MirrorFlipMode {
  String get wireValue => switch (this) {
    MirrorFlipMode.off => 'Off',
    MirrorFlipMode.mirror => 'Mirror',
    MirrorFlipMode.flip => 'Flip',
    MirrorFlipMode.both => 'Both',
  };

  static MirrorFlipMode? fromWire(String value) {
    return switch (value) {
      'Off' => MirrorFlipMode.off,
      'Mirror' => MirrorFlipMode.mirror,
      'Flip' => MirrorFlipMode.flip,
      'Both' => MirrorFlipMode.both,
      _ => null,
    };
  }
}
