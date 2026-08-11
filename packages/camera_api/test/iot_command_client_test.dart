import 'dart:convert';

import 'package:camera_api/camera_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('sendStartCloudStreaming POSTs a publishCommand action to the Lambda with command=0', () async {
    http.Request? captured;
    final client = IotCommandClient(
      'VZL-CAM-000001',
      idTokenProvider: () => 'fake-id-token',
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response('{"published":true}', 200);
      }),
    );

    await client.sendStartCloudStreaming();

    expect(captured, isNotNull);
    expect(captured!.method, 'POST');
    expect(captured!.headers['Authorization'], 'Bearer fake-id-token');
    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body['action'], 'publishCommand');
    expect(body['thingName'], 'VZL-CAM-000001');
    expect(body['command'], 0);
  });

  test('sendStopCloudStreaming POSTs command=1', () async {
    http.Request? captured;
    final client = IotCommandClient(
      'VZL-CAM-000001',
      idTokenProvider: () => 'fake-id-token',
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response('{"published":true}', 200);
      }),
    );

    await client.sendStopCloudStreaming();

    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body['command'], 1);
  });

  test(
    'getCloudStreamingStatus goes through the generic commandWithResponse relay (command=4), '
    'not a dedicated Lambda action — removed 2026-08-06 so the Lambda stays independent of '
    'firmware-specific command semantics',
    () async {
      http.Request? captured;
      final client = IotCommandClient(
        'VZL-CAM-000001',
        idTokenProvider: () => 'fake-id-token',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response('{"output":{"stream_status":"active"}}', 200);
        }),
      );

      final output = await client.sendCommandWithResponse(
        IotCommandClient.getCloudStreamingStatus,
      );

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['action'], 'commandWithResponse');
      expect(body['command'], 4);
      expect(output, {'stream_status': 'active'});
    },
  );

  test('a non-200 relay response throws with the Lambda\'s error message', () async {
    final client = IotCommandClient(
      'VZL-CAM-000001',
      idTokenProvider: () => 'fake-id-token',
      httpClient: MockClient((request) async => http.Response('{"error":"IoT publish failed: boom"}', 502)),
    );

    expect(
      client.sendStartCloudStreaming(),
      throwsA(predicate((e) => e.toString().contains('IoT publish failed: boom'))),
    );
  });

  test('throws StateError when unauthenticated (no ID token)', () async {
    final client = IotCommandClient('VZL-CAM-000001', idTokenProvider: () => null);

    expect(client.sendStartCloudStreaming(), throwsStateError);
  });

  test(
    'sendCommandWithResponse POSTs a commandWithResponse action with command+params and '
    'returns the output object',
    () async {
      http.Request? captured;
      final client = IotCommandClient(
        'VZL-CAM-000001',
        idTokenProvider: () => 'fake-id-token',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(
            '{"output":{"type":"Grey","color_capable":true,"smart_capable":false}}',
            200,
          );
        }),
      );

      final output = await client.sendCommandWithResponse(
        IotCommandClient.setNightVisionType,
        params: {'type': 'Grey'},
      );

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['action'], 'commandWithResponse');
      expect(body['thingName'], 'VZL-CAM-000001');
      expect(body['command'], IotCommandClient.setNightVisionType);
      expect(body['params'], {'type': 'Grey'});
      expect(output, {'type': 'Grey', 'color_capable': true, 'smart_capable': false});
    },
  );

  test(
    'a 504 (Lambda timeout) is retried once — a second-attempt 200 succeeds without the '
    'caller ever seeing the timeout',
    () async {
      var callCount = 0;
      final client = IotCommandClient(
        'VZL-CAM-000001',
        idTokenProvider: () => 'fake-id-token',
        httpClient: MockClient((request) async {
          callCount++;
          if (callCount == 1) {
            return http.Response('{"error":"No response from camera (timed out)"}', 504);
          }
          return http.Response('{"output":{"mode":"Both"}}', 200);
        }),
      );

      final output = await client.sendCommandWithResponse(IotCommandClient.getMirrorFlip);

      expect(callCount, 2);
      expect(output, {'mode': 'Both'});
    },
  );

  test('a second consecutive 504 is not retried again — the timeout is surfaced', () async {
    var callCount = 0;
    final client = IotCommandClient(
      'VZL-CAM-000001',
      idTokenProvider: () => 'fake-id-token',
      httpClient: MockClient((request) async {
        callCount++;
        return http.Response('{"error":"No response from camera (timed out)"}', 504);
      }),
    );

    expect(
      client.sendCommandWithResponse(IotCommandClient.getMirrorFlip),
      throwsA(predicate((e) => e.toString().contains('timed out'))),
    );
    await Future<void>.delayed(Duration.zero);
    expect(callCount, 2);
  });

  test('a genuine camera-side failure (502) is not retried', () async {
    var callCount = 0;
    final client = IotCommandClient(
      'VZL-CAM-000001',
      idTokenProvider: () => 'fake-id-token',
      httpClient: MockClient((request) async {
        callCount++;
        return http.Response('{"error":"Command 11 failed on camera"}', 502);
      }),
    );

    expect(
      client.sendCommandWithResponse(IotCommandClient.setMirrorFlip),
      throwsA(predicate((e) => e.toString().contains('failed on camera'))),
    );
    await Future<void>.delayed(Duration.zero);
    expect(callCount, 1);
  });

  test('sendCommandWithResponse omits params entirely when none are given', () async {
    http.Request? captured;
    final client = IotCommandClient(
      'VZL-CAM-000001',
      idTokenProvider: () => 'fake-id-token',
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response('{"output":{"type":"Grey"}}', 200);
      }),
    );

    await client.sendCommandWithResponse(IotCommandClient.getNightVisionType);

    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body.containsKey('params'), isFalse);
  });
}
