// GENERATED CODE — DO NOT HAND-EDIT.
//
// Produced by tools/generate_dart_rest_client.py from design/Camera-REST-API.openapi.yaml.
// Fix the generator and re-run `python3 tools/generate_dart_rest_client.py` to regenerate.

import 'nuraeye_rest_client.dart';
import 'rest_result.dart';

class RestPrivacyClient {
  RestPrivacyClient(this._client);

  final NuraeyeRestClient _client;

  Future<RestResult<GetPrivacyModeResponse>> getPrivacyMode() {
    return _client.get('/nuraeye/privacy-mode').then((result) => result.map((json) => GetPrivacyModeResponse.fromJson(json)));
  }

  /// Setting None or Full clears all configured privacy masks as a side effect.
  Future<RestResult<void>> setPrivacyMode({required String mode}) {
    final body = <String, dynamic>{
      'mode': mode,
    };
    return _client.post('/nuraeye/privacy-mode', body);
  }
}

class GetPrivacyModeResponse {
  final String? mode;

  const GetPrivacyModeResponse({this.mode});

  factory GetPrivacyModeResponse.fromJson(Map<String, dynamic> json) => GetPrivacyModeResponse(
        mode: json['mode'] as String?,
      );
}

