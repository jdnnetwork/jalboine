import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/theme.dart';
import '../../services/onboarding_settings_service.dart';
import '../../widgets/big_button.dart';

/// 시작하기 직후 - 음성 안내 모드(audio_guide_mode) 선택. 이 화면은 음성 재생 안 함.
class AudioGuideAskScreen extends ConsumerStatefulWidget {
  const AudioGuideAskScreen({super.key});

  @override
  ConsumerState<AudioGuideAskScreen> createState() =>
      _AudioGuideAskScreenState();
}

class _AudioGuideAskScreenState extends ConsumerState<AudioGuideAskScreen> {
  bool _busy = false;

  Future<void> _answer(bool yes) async {
    if (_busy) return;
    setState(() => _busy = true);
    await OnboardingSettingsService.setAudioGuide(ref, yes);
    if (!mounted) return;
    context.go('/font-size');
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
                    '음성을 함께 읽어드릴까요?\n음성 안내를 원하시면 네를 눌러주세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: JD.ink,
                      letterSpacing: -1.0,
                      height: 1.3,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: BigButton(
                        label: '네',
                        icon: Icons.check_rounded,
                        background: JD.cMint,
                        foreground: JD.ink,
                        shadowBottomColor: const Color(0xFF3C965A),
                        onTap: _busy ? null : () => _answer(true),
                        height: 96,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: BigButton(
                        label: '아니요',
                        icon: Icons.close_rounded,
                        background: Colors.white,
                        foreground: JD.ink,
                        shadowBottomColor: const Color(0xFFC8B89A),
                        onTap: _busy ? null : () => _answer(false),
                        height: 96,
                        fontSize: 28,
                        border: Border.all(
                          color: const Color(0xFFE8DDC9),
                          width: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
