import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/supabase.dart';
import '../../services/audio_service.dart';
import '../../services/onboarding_settings_service.dart';

/// 글자 크기 설정 — 1단계 / 2단계 / 3단계 (최대) 내부 setState 로 전환.
/// 1·2단계: "글자가 잘 보이시나요?" 네=현재 level 저장 후 /age, 아니요=다음 단계.
/// 3단계: "이 크기가 최대에요... 음성으로 안내?" 네=voice_guide=true, 아니요=false.
class FontSizeScreen extends ConsumerStatefulWidget {
  final int level;
  const FontSizeScreen({super.key, required this.level});

  @override
  ConsumerState<FontSizeScreen> createState() => _FontSizeScreenState();
}

class _FontSizeScreenState extends ConsumerState<FontSizeScreen> {
  static const _bubbleText = Color(0xFF1A1A2E);
  static const _bubbleBorder = Color(0xFFFFD1DC);
  static const _accentRed = Color(0xFFFF2D6F);
  static const _accentRedLight = Color(0xFFFF5A8A);
  static const _noBg = Color(0xFFF0F0F0);
  static const _noFg = Color(0xFF2D2D2D);
  static const _orangeStart = Color(0xFFFF6F00);
  static const _orangeEnd = Color(0xFFFF9800);

  late int _level;
  bool _busy = false;

  bool get _isMax => _level >= 3;

  String get _currentAsset => _isMax
      ? 'assets/audio/voice_ask.wav'
      : 'assets/audio/font_check.wav';

  @override
  void initState() {
    super.initState();
    _level = widget.level;
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePlay());
  }

  void _maybePlay() {
    if (ref.read(audioGuideModeProvider)) {
      AudioService.instance.play(_currentAsset);
    }
  }

  Future<void> _saveLevel() async {
    final sb = ref.read(supabaseProvider);
    final uid = sb.auth.currentUser!.id;
    await sb
        .from('profiles')
        .update({'font_size_level': _level}).eq('user_id', uid);
  }

  Future<void> _confirmLevel() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _saveLevel();
      await OnboardingSettingsService.setVoiceGuide(ref, false);
      if (!mounted) return;
      context.go('/age');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _busy = false);
    }
  }

  Future<void> _confirmVoiceGuide(bool yes) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _saveLevel();
      await OnboardingSettingsService.setVoiceGuide(ref, yes);
      if (!mounted) return;
      context.go('/age');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _busy = false);
    }
  }

  void _goNextLevel() {
    setState(() => _level += 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePlay());
  }

  void _onYes() {
    if (_isMax) {
      _confirmVoiceGuide(true);
    } else {
      _confirmLevel();
    }
  }

  void _onNo() {
    if (_isMax) {
      _confirmVoiceGuide(false);
    } else {
      _goNextLevel();
    }
  }

  Future<void> _onToggleAudio() async {
    final guideOn = ref.read(audioGuideModeProvider);
    if (guideOn) {
      await AudioService.instance.stop();
      await OnboardingSettingsService.setAudioGuide(ref, false);
    } else {
      await AudioService.instance.play(_currentAsset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guideOn = ref.watch(audioGuideModeProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: LayoutBuilder(
            builder: (context, c) {
              final h = c.maxHeight;
              final topH = h * 0.55;
              final bottomH = h - topH;
              return Column(
                children: [
                  SizedBox(
                    height: topH,
                    child: _MascotBubble(
                      level: _level,
                      bubbleBorder: _bubbleBorder,
                      bubbleText: _bubbleText,
                    ),
                  ),
                  SizedBox(
                    height: bottomH,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(height: 8),
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
                        _AudioToggle(
                          guideOn: guideOn,
                          gradStart: _orangeStart,
                          gradEnd: _orangeEnd,
                          onTap: _onToggleAudio,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 마스코트가 말풍선 위로 걸치는 Stack 레이아웃.
class _MascotBubble extends StatelessWidget {
  final int level;
  final Color bubbleBorder;
  final Color bubbleText;
  const _MascotBubble({
    required this.level,
    required this.bubbleBorder,
    required this.bubbleText,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const mascotSize = 160.0;
        const mascotOverlap = 50.0; // 말풍선 위로 걸치는 양
        final bubbleW = c.maxWidth * 0.85;
        final bubbleTop = mascotSize - mascotOverlap;
        return Stack(
          children: [
            // 말풍선 (마스코트 아래에서 시작)
            Positioned(
              top: bubbleTop,
              left: (c.maxWidth - bubbleW) / 2,
              width: bubbleW,
              child: Column(
                children: [
                  // 위 삼각형 꼬리
                  CustomPaint(
                    size: const Size(22, 12),
                    painter: _TailPainter(
                      border: bubbleBorder,
                      fill: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: bubbleBorder, width: 2),
                    ),
                    child: _BubbleText(level: level, color: bubbleText),
                  ),
                ],
              ),
            ),
            // 마스코트 (위에 걸침)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: mascotSize,
              child: Center(
                child: Image.asset(
                  'assets/images/mascot.png',
                  width: mascotSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BubbleText extends StatelessWidget {
  final int level;
  final Color color;
  const _BubbleText({required this.level, required this.color});

  TextStyle _t(double size) => GoogleFonts.notoSansKr(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.25,
        letterSpacing: -1.2,
      );

  @override
  Widget build(BuildContext context) {
    if (level <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('글자가', textAlign: TextAlign.center, style: _t(44)),
          Text('잘 보이시나요?', textAlign: TextAlign.center, style: _t(44)),
        ],
      );
    }
    if (level == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('글자가', textAlign: TextAlign.center, style: _t(52)),
          Text('잘 보이시나요?', textAlign: TextAlign.center, style: _t(52)),
        ],
      );
    }
    // level >= 3
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('이 크기가 최대에요.',
            textAlign: TextAlign.center, style: _t(52)),
        const SizedBox(height: 8),
        Text('버튼을 누를 때마다',
            textAlign: TextAlign.center, style: _t(44)),
        Text('음성으로 안내해',
            textAlign: TextAlign.center, style: _t(44)),
        Text('드릴까요?', textAlign: TextAlign.center, style: _t(44)),
      ],
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

class _AudioToggle extends StatelessWidget {
  final bool guideOn;
  final Color gradStart;
  final Color gradEnd;
  final VoidCallback onTap;
  const _AudioToggle({
    required this.guideOn,
    required this.gradStart,
    required this.gradEnd,
    required this.onTap,
  });

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
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(width: 10),
            Text(
              label,
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
