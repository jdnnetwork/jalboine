import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/theme.dart';
import '../../services/launcher_service.dart';
import '../../services/realtime_service.dart';
import '../../widgets/back_pill.dart';

class _Contact {
  final String label;
  final String sub;
  final IconData icon;
  final Color gradStart;
  final Color gradEnd;
  final String number;
  const _Contact({
    required this.label,
    required this.sub,
    required this.icon,
    required this.gradStart,
    required this.gradEnd,
    required this.number,
  });
}

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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    BackPill(onTap: () => context.go('/home')),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '긴급 전화',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: JD.cRed,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '어디에 거시나요?',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: JD.ink,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _EmCard(
                        contact: const _Contact(
                          label: '119',
                          sub: '소방서 · 응급실',
                          icon: Icons.local_fire_department_rounded,
                          gradStart: Color(0xFFD92020),
                          gradEnd: Color(0xFFF04545),
                          number: '119',
                        ),
                        onTap: () => _dial('119'),
                      ),
                      const SizedBox(height: 14),
                      _EmCard(
                        contact: const _Contact(
                          label: '112',
                          sub: '경찰서',
                          icon: Icons.shield_rounded,
                          gradStart: Color(0xFF6B4FB8),
                          gradEnd: Color(0xFF8E72D9),
                          number: '112',
                        ),
                        onTap: () => _dial('112'),
                      ),
                      const SizedBox(height: 14),
                      settings.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (s) {
                          if (s.emergencyContacts.isEmpty) {
                            return _EmCard(
                              contact: const _Contact(
                                label: '보호자',
                                sub: '아직 등록되지 않았어요',
                                icon: Icons.favorite_rounded,
                                gradStart: Color(0xFF6B7280),
                                gradEnd: Color(0xFF9099AC),
                                number: '',
                              ),
                              onTap: () {},
                            );
                          }
                          final c = s.emergencyContacts.first;
                          return _EmCard(
                            contact: _Contact(
                              label: c.name,
                              sub: c.phone,
                              icon: Icons.favorite_rounded,
                              gradStart: const Color(0xFF1F8A5B),
                              gradEnd: const Color(0xFF34B074),
                              number: c.phone,
                            ),
                            onTap: () => _dial(c.phone),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '위 카드를 한 번만 누르면\n바로 전화가 연결됩니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: JD.inkSoft,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
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

class _EmCard extends StatelessWidget {
  final _Contact contact;
  final VoidCallback onTap;
  const _EmCard({required this.contact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(JD.rCard),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(-1, -1),
              end: const Alignment(1, 1),
              colors: [contact.gradStart, contact.gradEnd],
            ),
            borderRadius: BorderRadius.circular(JD.rCard),
            boxShadow: [
              BoxShadow(
                  color: contact.gradStart.withValues(alpha: 0.40),
                  offset: const Offset(0, 6),
                  blurRadius: 0),
              BoxShadow(
                  color: contact.gradStart.withValues(alpha: 0.40),
                  offset: const Offset(0, 14),
                  blurRadius: 26),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(contact.icon, color: Colors.white, size: 42),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.label,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.6,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      contact.sub,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.call_rounded,
                    color: Colors.white, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
