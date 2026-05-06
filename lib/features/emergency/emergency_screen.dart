import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../services/launcher_service.dart';
import '../../services/realtime_service.dart';

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  void _dial(String number) {
    HapticFeedback.heavyImpact();
    LauncherService.dial(number);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(seniorSettingsProvider);
    return Scaffold(
      body: SeniorBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 32),
                      onPressed: () => context.pop(),
                    ),
                    const Text(
                      '긴급 전화',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: JTheme.seniorText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _EmergencyCard(
                    bg: const Color(0xFFC8102E),
                    title: '119',
                    subtitle: '아플 때, 다쳤을 때',
                    onTap: () => _dial('119'),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _EmergencyCard(
                    bg: const Color(0xFF1F6FE0),
                    title: '112',
                    subtitle: '도움이 필요할 때',
                    onTap: () => _dial('112'),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: settings.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (s) {
                      if (s.emergencyContacts.isEmpty) {
                        return _EmergencyCard(
                          bg: const Color(0xFF6B7280),
                          title: '보호자',
                          subtitle: '아직 등록되지 않았어요',
                          onTap: () {},
                        );
                      }
                      final c = s.emergencyContacts.first;
                      return _EmergencyCard(
                        bg: const Color(0xFF2E7D5A),
                        title: c.name,
                        subtitle: c.phone,
                        onTap: () => _dial(c.phone),
                      );
                    },
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

class _EmergencyCard extends StatelessWidget {
  final Color bg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _EmergencyCard({
    required this.bg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.call_rounded, color: Colors.white, size: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
