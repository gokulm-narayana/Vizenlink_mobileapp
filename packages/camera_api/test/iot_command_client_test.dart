import 'package:camera_api/camera_api.dart';
import 'package:test/test.dart';

class _FakeTransport implements IotTransport {
  final List<Map<String, dynamic>> published = [];
  final List<Map<String, dynamic>> publishedAndWaited = [];

  /// Queue of responses `publishAndWait` returns, in call order — `null` means "no reply"
  /// (timeout). Defaults to a single `{"status": "ok"}` reply if left empty.
  final List<Map<String, dynamic>?> replies = [];

  @override
  Future<void> publish(String thingName, Map<String, dynamic> body) async {
    published.add(body);
  }

  @override
  Future<Map<String, dynamic>?> publishAndWait(
    String thingName,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    publishedAndWaited.add(body);
    if (replies.isEmpty) return {'status': 'ok'};
    return replies.removeAt(0);
  }
}

void main() {
  test('sendStartCloudStreaming publishes command=0, no request_id (fire-and-forget)', () async {
    final transport = _FakeTransport();
    final client = IotCommandClient('VZL-CAM-000001', transport: transport);

    await client.sendStartCloudStreaming();

    expect(transport.published, [
      {'command': IotCommandClient.startCloudStreaming},
    ]);
  });

  test('sendStopCloudStreaming publishes command=1', () async {
    final transport = _FakeTransport();
    final client = IotCommandClient('VZL-CAM-000001', transport: transport);

    await client.sendStopCloudStreaming();

    expect(transport.published, [
      {'command': IotCommandClient.stopCloudStreaming},
    ]);
  });

  test(
    'getCloudStreamingStatus goes through the generic publishAndWait request/response path '
    '(command=4)',
    () async {
      final transport = _FakeTransport()
        ..replies.add({
          'status': 'ok',
          'output': {'stream_status': 'active'},
        });
      final client = IotCommandClient('VZL-CAM-000001', transport: transport);

      final output = await client.sendCommandWithResponse(IotCommandClient.getCloudStreamingStatus);

      expect(transport.publishedAndWaited.single['command'], IotCommandClient.getCloudStreamingStatus);
      expect(output, {'stream_status': 'active'});
    },
  );

  test('a camera-side failure (status != ok) throws', () async {
    final transport = _FakeTransport()..replies.add({'status': 'error'});
    final client = IotCommandClient('VZL-CAM-000001', transport: transport);

    expect(
      client.sendCommandWithResponse(IotCommandClient.setMirrorFlip),
      throwsA(predicate((e) => e.toString().contains('failed on camera'))),
    );
  });

  test(
    'sendCommandWithResponse includes command+params and returns the output object',
    () async {
      final transport = _FakeTransport()
        ..replies.add({
          'status': 'ok',
          'output': {'type': 'Grey', 'color_capable': true, 'smart_capable': false},
        });
      final client = IotCommandClient('VZL-CAM-000001', transport: transport);

      final output = await client.sendCommandWithResponse(
        IotCommandClient.setNightVisionType,
        params: {'type': 'Grey'},
      );

      final body = transport.publishedAndWaited.single;
      expect(body['command'], IotCommandClient.setNightVisionType);
      expect(body['params'], {'type': 'Grey'});
      expect(body['request_id'], isNotNull);
      expect(output, {'type': 'Grey', 'color_capable': true, 'smart_capable': false});
    },
  );

  test(
    'a timeout (no reply) is retried once — a second-attempt reply succeeds without the '
    'caller ever seeing the timeout',
    () async {
      final transport = _FakeTransport()
        ..replies.add(null)
        ..replies.add({
          'status': 'ok',
          'output': {'mode': 'Both'},
        });
      final client = IotCommandClient('VZL-CAM-000001', transport: transport);

      final output = await client.sendCommandWithResponse(IotCommandClient.getMirrorFlip);

      expect(transport.publishedAndWaited.length, 2);
      expect(output, {'mode': 'Both'});
    },
  );

  test('a second consecutive timeout is not retried again — it is surfaced', () async {
    final transport = _FakeTransport()
      ..replies.add(null)
      ..replies.add(null);
    final client = IotCommandClient('VZL-CAM-000001', transport: transport);

    await expectLater(
      client.sendCommandWithResponse(IotCommandClient.getMirrorFlip),
      throwsA(predicate((e) => e.toString().contains('timed out'))),
    );
    expect(transport.publishedAndWaited.length, 2);
  });

  test('a genuine camera-side failure is not retried', () async {
    final transport = _FakeTransport()..replies.add({'status': 'error'});
    final client = IotCommandClient('VZL-CAM-000001', transport: transport);

    await expectLater(
      client.sendCommandWithResponse(IotCommandClient.setMirrorFlip),
      throwsA(predicate((e) => e.toString().contains('failed on camera'))),
    );
    expect(transport.publishedAndWaited.length, 1);
  });

  test('sendCommandWithResponse omits params entirely when none are given', () async {
    final transport = _FakeTransport()
      ..replies.add({
        'status': 'ok',
        'output': {'type': 'Grey'},
      });
    final client = IotCommandClient('VZL-CAM-000001', transport: transport);

    await client.sendCommandWithResponse(IotCommandClient.getNightVisionType);

    expect(transport.publishedAndWaited.single.containsKey('params'), isFalse);
  });

  test(
    'a successful reply with no output field (every Set*/Delete* command\'s real shape) '
    'returns an empty map, not null — null must mean "no reply arrived", never "arrived with '
    'nothing to report" (regression: every WAN Set*/Delete* client checks output == null to '
    'mean timeout, so this used to misreport every successful Set as a timeout once the '
    'Lambda relay — which used to default this itself — was removed)',
    () async {
      final transport = _FakeTransport()..replies.add({'status': 'ok'});
      final client = IotCommandClient('VZL-CAM-000001', transport: transport);

      final output = await client.sendCommandWithResponse(IotCommandClient.setCameraLocation);

      expect(output, isNotNull);
      expect(output, <String, dynamic>{});
    },
  );

  test('each command gets a fresh, distinct request_id', () async {
    final transport = _FakeTransport();
    final client = IotCommandClient('VZL-CAM-000001', transport: transport);

    await client.sendCommandWithResponse(IotCommandClient.getMirrorFlip);
    await client.sendCommandWithResponse(IotCommandClient.getMirrorFlip);

    final ids = transport.publishedAndWaited.map((b) => b['request_id']).toSet();
    expect(ids.length, 2);
  });
}
