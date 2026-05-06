import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService._();
  static final instance = AudioService._();

  final _player = AudioPlayer();

  Future<void> play(String assetPath) async {
    final p = assetPath.startsWith('assets/')
        ? assetPath.substring('assets/'.length)
        : assetPath;
    try {
      await _player.stop();
      await _player.play(AssetSource(p));
    } catch (_) {
      // 음성 재생 실패는 무시 (UI는 계속 동작)
    }
  }

  Future<void> stop() => _player.stop();
}
