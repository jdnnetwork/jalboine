import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';

/// 피보호자 홈 화면 우측 하단 "가족 연결" 텍스트 버튼.
/// family_dismissed 가 true 이면 표시하지 않음.
class FamilyConnectButton extends ConsumerStatefulWidget {
  const FamilyConnectButton({super.key});

  @override
  ConsumerState<FamilyConnectButton> createState() =>
      _FamilyConnectButtonState();
}

class _FamilyConnectButtonState extends ConsumerState<FamilyConnectButton> {
  bool _dismissed = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sb = ref.read(supabaseProvider);
      final uid = sb.auth.currentUser?.id;
      if (uid == null) return;
      final r = await sb
          .from('profiles')
          .select('family_dismissed')
          .eq('user_id', uid)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _dismissed = (r?['family_dismissed'] as bool?) ?? false;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _onTap() async {
    final wantHelp = await _ask(
      title: '가족이나 자녀의 도움이\n필요하신가요?',
      yes: '네',
      no: '아니요',
    );
    if (!mounted) return;
    if (wantHelp == true) {
      await _showCode();
    } else if (wantHelp == false) {
      final reallyNo = await _ask(
        title: '정말 필요 없으신가요?',
        yes: '네 필요 없어요',
        no: '아니요\n다시 생각해볼게요',
      );
      if (!mounted) return;
      if (reallyNo == true) {
        try {
          final sb = ref.read(supabaseProvider);
          final uid = sb.auth.currentUser!.id;
          await sb
              .from('profiles')
              .update({'family_dismissed': true}).eq('user_id', uid);
          if (!mounted) return;
          setState(() => _dismissed = true);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }

  Future<bool?> _ask({
    required String title,
    required String yes,
    required String no,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: JD.ink,
              height: 1.3,
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              no,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: JD.inkSoft,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              yes,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: JD.cCoralDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCode() async {
    String? code;
    try {
      final sb = ref.read(supabaseProvider);
      final uid = sb.auth.currentUser!.id;
      // 이미 발급된 pending 코드가 있으면 재사용
      final existing = await sb
          .from('pair_links')
          .select('invite_code')
          .eq('senior_user_id', uid)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (existing != null && existing['invite_code'] != null) {
        code = existing['invite_code'] as String;
      } else {
        code = _gen4();
        await sb.from('pair_links').insert({
          'senior_user_id': uid,
          'status': 'pending',
          'invite_code': code,
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
      return;
    }
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '자녀분에게 잘보이네 앱\n설치를 부탁하세요.\n그리고 이 번호를 알려주세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: JD.ink,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                code!,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: JD.cCoralDeep,
                  letterSpacing: 14,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '확인',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: JD.cCoralDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _gen4() {
    final r = Random.secure();
    return List.generate(4, (_) => r.nextInt(10)).join();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _dismissed) return const SizedBox.shrink();
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            '가족 연결',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: JD.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}
