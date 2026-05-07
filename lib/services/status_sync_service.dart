import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/supabase.dart';
import 'sound_mode_service.dart';

/// 피보호자 폰 상태(배터리, 인터넷, 소리모드) 주기적 업로드.
/// 보호자가 senior_settings 스트림으로 받음.
class StatusSyncService {
  StatusSyncService._();
  static final instance = StatusSyncService._();

  static const _interval = Duration(minutes: 5);

  final _battery = Battery();
  final _conn = Connectivity();
  bool _running = false;
  Timer? _timer;

  Future<void> pushOnce({SoundMode? soundMode}) async {
    if (_running) return;
    _running = true;
    try {
      final sb = supabaseClient;
      final uid = sb.auth.currentUser?.id;
      if (uid == null) return;
      int? pct;
      try {
        pct = await _battery.batteryLevel;
      } catch (_) {}
      bool online = true;
      try {
        final r = await _conn.checkConnectivity();
        online = !r.contains(ConnectivityResult.none);
      } catch (_) {}
      final payload = <String, dynamic>{
        'battery_pct': pct,
        'online': online,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (soundMode != null) {
        payload['sound_mode'] = soundMode.id;
      }
      await sb.from('senior_settings').update(payload).eq('user_id', uid);
    } catch (_) {
      // 비치명적 — 다음 주기에 재시도
    } finally {
      _running = false;
    }
  }

  /// 5분마다 senior_settings에 상태 upsert. 인터넷 안 되면 다음 5분에 재시도.
  void startPeriodic() {
    _timer?.cancel();
    pushOnce();
    _timer = Timer.periodic(_interval, (_) => pushOnce());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
