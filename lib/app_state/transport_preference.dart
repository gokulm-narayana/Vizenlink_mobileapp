import 'package:camera_api/camera_api.dart';

import '../models/camera.dart';

/// Calls [lan] first, or [wan] directly when [camera]'s last confirmed live-
/// view transport was WAN (`Camera.lastKnownWan == true`) — skipping the LAN
/// attempt's own timeout (often up to 10-12s) entirely when we already know
/// it won't succeed, rather than paying that cost before falling back to WAN
/// anyway on every single settings-screen action. Still falls back from
/// [lan] to [wan] on a genuine LAN failure when the hint doesn't say WAN
/// outright (`lastKnownWan` is `false` or `null`) — same LAN-then-WAN
/// fallback behavior as before, just skipped when it's a foregone
/// conclusion. See `Camera.lastKnownWan`'s doc and
/// `.claude/rules/mobile-app-screen-conventions.md`'s "LAN/WAN transport
/// selection" section.
Future<CameraResult<T>> callPreferringKnownTransport<T>({
  required Camera camera,
  required String? thingName,
  required Future<CameraResult<T>> Function() lan,
  required Future<CameraResult<T>> Function() wan,
}) async {
  if (camera.lastKnownWan == true && thingName != null) {
    return wan();
  }
  final result = await lan();
  if (result is! CameraSuccess && thingName != null) {
    return wan();
  }
  return result;
}
