enum CallAlertLevel { urgent, normal, noResponse }

CallAlertLevel parseAlertLevel(String s) => switch (s) {
      'urgent' => CallAlertLevel.urgent,
      'no_response' => CallAlertLevel.noResponse,
      _ => CallAlertLevel.normal,
    };

String alertLevelToString(CallAlertLevel l) => switch (l) {
      CallAlertLevel.urgent => 'urgent',
      CallAlertLevel.normal => 'normal',
      CallAlertLevel.noResponse => 'no_response',
    };

class CallAlert {
  final String id;
  final String seniorId;
  final String phoneNumber;
  final int? callDuration;
  final CallAlertLevel alertLevel;
  final bool dismissed;
  final DateTime createdAt;

  const CallAlert({
    required this.id,
    required this.seniorId,
    required this.phoneNumber,
    required this.alertLevel,
    required this.dismissed,
    required this.createdAt,
    this.callDuration,
  });

  factory CallAlert.fromJson(Map<String, dynamic> j) => CallAlert(
        id: j['id'] as String,
        seniorId: j['senior_id'] as String,
        phoneNumber: j['phone_number'] as String,
        callDuration: j['call_duration'] as int?,
        alertLevel: parseAlertLevel(j['alert_level'] as String),
        dismissed: (j['dismissed'] as bool?) ?? false,
        createdAt:
            DateTime.parse(j['created_at'] as String).toLocal(),
      );
}
