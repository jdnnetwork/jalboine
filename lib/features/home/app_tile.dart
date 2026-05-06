import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';
import '../../core/design_tokens.dart';

class AppTile extends StatelessWidget {
  final String appKey;
  final VoidCallback onTap;
  const AppTile({super.key, required this.appKey, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = JConst.apps[appKey];
    if (meta == null) return const SizedBox.shrink();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(JD.rCard),
        onTap: () {
          HapticFeedback.lightImpact();
          SystemSound.play(SystemSoundType.click);
          onTap();
        },
        child: Ink(
          decoration: BoxDecoration(
            gradient: meta.gradient,
            borderRadius: BorderRadius.circular(JD.rCard),
            boxShadow: [
              BoxShadow(
                color: meta.shadow.withValues(alpha: 0.40),
                offset: const Offset(0, 6),
                blurRadius: 0,
              ),
              BoxShadow(
                color: meta.shadow.withValues(alpha: 0.40),
                offset: const Offset(0, 14),
                blurRadius: 26,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: meta.iconBg,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Icon(meta.icon, color: meta.iconColor, size: 50),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    meta.label,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: meta.textColor,
                      letterSpacing: -0.6,
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
