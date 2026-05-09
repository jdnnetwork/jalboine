import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase.dart';

/// Supabase Edge Function `send-push` 를 호출해 FCM 푸시를 발송한다.
/// 호출은 best-effort — 실패해도 throw 하지 않음 (앱 동작 차단 X).
class PushService {
  PushService._();
  static final instance = PushService._();

  Future<void> sendTo({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      await supabaseClient.functions.invoke(
        'send-push',
        body: {
          'user_id': userId,
          'title': title,
          'body': body,
          'data': data ?? const <String, String>{},
        },
      );
    } on FunctionException catch (_) {
      // 함수 미배포/실패 — 무시
    } catch (_) {
      // 네트워크 등 — 무시
    }
  }
}
