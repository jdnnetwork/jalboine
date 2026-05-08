import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/theme.dart';
import '../../widgets/big_button.dart';

/// 어르신 온보딩 첫 화면 — 이용약관/개인정보/위치정보 동의.
class SeniorTermsAgreementScreen extends StatefulWidget {
  const SeniorTermsAgreementScreen({super.key});

  @override
  State<SeniorTermsAgreementScreen> createState() =>
      _SeniorTermsAgreementScreenState();
}

class _SeniorTermsAgreementScreenState
    extends State<SeniorTermsAgreementScreen> {
  bool _terms = false;
  bool _privacy = false;
  bool _location = false;

  bool get _allRequired => _terms && _privacy;
  bool get _all => _terms && _privacy && _location;

  void _toggleAll(bool v) {
    setState(() {
      _terms = v;
      _privacy = v;
      _location = v;
    });
  }

  void _openViewer({required String asset, required String title}) {
    context.push(
      '/terms/view',
      extra: {'asset': asset, 'title': title},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SeniorBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '서비스 이용을 위해\n동의가 필요해요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: JD.ink,
                    height: 1.35,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 28),
                _AllAgreeCard(value: _all, onTap: () => _toggleAll(!_all)),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    children: [
                      _AgreeRow(
                        label: '이용약관 동의',
                        required: true,
                        value: _terms,
                        onChanged: (v) => setState(() => _terms = v),
                        onView: () => _openViewer(
                          asset: 'assets/terms/senior_terms.md',
                          title: '잘보이네 이용약관',
                        ),
                      ),
                      _AgreeRow(
                        label: '개인정보 수집 및 이용 동의',
                        required: true,
                        value: _privacy,
                        onChanged: (v) => setState(() => _privacy = v),
                        onView: () => _openViewer(
                          asset: 'assets/terms/senior_privacy.md',
                          title: '개인정보처리방침',
                        ),
                      ),
                      _AgreeRow(
                        label: '위치정보 이용약관 동의',
                        required: false,
                        value: _location,
                        onChanged: (v) => setState(() => _location = v),
                        onView: () => _openViewer(
                          asset: 'assets/terms/senior_location.md',
                          title: '위치정보 이용약관',
                        ),
                      ),
                    ],
                  ),
                ),
                BigButton(
                  label: '다음',
                  background:
                      _allRequired ? JD.cCoralDeep : const Color(0xFFCBC2B0),
                  shadowBottomColor: _allRequired
                      ? const Color(0xFFD9794D)
                      : const Color(0xFFAAA08D),
                  foreground: Colors.white,
                  height: 84,
                  fontSize: 28,
                  onTap: _allRequired
                      ? () => context.go('/onboarding/launcher-guide')
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AllAgreeCard extends StatelessWidget {
  final bool value;
  final VoidCallback onTap;
  const _AllAgreeCard({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: value ? JD.cCoralDeep : const Color(0xFFE6DCC4),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              _BigCheck(value: value),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  '전체 동의',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: JD.ink,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgreeRow extends StatelessWidget {
  final String label;
  final bool required;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onView;
  const _AgreeRow({
    required this.label,
    required this.required,
    required this.value,
    required this.onChanged,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onChanged(!value),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: _BigCheck(value: value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(!value),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: required ? '[필수] ' : '[선택] ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: required ? JD.cCoralDeep : JD.inkMute,
                          ),
                        ),
                        TextSpan(
                          text: label,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: JD.ink,
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
                  foregroundColor: JD.inkSoft,
                ),
                child: const Text(
                  '보기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigCheck extends StatelessWidget {
  final bool value;
  const _BigCheck({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: value ? JD.cCoralDeep : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value ? JD.cCoralDeep : const Color(0xFFC8B89A),
          width: 2,
        ),
      ),
      child: value
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
          : null,
    );
  }
}
