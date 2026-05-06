import 'package:flutter/material.dart';

/// 잘보이네 — 두 가지 톤:
///  - 피보호자(senior): 웜 베이지 배경 + 글래스, 큰 글씨, 따뜻한 색
///  - 보호자(guardian): 흰 배경 + 파란 포인트, 모던 글래스
class JTheme {
  // 피보호자 팔레트
  static const seniorBg = Color(0xFFF6EAD8);
  static const seniorBgEnd = Color(0xFFEFD9BC);
  static const seniorCard = Color(0xFFFFFFFF);
  static const seniorText = Color(0xFF2A2118);
  static const seniorAccent = Color(0xFFCB7A3C);
  static const sos = Color(0xFFC8102E);

  // 보호자 팔레트
  static const guardianBg = Color(0xFFF6F8FB);
  static const guardianAccent = Color(0xFF2F6FE0);
  static const guardianCard = Color(0xFFFFFFFF);
  static const guardianText = Color(0xFF101828);

  // 호환용 alias
  static const surface = seniorBg;
  static const onSurface = seniorText;

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: seniorBg,
      colorScheme: base.colorScheme.copyWith(
        surface: seniorBg,
        onSurface: seniorText,
        primary: seniorAccent,
        error: sos,
      ),
      textTheme: base.textTheme.apply(
        fontFamilyFallback: const ['sans-serif'],
      ).copyWith(
        displayLarge: const TextStyle(
            fontSize: 44, fontWeight: FontWeight.w900, color: seniorText),
        headlineLarge: const TextStyle(
            fontSize: 34, fontWeight: FontWeight.w900, color: seniorText),
        headlineMedium: const TextStyle(
            fontSize: 28, fontWeight: FontWeight.w900, color: seniorText),
        titleLarge: const TextStyle(
            fontSize: 26, fontWeight: FontWeight.w900, color: seniorText),
        bodyLarge: const TextStyle(
            fontSize: 24, fontWeight: FontWeight.w700, color: seniorText),
        labelLarge: const TextStyle(
            fontSize: 28, fontWeight: FontWeight.w900, color: seniorText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(96),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28)),
          textStyle:
              const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(72),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          textStyle:
              const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  static ThemeData guardian() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: guardianBg,
      colorScheme: base.colorScheme.copyWith(
        surface: guardianBg,
        onSurface: guardianText,
        primary: guardianAccent,
      ),
      cardColor: guardianCard,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: guardianAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          textStyle:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          elevation: 0,
        ),
      ),
    );
  }
}

/// 부드러운 웜 베이지 그라데이션 + 살짝 글래스 배경.
class SeniorBackground extends StatelessWidget {
  final Widget child;
  const SeniorBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [JTheme.seniorBg, JTheme.seniorBgEnd],
        ),
      ),
      child: child,
    );
  }
}

class GuardianBackground extends StatelessWidget {
  final Widget child;
  const GuardianBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF6F8FB), Color(0xFFEEF3FB)],
        ),
      ),
      child: child,
    );
  }
}
