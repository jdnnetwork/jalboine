import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/device_auth_service.dart';

class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen>
    with TickerProviderStateMixin {
  static const _ink = Color(0xFF3E2723);
  static const _inkSoft = Color(0xFF5D4037);
  static const _gray = Color(0xFF888888);
  static const _redA = Color(0xFFFF416C);
  static const _redB = Color(0xFFFF4B2B);

  bool _busy = false;

  // 등장 애니메이션 (총 1.1초)
  late final AnimationController _entryCtrl;
  late final Animation<Offset> _redSlide;
  late final Animation<Offset> _topSlide;
  late final Animation<double> _topFade;
  late final Animation<Offset> _bottomSlide;
  late final Animation<double> _bottomFade;

  // 마스코트 둥둥 (등장 완료 후 무한 반복)
  late final AnimationController _bobCtrl;
  late final Animation<double> _bobAnim;
  bool _entryDone = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _bobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _bobAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _bobCtrl, curve: Curves.easeInOut),
    );

    Animation<double> ival(double a, double b) => CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(a, b, curve: Curves.easeOutCubic),
        );

    // 1단계 빨강: 0 ~ 0.5s → 0 ~ 0.4545 of 1.1s
    _redSlide = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(ival(0.0, 0.4545));

    // 2단계 상단: 0.4 ~ 0.9s → 0.3636 ~ 0.8182
    _topSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(ival(0.3636, 0.8182));
    _topFade = ival(0.3636, 0.8182);

    // 3단계 하단: 0.6 ~ 1.1s → 0.5454 ~ 1.0
    _bottomSlide = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(ival(0.5454, 1.0));
    _bottomFade = ival(0.5454, 1.0);

    _entryCtrl.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _entryDone = true);
      _bobCtrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _bobCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await DeviceAuthService.instance.ensureSenior();
      if (!mounted) return;
      context.go('/onboarding/terms');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final h = c.maxHeight;
            const mascotSize = 120.0;
            const mascotOverlap = 30.0; // 빨강 영역 위로 살짝 걸치는 양
            final redH = h * 0.35;
            final topH = (h - redH) / 2;
            final bottomH = h - topH - redH;

            return Stack(
              children: [
                // 흰 배경 (전체)
                Positioned.fill(child: Container(color: Colors.white)),

                // 상단 영역 — 텍스트만 (마스코트는 별도 Positioned)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: topH,
                  child: SlideTransition(
                    position: _topSlide,
                    child: FadeTransition(
                      opacity: _topFade,
                      child: _TopText(ink: _ink, inkSoft: _inkSoft),
                    ),
                  ),
                ),

                // 하단 영역 — 보호자 링크
                Positioned(
                  top: topH + redH,
                  left: 0,
                  right: 0,
                  height: bottomH,
                  child: SlideTransition(
                    position: _bottomSlide,
                    child: FadeTransition(
                      opacity: _bottomFade,
                      child: _BottomLink(
                        onTap: () => context.go('/guardian/login'),
                        ink: _ink,
                        gray: _gray,
                      ),
                    ),
                  ),
                ),

                // 중간 빨강 영역 — 시작하기 버튼 (왼쪽에서 슬라이드)
                Positioned(
                  top: topH,
                  left: 0,
                  right: 0,
                  height: redH,
                  child: SlideTransition(
                    position: _redSlide,
                    child: _StartArea(
                      busy: _busy,
                      onTap: _start,
                      gradA: _redA,
                      gradB: _redB,
                    ),
                  ),
                ),

                // 마스코트 — 빨강 영역 위로 mascotOverlap 만큼 걸침
                Positioned(
                  top: topH - mascotSize + mascotOverlap,
                  left: 0,
                  right: 0,
                  height: mascotSize,
                  child: SlideTransition(
                    position: _topSlide,
                    child: FadeTransition(
                      opacity: _topFade,
                      child: AnimatedBuilder(
                        animation: _bobAnim,
                        builder: (_, child) => Transform.translate(
                          offset:
                              Offset(0, _entryDone ? _bobAnim.value : 0),
                          child: child,
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/mascot.png',
                            width: mascotSize,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopText extends StatelessWidget {
  final Color ink;
  final Color inkSoft;
  const _TopText({required this.ink, required this.inkSoft});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '잘보이네',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: ink,
              letterSpacing: -1.6,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '어르신을 위한 쉬운 스마트폰',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: inkSoft,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartArea extends StatelessWidget {
  final bool busy;
  final VoidCallback onTap;
  final Color gradA;
  final Color gradB;
  const _StartArea({
    required this.busy,
    required this.onTap,
    required this.gradA,
    required this.gradB,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gradA, gradB],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '→ 시작하기',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -1.6,
                  height: 1.05,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '(이 버튼을 누르세요)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: Color(0xCCFFFFFF),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomLink extends StatelessWidget {
  final VoidCallback onTap;
  final Color ink;
  final Color gray;
  const _BottomLink({
    required this.onTap,
    required this.ink,
    required this.gray,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '가족 및 부모님을 도와주시는 분은',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: gray,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                '여기를 클릭해주세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: ink,
                  decoration: TextDecoration.underline,
                  decorationColor: ink,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
