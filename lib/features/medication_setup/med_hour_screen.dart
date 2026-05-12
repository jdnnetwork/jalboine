import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/audio_service.dart';
import '../../services/onboarding_settings_service.dart';

const _ink = Color(0xFF1A1A2E);
const _accentPink = Color(0xFFFF6B8A);
const _accentOrange = Color(0xFFFF9800);
const _greenLight = Color(0xFF8BC34A);
const _brown = Color(0xFF8D6E63);
const _otherPink = Color(0xFFE91E63);
const _gray = Color(0xFFE0E0E0);
const _grayInk = Color(0xFF888888);

class _PresetOption {
  final String label;
  final int hour24;
  final Color color;
  const _PresetOption({
    required this.label,
    required this.hour24,
    required this.color,
  });
}

class _SlotConfig {
  final String bubbleText;
  final String audioAsset;
  final IconData icon;
  final Color iconColor;
  final List<_PresetOption> presets;
  const _SlotConfig({
    required this.bubbleText,
    required this.audioAsset,
    required this.icon,
    required this.iconColor,
    required this.presets,
  });
}

const _slotConfigs = <String, _SlotConfig>{
  'morning': _SlotConfig(
    bubbleText: '아침에\n몇 시에 드시나요?',
    audioAsset: 'assets/audio/morning.wav',
    icon: Icons.wb_sunny_rounded,
    iconColor: Colors.yellow,
    presets: [
      _PresetOption(label: '아침 7시', hour24: 7, color: _greenLight),
      _PresetOption(label: '아침 8시', hour24: 8, color: _accentOrange),
      _PresetOption(label: '아침 9시', hour24: 9, color: _accentPink),
      _PresetOption(label: '아침 10시', hour24: 10, color: _brown),
    ],
  ),
  'lunch': _SlotConfig(
    bubbleText: '점심에\n몇 시에 드시나요?',
    audioAsset: 'assets/audio/day.wav',
    icon: Icons.wb_sunny_rounded,
    iconColor: Colors.yellow,
    presets: [
      _PresetOption(label: '낮 12시', hour24: 12, color: _greenLight),
      _PresetOption(label: '오후 1시', hour24: 13, color: _accentOrange),
      _PresetOption(label: '오후 2시', hour24: 14, color: _accentPink),
      _PresetOption(label: '오후 3시', hour24: 15, color: _brown),
    ],
  ),
  'evening': _SlotConfig(
    bubbleText: '저녁에\n몇 시에 드시나요?',
    audioAsset: 'assets/audio/night.wav',
    icon: Icons.nightlight_round,
    iconColor: Colors.white,
    presets: [
      _PresetOption(label: '저녁 6시', hour24: 18, color: _greenLight),
      _PresetOption(label: '저녁 7시', hour24: 19, color: _accentOrange),
      _PresetOption(label: '저녁 8시', hour24: 20, color: _accentPink),
      _PresetOption(label: '밤 9시', hour24: 21, color: _brown),
    ],
  ),
};

/// 화면 7-4: 약 시간 선택. slots 순서대로 시간을 모은 뒤 /med/confirm 으로 이동.
class MedHourScreen extends ConsumerStatefulWidget {
  final int count;
  final List<String> slots;
  const MedHourScreen({
    super.key,
    required this.count,
    required this.slots,
  });

  @override
  ConsumerState<MedHourScreen> createState() => _MedHourScreenState();
}

class _MedHourScreenState extends ConsumerState<MedHourScreen> {
  int _slotIndex = 0;
  final List<String> _times = [];

  bool _customMode = false;
  int? _customHour;
  bool? _isPm;
  bool _busy = false;

  String get _currentSlotKey {
    if (widget.slots.isEmpty || _slotIndex >= widget.slots.length) {
      return 'morning';
    }
    return widget.slots[_slotIndex];
  }

  _SlotConfig get _config =>
      _slotConfigs[_currentSlotKey] ?? _slotConfigs['morning']!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playSlotAudio());
  }

  void _playSlotAudio() {
    if (ref.read(audioGuideModeProvider)) {
      AudioService.instance.play(_config.audioAsset);
    }
  }

  void _onPresetTap(int hour24) {
    if (_busy) return;
    final hh = hour24.toString().padLeft(2, '0');
    _times.add('$hh:00');
    _busy = true;
    Timer(const Duration(milliseconds: 500), _advanceOrComplete);
  }

  void _onOtherTap() {
    if (_busy) return;
    setState(() {
      _customMode = true;
      _customHour = null;
      _isPm = null;
    });
  }

  void _onCustomConfirm() {
    if (_busy) return;
    final h = _customHour;
    final pm = _isPm;
    if (h == null || pm == null) return;
    var h24 = h;
    if (pm) {
      if (h != 12) h24 = h + 12;
    } else {
      if (h == 12) h24 = 0;
    }
    final hh = h24.toString().padLeft(2, '0');
    _times.add('$hh:00');
    _busy = true;
    Timer(const Duration(milliseconds: 500), _advanceOrComplete);
  }

  void _advanceOrComplete() {
    if (!mounted) return;
    if (_slotIndex + 1 >= widget.slots.length || widget.slots.isEmpty) {
      context.go(
        '/med/confirm?count=${widget.count}&times=${_times.join(",")}',
      );
      return;
    }
    setState(() {
      _slotIndex++;
      _customMode = false;
      _customHour = null;
      _isPm = null;
      _busy = false;
    });
    _playSlotAudio();
  }

  Future<void> _onToggleAudio() async {
    final on = ref.read(audioGuideModeProvider);
    if (on) {
      await AudioService.instance.stop();
      await OnboardingSettingsService.setAudioGuide(ref, false);
    } else {
      await AudioService.instance.play(_config.audioAsset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guideOn = ref.watch(audioGuideModeProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: _customMode
              ? _buildCustomMode(guideOn)
              : _buildPresetMode(guideOn),
        ),
      ),
    );
  }

  Widget _buildPresetMode(bool guideOn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 2),
        _MascotWithBubble(text: _config.bubbleText),
        const Spacer(flex: 2),
        for (final p in _config.presets) ...[
          _HourButton(
            label: p.label,
            color: p.color,
            icon: _config.icon,
            iconColor: _config.iconColor,
            onTap: () => _onPresetTap(p.hour24),
          ),
          const SizedBox(height: 10),
        ],
        _HourButton(
          label: '다른 시간',
          color: _otherPink,
          icon: Icons.access_time_filled_rounded,
          iconColor: Colors.white,
          onTap: _onOtherTap,
        ),
        const Spacer(flex: 1),
        _AudioBar(on: guideOn, onTap: _onToggleAudio),
      ],
    );
  }

  Widget _buildCustomMode(bool guideOn) {
    final canConfirm = _customHour != null && _isPm != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _MascotWithBubble(
                  text: '몇 시에 드시나요?\n숫자를 눌러주세요',
                ),
                const SizedBox(height: 16),
                _CustomInputBox(hour: _customHour),
                const SizedBox(height: 12),
                _AmPmToggle(isPm: _isPm, onTap: (pm) {
                  setState(() => _isPm = pm);
                }),
                const SizedBox(height: 14),
                _NumPad(
                  selected: _customHour,
                  onTap: (n) => setState(() => _customHour = n),
                ),
                if (canConfirm) ...[
                  const SizedBox(height: 14),
                  _ConfirmButton(onTap: _onCustomConfirm),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        _AudioBar(on: guideOn, onTap: _onToggleAudio),
      ],
    );
  }
}

class _MascotWithBubble extends StatelessWidget {
  final String text;
  const _MascotWithBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 100),
          child: _BubbleWithTail(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: _ink,
                height: 1.25,
                letterSpacing: -1.2,
              ),
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
        ..color = _accentPink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) => false;
}

class _HourButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  const _HourButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              offset: const Offset(0, 5),
              blurRadius: 12,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Icon(icon, size: 40, color: iconColor),
            const SizedBox(width: 18),
            Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1.0,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomInputBox extends StatelessWidget {
  final int? hour;
  const _CustomInputBox({required this.hour});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentPink, width: 2),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            hour?.toString() ?? '__',
            style: GoogleFonts.notoSansKr(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: _ink,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '시',
            style: GoogleFonts.notoSansKr(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: _ink,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmPmToggle extends StatelessWidget {
  final bool? isPm;
  final void Function(bool) onTap;
  const _AmPmToggle({required this.isPm, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AmPmButton(
            label: '오전',
            selectedColor: _accentPink,
            selected: isPm == false,
            onTap: () => onTap(false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AmPmButton(
            label: '오후',
            selectedColor: _accentOrange,
            selected: isPm == true,
            onTap: () => onTap(true),
          ),
        ),
      ],
    );
  }
}

class _AmPmButton extends StatelessWidget {
  final String label;
  final Color selectedColor;
  final bool selected;
  final VoidCallback onTap;
  const _AmPmButton({
    required this.label,
    required this.selectedColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 60,
        decoration: BoxDecoration(
          color: selected ? selectedColor : _gray,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.notoSansKr(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : _grayInk,
            height: 1.0,
            letterSpacing: -0.8,
          ),
        ),
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  final int? selected;
  final void Function(int) onTap;
  const _NumPad({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const rows = [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9],
      [10, 11, 12],
    ];
    return Column(
      children: [
        for (var rIdx = 0; rIdx < rows.length; rIdx++) ...[
          Row(
            children: [
              for (var i = 0; i < rows[rIdx].length; i++) ...[
                Expanded(
                  child: _NumKey(
                    n: rows[rIdx][i],
                    selected: selected == rows[rIdx][i],
                    onTap: () => onTap(rows[rIdx][i]),
                  ),
                ),
                if (i < rows[rIdx].length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
          if (rIdx < rows.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _NumKey extends StatelessWidget {
  final int n;
  final bool selected;
  final VoidCallback onTap;
  const _NumKey({
    required this.n,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 70,
        decoration: BoxDecoration(
          color: _accentPink,
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: Colors.black, width: 4) : null,
          boxShadow: [
            BoxShadow(
              color: _accentPink.withValues(alpha: 0.30),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$n',
          style: GoogleFonts.notoSansKr(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ConfirmButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD32F2F), Color(0xFFFF6F00)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD32F2F).withValues(alpha: 0.40),
              offset: const Offset(0, 6),
              blurRadius: 14,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '확인',
          style: GoogleFonts.notoSansKr(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1.0,
            height: 1.0,
          ),
        ),
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
