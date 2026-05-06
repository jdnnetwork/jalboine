import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../widgets/back_pill.dart';
import '../../widgets/elder_card.dart';

class AgeScreen extends ConsumerStatefulWidget {
  const AgeScreen({super.key});

  @override
  ConsumerState<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends ConsumerState<AgeScreen> {
  bool _busy = false;
  String? _selected;

  static const _groups = <(String, String, Color)>[
    ('60_64', '60대 초반', JD.cMint),
    ('65_69', '60대 후반', JD.cYellowBg),
    ('70_74', '70대 초반', JD.cLavender),
    ('75_79', '70대 후반', JD.cPinkBg),
    ('80_plus', '80세 이상', JD.cCoral),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService.instance.play(JConst.audioAge);
    });
  }

  Future<void> _pick(String group) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _selected = group;
    });
    try {
      final sb = ref.read(supabaseProvider);
      final uid = sb.auth.currentUser!.id;
      await sb.from('profiles').update({'age_group': group}).eq('user_id', uid);
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      context.go('/onboarding');
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [BackPill(onTap: () => context.go('/'))]),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '연세가 어떻게 되세요?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: JD.ink,
                      letterSpacing: -1.0,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '글자 크기를 맞춰드릴게요',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: JD.inkSoft,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.separated(
                    itemCount: _groups.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (_, i) {
                      final g = _groups[i];
                      final selected = _selected == g.$1;
                      return ElderCard(
                        onTap: _busy ? null : () => _pick(g.$1),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: g.$3,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: JD.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Text(
                                g.$2,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: JD.ink,
                                  letterSpacing: -0.6,
                                ),
                              ),
                            ),
                            Icon(
                              selected
                                  ? Icons.check_circle_rounded
                                  : Icons.arrow_forward_ios_rounded,
                              color: selected ? JD.cGreen : JD.inkMute,
                              size: selected ? 32 : 22,
                            ),
                          ],
                        ),
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
