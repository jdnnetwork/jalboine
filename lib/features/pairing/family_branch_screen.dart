import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../services/audio_service.dart';
import '../../services/deep_link_service.dart';

/// 가족 연결 분기:
/// - 딥링크로 들어온 코드가 있으면 자동 연결 → 홈
/// - 없으면 "가족과 연결할까요?" → 네: 6자리 코드 표시 / 아니요: 홈
class FamilyBranchScreen extends ConsumerStatefulWidget {
  const FamilyBranchScreen({super.key});

  @override
  ConsumerState<FamilyBranchScreen> createState() =>
      _FamilyBranchScreenState();
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
    AudioService.instance.play(JConst.audioFamily);
  }

  Future<void> _autoPair(String code) async {
    setState(() => _busy = true);
    try {
      final sb = ref.read(supabaseProvider);
      final uid = sb.auth.currentUser!.id;
      // 코드를 가진 pair_link을 본인 senior로 연결
      await sb.from('pair_links').update({
        'senior_user_id': uid,
        'status': 'accepted',
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
    final r = Random.secure();
    return List.generate(6, (_) => r.nextInt(10).toString()).join();
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
      _speakCode(code);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _busy = false);
    }
  }

  void _speakCode(String code) {
    // 코드 자체를 읽어주는 음성 파일은 없으므로 family.mp3 안내음 재생
    AudioService.instance.play(JConst.audioFamily);
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
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            '가족과 연결하시겠어요?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            '연결하면 자녀가 도와줄 수 있어요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D5A),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(110),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              textStyle:
                  const TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
            ),
            onPressed: busy ? null : onYes,
            child: const Text('네'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC8102E),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(110),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              textStyle:
                  const TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
            ),
            onPressed: busy ? null : onNo,
            child: const Text('아니요'),
          ),
          const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            '자녀분에게\n이 번호를 알려주세요',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              code,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.w900,
                letterSpacing: 12,
                color: JTheme.seniorAccent,
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: JTheme.seniorAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('다음'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
