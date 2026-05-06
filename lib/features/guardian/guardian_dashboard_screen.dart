import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../models/senior_settings.dart';
import '../../services/realtime_service.dart';

enum _Tab { home, pill, remote, message }

class GuardianDashboardScreen extends ConsumerStatefulWidget {
  const GuardianDashboardScreen({super.key});

  @override
  ConsumerState<GuardianDashboardScreen> createState() =>
      _GuardianDashboardScreenState();
}

class _GuardianDashboardScreenState
    extends ConsumerState<GuardianDashboardScreen> {
  _Tab _tab = _Tab.home;
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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: JTheme.guardian(),
      child: Scaffold(
        backgroundColor: JD.gBg,
        body: GuardianBackground(
          child: SafeArea(
            child: FutureBuilder<String?>(
              future: _seniorIdFuture,
              builder: (context, snap) {
                if (!snap.hasData &&
                    snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final sid = snap.data;
                if (sid == null) {
                  return _NotPaired(
                      onConnect: () => context.go('/parent/connect'));
                }
                return _Paired(
                  seniorId: sid,
                  tab: _tab,
                  onTabChange: (t) => setState(() => _tab = t),
                  onLogout: () async {
                    await ref.read(supabaseProvider).auth.signOut();
                    if (context.mounted) context.go('/');
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NotPaired extends StatelessWidget {
  final VoidCallback onConnect;
  const _NotPaired({required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 80),
          Container(
            width: 96,
            height: 96,
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: JD.gBlueSoft,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.family_restroom_rounded,
                size: 48, color: JD.gBlue),
          ),
          const SizedBox(height: 24),
          const Text(
            '아직 부모님과\n연결되지 않았어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: JD.gInk,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
              onPressed: onConnect, child: const Text('부모님 연결 시작')),
        ],
      ),
    );
  }
}

class _Paired extends ConsumerWidget {
  final String seniorId;
  final _Tab tab;
  final ValueChanged<_Tab> onTabChange;
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
      data: (s) => Stack(
        children: [
          Column(
            children: [
              _Header(
                guardianName: '민수',
                seniorName: '어머니 김순자님',
                onLogout: onLogout,
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  child: switch (tab) {
                    _Tab.home => _HomeTab(s: s, seniorId: seniorId),
                    _Tab.pill => _PillTab(seniorId: seniorId),
                    _Tab.remote => _RemoteTab(s: s, seniorId: seniorId),
                    _Tab.message => const _MessageTab(),
                  },
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _BottomTabBar(active: tab, onChange: onTabChange),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String guardianName;
  final String seniorName;
  final VoidCallback onLogout;
  const _Header({
    required this.guardianName,
    required this.seniorName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
                color: JD.gBlue, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Text('김',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '가족 모드 · $guardianName',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: JD.gInkMute,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  seniorName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: JD.gInk,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          _IconBtn(icon: Icons.notifications_rounded, onTap: () {}, hasBadge: true),
          const SizedBox(width: 8),
          _IconBtn(icon: Icons.logout_rounded, onTap: onLogout),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool hasBadge;
  const _IconBtn({required this.icon, required this.onTap, this.hasBadge = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Ink(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: JD.shadowBlueCard,
              ),
              child: Icon(icon, size: 20, color: JD.gInk),
            ),
          ),
        ),
        if (hasBadge)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: JD.gPink,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

// ───────────── 탭: 홈 ─────────────
class _HomeTab extends StatelessWidget {
  final SeniorSettings s;
  final String seniorId;
  const _HomeTab({required this.s, required this.seniorId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GreetingCard(),
        const SizedBox(height: 14),
        _PhoneStatusCard(s: s),
        const SizedBox(height: 14),
        _ActivityChart(),
      ],
    );
  }
}

class _GreetingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        color: JD.gBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: JD.gBlue.withValues(alpha: 0.25),
              offset: const Offset(0, 12),
              blurRadius: 28),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '오늘 어머니는 평소처럼',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xD9FFFFFF),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '잘 지내고 계세요',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _StatPill(label: '걸음', value: '3,240'),
                  _StatPill(label: '통화', value: '2회'),
                  _StatPill(label: '문자', value: '1건'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
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
        color: JD.gCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: JD.shadowBlueCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('폰 상태',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: JD.gInk)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: JD.gGreen, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.online ? '연결됨' : '오프라인',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: JD.gGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: '배터리',
                  value: s.batteryPct == null ? '?' : '${s.batteryPct}%',
                  icon: Icons.battery_charging_full_rounded,
                  color: JD.gGreen,
                  bg: const Color(0xFFE8F8F0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: '와이파이',
                  value: s.online ? '강함' : '오프',
                  icon: Icons.wifi_rounded,
                  color: JD.gBlue,
                  bg: JD.gBlueSoft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: '소리',
                  value: switch (s.soundMode) {
                    'silent' => '무음',
                    'vibrate' => '진동',
                    _ => '소리',
                  },
                  icon: switch (s.soundMode) {
                    'silent' => Icons.notifications_off_rounded,
                    'vibrate' => Icons.vibration_rounded,
                    _ => Icons.volume_up_rounded,
                  },
                  color: JD.gOrange,
                  bg: const Color(0xFFFFF1E6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: JD.gBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: JD.gInkMute),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: JD.gInk,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: JD.gCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: JD.shadowBlueCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 주 걸음 수',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: JD.gInkMute,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '22,840',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: JD.gInk,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Text(
                  '보',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: JD.gInkMute),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '↑ 12%',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: JD.gGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                _Bar(d: '월', v: 0.55),
                SizedBox(width: 6),
                _Bar(d: '화', v: 0.40),
                SizedBox(width: 6),
                _Bar(d: '수', v: 0.72),
                SizedBox(width: 6),
                _Bar(d: '목', v: 0.50),
                SizedBox(width: 6),
                _Bar(d: '금', v: 0.85),
                SizedBox(width: 6),
                _Bar(d: '토', v: 0.60),
                SizedBox(width: 6),
                _Bar(d: '일', v: 0.95, today: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String d;
  final double v;
  final bool today;
  const _Bar({required this.d, required this.v, this.today = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: v * 60,
            decoration: BoxDecoration(
              color: today ? JD.gBlue : JD.gBlueSoft,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            d,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: today ? JD.gBlue : JD.gInkMute,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────── 탭: 복약 ─────────────
class _PillTab extends ConsumerWidget {
  final String seniorId;
  const _PillTab({required this.seniorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sb = ref.watch(supabaseProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: JD.gCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: JD.shadowBlueCard,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '복약 일정',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: JD.gInkMute,
                    letterSpacing: 0.4),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<dynamic>>(
                future: sb.from('medications').select().eq('user_id', seniorId),
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('불러오는 중…',
                          style: TextStyle(color: JD.gInkMute)),
                    );
                  }
                  final rows = snap.data!;
                  if (rows.isEmpty) {
                    return const Text('등록된 약이 없어요',
                        style: TextStyle(color: JD.gInkMute));
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final r in rows)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '하루 ${r['times_per_day']}번 · ${(r['times'] as List).join(', ')}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: JD.gInk,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: JD.gCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: JD.shadowBlueCard,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '최근 복용 기록',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: JD.gInk),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<dynamic>>(
                future: sb
                    .from('med_logs')
                    .select()
                    .eq('user_id', seniorId)
                    .order('scheduled_at', ascending: false)
                    .limit(5),
                builder: (_, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  final logs = snap.data!;
                  if (logs.isEmpty) {
                    return const Text('아직 기록 없음',
                        style: TextStyle(color: JD.gInkMute));
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final l in logs)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: switch (l['status']) {
                                    'taken' => JD.gGreen,
                                    'delayed' => JD.gOrange,
                                    _ => JD.gPink,
                                  },
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${l['scheduled_at']}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: JD.gInkSoft,
                                  ),
                                ),
                              ),
                              Text(
                                switch (l['status']) {
                                  'taken' => '먹음',
                                  'delayed' => '나중에',
                                  _ => '놓침',
                                },
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: JD.gInk),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────── 탭: 리모컨 (앱/연락처 관리) ─────────────
class _RemoteTab extends ConsumerStatefulWidget {
  final SeniorSettings s;
  final String seniorId;
  const _RemoteTab({required this.s, required this.seniorId});

  @override
  ConsumerState<_RemoteTab> createState() => _RemoteTabState();
}

class _RemoteTabState extends ConsumerState<_RemoteTab> {
  late final TextEditingController _name = TextEditingController(
      text: widget.s.emergencyContacts.isEmpty
          ? ''
          : widget.s.emergencyContacts.first.name);
  late final TextEditingController _phone = TextEditingController(
      text: widget.s.emergencyContacts.isEmpty
          ? ''
          : widget.s.emergencyContacts.first.phone);
  bool _saving = false;

  Future<void> _toggleApp(String key) async {
    final next = List<String>.from(widget.s.enabledApps);
    if (next.contains(key)) {
      next.remove(key);
    } else if (next.length < 8) {
      next.add(key);
    }
    final sb = ref.read(supabaseProvider);
    await sb
        .from('senior_settings')
        .update({'enabled_apps': next}).eq('user_id', widget.seniorId);
  }

  Future<void> _saveContact() async {
    setState(() => _saving = true);
    try {
      final sb = ref.read(supabaseProvider);
      await sb.from('senior_settings').update({
        'emergency_contacts': [
          {'name': _name.text.trim(), 'phone': _phone.text.trim()}
        ],
      }).eq('user_id', widget.seniorId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('저장되었습니다')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: JD.gCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: JD.shadowBlueCard,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '홈 화면 앱 (최대 8개)',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: JD.gInk),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in JConst.apps.entries)
                    _AppChip(
                      label: entry.value.label,
                      icon: entry.value.icon,
                      color: entry.value.gradStart,
                      selected: widget.s.enabledApps.contains(entry.key),
                      onTap: () => _toggleApp(entry.key),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: JD.gCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: JD.shadowBlueCard,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '긴급 연락처',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: JD.gInk),
              ),
              const SizedBox(height: 12),
              _GTextField(controller: _name, label: '이름'),
              const SizedBox(height: 8),
              _GTextField(
                  controller: _phone,
                  label: '전화번호',
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _saving ? null : _saveContact,
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _AppChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.12) : JD.gBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: selected ? color : JD.gInkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  const _GTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, color: JD.gInk),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: JD.gBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ───────────── 탭: 메시지 ─────────────
class _MessageTab extends StatelessWidget {
  const _MessageTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: JD.gCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: JD.shadowBlueCard,
          ),
          child: Column(
            children: const [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 56, color: JD.gInkMute),
              SizedBox(height: 12),
              Text(
                '메시지 기능은 곧 만나요',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: JD.gInk,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Phase 2에서 제공됩니다',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: JD.gInkMute,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────── 하단 둥근 탭바 ─────────────
class _BottomTabBar extends StatelessWidget {
  final _Tab active;
  final ValueChanged<_Tab> onChange;
  const _BottomTabBar({required this.active, required this.onChange});

  static const _items = <(_Tab, String, IconData)>[
    (_Tab.home, '홈', Icons.home_rounded),
    (_Tab.pill, '복약', Icons.medication_rounded),
    (_Tab.remote, '리모컨', Icons.settings_remote_rounded),
    (_Tab.message, '메시지', Icons.chat_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: JD.gInk,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
              color: JD.gInk.withValues(alpha: 0.25),
              offset: const Offset(0, 12),
              blurRadius: 32),
        ],
      ),
      child: Row(
        children: [
          for (final it in _items)
            Expanded(
              child: _TabItem(
                tab: it.$1,
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
  final _Tab tab;
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _TabItem({
    required this.tab,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? JD.gInk : Colors.white.withValues(alpha: 0.65),
              ),
              if (active) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: JD.gInk,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
