import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/design_tokens.dart';
import '../../core/theme.dart';
import '../../services/unknown_call_detector.dart';
import '../../widgets/big_button.dart';

/// 피보호자에게 READ_CALL_LOG + READ_CONTACTS 권한을 받기 위한 안내 화면.
/// 보호자가 안심 탭에서 모르는 번호 감지 토글 ON 했을 때 자동으로 푸시됨.
class CallPermissionScreen extends StatefulWidget {
  const CallPermissionScreen({super.key});

  @override
  State<CallPermissionScreen> createState() => _CallPermissionScreenState();
}

class _CallPermissionScreenState extends State<CallPermissionScreen> {
  bool _busy = false;

  Future<void> _request() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final r1 = await Permission.phone.request(); // READ_CALL_LOG
      if (!mounted) return;
      if (!r1.isGranted) {
        await _showDeniedAndExit();
        return;
      }
      final r2 = await Permission.contacts.request();
      if (!mounted) return;
      if (!r2.isGranted) {
        await _showDeniedAndExit();
        return;
      }
      await UnknownCallDetector.instance.resetLastCheck();
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showDeniedAndExit() async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '권한이 필요해요.\n나중에 다시 알려드릴게요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: JD.ink,
              height: 1.4,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '확인',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: JD.cCoralDeep,
              ),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    context.go('/home');
  }

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
                const Text(
                  '가족이 걱정하지 않도록\n모르는 전화를\n알려드려요.\n\n'
                  "다음 질문에서\n'허용'을 눌러주세요",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: JD.ink,
                    height: 1.45,
                    letterSpacing: -1,
                  ),
                ),
                const Spacer(flex: 3),
                BigButton(
                  label: '알겠어요',
                  background: JD.cGreen,
                  shadowBottomColor: const Color(0xFF166644),
                  foreground: Colors.white,
                  height: 88,
                  fontSize: 30,
                  onTap: _busy ? null : _request,
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
