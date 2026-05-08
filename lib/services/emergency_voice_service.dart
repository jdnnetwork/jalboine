import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase.dart';

class EmergencyVoiceService {
  EmergencyVoiceService._();
  static final instance = EmergencyVoiceService._();

  static const _bucket = 'emergency-voice';
  static const maxSeconds = 30;

  final _recorder = AudioRecorder();
  String? _currentPath;

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// 임시 파일 경로에 녹음 시작.
  Future<String> startRecording() async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/emergency_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 96000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );
    _currentPath = path;
    return path;
  }

  /// 녹음 중지. 저장된 파일 경로 반환.
  Future<String?> stopRecording() async {
    final p = await _recorder.stop();
    _currentPath = p ?? _currentPath;
    return _currentPath;
  }

  Future<bool> isRecording() => _recorder.isRecording();

  /// 녹음 파일을 Storage 에 업로드하고 public URL 반환.
  /// 보호자 본인 폴더 = auth.uid() 아래 저장.
  Future<String> uploadVoice({
    required String guardianUid,
    required String localPath,
    required String seniorUid,
  }) async {
    final sb = supabaseClient;
    final remotePath = '$guardianUid/$seniorUid.m4a';
    final file = File(localPath);
    await sb.storage.from(_bucket).upload(
          remotePath,
          file,
          fileOptions: const FileOptions(upsert: true, contentType: 'audio/mp4'),
        );
    return sb.storage.from(_bucket).getPublicUrl(remotePath);
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
