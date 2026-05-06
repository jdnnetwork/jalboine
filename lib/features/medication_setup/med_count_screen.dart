import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';

class MedCountScreen extends StatefulWidget {
  const MedCountScreen({super.key});

  @override
  State<MedCountScreen> createState() => _MedCountScreenState();
}

class _MedCountScreenState extends State<MedCountScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService.instance.play(JConst.audioMedicineCount);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SeniorBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  '하루에 몇 번\n약을 드시나요?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const Spacer(),
                for (final n in const [1, 2, 3]) ...[
                  _CountButton(
                    n: n,
                    onTap: () => context.go('/med/hour?count=$n'),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountButton extends StatelessWidget {
  final int n;
  final VoidCallback onTap;
  const _CountButton({required this.n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFFFE0B2)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          height: 100,
          child: Center(
            child: Text(
              '$n번',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: JTheme.seniorText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
