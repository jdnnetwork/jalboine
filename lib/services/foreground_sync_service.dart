import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

/// 잘보이네가 보호자와 연결 중임을 알리는 Foreground Service.
/// 3분 간격으로 senior_settings 테이블에 폰 상태를 업데이트한다.
class ForegroundSyncService {
  ForegroundSyncService._();
  static final instance = ForegroundSyncService._();

  static const _channelId = 'jalboine_guardian_link';
  static const _channelName = '보호자 연결';

  /// FlutterForegroundTask 채널/알림 설정. main에서 1회 호출.
  void initOptions() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: _channelName,
        channelDescription: '잘보이네가 보호자와 연결 중임을 알립니다',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        showWhen: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(180000), // 3분
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  /// 피보호자 세션이 있을 때 서비스를 시작/유지.
  Future<void> startIfNeeded() async {
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      notificationTitle: '잘보이네',
      notificationText: '잘보이네가 보호자와 연결 중입니다',
      callback: foregroundSyncCallback,
    );
  }

  Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}

/// TaskHandler 진입점 — top-level 함수여야 한다.
@pragma('vm:entry-point')
void foregroundSyncCallback() {
  FlutterForegroundTask.setTaskHandler(_SyncTaskHandler());
}

class _SyncTaskHandler extends TaskHandler {
  bool _supaReady = false;

  Future<void> _ensureSupabase() async {
    if (_supaReady) return;
    try {
      // 이미 init 됐다면 client 접근이 throw하지 않음
      Supabase.instance.client;
      _supaReady = true;
    } catch (_) {
      try {
        await Supabase.initialize(
          url: JConst.supabaseUrl,
          anonKey: JConst.supabaseAnonKey,
        );
        _supaReady = true;
      } catch (_) {}
    }
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _ensureSupabase();
    await _push();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _ensureSupabase().then((_) => _push());
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  Future<void> _push() async {
    if (!_supaReady) return;
    try {
      final sb = Supabase.instance.client;
      final uid = sb.auth.currentUser?.id;
      if (uid == null) return;
      int? pct;
      try {
        pct = await Battery().batteryLevel;
      } catch (_) {}
      bool online = true;
      try {
        final r = await Connectivity().checkConnectivity();
        online = !r.contains(ConnectivityResult.none);
      } catch (_) {}
      if (!online) return; // 다음 3분에 재시도
      await sb.from('senior_settings').update({
        'battery_pct': pct,
        'online': online,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', uid);
    } catch (_) {
      // 비치명적
    }
  }
}
