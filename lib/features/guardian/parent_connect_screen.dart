import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';

class ParentConnectScreen extends ConsumerStatefulWidget {
  const ParentConnectScreen({super.key});

  @override
  ConsumerState<ParentConnectScreen> createState() =>
      _ParentConnectScreenState();
}

class _ParentConnectScreenState extends ConsumerState<ParentConnectScreen> {
  final _phone = TextEditingController();
  bool _busy = false;
  String? _code;

  String _gen() {
    final r = Random.secure();
    return List.generate(6, (_) => r.nextInt(10).toString()).join();
  }

  Future<void> _sendSms() async {
    if (_busy) return;
    final phoneRaw = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (phoneRaw.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('전화번호를 정확히 입력해주세요')));
      return;
    }
    setState(() => _busy = true);
    try {
      final sb = ref.read(supabaseProvider);
      final uid = sb.auth.currentUser!.id;
      await sb.from('profiles').upsert({
        'user_id': uid,
        'role': 'guardian',
        'parent_phone': phoneRaw,
      });
      String code;
      final existing = await sb
          .from('pair_links')
          .select('invite_code, status')
          .eq('guardian_user_id', uid)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (existing != null && existing['invite_code'] != null) {
        code = existing['invite_code'] as String;
      } else {
        code = _gen();
        await sb.from('pair_links').insert({
          'guardian_user_id': uid,
          'status': 'pending',
          'invite_code': code,
        });
      }
      setState(() => _code = code);

      final uri = Uri.parse('https://jalboine.app/connect?code=$code');
      final body = '잘보이네 앱 설치 후 자동 연결돼요. $uri (연결코드: $code)';
      final smsUri = Uri(
        scheme: 'sms',
        path: phoneRaw,
        queryParameters: {'body': body},
      );
      await launchUrl(smsUri);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: JTheme.guardian(),
      child: Scaffold(
        backgroundColor: JD.gBg,
        body: GuardianBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Back(onTap: () => context.go('/')),
                  const SizedBox(height: 16),
                  const Text(
                    '부모님 연결',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: JD.gInk,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '부모님 전화번호를 입력하면\n설치 링크와 연결 코드를 문자로 보내드려요',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: JD.gInkSoft,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: JD.gCard,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: JD.shadowBlueCard,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: JD.gInk),
                          decoration: InputDecoration(
                            labelText: '부모님 전화번호',
                            filled: true,
                            fillColor: JD.gBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: _busy ? null : _sendSms,
                          icon: const Icon(Icons.sms_rounded),
                          label: const Text('문자 보내기'),
                        ),
                      ],
                    ),
                  ),
                  if (_code != null) ...[
                    const SizedBox(height: 16),
                    _CodeCard(code: _code!),
                  ],
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => context.go('/guardian/dashboard'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: JD.gLine),
                      foregroundColor: JD.gInk,
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('대시보드로'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: JD.shadowBlueCard,
            ),
            child: const Icon(Icons.arrow_back_rounded,
                size: 22, color: JD.gInk),
          ),
        ),
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  final String code;
  const _CodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: JD.gBlueSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: JD.gBlue.withValues(alpha: 0.20), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '연결 코드',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: JD.gInkMute,
                letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            code,
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: JD.gBlue,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '부모님이 앱을 설치하고 문자 링크를 누르면 자동 연결됩니다',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: JD.gInkSoft,
                height: 1.5),
          ),
        ],
      ),
    );
  }
}
