import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../services/voice_recognition_service.dart';
import '../../widgets/back_pill.dart';
import '../../widgets/big_button.dart';
import '../../widgets/progress_dots.dart';

class QuestionScreen extends StatefulWidget {
  final String question;
  final String subtitle;
  final String audioAsset;
  final int step;
  final int total;
  final void Function(bool yes) onAnswer;

  const QuestionScreen({
    super.key,
    required this.question,
    this.subtitle = '',
    required this.audioAsset,
    required this.step,
    required this.total,
    required this.onAnswer,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen>
    with SingleTickerProviderStateMixin {
  bool _listening = false;
  late final AnimationController _popCtrl;

  @override
  void initState() {
    super.initState();
    _popCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
    _start();
  }

  @override
  void didUpdateWidget(covariant QuestionScreen old) {
    super.didUpdateWidget(old);
    if (old.audioAsset != widget.audioAsset) {
      _popCtrl.forward(from: 0);
      _start();
    }
  }

  @override
  void dispose() {
    _popCtrl.dispose();
    VoiceRecognitionService.instance.stop();
    super.dispose();
  }

  Future<void> _start() async {
    await AudioService.instance.play(widget.audioAsset);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    final ok = await VoiceRecognitionService.instance.listenOnce((yes) {
      if (!mounted || yes == null) return;
      _setListening(false);
      widget.onAnswer(yes);
    });
    _setListening(ok);
  }

  void _setListening(bool v) {
    if (!mounted) return;
    setState(() => _listening = v);
  }

  Future<void> _tap(bool yes) async {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
    await VoiceRecognitionService.instance.stop();
    widget.onAnswer(yes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SeniorBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    BackPill(onTap: () => context.go('/')),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${widget.step + 1} / ${widget.total}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: JD.inkSoft,
                        ),
                      ),
                    ),
                    const SizedBox(width: 56),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.94, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _popCtrl,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: FadeTransition(
                        opacity: _popCtrl,
                        child: _QuestionCard(
                          number: widget.step + 1,
                          question: widget.question,
                          subtitle: widget.subtitle,
                          listening: _listening,
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: BigButton(
                        label: '네',
                        icon: Icons.check_rounded,
                        background: JD.cMint,
                        foreground: JD.ink,
                        shadowBottomColor: const Color(0xFF3C965A),
                        onTap: () => _tap(true),
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
                        onTap: () => _tap(false),
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
                const SizedBox(height: 24),
                ProgressDots(total: widget.total, current: widget.step),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int number;
  final String question;
  final String subtitle;
  final bool listening;
  const _QuestionCard({
    required this.number,
    required this.question,
    required this.subtitle,
    required this.listening,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 36),
      decoration: BoxDecoration(
        color: JD.cLavender,
        borderRadius: BorderRadius.circular(JD.rCardLg),
        boxShadow: [
          BoxShadow(
            color: JD.cPurple.withValues(alpha: 0.18),
            offset: const Offset(0, 12),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: JD.cPurple.withValues(alpha: 0.20),
                  offset: const Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: JD.cPurple,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: JD.ink,
              height: 1.25,
              letterSpacing: -0.8,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: JD.inkSoft,
              ),
            ),
          ],
          if (listening) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.mic_rounded, size: 20, color: JD.cPurple),
                SizedBox(width: 6),
                Text(
                  '말씀하세요…',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: JD.cPurple,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
