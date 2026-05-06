import 'package:flutter/material.dart';

/// 잘보이네 디자인 시스템 — design/desing.html 기준.
class JD {
  // 피보호자(senior) 배경
  static const bgCream = Color(0xFFFBF6EE);
  static const bgCreamDeep = Color(0xFFF4ECDC);
  static const bgPage = Color(0xFFE8DDC9);
  static const bgCard = Color(0xFFFFFFFF);

  // 잉크 (텍스트)
  static const ink = Color(0xFF1F1A14);
  static const inkSoft = Color(0xFF5C5347);
  static const inkMute = Color(0xFF8A8073);

  // 채도 높은 원색
  static const cGreen = Color(0xFF1F8A5B);
  static const cGreenLight = Color(0xFF34B074);
  static const cMint = Color(0xFF8FE0A8);

  static const cYellow = Color(0xFFE5A000);
  static const cYellowLight = Color(0xFFFFC233);
  static const cYellowBg = Color(0xFFFFD24A);

  static const cPurple = Color(0xFF6B4FB8);
  static const cPurpleLight = Color(0xFF8E72D9);
  static const cLavender = Color(0xFFC9B8F0);

  static const cPink = Color(0xFFC44569);
  static const cPinkLight = Color(0xFFE5638A);
  static const cPinkBg = Color(0xFFFF9DBC);

  static const cOrange = Color(0xFFE5641F);
  static const cOrangeLight = Color(0xFFFF8C4A);
  static const cCoral = Color(0xFFFFA875);
  static const cCoralDeep = Color(0xFFE5641F);

  static const cRed = Color(0xFFC92020);
  static const cRedLight = Color(0xFFE53E3E);

  // 보호자(guardian) 팔레트
  static const gBg = Color(0xFFF4F6FA);
  static const gCard = Color(0xFFFFFFFF);
  static const gInk = Color(0xFF0F1830);
  static const gInkSoft = Color(0xFF5A6378);
  static const gInkMute = Color(0xFF9099AC);
  static const gBlue = Color(0xFF2F6BFF);
  static const gBlueSoft = Color(0xFFE8F0FF);
  static const gBlueDeep = Color(0xFF1F4FCC);
  static const gGreen = Color(0xFF22B881);
  static const gOrange = Color(0xFFFF8A45);
  static const gPink = Color(0xFFFF6B9D);
  static const gLine = Color(0xFFEEF1F6);

  // 둥근 모서리
  static const rCard = 32.0;
  static const rCardLg = 40.0;
  static const rButton = 28.0;

  // 그림자 (입체 stacked shadow)
  static List<BoxShadow> shadowCard = const [
    BoxShadow(
      color: Color(0x14785A32), // rgba(120,90,50,0.08)
      offset: Offset(0, 6),
      blurRadius: 0,
    ),
    BoxShadow(
      color: Color(0x1A785A32), // rgba(120,90,50,0.10)
      offset: Offset(0, 12),
      blurRadius: 24,
    ),
  ];

  static List<BoxShadow> shadowPress = const [
    BoxShadow(
      color: Color(0x1F785A32),
      offset: Offset(0, 2),
      blurRadius: 0,
    ),
    BoxShadow(
      color: Color(0x14785A32),
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
  ];

  static List<BoxShadow> shadowSos = const [
    BoxShadow(
      color: Color(0x40B41E1E),
      offset: Offset(0, 8),
      blurRadius: 0,
    ),
    BoxShadow(
      color: Color(0x4DE53E3E),
      offset: Offset(0, 14),
      blurRadius: 30,
    ),
  ];

  static List<BoxShadow> shadowBlueCard = const [
    BoxShadow(
      color: Color(0x0F0F1830),
      offset: Offset(0, 6),
      blurRadius: 20,
    ),
    BoxShadow(
      color: Color(0x0A0F1830),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  /// 코랄→옐로 그라디언트 (로고용)
  static const gradLogo = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [cCoral, cYellow],
  );

  /// 페이지 베이스 그라디언트 (피보호자 화면)
  static const gradStage = RadialGradient(
    center: Alignment(-0.6, -0.7),
    radius: 1.2,
    colors: [Color(0x4DFFC896), Color(0x00EFE3CE)],
  );

  /// 그림자 stacked offset 값 (button bottom edge color)
  static const stackBtnGreen = Color(0xFF1F8A5B);
  static const stackBtnCoral = Color(0xFFD9794D);
  static const stackBtnRed = Color(0xFF8A1414);
}
