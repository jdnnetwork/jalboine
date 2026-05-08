import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../services/emergency_voice_service.dart';

class VoiceRecordScreen extends ConsumerStatefulWidget {
  final String seniorId;
  const VoiceRecordScreen({super.key, required this.seniorId});

  @override
  ConsumerState<VoiceRecordScreen> createState() =>
      _VoiceRecordScreenState();
}

class _VoiceRecordScreenState extends ConsumerState<VoiceRecordScreen> {
  bool _recording = false;
  bool _busy = false;
  String? _localPath;
  int _seconds = 0;
  Timer? _timer;
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    EmergencyVoiceService.instance.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    if (_busy) return;
    if (!_recording) {
      final ok = await Permission.microphone.request();
      if (!ok.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('마이크 권한이 필요합니다')));
        return;
      }
      try {
        await EmergencyVoiceService.instance.startRecording();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
        return;
      }
      setState(() {
        _recording = true;
        _seconds = 0;
        _localPath = null;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() => _seconds += 1);
        if (_seconds >= EmergencyVoiceService.maxSeconds) _stopRecord();
      });
    } else {
      await _stopRecord();
    }
  }

  Future<void> _stopRecord() async {
    _timer?.cancel();
    _timer = null;
    final p = await EmergencyVoiceService.instance.stopRecording();
    if (!mounted) return;
    setState(() {
      _recording = false;
      _localPath = p;
    });
  }

  Future<void> _preview() async {
    if (_localPath == null) return;
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
      return;
    }
    setState(() => _playing = true);
    await _player.play(DeviceFileSource(_localPath!));
    _player.onPlayerComplete.first.then((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  Future<void> _save() async {
    if (_busy || _localPath == null) return;
    setState(() => _busy = true);
    try {
      final sb = ref.read(supabaseProvider);
      final guardianUid = sb.auth.currentUser!.id;
      final url = await EmergencyVoiceService.instance.uploadVoice(
        guardianUid: guardianUid,
        localPath: _localPath!,
        seniorUid: widget.seniorId,
      );
      await sb.from('senior_settings').update({
        'emergency_voice_url': url,
      }).eq('user_id', widget.seniorId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('녹음을 저장했습니다')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: JTheme.guardian(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: JD.gInk),
                    ),
                    const Text(
                      '음성 녹음',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: JD.gInk,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Center(
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: _recording
                          ? const Color(0xFFFFE4E4)
                          : JD.gBlueSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _recording ? Icons.mic_rounded : Icons.mic_none_rounded,
                      size: 80,
                      color: _recording ? JD.cRed : JD.gBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    _recording
                        ? '녹음 중 ($_seconds / ${EmergencyVoiceService.maxSeconds}초)'
                        : (_localPath == null
                            ? '버튼을 눌러 녹음하세요'
                            : '녹음 완료 ($_seconds초)'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: JD.gInkSoft,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _busy ? null : _toggleRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _recording ? JD.cRed : JD.gBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(64),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  child: Text(_recording ? '녹음 중지' : '녹음 시작'),
                ),
                if (_localPath != null && !_recording) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : _preview,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: JD.gBlue,
                            side: const BorderSide(color: JD.gBlue),
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(_playing ? '■ 정지' : '▶ 미리듣기'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : _toggleRecord,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: JD.gInkSoft,
                            side: const BorderSide(color: JD.gLine),
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('다시 녹음'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _busy ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: JD.cGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                    child: const Text('저장'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
