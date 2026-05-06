import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';

class GuardianLoginScreen extends ConsumerStatefulWidget {
  const GuardianLoginScreen({super.key});

  @override
  ConsumerState<GuardianLoginScreen> createState() =>
      _GuardianLoginScreenState();
}

class _GuardianLoginScreenState extends ConsumerState<GuardianLoginScreen> {
  bool _busy = false;

  Future<void> _signInWith(OAuthProvider p) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(supabaseProvider).auth.signInWithOAuth(
            p,
            redirectTo: 'https://jalboine.app/auth/callback',
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: JTheme.guardian(),
      child: Scaffold(
        backgroundColor: JD.gBg,
        body: GuardianBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SmallBack(onTap: () => context.go('/')),
                  const SizedBox(height: 24),
                  _HeroCard(),
                  const SizedBox(height: 24),
                  _LoginButton(
                    label: '카카오로 시작하기',
                    bg: const Color(0xFFFEE500),
                    fg: JD.ink,
                    iconColor: JD.ink,
                    icon: Icons.chat_bubble_rounded,
                    onTap: _busy ? null : () => _signInWith(OAuthProvider.kakao),
                    accentShadow: const Color(0xFFFFE500),
                  ),
                  const SizedBox(height: 12),
                  _LoginButton(
                    label: '구글로 시작하기',
                    bg: Colors.white,
                    fg: JD.gInk,
                    iconColor: JD.gInk,
                    icon: Icons.g_mobiledata_rounded,
                    border: const Color(0xFFEEF1F6),
                    onTap: _busy ? null : () => _signInWith(OAuthProvider.google),
                  ),
                  const Spacer(),
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '로그인 시 '),
                        TextSpan(
                          text: '이용약관',
                          style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: JD.gInkSoft),
                        ),
                        TextSpan(text: '과 '),
                        TextSpan(
                          text: '개인정보 처리방침',
                          style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: JD.gInkSoft),
                        ),
                        TextSpan(text: '에\n동의한 것으로 간주됩니다.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: JD.gInkMute,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallBack extends StatelessWidget {
  final VoidCallback onTap;
  const _SmallBack({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: JD.shadowBlueCard,
            ),
            child: const Icon(Icons.arrow_back_rounded,
                size: 22, color: JD.gInk),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
      decoration: BoxDecoration(
        color: JD.gBlue,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: JD.gBlue.withValues(alpha: 0.30),
              offset: const Offset(0, 18),
              blurRadius: 40),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30), width: 1),
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 18),
              const Text(
                'FAMILY CARE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.7,
                  color: Color(0xCCFFFFFF),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '부모님을 더 가깝게',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.8,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '로그인하고 부모님 폰을\n멀리서 케어해보세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final Color iconColor;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? border;
  final Color? accentShadow;
  const _LoginButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.iconColor,
    required this.icon,
    required this.onTap,
    this.border,
    this.accentShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: border != null ? Border.all(color: border!, width: 1.5) : null,
            boxShadow: accentShadow != null
                ? [
                    BoxShadow(
                        color: accentShadow!.withValues(alpha: 0.25),
                        offset: const Offset(0, 4),
                        blurRadius: 12),
                  ]
                : JD.shadowBlueCard,
          ),
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
