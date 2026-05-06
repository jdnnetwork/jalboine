import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';

/// 보호자 → 부모님 연결 화면.
/// 전화번호 입력 후 SMS 앱을 열어 설치 링크 + 연결 코드를 보냅니다.
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

      // 본인 보호자로 등록
      await sb.from('profiles').upsert({
        'user_id': uid,
        'role': 'guardian',
        'parent_phone': phoneRaw,
      });

      // 코드 생성/저장
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
      final body =
          '잘보이네 앱 설치 후 자동 연결돼요. $uri (연결코드: $code)';
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

  Future<void> _continue() async {
    context.go('/guardian/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: JTheme.guardian(),
      child: Scaffold(
        body: GuardianBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => context.go('/'),
                      ),
                      const Text(
                        '부모님 연결',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: JTheme.guardianText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '부모님 전화번호를 입력하면\n자동으로 설치 링크를 보내드려요',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      labelText: '부모님 전화번호',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _sendSms,
                    icon: const Icon(Icons.sms_rounded),
                    label: const Text('문자 보내기'),
                  ),
                  if (_code != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '연결 코드',
                            style: TextStyle(
                                fontSize: 14, color: Colors.black54),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _code!,
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                              color: JTheme.guardianAccent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '부모님이 앱을 설치하고 링크를 누르면 자동 연결됩니다',
                            style: TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  OutlinedButton(
                    onPressed: _continue,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
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
