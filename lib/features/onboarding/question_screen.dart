import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/audio_service.dart';
import '../../services/onboarding_settings_service.dart';

/// 앱 선택 6개 질문 공용 화면 — 마스코트 + 말풍선 + 네/아니요 + 음성 토글.
class QuestionScreen extends ConsumerWidget {
  final String question;
  final String subtitle; // 미사용 (호환을 위해 시그니처 유지)
  final String audioAsset;
  final int step;
  final int total;
  final void Function(bool yes) onAnswer;

  const QuestionScreen({
    super.key,
    required this.question,
    this.subtitle = '',
    required this.audioAsset,
    required this.step,
    required this.total,
    required this.onAnswer,
  });

  static const _ink = Color(0xFF1A1A2E);
  static const _bubbleBorder = Color(0xFFFFD1DC);
  static const _accentRed = Color(0xFFFF2D6F);
  static const _accentRedLight = Color(0xFFFF5A8A);
  static const _noBg = Color(0xFFF0F0F0);
  static const _noFg = Color(0xFF2D2D2D);

  void _tap(bool yes) {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
    onAnswer(yes);
  }

  Future<void> _onToggleAudio(WidgetRef ref) async {
    final guideOn = ref.read(audioGuideModeProvider);
    if (guideOn) {
      await AudioService.instance.stop();
      await OnboardingSettingsService.setAudioGuide(ref, false);
    } else {
      await AudioService.instance.play(audioAsset);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideOn = ref.watch(audioGuideModeProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              const Spacer(flex: 1),
              _MascotBubble(
                question: question,
                bubbleBorder: _bubbleBorder,
                ink: _ink,
              ),
              const Spacer(flex: 1),
              Row(
                children: [
                  Expanded(
                    child: _AnswerButton(
                      label: '네',
                      gradStart: _accentRed,
                      gradEnd: _accentRedLight,
                      fg: Colors.white,
                      onTap: () => _tap(true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _AnswerButton(
                      label: '아니요',
                      bg: _noBg,
                      fg: _noFg,
                      onTap: () => _tap(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _AudioToggle(
                guideOn: guideOn,
                onTap: () => _onToggleAudio(ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 마스코트가 말풍선 위로 걸치는 Stack 레이아웃.
class _MascotBubble extends StatelessWidget {
  final String question;
  final Color bubbleBorder;
  final Color ink;
  const _MascotBubble({
    required this.question,
    required this.bubbleBorder,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    const mascotSize = 140.0;
    const mascotOverlap = 40.0;
    final bubbleW = MediaQuery.of(context).size.width * 0.90;
    return SizedBox(
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // 말풍선 (마스코트 아래에서 시작, 비포지셔닝 → Stack 크기 결정)
          Padding(
            padding: const EdgeInsets.only(top: mascotSize - mascotOverlap),
            child: SizedBox(
              width: bubbleW,
              child: Column(
                children: [
                  CustomPaint(
                    size: const Size(22, 12),
                    painter: _TailPainter(
                      border: bubbleBorder,
                      fill: Colors.white,
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: bubbleBorder, width: 2),
                    ),
                    child: Text(
                      question,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: ink,
                        height: 1.25,
                        letterSpacing: -1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 마스코트 (말풍선 위 걸침)
          Image.asset(
            'assets/images/mascot.png',
            width: mascotSize,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  final Color border;
  final Color fill;
  _TailPainter({required this.border, required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final apex = Offset(size.width / 2, 0);
    final left = Offset(0, size.height);
    final right = Offset(size.width, size.height);

    final fillPath = Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(fillPath, Paint()..color = fill);

    final stroke = Paint()
      ..color = border
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(apex, left, stroke);
    canvas.drawLine(apex, right, stroke);
  }

  @override
  bool shouldRepaint(covariant _TailPainter old) =>
      old.border != border || old.fill != fill;
}

/// 네/아니요 버튼: 위 큰 빈 원형 + 아래 텍스트
class _AnswerButton extends StatelessWidget {
  final String label;
  final Color? gradStart;
  final Color? gradEnd;
  final Color? bg;
  final Color fg;
  final VoidCallback onTap;
  const _AnswerButton({
    required this.label,
    required this.fg,
    required this.onTap,
    this.gradStart,
    this.gradEnd,
    this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final hasGradient = gradStart != null && gradEnd != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: hasGradient ? null : bg,
          gradient: hasGradient
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [gradStart!, gradEnd!],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: hasGradient
              ? [
                  BoxShadow(
                    color: gradStart!.withValues(alpha: 0.30),
                    offset: const Offset(0, 8),
                    blurRadius: 18,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: fg, width: 4),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.notoSansKr(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  letterSpacing: -1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 음성 안내 토글 — 흰 배경 + 검은 2px 테두리, 알약형
class _AudioToggle extends StatelessWidget {
  final bool guideOn;
  final VoidCallback onTap;
  const _AudioToggle({required this.guideOn, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = guideOn ? '음성 안내 끄기' : '음성 안내 듣기';
    final icon = guideOn ? Icons.volume_off_rounded : Icons.volume_up_rounded;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1A1A2E),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF1A1A2E), size: 30),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
