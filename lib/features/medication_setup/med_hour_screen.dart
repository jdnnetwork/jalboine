import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/back_pill.dart';

class MedHourScreen extends ConsumerStatefulWidget {
  final int count;
  const MedHourScreen({super.key, required this.count});

  @override
  ConsumerState<MedHourScreen> createState() => _MedHourScreenState();
}

class _MedHourScreenState extends ConsumerState<MedHourScreen> {
  final List<int> _hours = [];
  bool _busy = false;
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BackPill(onTap: () => context.go('/med/count')),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_hours.length + 1} / ${widget.count}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: JD.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _hours.isEmpty
                        ? '몇 시에\n드시나요?'
                        : '다음 시간을\n골라주세요',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: JD.ink,
                      letterSpacing: -1.0,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
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
      borderRadius: BorderRadius.circular(JD.rCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(JD.rCard),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(JD.rCard),
            boxShadow: JD.shadowCard,
          ),
          child: Center(
            child: Text(
              '$h시',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: JD.ink,
                letterSpacing: -1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
