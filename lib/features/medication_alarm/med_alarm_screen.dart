import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/big_button.dart';

class MedAlarmScreen extends ConsumerStatefulWidget {
  const MedAlarmScreen({super.key});

  @override
  ConsumerState<MedAlarmScreen> createState() => _MedAlarmScreenState();
}

class _MedAlarmScreenState extends ConsumerState<MedAlarmScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService.instance.play(JConst.audioMedicineAlarm);
    });
  }

  Future<void> _logAndExit(String status) async {
    if (_busy) return;
    HapticFeedback.lightImpact();
    setState(() => _busy = true);
    try {
      final sb = ref.read(supabaseProvider);
      await sb.from('med_logs').insert({
        'user_id': sb.auth.currentUser!.id,
        'scheduled_at': DateTime.now().toIso8601String(),
        'status': status,
        if (status == 'taken') 'taken_at': DateTime.now().toIso8601String(),
      });
      if (status == 'delayed') {
        await NotificationService.instance.snooze10min();
      }
      if (!mounted) return;
      context.go('/home');
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
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment(-1, -1),
                      end: Alignment(1, 1),
                      colors: [Color(0xFFFFC233), Color(0xFFE5A000)],
                    ),
                    borderRadius: BorderRadius.circular(44),
                    boxShadow: [
                      BoxShadow(
                          color: JD.cYellow.withValues(alpha: 0.30),
                          offset: const Offset(0, 14),
                          blurRadius: 30),
                    ],
                  ),
                  child: const Icon(Icons.medication_rounded,
                      color: Colors.white, size: 80),
                ),
                const SizedBox(height: 32),
                const Text(
                  '약 드실 시간이에요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: JD.ink,
                    letterSpacing: -1.2,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '약을 드시면 "먹었어요"를 눌러주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: JD.inkSoft,
                  ),
                ),
                const Spacer(),
                BigButton(
                  label: '먹었어요',
                  icon: Icons.check_circle_rounded,
                  background: JD.cGreen,
                  foreground: Colors.white,
                  shadowBottomColor: const Color(0xFF0F5C36),
                  onTap: _busy ? null : () => _logAndExit('taken'),
                  height: 96,
                  fontSize: 28,
                ),
                const SizedBox(height: 14),
                BigButton(
                  label: '나중에 (10분 뒤)',
                  background: JD.cYellowBg,
                  foreground: JD.ink,
                  shadowBottomColor: const Color(0xFF9B6F00),
                  onTap: _busy ? null : () => _logAndExit('delayed'),
                  height: 84,
                  fontSize: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
