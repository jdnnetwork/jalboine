import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_tokens.dart';
import '_setup_scaffold.dart';

/// 화면 2: 런처 설정 완료 안내.
class LauncherDoneScreen extends StatelessWidget {
  const LauncherDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SetupScaffold(
      body: '잘 하셨어요! 👍\n\n'
          '이제 홈 버튼을 누르면\n'
          '이 화면이 나와요',
      buttonLabel: '다음',
      buttonColor: JD.cCoralDeep,
      buttonShadow: const Color(0xFFD9794D),
      onTap: () => context.go('/onboarding/battery-guide'),
    );
  }
}
