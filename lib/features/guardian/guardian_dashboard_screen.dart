import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../models/senior_settings.dart';
import '../../services/realtime_service.dart';
import '../../models/call_alert.dart';
import '../../services/call_alerts_service.dart';
import '../../services/subscription_service.dart';
import 'tabs/home_apps_tab.dart';
import 'tabs/medications_tab.dart';
import 'tabs/emergency_tab.dart';
import 'tabs/info_tab.dart';
import 'tabs/safety_tab.dart';

enum GuardianTab {
  homeApps,
  medications,
  safety,
  emergency,
  info,
}

class GuardianDashboardScreen extends ConsumerStatefulWidget {
  const GuardianDashboardScreen({super.key});

  @override
  ConsumerState<GuardianDashboardScreen> createState() =>
      _GuardianDashboardScreenState();
}

class _GuardianDashboardScreenState
    extends ConsumerState<GuardianDashboardScreen> {
  GuardianTab _tab = GuardianTab.homeApps;
  Future<String?>? _seniorIdFuture;

  @override
  void initState() {
    super.initState();
    _seniorIdFuture = _findSeniorId();
  }

  Future<String?> _findSeniorId() async {
    final sb = ref.read(supabaseProvider);
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return null;
    final r = await sb
        .from('pair_links')
        .select('senior_user_id')
        .eq('guardian_user_id', uid)
        .eq('status', 'confirmed')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return r?['senior_user_id'] as String?;
  }

  Future<void> _logout() async {
    await ref.read(supabaseProvider).auth.signOut();
    if (!mounted) return;
    context.go('/guardian/login');
  }

  @override
  Widget build(BuildContext context) {
    // ===== DEV ONLY: ?dev=1 이면 더미 데이터로 대시보드 렌더 =====
    final isDev =
        GoRouterState.of(context).uri.queryParameters['dev'] == '1';
    if (isDev) {
      return Theme(
        data: JTheme.guardian(),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: _DevPaired(
              tab: _tab,
              onTabChange: (t) => setState(() => _tab = t),
              onLogout: () => context.go('/guardian/login'),
            ),
          ),
        ),
      );
    }
    // ===== /DEV =====
    return Theme(
      data: JTheme.guardian(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: FutureBuilder<String?>(
            future: _seniorIdFuture,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final sid = snap.data;
              if (sid == null) {
                return _NotPaired(
                  onConnect: () => context.push('/guardian/connect-method'),
                  onLogout: _logout,
                );
              }
              return _Paired(
                seniorId: sid,
                tab: _tab,
                onTabChange: (t) => setState(() => _tab = t),
                onLogout: _logout,
              );
            },
          ),
        ),
      ),
    );
  }
}

// ===== DEV ONLY: 릴리즈 시 이 클래스 + 위 dev 분기 함께 삭제 =====
class _DevPaired extends StatelessWidget {
  final GuardianTab tab;
  final ValueChanged<GuardianTab> onTabChange;
  final VoidCallback onLogout;
  const _DevPaired({
    required this.tab,
    required this.onTabChange,
    required this.onLogout,
  });

  static const _dummySeniorId = '00000000-0000-0000-0000-000000000000';
  static const _dummySettings = SeniorSettings(
    userId: _dummySeniorId,
    enabledApps: ['phone', 'message', 'kakaotalk', 'youtube'],
    takesMedication: false,
    emergencyContacts: [],
    soundMode: 'sound',
    batteryPct: 72,
    online: true,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3CC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'DEV MODE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF7A5C00),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: _PhoneStatusCard(s: _dummySettings),
        ),
        Expanded(
          child: switch (tab) {
            GuardianTab.homeApps =>
              HomeAppsTab(seniorId: _dummySeniorId, s: _dummySettings),
            GuardianTab.medications =>
              const MedicationsTab(seniorId: _dummySeniorId),
            GuardianTab.safety =>
              SafetyTab(seniorId: _dummySeniorId, s: _dummySettings),
            GuardianTab.emergency =>
              EmergencyTab(seniorId: _dummySeniorId, s: _dummySettings),
            GuardianTab.info =>
              InfoTab(seniorId: _dummySeniorId, onLogout: onLogout),
          },
        ),
        _BottomTabBar(active: tab, onChange: onTabChange),
      ],
    );
  }
}
// ===== /DEV =====

class _NotPaired extends StatelessWidget {
  final VoidCallback onConnect;
  final VoidCallback onLogout;
  const _NotPaired({required this.onConnect, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Spacer(),
              IconButton(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded, color: JD.gInkSoft),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 96,
            height: 96,
            margin: const EdgeInsets.symmetric(horizontal: 100),
            decoration: BoxDecoration(
              color: JD.gBlueSoft,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.link_rounded, size: 48, color: JD.gBlue),
          ),
          const SizedBox(height: 24),
          const Text(
            '부모님 폰과\n연결이 필요합니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: JD.gInk,
              height: 1.3,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onConnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: JD.gBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800),
            ),
            child: const Text('연결하기'),
          ),
        ],
      ),
    );
  }
}

class _Paired extends ConsumerWidget {
  final String seniorId;
  final GuardianTab tab;
  final ValueChanged<GuardianTab> onTabChange;
  final VoidCallback onLogout;
  const _Paired({
    required this.seniorId,
    required this.tab,
    required this.onTabChange,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(remoteSeniorSettingsProvider(seniorId));
    final alertsAsync = ref.watch(activeCallAlertsProvider(seniorId));
    return settings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (s) => Column(
        children: [
          // 상단 헤더: 메시지 아이콘 진입 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
            child: Row(
              children: [
                const Spacer(),
                _MessagesIconButton(seniorId: seniorId),
              ],
            ),
          ),
          // 모르는 번호 통화 알림 배너
          alertsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (alerts) {
              if (alerts.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  children: [
                    for (final a in alerts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _CallAlertBanner(alert: a),
                      ),
                  ],
                ),
              );
            },
          ),
          // 12h/24h 미사용 배너
          if (s.inactivityAlert) _InactivityBanner(updatedAt: s.updatedAt),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: _PhoneStatusCard(s: s),
          ),
          Expanded(
            child: switch (tab) {
              GuardianTab.homeApps => HomeAppsTab(seniorId: seniorId, s: s),
              GuardianTab.medications => MedicationsTab(seniorId: seniorId),
              GuardianTab.safety => SafetyTab(seniorId: seniorId, s: s),
              GuardianTab.emergency => EmergencyTab(seniorId: seniorId, s: s),
              GuardianTab.info =>
                InfoTab(seniorId: seniorId, onLogout: onLogout),
            },
          ),
          const _SubscriptionBanner(),
          _BottomTabBar(active: tab, onChange: onTabChange),
        ],
      ),
    );
  }
}

class _SubscriptionBanner extends ConsumerWidget {
  const _SubscriptionBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(subscriptionStatusProvider).maybeWhen(
          data: (v) => v.isPremium,
          orElse: () => false,
        );
    if (isPremium) return const SizedBox.shrink();
    return Material(
      color: const Color(0xFFEEF3FF),
      child: InkWell(
        onTap: () => context.push('/guardian/subscription'),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.shield_rounded,
                  color: JD.gBlue, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '안심 프리미엄으로 업그레이드하면 안심 기능을 이용할 수 있어요',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: JD.gInk,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '자세히 보기',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: JD.gBlue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessagesIconButton extends StatelessWidget {
  final String seniorId;
  const _MessagesIconButton({required this.seniorId});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: JD.gBlueSoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(
          '/guardian/messages',
          extra: {'seniorId': seniorId},
        ),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: const Icon(
            Icons.chat_bubble_rounded,
            color: JD.gBlue,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _InactivityBanner extends StatelessWidget {
  final DateTime? updatedAt;
  const _InactivityBanner({required this.updatedAt});

  @override
  Widget build(BuildContext context) {
    if (updatedAt == null) return const SizedBox.shrink();
    final hours = DateTime.now().difference(updatedAt!).inHours;
    if (hours < 12) return const SizedBox.shrink();
    final isUrgent = hours >= 24;
    final bg =
        isUrgent ? const Color(0xFFFFE4E4) : const Color(0xFFFFF3CC);
    final fg =
        isUrgent ? const Color(0xFFB41E1E) : const Color(0xFF7A5C00);
    final text = isUrgent
        ? '부모님이 24시간 이상 폰을 사용하지 않았어요. 확인이 필요합니다'
        : '부모님이 12시간 이상 폰을 사용하지 않았어요';
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isUrgent ? Icons.warning_rounded : Icons.access_time_rounded,
            color: fg,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: fg,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallAlertBanner extends ConsumerStatefulWidget {
  final CallAlert alert;
  const _CallAlertBanner({required this.alert});

  @override
  ConsumerState<_CallAlertBanner> createState() => _CallAlertBannerState();
}

class _CallAlertBannerState extends ConsumerState<_CallAlertBanner> {
  bool _busy = false;

  String _fmtTime(DateTime dt) {
    final ampm = dt.hour < 12 ? '오전' : '오후';
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    return '$ampm $h:$m';
  }

  String _fmtDuration(int? sec) {
    if (sec == null || sec <= 0) return '';
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m == 0) return ' · 통화 $s초';
    return ' · 통화 $m분 $s초';
  }

  Future<void> _dismiss() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await CallAlertsService.instance.dismiss(widget.alert.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.alert;
    final isUrgent = a.alertLevel == CallAlertLevel.urgent;
    final bg = isUrgent ? const Color(0xFFFFE4E4) : const Color(0xFFFFF3CC);
    final fg =
        isUrgent ? const Color(0xFFB41E1E) : const Color(0xFF7A5C00);
    final headline = switch (a.alertLevel) {
      CallAlertLevel.urgent =>
        '⚠️ 부모님이 모르는 번호와 통화 후 돈 얘기를 했다고 합니다! 즉시 확인하세요',
      CallAlertLevel.normal => '부모님이 모르는 번호와 통화했어요',
      CallAlertLevel.noResponse =>
        '부모님이 모르는 번호와 통화했어요 (응답 없음)',
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: fg,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${a.phoneNumber}${_fmtDuration(a.callDuration)} · ${_fmtTime(a.createdAt)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy ? null : _dismiss,
              style: TextButton.styleFrom(
                foregroundColor: fg,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text(
                '확인했어요',
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneStatusCard extends StatelessWidget {
  final SeniorSettings s;
  const _PhoneStatusCard({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: JD.gLine, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '부모님 폰 상태',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: JD.gInkMute,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatusItem(
                  icon: Icons.battery_charging_full_rounded,
                  label: '배터리',
                  value: s.batteryPct == null ? '?' : '${s.batteryPct}%',
                  valueColor:
                      (s.batteryAlert && s.batteryPct != null && s.batteryPct! <= 20)
                          ? JD.cRed
                          : null,
                ),
              ),
              Expanded(
                child: _StatusItem(
                  icon: switch (s.soundMode) {
                    'vibrate' => Icons.vibration_rounded,
                    _ => Icons.volume_up_rounded,
                  },
                  label: '소리',
                  value: switch (s.soundMode) {
                    'vibrate' => '진동',
                    _ => '소리 켜짐',
                  },
                ),
              ),
              Expanded(
                child: _StatusItem(
                  icon: s.online
                      ? Icons.wifi_rounded
                      : Icons.wifi_off_rounded,
                  label: '인터넷',
                  value: s.online ? '연결됨' : '연결 안 됨',
                ),
              ),
            ],
          ),
          if (s.batteryAlert &&
              s.batteryPct != null &&
              s.batteryPct! <= 20) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.battery_alert_rounded,
                      color: JD.cRed, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '부모님 폰 배터리가 부족해요',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: JD.cRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _StatusItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  @override
  Widget build(BuildContext context) {
    final low = valueColor != null;
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: low ? const Color(0xFFFFE4E4) : JD.gBlueSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: low ? JD.cRed : JD.gBlue, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: JD.gInkMute,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: valueColor ?? JD.gInk,
          ),
        ),
      ],
    );
  }
}

class _BottomTabBar extends StatelessWidget {
  final GuardianTab active;
  final ValueChanged<GuardianTab> onChange;
  const _BottomTabBar({required this.active, required this.onChange});

  static const _items = <(GuardianTab, String, IconData)>[
    (GuardianTab.homeApps, '홈 관리', Icons.phone_android_rounded),
    (GuardianTab.medications, '약 관리', Icons.medication_rounded),
    (GuardianTab.safety, '안심', Icons.shield_rounded),
    (GuardianTab.emergency, '긴급 연락', Icons.emergency_rounded),
    (GuardianTab.info, '정보', Icons.info_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: JD.gLine, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          for (final it in _items)
            Expanded(
              child: _TabItem(
                label: it.$2,
                icon: it.$3,
                active: active == it.$1,
                onTap: () => onChange(it.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _TabItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? JD.gBlue : JD.gInkMute;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
