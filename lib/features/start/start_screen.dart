import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/theme.dart';
import '../../services/device_auth_service.dart';
import '../../widgets/big_button.dart';

class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen> {
  bool _busy = false;

  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await DeviceAuthService.instance.ensureSenior();
      if (!mounted) return;
      context.go('/audio-guide-ask');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SeniorBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Image.asset(
                  'assets/images/logo.png',
                  width: 160,
                  height: 160,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                const Text(
                  '잘보이네',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: JD.ink,
                    letterSpacing: -2.2,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '어르신을 위한 쉬운 스마트폰',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: JD.inkSoft,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 28),
                BigButton(
                  label: '시작하기',
                  icon: Icons.arrow_forward_rounded,
                  background: JD.cCoralDeep,
                  shadowBottomColor: const Color(0xFFD9794D),
                  foreground: Colors.white,
                  height: 88,
                  fontSize: 30,
                  onTap: _busy ? null : _start,
                ),
                const SizedBox(height: 12),
                const Text(
                  '(이 버튼을 누르세요)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: JD.inkMute,
                  ),
                ),
                const Spacer(flex: 3),
                _GuardianHint(onTap: () => context.go('/guardian/login')),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuardianHint extends StatelessWidget {
  final VoidCallback onTap;
  const _GuardianHint({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: DottedBorder(
          color: const Color(0xFFC8B89A),
          radius: 24,
          strokeWidth: 2.5,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_rounded, size: 20, color: JD.inkSoft),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '가족 및 어르신을 도와주시는 분은 여기를 눌러주세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: JD.inkSoft,
                      letterSpacing: -0.3,
                    ),
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

class DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;
  const DottedBorder({
    super.key,
    required this.child,
    required this.color,
    required this.radius,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(
        color: color,
        radius: radius,
        strokeWidth: strokeWidth,
      ),
      child: child,
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  _DashedRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final dashed = _dashPath(path, dashWidth: 8, gapWidth: 6);
    canvas.drawPath(dashed, paint);
  }

  Path _dashPath(Path path, {required double dashWidth, required double gapWidth}) {
    final dest = Path();
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final next = dist + dashWidth;
        dest.addPath(metric.extractPath(dist, next.clamp(0, metric.length)), Offset.zero);
        dist = next + gapWidth;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth;
}
