import 'package:flutter/foundation.dart';

import 'live_view_controller.dart';

/// Global, app-session-wide LAN/WAN transport override for testing WAN code
/// paths without physically moving the phone off the camera's LAN — e.g.
/// exercising WAN live view while still sitting on the same network as the
/// camera. `null` = normal automatic LAN-first/WAN-fallback behavior. One
/// global choice (set from the Dashboard's app bar, DASH-023) that every
/// [LiveViewController] instance, for every camera, reads and reacts to for
/// as long as the app process runs — not per-camera, not reset by
/// navigating away and back.
///
/// **Dev/test tooling only** — mirrors the sibling `nuraeye-rt` app's
/// `DebugTransportOverride` of the same name/shape. Remove this file and its
/// call sites ([CameraLiveScreen]'s listener, the Dashboard app bar action,
/// [MultiviewScreen]'s tiles) once WAN testing no longer needs a manual
/// override.
class DebugTransportOverride extends ValueNotifier<LiveViewTransport?> {
  DebugTransportOverride._() : super(null);
  static final DebugTransportOverride instance = DebugTransportOverride._();
}
