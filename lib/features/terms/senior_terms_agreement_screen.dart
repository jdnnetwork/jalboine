import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 어르신 온보딩 첫 화면 — 이용약관/개인정보/위치정보 동의.
class SeniorTermsAgreementScreen extends StatefulWidget {
  const SeniorTermsAgreementScreen({super.key});

  @override
  State<SeniorTermsAgreementScreen> createState() =>
      _SeniorTermsAgreementScreenState();
}

class _SeniorTermsAgreementScreenState
    extends State<SeniorTermsAgreementScreen>
    with TickerProviderStateMixin {
  static const _ink = Color(0xFF2D3460);
  static const _inkSoft = Color(0xFF4A5088);
  static const _accent = Color(0xFF6C63FF);

  // 약관 동의 상태
  bool _terms = false;
  bool _privacy = false;
  bool _location = false;
  bool _individualMode = false;

  bool get _allRequired => _terms && _privacy;

  // 등장 애니메이션 (한 컨트롤러로 시퀀스 관리, 총 2초)
  late final AnimationController _entryCtrl;
  late final Animation<Offset> _mascotSlide;
  late final Animation<double> _title1Fade;
  late final Animation<Offset> _title1Slide;
  late final Animation<double> _title2Fade;
  late final Animation<Offset> _title2Slide;
  late final Animation<double> _descFade;
  late final Animation<Offset> _descSlide;
  late final Animation<double> _qFade;
  late final Animation<Offset> _qSlide;

  // 둥둥 애니메이션 (마스코트 등장 후 시작)
  late final AnimationController _bobCtrl;
  late final Animation<double> _bobAnim;
  bool _entryDone = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _bobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _bobAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _bobCtrl, curve: Curves.easeInOut),
    );

    // Intervals (entire sequence = 2.0s)
    Animation<double> ival(double a, double b, [Curve c = Curves.easeOut]) =>
        CurvedAnimation(parent: _entryCtrl, curve: Interval(a, b, curve: c));

    // 1) 마스코트: 0 ~ 0.25 (0.5s) easeOutBack, 오른쪽 바깥 → 중앙
    _mascotSlide = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: Offset.zero,
    ).animate(ival(0.0, 0.25, Curves.easeOutBack));

    // 2) 제목1: 0.25 ~ 0.40 (0.3s) — 마스코트 직후
    _title1Fade = ival(0.25, 0.40);
    _title1Slide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(ival(0.25, 0.40));

    // 3) 제목2: 0.40 ~ 0.55
    _title2Fade = ival(0.40, 0.55);
    _title2Slide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(ival(0.40, 0.55));

    // 4) 설명: 0.55 ~ 0.70
    _descFade = ival(0.55, 0.70);
    _descSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(ival(0.55, 0.70));

    // 5) 질문 + 버튼: 0.80 ~ 1.0 (0.4s)
    _qFade = ival(0.80, 1.0);
    _qSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(ival(0.80, 1.0));

    _entryCtrl.forward();
    // 마스코트 등장 끝나는 시점에 둥둥 시작
    _entryCtrl.addListener(() {
      if (!_entryDone && _entryCtrl.value >= 0.25) {
        _entryDone = true;
        _bobCtrl.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _bobCtrl.dispose();
    super.dispose();
  }

  void _openViewer({required String asset, required String title}) {
    context.push('/terms/view', extra: {'asset': asset, 'title': title});
  }

  void _onYes() {
    setState(() {
      _terms = true;
      _privacy = true;
      _location = true;
    });
    context.go('/onboarding/launcher-guide');
  }

  void _onNo() {
    setState(() => _individualMode = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDDE4F5), Color(0xFFA8B5DC)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                // 마스코트 — 등장 슬라이드 + 등장 후 둥둥
                _Mascot(
                  slide: _mascotSlide,
                  bob: _bobAnim,
                  showBob: () => _entryDone,
                ),
                const SizedBox(height: 24),
                // 제목 1
                _SlideFade(
                  fade: _title1Fade,
                  slide: _title1Slide,
                  child: const Text(
                    '어르신의 정보는',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      letterSpacing: -1.0,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 제목 2
                _SlideFade(
                  fade: _title2Fade,
                  slide: _title2Slide,
                  child: const Text(
                    '소중하게 관리할게요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      letterSpacing: -1.0,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 설명
                _SlideFade(
                  fade: _descFade,
                  slide: _descSlide,
                  child: const Text(
                    '서비스 이용을 위해 동의가 필요해요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _inkSoft,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const Spacer(),
                // 질문/버튼 영역 — 모드 토글
                _SlideFade(
                  fade: _qFade,
                  slide: _qSlide,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _individualMode
                        ? _IndividualPanel(
                            key: const ValueKey('individual'),
                            terms: _terms,
                            privacy: _privacy,
                            location: _location,
                            onTermsChanged: (v) => setState(() => _terms = v),
                            onPrivacyChanged:
                                (v) => setState(() => _privacy = v),
                            onLocationChanged:
                                (v) => setState(() => _location = v),
                            onView: _openViewer,
                            onNext: _allRequired
                                ? () => context.go('/onboarding/launcher-guide')
                                : null,
                          )
                        : _AggregatePanel(
                            key: const ValueKey('aggregate'),
                            onYes: _onYes,
                            onNo: _onNo,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Mascot extends StatelessWidget {
  final Animation<Offset> slide;
  final Animation<double> bob;
  final bool Function() showBob;
  const _Mascot({
    required this.slide,
    required this.bob,
    required this.showBob,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slide,
      child: Center(
        child: AnimatedBuilder(
          animation: bob,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, showBob() ? bob.value : 0),
            child: child,
          ),
          child: Image.asset(
            'assets/images/mascot.png',
            width: 120,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _SlideFade extends StatelessWidget {
  final Animation<double> fade;
  final Animation<Offset> slide;
  final Widget child;
  const _SlideFade({
    required this.fade,
    required this.slide,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

class _AggregatePanel extends StatelessWidget {
  final VoidCallback onYes;
  final VoidCallback onNo;
  const _AggregatePanel({
    super.key,
    required this.onYes,
    required this.onNo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '전체 동의 하시겠습니까?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _SeniorTermsAgreementScreenState._ink,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (_, c) {
            final yesW = c.maxWidth * 0.55;
            final noW = c.maxWidth * 0.40;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: yesW,
                  height: 90,
                  child: ElevatedButton(
                    onPressed: onYes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _SeniorTermsAgreementScreenState._accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      '네',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: noW,
                  height: 90,
                  child: ElevatedButton(
                    onPressed: onNo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.5),
                      foregroundColor:
                          _SeniorTermsAgreementScreenState._inkSoft,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      '아니요',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _SeniorTermsAgreementScreenState._inkSoft,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _IndividualPanel extends StatelessWidget {
  final bool terms;
  final bool privacy;
  final bool location;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<bool> onPrivacyChanged;
  final ValueChanged<bool> onLocationChanged;
  final void Function({required String asset, required String title}) onView;
  final VoidCallback? onNext;
  const _IndividualPanel({
    super.key,
    required this.terms,
    required this.privacy,
    required this.location,
    required this.onTermsChanged,
    required this.onPrivacyChanged,
    required this.onLocationChanged,
    required this.onView,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final canNext = onNext != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '원하시는 항목만 동의해주세요',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _SeniorTermsAgreementScreenState._ink,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        _ToggleRow(
          label: '이용약관 동의 (필수)',
          value: terms,
          onChanged: onTermsChanged,
          onView: () => onView(
            asset: 'assets/terms/senior_terms.md',
            title: '잘보이네 이용약관',
          ),
        ),
        const SizedBox(height: 10),
        _ToggleRow(
          label: '개인정보 수집 동의 (필수)',
          value: privacy,
          onChanged: onPrivacyChanged,
          onView: () => onView(
            asset: 'assets/terms/senior_privacy.md',
            title: '개인정보처리방침',
          ),
        ),
        const SizedBox(height: 10),
        _ToggleRow(
          label: '위치정보 이용 동의 (선택)',
          value: location,
          onChanged: onLocationChanged,
          onView: () => onView(
            asset: 'assets/terms/senior_location.md',
            title: '위치정보 이용약관',
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 80,
          child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: canNext
                  ? _SeniorTermsAgreementScreenState._accent
                  : const Color(0xFFCBD0DD),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFCBD0DD),
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              '다음',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onView;
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final bg = value
        ? _SeniorTermsAgreementScreenState._accent
        : Colors.white.withValues(alpha: 0.55);
    final fg = value
        ? Colors.white
        : _SeniorTermsAgreementScreenState._inkSoft;
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onChanged(!value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        value
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: fg,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: fg,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onView,
            style: TextButton.styleFrom(
              foregroundColor: _SeniorTermsAgreementScreenState._ink,
              minimumSize: const Size(56, 60),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              '보기',
              style: TextStyle(
                fontSize: 14,
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
