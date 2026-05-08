import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';

class GuardianLoginScreen extends ConsumerStatefulWidget {
  const GuardianLoginScreen({super.key});

  @override
  ConsumerState<GuardianLoginScreen> createState() =>
      _GuardianLoginScreenState();
}

class _GuardianLoginScreenState extends ConsumerState<GuardianLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signupMode = false;
  bool _busy = false;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;

  bool get _allAgree => _agreeTerms && _agreePrivacy;
  bool get _canSubmit =>
      !_busy && (_signupMode ? _allAgree : true);

  void _toggleAll(bool v) {
    setState(() {
      _agreeTerms = v;
      _agreePrivacy = v;
    });
  }

  void _viewTerms(String asset, String title) {
    context.push('/terms/view', extra: {'asset': asset, 'title': title});
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final email = _email.text.trim();
    final pw = _password.text;
    if (email.isEmpty || pw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일과 비밀번호를 입력해주세요')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final sb = ref.read(supabaseProvider);
      if (_signupMode) {
        await sb.auth.signUp(email: email, password: pw);
      } else {
        await sb.auth.signInWithPassword(email: email, password: pw);
      }
      final uid = sb.auth.currentUser?.id;
      if (uid != null) {
        await sb.from('profiles').upsert({
          'user_id': uid,
          'role': 'guardian',
        });
      }
      if (!mounted) return;
      context.go('/guardian/connect-method');
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
                _Back(onTap: () => context.go('/')),
                const SizedBox(height: 28),
                const Text(
                  '잘보이네',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: JD.gInkMute,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _signupMode ? '가족 계정 만들기' : '가족을 도와주세요',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: JD.gInk,
                    letterSpacing: -0.8,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 32),
                _Field(
                  controller: _email,
                  label: '이메일',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _password,
                  label: '비밀번호',
                  obscure: true,
                ),
                if (_signupMode) ...[
                  const SizedBox(height: 18),
                  _AllAgreeRow(
                    value: _allAgree,
                    onTap: () => _toggleAll(!_allAgree),
                  ),
                  const SizedBox(height: 8),
                  _AgreeRow(
                    label: '이용약관 동의',
                    value: _agreeTerms,
                    onChanged: (v) => setState(() => _agreeTerms = v),
                    onView: () => _viewTerms(
                      'assets/terms/guardian_terms.md',
                      '잘보이네 이용약관',
                    ),
                  ),
                  _AgreeRow(
                    label: '개인정보 수집 및 이용 동의',
                    value: _agreePrivacy,
                    onChanged: (v) => setState(() => _agreePrivacy = v),
                    onView: () => _viewTerms(
                      'assets/terms/guardian_privacy.md',
                      '개인정보처리방침',
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JD.gBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  child: Text(_signupMode ? '회원가입' : '로그인'),
                ),
                const Spacer(),
                Center(
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _signupMode = !_signupMode),
                    style: TextButton.styleFrom(
                      foregroundColor: JD.gInkSoft,
                    ),
                    child: Text(
                      _signupMode
                          ? '이미 계정이 있으신가요? 로그인'
                          : '계정이 없으신가요? 회원가입',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // ===== DEV ONLY: 릴리즈 시 이 블록만 삭제 =====
                Center(
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () => context.go('/guardian/connect-method?dev=1'),
                    style: TextButton.styleFrom(
                      foregroundColor: JD.gInkMute,
                    ),
                    child: const Text(
                      'DEV: 로그인 없이 진입',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
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
}

class _AllAgreeRow extends StatelessWidget {
  final bool value;
  final VoidCallback onTap;
  const _AllAgreeRow({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: JD.gBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? JD.gBlue : JD.gLine,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            _CheckBox(value: value),
            const SizedBox(width: 10),
            const Text(
              '전체 동의',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: JD.gInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgreeRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onView;
  const _AgreeRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onChanged(!value),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: _CheckBox(value: value),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(!value),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '[필수] ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: JD.gBlue,
                      ),
                    ),
                    TextSpan(
                      text: label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: JD.gInk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: onView,
            style: TextButton.styleFrom(
              foregroundColor: JD.gInkSoft,
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              '보기',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  final bool value;
  const _CheckBox({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: value ? JD.gBlue : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: value ? JD.gBlue : const Color(0xFFCBD3DE),
          width: 1.5,
        ),
      ),
      child: value
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
          : null,
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

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  const _Field({
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: JD.gInk),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: JD.gInkMute),
        filled: true,
        fillColor: JD.gBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: JD.gBlue, width: 1.5),
        ),
      ),
    );
  }
}
