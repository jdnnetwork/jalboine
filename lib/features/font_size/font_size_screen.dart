import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../widgets/big_button.dart';

/// 글자 크기 설정 화면 (1차/2차/3차).
/// 1차: 단계 1 → "네"=확정/"아니요"=2차로
/// 2차: 단계 2 → "네"=확정/"아니요"=3차로
/// 3차: 단계 3 → "알겠어요" 한 개 버튼으로 확정
class FontSizeScreen extends ConsumerStatefulWidget {
  final int level;
  const FontSizeScreen({super.key, required this.level});

  @override
  ConsumerState<FontSizeScreen> createState() => _FontSizeScreenState();
}

class _FontSizeScreenState extends ConsumerState<FontSizeScreen> {
  bool _busy = false;

  double get _fontSize => switch (widget.level) {
        1 => 32,
        2 => 44,
        _ => 56,
      };

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final sb = ref.read(supabaseProvider);
      final uid = sb.auth.currentUser!.id;
      await sb
          .from('profiles')
          .update({'font_size_level': widget.level}).eq('user_id', uid);
      if (!mounted) return;
      context.go('/age');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _busy = false);
    }
  }

  void _next() {
    context.go('/font-size?level=${widget.level + 1}');
  }

  @override
  Widget build(BuildContext context) {
    final isMax = widget.level >= 3;
    return Scaffold(
      body: SeniorBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    isMax
                        ? '이 크기가 가장 큰 글자예요.\n이대로 할게요'
                        : '글자가 잘 보이시나요?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w900,
                      color: JD.ink,
                      letterSpacing: -1.0,
                      height: 1.25,
                    ),
                  ),
                ),
                const Spacer(),
                if (isMax)
                  BigButton(
                    label: '알겠어요',
                    icon: Icons.check_rounded,
                    background: JD.cMint,
                    foreground: JD.ink,
                    shadowBottomColor: const Color(0xFF3C965A),
                    onTap: _busy ? null : _confirm,
                    height: 96,
                    fontSize: 30,
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: BigButton(
                          label: '네',
                          icon: Icons.check_rounded,
                          background: JD.cMint,
                          foreground: JD.ink,
                          shadowBottomColor: const Color(0xFF3C965A),
                          onTap: _busy ? null : _confirm,
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
                          onTap: _busy ? null : _next,
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
