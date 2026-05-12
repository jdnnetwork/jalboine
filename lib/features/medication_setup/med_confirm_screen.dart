import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/supabase.dart';
import '../../services/audio_service.dart';
import '../../services/notification_service.dart';
import '../../services/onboarding_settings_service.dart';

const _ink = Color(0xFF1A1A2E);
const _accentPink = Color(0xFFFF6B8A);
const _yesStart = Color(0xFFFF2D6F);
const _yesEnd = Color(0xFFFF5A8A);
const _noBg = Color(0xFFF0F0F0);
const _noFg = Color(0xFF2D2D2D);
const _cardBg = Color(0xFFFFF0F0);
const _cardInk = Color(0xFF3E2723);

const _audioConfirm = 'assets/audio/alarm_confirm.wav';

/// 화면 7-5: 약 알림 확인.
///
/// 네 → medications 저장 (alarm_enabled=true) + 알림 스케줄 → 알림 권한 화면(yes)
/// 아니요 → medications 저장 (alarm_enabled=false) → "나중에" 2초 → 알림 권한 화면(no)
class MedConfirmScreen extends ConsumerStatefulWidget {
  final List<String> times;
  final int count;
  final List<String> slots;
  const MedConfirmScreen({
    super.key,
    required this.times,
    required this.count,
    required this.slots,
  });

  @override
  ConsumerState<MedConfirmScreen> createState() => _MedConfirmScreenState();
}

class _MedConfirmScreenState extends ConsumerState<MedConfirmScreen> {
  bool _declined = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(audioGuideModeProvider)) {
        AudioService.instance.play(_audioConfirm);
      }
    });
  }

  Future<void> _saveMedications({required bool alarmEnabled}) async {
    final sb = ref.read(supabaseProvider);
    final user = sb.auth.currentUser;
    if (user == null) return;
    final uid = user.id;
    final timesWithSec = widget.times.map((t) => '$t:00').toList();
    // medications.user_id 에 unique 제약이 (오래된 DB 의 경우) 없을 수 있어
    // upsert 가 매번 새 row 를 만든다. 안전하게 delete → insert.
    await sb.from('medications').delete().eq('user_id', uid);
    await sb.from('medications').insert({
      'user_id': uid,
      'frequency': widget.count,
      'times_per_day': widget.count,
      'times': timesWithSec,
      'alarm_enabled': alarmEnabled,
    });
    if (alarmEnabled) {
      await NotificationService.instance.rescheduleMedications(timesWithSec);
    } else {
      await NotificationService.instance.cancelAll();
    }
  }

  Future<void> _onYes() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _saveMedications(alarmEnabled: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _busy = false);
      return;
    }
    if (!mounted) return;
    context.go('/permission/notification?med_alarm=true');
  }

  Future<void> _onNo() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _declined = true;
    });
    try {
      await _saveMedications(alarmEnabled: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() {
        _busy = false;
        _declined = false;
      });
      return;
    }
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    context.go('/permission/notification?med_alarm=false');
  }

  Future<void> _onToggleAudio() async {
    final on = ref.read(audioGuideModeProvider);
    if (on) {
      await AudioService.instance.stop();
      await OnboardingSettingsService.setAudioGuide(ref, false);
    } else {
      await AudioService.instance.play(_audioConfirm);
    }
  }

  String _slotKeyForIndex(int idx) {
    if (idx < widget.slots.length) return widget.slots[idx];
    if (widget.count == 2) return idx == 0 ? 'morning' : 'evening';
    if (widget.count == 3) {
      return switch (idx) {
        0 => 'morning',
        1 => 'lunch',
        _ => 'evening',
      };
    }
    return '';
  }

  List<_TimeCardData> get _cards {
    final out = <_TimeCardData>[];
    for (var i = 0; i < widget.times.length; i++) {
      final t = widget.times[i];
      final parts = t.split(':');
      final h24 = int.tryParse(parts.first) ?? 0;
      out.add(_TimeCardData(slotKey: _slotKeyForIndex(i), hour24: h24));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final guideOn = ref.watch(audioGuideModeProvider);
    final bubbleText = _declined
        ? '나중에 다시\n설정할 수 있어요'
        : '이 시간에 큰 알림으로\n알려드릴까요?';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              _MascotWithBubble(text: bubbleText),
              const SizedBox(height: 20),
              if (!_declined)
                ...[
                  for (final c in _cards) ...[
                    _TimeCard(data: c),
                    const SizedBox(height: 12),
                  ],
                ],
              const Spacer(flex: 2),
              if (!_declined)
                Row(
                  children: [
                    Expanded(
                      child: _YesButton(onTap: _busy ? null : _onYes),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _NoButton(onTap: _busy ? null : _onNo),
                    ),
                  ],
                ),
              const Spacer(flex: 1),
              _AudioBar(on: guideOn, onTap: _onToggleAudio),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeCardData {
  final String slotKey;
  final int hour24;
  const _TimeCardData({required this.slotKey, required this.hour24});
}

class _TimeCard extends StatelessWidget {
  final _TimeCardData data;
  const _TimeCard({required this.data});

  String get _label {
    final slot = switch (data.slotKey) {
      'morning' => '아침',
      'lunch' => '점심',
      'evening' => '저녁',
      _ => '',
    };
    final h24 = data.hour24;
    final h12 = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
    if (slot.isEmpty) {
      final ampm = h24 < 12 ? '오전' : '오후';
      return '$ampm $h12시';
    }
    return '$slot $h12시';
  }

  IconData get _icon {
    return data.slotKey == 'evening'
        ? Icons.nightlight_round
        : Icons.wb_sunny_rounded;
  }

  Color get _iconColor {
    return data.slotKey == 'evening'
        ? const Color(0xFF6D4C41)
        : const Color(0xFFFFA000);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentPink, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_icon, color: _iconColor, size: 28),
          const SizedBox(width: 10),
          Text(
            _label,
            style: GoogleFonts.notoSansKr(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _cardInk,
              letterSpacing: -0.8,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MascotWithBubble extends StatelessWidget {
  final String text;
  const _MascotWithBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 84),
          child: _BubbleWithTail(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: _ink,
                height: 1.25,
                letterSpacing: -1.2,
              ),
            ),
          ),
        ),
        Image.asset(
          'assets/images/mascot.png',
          width: 120,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

class _BubbleWithTail extends StatelessWidget {
  final Widget child;
  const _BubbleWithTail({required this.child});

  static const double _tailH = 18;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _BubblePainter(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, _tailH + 24, 20, 24),
        child: child,
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const r = 20.0;
    const tailW = 36.0;
    const tailH = _BubbleWithTail._tailH;
    final cx = size.width / 2;
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(r, tailH)
      ..lineTo(cx - tailW / 2, tailH)
      ..lineTo(cx, 0)
      ..lineTo(cx + tailW / 2, tailH)
      ..lineTo(w - r, tailH)
      ..arcToPoint(Offset(w, tailH + r), radius: const Radius.circular(r))
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: const Radius.circular(r))
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: const Radius.circular(r))
      ..lineTo(0, tailH + r)
      ..arcToPoint(Offset(r, tailH), radius: const Radius.circular(r))
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = _accentPink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) => false;
}

class _YesButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _YesButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_yesStart, _yesEnd],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _yesStart.withValues(alpha: 0.35),
              offset: const Offset(0, 8),
              blurRadius: 18,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '네',
          style: GoogleFonts.notoSansKr(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1.2,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _NoButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _NoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: _noBg,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          '아니요',
          style: GoogleFonts.notoSansKr(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: _noFg,
            letterSpacing: -1.2,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _AudioBar extends StatelessWidget {
  final bool on;
  final VoidCallback onTap;
  const _AudioBar({required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = on ? '음성 안내 끄기' : '음성 안내 듣기';
    final icon = on ? Icons.volume_off_rounded : Icons.volume_up_rounded;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _ink, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _ink, size: 32),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
