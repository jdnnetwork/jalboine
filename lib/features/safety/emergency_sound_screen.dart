import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/supabase.dart';
import '../../core/theme.dart';
import '../../models/senior_settings.dart';
import '../../services/launcher_service.dart';
import '../../services/realtime_service.dart';
import '../../services/volume_service.dart';
import '../../widgets/big_button.dart';

/// 보호자가 emergency_sound=true 를 보냈을 때 띄우는 전체화면 팝업.
/// 화면 켜짐 + 최대 볼륨 + 음성 반복 재생.
class EmergencySoundScreen extends ConsumerStatefulWidget {
  const EmergencySoundScreen({super.key});

  @override
  ConsumerState<EmergencySoundScreen> createState() =>
      _EmergencySoundScreenState();
}

class _EmergencySoundScreenState extends ConsumerState<EmergencySoundScreen> {
  final _player = AudioPlayer();
  Timer? _repeatTimer;
  int _playCount = 0;
  static const _maxLoops = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    await VolumeService.instance.setMax();
    await _playOnce();
    // 30초마다 반복 (음성 길이 짧을 때 빠른 반복 효과)
    _repeatTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_playCount >= _maxLoops) {
        _repeatTimer?.cancel();
        return;
      }
      await _playOnce();
    });
  }

  Future<void> _playOnce() async {
    _playCount += 1;
    final s = ref.read(seniorSettingsProvider).value ?? SeniorSettings.empty;
    final url = s.emergencyVoiceUrl;
    try {
      if (url != null && url.isNotEmpty) {
        await _player.stop();
        await _player.play(UrlSource(url));
      } else {
        FlutterRingtonePlayer().playAlarm();
      }
    } catch (_) {
      try {
        FlutterRingtonePlayer().playAlarm();
      } catch (_) {}
    }
  }

  Future<void> _stopAll() async {
    _repeatTimer?.cancel();
    try {
      await _player.stop();
    } catch (_) {}
    try {
      FlutterRingtonePlayer().stop();
    } catch (_) {}
    await VolumeService.instance.restore();
  }

  Future<void> _onCallGuardian() async {
    final s = ref.read(seniorSettingsProvider).value;
    final phone = s?.guardianPhone;
    if (phone == null || phone.trim().isEmpty) return;
    HapticFeedback.heavyImpact();
    await LauncherService.dial(phone);
  }

  Future<void> _onAck() async {
    await _stopAll();
    final sb = ref.read(supabaseProvider);
    final uid = sb.auth.currentUser?.id;
    if (uid != null) {
      try {
        await sb
            .from('senior_settings')
            .update({'emergency_sound': false}).eq('user_id', uid);
      } catch (_) {}
    }
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SeniorBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE4E4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_rounded,
                      size: 80,
                      color: JD.cRed,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    '가족이 연락하고\n있어요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: JD.ink,
                      height: 1.3,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const Spacer(),
                  BigButton(
                    label: '전화하기',
                    background: JD.cGreen,
                    shadowBottomColor: const Color(0xFF166644),
                    height: 96,
                    fontSize: 32,
                    icon: Icons.call_rounded,
                    onTap: _onCallGuardian,
                  ),
                  const SizedBox(height: 12),
                  BigButton(
                    label: '확인했어요',
                    background: Colors.white,
                    shadowBottomColor: const Color(0xFFD9CFB8),
                    foreground: JD.ink,
                    height: 80,
                    fontSize: 26,
                    border: Border.all(
                        color: const Color(0xFFE6DCC4), width: 2),
                    onTap: _onAck,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
