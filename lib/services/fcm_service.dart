import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

/// 백그라운드 메시지 핸들러 — top-level 함수여야 함.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // notification 페이로드는 Android가 자동 표시.
  // data-only 메시지는 여기서 별도 처리할 게 있다면 추가.
}

/// onTap 시 라우터로 전달할 콜백을 받아서 라우팅.
typedef PushTapHandler = void Function(Map<String, dynamic> data);

class FcmService {
  FcmService._();
  static final instance = FcmService._();

  PushTapHandler? _tapHandler;
  Map<String, dynamic>? _pendingTap;

  /// main 에서 1회 호출. Firebase.initializeApp 후에.
  Future<void> init() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // 포그라운드 수신 → 로컬 알림으로 표시
    FirebaseMessaging.onMessage.listen(_onForeground);

    // 백그라운드에서 알림 탭으로 앱 진입
    FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);

    // 앱이 죽어있다가 알림 탭으로 시작된 경우
    final initial = await messaging.getInitialMessage();
    if (initial != null) _onOpened(initial);

    // 토큰 발급 + DB 저장 + 갱신 리스너
    await _syncToken();
    messaging.onTokenRefresh.listen((_) => _syncToken());

    // 로그인 상태 바뀔 때마다 토큰 다시 sync
    Supabase.instance.client.auth.onAuthStateChange.listen((_) => _syncToken());
  }

  /// 라우터가 ready 되면 호출. 큐에 쌓인 탭이 있으면 즉시 실행.
  void registerTapHandler(PushTapHandler handler) {
    _tapHandler = handler;
    final pending = _pendingTap;
    if (pending != null) {
      _pendingTap = null;
      handler(pending);
    }
  }

  Future<void> _syncToken() async {
    try {
      final sb = Supabase.instance.client;
      final uid = sb.auth.currentUser?.id;
      if (uid == null) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await sb
          .from('profiles')
          .update({'fcm_token': token}).eq('user_id', uid);
    } catch (_) {
      // 비치명적
    }
  }

  Future<void> _onForeground(RemoteMessage m) async {
    final n = m.notification;
    if (n == null) return;
    await NotificationService.instance.plugin.show(
      m.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'jalboine_push',
          '잘보이네 알림',
          channelDescription: '잘보이네 푸시 알림 채널',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: m.data['route'] as String?,
    );
  }

  void _onOpened(RemoteMessage m) {
    final data = Map<String, dynamic>.from(m.data);
    final h = _tapHandler;
    if (h == null) {
      _pendingTap = data;
    } else {
      h(data);
    }
  }
}
