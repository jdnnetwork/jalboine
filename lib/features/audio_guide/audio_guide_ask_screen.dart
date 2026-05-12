import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/onboarding_settings_service.dart';

/// 시작하기 직후 - 음성 안내 모드(audio_guide_mode) 선택.
class AudioGuideAskScreen extends ConsumerStatefulWidget {
  const AudioGuideAskScreen({super.key});

  @override
  ConsumerState<AudioGuideAskScreen> createState() =>
      _AudioGuideAskScreenState();
}

class _AudioGuideAskScreenState extends ConsumerState<AudioGuideAskScreen> {
  static const _ink = Color(0xFF1A1A2E);
  static const _bubbleText = Color(0xFF3E2723);
  static const _hint = Color(0xFF888888);
  static const _accentRed = Color(0xFFFF2D6F);
  static const _accentRedLight = Color(0xFFFF5A8A);
  static const _bubbleBorder = Color(0xFFFFD1DC);
  static const _noBg = Color(0xFFF0F0F0);
  static const _noFg = Color(0xFF2D2D2D);
  static const _orangeStart = Color(0xFFFF6F00);
  static const _orangeEnd = Color(0xFFFF9800);

  bool _busy = false;
  bool _showHint = false;
  final _player = AudioPlayer();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _onYes() async {
    if (_busy) return;
    setState(() => _busy = true);
    await OnboardingSettingsService.setAudioGuide(ref, true);
    if (!mounted) return;
    context.go('/font-size');
  }

  Future<void> _onNo() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _showHint = true;
    });
    await OnboardingSettingsService.setAudioGuide(ref, false);
    if (!mounted) return;
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    context.go('/font-size');
  }

  Future<void> _playVoice() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/onboarding1.wav'));
    } catch (_) {
      // 파일 없거나 재생 실패 시 무시
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),
              const _MascotBubble(
                bubbleBorder: _bubbleBorder,
                bubbleText: _bubbleText,
                accent: _accentRed,
              ),
              const Spacer(flex: 1),
              Text(
                '음성으로\n안내를 드릴까요?',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -1.8,
                  height: 1.15,
                ),
              ),
              const Spacer(flex: 1),
              if (_showHint)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '음성 안내가 필요하시면, 언제든 음성 안내를 켤 수 있어요',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: _hint,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: _GradientButton(
                      label: '네',
                      gradStart: _accentRed,
                      gradEnd: _accentRedLight,
                      fg: Colors.white,
                      onTap: _onYes,
                      enabled: !_busy,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SolidButton(
                      label: '아니요',
                      bg: _noBg,
                      fg: _noFg,
                      onTap: _onNo,
                      enabled: !_busy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _ListenButton(
                gradStart: _orangeStart,
                gradEnd: _orangeEnd,
                onTap: _playVoice,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MascotBubble extends StatelessWidget {
  final Color bubbleBorder;
  final Color bubbleText;
  final Color accent;
  const _MascotBubble({
    required this.bubbleBorder,
    required this.bubbleText,
    required this.accent,
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
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: bubbleBorder, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text.rich(
                          textAlign: TextAlign.center,
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '어르신이 ',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: bubbleText,
                                  height: 1.4,
                                ),
                              ),
                              TextSpan(
                                text: '쉽게',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                  height: 1.4,
                                ),
                              ),
                              TextSpan(
                                text: ' 스마트폰을',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: bubbleText,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '사용할 수 있도록 도와드릴게요',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: bubbleText,
                            height: 1.4,
                          ),
                        ),
                        Text(
                          '차근 차근 따라오세요',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: bubbleText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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

class _GradientButton extends StatelessWidget {
  final String label;
  final Color gradStart;
  final Color gradEnd;
  final Color fg;
  final VoidCallback onTap;
  final bool enabled;
  const _GradientButton({
    required this.label,
    required this.gradStart,
    required this.gradEnd,
    required this.fg,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gradStart, gradEnd],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradStart.withValues(alpha: 0.30),
              offset: const Offset(0, 8),
              blurRadius: 18,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.notoSansKr(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: fg,
            letterSpacing: -1.2,
          ),
        ),
      ),
    );
  }
}

class _SolidButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  final bool enabled;
  const _SolidButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.notoSansKr(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: fg,
            letterSpacing: -1.2,
          ),
        ),
      ),
    );
  }
}

class _ListenButton extends StatelessWidget {
  final Color gradStart;
  final Color gradEnd;
  final VoidCallback onTap;
  const _ListenButton({
    required this.gradStart,
    required this.gradEnd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gradStart, gradEnd],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradStart.withValues(alpha: 0.30),
              offset: const Offset(0, 6),
              blurRadius: 14,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.volume_up_rounded,
                color: Colors.white, size: 30),
            const SizedBox(width: 10),
            Text(
              '음성 안내 듣기',
              style: GoogleFonts.notoSansKr(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
