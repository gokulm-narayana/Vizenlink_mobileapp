import 'dart:io';
import 'dart:typed_data';

import 'package:camera_api/camera_api.dart';
import 'package:path_provider/path_provider.dart';

import '../models/camera.dart';
import 'homes_controller.dart';
import 'preview_key_store.dart';

/// Fetches [cameraId]'s live device information, network interface, and WAN
/// capability over LAN (`OnvifDeviceClient`/`CapabilitiesClient`) and
/// persists whatever succeeds via [HomesController.updateCamera]. Shared by
/// the scan setup flow (auto-sync right after a camera is added) and
/// [CameraInfoScreen]'s manual "Sync from camera" button, so both stay in
/// sync with the same fields/behavior.
///
/// Returns the human-readable failure reasons for whichever calls didn't
/// succeed (empty list = fully synced) — callers decide how to surface that.
Future<List<String>> syncCameraFromDevice({
  required HomesController homesController,
  required String cameraId,
  required CameraConnection connection,
}) async {
  final device = OnvifDeviceClient(connection);
  final nuraeye = NuraeyeClient(connection);
  try {
    final results = await Future.wait([
      device.getDeviceInformation(),
      device.getDeviceIdentity(),
      device.getNetworkInterfaceInfo(),
      CapabilitiesClient(nuraeye).getCapabilities(),
      device.getSystemDateAndTime(),
      SnapshotClient(connection).getSnapshot(),
    ]);
    final infoResult = results[0] as CameraResult<DeviceInformation>;
    final identityResult = results[1] as CameraResult<DeviceIdentity>;
    final netResult = results[2] as CameraResult<NetworkInterfaceInfo>;
    final capsResult = results[3] as CameraResult<CameraCapabilities>;
    final dateTimeResult = results[4] as CameraResult<DeviceDateTime>;
    final snapshotResult = results[5] as CameraResult<Uint8List>;

    final failures = <String>[];
    DeviceInformation? info;
    DeviceIdentity? identity;
    NetworkInterfaceInfo? net;
    CameraCapabilities? caps;
    DeviceDateTime? dateTime;
    String? thumbnailPath;

    switch (identityResult) {
      case CameraSuccess(:final value):
        identity = value;
      case CameraFailure(:final reason):
        failures.add('name ($reason)');
      case CameraTimeout():
        failures.add('name (timed out)');
    }
    switch (infoResult) {
      case CameraSuccess(:final value):
        info = value;
      case CameraFailure(:final reason):
        failures.add('device info ($reason)');
      case CameraTimeout():
        failures.add('device info (timed out)');
    }
    switch (netResult) {
      case CameraSuccess(:final value):
        net = value;
      case CameraFailure(:final reason):
        failures.add('network info ($reason)');
      case CameraTimeout():
        failures.add('network info (timed out)');
    }
    switch (capsResult) {
      case CameraSuccess(:final value):
        caps = value;
      case CameraFailure(:final reason):
        failures.add('capabilities ($reason)');
      case CameraTimeout():
        failures.add('capabilities (timed out)');
    }
    switch (dateTimeResult) {
      case CameraSuccess(:final value):
        dateTime = value;
      case CameraFailure(:final reason):
        failures.add('timezone ($reason)');
      case CameraTimeout():
        failures.add('timezone (timed out)');
    }
    switch (snapshotResult) {
      case CameraSuccess(:final value):
        thumbnailPath = await _saveSnapshotLocally(
          cameraId: cameraId,
          bytes: value,
          previousThumbnailUrl: _findCamera(
            homesController,
            cameraId,
          )?.thumbnailUrl,
        );
        if (thumbnailPath == null) {
          failures.add('snapshot (failed to save locally)');
        }
      case CameraFailure(:final reason):
        failures.add('snapshot ($reason)');
      case CameraTimeout():
        failures.add('snapshot (timed out)');
    }

    // Empty means factory-default (no name ever configured on this camera)
    // — leave the existing app-side name alone rather than blanking it.
    final realName = (identity != null && identity.name.isNotEmpty)
        ? identity.name
        : null;

    // Reachability ("ping") for [Camera.isOnline]: this camera is online if
    // *any* of the LAN calls above actually got a response — a single
    // failed call (e.g. one ONVIF service down) doesn't mean the whole
    // device is unreachable, but every one of them failing/timing out does.
    // Always written below, even when every call failed, so a camera that's
    // gone offline actually gets marked offline instead of the app trusting
    // whatever isOnline was set to at onboarding forever.
    final reachable =
        infoResult is CameraSuccess ||
        identityResult is CameraSuccess ||
        netResult is CameraSuccess ||
        capsResult is CameraSuccess ||
        dateTimeResult is CameraSuccess ||
        snapshotResult is CameraSuccess;

    homesController.updateCamera(
      cameraId,
      (current) => current.copyWith(
        isOnline: reachable,
        lastSeen: reachable ? DateTime.now() : null,
        name: realName,
        manufacturer: info?.manufacturer,
        model: info?.model,
        firmwareVersion: info?.firmwareVersion,
        serialNumber: info?.serialNumber,
        hardwareId: info?.hardwareId,
        macAddress: net?.macAddress,
        ipAddress: net?.ipv4Address,
        // The device's serial number doubles as its AWS IoT thing
        // name/KVS stream name (OnvifDeviceClient.getSerialNumber's
        // doc) — this is what unlocks the WAN identity/live-view
        // clients for a camera onboarded via LAN.
        thingName: info?.serialNumber,
        wanLiveViewCapable: caps?.wanLiveViewCapable,
        wanCommandCapable: caps?.wanCommandCapable,
        sirenCapable: caps?.sirenCapable,
        spotlightCapable: caps?.spotlightCapable,
        warningCapable: caps?.warningCapable,
        // The camera's own POSIX-style TZ code (e.g. "IST-5:30"), not an
        // IANA name — CameraInfoScreen's timezone picker switches to the
        // camera's own GetSupportedTimezones catalog (same code
        // vocabulary) once a connection is available, so this is never
        // compared against IANA strings.
        timezone: dateTime?.timezone,
        thumbnailUrl: thumbnailPath,
      ),
    );

    // Opportunistic, once-per-camera registration of this device's WAN
    // preview-snapshot public key (see PreviewKeyStore's doc) — needs a
    // reachable LAN connection and a resolved thingName, both of which this
    // sync either already has or just confirmed.
    final resolvedThingName = info?.serialNumber ?? connection.thingName;
    if (reachable && resolvedThingName != null) {
      await _registerPreviewKeyIfNeeded(connection, resolvedThingName);
    }

    return failures;
  } finally {
    device.close();
    nuraeye.close();
  }
}

/// Registers this device's preview public key with the camera
/// (`RegisterPreviewKey`, LAN-only) if it hasn't been already — see
/// [PreviewKeyStore]'s doc comment for the full picture. Best-effort:
/// failures are silently skipped, same reasoning as every other
/// non-critical field in [syncCameraFromDevice] — the next sync/reachability
/// check simply tries again since nothing gets marked registered on failure.
Future<void> _registerPreviewKeyIfNeeded(
  CameraConnection connection,
  String thingName,
) async {
  if (await PreviewKeyStore.instance.isRegistered(thingName)) return;
  final publicKeyBase64 = await PreviewKeyStore.instance
      .getOrCreatePublicKeyBase64();
  final nuraeye = NuraeyeClient(connection);
  try {
    final result = await nuraeye.call(
      'RegisterPreviewKey',
      params: {'public_key': publicKeyBase64},
    );
    if (result is CameraSuccess) {
      await PreviewKeyStore.instance.markRegistered(thingName);
    }
  } finally {
    nuraeye.close();
  }
}

/// Fetches a fresh real snapshot for [cameraId] over LAN and persists it as
/// `Camera.thumbnailUrl` — the lighter-weight action behind every "Refresh
/// preview" button on the camera-settings screens (as opposed to
/// [syncCameraFromDevice]'s full device-info sync, which also refetches a
/// snapshot but alongside several other fields). Returns true on success.
Future<bool> refreshCameraSnapshot({
  required HomesController homesController,
  required String cameraId,
  required CameraConnection connection,
}) async {
  final client = SnapshotClient(connection);
  try {
    final result = await client.getSnapshot();
    // A successful snapshot fetch doubles as this camera's reachability
    // ping — always recorded, on both success and failure, so a camera
    // that's gone offline gets marked offline instead of the app trusting
    // whatever isOnline was last set to (see syncCameraFromDevice's doc for
    // the fuller version of this same reasoning).
    final reachable = result is CameraSuccess;
    homesController.updateCamera(
      cameraId,
      (current) => current.copyWith(
        isOnline: reachable,
        lastSeen: reachable ? DateTime.now() : null,
      ),
    );
    // Same opportunistic registration syncCameraFromDevice does — this is a
    // much more frequently-successful LAN touchpoint (every manual "Refresh
    // preview" tap, not just onboarding/"Sync from camera"), so a camera
    // whose full sync never happened to land while reachable still gets its
    // WAN preview key registered the first time this lighter call succeeds.
    final thingName = connection.thingName;
    if (reachable && thingName != null) {
      await _registerPreviewKeyIfNeeded(connection, thingName);
    }
    if (result case CameraSuccess(:final value)) {
      final path = await _saveSnapshotLocally(
        cameraId: cameraId,
        bytes: value,
        previousThumbnailUrl: _findCamera(
          homesController,
          cameraId,
        )?.thumbnailUrl,
      );
      if (path != null) {
        homesController.updateCamera(
          cameraId,
          (current) => current.copyWith(thumbnailUrl: path),
        );
        return true;
      }
    }
    return false;
  } finally {
    client.close();
  }
}

/// Cheap reachability-only probe for [cameraId] — updates `isOnline`/
/// `lastSeen` the same way [refreshCameraSnapshot] does, but via a single
/// unauthenticated LAN round trip (`WebRtcUriClient.checkReachable()`'s
/// `areYouNuraeyeDevice`) instead of fetching a full snapshot image. Meant
/// to run on a much tighter timer (e.g. the Dashboard's short-interval
/// online/offline check) than the heavier, image-fetching
/// [refreshCameraSnapshot] — polling every camera's full snapshot every few
/// seconds would waste bandwidth for no benefit beyond the reachability bit
/// this already gets for a fraction of the cost.
///
/// Falls back to a cheap WAN read (`WanDeviceIdentityClient.getDeviceIdentity`
/// — a real round trip, but the smallest one available on that transport)
/// when the LAN probe fails and this camera has a known `thingName` —
/// otherwise a camera that's simply off the phone's current LAN (not
/// actually offline) would be wrongly marked offline, same reasoning as
/// live view's own LAN-then-WAN transport selection
/// (`STREAMING_GUIDE.md` §1).
Future<void> pingCameraReachability({
  required HomesController homesController,
  required String cameraId,
  required CameraConnection connection,
}) async {
  final nuraeye = NuraeyeClient(connection);
  bool reachable;
  try {
    reachable = await WebRtcUriClient(nuraeye).checkReachable();
  } finally {
    nuraeye.close();
  }

  if (!reachable) {
    final thingName = connection.thingName;
    if (thingName != null) {
      final result = await WanDeviceIdentityClient(
        thingName,
      ).getDeviceIdentity(timeout: const Duration(seconds: 5));
      reachable = result is CameraSuccess;
    }
  }

  final current = _findCamera(homesController, cameraId);
  if (current == null || current.isOnline == reachable) return;
  homesController.updateCamera(
    cameraId,
    (camera) => camera.copyWith(
      isOnline: reachable,
      lastSeen: reachable ? DateTime.now() : null,
    ),
  );
}

/// Transient WAN preview fetch for a single "Refresh preview" attempt, used
/// as a fallback once [refreshCameraSnapshot]'s LAN attempt fails.
/// `WanPreviewSnapshotClient`'s own doc is explicit that the returned bytes
/// must never be persisted (no gallery save, no cache file — and
/// deliberately not written to `Camera.thumbnailUrl` here either) since this
/// is a live decrypted frame for on-screen display only, not a kept
/// snapshot. Callers should hold the bytes in local widget state only, for
/// as long as that screen wants to keep showing them. Returns null if this
/// camera has no `thingName` yet, or the WAN fetch itself fails (no local
/// preview key registered with this camera yet, camera unreachable, decrypt
/// failure, etc — all indistinguishable to a caller that just wants bytes
/// or nothing).
Future<Uint8List?> fetchWanPreviewSnapshot({
  required CameraConnection connection,
}) async {
  final thingName = connection.thingName;
  if (thingName == null) return null;
  final result = await WanPreviewSnapshotClient(thingName).getPreviewSnapshot();
  switch (result) {
    case CameraSuccess(:final value):
      return value;
    case CameraFailure(:final reason):
      // Swallowed to null for the UI (just shows a generic "failed to
      // refresh" snackbar), but logged — the most likely reason ("No
      // preview key generated/registered yet") is otherwise invisible and
      // easy to mistake for a generic failure.
      // ignore: avoid_print
      print('[WanPreview] getPreviewSnapshot failed: $reason');
      return null;
    case CameraTimeout():
      // ignore: avoid_print
      print('[WanPreview] getPreviewSnapshot timed out');
      return null;
  }
}

Camera? _findCamera(HomesController homesController, String cameraId) {
  for (final home in homesController.value.homes) {
    for (final camera in home.cameras) {
      if (camera.id == cameraId) return camera;
    }
  }
  return null;
}

/// Writes a real camera snapshot to a fresh, uniquely-named file under the
/// app's documents directory, deleting the previous local snapshot (if any)
/// so they don't accumulate. A fresh filename per sync — rather than
/// overwriting the same path — sidesteps `Image.file`'s path-keyed cache
/// never refreshing when the same path's bytes change underneath it.
/// Returns null (caller falls back to whatever `thumbnailUrl` already was)
/// on any I/O failure.
Future<String?> _saveSnapshotLocally({
  required String cameraId,
  required Uint8List bytes,
  required String? previousThumbnailUrl,
}) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final snapshotsDir = Directory('${dir.path}/camera_snapshots');
    if (!await snapshotsDir.exists()) {
      await snapshotsDir.create(recursive: true);
    }
    final file = File(
      '${snapshotsDir.path}/$cameraId-${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(bytes);

    if (previousThumbnailUrl != null &&
        !previousThumbnailUrl.startsWith('http://') &&
        !previousThumbnailUrl.startsWith('https://')) {
      final previousFile = File(previousThumbnailUrl);
      if (await previousFile.exists()) await previousFile.delete();
    }
    return file.path;
  } on Exception {
    return null;
  }
}
