import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/design_tokens.dart';

/// 흰 카드 + stacked shadow + 둥근 모서리.
class ElderCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadow;

  const ElderCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.radius = JD.rCard,
    this.onTap,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final dec = BoxDecoration(
      color: color ?? JD.bgCard,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadow ?? JD.shadowCard,
    );
    final body = Padding(padding: padding, child: child);
    if (onTap == null) {
      return DecoratedBox(decoration: dec, child: body);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: () {
          HapticFeedback.lightImpact();
          SystemSound.play(SystemSoundType.click);
          onTap!();
        },
        child: Ink(decoration: dec, child: body),
      ),
    );
  }
}

/// 그라디언트 배경 카드 (앱 타일/긴급 카드용).
class GradientCard extends StatelessWidget {
  final Gradient gradient;
  final Color shadowColor;
  final BorderRadiusGeometry borderRadius;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    required this.gradient,
    required this.shadowColor,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(JD.rCard)),
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius is BorderRadius
        ? borderRadius as BorderRadius
        : const BorderRadius.all(Radius.circular(JD.rCard));
    final dec = BoxDecoration(
      gradient: gradient,
      borderRadius: br,
      boxShadow: [
        BoxShadow(color: shadowColor.withValues(alpha: 0.40), offset: const Offset(0, 6), blurRadius: 0),
        BoxShadow(color: shadowColor.withValues(alpha: 0.40), offset: const Offset(0, 14), blurRadius: 26),
      ],
    );
    final body = Padding(padding: padding, child: child);
    if (onTap == null) return DecoratedBox(decoration: dec, child: body);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: br,
        onTap: () {
          HapticFeedback.lightImpact();
          SystemSound.play(SystemSoundType.click);
          onTap!();
        },
        child: Ink(decoration: dec, child: body),
      ),
    );
  }
}
