import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/supabase.dart';
import '../../services/audio_service.dart';
import '../../services/onboarding_settings_service.dart';

const _ink = Color(0xFF1A1A2E);
const _accentPink = Color(0xFFFF6B8A);
const _cardInk = Color(0xFF3E2723);
const _guideBg = Color(0xFFFFF8E1);
const _emphasisRed = Color(0xFFD32F2F);

/// 화면 7-6: 알림 권한 안내.
///
/// 진입 경로 3가지:
///  1) 약 "아니요" — medicineAlarm=false, no_guide.wav
///  2) 약 시간 저장 + 알림 "네" — medicineAlarm=true, yes_guide.wav
///  3) 약 시간 저장 + 알림 "아니요" — medicineAlarm=false, no_guide.wav
class NotificationPermissionScreen extends ConsumerStatefulWidget {
  final bool medicineAlarm;
  const NotificationPermissionScreen({
    super.key,
    required this.medicineAlarm,
  });

  @override
  ConsumerState<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends ConsumerState<NotificationPermissionScreen> {
  bool _busy = false;

  String get _audioAsset => widget.medicineAlarm
      ? 'assets/audio/yes_guide.wav'
      : 'assets/audio/no_guide.wav';

  String get _bubbleText => widget.medicineAlarm
      ? '약 알림과 가족 메시지를\n받으려면 허락이 필요해요'
      : '가족이 보내는 메시지를\n받으려면 허락이 필요해요';

  String get _guideBottom => widget.medicineAlarm
      ? '허용을 누르시면\n약 드실 시간과 가족 메시지를\n알려드려요'
      : '허용을 누르시면\n가족 메시지를 알려드려요';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(audioGuideModeProvider)) {
        AudioService.instance.play(_audioAsset);
      }
    });
  }

  Future<void> _onConfirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final sb = ref.read(supabaseProvider);
      final uid = sb.auth.currentUser?.id;
      if (uid != null) {
        await sb
            .from('profiles')
            .update({'medicine_alarm': widget.medicineAlarm})
            .eq('user_id', uid);
      }
    } catch (_) {
      // 저장 실패해도 권한 요청은 진행 — 어르신을 막지 않는다.
    }
    await Permission.notification.request();
    if (!mounted) return;
    context.go('/onboarding/launcher-guide');
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      _MascotWithBubble(text: _bubbleText),
                      const SizedBox(height: 24),
                      _GuideCard(bottomText: _guideBottom),
                      const SizedBox(height: 24),
                      _OkButton(onTap: _busy ? null : _onConfirm),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              _AudioBar(on: guideOn, onTap: _onToggleAudio),
            ],
          ),
        ),
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

class _GuideCard extends StatelessWidget {
  final String bottomText;
  const _GuideCard({required this.bottomText});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _guideBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '곧 작은 창이 뜰 거예요',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _cardInk,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "거기에서 '허용'을\n꼭 눌러주세요",
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: _emphasisRed,
              letterSpacing: -1.0,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            bottomText,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _cardInk,
              letterSpacing: -0.6,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _OkButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _OkButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_emphasisRed, Color(0xFFFF6F00)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _emphasisRed.withValues(alpha: 0.40),
              offset: const Offset(0, 8),
              blurRadius: 18,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '알겠어요',
          style: GoogleFonts.notoSansKr(
            fontSize: 40,
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
