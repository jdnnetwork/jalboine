import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../widgets/back_pill.dart';
import '../../widgets/big_button.dart';

/// 화면 7-1: 약 복용 여부.
class MedHasScreen extends ConsumerStatefulWidget {
  const MedHasScreen({super.key});

  @override
  ConsumerState<MedHasScreen> createState() => _MedHasScreenState();
}

class _MedHasScreenState extends ConsumerState<MedHasScreen> {
  bool _busy = false;

  Future<void> _answer(bool yes) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final sb = ref.read(supabaseProvider);
      final uid = sb.auth.currentUser!.id;
      await sb
          .from('senior_settings')
          .upsert({'user_id': uid, 'takes_medication': yes});
      if (!mounted) return;
      if (yes) {
        context.go('/med/count');
      } else {
        context.go('/setup-done');
      }
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
              children: [
                Row(children: [BackPill(onTap: () => context.go('/'))]),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '혹시 약을 드시나요?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: JD.ink,
                      letterSpacing: -1.0,
                      height: 1.25,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: BigButton(
                        label: '네',
                        icon: Icons.check_rounded,
                        background: JD.cMint,
                        foreground: JD.ink,
                        shadowBottomColor: const Color(0xFF3C965A),
                        onTap: _busy ? null : () => _answer(true),
                        height: 96,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: BigButton(
                        label: '아니요',
                        icon: Icons.close_rounded,
                        background: Colors.white,
                        foreground: JD.ink,
                        shadowBottomColor: const Color(0xFFC8B89A),
                        onTap: _busy ? null : () => _answer(false),
                        height: 96,
                        fontSize: 28,
                        border: Border.all(
                          color: const Color(0xFFE8DDC9),
                          width: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
