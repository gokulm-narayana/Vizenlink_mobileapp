// GENERATED CODE — DO NOT HAND-EDIT.
//
// Produced by tools/generate_dart_rest_client.py from design/Camera-REST-API.openapi.yaml.
// Fix the generator and re-run `python3 tools/generate_dart_rest_client.py` to regenerate.

import 'nuraeye_rest_client.dart';
import 'rest_result.dart';

class RestDeterrenceAlarmsClient {
  RestDeterrenceAlarmsClient(this._client);

  final NuraeyeRestClient _client;

  Future<RestResult<GetBuzzerStatusResponse>> getBuzzerStatus() {
    return _client.get('/nuraeye/buzzer').then((result) => result.map((json) => GetBuzzerStatusResponse.fromJson(json)));
  }

  /// Which deterrence action, if any, is currently active
  Future<RestResult<GetDeterrenceStatusResponse>> getDeterrenceStatus() {
    return _client.get('/nuraeye/deterrence').then((result) => result.map((json) => GetDeterrenceStatusResponse.fromJson(json)));
  }

  Future<RestResult<void>> setBuzzer({required bool active, int? durationSeconds}) {
    final body = <String, dynamic>{
      'active': active,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
    };
    return _client.post('/nuraeye/buzzer', body);
  }

  Future<RestResult<void>> setDeterrence({required String action, required bool active, int? durationSeconds}) {
    final body = <String, dynamic>{
      'action': action,
      'active': active,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
    };
    return _client.post('/nuraeye/deterrence', body);
  }
}

class GetBuzzerStatusResponse {
  final bool? active;

  const GetBuzzerStatusResponse({this.active});

  factory GetBuzzerStatusResponse.fromJson(Map<String, dynamic> json) => GetBuzzerStatusResponse(
        active: json['active'] as bool?,
      );
}

class GetDeterrenceStatusResponse {
  final bool? active;
  final String? action;

  const GetDeterrenceStatusResponse({this.active, this.action});

  factory GetDeterrenceStatusResponse.fromJson(Map<String, dynamic> json) => GetDeterrenceStatusResponse(
        active: json['active'] as bool?,
        action: json['action'] as String?,
      );
}

