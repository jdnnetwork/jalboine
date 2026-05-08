import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_tokens.dart';
import '../../../core/supabase.dart';
import '../../../models/senior_settings.dart';

class SafetyTab extends ConsumerStatefulWidget {
  final String seniorId;
  final SeniorSettings s;
  const SafetyTab({super.key, required this.seniorId, required this.s});

  @override
  ConsumerState<SafetyTab> createState() => _SafetyTabState();
}

class _SafetyTabState extends ConsumerState<SafetyTab> {
  bool _busy = false;

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
          .update({'emergency_sound': true}).eq('user_id', widget.seniorId);
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
        const SizedBox(height: 4),
        const Text(
          '유료 기능 (현재 무료 체험 중)',
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
          onChanged: (v) => _toggle('unknown_call_detection', v),
        ),
        const SizedBox(height: 12),
        _ToggleCard(
          icon: Icons.location_on_rounded,
          title: '위치 추적',
          sub: '부모님 위치를 실시간으로 확인해요',
          value: s.locationTracking,
          onChanged: (v) => _toggle('location_tracking', v),
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
        _ButtonCard(
          icon: Icons.volume_up_rounded,
          title: '긴급 소리 보내기',
          sub: '부모님 폰을 강제로 울려요',
          buttonLabel: '보내기',
          buttonColor: JD.cRed,
          busy: _busy,
          onTap: _sendEmergencySound,
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
  const _ToggleCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.value,
    required this.onChanged,
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
      child: Row(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: JD.gInk,
                  ),
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
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ButtonCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final String buttonLabel;
  final Color buttonColor;
  final bool busy;
  final VoidCallback onTap;
  const _ButtonCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.buttonLabel,
    required this.buttonColor,
    required this.busy,
    required this.onTap,
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: buttonColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: JD.gInk,
                  ),
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
          ElevatedButton(
            onPressed: busy ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(72, 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w900),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
