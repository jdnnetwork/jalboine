import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase.dart';

enum SubscriptionStatus { free, premium }

extension SubscriptionStatusX on SubscriptionStatus {
  bool get isPremium => this == SubscriptionStatus.premium;
}

/// 현재 로그인된 사용자(보호자/피보호자 모두)의 profile.subscription_status 를 읽어온다.
/// 미로그인 / 행 없음 / 에러 → free.
final subscriptionStatusProvider =
    FutureProvider<SubscriptionStatus>((ref) async {
  final sb = ref.watch(supabaseProvider);
  final uid = sb.auth.currentUser?.id;
  if (uid == null) return SubscriptionStatus.free;
  try {
    final row = await sb
        .from('profiles')
        .select('subscription_status')
        .eq('user_id', uid)
        .maybeSingle();
    final s = (row?['subscription_status'] as String?) ?? 'free';
    return s == 'premium'
        ? SubscriptionStatus.premium
        : SubscriptionStatus.free;
  } catch (_) {
    return SubscriptionStatus.free;
  }
});
