import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'alerts_api_config.dart';

/// AWS Signature Version 4 — request signing (Authorization header, for the IoT Data Plane
/// HTTPS Publish API) and presigned-URL signing (for the IoT MQTT-over-WSS endpoint). Ported
/// directly from `testing_utilities/kvs_livestream_test.py`'s `_publish_command` (via boto3,
/// which does request signing internally) and `_sigv4_websocket_url` — per this repo's
/// Python-script-is-the-reference convention, this is the wire format proven against real
/// AWS/firmware, not derived from the SigV4 spec alone. No AWS SDK dependency (none exists for
/// Dart with the needed coverage) — plain HMAC-SHA256 (`crypto` package).
class AwsSigV4 {
  const AwsSigV4._();

  static List<int> _hmac(List<int> key, String data) =>
      Hmac(sha256, key).convert(utf8.encode(data)).bytes;

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static String _sha256Hex(String data) => sha256.convert(utf8.encode(data)).toString();

  static List<int> _signingKey(String secretKey, String dateStamp, String region, String service) {
    List<int> key = utf8.encode('AWS4$secretKey');
    key = _hmac(key, dateStamp);
    key = _hmac(key, region);
    key = _hmac(key, service);
    key = _hmac(key, 'aws4_request');
    return key;
  }

  /// Signs an HTTPS request, returning the header map to add (`Authorization`, `X-Amz-Date`,
  /// and `X-Amz-Security-Token` when the credentials are temporary). Mirrors boto3's request
  /// signing as exercised by `_publish_command` in the Python reference — used for the IoT Data
  /// Plane `POST /topics/<topic>` publish call.
  static Map<String, String> signRequest({
    required AlertsCredentials credentials,
    required String method,
    required Uri uri,
    required String region,
    required String service,
    required String body,
    DateTime? now,
  }) {
    now = (now ?? DateTime.now()).toUtc();
    final amzDate =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
        'T${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}Z';
    final dateStamp = amzDate.substring(0, 8);
    final credentialScope = '$dateStamp/$region/$service/aws4_request';

    final canonicalHeaders = 'host:${uri.host}\nx-amz-date:$amzDate\n';
    const signedHeaders = 'host;x-amz-date';
    final payloadHash = _sha256Hex(body);
    final canonicalQuery = (uri.queryParametersAll.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)))
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.first)}')
        .join('&');
    final canonicalRequest =
        '$method\n${uri.path}\n$canonicalQuery\n$canonicalHeaders\n$signedHeaders\n$payloadHash';

    const algorithm = 'AWS4-HMAC-SHA256';
    final stringToSign =
        '$algorithm\n$amzDate\n$credentialScope\n${_sha256Hex(canonicalRequest)}';

    final signingKey = _signingKey(credentials.secretKey, dateStamp, region, service);
    final signature = _hex(_hmac(signingKey, stringToSign));

    final authorization =
        '$algorithm Credential=${credentials.accessKeyId}/$credentialScope, '
        'SignedHeaders=$signedHeaders, Signature=$signature';

    return {
      'Authorization': authorization,
      'X-Amz-Date': amzDate,
      'X-Amz-Security-Token': credentials.sessionToken,
    };
  }

  /// Presigns a `wss://` URL for AWS IoT's MQTT-over-WebSocket endpoint (query-string SigV4,
  /// not a header) — mirrors `_sigv4_websocket_url` in the Python reference exactly (same query
  /// param set/order, `iotdevicegateway` service, empty-body payload hash).
  static Uri presignWebSocketUrl({
    required AlertsCredentials credentials,
    required String endpoint,
    required String region,
    DateTime? now,
  }) {
    const service = 'iotdevicegateway';
    const algorithm = 'AWS4-HMAC-SHA256';
    now = (now ?? DateTime.now()).toUtc();
    final amzDate =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
        'T${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}Z';
    final dateStamp = amzDate.substring(0, 8);
    final credentialScope = '$dateStamp/$region/$service/aws4_request';

    final credentialParam = Uri.encodeComponent('${credentials.accessKeyId}/$credentialScope');
    var query =
        'X-Amz-Algorithm=$algorithm'
        '&X-Amz-Credential=$credentialParam'
        '&X-Amz-Date=$amzDate'
        '&X-Amz-SignedHeaders=host';

    const canonicalUri = '/mqtt';
    final payloadHash = _sha256Hex('');
    final canonicalRequest = 'GET\n$canonicalUri\n$query\nhost:$endpoint\n\nhost\n$payloadHash';
    final stringToSign =
        '$algorithm\n$amzDate\n$credentialScope\n${_sha256Hex(canonicalRequest)}';

    final signingKey = _signingKey(credentials.secretKey, dateStamp, region, service);
    final signature = _hex(_hmac(signingKey, stringToSign));

    query += '&X-Amz-Signature=$signature';
    query += '&X-Amz-Security-Token=${Uri.encodeComponent(credentials.sessionToken)}';

    return Uri.parse('wss://$endpoint$canonicalUri?$query');
  }
}
