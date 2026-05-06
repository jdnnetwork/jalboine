import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_tokens.dart';
import '../services/onboarding_settings_service.dart';

/// 온보딩 화면 공통 - "음성 켜기/끄기" 토글.
class AudioToggleButton extends ConsumerWidget {
  const AudioToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(audioGuideModeProvider);
    return Center(
      child: Material(
        color: on ? JD.cMint : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            SystemSound.play(SystemSoundType.click);
            OnboardingSettingsService.setAudioGuide(ref, !on);
          },
          child: Ink(
            decoration: BoxDecoration(
              color: on ? JD.cMint : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: on ? const Color(0xFF3C965A) : const Color(0xFFE8DDC9),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x14785A32),
                  offset: const Offset(0, 3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    on ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    size: 22,
                    color: on ? Colors.white : JD.inkSoft,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    on ? '음성 끄기' : '음성 켜기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: on ? Colors.white : JD.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
