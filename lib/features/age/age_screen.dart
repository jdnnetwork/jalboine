import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/supabase.dart';
import '../../services/audio_service.dart';
import '../../services/onboarding_settings_service.dart';

class AgeScreen extends ConsumerStatefulWidget {
  const AgeScreen({super.key});

  @override
  ConsumerState<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends ConsumerState<AgeScreen> {
  static const _ink = Color(0xFF1A1A2E);
  static const _hint = Color(0xFF888888);
  static const _accentRed = Color(0xFFFF2D6F);
  static const _yellowText = Color(0xFF3E2723);

  bool _busy = false;
  String? _selected;

  static const _groups = <_AgeGroup>[
    _AgeGroup(
      key: '85+',
      label: '85세 이상',
      bg: Color(0xFFFF8C00),
      fg: Colors.white,
    ),
    _AgeGroup(
      key: '80-84',
      label: '80~84세',
      bg: Color(0xFFFF4B7A),
      fg: Colors.white,
    ),
    _AgeGroup(
      key: '75-79',
      label: '75~79세',
      bg: Color(0xFFFF6B8A),
      fg: Colors.white,
    ),
    _AgeGroup(
      key: '70-74',
      label: '70~74세',
      bg: Color(0xFFFFB74D),
      fg: Colors.white,
    ),
    _AgeGroup(
      key: '<70',
      label: '70세 미만',
      bg: Color(0xFFFFD54F),
      fg: _yellowText,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(audioGuideModeProvider)) {
        AudioService.instance.play('assets/audio/age.wav');
      }
    });
  }

  Future<void> _pick(String key) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _selected = key;
    });
    try {
      final sb = ref.read(supabaseProvider);
      final uid = sb.auth.currentUser!.id;
      await sb
          .from('profiles')
          .update({'age_group': key}).eq('user_id', uid);
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      context.go('/setup-intro');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _busy = false);
    }
  }

  Future<void> _onToggleAudio() async {
    final guideOn = ref.read(audioGuideModeProvider);
    if (guideOn) {
      // 끄기: 정지 + audio_guide_mode false 저장
      await AudioService.instance.stop();
      await OnboardingSettingsService.setAudioGuide(ref, false);
    } else {
      // 일회성 재생만 (audio_guide_mode 변경 안 함)
      await AudioService.instance.play('assets/audio/age.wav');
    }
  }

  @override
  Widget build(BuildContext context) {
    final guideOn = ref.watch(audioGuideModeProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                '연세가',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -1.8,
                  height: 1.1,
                ),
              ),
              Text(
                '어떻게 되시나요?',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -1.8,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '아래 해당되는 나이를 ',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: _hint,
                        letterSpacing: -0.4,
                      ),
                    ),
                    TextSpan(
                      text: '꼭',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _accentRed,
                        letterSpacing: -0.4,
                      ),
                    ),
                    TextSpan(
                      text: ' 눌러주세요',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: _hint,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _AudioPill(guideOn: guideOn, onTap: _onToggleAudio),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  physics: const ClampingScrollPhysics(),
                  itemCount: _groups.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final g = _groups[i];
                    return _AgeButton(
                      group: g,
                      selected: _selected == g.key,
                      onTap: _busy ? null : () => _pick(g.key),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgeGroup {
  final String key;
  final String label;
  final Color bg;
  final Color fg;
  const _AgeGroup({
    required this.key,
    required this.label,
    required this.bg,
    required this.fg,
  });
}

class _AudioPill extends StatelessWidget {
  final bool guideOn;
  final VoidCallback onTap;
  const _AudioPill({required this.guideOn, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = guideOn ? '음성 안내 끄기' : '음성 안내 듣기';
    final icon = guideOn ? Icons.volume_off_rounded : Icons.volume_up_rounded;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFF1A1A2E),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF1A1A2E), size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgeButton extends StatelessWidget {
  final _AgeGroup group;
  final bool selected;
  final VoidCallback? onTap;
  const _AgeButton({
    required this.group,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 85,
        decoration: BoxDecoration(
          color: group.bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: group.bg.withValues(alpha: 0.45),
                    offset: const Offset(0, 8),
                    blurRadius: 18,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            _Radio(selected: selected, ringColor: group.fg),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                group.label,
                style: GoogleFonts.notoSansKr(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: group.fg,
                  letterSpacing: -1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool selected;
  final Color ringColor;
  const _Radio({required this.selected, required this.ringColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 3),
      ),
      child: selected
          ? Padding(
              padding: const EdgeInsets.all(5),
              child: DecoratedBox(
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: ringColor),
              ),
            )
          : null,
    );
  }
}
