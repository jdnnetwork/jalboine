import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/onboarding_setup_service.dart';
import '_setup_scaffold.dart';

/// 화면 4: Android 13+ 알림 권한 안내. 12 이하면 즉시 audio-guide-ask로.
class NotificationGuideScreen extends StatefulWidget {
  const NotificationGuideScreen({super.key});

  @override
  State<NotificationGuideScreen> createState() =>
      _NotificationGuideScreenState();
}

class _NotificationGuideScreenState extends State<NotificationGuideScreen> {
  bool _checking = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final sdk = await OnboardingSetupService.instance.getSdkInt();
    // Android 13+ 만 런타임 권한이 필요. 그 이하면 화면 건너뛰기.
    if (sdk > 0 && sdk < 33) {
      if (!mounted) return;
      context.go('/audio-guide-ask');
      return;
    }
    final granted = await Permission.notification.isGranted;
    if (granted) {
      if (!mounted) return;
      context.go('/audio-guide-ask');
      return;
    }
    if (!mounted) return;
    setState(() => _checking = false);
  }

  Future<void> _onConfirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    await Permission.notification.request();
    if (!mounted) return;
    context.go('/audio-guide-ask');
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return SetupScaffold(
      body: '마지막이에요!\n\n'
          '다음 질문에서\n'
          "'허용'을 눌러주세요.\n\n"
          '이걸 해야\n'
          '약 먹을 시간을\n'
          '알려드릴 수 있어요',
      buttonLabel: '알겠어요',
      busy: _busy,
      onTap: _onConfirm,
    );
  }
}
