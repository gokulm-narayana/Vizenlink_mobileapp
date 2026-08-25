// GENERATED CODE — DO NOT HAND-EDIT.
//
// Produced by tools/generate_dart_rest_client.py from design/Camera-REST-API.openapi.yaml.
// Fix the generator and re-run `python3 tools/generate_dart_rest_client.py` to regenerate.

import 'nuraeye_rest_client.dart';
import 'rest_result.dart';

class RestStreamingClient {
  RestStreamingClient(this._client);

  final NuraeyeRestClient _client;

  Future<RestResult<GetCloudStreamingStatusResponse>> getCloudStreamingStatus() {
    return _client.get('/nuraeye/cloud/streaming').then((result) => result.map((json) => GetCloudStreamingStatusResponse.fromJson(json)));
  }

  /// Fetch the camera-generated shared key for end-to-end-encrypted WAN preview snapshots
  Future<RestResult<GetPreviewKeyResponse>> getPreviewKey() {
    return _client.get('/nuraeye/preview-key').then((result) => result.map((json) => GetPreviewKeyResponse.fromJson(json)));
  }

  /// Resolve the LAN WebRTC signaling URI for a stream profile
  Future<RestResult<GetWebRtcUriResponse>> getWebRtcUri({required String profileToken}) {
    final body = <String, dynamic>{
      'profile_token': profileToken,
    };
    return _client.post('/nuraeye/webrtc-uri', body).then((result) => result.map((json) => GetWebRtcUriResponse.fromJson(json)));
  }

  Future<RestResult<void>> stopCloudStreaming() {
    final body = <String, dynamic>{'active': false};
    return _client.post('/nuraeye/cloud/streaming', body);
  }
}

class GetCloudStreamingStatusResponse {
  final String? streamStatus;

  const GetCloudStreamingStatusResponse({this.streamStatus});

  factory GetCloudStreamingStatusResponse.fromJson(Map<String, dynamic> json) => GetCloudStreamingStatusResponse(
        streamStatus: json['stream_status'] as String?,
      );
}

class GetPreviewKeyResponse {
  final String? key;

  const GetPreviewKeyResponse({this.key});

  factory GetPreviewKeyResponse.fromJson(Map<String, dynamic> json) => GetPreviewKeyResponse(
        key: json['key'] as String?,
      );
}

class GetWebRtcUriResponse {
  final int? port;
  final String? url;

  const GetWebRtcUriResponse({this.port, this.url});

  factory GetWebRtcUriResponse.fromJson(Map<String, dynamic> json) => GetWebRtcUriResponse(
        port: json['port'] as int?,
        url: json['url'] as String?,
      );
}

