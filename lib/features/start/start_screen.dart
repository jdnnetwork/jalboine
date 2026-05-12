import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/device_auth_service.dart';

class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFFF5F2EC);
  static const _ink = Color(0xFF0A1A38);
  static const _orange = Color(0xFFD35400);
  static const _orangeLight = Color(0xFFEE8232);
  static const _orangeDark = Color(0xFF9E3F00);
  static const _heart = Color(0xFFFF5E89);

  bool _busy = false;

  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _topSlide;
  late final Animation<Offset> _bottomSlide;
  late final Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _topSlide = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));
    _bottomSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
    _btnScale = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.15, 1.0, curve: Curves.easeOutBack),
    ));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await DeviceAuthService.instance.ensureSenior();
      if (!mounted) return;
      context.go('/audio-guide-ask');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              SlideTransition(
                position: _topSlide,
                child: FadeTransition(
                  opacity: _fade,
                  child: const _Heading(ink: _ink, accent: _orange),
                ),
              ),
              const Spacer(flex: 2),
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _btnScale,
                  child: _StartButton(
                    busy: _busy,
                    onTap: _start,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              SlideTransition(
                position: _bottomSlide,
                child: FadeTransition(
                  opacity: _fade,
                  child: _GuardianCard(
                    onTap: () => context.go('/guardian/login'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final Color ink;
  final Color accent;
  const _Heading({required this.ink, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '잘보이네',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansKr(
            fontSize: 84,
            fontWeight: FontWeight.w900,
            color: ink,
            letterSpacing: -3.2,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '어르신을 위한',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansKr(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: ink,
            letterSpacing: -1.3,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '쉬운 스마트폰',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansKr(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: accent,
            letterSpacing: -1.3,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _StartButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onTap;
  const _StartButton({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: 1.05,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _StartScreenState._orangeLight,
                _StartScreenState._orange,
              ],
            ),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              // 두꺼운 아래 그림자 — 3D 입체감
              BoxShadow(
                color: _StartScreenState._orangeDark.withValues(alpha: 0.65),
                offset: const Offset(0, 14),
                blurRadius: 0,
              ),
              // 부드러운 외곽 글로우
              BoxShadow(
                color: _StartScreenState._orange.withValues(alpha: 0.35),
                offset: const Offset(0, 22),
                blurRadius: 36,
              ),
            ],
          ),
          child: Stack(
            children: [
              // 상단 하이라이트 (글로시 효과)
              Positioned(
                top: 16,
                left: 24,
                right: 24,
                height: 28,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '시작하기',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 78,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -3.0,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '이 버튼을 누르세요',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.92),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuardianCard extends StatelessWidget {
  final VoidCallback onTap;
  const _GuardianCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                offset: const Offset(0, 6),
                blurRadius: 18,
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: _StartScreenState._heart,
                size: 44,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '가족 및 어르신을',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _StartScreenState._ink,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '도와주시는 분은',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _StartScreenState._ink,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '여기를 눌러주세요',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _StartScreenState._orange,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
