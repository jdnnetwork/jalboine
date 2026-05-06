import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../services/notification_service.dart';

class MedHourScreen extends ConsumerStatefulWidget {
  final int count;
  const MedHourScreen({super.key, required this.count});

  @override
  ConsumerState<MedHourScreen> createState() => _MedHourScreenState();
}

class _MedHourScreenState extends ConsumerState<MedHourScreen> {
  final List<int> _hours = [];
  bool _busy = false;

  // 6시 ~ 12시
  static const _options = [6, 7, 8, 9, 10, 11, 12];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService.instance.play(JConst.audioMedicineHour);
    });
  }

  Future<void> _pick(int h) async {
    if (_busy) return;
    setState(() => _hours.add(h));
    if (_hours.length < widget.count) return;
    setState(() => _busy = true);
    try {
      final sb = ref.read(supabaseProvider);
      final uid = sb.auth.currentUser!.id;
      final times = _hours
          .map((h) => '${h.toString().padLeft(2, '0')}:00:00')
          .toList();
      await sb.from('medications').upsert({
        'user_id': uid,
        'times': times,
        'times_per_day': widget.count,
      });
      await NotificationService.instance.rescheduleMedications(times);
      if (!mounted) return;
      context.go('/family');
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
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  '${_hours.length + 1}번째 시간\n언제 드시나요?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      for (final h in _options)
                        _HourTile(
                          h: h,
                          onTap: _busy ? null : () => _pick(h),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HourTile extends StatelessWidget {
  final int h;
  final VoidCallback? onTap;
  const _HourTile({required this.h, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFFFE0B2)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$h시',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: JTheme.seniorText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
