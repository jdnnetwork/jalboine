import 'package:flutter/material.dart';

class JConst {
  static const supabaseUrl = 'https://jubgobjvcrbagfuyohwv.supabase.co';
  static const supabaseAnonKey =
      'sb_publishable_xtCmqqKIvSuSxdJPjRDh-w_m_TLIotZ';

  static const deepLinkScheme = 'https';
  static const deepLinkHost = 'jalboine.app';

  static const apps = <String, AppMeta>{
    'phone': AppMeta(
      label: '전화',
      audio: 'assets/audio/phone.wav',
      bg: Color(0xFF2E7D5A),
      fg: Colors.white,
      gradient: Color(0xFFB7E4C7),
      icon: Icons.call_rounded,
    ),
    'kakao': AppMeta(
      label: '카카오톡',
      audio: 'assets/audio/kakao.wav',
      bg: Color(0xFFFFE100),
      fg: Color(0xFF181600),
      gradient: Color(0xFFFFF59D),
      icon: Icons.chat_bubble_rounded,
    ),
    'youtube': AppMeta(
      label: '동영상',
      audio: 'assets/audio/youtube.wav',
      bg: Color(0xFFD64545),
      fg: Colors.white,
      gradient: Color(0xFFFFCDD2),
      icon: Icons.play_circle_fill_rounded,
    ),
    'camera': AppMeta(
      label: '카메라',
      audio: 'assets/audio/camera.wav',
      bg: Color(0xFF2D2D2D),
      fg: Colors.white,
      gradient: Color(0xFFE0DFDC),
      icon: Icons.photo_camera_rounded,
    ),
    'album': AppMeta(
      label: '사진앨범',
      audio: 'assets/audio/album.wav',
      bg: Color(0xFFB44C5A),
      fg: Colors.white,
      gradient: Color(0xFFF8BBD0),
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
  final Color bg;
  final Color fg;
  final Color gradient;
  final IconData icon;
  const AppMeta({
    required this.label,
    required this.audio,
    required this.bg,
    required this.fg,
    required this.gradient,
    required this.icon,
  });
}
