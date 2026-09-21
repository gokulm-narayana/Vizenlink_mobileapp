import 'dart:async';
import 'dart:io';

import 'package:camera_api/src/lan/insecure_camera_http_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

/// Regression test for `BUG-008` Iteration 3 (and the original `BUG-005`): `package:http`'s
/// `IOClient` lowercases outgoing header names by default, and this camera's embedded HTTP
/// server looks headers up case-sensitively. A mocked (`http.testing.MockClient`) test can't
/// catch this — a mock never serializes a real request, so it can't observe what actually hits
/// the wire — and `dart:io`'s own `HttpServer` API normalizes header-name case on read, so even
/// a real loopback `HttpServer` can't prove this either. A raw `ServerSocket`, inspecting the
/// literal bytes received, is the only way to see the real wire case.
void main() {
  test(
    'createCameraHttpClient() sends "Authorization" verbatim on the wire, not "authorization"',
    () async {
      final serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final rawRequestFuture = serverSocket.first.then((socket) async {
        final bytes = <int>[];
        await for (final chunk in socket) {
          bytes.addAll(chunk);
          if (String.fromCharCodes(bytes).contains('\r\n\r\n')) break;
        }
        socket.add('HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n'.codeUnits);
        await socket.flush();
        await socket.close();
        return String.fromCharCodes(bytes);
      });

      final client = createCameraHttpClient();
      addTearDown(client.close);
      // The raw socket's canned response is minimal, not a fully package:http-parseable
      // response in every environment — irrelevant here, only the *request* bytes the server
      // captured matter for this assertion, so any client-side parse failure is ignored.
      unawaited(
        client
            .get(
              Uri.http('${serverSocket.address.address}:${serverSocket.port}', '/probe'),
              headers: {'Authorization': 'Bearer test-token'},
            )
            .catchError((_) => http.Response('', 200)),
      );

      final rawRequest = await rawRequestFuture.timeout(const Duration(seconds: 5));
      await serverSocket.close();

      expect(rawRequest, contains('Authorization: Bearer test-token'));
      expect(rawRequest, isNot(contains('authorization: Bearer test-token')));
    },
  );
}
