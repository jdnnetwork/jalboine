import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/realtime_service.dart';

const _ink = Color(0xFF1A1A2E);
const _btnGrayBg = Color(0xFFF5F5F5);
const _btnGrayBorder = Color(0xFFCCCCCC);
const _btnGrayInk = Color(0xFF3E2723);
const _medBg = Color(0xFFFFF0F0);
const _medBorder = Color(0xFFFF6B8A);
const _medInk = Color(0xFFD32F2F);
const _homeBg = Color(0xFFFFF8E1);
const _homeBorder = Color(0xFFFF9800);
const _homeInk = Color(0xFFE65100);
const _backBg = Color(0xFFE8F5E9);
const _backBorder = Color(0xFF4CAF50);
const _backInk = Color(0xFF2E7D32);

/// "다른 화면" — 홈 화면의 추가 메뉴 페이지.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(seniorSettingsProvider);
    final hasMed = s.value?.takesMedication ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                '다른 화면',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: -1.0,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MenuCard(
                        emoji: '📱',
                        label: '다른 앱 열기',
                        bg: _btnGrayBg,
                        border: _btnGrayBorder,
                        ink: _btnGrayInk,
                        onTap: () => _onOtherApps(context),
                      ),
                      const SizedBox(height: 10),
                      if (hasMed) ...[
                        _MenuCard(
                          emoji: '💊',
                          label: '약 복용 시간 바꾸기',
                          bg: _medBg,
                          border: _medBorder,
                          ink: _medInk,
                          onTap: () => context.push('/med/has'),
                        ),
                        const SizedBox(height: 10),
                      ],
                      _MenuCard(
                        emoji: '🏠',
                        label: '원래 홈 화면',
                        bg: _homeBg,
                        border: _homeBorder,
                        ink: _homeInk,
                        onTap: () => _onSwitchLauncher(context),
                      ),
                      const SizedBox(height: 10),
                      _MenuCard(
                        emoji: '🔙',
                        label: '첫 화면으로 돌아가기',
                        bg: _backBg,
                        border: _backBorder,
                        ink: _backInk,
                        onTap: () => context.go('/home'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _BackButton(onTap: () => context.go('/home')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onOtherApps(BuildContext context) async {
    // TODO(other-apps): 설치된 앱 목록 화면 — PackageManager native bridge 필요.
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        title: Text(
          '준비 중',
          style: GoogleFonts.notoSansKr(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: _ink,
          ),
        ),
        content: Text(
          '곧 다른 앱도 열어드릴게요',
          style: GoogleFonts.notoSansKr(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _ink,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '알겠어요',
              style: GoogleFonts.notoSansKr(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _medInk,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSwitchLauncher(BuildContext context) async {
    final ok1 = await _confirm(
      context,
      '기본 홈 화면으로\n돌아가시겠어요?',
    );
    if (!ok1 || !context.mounted) return;
    final ok2 = await _confirm(
      context,
      '정말로 돌아가시겠어요?\n잘보이네 앱은 그대로 있어요',
    );
    if (!ok2 || !context.mounted) return;
    // Android: 시스템이 기본 런처를 jalboine 으로 설정한 상태라면
    // SystemNavigator.pop() 만으로는 원래 런처로 못 돌아갈 수 있다.
    // 그래도 사용자가 '뒤로'/'홈'을 누르면 시스템 선택기가 뜨는 경우가 있어
    // 가장 단순한 방식으로 종료를 시도한다.
    SystemNavigator.pop();
  }

  Future<bool> _confirm(BuildContext context, String text) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Colors.white,
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _ink,
              height: 1.35,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '아니요',
              style: GoogleFonts.notoSansKr(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _btnGrayInk,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '네',
              style: GoogleFonts.notoSansKr(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _medInk,
              ),
            ),
          ),
        ],
      ),
    );
    return r == true;
  }
}

class _MenuCard extends StatelessWidget {
  final String emoji;
  final String label;
  final Color bg;
  final Color border;
  final Color ink;
  final VoidCallback onTap;
  const _MenuCard({
    required this.emoji,
    required this.label,
    required this.bg,
    required this.border,
    required this.ink,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 30, height: 1.0),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.notoSansKr(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: ink,
                  letterSpacing: -0.8,
                  height: 1.0,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: ink, size: 28),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_back_rounded, color: _btnGrayInk, size: 28),
            const SizedBox(width: 10),
            Text(
              '돌아가기',
              style: GoogleFonts.notoSansKr(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _btnGrayInk,
                letterSpacing: -0.8,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
