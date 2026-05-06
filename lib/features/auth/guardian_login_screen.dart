import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';

/// 보호자 전용 로그인 — Google / Kakao OAuth.
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
    return Scaffold(
      body: GuardianBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.go('/'),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '보호자 로그인',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: JTheme.guardianText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '가족 어르신의 폰을 안전하게 함께 관리하세요',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const Spacer(),
                _LoginCard(
                  bg: const Color(0xFF1A1A1A),
                  fg: Colors.white,
                  icon: Icons.g_mobiledata_rounded,
                  label: 'Google로 계속하기',
                  onTap: _busy ? null : () => _signInWith(OAuthProvider.google),
                ),
                const SizedBox(height: 12),
                _LoginCard(
                  bg: const Color(0xFFFEE500),
                  fg: const Color(0xFF181600),
                  icon: Icons.chat_rounded,
                  label: '카카오로 계속하기',
                  onTap: _busy ? null : () => _signInWith(OAuthProvider.kakao),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final Color bg;
  final Color fg;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _LoginCard({
    required this.bg,
    required this.fg,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: fg, size: 28),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
