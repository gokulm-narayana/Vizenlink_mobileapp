import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../../camera_connection.dart';
import '../../camera_result.dart';
import '../../util/onvif_rect_coordinates.dart';
import '../insecure_camera_http_client.dart';
import 'onvif_device_client.dart';
import 'soap_fault.dart';
import '../wsse_digest.dart';

const _kVideoSourceConfigToken = 'VideoSourceCfg_1';
const _kMedia2Namespace = 'http://www.onvif.org/ver20/media/wsdl';

/// One currently-configured privacy mask, as reported by ONVIF Media2 `GetMasks`.
class MaskEntry {
  const MaskEntry({
    required this.token,
    required this.vsrcCfgToken,
    required this.polygon,
    required this.type,
    required this.enabled,
    this.colorX,
    this.colorY,
    this.colorZ,
    this.colorspace,
  });

  final String token;
  final String vsrcCfgToken;
  final List<OnvifPoint> polygon;

  /// `"Color"`, `"Pixelated"`, or `"Blurred"` — accepted and echoed by ONVIF, but only `"Color"`
  /// (a fixed black rectangle) is actually applied to the video on this camera today
  /// (`bsp_camera_ameba.c`'s `fast_mask.color` is hardcoded, never read from this field) —
  /// `MaskOptions.types`/`colorList` (below) are what a client should actually gate UI on.
  final String type;
  final bool enabled;
  final double? colorX;
  final double? colorY;
  final double? colorZ;
  final String? colorspace;
}

class MaskColor {
  const MaskColor({
    required this.x,
    required this.y,
    required this.z,
    required this.colorspace,
  });
  final double x;
  final double y;
  final double z;

  /// `"RGB"` or `"YCbCr"` — the raw ONVIF `Colorspace` wire value.
  final String colorspace;

  @override
  bool operator ==(Object other) =>
      other is MaskColor &&
      x == other.x &&
      y == other.y &&
      z == other.z &&
      colorspace == other.colorspace;

  @override
  int get hashCode => Object.hash(x, y, z, colorspace);
}

/// The camera's mask capability envelope, from `GetMaskOptions` — the source a mask editor
/// should query before rendering type/color pickers (`FR-MOB-093`): render a picker only when
/// more than one value is reported, never assume from `MaskEntry`'s own `type`/`color` fields
/// alone.
class MaskOptions {
  const MaskOptions({
    required this.rectangleOnly,
    required this.singleColorOnly,
    required this.maxMasks,
    required this.maxPoints,
    required this.types,
    required this.colorList,
  });

  final bool rectangleOnly;
  final bool singleColorOnly;
  final int maxMasks;
  final int maxPoints;
  final List<String> types;
  final List<MaskColor> colorList;
}

/// LAN-only ONVIF Media2 client for `CreateMask`/`SetMask`/`DeleteMask`/`GetMasks`/
/// `GetMaskOptions` (`FR-MOB-093`'s privacy mask editor). Always sends a 4-point rectangle
/// polygon (`pixelRectToOnvifPolygon`) and, per `MaskOptions`' capability-driven-visibility
/// rule, the camera's own single reported type/color when it reports only one of either —
/// never a value the UI invented.
///
/// Endpoint resolved via `OnvifDeviceClient.getServices()` (real ONVIF service discovery,
/// not a hardcoded path) — same pattern `Media2CapabilitiesClient` established. **Cached for
/// the life of the app process, not just this client instance** — keyed by
/// `connection.host` in `_endpointCacheByHost`/`_optionsCacheByHost` (module-level `static`
/// maps, below), because `MaskEditorCardState` constructs a brand-new `MaskClient` every time
/// the editor screen mounts; an instance-level cache would reset on every screen visit and miss
/// the actual complaint this was built to fix. A fixed endpoint and this camera's mask
/// capability descriptor (`MaxMasks`/`MaxPoints`/supported types/colors) don't change mid-app-
/// session, so re-resolving/re-fetching them on every single `getMasks`/`getMaskOptions`/
/// `createMask`/`setMask`/`deleteMask` call — or every time the editor screen is reopened — was
/// pure waste. Real-world impact this was causing, per direct user report: on this camera the
/// HTTPD task runs at the highest FreeRTOS priority tier (see
/// `.claude/rules/camera-firmware.md` § Task priority convention), so a burst of redundant ONVIF
/// requests during mask editing visibly starved the RTSP/NVR video pipeline, not just slowed
/// the mobile app UI.
///
/// **Not yet hardware-verified** — no `testing_utilities/*.py` reference script exists for
/// mask CRUD; this wire format is matched directly against `onvif_media2.c`/`onvif_parser.c`
/// source, same higher-risk caveat `OsdClient`'s own doc carries.
class MaskClient {
  MaskClient(this.connection, {http.Client? httpClient})
    : _http = httpClient ?? createCameraHttpClient(),
      _device = OnvifDeviceClient(connection, httpClient: httpClient);

  final CameraConnection connection;
  final http.Client _http;
  final OnvifDeviceClient _device;

  /// Process-lifetime caches, keyed by camera host so multiple onboarded cameras don't share
  /// each other's endpoint/options. Cleared only by explicit `forceRefresh` on
  /// [getMaskOptions] or process restart — there's no cache-invalidation signal for "this
  /// camera's ONVIF service layout changed" short of a firmware update, which already requires
  /// a reboot (a fresh app process) to take effect.
  static final Map<String, Uri> _endpointCacheByHost = {};
  static final Map<String, MaskOptions> _optionsCacheByHost = {};

  Future<CameraResult<Uri>> _resolveMedia2Endpoint(Duration timeout) async {
    final cached = _endpointCacheByHost[connection.host];
    if (cached != null) return CameraSuccess(cached);

    final servicesResult = await _device.getServices(timeout: timeout);
    switch (servicesResult) {
      case CameraSuccess<List<OnvifServiceEntry>>(:final value):
        final entry = value
            .where((e) => e.namespace == _kMedia2Namespace)
            .firstOrNull;
        if (entry == null) {
          return const CameraFailure(
            'Media2 service not offered by this camera',
          );
        }
        _endpointCacheByHost[connection.host] = entry.xAddr;
        return CameraSuccess(entry.xAddr);
      case CameraFailure(:final reason):
        return CameraFailure(reason);
      case CameraTimeout():
        return const CameraTimeout();
    }
  }

  Future<CameraResult<List<MaskEntry>>> getMasks({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final bodyResult = await _post(
      '<tr2:GetMasks xmlns:tr2="$_kMedia2Namespace"/>',
      timeout,
    );
    return bodyResult.map((body) {
      final doc = XmlDocument.parse(body);
      final entries = <MaskEntry>[];
      for (final el in doc.findAllElements('Masks', namespace: '*')) {
        final token = el.getAttribute('token');
        if (token == null || token.isEmpty) continue;
        final cfgTokenEl = el.findElements(
          'ConfigurationToken',
          namespace: '*',
        );
        final typeEl = el.findElements('Type', namespace: '*');
        final enabledEl = el.findElements('Enabled', namespace: '*');
        if (typeEl.isEmpty || enabledEl.isEmpty) continue;

        final points = <OnvifPoint>[];
        for (final polygonEl in el.findElements('Polygon', namespace: '*')) {
          for (final pointEl in polygonEl.findElements(
            'Point',
            namespace: '*',
          )) {
            final x = double.tryParse(pointEl.getAttribute('x') ?? '');
            final y = double.tryParse(pointEl.getAttribute('y') ?? '');
            if (x != null && y != null) points.add(OnvifPoint(x, y));
          }
        }

        final colorEl = el.findElements('Color', namespace: '*');
        entries.add(
          MaskEntry(
            token: token,
            vsrcCfgToken: cfgTokenEl.isEmpty
                ? ''
                : cfgTokenEl.first.innerText.trim(),
            polygon: points,
            type: typeEl.first.innerText.trim(),
            enabled: enabledEl.first.innerText.trim() == 'true',
            colorX: colorEl.isEmpty
                ? null
                : double.tryParse(colorEl.first.getAttribute('X') ?? ''),
            colorY: colorEl.isEmpty
                ? null
                : double.tryParse(colorEl.first.getAttribute('Y') ?? ''),
            colorZ: colorEl.isEmpty
                ? null
                : double.tryParse(colorEl.first.getAttribute('Z') ?? ''),
            colorspace: colorEl.isEmpty
                ? null
                : colorEl.first.getAttribute('Colorspace'),
          ),
        );
      }
      return entries;
    });
  }

  /// Cached (process-lifetime, per host — see `_optionsCacheByHost`) after the first successful
  /// fetch — pass `forceRefresh: true` to bypass the cache (e.g. a manual "reload" action the
  /// user explicitly requested), otherwise this never hits the network more than once per
  /// camera for the life of the app. See the class doc for why.
  Future<CameraResult<MaskOptions>> getMaskOptions({
    Duration timeout = const Duration(seconds: 10),
    bool forceRefresh = false,
  }) async {
    final cached = _optionsCacheByHost[connection.host];
    if (cached != null && !forceRefresh) return CameraSuccess(cached);

    final bodyResult = await _post(
      '<tr2:GetMaskOptions xmlns:tr2="$_kMedia2Namespace">'
      '<tr2:ConfigurationToken>$_kVideoSourceConfigToken</tr2:ConfigurationToken>'
      '</tr2:GetMaskOptions>',
      timeout,
    );
    final result = bodyResult.map((body) {
      final doc = XmlDocument.parse(body);
      final optionsEl = doc.findAllElements('Options', namespace: '*');
      if (optionsEl.isEmpty) {
        return const MaskOptions(
          rectangleOnly: true,
          singleColorOnly: true,
          maxMasks: 0,
          maxPoints: 4,
          types: [],
          colorList: [],
        );
      }
      final el = optionsEl.first;
      final maxMasksEl = el.findElements('MaxMasks', namespace: '*');
      final maxPointsEl = el.findElements('MaxPoints', namespace: '*');
      final types = el
          .findElements('Types', namespace: '*')
          .map((e) => e.innerText.trim())
          .toList(growable: false);
      final colorList = <MaskColor>[];
      for (final colorOptEl in el.findElements('Color', namespace: '*')) {
        for (final listEl in colorOptEl.findElements(
          'ColorList',
          namespace: '*',
        )) {
          final x = double.tryParse(listEl.getAttribute('X') ?? '');
          final y = double.tryParse(listEl.getAttribute('Y') ?? '');
          final z = double.tryParse(listEl.getAttribute('Z') ?? '');
          final cs = listEl.getAttribute('Colorspace');
          if (x != null && y != null && z != null && cs != null) {
            colorList.add(MaskColor(x: x, y: y, z: z, colorspace: cs));
          }
        }
      }
      return MaskOptions(
        rectangleOnly: el.getAttribute('RectangleOnly') == 'true',
        singleColorOnly: el.getAttribute('SingleColorOnly') == 'true',
        maxMasks: maxMasksEl.isEmpty
            ? 0
            : int.tryParse(maxMasksEl.first.innerText.trim()) ?? 0,
        maxPoints: maxPointsEl.isEmpty
            ? 4
            : int.tryParse(maxPointsEl.first.innerText.trim()) ?? 4,
        types: types,
        colorList: colorList,
      );
    });
    if (result case CameraSuccess<MaskOptions>(:final value)) {
      _optionsCacheByHost[connection.host] = value;
    }
    return result;
  }

  Future<CameraResult<String>> createMask({
    required List<OnvifPoint> polygon,
    required bool enabled,
    required String type,
    MaskColor? color,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final bodyResult = await _post(
      '<tr2:CreateMask xmlns:tr2="$_kMedia2Namespace" xmlns:tt="http://www.onvif.org/ver10/schema">'
      '${_maskXml(token: '', polygon: polygon, enabled: enabled, type: type, color: color)}'
      '</tr2:CreateMask>',
      timeout,
    );
    return bodyResult.map((body) {
      final doc = XmlDocument.parse(body);
      final tokenEl = doc.findAllElements('Token', namespace: '*');
      return tokenEl.isEmpty ? '' : tokenEl.first.innerText.trim();
    });
  }

  Future<CameraResult<void>> setMask({
    required String token,
    required List<OnvifPoint> polygon,
    required bool enabled,
    required String type,
    MaskColor? color,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final bodyResult = await _post(
      '<tr2:SetMask xmlns:tr2="$_kMedia2Namespace" xmlns:tt="http://www.onvif.org/ver10/schema">'
      '${_maskXml(token: token, polygon: polygon, enabled: enabled, type: type, color: color)}'
      '</tr2:SetMask>',
      timeout,
    );
    return bodyResult.map((_) {});
  }

  Future<CameraResult<void>> deleteMask(
    String token, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final bodyResult = await _post(
      '<tr2:DeleteMask xmlns:tr2="$_kMedia2Namespace">'
      '<tr2:Token>$token</tr2:Token>'
      '</tr2:DeleteMask>',
      timeout,
    );
    return bodyResult.map((_) {});
  }

  /// Test-only: clears the process-lifetime endpoint/options caches so test cases sharing a
  /// `CameraConnection.host` (e.g. the same mock camera address across a whole test file)
  /// don't leak cached state between otherwise-independent tests. Not for use in app code —
  /// the whole point of these caches in production is that nothing ever needs to clear them
  /// short of an app restart.
  static void debugClearCaches() {
    _endpointCacheByHost.clear();
    _optionsCacheByHost.clear();
  }

  String _maskXml({
    required String token,
    required List<OnvifPoint> polygon,
    required bool enabled,
    required String type,
    MaskColor? color,
  }) {
    final pointsXml = polygon
        .map((p) => '<tt:Point x="${p.x}" y="${p.y}"/>')
        .join();
    final colorXml = color == null
        ? ''
        : '<tr2:Color X="${color.x}" Y="${color.y}" Z="${color.z}" '
              'Colorspace="${color.colorspace}"/>';
    return '<tr2:Mask token="$token">'
        '<tr2:ConfigurationToken>$_kVideoSourceConfigToken</tr2:ConfigurationToken>'
        '<tr2:Polygon>$pointsXml</tr2:Polygon>'
        '<tr2:Type>$type</tr2:Type>'
        '$colorXml'
        '<tr2:Enabled>$enabled</tr2:Enabled>'
        '</tr2:Mask>';
  }

  Future<CameraResult<String>> _post(String bodyXml, Duration timeout) async {
    final endpointResult = await _resolveMedia2Endpoint(timeout);
    final Uri endpoint;
    switch (endpointResult) {
      case CameraSuccess<Uri>(:final value):
        endpoint = value;
      case CameraFailure(:final reason):
        return CameraFailure(reason);
      case CameraTimeout():
        return const CameraTimeout();
    }

    final digest = WsseDigest.generate(connection.password);
    final envelope =
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">'
        '<s:Header>'
        '<wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">'
        '<wsse:UsernameToken>'
        '<wsse:Username>${connection.username}</wsse:Username>'
        '<wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">'
        '${digest.digestBase64}</wsse:Password>'
        '<wsse:Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">'
        '${digest.nonceBase64}</wsse:Nonce>'
        '<wsu:Created xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">'
        '${digest.createdIso}</wsu:Created>'
        '</wsse:UsernameToken>'
        '</wsse:Security>'
        '</s:Header>'
        '<s:Body>$bodyXml</s:Body>'
        '</s:Envelope>';

    try {
      final response = await _http
          .post(
            endpoint,
            headers: const {
              'Content-Type': 'application/soap+xml; charset=utf-8',
            },
            body: envelope,
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        return CameraFailure('HTTP ${response.statusCode}: ${response.body}');
      }
      final faultReason = soapFaultReason(response.body);
      if (faultReason != null) {
        return CameraFailure(faultReason);
      }
      return CameraSuccess(response.body);
    } on Exception catch (e) {
      return CameraFailure(e.toString());
    }
  }

  void close() {
    _http.close();
    _device.close();
  }
}

extension _ResultMap<T> on CameraResult<T> {
  CameraResult<R> map<R>(R Function(T value) f) {
    return switch (this) {
      CameraSuccess(:final value) => CameraSuccess<R>(f(value)),
      CameraFailure(:final reason) => CameraFailure<R>(reason),
      CameraTimeout() => CameraTimeout<R>(),
    };
  }
}
