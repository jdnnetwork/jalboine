import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/design_tokens.dart';

/// 큰 둥근 버튼 + 입체 stacked shadow.
class BigButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;
  final Color shadowBottomColor;
  final double height;
  final double fontSize;
  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? extraShadow;

  const BigButton({
    super.key,
    required this.label,
    required this.background,
    required this.shadowBottomColor,
    this.icon,
    this.onTap,
    this.foreground = Colors.white,
    this.height = 84,
    this.fontSize = 26,
    this.borderRadius,
    this.border,
    this.extraShadow,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(JD.rButton);
    final dec = BoxDecoration(
      color: background,
      borderRadius: br,
      border: border,
      boxShadow: [
        BoxShadow(color: shadowBottomColor, offset: const Offset(0, 8), blurRadius: 0),
        BoxShadow(color: shadowBottomColor.withValues(alpha: 0.30), offset: const Offset(0, 14), blurRadius: 24),
        if (extraShadow != null) ...extraShadow!,
      ],
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: br,
        onTap: onTap == null ? null : () {
          HapticFeedback.lightImpact();
          SystemSound.play(SystemSoundType.click);
          onTap!();
        },
        child: Ink(
          decoration: dec,
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: foreground, size: fontSize + 4),
                const SizedBox(width: 12),
              ],
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
