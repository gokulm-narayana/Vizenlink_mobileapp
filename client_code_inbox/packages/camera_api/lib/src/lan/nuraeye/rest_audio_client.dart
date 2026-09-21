// GENERATED CODE — DO NOT HAND-EDIT.
//
// Produced by tools/generate_dart_rest_client.py from design/Camera-REST-API.openapi.yaml.
// Fix the generator and re-run `python3 tools/generate_dart_rest_client.py` to regenerate.

import 'nuraeye_rest_client.dart';
import 'rest_result.dart';

class RestAudioClient {
  RestAudioClient(this._client);

  final NuraeyeRestClient _client;

  Future<RestResult<GetAudioRecordingResponse>> getAudioRecording() {
    return _client.get('/nuraeye/audio/recording').then((result) => result.map((json) => GetAudioRecordingResponse.fromJson(json)));
  }

  Future<RestResult<GetAudioSettingsResponse>> getAudioSettings() {
    return _client.get('/nuraeye/audio/settings').then((result) => result.map((json) => GetAudioSettingsResponse.fromJson(json)));
  }

  Future<RestResult<GetTestSoundStatusResponse>> getTestSoundStatus() {
    return _client.get('/nuraeye/audio/test-sound').then((result) => result.map((json) => GetTestSoundStatusResponse.fromJson(json)));
  }

  Future<RestResult<void>> setAudioRecording({required bool enabled}) {
    final body = <String, dynamic>{
      'enabled': enabled,
    };
    return _client.post('/nuraeye/audio/recording', body);
  }

  Future<RestResult<void>> setAudioSettings({int? micGain, int? speakerVolume}) {
    final body = <String, dynamic>{
      if (micGain != null) 'mic_gain': micGain,
      if (speakerVolume != null) 'speaker_volume': speakerVolume,
    };
    return _client.post('/nuraeye/audio/settings', body);
  }

  Future<RestResult<void>> setTestSound({required bool active}) {
    final body = <String, dynamic>{
      'active': active,
    };
    return _client.post('/nuraeye/audio/test-sound', body);
  }
}

class GetAudioRecordingResponse {
  final bool? enabled;

  const GetAudioRecordingResponse({this.enabled});

  factory GetAudioRecordingResponse.fromJson(Map<String, dynamic> json) => GetAudioRecordingResponse(
        enabled: json['enabled'] as bool?,
      );
}

class GetAudioSettingsResponse {
  final int? micGain;
  final int? speakerVolume;

  const GetAudioSettingsResponse({this.micGain, this.speakerVolume});

  factory GetAudioSettingsResponse.fromJson(Map<String, dynamic> json) => GetAudioSettingsResponse(
        micGain: json['mic_gain'] as int?,
        speakerVolume: json['speaker_volume'] as int?,
      );
}

class GetTestSoundStatusResponse {
  final bool? playing;

  const GetTestSoundStatusResponse({this.playing});

  factory GetTestSoundStatusResponse.fromJson(Map<String, dynamic> json) => GetTestSoundStatusResponse(
        playing: json['playing'] as bool?,
      );
}

