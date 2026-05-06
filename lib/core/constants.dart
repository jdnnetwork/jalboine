import 'package:flutter/material.dart';
import 'design_tokens.dart';

class JConst {
  static const supabaseUrl = 'https://jubgobjvcrbagfuyohwv.supabase.co';
  static const supabaseAnonKey =
      'sb_publishable_xtCmqqKIvSuSxdJPjRDh-w_m_TLIotZ';

  static const deepLinkHost = 'jalboine.app';

  static const apps = <String, AppMeta>{
    'phone': AppMeta(
      label: '전화하기',
      audio: 'assets/audio/phone.wav',
      gradStart: Color(0xFF1F8A5B),
      gradEnd: Color(0xFF34B074),
      shadow: Color(0xFF1F8A5B),
      iconBg: Color(0x38FFFFFF), // 0.22
      iconColor: Colors.white,
      textColor: Colors.white,
      icon: Icons.call_rounded,
    ),
    'kakao': AppMeta(
      label: '카카오톡',
      audio: 'assets/audio/kakao.wav',
      gradStart: Color(0xFFFFD24A),
      gradEnd: Color(0xFFF5B800),
      shadow: Color(0xFFF5B800),
      iconBg: Color(0x8CFFFFFF), // 0.55
      iconColor: Color(0xFF5C4100),
      textColor: JD.ink,
      icon: Icons.chat_bubble_rounded,
    ),
    'camera': AppMeta(
      label: '사진찍기',
      audio: 'assets/audio/camera.wav',
      gradStart: Color(0xFF6B4FB8),
      gradEnd: Color(0xFF8E72D9),
      shadow: Color(0xFF6B4FB8),
      iconBg: Color(0x38FFFFFF),
      iconColor: Colors.white,
      textColor: Colors.white,
      icon: Icons.photo_camera_rounded,
    ),
    'youtube': AppMeta(
      label: '영상 보기',
      audio: 'assets/audio/youtube.wav',
      gradStart: Color(0xFFE5641F),
      gradEnd: Color(0xFFFF8A45),
      shadow: Color(0xFFE5641F),
      iconBg: Color(0x38FFFFFF),
      iconColor: Colors.white,
      textColor: Colors.white,
      icon: Icons.play_circle_fill_rounded,
    ),
    'album': AppMeta(
      label: '사진앨범',
      audio: 'assets/audio/album.wav',
      gradStart: Color(0xFFC44569),
      gradEnd: Color(0xFFE5638A),
      shadow: Color(0xFFC44569),
      iconBg: Color(0x38FFFFFF),
      iconColor: Colors.white,
      textColor: Colors.white,
      icon: Icons.photo_library_rounded,
    ),
  };

  static const audioMedicineQ = 'assets/audio/medicine.wav';
  static const audioMedicineCount = 'assets/audio/how many.wav';
  static const audioMedicineHour = 'assets/audio/what hour.wav';
  static const audioMedicineAlarm = 'assets/audio/medicine_alarm.wav';
  static const audioAge = 'assets/audio/age.wav';
  static const audioFamily = 'assets/audio/family.wav';
  static const audioStart = 'assets/audio/start.wav';
}

class AppMeta {
  final String label;
  final String audio;
  final Color gradStart;
  final Color gradEnd;
  final Color shadow;
  final Color iconBg;
  final Color iconColor;
  final Color textColor;
  final IconData icon;
  const AppMeta({
    required this.label,
    required this.audio,
    required this.gradStart,
    required this.gradEnd,
    required this.shadow,
    required this.iconBg,
    required this.iconColor,
    required this.textColor,
    required this.icon,
  });

  LinearGradient get gradient => LinearGradient(
        begin: const Alignment(-0.6, -1),
        end: const Alignment(0.6, 1),
        colors: [gradStart, gradEnd],
      );
}
