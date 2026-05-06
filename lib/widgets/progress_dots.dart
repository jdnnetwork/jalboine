import 'package:flutter/material.dart';
import '../core/design_tokens.dart';

class ProgressDots extends StatelessWidget {
  final int total;
  final int current;
  const ProgressDots({super.key, required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: active ? 36 : 12,
          height: 12,
          decoration: BoxDecoration(
            color: active ? JD.cCoralDeep : JD.inkMute.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(active ? 6 : 999),
          ),
        );
      }),
    );
  }
}
