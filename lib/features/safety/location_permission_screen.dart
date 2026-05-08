import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/theme.dart';
import '../../services/location_service.dart';
import '../../widgets/big_button.dart';

/// 보호자가 위치 추적 토글 ON 시 자동 푸시. FINE → BACKGROUND 순으로 권한 요청.
class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _busy = false;

  Future<void> _request() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final fine = await LocationService.instance.requestFine();
      if (!mounted) return;
      if (!fine) {
        await _denied();
        return;
      }
      final bg = await LocationService.instance.requestBackground();
      if (!mounted) return;
      if (!bg) {
        await _denied();
        return;
      }
      await LocationService.instance.pushOnce();
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

  Future<void> _denied() async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
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
                  '가족이 걱정하지 않도록\n위치를 알려드려요.\n\n'
                  "다음 질문에서\n'항상 허용'을\n눌러주세요",
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
