import 'package:flutter/services.dart';

/// 강제 울리기 직전 시스템 볼륨을 최대로 올리고, 끝나면 원래대로 복원.
class VolumeService {
  VolumeService._();
  static final instance = VolumeService._();

  static const _ch = MethodChannel('com.jalboine/volume');

  Future<void> setMax() async {
    try {
      await _ch.invokeMethod('setMaxVolume');
    } on PlatformException {
      // 무시
    } on MissingPluginException {
      // 무시
    }
  }

  Future<void> restore() async {
    try {
      await _ch.invokeMethod('restoreVolume');
    } on PlatformException {
      // 무시
    } on MissingPluginException {
      // 무시
    }
  }
}
