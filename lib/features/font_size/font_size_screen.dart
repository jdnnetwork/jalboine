import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../services/onboarding_settings_service.dart';
import '../../widgets/audio_toggle_button.dart';
import '../../widgets/big_button.dart';

/// 글자 크기 설정.
/// level 1/2: "글자가 잘 보이시나요?" 네/아니요. font_check.wav.
/// level 3: 최대 도달. "지금 이 글자 크기가 최대에요. 대신에 버튼을 누르실
/// 때마다 음성 안내를 해드릴까요?" + voice_ask.wav (audio_guide_mode true 시).
/// 네 → voice_guide_mode true / 아니요 → voice_guide_mode false.
class FontSizeScreen extends ConsumerStatefulWidget {
  final int level;
  const FontSizeScreen({super.key, required this.level});

  @override
  ConsumerState<FontSizeScreen> createState() => _FontSizeScreenState();
}

class _FontSizeScreenState extends ConsumerState<FontSizeScreen> {
  bool _busy = false;

  bool get _isMax => widget.level >= 3;

  double get _fontSize => switch (widget.level) {
        1 => 30,
        2 => 40,
        _ => 48,
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(audioGuideModeProvider)) {
        AudioService.instance.play(
            _isMax ? 'assets/audio/voice_ask.wav' : 'assets/audio/font_check.wav');
      }
    });
  }

  Future<void> _saveLevel() async {
    final sb = ref.read(supabaseProvider);
    final uid = sb.auth.currentUser!.id;
    await sb
        .from('profiles')
        .update({'font_size_level': widget.level}).eq('user_id', uid);
  }

  Future<void> _confirmLevel() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _saveLevel();
      await OnboardingSettingsService.setVoiceGuide(ref, false);
      if (!mounted) return;
      context.go('/age');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _busy = false);
    }
  }

  Future<void> _confirmVoiceGuide(bool yes) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _saveLevel();
      await OnboardingSettingsService.setVoiceGuide(ref, yes);
      if (!mounted) return;
      context.go('/age');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _busy = false);
    }
  }

  void _next() {
    context.go('/font-size?level=${widget.level + 1}');
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _isMax
                        ? '지금 이 글자 크기가 최대에요.\n대신에 버튼을 누르실 때마다\n음성 안내를 해드릴까요?'
                        : '글자가 잘 보이시나요?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w900,
                      color: JD.ink,
                      letterSpacing: -1.0,
                      height: 1.3,
                    ),
                  ),
                ),
                const Spacer(),
                AudioToggleButton(
                  audioAsset: _isMax
                      ? 'assets/audio/voice_ask.wav'
                      : 'assets/audio/font_check.wav',
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: BigButton(
                        label: '네',
                        icon: Icons.check_rounded,
                        background: JD.cMint,
                        foreground: JD.ink,
                        shadowBottomColor: const Color(0xFF3C965A),
                        onTap: _busy
                            ? null
                            : () => _isMax
                                ? _confirmVoiceGuide(true)
                                : _confirmLevel(),
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
                        onTap: _busy
                            ? null
                            : () => _isMax
                                ? _confirmVoiceGuide(false)
                                : _next(),
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
