import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/theme.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  static const _rows = <_FeatureRow>[
    _FeatureRow('폰 상태 확인', free: true, premium: true),
    _FeatureRow('홈 화면 관리', free: true, premium: true),
    _FeatureRow('약 관리', free: true, premium: true),
    _FeatureRow('긴급 연락', free: true, premium: true),
    _FeatureRow('가족 메시지',
        freeText: '월 50건', premiumText: '무제한'),
    _FeatureRow('모르는 번호 감지', free: false, premium: true),
    _FeatureRow('위치 추적', free: false, premium: true),
    _FeatureRow('폰 미사용 알림', free: true, premium: true),
    _FeatureRow('배터리 부족 알림', free: true, premium: true),
    _FeatureRow('긴급 소리 보내기', free: false, premium: true),
  ];

  void _onSubscribe(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('준비 중입니다')));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: JTheme.guardian(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon:
                          const Icon(Icons.close_rounded, color: JD.gInk),
                    ),
                    const Text(
                      '안심 프리미엄',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: JD.gInkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: [
                    const Text(
                      '안심 프리미엄 구독',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: JD.gInk,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '부모님의 안전을 더 든든하게 지켜드려요',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: JD.gInkSoft,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: JD.gLine, width: 1),
                      ),
                      child: Column(
                        children: [
                          const _HeaderRow(),
                          for (var i = 0; i < _rows.length; i++) ...[
                            const Divider(
                                height: 1, color: JD.gLine, thickness: 1),
                            _BodyRow(row: _rows[i]),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    children: [
                      const Text(
                        '월 5,900원',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: JD.gBlue,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _onSubscribe(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: JD.gBlue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          textStyle: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        child: const Text('구독하기'),
                      ),
                    ],
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

class _FeatureRow {
  final String label;
  final bool? free;
  final bool? premium;
  final String? freeText;
  final String? premiumText;
  const _FeatureRow(
    this.label, {
    this.free,
    this.premium,
    this.freeText,
    this.premiumText,
  });
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8FC),
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              '기능',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: JD.gInkMute,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '무료',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: JD.gInkMute,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '프리미엄',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: JD.gBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyRow extends StatelessWidget {
  final _FeatureRow row;
  const _BodyRow({required this.row});

  Widget _cell({String? text, bool? value, required bool premiumCol}) {
    if (text != null) {
      return Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: premiumCol ? JD.gBlue : JD.gInkSoft,
        ),
      );
    }
    return Icon(
      value == true ? Icons.check_circle_rounded : Icons.remove_circle_rounded,
      color: value == true
          ? (premiumCol ? JD.gBlue : JD.gGreen)
          : JD.gInkMute.withValues(alpha: 0.5),
      size: 22,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              row.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: JD.gInk,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: _cell(
                text: row.freeText,
                value: row.free,
                premiumCol: false,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: _cell(
                text: row.premiumText,
                value: row.premium,
                premiumCol: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
