import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/supabase.dart';

/// 피보호자 폰 위치 수집 + senior_settings 업로드.
class LocationService {
  LocationService._();
  static final instance = LocationService._();

  Future<bool> hasFinePermission() async {
    final s = await Permission.locationWhenInUse.status;
    return s.isGranted;
  }

  Future<bool> hasBackgroundPermission() async {
    final s = await Permission.locationAlways.status;
    return s.isGranted;
  }

  Future<bool> requestFine() async {
    final r = await Permission.locationWhenInUse.request();
    return r.isGranted;
  }

  Future<bool> requestBackground() async {
    final r = await Permission.locationAlways.request();
    return r.isGranted;
  }

  /// 현재 위치를 senior_settings 에 push. 권한 없거나 GPS 꺼져있으면 noop.
  Future<void> pushOnce() async {
    try {
      if (!await hasFinePermission()) return;
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      final sb = supabaseClient;
      final uid = sb.auth.currentUser?.id;
      if (uid == null) return;
      await sb.from('senior_settings').update({
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'location_updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('user_id', uid);
    } catch (_) {
      // 비치명적 — 다음 주기에 재시도
    }
  }
}
