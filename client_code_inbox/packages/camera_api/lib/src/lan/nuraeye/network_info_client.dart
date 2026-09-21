import 'package:http/http.dart' as http;

import '../../camera_connection.dart';
import '../../camera_result.dart';
import 'nuraeye_client.dart';

/// One entry from `GetSupportedTimezones` (`FR-NE-097`) — [code] is the POSIX-style string sent
/// straight back on `OnvifDeviceClient.setTimeZone` (ONVIF `SetSystemDateAndTime`, a different
/// class — time zone *setting* stays ONVIF, only the curated *catalog* to pick from is a
/// NuraeyeClient action), [name] the human-readable label to show in a picker.
class TimezoneOption {
  const TimezoneOption({required this.code, required this.name});
  final String code;
  final String name;
}

/// The camera's WiFi info/setup/signal (`nuraeye.c`'s `GetWiFiInfo`/`SetupWiFi`/
/// `GetWiFiSignalStrength`) and curated time-zone catalog (`GetSupportedTimezones`,
/// `FR-NE-097`) — all `/nuraeye` NuraeyeClient actions with no ONVIF equivalent.
///
/// **Split out of `OnvifDeviceClient` 2026-08-11** — these four methods were the only
/// NuraeyeClient calls mixed into what's otherwise a pure ONVIF SOAP class; see
/// `kb/raw/2026-08-11-code-camera-api-lan-wan-restructure.md` for why a single class speaking
/// two protocols didn't belong in a `lan/onvif/` vs `lan/nuraeye/` folder split — the same
/// reasoning that split `AudioVolumeClient` earlier the same session.
class NetworkInfoClient {
  NetworkInfoClient(this.connection, {http.Client? httpClient})
      : _nuraeye = NuraeyeClient(connection, httpClient: httpClient);

  final CameraConnection connection;
  final NuraeyeClient _nuraeye;

  /// The camera's configured WiFi network name — `nuraeye.c`'s `GetWiFiInfo` action. Only the
  /// SSID is ever surfaced; the response also carries the WiFi password (`psk`), which this
  /// method deliberately discards rather than exposing anywhere in the UI. Only meaningful when
  /// `NetworkInterfaceInfo.isWireless` (`OnvifDeviceClient.getNetworkInterfaceInfo`) — callers
  /// should gate on that first.
  Future<CameraResult<String>> getWifiSsid({Duration timeout = const Duration(seconds: 10)}) async {
    final result = await _nuraeye.call('GetWiFiInfo', timeout: timeout);
    return switch (result) {
      CameraSuccess(:final value) => CameraSuccess((value['ssid'] as String?) ?? ''),
      CameraFailure(:final reason) => CameraFailure(reason),
      CameraTimeout() => const CameraTimeout(),
    };
  }

  /// Sends new WiFi credentials to the camera — `nuraeye.c`'s `SetupWiFi` action (`FR-NE-010`).
  /// `verify: true` (default) saves the credentials and has the camera immediately attempt a
  /// WiFi STA connection; `verify: false` saves only, without connecting (`NW5` Mode 2 Pattern
  /// A). **The firmware itself always forces save-only when it's currently reached over
  /// Ethernet, regardless of this `verify` value** — see `FR-NE-010`'s "Ethernet safety
  /// override" note — so callers don't need to special-case that themselves.
  Future<CameraResult<void>> setupWifi({
    required String ssid,
    required String psk,
    bool verify = true,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final result = await _nuraeye.call(
      'SetupWiFi',
      params: {'ssid': ssid, 'psk': psk, 'verify': verify},
      timeout: timeout,
    );
    return switch (result) {
      CameraSuccess() => const CameraSuccess(null),
      CameraFailure(:final reason) => CameraFailure(reason),
      CameraTimeout() => const CameraTimeout(),
    };
  }

  /// The camera's current WiFi signal strength — `nuraeye.c`'s `GetWiFiSignalStrength` action.
  /// Both fields come back as JSON strings on the wire (`"rssi": "-45"`, not a bare number —
  /// confirmed against `nuraeye.c`'s `sprintf(..., "\"rssi\": \"%d\"", rssi)`), so this parses
  /// them rather than casting to `num`. Only meaningful when `NetworkInterfaceInfo.isWireless`.
  Future<CameraResult<({int rssi, int snr})>> getWifiSignalStrength({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call('GetWiFiSignalStrength', timeout: timeout);
    return switch (result) {
      CameraSuccess(:final value) => () {
        final rssi = int.tryParse(value['rssi']?.toString() ?? '');
        final snr = int.tryParse(value['snr']?.toString() ?? '');
        if (rssi == null || snr == null) {
          return CameraFailure<({int rssi, int snr})>(
            'GetWiFiSignalStrength response missing rssi/snr: $value',
          );
        }
        return CameraSuccess<({int rssi, int snr})>((rssi: rssi, snr: snr));
      }(),
      CameraFailure(:final reason) => CameraFailure(reason),
      CameraTimeout() => const CameraTimeout(),
    };
  }

  /// The camera's curated, camera-served time-zone catalog (`FR-NE-097`, `nuraeye.c`'s
  /// `GetSupportedTimezones`) — always a live network call, no caching in this package (see
  /// `.claude/rules/mobile-app-screen-conventions.md`'s "Caching capability/service-discovery
  /// responses" convention; the app layer caches this in `camera_settings_cache.dart`'s
  /// `NetworkAnswerCache`). Older firmware without this action returns [CameraFailure]; callers
  /// should fall back to a hardcoded list in that case rather than leaving a time-zone picker
  /// empty.
  Future<CameraResult<List<TimezoneOption>>> getSupportedTimezones({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call('GetSupportedTimezones', timeout: timeout);
    return switch (result) {
      CameraSuccess(:final value) => () {
        final raw = value['timezones'];
        if (raw is! List) {
          return CameraFailure<List<TimezoneOption>>(
            'GetSupportedTimezones response missing "timezones": $value',
          );
        }
        final options = <TimezoneOption>[
          for (final entry in raw)
            if (entry is Map<String, dynamic>)
              TimezoneOption(
                code: (entry['code'] as String?) ?? '',
                name: (entry['name'] as String?) ?? '',
              ),
        ];
        return CameraSuccess<List<TimezoneOption>>(options);
      }(),
      CameraFailure(:final reason) => CameraFailure(reason),
      CameraTimeout() => const CameraTimeout(),
    };
  }

  void close() {
    _nuraeye.close();
  }
}
