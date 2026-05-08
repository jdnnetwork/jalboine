import 'package:flutter/material.dart';
import '../../../core/design_tokens.dart';
import '../../../core/theme.dart';
import '../../../widgets/big_button.dart';

/// 온보딩 설정 안내 화면 공통 레이아웃.
/// 베이지톤 배경 + 큰 본문 + 하단 큰 버튼(초록색 기본).
class SetupScaffold extends StatelessWidget {
  final String body;
  final String buttonLabel;
  final VoidCallback onTap;
  final Color buttonColor;
  final Color buttonShadow;
  final bool busy;

  const SetupScaffold({
    super.key,
    required this.body,
    required this.buttonLabel,
    required this.onTap,
    this.buttonColor = JD.cGreen,
    this.buttonShadow = const Color(0xFF166644),
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SeniorBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: JD.ink,
                    height: 1.45,
                    letterSpacing: -1,
                  ),
                ),
                const Spacer(flex: 3),
                BigButton(
                  label: buttonLabel,
                  background: buttonColor,
                  shadowBottomColor: buttonShadow,
                  foreground: Colors.white,
                  height: 88,
                  fontSize: 30,
                  onTap: busy ? null : onTap,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
