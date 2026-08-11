// GENERATED CODE — DO NOT HAND-EDIT.
//
// Produced by tools/generate_dart_rest_client.py from design/Camera-REST-API.openapi.yaml.
// Fix the generator and re-run `python3 tools/generate_dart_rest_client.py` to regenerate.

import 'nuraeye_rest_client.dart';
import 'rest_result.dart';

class RestAlertsClient {
  RestAlertsClient(this._client);

  final NuraeyeRestClient _client;

  /// Read one detection rule's alert choices (read counterpart to POST /nuraeye/alert-rules)
  Future<RestResult<QueryAlertRuleResponse>> queryAlertRule({required String rule}) {
    final body = <String, dynamic>{
      'rule': rule,
    };
    return _client.post('/nuraeye/alert-rules/query', body).then((result) => result.map((json) => QueryAlertRuleResponse.fromJson(json)));
  }

  Future<RestResult<void>> setAlertRule({required String rule, required bool mobileNotifications, required bool buzzerActivation}) {
    final body = <String, dynamic>{
      'rule': rule,
      'mobile_notifications': mobileNotifications,
      'buzzer_activation': buzzerActivation,
    };
    return _client.post('/nuraeye/alert-rules', body);
  }
}

class QueryAlertRuleResponse {
  final bool? mobileNotifications;
  final bool? buzzerActivation;

  const QueryAlertRuleResponse({this.mobileNotifications, this.buzzerActivation});

  factory QueryAlertRuleResponse.fromJson(Map<String, dynamic> json) => QueryAlertRuleResponse(
        mobileNotifications: json['mobile_notifications'] as bool?,
        buzzerActivation: json['buzzer_activation'] as bool?,
      );
}

