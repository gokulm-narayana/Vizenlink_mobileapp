// GENERATED CODE — DO NOT HAND-EDIT.
//
// Produced by tools/generate_dart_rest_client.py from design/Camera-REST-API.openapi.yaml.
// Fix the generator and re-run `python3 tools/generate_dart_rest_client.py` to regenerate.

import 'nuraeye_rest_client.dart';
import 'rest_result.dart';

class RestStorageClient {
  RestStorageClient(this._client);

  final NuraeyeRestClient _client;

  /// Deletes specific clips by id, or every clip (FR-NE-120)
  Future<RestResult<DeleteRecordingsResponse>> deleteRecordings({List<int>? ids, bool? deleteAll}) {
    final body = <String, dynamic>{
      if (ids != null) 'ids': ids,
      if (deleteAll != null) 'delete_all': deleteAll,
    };
    return _client.post('/nuraeye/recordings/delete', body).then((result) => result.map((json) => DeleteRecordingsResponse.fromJson(json)));
  }

  Future<RestResult<GetLocalStorageResponse>> getLocalStorage() {
    return _client.get('/nuraeye/local-storage').then((result) => result.map((json) => GetLocalStorageResponse.fromJson(json)));
  }

  Future<RestResult<GetRecordingClipDurationResponse>> getRecordingClipDuration() {
    return _client.get('/nuraeye/recordings/clip-duration').then((result) => result.map((json) => GetRecordingClipDurationResponse.fromJson(json)));
  }

  Future<RestResult<GetRecordingsResponse>> getRecordings() {
    return _client.get('/nuraeye/recordings').then((result) => result.map((json) => GetRecordingsResponse.fromJson(json)));
  }

  Future<RestResult<void>> setLocalStorage({required bool enabled}) {
    final body = <String, dynamic>{
      'enabled': enabled,
    };
    return _client.post('/nuraeye/local-storage', body);
  }

  /// Sets the recorded-clip duration for future segment rotations (FR-CF-148/FR-NE-119)
  Future<RestResult<void>> setRecordingClipDuration({required int clipDurationSeconds}) {
    final body = <String, dynamic>{
      'clip_duration_seconds': clipDurationSeconds,
    };
    return _client.post('/nuraeye/recordings/clip-duration', body);
  }
}

class DeleteRecordingsResponse {
  final List<int>? deleted;
  final int? deletedCount;

  const DeleteRecordingsResponse({this.deleted, this.deletedCount});

  factory DeleteRecordingsResponse.fromJson(Map<String, dynamic> json) => DeleteRecordingsResponse(
        deleted: json['deleted'] as List<int>?,
        deletedCount: json['deleted_count'] as int?,
      );
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

class GetRecordingClipDurationResponse {
  final int? clipDurationSeconds;

  const GetRecordingClipDurationResponse({this.clipDurationSeconds});

  factory GetRecordingClipDurationResponse.fromJson(Map<String, dynamic> json) => GetRecordingClipDurationResponse(
        clipDurationSeconds: json['clip_duration_seconds'] as int?,
      );
}

class GetRecordingsRecordingsEntry {
  final int? id;
  final int? start;
  final int? end;
  final int? sizeBytes;
  final bool? active;
  final String? trigger;

  const GetRecordingsRecordingsEntry({this.id, this.start, this.end, this.sizeBytes, this.active, this.trigger});

  factory GetRecordingsRecordingsEntry.fromJson(Map<String, dynamic> json) => GetRecordingsRecordingsEntry(
        id: json['id'] as int?,
        start: json['start'] as int?,
        end: json['end'] as int?,
        sizeBytes: json['size_bytes'] as int?,
        active: json['active'] as bool?,
        trigger: json['trigger'] as String?,
      );
}

class GetRecordingsResponse {
  final bool? storageAvailable;
  final bool? cardPresent;
  final bool? truncated;
  final List<GetRecordingsRecordingsEntry>? recordings;

  const GetRecordingsResponse({this.storageAvailable, this.cardPresent, this.truncated, this.recordings});

  factory GetRecordingsResponse.fromJson(Map<String, dynamic> json) => GetRecordingsResponse(
        storageAvailable: json['storage_available'] as bool?,
        cardPresent: json['card_present'] as bool?,
        truncated: json['truncated'] as bool?,
        recordings: (json['recordings'] as List<dynamic>?)?.map((e) => GetRecordingsRecordingsEntry.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

