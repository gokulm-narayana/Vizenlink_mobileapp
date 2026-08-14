import 'package:alerts_api/alerts_api.dart';
import 'package:alerts_api/src/aws_sigv4.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cross-checked byte-for-byte against an independent Python implementation of the same SigV4
/// algorithm (fixed AWS SigV4 test-suite credentials, `AKIDEXAMPLE`/
/// `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`, fixed timestamp `20250830T123600Z`) — this exists
/// because `AwsSigV4` has no automated coverage otherwise and a signing bug would only surface
/// as an opaque 403 against real AWS, with no way to localize which of the two algorithms
/// (request vs. presigned-URL signing) or which step was wrong.
void main() {
  final credentials = AlertsCredentials(
    accessKeyId: 'AKIDEXAMPLE',
    secretKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
    sessionToken: 'TOKEN123',
    expiresAt: DateTime.utc(2025, 8, 30, 13, 36, 0),
  );
  final fixedNow = DateTime.utc(2025, 8, 30, 12, 36, 0);

  test('presignWebSocketUrl matches the Python reference implementation byte-for-byte', () {
    final url = AwsSigV4.presignWebSocketUrl(
      credentials: credentials,
      endpoint: 'a1b2c3d4e5.iot.ap-south-1.amazonaws.com',
      region: 'ap-south-1',
      now: fixedNow,
    );

    expect(
      url.toString(),
      'wss://a1b2c3d4e5.iot.ap-south-1.amazonaws.com/mqtt?'
      'X-Amz-Algorithm=AWS4-HMAC-SHA256'
      '&X-Amz-Credential=AKIDEXAMPLE%2F20250830%2Fap-south-1%2Fiotdevicegateway%2Faws4_request'
      '&X-Amz-Date=20250830T123600Z'
      '&X-Amz-SignedHeaders=host'
      '&X-Amz-Signature=be1222ca7aa460c77de86e0449ace2e8e8822bfc71216828ff2213bfd90bb40b'
      '&X-Amz-Security-Token=TOKEN123',
    );
  });

  test('signRequest matches the Python reference implementation byte-for-byte', () {
    final headers = AwsSigV4.signRequest(
      credentials: credentials,
      method: 'POST',
      uri: Uri.parse(
        'https://a1b2c3d4e5.iot.ap-south-1.amazonaws.com/topics/vizenlink/command/VZL-CAM-000001?qos=1',
      ),
      region: 'ap-south-1',
      service: 'iotdata',
      body: '{"command":0}',
      now: fixedNow,
    );

    expect(
      headers['Authorization'],
      'AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20250830/ap-south-1/iotdata/aws4_request, '
      'SignedHeaders=host;x-amz-date, '
      'Signature=87d40feb85ad5df3748e85302e66960f8fdc943e9e2e879a5630af46858773f6',
    );
    expect(headers['X-Amz-Date'], '20250830T123600Z');
    expect(headers['X-Amz-Security-Token'], 'TOKEN123');
  });
}
