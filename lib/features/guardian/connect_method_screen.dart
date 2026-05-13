import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';

/// 보호자 로그인 직후 진입. 이미 피보호자와 연결돼 있으면 대시보드로 직행.
class ConnectMethodScreen extends ConsumerStatefulWidget {
  const ConnectMethodScreen({super.key});

  @override
  ConsumerState<ConnectMethodScreen> createState() =>
      _ConnectMethodScreenState();
}

class _ConnectMethodScreenState extends ConsumerState<ConnectMethodScreen> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPaired());
  }

  Future<void> _checkPaired() async {
    // ===== DEV ONLY: 쿼리 ?dev=1 이면 인증 검사 건너뛰기 =====
    final isDev =
        GoRouterState.of(context).uri.queryParameters['dev'] == '1';
    if (isDev) {
      setState(() => _checking = false);
      return;
    }
    // ===== /DEV =====
    try {
      final sb = ref.read(supabaseProvider);
      final uid = sb.auth.currentUser?.id;
      if (uid == null) {
        if (!mounted) return;
        context.go('/guardian/login');
        return;
      }
      final r = await sb
          .from('pair_links')
          .select('id')
          .eq('guardian_user_id', uid)
          .eq('status', 'confirmed')
          .limit(1)
          .maybeSingle();
      if (!mounted) return;
      if (r != null) {
        context.go('/guardian/dashboard');
        return;
      }
      setState(() => _checking = false);
    } catch (_) {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('준비 중입니다')));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: JTheme.guardian(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _checking
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 28),
                      const Text(
                        '잘보이네',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: JD.gInkMute,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        '부모님 폰과 연결하기',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: JD.gInk,
                          letterSpacing: -0.8,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '두 가지 방법 중 하나를 선택하세요',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: JD.gInkSoft,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _MethodCard(
                        primary: true,
                        icon: Icons.phonelink_setup_rounded,
                        title: '부모님께 설치 권유 드리기',
                        sub: '문자로 설치 안내 보내드릴게요',
                        onTap: _showComingSoon,
                      ),
                      const SizedBox(height: 14),
                      _MethodCard(
                        primary: false,
                        icon: Icons.dialpad_rounded,
                        title: '부모님께 연결 번호 받기',
                        sub: '부모님이 알려주신 4자리 번호 입력',
                        onTap: () =>
                            context.go('/guardian/connect-nickname'),
                      ),
                      const Spacer(),
                      // ===== DEV ONLY: 릴리즈 시 이 블록만 삭제 =====
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              context.go('/guardian/dashboard?dev=1'),
                          style: TextButton.styleFrom(
                            foregroundColor: JD.gInkMute,
                          ),
                          child: const Text(
                            'DEV: 바로 대시보드',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      // ===== /DEV =====
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final bool primary;
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  const _MethodCard({
    required this.primary,
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? JD.gBlue : Colors.white;
    final border = primary ? JD.gBlue : JD.gBlue;
    final fg = primary ? Colors.white : JD.gBlue;
    final sub2 = primary ? Colors.white.withValues(alpha: 0.85) : JD.gInkSoft;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primary
                      ? Colors.white.withValues(alpha: 0.18)
                      : JD.gBlueSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: fg, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: fg,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sub2,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: fg, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
