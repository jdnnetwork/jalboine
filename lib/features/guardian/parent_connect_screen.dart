import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';

/// 보호자가 피보호자가 생성한 4자리 연결 코드를 입력하는 화면.
class ParentConnectScreen extends ConsumerStatefulWidget {
  const ParentConnectScreen({super.key});

  @override
  ConsumerState<ParentConnectScreen> createState() =>
      _ParentConnectScreenState();
}

class _ParentConnectScreenState extends ConsumerState<ParentConnectScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_busy) return;
    final code = _code.text.trim();
    if (code.length != 4 || int.tryParse(code) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('번호가 맞지 않아요. 다시 확인해주세요')));
      return;
    }
    setState(() => _busy = true);
    try {
      final sb = ref.read(supabaseProvider);
      final uid = sb.auth.currentUser!.id;
      final row = await sb
          .from('pair_links')
          .select('id, senior_user_id')
          .eq('invite_code', code)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null || row['senior_user_id'] == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('번호가 맞지 않아요. 다시 확인해주세요')));
        return;
      }
      await sb.from('pair_links').update({
        'guardian_user_id': uid,
        'status': 'accepted',
      }).eq('id', row['id'] as String);
      if (!mounted) return;
      context.go('/guardian/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: JTheme.guardian(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Back(onTap: () => context.go('/guardian/connect-method')),
                const SizedBox(height: 28),
                const Text(
                  '연결 번호 입력',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: JD.gInk,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '부모님이 알려주신 연결 번호를 입력해주세요',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: JD.gInkSoft,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: JD.gBlue,
                    letterSpacing: 12,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: JD.gBg,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 22),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: JD.gBlue, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _busy ? null : _connect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JD.gBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  child: const Text('연결하기'),
                ),
                // ===== DEV ONLY: 릴리즈 시 이 블록만 삭제 =====
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : _devConnect,
                  style: TextButton.styleFrom(
                    foregroundColor: JD.gInkMute,
                    minimumSize: const Size.fromHeight(36),
                  ),
                  child: const Text(
                    'DEV: 테스트 연결',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // ===== /DEV =====
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// DEV 전용: 코드 검증 없이 보호자 본인을 더미 senior로 묶고 대시보드로 이동.
  /// 릴리즈 시 이 메서드와 위 TextButton을 함께 삭제하면 된다.
  Future<void> _devConnect() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final sb = ref.read(supabaseProvider);
      final uid = sb.auth.currentUser!.id;
      await sb.from('pair_links').insert({
        'senior_user_id': uid,
        'guardian_user_id': uid,
        'status': 'accepted',
      });
      if (!mounted) return;
      context.go('/guardian/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('DEV 연결 실패: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _Back extends StatelessWidget {
  final VoidCallback onTap;
  const _Back({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: JD.gBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.arrow_back_rounded, size: 20, color: JD.gInk),
          ),
        ),
      ),
    );
  }
}
