import 'package:camera_api/camera_api.dart';
import 'package:test/test.dart';

// `wanCommandCapable` added 2026-08-14 — was already fetched at onboarding
// (`AddCameraCredentialsScreen`) but never persisted on `CameraConnection`, so nothing
// downstream could gate on it. This covers the persistence path directly (the actual bug was
// "the value never survives past the onboarding screen," not a UI mistake), complementing
// `CameraAlertsScreen`'s own gating logic.
void main() {
  const base = CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw');

  test('wanCommandCapable defaults to null ("unknown"), distinct from wanLiveViewCapable', () {
    expect(base.wanCommandCapable, isNull);
    expect(base.wanLiveViewCapable, isNull);
  });

  test('copyWithWanCapabilities sets both flags independently — AWS-on/KVS-off is a real state', () {
    // The cost-constrained-SKU case FR-CF-137 exists for: AWS IoT on (alerts work) but KVS off
    // (WAN live view doesn't) — one flag must never be inferred from the other.
    final updated = base.copyWithWanCapabilities(
      wanLiveViewCapable: false,
      wanCommandCapable: true,
    );

    expect(updated.wanCommandCapable, true);
    expect(updated.wanLiveViewCapable, false);
    // Every other field carries over unchanged.
    expect(updated.host, base.host);
    expect(updated.username, base.username);
  });

  test('toJson/fromJson round-trips wanCommandCapable', () {
    final updated = base.copyWithWanCapabilities(
      wanLiveViewCapable: true,
      wanCommandCapable: false,
    );

    final restored = CameraConnection.fromJson(updated.toJson());

    expect(restored.wanCommandCapable, false);
    expect(restored.wanLiveViewCapable, true);
  });

  test('toJson omits wanCommandCapable when null — fromJson then restores it as null, not false', () {
    final json = base.toJson();

    expect(json.containsKey('wanCommandCapable'), isFalse);

    final restored = CameraConnection.fromJson(json);
    expect(restored.wanCommandCapable, isNull);
  });

  test(
    'fromJson on a connection persisted before this field existed leaves wanCommandCapable null, '
    'not false — a pre-existing camera must not silently lose Alerts access',
    () {
      final legacyJson = {
        'host': '192.168.1.50',
        'username': 'admin',
        'password': 'pw',
        'httpsPort': 443,
        'rtspPort': 554,
        'thingName': 'VZL-CAM-000001',
        'wanLiveViewCapable': true,
        // no 'wanCommandCapable' key at all — simulates a connection saved before this field
      };

      final restored = CameraConnection.fromJson(legacyJson);

      expect(restored.wanCommandCapable, isNull);
    },
  );
}
