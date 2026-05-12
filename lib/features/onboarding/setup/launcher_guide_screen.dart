import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/supabase.dart';
import '../../../services/audio_service.dart';
import '../../../services/onboarding_settings_service.dart';
import '../../../services/onboarding_setup_service.dart';
import '../../../services/onboarding_status.dart';

const _ink = Color(0xFF1A1A2E);
const _accentPink = Color(0xFFFF6B8A);
const _cardBg = Color(0xFFF5F5F5);
const _cardInk = Color(0xFF3E2723);
const _emphasisRed = Color(0xFFD32F2F);
const _subText = Color(0xFF555555);
const _popupBorder = Color(0xFFDDDDDD);
const _popupGray = Color(0xFF888888);

const _audioAsset = 'assets/audio/setting_permission.wav';

enum _Stage { initial, success, fail1, fail2 }

/// 화면 8: 런처 설정 안내 (온보딩 최종).
///
/// 알겠어요 → requestDefaultLauncher() → 시스템 다이얼로그 → resume 후 결과 판정
///  - 잘보이네 선택 → success → 1.5초 후 /home
///  - 다른 런처 1회 → fail1 → 다시 해볼게요
///  - 다른 런처 2회 → fail2 → 다음에 할게요 → /home (launcher_set=false)
class LauncherGuideScreen extends ConsumerStatefulWidget {
  const LauncherGuideScreen({super.key});

  @override
  ConsumerState<LauncherGuideScreen> createState() =>
      _LauncherGuideScreenState();
}

class _LauncherGuideScreenState extends ConsumerState<LauncherGuideScreen>
    with WidgetsBindingObserver {
  _Stage _stage = _Stage.initial;
  bool _checking = true;
  bool _awaiting = false;
  bool _busy = false;
  int _failures = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialCheck());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initialCheck() async {
    final isDefault =
        await OnboardingSetupService.instance.isDefaultLauncher();
    if (!mounted) return;
    if (isDefault) {
      await _finishSuccess();
      return;
    }
    setState(() => _checking = false);
    if (ref.read(audioGuideModeProvider)) {
      AudioService.instance.play(_audioAsset);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_awaiting) return;
    _awaiting = false;
    _handleReturnFromSystem();
  }

  Future<void> _handleReturnFromSystem() async {
    final isDefault =
        await OnboardingSetupService.instance.isDefaultLauncher();
    if (!mounted) return;
    if (isDefault) {
      await _finishSuccess();
      return;
    }
    _failures++;
    setState(() {
      _stage = _failures >= 2 ? _Stage.fail2 : _Stage.fail1;
    });
  }

  Future<void> _onConfirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    _awaiting = true;
    await OnboardingSetupService.instance.requestDefaultLauncher();
    if (!mounted) return;
    setState(() => _busy = false);
  }

  Future<void> _onSkip() async {
    if (_busy) return;
    setState(() => _busy = true);
    await _saveFlags(launcherSet: false);
    if (!mounted) return;
    context.go('/home');
  }

  Future<void> _finishSuccess() async {
    setState(() => _stage = _Stage.success);
    await _saveFlags(launcherSet: true);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    context.go('/home');
  }

  Future<void> _saveFlags({required bool launcherSet}) async {
    await OnboardingStatus.save(launcherSet: launcherSet);
    try {
      final sb = ref.read(supabaseProvider);
      final uid = sb.auth.currentUser?.id;
      if (uid != null) {
        await sb.from('profiles').update({
          'onboarding_complete': true,
          'launcher_set': launcherSet,
        }).eq('user_id', uid);
      }
    } catch (_) {}
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
    if (_checking) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
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
                  child: _buildContent(),
                ),
              ),
              if (_stage != _Stage.success)
                _AudioBar(on: guideOn, onTap: _onToggleAudio),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return switch (_stage) {
      _Stage.initial => _buildInitialOrFail1(
          bubbleText: '이제 마지막이에요!\n제일 중요해요',
          bubbleSize: 32,
          bubbleColor: _ink,
          buttonLabel: '알겠어요!',
        ),
      _Stage.fail1 => _buildInitialOrFail1(
          bubbleText: '잘못 선택하셨어요\n다시 한 번 해볼게요',
          bubbleSize: 32,
          bubbleColor: _emphasisRed,
          buttonLabel: '다시 해볼게요',
        ),
      _Stage.success => _buildSuccess(),
      _Stage.fail2 => _buildFail2(),
    };
  }

  Widget _buildInitialOrFail1({
    required String bubbleText,
    required double bubbleSize,
    required Color bubbleColor,
    required String buttonLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        _MascotWithBubble(
          text: bubbleText,
          fontSize: bubbleSize,
          color: bubbleColor,
        ),
        const SizedBox(height: 20),
        const _GuideCardWithFakePopup(),
        const SizedBox(height: 20),
        _PrimaryButton(
          label: buttonLabel,
          onTap: _busy ? null : _onConfirm,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const _MascotWithBubble(
          text: '잘 하셨어요! 🎉',
          fontSize: 36,
          color: _ink,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildFail2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const _MascotWithBubble(
          text: '기본 홈 화면을\n사용하고 싶으신가 보군요',
          fontSize: 28,
          color: _ink,
        ),
        const SizedBox(height: 24),
        Text(
          '괜찮아요!\n앱을 열면 언제든\n다시 설정할 수 있어요',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansKr(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: _subText,
            height: 1.4,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 32),
        _PrimaryButton(
          label: '다음에 할게요',
          onTap: _busy ? null : _onSkip,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _MascotWithBubble extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  const _MascotWithBubble({
    required this.text,
    required this.fontSize,
    required this.color,
  });

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
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.25,
                letterSpacing: -1.0,
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

class _GuideCardWithFakePopup extends StatelessWidget {
  const _GuideCardWithFakePopup();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '곧 알림이 하나 뜰 거예요',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _cardInk,
              letterSpacing: -0.6,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '잘보이네 앱을 기본 홈 앱으로\n설정하시겠습니까?',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: _subText,
              letterSpacing: -0.5,
              height: 1.35,
            ),
          ),
          Text(
            '라는 말이 나올 거예요',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: _subText,
              letterSpacing: -0.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '여기서 👇',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _emphasisRed,
              letterSpacing: -0.6,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          const _FakeSystemPopup(),
        ],
      ),
    );
  }
}

class _FakeSystemPopup extends StatelessWidget {
  const _FakeSystemPopup();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _popupBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '기본 홈 앱으로 설정',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.4,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.radio_button_checked,
                color: _emphasisRed,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                '잘보이네',
                style: GoogleFonts.notoSansKr(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _emphasisRed,
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '👈 이걸 눌러주세요!',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _emphasisRed,
                    letterSpacing: -0.4,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.radio_button_unchecked,
                color: _popupGray,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                'One UI 홈',
                style: GoogleFonts.notoSansKr(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: _popupGray,
                  letterSpacing: -0.4,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 90,
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
          label,
          style: GoogleFonts.notoSansKr(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1.0,
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
