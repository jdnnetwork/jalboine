import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/supabase.dart';
import '../../services/audio_service.dart';
import '../../services/onboarding_settings_service.dart';

/// 글자 크기 설정 — 1단계 / 2단계 / 3단계 (최대) 내부 setState 로 전환.
/// 1·2단계: "글자가 잘 보이시나요?" 네=현재 level 저장 후 /age,  아니요=다음 단계.
/// 3단계: "이 크기가 최대에요... 음성으로 안내?" 네=voice_guide=true, 아니요=false.
class FontSizeScreen extends ConsumerStatefulWidget {
  final int level;
  const FontSizeScreen({super.key, required this.level});

  @override
  ConsumerState<FontSizeScreen> createState() => _FontSizeScreenState();
}

class _FontSizeScreenState extends ConsumerState<FontSizeScreen> {
  static const _bubbleText = Color(0xFF3E2723);
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

  double get _bubbleFontSize => switch (_level) {
        1 => 36,
        _ => 44,
      };

  double get _buttonFontSize => switch (_level) {
        1 => 36,
        _ => 44,
      };

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
      // 끄기: 정지 + audio_guide_mode = false 저장
      await AudioService.instance.stop();
      await OnboardingSettingsService.setAudioGuide(ref, false);
    } else {
      // 듣기: 현재 단계 음성 재생
      await AudioService.instance.play(_currentAsset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guideOn = ref.watch(audioGuideModeProvider);
    final bubbleText = _isMax
        ? '이 크기가 최대에요. 대신 버튼을 누를 때마다 음성으로 안내해 드릴까요?'
        : '글자가 잘 보이시나요?';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Image.asset(
                  'assets/images/mascot.png',
                  width: 100,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 4),
              const _BubbleTail(
                border: _bubbleBorder,
                fill: Colors.white,
              ),
              _Bubble(
                border: _bubbleBorder,
                child: Text(
                  bubbleText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    fontSize: _bubbleFontSize,
                    fontWeight: FontWeight.w700,
                    color: _bubbleText,
                    height: 1.35,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: _GradientButton(
                      label: '네',
                      fontSize: _buttonFontSize,
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
                      fontSize: _buttonFontSize,
                      bg: _noBg,
                      fg: _noFg,
                      onTap: _onNo,
                      enabled: !_busy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _AudioToggle(
                guideOn: guideOn,
                gradStart: _orangeStart,
                gradEnd: _orangeEnd,
                onTap: _onToggleAudio,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Color border;
  final Widget child;
  const _Bubble({required this.border, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 2),
      ),
      child: child,
    );
  }
}

class _BubbleTail extends StatelessWidget {
  final Color border;
  final Color fill;
  const _BubbleTail({required this.border, required this.fill});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        size: const Size(20, 12),
        painter: _TailPainter(border: border, fill: fill),
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

    // 두 빗변만 그려서 말풍선 테두리와 자연스럽게 연결
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
  final double fontSize;
  final Color gradStart;
  final Color gradEnd;
  final Color fg;
  final VoidCallback onTap;
  final bool enabled;
  const _GradientButton({
    required this.label,
    required this.fontSize,
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
        height: 100,
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
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: fg,
            letterSpacing: -1.0,
          ),
        ),
      ),
    );
  }
}

class _SolidButton extends StatelessWidget {
  final String label;
  final double fontSize;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  final bool enabled;
  const _SolidButton({
    required this.label,
    required this.fontSize,
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
        height: 100,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.notoSansKr(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: fg,
            letterSpacing: -1.0,
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
