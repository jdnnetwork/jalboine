import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../models/senior_settings.dart';
import '../../services/realtime_service.dart';
import 'tabs/home_apps_tab.dart';
import 'tabs/medications_tab.dart';
import 'tabs/emergency_tab.dart';
import 'tabs/info_tab.dart';

enum GuardianTab { homeApps, medications, emergency, info }

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
        .eq('status', 'accepted')
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
                  onConnect: () => context.push('/parent/connect'),
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
    return settings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (s) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: _PhoneStatusCard(s: s),
          ),
          Expanded(
            child: switch (tab) {
              GuardianTab.homeApps => HomeAppsTab(seniorId: seniorId, s: s),
              GuardianTab.medications => MedicationsTab(seniorId: seniorId),
              GuardianTab.emergency => EmergencyTab(seniorId: seniorId, s: s),
              GuardianTab.info =>
                InfoTab(seniorId: seniorId, onLogout: onLogout),
            },
          ),
          _BottomTabBar(active: tab, onChange: onTabChange),
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
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatusItem({
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: JD.gBlueSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: JD.gBlue, size: 22),
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: JD.gInk,
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
    (GuardianTab.homeApps, '홈 화면 관리', Icons.phone_android_rounded),
    (GuardianTab.medications, '약 관리', Icons.medication_rounded),
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
