import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/supabase.dart';

/// 피보호자 폰 상태(배터리, 인터넷) 주기적 업로드.
/// 보호자가 senior_settings 스트림으로 받음.
class StatusSyncService {
  StatusSyncService._();
  static final instance = StatusSyncService._();

  final _battery = Battery();
  final _conn = Connectivity();
  bool _running = false;

  Future<void> pushOnce() async {
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
      await sb.from('senior_settings').update({
        'battery_pct': pct,
        'online': online,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', uid);
    } catch (_) {
      // 비치명적
    } finally {
      _running = false;
    }
  }
}
