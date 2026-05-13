import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase.dart';
import '../models/message.dart';
import 'push_service.dart';

class MessagesService {
  MessagesService._();
  static final instance = MessagesService._();

  static const monthlyTextLimit = 50;
  static const monthlyImageLimit = 10;
  static const _bucket = 'message-images';

  /// 현재 사용자와 1:1로 이어진 상대(보호자/피보호자) 의 user_id.
  /// pair_links 테이블에서 accepted 상태의 상대를 찾는다.
  Future<String?> findPartnerId() async {
    final sb = supabaseClient;
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await sb
        .from('pair_links')
        .select('senior_user_id, guardian_user_id')
        .eq('status', 'confirmed')
        .or('senior_user_id.eq.$uid,guardian_user_id.eq.$uid')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    final senior = row['senior_user_id'] as String?;
    final guardian = row['guardian_user_id'] as String?;
    if (senior == uid) return guardian;
    if (guardian == uid) return senior;
    return null;
  }

  /// 두 사용자 사이의 메시지 실시간 스트림 (오래된 → 최신 정렬).
  Stream<List<Message>> watchConversation({
    required String me,
    required String partner,
  }) {
    final sb = supabaseClient;
    return sb
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((rows) => rows
            .map(Message.fromJson)
            .where((m) =>
                (m.senderId == me && m.receiverId == partner) ||
                (m.senderId == partner && m.receiverId == me))
            .toList());
  }

  DateTime _monthStart() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, 1);
  }

  /// 이번 달에 내가 보낸 텍스트 메시지 수.
  Future<int> monthlyTextCount() async {
    final sb = supabaseClient;
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return 0;
    final r = await sb
        .from('messages')
        .select('id')
        .eq('sender_id', uid)
        .isFilter('image_url', null)
        .gte('created_at', _monthStart().toUtc().toIso8601String())
        .count(CountOption.exact);
    return r.count;
  }

  /// 이번 달에 내가 보낸 이미지 메시지 수.
  Future<int> monthlyImageCount() async {
    final sb = supabaseClient;
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return 0;
    final r = await sb
        .from('messages')
        .select('id')
        .eq('sender_id', uid)
        .not('image_url', 'is', null)
        .gte('created_at', _monthStart().toUtc().toIso8601String())
        .count(CountOption.exact);
    return r.count;
  }

  /// 텍스트 전송. 한도 초과 시 [LimitExceeded] throw.
  Future<void> sendText({
    required String receiverId,
    required String text,
  }) async {
    final sb = supabaseClient;
    final uid = sb.auth.currentUser!.id;
    final used = await monthlyTextCount();
    if (used >= monthlyTextLimit) {
      throw const LimitExceeded(isImage: false);
    }
    await sb.from('messages').insert({
      'sender_id': uid,
      'receiver_id': receiverId,
      'content': text,
    });
    await _notifyMessageReceived(uid: uid, receiverId: receiverId);
  }

  /// 이미지 전송. 한도 초과 시 [LimitExceeded] throw.
  Future<void> sendImage({
    required String receiverId,
    required File file,
  }) async {
    final sb = supabaseClient;
    final uid = sb.auth.currentUser!.id;
    final used = await monthlyImageCount();
    if (used >= monthlyImageLimit) {
      throw const LimitExceeded(isImage: true);
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ext = file.path.split('.').last.toLowerCase();
    final path = '$uid/$ts.$ext';
    await sb.storage.from(_bucket).upload(path, file);
    final url = sb.storage.from(_bucket).getPublicUrl(path);
    await sb.from('messages').insert({
      'sender_id': uid,
      'receiver_id': receiverId,
      'image_url': url,
    });
    await _notifyMessageReceived(uid: uid, receiverId: receiverId);
  }

  /// 특정 상대에게서 온 미읽 메시지를 모두 읽음 처리.
  Future<void> markConversationAsRead(String partnerId) async {
    try {
      final sb = supabaseClient;
      final uid = sb.auth.currentUser?.id;
      if (uid == null) return;
      await sb
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', partnerId)
          .eq('receiver_id', uid)
          .eq('is_read', false);
    } catch (_) {
      // 읽음 처리 실패는 조용히 무시
    }
  }

  /// 내가 받은 미읽 메시지를 실시간으로 watch. sender 별로 그룹핑한 결과.
  /// `Map<senderId, List<Message>>`.
  Stream<Map<String, List<Message>>> watchUnreadByPartner() {
    final sb = supabaseClient;
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return Stream.value(const {});
    return sb.from('messages').stream(primaryKey: ['id']).map((rows) {
      final out = <String, List<Message>>{};
      for (final r in rows) {
        final m = Message.fromJson(r);
        if (m.receiverId != uid || m.isRead) continue;
        out.putIfAbsent(m.senderId, () => []).add(m);
      }
      // 각 그룹을 시간순 정렬 (최신이 마지막)
      for (final v in out.values) {
        v.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }
      return out;
    });
  }

  /// 메시지 수신 푸시. sender role 에 따라 본문/route 다르게 보냄.
  Future<void> _notifyMessageReceived({
    required String uid,
    required String receiverId,
  }) async {
    try {
      final sb = supabaseClient;
      final me = await sb
          .from('profiles')
          .select('role')
          .eq('user_id', uid)
          .maybeSingle();
      final senderIsSenior = (me?['role'] as String?) == 'senior';
      // sender 가 senior 면 receiver 는 guardian → 보호자에게 알림
      final title = senderIsSenior
          ? '부모님에게 메시지가 왔어요'
          : '가족에게 메시지가 왔어요';
      // sender 가 senior 면 보호자가 받음 → 대시보드, 반대면 메시지 화면
      final route = senderIsSenior ? '/guardian/dashboard' : '/messages';
      await PushService.instance.sendTo(
        userId: receiverId,
        title: title,
        body: '메시지를 확인해보세요',
        data: {'route': route},
      );
    } catch (_) {
      // best-effort
    }
  }
}

class LimitExceeded implements Exception {
  final bool isImage;
  const LimitExceeded({required this.isImage});
  @override
  String toString() => '이번 달 무료 메시지를 다 사용했어요';
}

/// 채팅 상대 user_id provider — pair_links 에서 자동 조회.
final partnerIdProvider = FutureProvider<String?>((ref) async {
  ref.watch(supabaseProvider); // auth 변경 시 재계산
  return MessagesService.instance.findPartnerId();
});

/// 현재 어르신과 연결된 보호자의 별명 (가장 최근 confirmed pair_link).
final partnerNicknameProvider = FutureProvider<String?>((ref) async {
  final sb = supabaseClient;
  final uid = sb.auth.currentUser?.id;
  if (uid == null) return null;
  try {
    final row = await sb
        .from('pair_links')
        .select('guardian_nickname')
        .eq('senior_user_id', uid)
        .eq('status', 'confirmed')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    final v = row?['guardian_nickname'] as String?;
    return (v == null || v.trim().isEmpty) ? null : v.trim();
  } catch (_) {
    return null;
  }
});

/// 내게 온 미읽 메시지를 senderId 별로 그룹핑한 실시간 스트림.
/// 홈 화면에서 가족 카드 반짝임/팝업 트리거에 사용.
final unreadByPartnerProvider =
    StreamProvider<Map<String, List<Message>>>((ref) {
  return MessagesService.instance.watchUnreadByPartner();
});

/// 두 사용자 간 대화 스트림.
final conversationProvider =
    StreamProvider.family<List<Message>, ConversationKey>((ref, key) {
  return MessagesService.instance
      .watchConversation(me: key.me, partner: key.partner);
});

class MonthlyCounts {
  final int text;
  final int image;
  const MonthlyCounts({required this.text, required this.image});
}

/// 이번 달에 내가 보낸 텍스트/이미지 메시지 수. 전송 후 invalidate 로 새로고침.
final monthlyMessageCountsProvider =
    FutureProvider<MonthlyCounts>((ref) async {
  final t = await MessagesService.instance.monthlyTextCount();
  final i = await MessagesService.instance.monthlyImageCount();
  return MonthlyCounts(text: t, image: i);
});

class ConversationKey {
  final String me;
  final String partner;
  const ConversationKey(this.me, this.partner);
  @override
  bool operator ==(Object other) =>
      other is ConversationKey && other.me == me && other.partner == partner;
  @override
  int get hashCode => Object.hash(me, partner);
}
