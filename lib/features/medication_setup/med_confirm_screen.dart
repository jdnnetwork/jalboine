import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../services/notification_service.dart';
import '../../services/onboarding_settings_service.dart';
import '../../widgets/audio_toggle_button.dart';
import '../../widgets/back_pill.dart';
import '../../widgets/big_button.dart';

/// 화면 7-4: 약 알림 확인.
class MedConfirmScreen extends ConsumerStatefulWidget {
  final List<String> times;
  final int count;
  const MedConfirmScreen({super.key, required this.times, required this.count});

  @override
  ConsumerState<MedConfirmScreen> createState() => _MedConfirmScreenState();
}

class _MedConfirmScreenState extends ConsumerState<MedConfirmScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(audioGuideModeProvider)) {
        AudioService.instance.play('assets/audio/alarm_confirm.wav');
      }
    });
  }

  String _slotLabel(int idx) {
    if (widget.count == 1) return '';
    if (widget.count == 2) return idx == 0 ? '아침' : '저녁';
    return switch (idx) {
      0 => '아침',
      1 => '점심',
      _ => '저녁',
    };
  }

  String get _summary {
    final entries = <String>[];
    for (var i = 0; i < widget.times.length; i++) {
      final t = widget.times[i];
      final parts = t.split(':');
      final h = int.tryParse(parts.first) ?? 0;
      final ampm = h < 12 ? '오전' : '오후';
      final hh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      final label = _slotLabel(i);
      entries.add(label.isEmpty ? '$ampm $hh시' : '$label $hh시');
    }
    return entries.join(', ');
  }

  Future<void> _save({required bool alarmEnabled}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final sb = ref.read(supabaseProvider);
      final uid = sb.auth.currentUser!.id;
      await sb.from('medications').upsert({
        'user_id': uid,
        'frequency': widget.count,
        'times_per_day': widget.count,
        'times': widget.times.map((t) => '$t:00').toList(),
        'alarm_enabled': alarmEnabled,
      });
      if (alarmEnabled) {
        await NotificationService.instance
            .rescheduleMedications(widget.times.map((t) => '$t:00').toList());
      } else {
        await NotificationService.instance.cancelAll();
      }
      if (!mounted) return;
      context.go('/setup-done');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SeniorBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    BackPill(onTap: () => context.go('/med/count')),
                    const Spacer(),
                    const AudioToggleButton(
                        audioAsset: 'assets/audio/alarm_confirm.wav'),
                  ],
                ),
                const Spacer(),
                const Text(
                  '이 시간에 큰 알림으로\n알려드릴까요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: JD.ink,
                    letterSpacing: -1.0,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 22, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(JD.rCard),
                    boxShadow: JD.shadowCard,
                  ),
                  child: Text(
                    _summary,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: JD.ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: BigButton(
                        label: '네',
                        icon: Icons.check_rounded,
                        background: JD.cMint,
                        foreground: JD.ink,
                        shadowBottomColor: const Color(0xFF3C965A),
                        onTap: _busy ? null : () => _save(alarmEnabled: true),
                        height: 96,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: BigButton(
                        label: '아니요',
                        icon: Icons.close_rounded,
                        background: Colors.white,
                        foreground: JD.ink,
                        shadowBottomColor: const Color(0xFFC8B89A),
                        onTap: _busy ? null : () => _save(alarmEnabled: false),
                        height: 96,
                        fontSize: 28,
                        border: Border.all(
                          color: const Color(0xFFE8DDC9),
                          width: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
