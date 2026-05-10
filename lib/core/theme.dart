import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

/// 두 가지 톤:
///  - 피보호자(senior): 따뜻한 크림베이지 + 진한 잉크
///  - 보호자(guardian): 라이트 그레이블루 + 블루 액센트
class JTheme {
  // 호환용 alias
  static const surface = JD.bgCream;
  static const onSurface = JD.ink;
  static const seniorBg = JD.bgCream;
  static const seniorBgEnd = JD.bgCreamDeep;
  static const seniorCard = JD.bgCard;
  static const seniorText = JD.ink;
  static const seniorAccent = JD.cCoralDeep;
  static const sos = JD.cRed;
  static const guardianBg = JD.gBg;
  static const guardianAccent = JD.gBlue;
  static const guardianCard = JD.gCard;
  static const guardianText = JD.gInk;

  /// Pretendard 우선, 없으면 Noto Sans KR (Google Fonts 라이브러리에 등재된 가장 가까운 대체).
  /// assets/fonts/Pretendard-*.ttf 를 추가하고 pubspec 의 fonts: 섹션에 등록하면
  /// 자동으로 Pretendard 가 우선 사용됨 (fontFamilyFallback 1순위).
  static const _kFallback = ['Pretendard', 'Apple SD Gothic Neo', 'sans-serif'];

  static TextStyle _font({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.notoSansKr(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    ).copyWith(fontFamilyFallback: _kFallback);
  }

  /// 앱 전체 기본 텍스트 테마. 본문 w600 (SemiBold), 제목 w800 (ExtraBold).
  static TextTheme _pretendardTheme(TextTheme base, Color ink, Color inkSoft) {
    return GoogleFonts.notoSansKrTextTheme(base).copyWith(
      displayLarge: _font(
          fontSize: 52, fontWeight: FontWeight.w800, color: ink, height: 1.05, letterSpacing: -1.5),
      displayMedium: _font(
          fontSize: 44, fontWeight: FontWeight.w800, color: ink, height: 1.1, letterSpacing: -1.2),
      headlineLarge: _font(
          fontSize: 36, fontWeight: FontWeight.w800, color: ink, height: 1.15, letterSpacing: -0.8),
      headlineMedium: _font(
          fontSize: 28, fontWeight: FontWeight.w800, color: ink, height: 1.2, letterSpacing: -0.6),
      titleLarge: _font(
          fontSize: 24, fontWeight: FontWeight.w800, color: ink, letterSpacing: -0.4),
      titleMedium: _font(
          fontSize: 20, fontWeight: FontWeight.w800, color: ink),
      bodyLarge: _font(
          fontSize: 18, fontWeight: FontWeight.w600, color: ink),
      bodyMedium: _font(
          fontSize: 16, fontWeight: FontWeight.w600, color: inkSoft),
      labelLarge: _font(
          fontSize: 24, fontWeight: FontWeight.w800, color: ink),
    );
  }

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: JD.bgCream,
      colorScheme: base.colorScheme.copyWith(
        surface: JD.bgCream,
        onSurface: JD.ink,
        primary: JD.cCoralDeep,
        error: JD.cRed,
      ),
      textTheme: _pretendardTheme(base.textTheme, JD.ink, JD.inkSoft),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(64),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(JD.rButton)),
          textStyle: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          textStyle:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  static ThemeData guardian() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: JD.gBg,
      colorScheme: base.colorScheme.copyWith(
        surface: JD.gBg,
        onSurface: JD.gInk,
        primary: JD.gBlue,
      ),
      cardColor: JD.gCard,
      textTheme: _pretendardTheme(base.textTheme, JD.gInk, JD.gInkSoft),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: JD.gBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2),
          elevation: 0,
        ),
      ),
    );
  }
}

/// 피보호자 부드러운 라디얼 그라디언트 배경.
class SeniorBackground extends StatelessWidget {
  final Widget child;
  const SeniorBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: JD.bgCream)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.7, -0.8),
                radius: 1.2,
                colors: [
                  const Color(0xFFFFE0BE).withValues(alpha: 0.55),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.9, 0.9),
                radius: 1.0,
                colors: [
                  const Color(0xFFD4C2F0).withValues(alpha: 0.40),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class GuardianBackground extends StatelessWidget {
  final Widget child;
  const GuardianBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) => ColoredBox(color: JD.gBg, child: child);
}
