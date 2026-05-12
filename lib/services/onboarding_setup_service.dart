import 'package:flutter/services.dart';

/// 온보딩 시작 시 런처/배터리 설정 호출용 네이티브 채널 래퍼.
class OnboardingSetupService {
  OnboardingSetupService._();
  static final instance = OnboardingSetupService._();

  static const _ch = MethodChannel('com.jalboine/onboarding');

  Future<bool> isDefaultLauncher() async {
    try {
      final r = await _ch.invokeMethod<bool>('isDefaultLauncher');
      return r ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestDefaultLauncher() async {
    try {
      await _ch.invokeMethod('requestDefaultLauncher');
    } catch (_) {}
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final r =
          await _ch.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return r ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _ch.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (_) {}
  }

  /// Android SDK_INT. iOS/실패 시 0.
  Future<int> getSdkInt() async {
    try {
      final r = await _ch.invokeMethod<int>('getSdkInt');
      return r ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// 시스템 홈/기본 앱 설정을 연다.
  /// 사용자가 잘보이네에서 다른 런처로 기본 런처를 바꾸려 할 때 사용.
  Future<void> openHomeSettings() async {
    try {
      await _ch.invokeMethod('openHomeSettings');
    } catch (_) {}
  }
}
