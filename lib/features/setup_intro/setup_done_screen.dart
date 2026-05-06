import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../services/onboarding_settings_service.dart';
import '../../widgets/big_button.dart';

class SetupDoneScreen extends ConsumerStatefulWidget {
  const SetupDoneScreen({super.key});

  @override
  ConsumerState<SetupDoneScreen> createState() => _SetupDoneScreenState();
}

class _SetupDoneScreenState extends ConsumerState<SetupDoneScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(audioGuideModeProvider)) {
        AudioService.instance.play('assets/audio/complete.wav');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SeniorBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: JD.cMint,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                          color: JD.cGreen.withValues(alpha: 0.20),
                          offset: const Offset(0, 8),
                          blurRadius: 24),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 72),
                ),
                const SizedBox(height: 28),
                const Text(
                  '화면 구성을\n모두 마쳤습니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: JD.ink,
                    letterSpacing: -1.0,
                    height: 1.25,
                  ),
                ),
                const Spacer(),
                BigButton(
                  label: '시작하기',
                  icon: Icons.arrow_forward_rounded,
                  background: JD.cCoralDeep,
                  foreground: Colors.white,
                  shadowBottomColor: const Color(0xFFD9794D),
                  onTap: () => context.go('/home'),
                  height: 96,
                  fontSize: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
