import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../models/senior_settings.dart';
import '../../services/realtime_service.dart';

/// 보호자 메인 대시보드.
/// - 부모님 폰 상태 (배터리, 소리모드, 인터넷)
/// - 홈 화면 앱 관리 (최대 8개)
/// - 약 관리 + 복용 기록
/// - 긴급 연락처
class GuardianDashboardScreen extends ConsumerWidget {
  const GuardianDashboardScreen({super.key});

  Future<String?> _findSeniorId(WidgetRef ref) async {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: JTheme.guardian(),
      child: Scaffold(
        body: GuardianBackground(
          child: SafeArea(
            child: FutureBuilder<String?>(
              future: _findSeniorId(ref),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final sid = snap.data;
                if (sid == null) {
                  return _NotPaired(onConnect: () => context.go('/parent/connect'));
                }
                return _PairedDashboard(seniorId: sid);
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
          const Icon(Icons.family_restroom_rounded,
              size: 96, color: JTheme.guardianAccent),
          const SizedBox(height: 24),
          const Text(
            '아직 부모님과 연결되지 않았어요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: onConnect, child: const Text('연결 시작')),
        ],
      ),
    );
  }
}

class _PairedDashboard extends ConsumerWidget {
  final String seniorId;
  const _PairedDashboard({required this.seniorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(remoteSeniorSettingsProvider(seniorId));
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          pinned: true,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
          title: const Text('대시보드',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: JTheme.guardianText)),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.black54),
              onPressed: () async {
                await ref.read(supabaseProvider).auth.signOut();
                if (context.mounted) context.go('/');
              },
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: settings.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(child: Text('$e')),
            data: (s) => SliverList(
              delegate: SliverChildListDelegate([
                _StatusCard(s: s),
                const SizedBox(height: 16),
                _AppsCard(seniorId: seniorId, s: s),
                const SizedBox(height: 16),
                _MedicationsCard(seniorId: seniorId),
                const SizedBox(height: 16),
                _ContactCard(seniorId: seniorId, s: s),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.6), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final SeniorSettings s;
  const _StatusCard({required this.s});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('부모님 폰 상태',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                  icon: Icons.battery_charging_full_rounded,
                  label: s.batteryPct == null ? '?' : '${s.batteryPct}%'),
              const SizedBox(width: 8),
              _StatChip(
                  icon: _soundIcon(s.soundMode),
                  label: _soundLabel(s.soundMode)),
              const SizedBox(width: 8),
              _StatChip(
                  icon: s.online
                      ? Icons.wifi_rounded
                      : Icons.wifi_off_rounded,
                  label: s.online ? '온라인' : '오프라인'),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _soundIcon(String m) => switch (m) {
        'silent' => Icons.notifications_off_rounded,
        'vibrate' => Icons.vibration_rounded,
        _ => Icons.volume_up_rounded,
      };
  static String _soundLabel(String m) => switch (m) {
        'silent' => '무음',
        'vibrate' => '진동',
        _ => '소리',
      };
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: JTheme.guardianAccent),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AppsCard extends ConsumerWidget {
  final String seniorId;
  final SeniorSettings s;
  const _AppsCard({required this.seniorId, required this.s});

  Future<void> _toggle(WidgetRef ref, String key) async {
    final next = List<String>.from(s.enabledApps);
    if (next.contains(key)) {
      next.remove(key);
    } else if (next.length < 8) {
      next.add(key);
    }
    final sb = ref.read(supabaseProvider);
    await sb
        .from('senior_settings')
        .update({'enabled_apps': next}).eq('user_id', seniorId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('홈 화면 앱 (최대 8개)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in JConst.apps.entries)
                FilterChip(
                  showCheckmark: false,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(entry.value.icon, size: 16, color: entry.value.bg),
                      const SizedBox(width: 6),
                      Text(entry.value.label,
                          style:
                              const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  selected: s.enabledApps.contains(entry.key),
                  onSelected: (_) => _toggle(ref, entry.key),
                  selectedColor:
                      JTheme.guardianAccent.withValues(alpha: 0.15),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MedicationsCard extends ConsumerWidget {
  final String seniorId;
  const _MedicationsCard({required this.seniorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sb = ref.watch(supabaseProvider);
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('약 관리',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          FutureBuilder<List<dynamic>>(
            future: sb.from('medications').select().eq('user_id', seniorId),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('불러오는 중…'),
                );
              }
              final rows = snap.data!;
              if (rows.isEmpty) {
                return const Text('등록된 약이 없어요',
                    style: TextStyle(color: Colors.black54));
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
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              );
            },
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
                return const Text('아직 복용 기록 없음',
                    style: TextStyle(color: Colors.black54));
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('최근 복용 기록',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  for (final l in logs)
                    Text(
                      '· ${l['scheduled_at']} — ${_label(l['status'] as String?)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static String _label(String? s) => switch (s) {
        'taken' => '먹음',
        'delayed' => '나중에',
        'missed' => '놓침',
        _ => '?',
      };
}

class _ContactCard extends ConsumerStatefulWidget {
  final String seniorId;
  final SeniorSettings s;
  const _ContactCard({required this.seniorId, required this.s});

  @override
  ConsumerState<_ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends ConsumerState<_ContactCard> {
  late final TextEditingController _name = TextEditingController(
      text: widget.s.emergencyContacts.isEmpty
          ? ''
          : widget.s.emergencyContacts.first.name);
  late final TextEditingController _phone = TextEditingController(
      text: widget.s.emergencyContacts.isEmpty
          ? ''
          : widget.s.emergencyContacts.first.phone);
  bool _saving = false;

  Future<void> _save() async {
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
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('긴급 연락처',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: '이름',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: '전화번호',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
