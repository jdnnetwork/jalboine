import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/device_auth_service.dart';
import '../../services/onboarding_status.dart';

class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen>
    with SingleTickerProviderStateMixin {
  bool _busy = false;

  late final AnimationController _ctrl;
  late final Animation<double> _floatAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    // 라우터 redirect 안전망 — 이미 온보딩 마친 익명 세션이면 곧장 /home 으로.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSkipToHome());

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: 0, end: -7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.018).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _maybeSkipToHome() async {
    if (!mounted) return;
    if (!OnboardingStatus.isLoaded) {
      await OnboardingStatus.load();
      if (!mounted) return;
    }
    if (!OnboardingStatus.isComplete) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || !user.isAnonymous) return;
    // ignore: avoid_print
    print('jalboine start: onboarding done + anon → skip to /home');
    context.go('/home');
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
      backgroundColor: const Color(0xFFF7F2EB),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 26,
                vertical: 20,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 22),

                  // TOP
                  Column(
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFFF7A3D),
                        size: 42,
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        '어르신을 위한',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3A2D26),
                          letterSpacing: -1.2,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: '쉬운 ',
                              style: TextStyle(
                                fontSize: 62,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFF07A34),
                                letterSpacing: -3,
                                height: 1,
                              ),
                            ),
                            TextSpan(
                              text: '스마트폰',
                              style: TextStyle(
                                fontSize: 62,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2E241F),
                                letterSpacing: -3,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // FLOATING START BUTTON
                  AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: Transform.scale(
                          scale: _scaleAnim.value,
                          child: child,
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: _busy ? null : _start,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 360,
                        height: 360,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFB869),
                              Color(0xFFE9782E),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.92),
                            width: 5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x33E9782E),
                              blurRadius: 42,
                              spreadRadius: 2,
                              offset: const Offset(0, 24),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.touch_app_rounded,
                              color: Colors.white,
                              size: 84,
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              '시작하기',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 72,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -4,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 26),
                            Container(
                              width: 220,
                              height: 2,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const SizedBox(height: 26),
                            const Text(
                              '눌러서 시작하세요',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -2,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // BOTTOM CARD — 보호자 진입
                  GestureDetector(
                    onTap: () => context.go('/guardian/login'),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 26,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.74),
                        borderRadius: BorderRadius.circular(34),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 86,
                            height: 86,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFFF1EA),
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFFFF7A55),
                              size: 46,
                            ),
                          ),
                          const SizedBox(width: 22),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '가족 및 어르신을\n도와주시는 분은',
                                  style: TextStyle(
                                    color: Color(0xFF3A2D26),
                                    fontSize: 30,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: const [
                                    Text(
                                      '여기를 눌러주세요',
                                      style: TextStyle(
                                        color: Color(0xFFF07A34),
                                        fontSize: 34,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -1.5,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Color(0xFFF07A34),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
