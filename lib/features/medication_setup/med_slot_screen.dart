import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/audio_service.dart';
import '../../services/onboarding_settings_service.dart';

const _ink = Color(0xFF1A1A2E);
const _bubblePink = Color(0xFFFF6B8A);
const _morning = Color(0xFFFF6B8A);
const _lunch = Color(0xFFFF9800);
const _evening = Color(0xFF4CAF50);

const _slotMorning = 'morning';
const _slotLunch = 'lunch';
const _slotEvening = 'evening';

/// 화면 7-3: 약 시간대 선택 (아침/점심/저녁).
///
/// count=1: 1개 선택 → 자동 진행
/// count=2: 2개 선택 → 자동 진행 (토글)
/// count=3: 화면 건너뛰기, 3개 자동 선택 후 바로 진행
class MedSlotScreen extends ConsumerStatefulWidget {
  final int count;
  const MedSlotScreen({super.key, required this.count});

  @override
  ConsumerState<MedSlotScreen> createState() => _MedSlotScreenState();
}

class _MedSlotScreenState extends ConsumerState<MedSlotScreen> {
  final Set<String> _selected = {};
  bool _advancing = false;

  String get _audioAsset =>
      widget.count == 1 ? 'assets/audio/when.wav' : 'assets/audio/when2.wav';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.count == 3) {
        _selected
          ..add(_slotMorning)
          ..add(_slotLunch)
          ..add(_slotEvening);
        _goNext();
        return;
      }
      if (ref.read(audioGuideModeProvider)) {
        AudioService.instance.play(_audioAsset);
      }
    });
  }

  void _toggle(String slot) {
    if (_advancing) return;
    setState(() {
      if (_selected.contains(slot)) {
        _selected.remove(slot);
      } else {
        _selected.add(slot);
      }
    });
    if (_selected.length == widget.count) {
      _advancing = true;
      Timer(const Duration(milliseconds: 500), _goNext);
    }
  }

  void _goNext() {
    if (!mounted) return;
    final orderedSlots = [
      if (_selected.contains(_slotMorning)) _slotMorning,
      if (_selected.contains(_slotLunch)) _slotLunch,
      if (_selected.contains(_slotEvening)) _slotEvening,
    ];
    context.go(
      '/med/hour?count=${widget.count}&slots=${orderedSlots.join(",")}',
    );
  }

  Future<void> _onToggleAudio() async {
    final on = ref.read(audioGuideModeProvider);
    if (on) {
      await AudioService.instance.stop();
      await OnboardingSettingsService.setAudioGuide(ref, false);
    } else {
      await AudioService.instance.play(_audioAsset);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count == 3) {
      return const Scaffold(backgroundColor: Colors.white);
    }
    final guideOn = ref.watch(audioGuideModeProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              _MascotWithBubble(count: widget.count),
              const Spacer(flex: 2),
              _SlotButton(
                label: '아침',
                color: _morning,
                selected: _selected.contains(_slotMorning),
                onTap: () => _toggle(_slotMorning),
              ),
              const SizedBox(height: 12),
              _SlotButton(
                label: '점심',
                color: _lunch,
                selected: _selected.contains(_slotLunch),
                onTap: () => _toggle(_slotLunch),
              ),
              const SizedBox(height: 12),
              _SlotButton(
                label: '저녁',
                color: _evening,
                selected: _selected.contains(_slotEvening),
                onTap: () => _toggle(_slotEvening),
              ),
              const Spacer(flex: 1),
              _AudioBar(on: guideOn, onTap: _onToggleAudio),
            ],
          ),
        ),
      ),
    );
  }
}

class _MascotWithBubble extends StatelessWidget {
  final int count;
  const _MascotWithBubble({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 100),
          child: _BubbleWithTail(
            child: count == 1
                ? Text(
                    '언제 드시나요?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      height: 1.2,
                      letterSpacing: -1.4,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '언제 드시나요?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          height: 1.2,
                          letterSpacing: -1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '2개를 눌러주세요',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                          height: 1.2,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        Image.asset(
          'assets/images/mascot.png',
          width: 140,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

class _BubbleWithTail extends StatelessWidget {
  final Widget child;
  const _BubbleWithTail({required this.child});

  static const double _tailH = 18;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _BubblePainter(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, _tailH + 24, 20, 24),
        child: child,
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const r = 20.0;
    const tailW = 36.0;
    const tailH = _BubbleWithTail._tailH;
    final cx = size.width / 2;
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(r, tailH)
      ..lineTo(cx - tailW / 2, tailH)
      ..lineTo(cx, 0)
      ..lineTo(cx + tailW / 2, tailH)
      ..lineTo(w - r, tailH)
      ..arcToPoint(Offset(w, tailH + r), radius: const Radius.circular(r))
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: const Radius.circular(r))
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: const Radius.circular(r))
      ..lineTo(0, tailH + r)
      ..arcToPoint(Offset(r, tailH), radius: const Radius.circular(r))
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = _bubblePink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) => false;
}

class _SlotButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _SlotButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 90,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              border: selected
                  ? Border.all(color: Colors.black, width: 4)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  offset: const Offset(0, 6),
                  blurRadius: 14,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1.2,
                height: 1.0,
              ),
            ),
          ),
          if (selected)
            const Positioned(
              top: 10,
              left: 14,
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
        ],
      ),
    );
  }
}

class _AudioBar extends StatelessWidget {
  final bool on;
  final VoidCallback onTap;
  const _AudioBar({required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = on ? '음성 안내 끄기' : '음성 안내 듣기';
    final icon = on ? Icons.volume_off_rounded : Icons.volume_up_rounded;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _ink, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _ink, size: 32),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
