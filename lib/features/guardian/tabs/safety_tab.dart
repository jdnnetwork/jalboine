import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_tokens.dart';
import '../../../core/supabase.dart';
import '../../../models/senior_settings.dart';
import '../../../services/subscription_service.dart';
import '../../subscription/paywall_dialog.dart';

class SafetyTab extends ConsumerStatefulWidget {
  final String seniorId;
  final SeniorSettings s;
  const SafetyTab({super.key, required this.seniorId, required this.s});

  @override
  ConsumerState<SafetyTab> createState() => _SafetyTabState();
}

class _SafetyTabState extends ConsumerState<SafetyTab> {
  bool _busy = false;
  final _previewer = AudioPlayer();
  bool _previewing = false;

  @override
  void dispose() {
    _previewer.dispose();
    super.dispose();
  }

  Future<void> _previewVoice(String url) async {
    if (_previewing) {
      await _previewer.stop();
      setState(() => _previewing = false);
      return;
    }
    setState(() => _previewing = true);
    try {
      await _previewer.play(UrlSource(url));
      _previewer.onPlayerComplete.first.then((_) {
        if (mounted) setState(() => _previewing = false);
      });
    } catch (_) {
      if (mounted) setState(() => _previewing = false);
    }
  }

  Future<void> _toggle(String column, bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(supabaseProvider)
          .from('senior_settings')
          .update({column: value}).eq('user_id', widget.seniorId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendEmergencySound() async {
    if (_busy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('긴급 소리 보내기'),
        content: const Text('부모님 폰을 강제로 울립니다. 보내시겠어요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('보내기')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(supabaseProvider)
          .from('senior_settings')
          .update({
        'emergency_sound': true,
        'emergency_sound_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('user_id', widget.seniorId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('긴급 소리 신호를 보냈습니다')));
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
    final s = widget.s;
    final subAsync = ref.watch(subscriptionStatusProvider);
    final isPremium = subAsync.maybeWhen(
      data: (v) => v.isPremium,
      orElse: () => false,
    );
    void gate(VoidCallback action) {
      if (isPremium) {
        action();
      } else {
        showPaywallDialog(context);
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      children: [
        const Text(
          '안심 기능',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: JD.gBlue,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        if (isPremium)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: JD.gBlueSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              '안심 프리미엄 이용 중',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: JD.gBlue,
                letterSpacing: 0.4,
              ),
            ),
          )
        else
          const Text(
            '안심 프리미엄 구독으로 모든 기능을 이용하세요',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: JD.gInkMute,
            ),
          ),
        const SizedBox(height: 16),
        _ToggleCard(
          icon: Icons.search_rounded,
          title: '모르는 번호 감지',
          sub: '모르는 번호와 통화하면 알려드려요',
          value: s.unknownCallDetection,
          locked: !isPremium,
          onChanged: (v) =>
              gate(() => _toggle('unknown_call_detection', v)),
        ),
        const SizedBox(height: 12),
        _ToggleCard(
          icon: Icons.location_on_rounded,
          title: '위치 추적',
          sub: '부모님 위치를 실시간으로 확인해요',
          value: s.locationTracking,
          locked: !isPremium,
          onChanged: (v) => gate(() => _toggle('location_tracking', v)),
          extra: (isPremium && s.locationTracking)
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(
                      '/guardian/location',
                      extra: {'seniorId': widget.seniorId},
                    ),
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: const Text('위치 보기'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: JD.gBlue,
                      side: const BorderSide(color: JD.gBlue),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),
        _ToggleCard(
          icon: Icons.phone_android_rounded,
          title: '폰 미사용 알림',
          sub: '12시간 이상 미사용 시 알려드려요',
          value: s.inactivityAlert,
          onChanged: (v) => _toggle('inactivity_alert', v),
        ),
        const SizedBox(height: 12),
        _ToggleCard(
          icon: Icons.battery_alert_rounded,
          title: '배터리 부족 알림',
          sub: '20% 이하일 때 알려드려요',
          value: s.batteryAlert,
          onChanged: (v) => _toggle('battery_alert', v),
        ),
        const SizedBox(height: 12),
        _EmergencySoundCard(
          voiceUrl: s.emergencyVoiceUrl,
          busy: _busy,
          previewing: _previewing,
          locked: !isPremium,
          onRecord: () => gate(() => context.push(
                '/guardian/voice-record',
                extra: {'seniorId': widget.seniorId},
              )),
          onPreview: () {
            final url = s.emergencyVoiceUrl;
            if (url != null) _previewVoice(url);
          },
          onSend: () => gate(_sendEmergencySound),
        ),
      ],
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? extra;
  final bool locked;
  const _ToggleCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.value,
    required this.onChanged,
    this.extra,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JD.gLine, width: 1),
        boxShadow: JD.shadowBlueCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: locked
                      ? const Color(0xFFF2F4F8)
                      : JD.gBlueSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    color: locked ? JD.gInkMute : JD.gBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: JD.gInk,
                          ),
                        ),
                        if (locked) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.lock_rounded,
                              color: JD.gInkMute, size: 14),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: JD.gInkMute,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                activeThumbColor: JD.gBlue,
                onChanged: (v) => onChanged(v),
              ),
            ],
          ),
          ?extra,
        ],
      ),
    );
  }
}

class _EmergencySoundCard extends StatelessWidget {
  final String? voiceUrl;
  final bool busy;
  final bool previewing;
  final bool locked;
  final VoidCallback onRecord;
  final VoidCallback onPreview;
  final VoidCallback onSend;
  const _EmergencySoundCard({
    required this.voiceUrl,
    required this.busy,
    required this.previewing,
    required this.locked,
    required this.onRecord,
    required this.onPreview,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final hasVoice = voiceUrl != null && voiceUrl!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JD.gLine, width: 1),
        boxShadow: JD.shadowBlueCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.volume_up_rounded,
                    color: JD.cRed, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '긴급 소리 보내기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: JD.gInk,
                          ),
                        ),
                        if (locked) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.lock_rounded,
                              color: JD.gInkMute, size: 14),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '부모님 폰을 강제로 울려요',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: JD.gInkMute,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasVoice)
            ElevatedButton.icon(
              onPressed: busy ? null : onRecord,
              icon: const Icon(Icons.mic_rounded, size: 18),
              label: const Text('음성 녹음하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: JD.gBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w900),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onPreview,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: JD.gBlue,
                      side: const BorderSide(color: JD.gBlue),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(previewing ? '■ 정지' : '▶ 미리듣기'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onRecord,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: JD.gInkSoft,
                      side: const BorderSide(color: JD.gLine),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('다시 녹음'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: busy ? null : onSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: JD.cRed,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900),
              ),
              child: const Text('보내기'),
            ),
          ],
        ],
      ),
    );
  }
}
