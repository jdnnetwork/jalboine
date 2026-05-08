import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../models/call_alert.dart';
import '../../services/call_alerts_service.dart';
import '../../widgets/big_button.dart';

/// 모르는 번호와의 통화가 감지됐을 때 띄우는 전체화면 팝업.
/// 30초 무응답 → no_response 저장 후 자동 닫힘.
class UnknownCallAlertScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final int? durationSec;
  const UnknownCallAlertScreen({
    super.key,
    required this.phoneNumber,
    this.durationSec,
  });

  @override
  ConsumerState<UnknownCallAlertScreen> createState() =>
      _UnknownCallAlertScreenState();
}

class _UnknownCallAlertScreenState
    extends ConsumerState<UnknownCallAlertScreen> {
  Timer? _timer;
  bool _answered = false;
  int _secondsLeft = 30;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft -= 1);
      if (_secondsLeft <= 0) {
        t.cancel();
        if (!_answered) _respond(CallAlertLevel.noResponse);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _respond(CallAlertLevel level) async {
    if (_answered) return;
    _answered = true;
    _timer?.cancel();
    final me = ref.read(currentUserProvider)?.id;
    if (me != null) {
      try {
        await CallAlertsService.instance.insert(
          seniorId: me,
          phoneNumber: widget.phoneNumber,
          level: level,
          durationSec: widget.durationSec,
        );
      } catch (_) {
        // 비치명적
      }
    }
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
                const Spacer(),
                Text(
                  '$_secondsLeft초',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: JD.inkMute,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '방금 모르는 번호에서\n전화가 왔어요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: JD.ink,
                    height: 1.4,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: JD.shadowCard,
                  ),
                  child: const Text(
                    '혹시 돈 얘기를\n했나요?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: JD.cRed,
                      height: 1.35,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const Spacer(),
                BigButton(
                  label: '네',
                  background: JD.cRed,
                  shadowBottomColor: JD.stackBtnRed,
                  height: 96,
                  fontSize: 34,
                  onTap: () => _respond(CallAlertLevel.urgent),
                ),
                const SizedBox(height: 14),
                BigButton(
                  label: '아니요',
                  background: JD.cGreen,
                  shadowBottomColor: const Color(0xFF166644),
                  height: 96,
                  fontSize: 34,
                  onTap: () => _respond(CallAlertLevel.normal),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
