import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design_tokens.dart';
import '../../core/theme.dart';

const _ink = Color(0xFF1A1A2E);
const _accentPink = Color(0xFFFF6B8A);
const _emphasisRed = Color(0xFFD32F2F);

/// 보호자가 어르신 화면에 표시될 별명을 입력하는 화면.
/// 연결 코드 입력 화면(/guardian/connect-code) 으로 nickname 쿼리 파라미터와 함께 이동.
class GuardianNicknameScreen extends ConsumerStatefulWidget {
  const GuardianNicknameScreen({super.key});

  @override
  ConsumerState<GuardianNicknameScreen> createState() =>
      _GuardianNicknameScreenState();
}

class _GuardianNicknameScreenState
    extends ConsumerState<GuardianNicknameScreen> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onNext() {
    final nickname = _ctrl.text.trim();
    if (nickname.isEmpty) return;
    context.go('/guardian/connect-code?nickname=${Uri.encodeComponent(nickname)}');
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = _ctrl.text.trim().isNotEmpty;
    return Theme(
      data: JTheme.guardian(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BackBtn(onTap: () => context.go('/guardian/connect-method')),
                const SizedBox(height: 32),
                Text(
                  '어르신에게 보여질 이름을\n입력해주세요',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    letterSpacing: -0.6,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accentPink, width: 2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  child: TextField(
                    controller: _ctrl,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    maxLength: 12,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                      letterSpacing: -0.4,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '예: 민수, 딸, 아들, 손녀',
                      hintStyle: GoogleFonts.notoSansKr(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: JD.gInkMute,
                      ),
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: canProceed ? _onNext : null,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: canProceed ? 1.0 : 0.45,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_emphasisRed, Color(0xFFFF6F00)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: canProceed
                            ? [
                                BoxShadow(
                                  color: _emphasisRed.withValues(alpha: 0.35),
                                  offset: const Offset(0, 6),
                                  blurRadius: 14,
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '다음',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: JD.gBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.arrow_back_rounded, size: 20, color: JD.gInk),
          ),
        ),
      ),
    );
  }
}
