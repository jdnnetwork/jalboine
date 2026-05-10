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
    with SingleTickerProviderStateMixin {
  bool _busy = false;
  late final AnimationController _bobCtrl;
  late final Animation<double> _bobAnim;

  static const _ink = Color(0xFF2D3460);
  static const _inkSoft = Color(0xFF4A5088);
  static const _accent = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    _bobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _bobAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _bobCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD0D8F0), Color(0xFFB8C4E8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              AnimatedBuilder(
                animation: _bobAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _bobAnim.value),
                  child: child,
                ),
                child: Image.asset(
                  'assets/images/mascot.png',
                  width: 180,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                '잘보이네',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -1.8,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '어르신을 위한 쉬운 스마트폰',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: _inkSoft,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _StartButton(
                  busy: _busy,
                  onTap: _start,
                  accent: _accent,
                ),
              ),
              const SizedBox(height: 24),
              _GuardianHint(
                onTap: () => context.go('/guardian/login'),
                ink: _ink,
                inkSoft: _inkSoft,
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onTap;
  final Color accent;
  const _StartButton({
    required this.busy,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 120,
      child: ElevatedButton(
        onPressed: busy ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.zero,
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '시작하기',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1.2,
                height: 1.1,
              ),
            ),
            SizedBox(height: 6),
            Text(
              '이 버튼을 누르세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xB3FFFFFF),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuardianHint extends StatelessWidget {
  final VoidCallback onTap;
  final Color ink;
  final Color inkSoft;
  const _GuardianHint({
    required this.onTap,
    required this.ink,
    required this.inkSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '가족 및 어르신을 도와주시는 분은',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: inkSoft,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              '여기를 눌러주세요',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ink,
                decoration: TextDecoration.underline,
                decorationColor: ink,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
