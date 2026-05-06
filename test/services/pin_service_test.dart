import 'package:flutter_test/flutter_test.dart';
import 'package:jalboine/services/pin_service.dart';

void main() {
  test('hash and verify match', () {
    final h = PinService.hash('1234');
    expect(PinService.verify('1234', h), isTrue);
    expect(PinService.verify('0000', h), isFalse);
  });

  test('verify returns false for null/empty hash', () {
    expect(PinService.verify('1234', null), isFalse);
    expect(PinService.verify('1234', ''), isFalse);
  });
}
