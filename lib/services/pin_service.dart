import 'dart:convert';
import 'package:crypto/crypto.dart';

class PinService {
  static const _salt = 'jalboine_v1_pin_salt';

  static String hash(String pin) {
    final bytes = utf8.encode('$_salt:$pin');
    return sha256.convert(bytes).toString();
  }

  static bool verify(String pin, String? hashed) {
    if (hashed == null || hashed.isEmpty) return false;
    return hash(pin) == hashed;
  }
}
