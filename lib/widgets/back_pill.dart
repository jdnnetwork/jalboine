import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/design_tokens.dart';

/// 둥근 사각 뒤로가기 버튼 — 흰 배경 + 부드러운 그림자.
class BackPill extends StatelessWidget {
  final VoidCallback? onTap;
  final Color color;
  final Color iconColor;
  final double size;
  const BackPill({
    super.key,
    this.onTap,
    this.color = Colors.white,
    this.iconColor = JD.ink,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap ?? () => context.canPop() ? context.pop() : null,
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: JD.shadowPress,
          ),
          child: Icon(Icons.arrow_back_rounded, size: size * 0.5, color: iconColor),
        ),
      ),
    );
  }
}
