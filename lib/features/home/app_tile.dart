import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';

class AppTile extends StatelessWidget {
  final String appKey;
  final VoidCallback onTap;
  const AppTile({super.key, required this.appKey, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = JConst.apps[appKey];
    if (meta == null) return const SizedBox();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          HapticFeedback.lightImpact();
          SystemSound.play(SystemSoundType.click);
          onTap();
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, meta.gradient],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: meta.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(meta.icon, color: meta.fg, size: 40),
              ),
              const SizedBox(height: 12),
              Text(
                meta.label,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2A2118),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
