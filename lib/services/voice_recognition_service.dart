import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// 짧은 한국어 발화에서 "예/아니요"를 추출.
class VoiceRecognitionService {
  VoiceRecognitionService._();
  static final instance = VoiceRecognitionService._();

  final _speech = stt.SpeechToText();
  bool _initOk = false;

  Future<bool> _ensureInit() async {
    if (_initOk) return true;
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return false;
    _initOk = await _speech.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
    return _initOk;
  }

  /// 한 번 듣고 "예"/"아니요" 결과를 콜백으로 전달.
  /// 음성 인식이 불가하면 호출자가 그냥 버튼만 사용하도록 false 반환.
  Future<bool> listenOnce(void Function(bool? yes) onResult) async {
    final ok = await _ensureInit();
    if (!ok) return false;
    if (_speech.isListening) await _speech.stop();
    try {
      await _speech.listen(
        localeId: 'ko_KR',
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 2),
        onResult: (r) {
          if (!r.finalResult) return;
          onResult(_classify(r.recognizedWords));
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() async {
    if (_speech.isListening) await _speech.stop();
  }

  bool? _classify(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    const yes = ['네', '예', '응', '그래', '맞아', '좋아'];
    const no = ['아니요', '아니', '아뇨', '안해', '아닙니다', '싫어'];
    for (final w in yes) {
      if (t.contains(w)) return true;
    }
    for (final w in no) {
      if (t.contains(w)) return false;
    }
    return null;
  }
}
