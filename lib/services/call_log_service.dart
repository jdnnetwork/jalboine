import 'package:flutter/services.dart';

class RecentCall {
  final String number;
  final DateTime timestamp;
  final int durationSec;
  final int type; // 1=incoming, 2=outgoing, 3=missed (Android 표준)
  const RecentCall({
    required this.number,
    required this.timestamp,
    required this.durationSec,
    required this.type,
  });
}

class CallLogService {
  CallLogService._();
  static final instance = CallLogService._();

  static const _ch = MethodChannel('com.jalboine/call_log');

  /// [since] 이후의 통화 기록을 최신순으로 반환. 권한 없으면 빈 리스트.
  Future<List<RecentCall>> recentCallsSince(DateTime since) async {
    try {
      final list = await _ch.invokeListMethod<dynamic>(
        'getRecentCalls',
        {'sinceMs': since.millisecondsSinceEpoch},
      );
      if (list == null) return const [];
      return list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return RecentCall(
          number: (m['number'] as String?) ?? '',
          timestamp:
              DateTime.fromMillisecondsSinceEpoch((m['timestampMs'] as num).toInt()),
          durationSec: (m['durationSec'] as num?)?.toInt() ?? 0,
          type: (m['type'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }

  /// 연락처에 있으면 true. 권한 없으면 true (오탐 방지).
  Future<bool> isKnownNumber(String number) async {
    try {
      final r = await _ch.invokeMethod<bool>('isKnownNumber', {
        'number': number,
      });
      return r ?? true;
    } on PlatformException {
      return true;
    } on MissingPluginException {
      return true;
    }
  }
}
