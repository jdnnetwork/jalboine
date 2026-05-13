import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/supabase.dart';
import 'push_service.dart';
import 'sound_mode_service.dart';

/// 피보호자 폰 상태(배터리, 인터넷, 소리모드) 주기적 업로드.
/// 보호자가 senior_settings 스트림으로 받음.
class StatusSyncService {
  StatusSyncService._();
  static final instance = StatusSyncService._();

  static const _interval = Duration(minutes: 3);
  static const _kLastBatteryReported =
      'jalboine.status.last_battery_reported';

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

      // 업데이트 전에 이전 updated_at + 알림 토글 상태를 읽어 inactivity 판단
      DateTime? prevUpdatedAt;
      bool inactivityAlertOn = false;
      bool batteryAlertOn = false;
      try {
        final prev = await sb
            .from('senior_settings')
            .select('updated_at, inactivity_alert, battery_alert')
            .eq('user_id', uid)
            .maybeSingle();
        prevUpdatedAt = prev?['updated_at'] == null
            ? null
            : DateTime.parse(prev!['updated_at'] as String).toUtc();
        inactivityAlertOn = (prev?['inactivity_alert'] as bool?) ?? false;
        batteryAlertOn = (prev?['battery_alert'] as bool?) ?? false;
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

      // 푸시 best-effort
      await _maybePushBattery(
        uid: uid,
        currentPct: pct,
        enabled: batteryAlertOn,
      );
      await _maybePushInactivity(
        uid: uid,
        prevUpdatedAt: prevUpdatedAt,
        enabled: inactivityAlertOn,
      );
    } catch (_) {
      // 비치명적 — 다음 주기에 재시도
    } finally {
      _running = false;
    }
  }

  Future<void> _maybePushBattery({
    required String uid,
    required int? currentPct,
    required bool enabled,
  }) async {
    if (!enabled || currentPct == null) return;
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_kLastBatteryReported);
    await prefs.setInt(_kLastBatteryReported, currentPct);
    final crossedDown =
        currentPct <= 20 && (last == null || last > 20);
    if (!crossedDown) return;
    final gid = await _findGuardianId(uid);
    if (gid == null) return;
    await PushService.instance.sendTo(
      userId: gid,
      title: '부모님 폰 배터리가 부족해요',
      body: '현재 $currentPct% 입니다',
      data: const {'route': '/guardian/dashboard'},
    );
  }

  Future<void> _maybePushInactivity({
    required String uid,
    required DateTime? prevUpdatedAt,
    required bool enabled,
  }) async {
    if (!enabled || prevUpdatedAt == null) return;
    final gap = DateTime.now().toUtc().difference(prevUpdatedAt);
    if (gap < const Duration(hours: 12)) return;
    final gid = await _findGuardianId(uid);
    if (gid == null) return;
    final isUrgent = gap >= const Duration(hours: 24);
    await PushService.instance.sendTo(
      userId: gid,
      title: isUrgent
          ? '부모님이 24시간 이상 폰을 사용하지 않았어요. 확인이 필요합니다'
          : '부모님이 12시간 이상 폰을 사용하지 않았어요',
      body: '잘보이네 앱에서 확인하세요',
      data: const {'route': '/guardian/dashboard'},
    );
  }

  Future<String?> _findGuardianId(String seniorId) async {
    try {
      final pair = await supabaseClient
          .from('pair_links')
          .select('guardian_user_id')
          .eq('senior_user_id', seniorId)
          .eq('status', 'confirmed')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return pair?['guardian_user_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// 3분마다 senior_settings에 상태 upsert. 인터넷 안 되면 다음 주기에 재시도.
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
