import 'package:flutter_test/flutter_test.dart';
import 'package:jalboine/models/senior_settings.dart';

void main() {
  test('SeniorSettings round-trips through JSON', () {
    const s = SeniorSettings(
      userId: 'u1',
      enabledApps: ['phone', 'kakao'],
      takesMedication: true,
      emergencyContacts: [
        EmergencyContact(name: '아들', phone: '01012345678'),
      ],
      guardianPinHash: 'abc',
    );
    final json = s.toJson();
    final back = SeniorSettings.fromJson(json);
    expect(back.userId, 'u1');
    expect(back.enabledApps, ['phone', 'kakao']);
    expect(back.takesMedication, isTrue);
    expect(back.emergencyContacts.first.phone, '01012345678');
    expect(back.guardianPinHash, 'abc');
  });

  test('SeniorSettings handles missing fields', () {
    final back = SeniorSettings.fromJson({'user_id': 'u2'});
    expect(back.userId, 'u2');
    expect(back.enabledApps, isEmpty);
    expect(back.takesMedication, isFalse);
    expect(back.emergencyContacts, isEmpty);
    expect(back.guardianPinHash, isNull);
  });
}
