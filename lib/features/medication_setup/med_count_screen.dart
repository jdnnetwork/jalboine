import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../services/onboarding_settings_service.dart';
import '../../widgets/audio_toggle_button.dart';
import '../../widgets/back_pill.dart';
import '../../widgets/elder_card.dart';

/// 화면 7-2: 약 복용 횟수.
class MedCountScreen extends ConsumerStatefulWidget {
  const MedCountScreen({super.key});

  @override
  ConsumerState<MedCountScreen> createState() => _MedCountScreenState();
}

class _MedCountScreenState extends ConsumerState<MedCountScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(audioGuideModeProvider)) {
        AudioService.instance.play('assets/audio/how_many.wav');
      }
    });
  }

  static const _options = <(int, String, Color)>[
    (1, '1번', JD.cMint),
    (2, '2번', JD.cYellowBg),
    (3, '3번', JD.cLavender),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SeniorBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BackPill(onTap: () => context.go('/med/has')),
                    const Spacer(),
                    const AudioToggleButton(
                        audioAsset: 'assets/audio/how_many.wav'),
                  ],
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '하루에 몇 번\n약을 드시나요?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: JD.ink,
                      letterSpacing: -1.0,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Column(
                    children: [
                      for (final o in _options) ...[
                        Expanded(
                          child: ElderCard(
                            onTap: () => context.go('/med/hour?count=${o.$1}'),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                            child: Row(
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: o.$3,
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${o.$1}',
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w900,
                                      color: JD.ink,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Text(
                                    o.$2,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: JD.ink,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    color: JD.inkMute, size: 22),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
