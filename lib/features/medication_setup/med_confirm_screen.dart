import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/supabase.dart';
import '../../services/audio_service.dart';
import '../../services/notification_service.dart';
import '../../services/onboarding_settings_service.dart';

const _ink = Color(0xFF1A1A2E);
const _accentPink = Color(0xFFFF6B8A);
const _yesStart = Color(0xFFFF2D6F);
const _yesEnd = Color(0xFFFF5A8A);
const _noBg = Color(0xFFF0F0F0);
const _noFg = Color(0xFF2D2D2D);
const _cardBg = Color(0xFFFFF0F0);
const _cardInk = Color(0xFF3E2723);
const _guideBg = Color(0xFFFFF8E1);
const _emphasisRed = Color(0xFFD32F2F);

const _audioConfirm = 'assets/audio/alarm_confirm.wav';
const _audioPermission = 'assets/audio/permission_alarm.wav';

enum _Stage { confirm, declined, permission }

/// 화면 7-5: 약 알림 확인 + 알림 권한 안내.
class MedConfirmScreen extends ConsumerStatefulWidget {
  final List<String> times;
  final int count;
  final List<String> slots;
  const MedConfirmScreen({
    super.key,
    required this.times,
    required this.count,
    required this.slots,
  });

  @override
  ConsumerState<MedConfirmScreen> createState() => _MedConfirmScreenState();
}

class _MedConfirmScreenState extends ConsumerState<MedConfirmScreen> {
  _Stage _stage = _Stage.confirm;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playStageAudio());
  }

  String get _stageAudio =>
      _stage == _Stage.permission ? _audioPermission : _audioConfirm;

  void _playStageAudio() {
    if (ref.read(audioGuideModeProvider)) {
      AudioService.instance.play(_stageAudio);
    }
  }

  Future<void> _saveMedications({required bool alarmEnabled}) async {
    final sb = ref.read(supabaseProvider);
    final uid = sb.auth.currentUser!.id;
    final timesWithSec = widget.times.map((t) => '$t:00').toList();
    await sb.from('medications').upsert({
      'user_id': uid,
      'frequency': widget.count,
      'times_per_day': widget.count,
      'times': timesWithSec,
      'alarm_enabled': alarmEnabled,
    });
    if (alarmEnabled) {
      await NotificationService.instance.rescheduleMedications(timesWithSec);
    } else {
      await NotificationService.instance.cancelAll();
    }
  }

  Future<void> _onYes() async {
    if (_busy) return;
    setState(() => _stage = _Stage.permission);
    await AudioService.instance.stop();
    _playStageAudio();
  }

  Future<void> _onNo() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _stage = _Stage.declined;
    });
    try {
      await _saveMedications(alarmEnabled: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    context.go('/setup-done');
  }

  Future<void> _onPermissionConfirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    final status = await Permission.notification.request();
    final granted = status.isGranted;
    try {
      await _saveMedications(alarmEnabled: granted);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (!mounted) return;
    context.go('/setup-done');
  }

  Future<void> _onToggleAudio() async {
    final on = ref.read(audioGuideModeProvider);
    if (on) {
      await AudioService.instance.stop();
      await OnboardingSettingsService.setAudioGuide(ref, false);
    } else {
      await AudioService.instance.play(_stageAudio);
    }
  }

  String get _bubbleText {
    return switch (_stage) {
      _Stage.confirm => '이 시간에 큰 알림으로\n알려드릴까요?',
      _Stage.declined => '나중에 다시\n설정할 수 있어요',
      _Stage.permission => '알림을 보내드리려면\n허락이 필요해요',
    };
  }

  String _slotKeyForIndex(int idx) {
    if (idx < widget.slots.length) return widget.slots[idx];
    if (widget.count == 2) return idx == 0 ? 'morning' : 'evening';
    if (widget.count == 3) {
      return switch (idx) {
        0 => 'morning',
        1 => 'lunch',
        _ => 'evening',
      };
    }
    return '';
  }

  List<_TimeCardData> get _cards {
    final out = <_TimeCardData>[];
    for (var i = 0; i < widget.times.length; i++) {
      final t = widget.times[i];
      final parts = t.split(':');
      final h24 = int.tryParse(parts.first) ?? 0;
      final slotKey = _slotKeyForIndex(i);
      out.add(_TimeCardData(slotKey: slotKey, hour24: h24));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final guideOn = ref.watch(audioGuideModeProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: _stage == _Stage.permission
              ? _buildPermission(guideOn)
              : _buildConfirm(guideOn),
        ),
      ),
    );
  }

  Widget _buildConfirm(bool guideOn) {
    final declined = _stage == _Stage.declined;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 2),
        _MascotWithBubble(text: _bubbleText),
        const SizedBox(height: 20),
        if (!declined)
          ...[
            for (final c in _cards) ...[
              _TimeCard(data: c),
              const SizedBox(height: 12),
            ],
          ],
        const Spacer(flex: 2),
        if (!declined)
          Row(
            children: [
              Expanded(
                child: _YesButton(onTap: _busy ? null : _onYes),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _NoButton(onTap: _busy ? null : _onNo),
              ),
            ],
          ),
        const Spacer(flex: 1),
        _AudioBar(on: guideOn, onTap: _onToggleAudio),
      ],
    );
  }

  Widget _buildPermission(bool guideOn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _MascotWithBubble(text: _bubbleText),
                const SizedBox(height: 24),
                const _PermissionGuideCard(),
                const SizedBox(height: 24),
                _OkButton(
                  onTap: _busy ? null : _onPermissionConfirm,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        _AudioBar(on: guideOn, onTap: _onToggleAudio),
      ],
    );
  }
}

class _TimeCardData {
  final String slotKey;
  final int hour24;
  const _TimeCardData({required this.slotKey, required this.hour24});
}

class _TimeCard extends StatelessWidget {
  final _TimeCardData data;
  const _TimeCard({required this.data});

  String get _label {
    final slot = switch (data.slotKey) {
      'morning' => '아침',
      'lunch' => '점심',
      'evening' => '저녁',
      _ => '',
    };
    final h24 = data.hour24;
    final h12 = h24 == 0
        ? 12
        : (h24 == 12 ? 12 : (h24 > 12 ? h24 - 12 : h24));
    if (slot.isEmpty) {
      final ampm = h24 < 12 ? '오전' : '오후';
      return '$ampm $h12시';
    }
    return '$slot $h12시';
  }

  IconData get _icon {
    return switch (data.slotKey) {
      'evening' => Icons.nightlight_round,
      _ => Icons.wb_sunny_rounded,
    };
  }

  Color get _iconColor {
    return data.slotKey == 'evening'
        ? const Color(0xFF6D4C41)
        : const Color(0xFFFFA000);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentPink, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_icon, color: _iconColor, size: 28),
          const SizedBox(width: 10),
          Text(
            _label,
            style: GoogleFonts.notoSansKr(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _cardInk,
              letterSpacing: -0.8,
              height: 1.0,
            ),
          ),
        ],
      ),
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
          padding: const EdgeInsets.only(top: 84),
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
          width: 120,
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

class _YesButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _YesButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_yesStart, _yesEnd],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _yesStart.withValues(alpha: 0.35),
              offset: const Offset(0, 8),
              blurRadius: 18,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '네',
          style: GoogleFonts.notoSansKr(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1.2,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _NoButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _NoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: _noBg,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          '아니요',
          style: GoogleFonts.notoSansKr(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: _noFg,
            letterSpacing: -1.2,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _PermissionGuideCard extends StatelessWidget {
  const _PermissionGuideCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _guideBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '곧 작은 창이 뜰 거예요',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _cardInk,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "거기에서 '허용'을\n꼭 눌러주세요",
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: _emphasisRed,
              letterSpacing: -1.0,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '허용을 누르시면\n약 드실 시간에 알려드려요',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _cardInk,
              letterSpacing: -0.6,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _OkButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _OkButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_emphasisRed, Color(0xFFFF6F00)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _emphasisRed.withValues(alpha: 0.40),
              offset: const Offset(0, 8),
              blurRadius: 18,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '알겠어요',
          style: GoogleFonts.notoSansKr(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1.2,
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
