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

  /// Camera-reported valid min/max range for each deterrence duration/count key
  Future<RestResult<GetDeterrenceDurationOptionsResponse>> getDeterrenceDurationOptions() {
    return _client.get('/nuraeye/deterrence/durations/options').then((result) => result.map((json) => GetDeterrenceDurationOptionsResponse.fromJson(json)));
  }

  /// Persisted, per-action auto-stop configuration for each deterrence action
  Future<RestResult<GetDeterrenceDurationsResponse>> getDeterrenceDurations() {
    return _client.get('/nuraeye/deterrence/durations').then((result) => result.map((json) => GetDeterrenceDurationsResponse.fromJson(json)));
  }

  /// Each deterrence action's own independent active/inactive state
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

  /// No duration_seconds field (removed FEAT-236, 2026-08-14) — the camera applies its own persisted, per-action duration instead, see /nuraeye/deterrence/durations.
  Future<RestResult<void>> setDeterrence({required String action, required bool active}) {
    final body = <String, dynamic>{
      'action': action,
      'active': active,
    };
    return _client.post('/nuraeye/deterrence', body);
  }

  /// Partial update — any subset of the three keys. 0-255 below is only the wire type's outer bound; the real accepted range per key comes from /nuraeye/deterrence/durations/options and is enforced server-side (2026-08-15).
  Future<RestResult<void>> setDeterrenceDurations({int? sirenSeconds, int? spotlightSeconds, int? warningRepeatCount}) {
    final body = <String, dynamic>{
      if (sirenSeconds != null) 'siren_seconds': sirenSeconds,
      if (spotlightSeconds != null) 'spotlight_seconds': spotlightSeconds,
      if (warningRepeatCount != null) 'warning_repeat_count': warningRepeatCount,
    };
    return _client.post('/nuraeye/deterrence/durations', body);
  }
}

class GetBuzzerStatusResponse {
  final bool? active;

  const GetBuzzerStatusResponse({this.active});

  factory GetBuzzerStatusResponse.fromJson(Map<String, dynamic> json) => GetBuzzerStatusResponse(
        active: json['active'] as bool?,
      );
}

class GetDeterrenceDurationOptionsResponse {
  final int? sirenSecondsMin;
  final int? sirenSecondsMax;
  final int? spotlightSecondsMin;
  final int? spotlightSecondsMax;
  final int? warningRepeatCountMin;
  final int? warningRepeatCountMax;

  const GetDeterrenceDurationOptionsResponse({this.sirenSecondsMin, this.sirenSecondsMax, this.spotlightSecondsMin, this.spotlightSecondsMax, this.warningRepeatCountMin, this.warningRepeatCountMax});

  factory GetDeterrenceDurationOptionsResponse.fromJson(Map<String, dynamic> json) => GetDeterrenceDurationOptionsResponse(
        sirenSecondsMin: json['siren_seconds_min'] as int?,
        sirenSecondsMax: json['siren_seconds_max'] as int?,
        spotlightSecondsMin: json['spotlight_seconds_min'] as int?,
        spotlightSecondsMax: json['spotlight_seconds_max'] as int?,
        warningRepeatCountMin: json['warning_repeat_count_min'] as int?,
        warningRepeatCountMax: json['warning_repeat_count_max'] as int?,
      );
}

class GetDeterrenceDurationsResponse {
  final int? sirenSeconds;
  final int? spotlightSeconds;
  final int? warningRepeatCount;

  const GetDeterrenceDurationsResponse({this.sirenSeconds, this.spotlightSeconds, this.warningRepeatCount});

  factory GetDeterrenceDurationsResponse.fromJson(Map<String, dynamic> json) => GetDeterrenceDurationsResponse(
        sirenSeconds: json['siren_seconds'] as int?,
        spotlightSeconds: json['spotlight_seconds'] as int?,
        warningRepeatCount: json['warning_repeat_count'] as int?,
      );
}

class GetDeterrenceStatusResponse {
  final bool? siren;
  final bool? spotlight;
  final bool? warning;

  const GetDeterrenceStatusResponse({this.siren, this.spotlight, this.warning});

  factory GetDeterrenceStatusResponse.fromJson(Map<String, dynamic> json) => GetDeterrenceStatusResponse(
        siren: json['siren'] as bool?,
        spotlight: json['spotlight'] as bool?,
        warning: json['warning'] as bool?,
      );
}

