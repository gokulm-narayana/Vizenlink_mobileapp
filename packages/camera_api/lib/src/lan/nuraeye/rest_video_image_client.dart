// GENERATED CODE — DO NOT HAND-EDIT.
//
// Produced by tools/generate_dart_rest_client.py from design/Camera-REST-API.openapi.yaml.
// Fix the generator and re-run `python3 tools/generate_dart_rest_client.py` to regenerate.

import 'nuraeye_rest_client.dart';
import 'rest_result.dart';

class RestVideoImageClient {
  RestVideoImageClient(this._client);

  final NuraeyeRestClient _client;

  Future<RestResult<GetImageDefaultsResponse>> getImageDefaults() {
    return _client.get('/nuraeye/video/image-defaults').then((result) => result.map((json) => GetImageDefaultsResponse.fromJson(json)));
  }

  Future<RestResult<GetMirrorFlipResponse>> getMirrorFlip() {
    return _client.get('/nuraeye/video/mirror-flip').then((result) => result.map((json) => GetMirrorFlipResponse.fromJson(json)));
  }

  Future<RestResult<GetNightVisionTypeResponse>> getNightVisionType() {
    return _client.get('/nuraeye/video/night-vision-type').then((result) => result.map((json) => GetNightVisionTypeResponse.fromJson(json)));
  }

  Future<RestResult<GetVideoModeResponse>> getVideoMode() {
    return _client.get('/nuraeye/video/mode').then((result) => result.map((json) => GetVideoModeResponse.fromJson(json)));
  }

  Future<RestResult<void>> setMirrorFlip({required String mode}) {
    final body = <String, dynamic>{
      'mode': mode,
    };
    return _client.post('/nuraeye/video/mirror-flip', body);
  }

  Future<RestResult<void>> setNightVisionType({required String type}) {
    final body = <String, dynamic>{
      'type': type,
    };
    return _client.post('/nuraeye/video/night-vision-type', body);
  }
}

class GetImageDefaultsResponse {
  final double? brightness;
  final double? contrast;
  final double? saturation;
  final double? sharpness;
  final String? whiteBalanceMode;
  final double? wbRedGain;
  final double? wbBlueGain;
  final String? exposureMode;
  final double? exposureTime;
  final double? exposureGain;

  const GetImageDefaultsResponse({this.brightness, this.contrast, this.saturation, this.sharpness, this.whiteBalanceMode, this.wbRedGain, this.wbBlueGain, this.exposureMode, this.exposureTime, this.exposureGain});

  factory GetImageDefaultsResponse.fromJson(Map<String, dynamic> json) => GetImageDefaultsResponse(
        brightness: json['brightness'] as double?,
        contrast: json['contrast'] as double?,
        saturation: json['saturation'] as double?,
        sharpness: json['sharpness'] as double?,
        whiteBalanceMode: json['white_balance_mode'] as String?,
        wbRedGain: json['wb_red_gain'] as double?,
        wbBlueGain: json['wb_blue_gain'] as double?,
        exposureMode: json['exposure_mode'] as String?,
        exposureTime: json['exposure_time'] as double?,
        exposureGain: json['exposure_gain'] as double?,
      );
}

class GetMirrorFlipResponse {
  final String? mode;

  const GetMirrorFlipResponse({this.mode});

  factory GetMirrorFlipResponse.fromJson(Map<String, dynamic> json) => GetMirrorFlipResponse(
        mode: json['mode'] as String?,
      );
}

class GetNightVisionTypeResponse {
  final String type;
  final String? subState;

  const GetNightVisionTypeResponse({required this.type, this.subState});

  factory GetNightVisionTypeResponse.fromJson(Map<String, dynamic> json) => GetNightVisionTypeResponse(
        type: json['type'] as String,
        subState: json['sub_state'] as String?,
      );
}

class GetVideoModeResponse {
  final String? configuredMode;
  final String? effectiveState;

  const GetVideoModeResponse({this.configuredMode, this.effectiveState});

  factory GetVideoModeResponse.fromJson(Map<String, dynamic> json) => GetVideoModeResponse(
        configuredMode: json['configured_mode'] as String?,
        effectiveState: json['effective_state'] as String?,
      );
}

