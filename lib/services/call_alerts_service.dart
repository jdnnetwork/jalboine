import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase.dart';
import '../models/call_alert.dart';
import 'push_service.dart';

class CallAlertsService {
  CallAlertsService._();
  static final instance = CallAlertsService._();

  /// 피보호자가 직접 insert. RLS상 sender_id == auth.uid().
  Future<void> insert({
    required String seniorId,
    required String phoneNumber,
    required CallAlertLevel level,
    int? durationSec,
  }) async {
    await supabaseClient.from('call_alerts').insert({
      'senior_id': seniorId,
      'phone_number': phoneNumber,
      'call_duration': durationSec,
      'alert_level': alertLevelToString(level),
    });
    await _notifyGuardian(
      seniorId: seniorId,
      level: level,
      phoneNumber: phoneNumber,
    );
  }

  /// 페어된 보호자에게 푸시. urgent 면 강한 본문, 그 외엔 기본 본문.
  Future<void> _notifyGuardian({
    required String seniorId,
    required CallAlertLevel level,
    required String phoneNumber,
  }) async {
    try {
      final sb = supabaseClient;
      final pair = await sb
          .from('pair_links')
          .select('guardian_user_id')
          .eq('senior_user_id', seniorId)
          .eq('status', 'confirmed')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final gid = pair?['guardian_user_id'] as String?;
      if (gid == null) return;
      final isUrgent = level == CallAlertLevel.urgent;
      await PushService.instance.sendTo(
        userId: gid,
        title: isUrgent ? '⚠️ 긴급! 보이스피싱 의심' : '부모님이 모르는 번호와 통화했어요',
        body: phoneNumber,
        data: const {'route': '/guardian/dashboard'},
      );
    } catch (_) {
      // best-effort
    }
  }

  /// 보호자가 dismiss.
  Future<void> dismiss(String id) async {
    await supabaseClient
        .from('call_alerts')
        .update({'dismissed': true}).eq('id', id);
  }

  /// 특정 피보호자의 미확인 알림 실시간 스트림 (최신순).
  Stream<List<CallAlert>> watchActive(String seniorId) {
    return supabaseClient
        .from('call_alerts')
        .stream(primaryKey: ['id'])
        .eq('senior_id', seniorId)
        .order('created_at')
        .map((rows) => rows
            .map(CallAlert.fromJson)
            .where((a) => !a.dismissed)
            .toList()
            .reversed
            .toList());
  }
}

/// 보호자 대시보드용: 특정 senior 의 active call_alerts.
final activeCallAlertsProvider =
    StreamProvider.family<List<CallAlert>, String>((ref, seniorId) {
  return CallAlertsService.instance.watchActive(seniorId);
});
