import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// FCM 포그라운드 알림 표시 등 외부에서 plugin 직접 사용 시.
  FlutterLocalNotificationsPlugin get plugin => _plugin;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    } catch (_) {
      // 폴백: UTC
    }
    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(
      init,
      onDidReceiveNotificationResponse: _onTap,
    );
    await Permission.notification.request();
    _ready = true;
  }

  static void _onTap(NotificationResponse r) {
    // payload로 라우터 진입 가능 (생략)
  }

  Future<void> rescheduleMedications(List<String> times) async {
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    int id = 100;
    for (final t in times) {
      final parts = t.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      var when =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
      if (when.isBefore(now)) when = when.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        id++,
        '약 드실 시간이에요!',
        '약을 드세요',
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'med_alarm',
            '약 알림',
            channelDescription: '약 복용 시간 알림',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'med_alarm',
      );
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> snooze10min() async {
    final when =
        tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10));
    await _plugin.zonedSchedule(
      999,
      '약 드실 시간이에요!',
      '아직 약을 드시지 않았어요',
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'med_alarm',
          '약 알림',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'med_alarm',
    );
  }
}
