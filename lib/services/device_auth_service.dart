import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 피보호자(senior) 익명 sign-in.
/// 기기마다 device_id를 생성/저장하고, Supabase 익명 세션에 연결합니다.
class DeviceAuthService {
  DeviceAuthService._();
  static final instance = DeviceAuthService._();

  static const _kDeviceId = 'jalboine.device_id';

  Future<String> _ensureDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_kDeviceId);
    if (id == null) {
      id = _gen();
      await prefs.setString(_kDeviceId, id);
    }
    return id;
  }

  String _gen() {
    final r = Random.secure();
    return List<int>.generate(16, (_) => r.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// 익명 senior 계정 보장. 이미 인증돼있으면 그대로 사용.
  Future<User> ensureSenior() async {
    final sb = Supabase.instance.client;
    final deviceId = await _ensureDeviceId();
    var user = sb.auth.currentUser;
    if (user == null) {
      final res = await sb.auth.signInAnonymously();
      user = res.user!;
    }
    await sb.from('profiles').upsert({
      'user_id': user.id,
      'role': 'senior',
      'device_id': deviceId,
    });
    await sb.from('senior_settings').upsert({'user_id': user.id});
    return user;
  }

  Future<String> deviceId() => _ensureDeviceId();
}
