import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../services/deep_link_service.dart';
import '../../widgets/big_button.dart';

class FamilyBranchScreen extends ConsumerStatefulWidget {
  const FamilyBranchScreen({super.key});

  @override
  ConsumerState<FamilyBranchScreen> createState() => _FamilyBranchScreenState();
}

class _FamilyBranchScreenState extends ConsumerState<FamilyBranchScreen> {
  String? _generatedCode;
  bool _resolved = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _resolve();
    });
  }

  Future<void> _resolve() async {
    final code = await DeepLinkService.instance.takePendingCode();
    if (code != null && code.isNotEmpty) {
      await _autoPair(code);
      return;
    }
    setState(() => _resolved = true);
  }

  Future<void> _autoPair(String code) async {
    setState(() => _busy = true);
    try {
      final sb = ref.read(supabaseProvider);
      final uid = sb.auth.currentUser!.id;
      await sb.from('pair_links').update({
        'senior_user_id': uid,
        'status': 'confirmed',
      }).eq('invite_code', code);
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() {
        _resolved = true;
        _busy = false;
      });
    }
  }

  String _gen() {
    // 1000~9999 범위의 4자리 코드.
    final r = Random.secure();
    return (1000 + r.nextInt(9000)).toString();
  }

  Future<void> _yes() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final sb = ref.read(supabaseProvider);
      final uid = sb.auth.currentUser!.id;
      final existing = await sb
          .from('pair_links')
          .select('invite_code, status')
          .eq('senior_user_id', uid)
          .maybeSingle();
      String code;
      if (existing != null && existing['invite_code'] != null) {
        code = existing['invite_code'] as String;
      } else {
        code = _gen();
        await sb.from('pair_links').insert({
          'senior_user_id': uid,
          'status': 'pending',
          'invite_code': code,
        });
      }
      setState(() {
        _generatedCode = code;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _busy = false);
    }
  }

  Future<void> _skip() async {
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SeniorBackground(
        child: SafeArea(
          child: !_resolved
              ? const Center(child: CircularProgressIndicator())
              : _generatedCode != null
                  ? _CodeView(code: _generatedCode!, onDone: _skip)
                  : _AskView(busy: _busy, onYes: _yes, onNo: _skip),
        ),
      ),
    );
  }
}

class _AskView extends StatelessWidget {
  final bool busy;
  final VoidCallback onYes;
  final VoidCallback onNo;
  const _AskView({required this.busy, required this.onYes, required this.onNo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: JD.cPinkBg,
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                    color: JD.cPink.withValues(alpha: 0.20),
                    offset: const Offset(0, 8),
                    blurRadius: 24),
              ],
            ),
            child: const Icon(Icons.favorite_rounded,
                color: Colors.white, size: 60),
          ),
          const SizedBox(height: 28),
          const Text(
            '가족과 연결할까요?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: JD.ink,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '연결하면 자녀가 도와드릴 수 있어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: JD.inkSoft,
            ),
          ),
          const Spacer(),
          BigButton(
            label: '네',
            icon: Icons.check_rounded,
            background: JD.cMint,
            foreground: JD.ink,
            shadowBottomColor: const Color(0xFF3C965A),
            onTap: busy ? null : onYes,
            height: 96,
            fontSize: 30,
          ),
          const SizedBox(height: 14),
          BigButton(
            label: '아니요',
            background: Colors.white,
            foreground: JD.ink,
            shadowBottomColor: const Color(0xFFC8B89A),
            border: Border.all(color: const Color(0xFFE8DDC9), width: 3),
            onTap: busy ? null : onNo,
            height: 96,
            fontSize: 30,
          ),
        ],
      ),
    );
  }
}

class _CodeView extends StatelessWidget {
  final String code;
  final VoidCallback onDone;
  const _CodeView({required this.code, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Text(
            '자녀분에게\n이 번호를 알려주세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: JD.ink,
              letterSpacing: -1.0,
              height: 1.25,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment(-1, -1),
                end: Alignment(1, 1),
                colors: [Color(0xFFFFE9C2), Color(0xFFFFD49A)],
              ),
              borderRadius: BorderRadius.circular(JD.rCardLg),
              boxShadow: [
                BoxShadow(
                    color: JD.cYellow.withValues(alpha: 0.25),
                    offset: const Offset(0, 12),
                    blurRadius: 30),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '연결 번호',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: JD.inkSoft,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  code,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: JD.ink,
                    letterSpacing: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '자녀분이 카카오/구글로 로그인 후\n이 번호를 입력하면 연결됩니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: JD.inkSoft,
              height: 1.5,
            ),
          ),
          const Spacer(),
          BigButton(
            label: '다음',
            icon: Icons.arrow_forward_rounded,
            background: JD.cCoralDeep,
            foreground: Colors.white,
            shadowBottomColor: const Color(0xFFD9794D),
            onTap: onDone,
            height: 84,
            fontSize: 26,
          ),
        ],
      ),
    );
  }
}
