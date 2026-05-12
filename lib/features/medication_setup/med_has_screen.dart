import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/supabase.dart';
import '../../services/audio_service.dart';
import '../../services/onboarding_settings_service.dart';

const _ink = Color(0xFF1A1A2E);
const _subtitle = Color(0xFF555555);
const _bubblePink = Color(0xFFFFD1DC);
const _yesStart = Color(0xFFFF2D6F);
const _yesEnd = Color(0xFFFF5A8A);
const _noBg = Color(0xFFF0F0F0);
const _noFg = Color(0xFF2D2D2D);

const _audioAsset = 'assets/audio/medicine_q.wav';

/// 화면 7-1: 약 복용 여부.
class MedHasScreen extends ConsumerStatefulWidget {
  const MedHasScreen({super.key});

  @override
  ConsumerState<MedHasScreen> createState() => _MedHasScreenState();
}

class _MedHasScreenState extends ConsumerState<MedHasScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(audioGuideModeProvider)) {
        AudioService.instance.play(_audioAsset);
      }
    });
  }

  Future<void> _answer(bool yes) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final sb = ref.read(supabaseProvider);
      final uid = sb.auth.currentUser!.id;
      await sb
          .from('senior_settings')
          .upsert({'user_id': uid, 'takes_medication': yes});
      if (!mounted) return;
      if (yes) {
        context.go('/med/count');
      } else {
        context.go('/setup-done');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _busy = false);
    }
  }

  Future<void> _onToggleAudio() async {
    final on = ref.read(audioGuideModeProvider);
    if (on) {
      await AudioService.instance.stop();
      await OnboardingSettingsService.setAudioGuide(ref, false);
    } else {
      await AudioService.instance.play(_audioAsset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guideOn = ref.watch(audioGuideModeProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const _MascotWithBubble(),
              const Spacer(flex: 2),
              Row(
                children: [
                  Expanded(
                    child: _YesButton(
                      onTap: _busy ? null : () => _answer(true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _NoButton(
                      onTap: _busy ? null : () => _answer(false),
                    ),
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

class _MascotWithBubble extends StatelessWidget {
  const _MascotWithBubble();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 100),
          child: _BubbleWithTail(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '혹시 약을\n드시고 계신가요?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    height: 1.2,
                    letterSpacing: -1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '알려주시면, 약 복용 시간을\n알림으로 알려드릴게요',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: _subtitle,
                    height: 1.4,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        Image.asset(
          'assets/images/mascot.png',
          width: 140,
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
      ..arcToPoint(
        Offset(w, tailH + r),
        radius: const Radius.circular(r),
      )
      ..lineTo(w, h - r)
      ..arcToPoint(
        Offset(w - r, h),
        radius: const Radius.circular(r),
      )
      ..lineTo(r, h)
      ..arcToPoint(
        Offset(0, h - r),
        radius: const Radius.circular(r),
      )
      ..lineTo(0, tailH + r)
      ..arcToPoint(
        Offset(r, tailH),
        radius: const Radius.circular(r),
      )
      ..close();

    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = _bubblePink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
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
        height: 150,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '네',
              style: GoogleFonts.notoSansKr(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1.2,
                height: 1.0,
              ),
            ),
          ],
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
        height: 150,
        decoration: BoxDecoration(
          color: _noBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _noFg, width: 4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '아니요',
              style: GoogleFonts.notoSansKr(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: _noFg,
                letterSpacing: -1.2,
                height: 1.0,
              ),
            ),
          ],
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
