import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../services/onboarding_settings_service.dart';
import '../../widgets/audio_toggle_button.dart';
import '../../widgets/big_button.dart';

class SetupIntroScreen extends ConsumerStatefulWidget {
  const SetupIntroScreen({super.key});

  @override
  ConsumerState<SetupIntroScreen> createState() => _SetupIntroScreenState();
}

class _SetupIntroScreenState extends ConsumerState<SetupIntroScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(audioGuideModeProvider)) {
        AudioService.instance.play('assets/audio/guide.wav');
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '화면 구성을 도와드릴게요.\n질문에 따라 클릭해주세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: JD.ink,
                      letterSpacing: -1.0,
                      height: 1.3,
                    ),
                  ),
                ),
                const Spacer(),
                const AudioToggleButton(audioAsset: 'assets/audio/guide.wav'),
                const SizedBox(height: 18),
                BigButton(
                  label: '다음',
                  icon: Icons.arrow_forward_rounded,
                  background: JD.cCoralDeep,
                  foreground: Colors.white,
                  shadowBottomColor: const Color(0xFFD9794D),
                  onTap: () => context.go('/onboarding'),
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
