import 'package:shared_preferences/shared_preferences.dart';

/// 온보딩 완료 여부 — 앱 시작 시 1회 로드하여 라우터 redirect 에서 사용.
///
/// Supabase 의 profiles.onboarding_complete 와 SharedPreferences 양쪽에
/// 저장되지만, 라우터는 빠르고 오프라인에서도 동작하는 로컬 값을 본다.
class OnboardingStatus {
  OnboardingStatus._();

  static bool _complete = false;
  static bool _launcherSet = false;
  static bool _loaded = false;

  static const _kComplete = 'onboarding_complete';
  static const _kLauncherSet = 'launcher_set';

  static bool get isComplete => _complete;
  static bool get launcherSet => _launcherSet;
  static bool get isLoaded => _loaded;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _complete = prefs.getBool(_kComplete) ?? false;
      _launcherSet = prefs.getBool(_kLauncherSet) ?? false;
    } catch (_) {}
    _loaded = true;
  }

  static Future<void> save({required bool launcherSet}) async {
    _complete = true;
    _launcherSet = launcherSet;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kComplete, true);
      await prefs.setBool(_kLauncherSet, launcherSet);
    } catch (_) {}
  }

  static Future<void> reset() async {
    _complete = false;
    _launcherSet = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kComplete);
      await prefs.remove(_kLauncherSet);
    } catch (_) {}
  }
}
