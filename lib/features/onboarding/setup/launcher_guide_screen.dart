import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/onboarding_setup_service.dart';
import '_setup_scaffold.dart';

/// 화면 1: 기본 런처 설정 안내. 이미 기본 런처면 즉시 화면 3으로 건너뜀.
class LauncherGuideScreen extends StatefulWidget {
  const LauncherGuideScreen({super.key});

  @override
  State<LauncherGuideScreen> createState() => _LauncherGuideScreenState();
}

class _LauncherGuideScreenState extends State<LauncherGuideScreen>
    with WidgetsBindingObserver {
  bool _checking = true;
  bool _awaiting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _check() async {
    final isDefault =
        await OnboardingSetupService.instance.isDefaultLauncher();
    if (!mounted) return;
    if (isDefault) {
      // 이미 기본 런처: 화면 1·2 모두 건너뛰고 배터리 안내로
      context.go('/onboarding/battery-guide');
      return;
    }
    setState(() => _checking = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_awaiting) return;
    _awaiting = false;
    if (!mounted) return;
    // 시스템 다이얼로그가 끝났으니 다음 화면으로
    context.go('/onboarding/launcher-done');
  }

  Future<void> _onConfirm() async {
    _awaiting = true;
    await OnboardingSetupService.instance.requestDefaultLauncher();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return SetupScaffold(
      body: '지금부터 화면에\n질문이 하나 나와요.\n\n'
          "거기서 '잘보이네'를\n선택하고\n\n"
          "'항상'을 눌러주세요",
      buttonLabel: '알겠어요',
      onTap: _onConfirm,
    );
  }
}
