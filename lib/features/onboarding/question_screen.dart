import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../services/voice_recognition_service.dart';

class QuestionScreen extends StatefulWidget {
  final String question;
  final String audioAsset;
  final int step;
  final int total;
  final void Function(bool yes) onAnswer;

  const QuestionScreen({
    super.key,
    required this.question,
    required this.audioAsset,
    required this.step,
    required this.total,
    required this.onAnswer,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant QuestionScreen old) {
    super.didUpdateWidget(old);
    if (old.audioAsset != widget.audioAsset) {
      _start();
    }
  }

  @override
  void dispose() {
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
          child: Column(
            children: [
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  widget.question,
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              if (_listening)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.mic, color: JTheme.seniorAccent),
                    SizedBox(width: 8),
                    Text(
                      '말씀하세요…',
                      style: TextStyle(
                          fontSize: 18,
                          color: JTheme.seniorAccent,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _BigAnswerButton(
                      label: '네',
                      bg: const Color(0xFF2E7D5A),
                      fg: Colors.white,
                      onTap: () => _tap(true),
                    ),
                    const SizedBox(height: 16),
                    _BigAnswerButton(
                      label: '아니요',
                      bg: const Color(0xFFC8102E),
                      fg: Colors.white,
                      onTap: () => _tap(false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.total, (i) {
                  final active = i <= widget.step;
                  return Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? JTheme.seniorAccent
                          : Colors.black.withValues(alpha: 0.18),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigAnswerButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _BigAnswerButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 110,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
