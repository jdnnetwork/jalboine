import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../services/notification_service.dart';

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
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Icon(Icons.medication_rounded,
                    size: 96, color: JTheme.seniorAccent),
                const SizedBox(height: 24),
                Text(
                  '약 드실 시간이에요!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D5A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _busy ? null : () => _logAndExit('taken'),
                  child: const Text('먹었어요'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD24A),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _busy ? null : () => _logAndExit('delayed'),
                  child: const Text('나중에'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
