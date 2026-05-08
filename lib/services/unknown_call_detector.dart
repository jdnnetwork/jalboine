import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'call_log_service.dart';

/// 모르는 번호 감지 결과 — 가장 최근 1건만 반환하는 게 호출부 입장에서 단순.
class UnknownCallHit {
  final String number;
  final DateTime timestamp;
  final int durationSec;
  const UnknownCallHit({
    required this.number,
    required this.timestamp,
    required this.durationSec,
  });
}

class UnknownCallDetector {
  UnknownCallDetector._();
  static final instance = UnknownCallDetector._();

  static const _kLastCheck = 'jalboine.call_log_last_check_ms';

  Future<bool> hasPermissions() async {
    final c1 = await Permission.phone.status; // READ_CALL_LOG (permission_handler 11+)
    final c2 = await Permission.contacts.status;
    return c1.isGranted && c2.isGranted;
  }

  /// 마지막 체크 이후의 새로운 모르는 번호 통화 1건 반환. 없으면 null.
  /// 호출 후 last-check 타임스탬프는 자동 업데이트.
  Future<UnknownCallHit?> checkOnce() async {
    if (!await hasPermissions()) return null;
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_kLastCheck) ??
        DateTime.now()
            .subtract(const Duration(minutes: 5))
            .millisecondsSinceEpoch;
    final since = DateTime.fromMillisecondsSinceEpoch(lastMs);
    final calls = await CallLogService.instance.recentCallsSince(since);
    // 이번 체크 윈도우 끝 갱신은 호출 직후 = now
    await prefs.setInt(
      _kLastCheck,
      DateTime.now().millisecondsSinceEpoch,
    );
    if (calls.isEmpty) return null;
    // 최신 → 오래된 순. 첫 번째 모르는 번호를 반환.
    for (final c in calls) {
      final known = await CallLogService.instance.isKnownNumber(c.number);
      if (!known) {
        return UnknownCallHit(
          number: c.number,
          timestamp: c.timestamp,
          durationSec: c.durationSec,
        );
      }
    }
    return null;
  }

  /// 권한 허용된 적 없도록 last-check 초기화 (권한 안내 직후 호출).
  Future<void> resetLastCheck() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _kLastCheck,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
