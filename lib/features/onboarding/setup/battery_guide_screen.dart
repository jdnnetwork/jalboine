import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/onboarding_setup_service.dart';
import '_setup_scaffold.dart';

/// 화면 3: 배터리 최적화 제외 안내. 이미 제외돼 있으면 즉시 다음 화면으로.
class BatteryGuideScreen extends StatefulWidget {
  const BatteryGuideScreen({super.key});

  @override
  State<BatteryGuideScreen> createState() => _BatteryGuideScreenState();
}

class _BatteryGuideScreenState extends State<BatteryGuideScreen>
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
    final ok = await OnboardingSetupService.instance
        .isIgnoringBatteryOptimizations();
    if (!mounted) return;
    if (ok) {
      context.go('/onboarding/notification-guide');
      return;
    }
    setState(() => _checking = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_awaiting) return;
    _awaiting = false;
    if (!mounted) return;
    context.go('/onboarding/notification-guide');
  }

  Future<void> _onConfirm() async {
    _awaiting = true;
    await OnboardingSetupService.instance.requestIgnoreBatteryOptimizations();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return SetupScaffold(
      body: '하나만 더 할게요.\n\n'
          '다음 화면에서\n'
          "'제한 없음'을\n"
          '눌러주세요.\n\n'
          '이걸 해야\n'
          '알림이 잘 와요',
      buttonLabel: '알겠어요',
      onTap: _onConfirm,
    );
  }
}
