import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/theme.dart';
import '../../widgets/back_pill.dart';

/// 화면 7-3: 약 복용 시간 선택. count(1/2/3)에 따라 반복.
class MedHourScreen extends ConsumerStatefulWidget {
  final int count;
  const MedHourScreen({super.key, required this.count});

  @override
  ConsumerState<MedHourScreen> createState() => _MedHourScreenState();
}

class _MedHourScreenState extends ConsumerState<MedHourScreen> {
  final List<int> _hours = [];
  static const _options = [6, 7, 8, 9, 10, 11, 12];

  String get _slotTitle {
    if (widget.count == 1) return '몇 시에 약을 드시나요?';
    final idx = _hours.length;
    if (widget.count == 2) {
      return idx == 0 ? '아침에 몇 시에 드시나요?' : '저녁에 몇 시에 드시나요?';
    }
    return switch (idx) {
      0 => '아침에 몇 시에 드시나요?',
      1 => '점심에 몇 시에 드시나요?',
      _ => '저녁에 몇 시에 드시나요?',
    };
  }

  Future<void> _pick(int h) async {
    setState(() => _hours.add(h));
    if (_hours.length >= widget.count) {
      final times = _hours
          .map((h) => '${h.toString().padLeft(2, '0')}:00')
          .toList();
      if (!mounted) return;
      context.go(
        '/med/confirm?times=${times.join(",")}&count=${widget.count}',
      );
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
                    _slotTitle,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: JD.ink,
                      letterSpacing: -1.0,
                      height: 1.25,
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
                          onTap: () => _pick(h),
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
