import 'dart:convert';

import 'package:camera_api/camera_api.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// Computes the same digest the camera firmware computes server-side
/// (`digest_utils_computeOnvifSHA256Digest`, actually SHA-1 despite the name) — mirrors
/// `nuraeye/nuraeye.c:1745`/`1762`'s construction exactly, so these tests exercise the same
/// verification path a real camera reply would.
String _serverDigest(String plaintext, String nonceBase64, String created) {
  final input = <int>[
    ...base64.decode(nonceBase64),
    ...utf8.encode(created),
    ...utf8.encode(plaintext),
  ];
  return base64.encode(sha1.convert(input).bytes);
}

void main() {
  test('areYouNuraeyeDevice succeeds against a correctly-signed reply', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: '', password: ''),
      httpClient: MockClient((request) async {
        expect(request.url.path, '/nuraeye/identity');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        // Firmware verifies the request's digest is a digest of the fixed challenge password —
        // confirm the client sent that, not the connection's (empty) real password.
        expect(
          body['digest'],
          _serverDigest('are-you-onchip-nuraeye', body['nonce'] as String, body['created'] as String),
        );
        final reply = _serverDigest(
          'yes-i-am-onchip-nuraeye',
          body['nonce'] as String,
          body['created'] as String,
        );
        return http.Response(
          jsonEncode({'error_code': 0, 'error_msg': 'Success', 'output': {'reply': reply}}),
          200,
        );
      }),
    );

    final result = await nuraeye.areYouNuraeyeDevice();

    expect(result, isA<CameraSuccess<bool>>());
    expect((result as CameraSuccess<bool>).value, isTrue);
  });

  test('areYouNuraeyeDevice returns false for a wrong reply digest', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: '', password: ''),
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({'error_code': 0, 'error_msg': 'Success', 'output': {'reply': 'not-a-real-digest'}}),
          200,
        );
      }),
    );

    final result = await nuraeye.areYouNuraeyeDevice();

    expect(result, isA<CameraSuccess<bool>>());
    expect((result as CameraSuccess<bool>).value, isFalse);
  });

  test('areYouNuraeyeDevice fails on HTTP 401 (not this camera / rejected)', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: '', password: ''),
      httpClient: MockClient((request) async => http.Response('{"error_code":401,"error_msg":"no","output":{}}', 401)),
    );

    final result = await nuraeye.areYouNuraeyeDevice();

    expect(result, isA<CameraFailure<bool>>());
  });

  test('areYouNuraeyeDeviceWithRetry succeeds on a later attempt after earlier ones fail', () async {
    var callCount = 0;
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: '', password: ''),
      httpClient: MockClient((request) async {
        callCount++;
        // First two attempts simulate the cold-WiFi-connection failure this method exists to
        // absorb; the third succeeds, same as the real device did once the connection warmed up.
        if (callCount < 3) {
          return http.Response('{"error_code":500,"error_msg":"no","output":{}}', 500);
        }
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final reply = _serverDigest(
          'yes-i-am-onchip-nuraeye',
          body['nonce'] as String,
          body['created'] as String,
        );
        return http.Response(
          jsonEncode({'error_code': 0, 'error_msg': 'Success', 'output': {'reply': reply}}),
          200,
        );
      }),
    );

    final result = await nuraeye.areYouNuraeyeDeviceWithRetry(
      retryDelay: Duration.zero,
    );

    expect(result, isA<CameraSuccess<bool>>());
    expect((result as CameraSuccess<bool>).value, isTrue);
    expect(callCount, 3);
  });

  test('areYouNuraeyeDeviceWithRetry returns the last failure once every attempt is exhausted', () async {
    var callCount = 0;
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: '', password: ''),
      httpClient: MockClient((request) async {
        callCount++;
        return http.Response('{"error_code":401,"error_msg":"no","output":{}}', 401);
      }),
    );

    final result = await nuraeye.areYouNuraeyeDeviceWithRetry(
      attempts: 3,
      retryDelay: Duration.zero,
    );

    expect(result, isA<CameraFailure<bool>>());
    expect(callCount, 3);
  });

  test('areYouNuraeyeDeviceWithRetry does not retry once genuine on the first attempt', () async {
    var callCount = 0;
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: '', password: ''),
      httpClient: MockClient((request) async {
        callCount++;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final reply = _serverDigest(
          'yes-i-am-onchip-nuraeye',
          body['nonce'] as String,
          body['created'] as String,
        );
        return http.Response(
          jsonEncode({'error_code': 0, 'error_msg': 'Success', 'output': {'reply': reply}}),
          200,
        );
      }),
    );

    final result = await nuraeye.areYouNuraeyeDeviceWithRetry(retryDelay: Duration.zero);

    expect(result, isA<CameraSuccess<bool>>());
    expect(callCount, 1);
  });
}
