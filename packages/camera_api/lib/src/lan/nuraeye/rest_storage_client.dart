// GENERATED CODE — DO NOT HAND-EDIT.
//
// Produced by tools/generate_dart_rest_client.py from design/Camera-REST-API.openapi.yaml.
// Fix the generator and re-run `python3 tools/generate_dart_rest_client.py` to regenerate.

import 'nuraeye_rest_client.dart';
import 'rest_result.dart';

class RestStorageClient {
  RestStorageClient(this._client);

  final NuraeyeRestClient _client;

  Future<RestResult<GetLocalStorageResponse>> getLocalStorage() {
    return _client.get('/nuraeye/local-storage').then((result) => result.map((json) => GetLocalStorageResponse.fromJson(json)));
  }

  Future<RestResult<void>> setLocalStorage({required bool enabled}) {
    final body = <String, dynamic>{
      'enabled': enabled,
    };
    return _client.post('/nuraeye/local-storage', body);
  }
}

class GetLocalStorageResponse {
  final bool? enabled;
  final bool? cardPresent;
  final int? capacityBytes;
  final int? freeBytes;

  const GetLocalStorageResponse({this.enabled, this.cardPresent, this.capacityBytes, this.freeBytes});

  factory GetLocalStorageResponse.fromJson(Map<String, dynamic> json) => GetLocalStorageResponse(
        enabled: json['enabled'] as bool?,
        cardPresent: json['card_present'] as bool?,
        capacityBytes: json['capacity_bytes'] as int?,
        freeBytes: json['free_bytes'] as int?,
      );
}

